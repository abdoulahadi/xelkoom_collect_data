#!/usr/bin/env python3
"""
Script to check database structure and data integrity

This script provides functionality to:
1. Check the structure of all tables in the database
2. Verify audio recording metadata and file existence
3. Report inconsistencies in the database
4. Generate summary statistics

Usage:
    python check_db.py [--full] [--validate-audio] [--summary]
    
Arguments:
    --full: Check all tables in the database instead of just recordings
    --validate-audio: Check if audio files exist for each recording entry
    --summary: Generate summary statistics
"""
import os
import sys
import sqlite3
import argparse
from typing import List, Dict, Tuple, Optional
from pathlib import Path

# Define paths relative to the project structure
DATABASE_PATH = '../xelkoom.db'
UPLOADS_DIR = '../uploads/audio'
VALIDATED_DIR = '../audio/validated'

def connect_to_db(db_path: str) -> Tuple[sqlite3.Connection, sqlite3.Cursor]:
    """
    Connect to the SQLite database.
    
    Args:
        db_path: Path to the SQLite database file
        
    Returns:
        Tuple containing connection and cursor objects
    
    Raises:
        sqlite3.Error: If connection to database fails
    """
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        return conn, cursor
    except sqlite3.Error as e:
        print(f"Error connecting to database: {e}")
        sys.exit(1)

def get_table_names(cursor: sqlite3.Cursor) -> List[str]:
    """
    Get all table names from the database.
    
    Args:
        cursor: SQLite cursor
        
    Returns:
        List of table names
    """
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    return [table[0] for table in cursor.fetchall()]

def check_table_structure(cursor: sqlite3.Cursor, table_name: str) -> None:
    """
    Check and print the structure of a table.
    
    Args:
        cursor: SQLite cursor
        table_name: Name of the table to check
    """
    cursor.execute(f'PRAGMA table_info({table_name})')
    columns = cursor.fetchall()
    
    print(f"\nTable: {table_name}")
    print("=" * (len(table_name) + 7))
    print(f"{'Column Name':<20} {'Type':<15} {'Not Null':<10} {'PK':<5} {'Default':<15}")
    print("-" * 65)
    
    for col in columns:
        col_id, name, col_type, not_null, default_val, is_pk = col
        print(f"{name:<20} {col_type:<15} {'Yes' if not_null else 'No':<10} "
              f"{'Yes' if is_pk else 'No':<5} {str(default_val):<15}")

def check_audio_files(cursor: sqlite3.Cursor) -> Dict[str, int]:
    """
    Check if audio files exist for each recording in the database.
    
    Args:
        cursor: SQLite cursor
        
    Returns:
        Dictionary with statistics about audio file validation
    """
    stats = {
        "total_recordings": 0,
        "missing_files": 0,
        "validated_files": 0
    }
    
    # Check if recordings table exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='recordings';")
    if not cursor.fetchone():
        print("Recordings table doesn't exist.")
        return stats
    
    # Get file paths from recordings table
    try:
        cursor.execute("SELECT id, file_path, validated FROM recordings")
        recordings = cursor.fetchall()
        stats["total_recordings"] = len(recordings)
        
        for rec_id, file_path, validated in recordings:
            if not file_path:
                print(f"Warning: Recording with ID {rec_id} has no file path.")
                stats["missing_files"] += 1
                continue
                
            path_to_check = os.path.join(VALIDATED_DIR, file_path) if validated else os.path.join(UPLOADS_DIR, file_path)
            if not os.path.exists(path_to_check):
                print(f"Warning: Audio file for recording ID {rec_id} not found at {path_to_check}")
                stats["missing_files"] += 1
            elif validated:
                stats["validated_files"] += 1
                
    except sqlite3.Error as e:
        print(f"Error checking audio files: {e}")
    
    return stats

def generate_summary(cursor: sqlite3.Cursor) -> None:
    """
    Generate and print summary statistics from the database.
    
    Args:
        cursor: SQLite cursor
    """
    tables = get_table_names(cursor)
    print("\nDatabase Summary")
    print("===============")
    print(f"Total tables: {len(tables)}")
    
    # Count records in each table
    for table in tables:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"Table '{table}': {count} records")
        except sqlite3.Error as e:
            print(f"Error counting records in {table}: {e}")
    
    # Get specific metrics for recordings if table exists
    if 'recordings' in tables:
        try:
            cursor.execute("SELECT COUNT(*) FROM recordings WHERE validated=1")
            validated_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(DISTINCT user_id) FROM recordings")
            unique_users = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(DISTINCT sentence_id) FROM recordings")
            unique_sentences = cursor.fetchone()[0]
            
            print("\nRecordings Statistics:")
            print(f"Validated recordings: {validated_count}")
            print(f"Unique contributors: {unique_users}")
            print(f"Unique sentences recorded: {unique_sentences}")
        except sqlite3.Error as e:
            print(f"Error getting recording statistics: {e}")

def parse_arguments() -> argparse.Namespace:
    """
    Parse command line arguments.
    
    Returns:
        Parsed arguments namespace
    """
    parser = argparse.ArgumentParser(description='Check database structure and integrity')
    parser.add_argument('--full', action='store_true', help='Check all tables in database')
    parser.add_argument('--validate-audio', action='store_true', help='Validate audio file existence')
    parser.add_argument('--summary', action='store_true', help='Generate database summary')
    return parser.parse_args()

def main() -> None:
    """
    Main function to check database structure and integrity
    """
    args = parse_arguments()
    
    # Set up database connection
    db_path = os.path.abspath(os.path.join(os.path.dirname(__file__), DATABASE_PATH))
    conn, cursor = connect_to_db(db_path)
    
    try:
        if args.full:
            # Check structure of all tables
            tables = get_table_names(cursor)
            for table in tables:
                check_table_structure(cursor, table)
        else:
            # Check only recordings table (default behavior)
            check_table_structure(cursor, 'recordings')
        
        if args.validate_audio:
            print("\nValidating audio files...")
            stats = check_audio_files(cursor)
            print(f"\nAudio validation complete:")
            print(f"Total recordings: {stats['total_recordings']}")
            print(f"Missing files: {stats['missing_files']}")
            print(f"Validated files: {stats['validated_files']}")
            
        if args.summary:
            generate_summary(cursor)
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        conn.close()
        print("\nDatabase check complete.")

if __name__ == "__main__":
    main()
