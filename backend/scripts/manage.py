#!/usr/bin/env python3
"""
Utility script that provides common commands for the backend
"""
import argparse
import os
import subprocess
import sys
from pathlib import Path

# Add the backend directory to the Python path
backend_dir = Path(__file__).parent.parent.absolute()
sys.path.insert(0, str(backend_dir))

def run_command(command):
    """Run a system command and print output"""
    print(f"Running: {command}")
    process = subprocess.run(command, shell=True, check=False)
    if process.returncode != 0:
        print(f"Command failed with exit code {process.returncode}")
        return False
    return True

def start_server(args):
    """Start the FastAPI server"""
    os.chdir(backend_dir)
    reload_flag = "--reload" if args.reload else ""
    command = f"python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 {reload_flag}"
    run_command(command)

def create_admin(args):
    """Create an admin user"""
    os.chdir(backend_dir)
    run_command(f"python scripts/create_admin_user.py")

def initialize_db(args):
    """Initialize the database"""
    os.chdir(backend_dir)
    run_command(f"python scripts/init_db.py")

def run_migrations(args):
    """Run database migrations"""
    os.chdir(backend_dir)
    run_command(f"alembic upgrade head")

def add_sample_data(args):
    """Add sample data to the database"""
    os.chdir(backend_dir)
    run_command(f"python scripts/add_sample_sentences.py")

def run_tests(args):
    """Run tests"""
    os.chdir(backend_dir)
    test_dir = "tests"
    if args.test:
        run_command(f"python -m pytest {test_dir}/{args.test} -v")
    else:
        run_command(f"python -m pytest {test_dir} -v")

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Xelkoom Backend Management Tool")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Start server command
    start_parser = subparsers.add_parser("start", help="Start the FastAPI server")
    start_parser.add_argument("--reload", action="store_true", help="Enable auto-reload")
    start_parser.set_defaults(func=start_server)
    
    # Create admin command
    admin_parser = subparsers.add_parser("admin", help="Create an admin user")
    admin_parser.set_defaults(func=create_admin)
    
    # Init DB command
    init_db_parser = subparsers.add_parser("init-db", help="Initialize the database")
    init_db_parser.set_defaults(func=initialize_db)
    
    # Run migrations command
    migrations_parser = subparsers.add_parser("migrate", help="Run database migrations")
    migrations_parser.set_defaults(func=run_migrations)
    
    # Add sample data command
    sample_data_parser = subparsers.add_parser("sample-data", help="Add sample data to the database")
    sample_data_parser.set_defaults(func=add_sample_data)
    
    # Run tests command
    test_parser = subparsers.add_parser("test", help="Run tests")
    test_parser.add_argument("--test", help="Specific test file to run")
    test_parser.set_defaults(func=run_tests)
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        return
    
    args.func(args)

if __name__ == "__main__":
    main()
