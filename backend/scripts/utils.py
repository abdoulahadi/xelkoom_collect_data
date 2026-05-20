#!/usr/bin/env python3
"""
Utility functions for scripts
"""
import os
import sys
from pathlib import Path

def setup_python_path():
    """
    Add the parent directory (backend) to the Python path 
    to allow importing from the 'app' package
    """
    backend_dir = Path(__file__).parent.parent.absolute()
    if str(backend_dir) not in sys.path:
        sys.path.insert(0, str(backend_dir))
    return backend_dir
