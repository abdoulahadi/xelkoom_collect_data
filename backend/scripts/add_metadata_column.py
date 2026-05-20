#!/usr/bin/env python3
"""
Script to add audio_metadata column to recordings table
"""
import sqlite3

def add_audio_metadata_column():
    conn = sqlite3.connect('xelkoom.db')
    cursor = conn.cursor()
    
    try:
        # Add the audio_metadata column
        cursor.execute('ALTER TABLE recordings ADD COLUMN audio_metadata TEXT')
        conn.commit()
        print("Successfully added audio_metadata column to recordings table")
        
        # Verify the column was added
        cursor.execute('PRAGMA table_info(recordings)')
        columns = cursor.fetchall()
        
        print("\nUpdated columns in recordings table:")
        for col in columns:
            print(f"  {col[1]} - {col[2]}")
            
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("Column audio_metadata already exists")
        else:
            print(f"Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    add_audio_metadata_column()
