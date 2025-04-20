#!/usr/bin/env python3
"""
Stop Server Script
Stops the Shared Memory Framework Server for Obsidian integration
"""

import os
import sys
import subprocess
import platform
import signal
from pathlib import Path

# Set up paths
SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
PID_FILE = SCRIPT_DIR / "server.pid"

def stop_server():
    """Stop the server process"""
    if not PID_FILE.exists():
        print("PID file not found. Server may not be running.")
        # Try to find and kill process anyway
        try:
            if platform.system() == 'Windows':
                subprocess.run("taskkill /f /im python.exe /fi \"WINDOWTITLE eq Shared Memory Framework Server\"", shell=True)
            else:
                subprocess.run("pkill -f 'python.*app.py'", shell=True)
        except subprocess.SubprocessError:
            pass
        return
    
    # Read PID from file
    try:
        with open(PID_FILE, 'r') as f:
            pid = int(f.read().strip())
    except (ValueError, IOError) as e:
        print(f"Error reading PID file: {e}")
        return
    
    print(f"Stopping Shared Memory Framework Server (PID: {pid})...")
    
    # Kill the process
    try:
        if platform.system() == 'Windows':
            subprocess.run(f"taskkill /f /pid {pid}", shell=True)
        else:
            os.kill(pid, signal.SIGTERM)
    except (subprocess.SubprocessError, OSError) as e:
        print(f"Error stopping server: {e}")
        return
    
    # Remove PID file
    try:
        os.remove(PID_FILE)
    except OSError:
        pass
    
    print("Server stopped.")

if __name__ == "__main__":
    stop_server()