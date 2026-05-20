"""JSON file logging handler for the application."""
import logging
import json
import os
from datetime import datetime
from pathlib import Path

LOG_DIR = Path(__file__).parent.parent / "logs"
LOG_FILE = LOG_DIR / "app.log"
MAX_LOG_SIZE = 10 * 1024 * 1024  # 10 MB


class JsonFileHandler(logging.Handler):
    """Writes log records as JSON lines to a file."""

    def __init__(self, filepath: Path = LOG_FILE):
        super().__init__()
        filepath.parent.mkdir(parents=True, exist_ok=True)
        self._filepath = filepath

    def emit(self, record: logging.LogRecord) -> None:
        try:
            entry = {
                "timestamp": datetime.fromtimestamp(record.created).isoformat(),
                "level": record.levelname,
                "message": record.getMessage(),
                "module": record.name,
            }
            if record.exc_info and record.exc_info[1]:
                entry["exception"] = str(record.exc_info[1])
            line = json.dumps(entry, ensure_ascii=False) + "\n"
            with open(self._filepath, "a", encoding="utf-8") as f:
                f.write(line)
            # Simple rotation: truncate if too big
            if self._filepath.stat().st_size > MAX_LOG_SIZE:
                self._rotate()
        except Exception:
            self.handleError(record)

    def _rotate(self) -> None:
        backup = self._filepath.with_suffix(".log.1")
        if backup.exists():
            backup.unlink()
        self._filepath.rename(backup)


def read_logs(page: int = 1, size: int = 100, level: str | None = None) -> dict:
    """Read logs from the JSON log file with pagination and optional level filter."""
    if not LOG_FILE.exists():
        return {"items": [], "total": 0, "page": page, "size": size, "pages": 0}

    lines: list[dict] = []
    with open(LOG_FILE, "r", encoding="utf-8") as f:
        for raw in f:
            raw = raw.strip()
            if not raw:
                continue
            try:
                entry = json.loads(raw)
                if level and entry.get("level", "").upper() != level.upper():
                    continue
                lines.append(entry)
            except json.JSONDecodeError:
                continue

    # Reverse so newest first
    lines.reverse()
    total = len(lines)
    start = (page - 1) * size
    items = lines[start: start + size]
    pages = (total + size - 1) // size if size > 0 else 0

    return {"items": items, "total": total, "page": page, "size": size, "pages": pages}


def setup_json_logging() -> None:
    """Attach the JSON file handler to the root logger."""
    handler = JsonFileHandler()
    handler.setLevel(logging.INFO)
    logging.getLogger().addHandler(handler)
