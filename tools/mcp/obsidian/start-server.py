#!/usr/bin/env python3
"""
Start Server Script
Starts the Shared Memory Framework Server for Obsidian integration
"""

import os
import sys
import subprocess
import json
import time
import platform
from pathlib import Path
import socket

# Set up paths
SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
SERVER_DIR = SCRIPT_DIR / "server"
CONFIG_FILE = SERVER_DIR / "config.json"
PID_FILE = SCRIPT_DIR / "server.pid"
LOG_FILE = SCRIPT_DIR / "server.log"
VENV_DIR = SCRIPT_DIR / ".venv"

def is_server_running():
    """Check if server is already running"""
    # Try socket connection
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.connect(("localhost", 5678))
        s.close()
        return True
    except (socket.error, ConnectionRefusedError):
        s.close()
        return False

def check_python():
    """Check if Python is installed"""
    try:
        subprocess.run([sys.executable, "--version"], check=True, stdout=subprocess.PIPE)
        return True
    except (subprocess.SubprocessError, FileNotFoundError):
        print("Python 3 is required but not installed. Please install Python 3 and try again.")
        return False

def create_venv():
    """Create virtual environment if it doesn't exist"""
    if not VENV_DIR.exists():
        print("Creating virtual environment...")
        try:
            subprocess.run([sys.executable, "-m", "venv", str(VENV_DIR)], check=True)
        except subprocess.SubprocessError:
            print("Error creating virtual environment.")
            sys.exit(1)
    return True

def install_requirements():
    """Install required packages"""
    print("Installing dependencies...")
    
    # Get pip path based on platform
    if platform.system() == 'Windows':
        pip_path = VENV_DIR / "Scripts" / "pip"
    else:
        pip_path = VENV_DIR / "bin" / "pip"
    
    requirements_file = SERVER_DIR / "requirements.txt"
    
    try:
        subprocess.run([str(pip_path), "install", "-r", str(requirements_file)], check=True)
        return True
    except subprocess.SubprocessError:
        print("Error installing dependencies.")
        return False

def check_config():
    """Check if config exists, prompt for it if not"""
    if not CONFIG_FILE.exists():
        print("Server not configured yet.")
        vault_path = input("Enter the path to your Obsidian vault: ")
        
        # Validate path
        if not os.path.isdir(vault_path):
            print(f"The specified path does not exist: {vault_path}")
            print("Please check the path and try again.")
            return False
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
        
        # Save config
        with open(CONFIG_FILE, 'w') as f:
            json.dump({"vault_path": vault_path}, f)
        print("Configuration saved.")
    
    return True

def start_server():
    """Start the server in the background"""
    print("Starting Shared Memory Framework Server on port 5678...")
    
    # Get python path based on platform
    if platform.system() == 'Windows':
        python_path = VENV_DIR / "Scripts" / "python"
    else:
        python_path = VENV_DIR / "bin" / "python"
    
    # Change to server directory
    os.chdir(SERVER_DIR)
    
    # Start server in background
    try:
        if platform.system() == 'Windows':
            # Windows process creation
            from subprocess import CREATE_NEW_CONSOLE
            process = subprocess.Popen(
                [str(python_path), "app.py"],
                creationflags=CREATE_NEW_CONSOLE,
                stdout=open(LOG_FILE, 'w'),
                stderr=subprocess.STDOUT
            )
        else:
            # Unix-like systems
            process = subprocess.Popen(
                [str(python_path), "app.py"],
                stdout=open(LOG_FILE, 'w'),
                stderr=subprocess.STDOUT,
                start_new_session=True  # Equivalent to nohup
            )
        
        # Save PID to file
        with open(PID_FILE, 'w') as f:
            f.write(str(process.pid))
        
        # Wait a moment to ensure server starts
        time.sleep(2)
        
        # Check if server started successfully
        if is_server_running():
            print("Server started successfully! Available at http://localhost:5678")
            print(f"Server logs available at: {LOG_FILE}")
            return True
        else:
            print(f"Server failed to start. Check logs at {LOG_FILE}")
            return False
            
    except Exception as e:
        print(f"Error starting server: {e}")
        return False

def main():
    """Main function"""
    # Check if server is already running
    if is_server_running():
        print("Shared Memory Framework Server is already running.")
        sys.exit(0)
    
    # Check Python installation
    if not check_python():
        sys.exit(1)
    
    # Setup virtual environment
    if not create_venv():
        sys.exit(1)
    
    # Install requirements
    if not install_requirements():
        sys.exit(1)
    
    # Check/create configuration
    if not check_config():
        sys.exit(1)
    
    # Start the server
    if not start_server():
        sys.exit(1)

if __name__ == "__main__":
    main()