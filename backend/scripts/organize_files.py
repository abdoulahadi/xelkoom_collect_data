#!/usr/bin/env python3
"""
Script to organize backend files by moving utility scripts to the scripts directory
"""
import os
import shutil
from pathlib import Path

# Define the root directory and scripts directory
ROOT_DIR = Path(__file__).parent.parent.absolute()
SCRIPTS_DIR = ROOT_DIR / "scripts"

# Define files to move to scripts directory
SCRIPT_FILES = [
    "add_metadata_column.py",
    "add_role_column.py",
    "add_sample_sentences.py",
    "check_db.py",
    "configure_balance.py",
    "create_admin_user.py",
    "create_moderator.py",
    "update_user_roles.py",
]

# Define test files to move to tests directory
TEST_FILES = [
    "test_api_sentences.py",
    "test_audio_processing.py",
    "test_auth_with_password.py",
    "test_balanced_selection.py",
    "test_recording_count.py",
    "test_routes.py",
]

def move_files():
    """Move utility scripts to scripts directory"""
    # Ensure scripts directory exists
    os.makedirs(SCRIPTS_DIR, exist_ok=True)
    
    # Move script files
    for script_file in SCRIPT_FILES:
        source_path = ROOT_DIR / script_file
        target_path = SCRIPTS_DIR / script_file
        
        if source_path.exists():
            print(f"Moving {script_file} to scripts directory")
            shutil.move(str(source_path), str(target_path))
        else:
            print(f"File {script_file} not found, skipping")
    
    # Move test files
    tests_dir = ROOT_DIR / "tests"
    os.makedirs(tests_dir, exist_ok=True)
    
    for test_file in TEST_FILES:
        source_path = ROOT_DIR / test_file
        target_path = tests_dir / test_file
        
        if source_path.exists():
            print(f"Moving {test_file} to tests directory")
            shutil.move(str(source_path), str(target_path))
        else:
            print(f"File {test_file} not found, skipping")
    
    print("File organization completed successfully!")

if __name__ == "__main__":
    move_files()
