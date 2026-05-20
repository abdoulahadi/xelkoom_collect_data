#!/usr/bin/env python3
"""
Script to update user roles in the database
"""
import sqlite3

def update_user_roles():
    conn = sqlite3.connect('xelkoom.db')
    cursor = conn.cursor()
    
    try:
        # Update all users with role 'moderator' to 'user' (except admin)
        cursor.execute('UPDATE users SET role = "user" WHERE role = "moderator" AND is_admin = 0')
        
        # Keep admin with role 'admin'
        cursor.execute('UPDATE users SET role = "admin" WHERE is_admin = 1')
        
        conn.commit()
        print("Successfully updated user roles")
        
        # Show updated user data
        cursor.execute('SELECT id, username, is_admin, role FROM users')
        users = cursor.fetchall()
        
        print("\nUsers with updated roles:")
        for user in users:
            print(f"  ID: {user[0]}, Username: {user[1]}, is_admin: {user[2]}, role: {user[3]}")
            
    except sqlite3.OperationalError as e:
        print(f"Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    update_user_roles()
