#!/usr/bin/env python3
"""
Configure Script
Configures the Shared Memory Framework Server for Obsidian integration
"""

import os
import json
import sys
from pathlib import Path

# Set up paths
SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
SERVER_DIR = SCRIPT_DIR / "server"
CONFIG_FILE = SERVER_DIR / "config.json"

def configure_server():
    """Configure the server settings"""
    print("Shared Memory Framework Server Configuration")
    print("===========================================")
    print()
    
    # Check if config exists
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, 'r') as f:
                config = json.load(f)
                print(f"Current vault path: {config.get('vault_path', 'Not set')}")
        except (json.JSONDecodeError, IOError):
            print("Current configuration is invalid or corrupted.")
    
    # Prompt for vault path
    vault_path = input("Enter the path to your Obsidian vault (press Enter to keep current): ").strip()
    
    if not vault_path:
        print("No changes made to configuration.")
        return
    
    # Validate path
    if not os.path.isdir(vault_path):
        print(f"Error: The specified path does not exist: {vault_path}")
        return
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
    
    # Save config
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump({"vault_path": vault_path}, f)
        print("Configuration saved successfully.")
    except IOError as e:
        print(f"Error saving configuration: {e}")

if __name__ == "__main__":
    configure_server()