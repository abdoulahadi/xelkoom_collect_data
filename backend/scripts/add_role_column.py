#!/usr/bin/env python3
"""
Script to add role column to users table
"""
import sqlite3

def add_role_column():
    conn = sqlite3.connect('xelkoom.db')
    cursor = conn.cursor()
    
    try:
        # Add the role column
        cursor.execute('ALTER TABLE users ADD COLUMN role TEXT DEFAULT "moderator"')
        
        # Update existing admin users to have role = 'admin'
        cursor.execute('UPDATE users SET role = "admin" WHERE is_admin = 1')
        
        conn.commit()
        print("Successfully added role column to users table")
        
        # Verify the column was added
        cursor.execute('PRAGMA table_info(users)')
        columns = cursor.fetchall()
        
        print("\nUpdated columns in users table:")
        for col in columns:
            print(f"  {col[1]} - {col[2]}")
            
        # Show updated user data
        cursor.execute('SELECT id, username, is_admin, role FROM users')
        users = cursor.fetchall()
        
        print("\nUsers with roles:")
        for user in users:
            print(f"  ID: {user[0]}, Username: {user[1]}, is_admin: {user[2]}, role: {user[3]}")
            
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e):
            print("Column role already exists")
        else:
            print(f"Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    add_role_column()
