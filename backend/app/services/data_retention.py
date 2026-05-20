"""
GDPR-005: Data retention service.

- Delete rejected recordings after 90 days
- Anonymize inactive user accounts after 2 years
- Clean orphan audio files with no database record
"""

import os
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models import Recording, User, RecordingStatusEnum

logger = logging.getLogger(__name__)

REJECTED_RETENTION_DAYS = 90
INACTIVE_ACCOUNT_YEARS = 2


def delete_rejected_recordings(db: Session, dry_run: bool = False) -> int:
    """Delete recordings rejected more than REJECTED_RETENTION_DAYS ago."""
    cutoff = datetime.now(timezone.utc) - timedelta(days=REJECTED_RETENTION_DAYS)

    rejected = (
        db.query(Recording)
        .filter(
            Recording.status == RecordingStatusEnum.REJECTED.value,
            Recording.updated_at < cutoff,
        )
        .all()
    )

    count = 0
    for rec in rejected:
        if rec.filepath and os.path.isfile(rec.filepath):
            if not dry_run:
                try:
                    os.remove(rec.filepath)
                except OSError as e:
                    logger.warning("Could not delete file %s: %s", rec.filepath, e)
        if not dry_run:
            db.delete(rec)
        count += 1

    if not dry_run and count > 0:
        db.commit()

    logger.info(
        "Rejected recordings cleanup: %d recordings %s",
        count,
        "would be deleted (dry run)" if dry_run else "deleted",
    )
    return count


def anonymize_inactive_accounts(db: Session, dry_run: bool = False) -> int:
    """Anonymize users inactive for more than INACTIVE_ACCOUNT_YEARS."""
    cutoff = datetime.now(timezone.utc) - timedelta(days=INACTIVE_ACCOUNT_YEARS * 365)

    inactive_users = (
        db.query(User)
        .filter(
            User.is_active == True,
            User.role != "admin",
            User.updated_at < cutoff,
            User.created_at < cutoff,
        )
        .all()
    )

    count = 0
    for user in inactive_users:
        # Check last recording activity
        last_recording = (
            db.query(Recording)
            .filter(Recording.user_id == user.id)
            .order_by(Recording.created_at.desc())
            .first()
        )

        if last_recording and last_recording.created_at and last_recording.created_at > cutoff:
            continue

        if not dry_run:
            user.username = f"anonymized_{user.id}"
            user.hashed_password = None
            user.is_active = False
            user.consent_given = False
        count += 1

    if not dry_run and count > 0:
        db.commit()

    logger.info(
        "Inactive accounts: %d accounts %s",
        count,
        "would be anonymized (dry run)" if dry_run else "anonymized",
    )
    return count


def clean_orphan_files(db: Session, upload_dir: str, dry_run: bool = False) -> int:
    """Remove audio files that have no corresponding database record."""
    if not os.path.isdir(upload_dir):
        logger.warning("Upload directory does not exist: %s", upload_dir)
        return 0

    db_filepaths = {r.filepath for r in db.query(Recording.filepath).all() if r.filepath}

    count = 0
    for root, _dirs, files in os.walk(upload_dir):
        for fname in files:
            full_path = os.path.join(root, fname)
            if full_path not in db_filepaths:
                if not dry_run:
                    try:
                        os.remove(full_path)
                    except OSError as e:
                        logger.warning("Could not delete orphan %s: %s", full_path, e)
                count += 1

    logger.info(
        "Orphan files cleanup: %d files %s",
        count,
        "would be deleted (dry run)" if dry_run else "deleted",
    )
    return count


def run_all_retention_tasks(db: Session, upload_dir: str, dry_run: bool = False) -> dict:
    """Run all data retention tasks and return a summary."""
    results = {
        "rejected_recordings_deleted": delete_rejected_recordings(db, dry_run=dry_run),
        "accounts_anonymized": anonymize_inactive_accounts(db, dry_run=dry_run),
        "orphan_files_cleaned": clean_orphan_files(db, upload_dir, dry_run=dry_run),
        "dry_run": dry_run,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    logger.info("Data retention summary: %s", results)
    return results
