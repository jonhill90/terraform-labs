#!/usr/bin/env python3
"""
Shared Memory Framework Management Tool
A cross-platform tool for managing the Shared Memory Framework
"""

import os
import sys
import subprocess
import json
import argparse
import platform
from pathlib import Path
try:
    from dotenv import load_dotenv, set_key
except ImportError:
    # If dotenv is not available, provide fallback implementation
    def load_dotenv(path):
        if not os.path.exists(path):
            return False
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or '=' not in line:
                    continue
                key, value = line.split('=', 1)
                os.environ[key] = value
        return True
    
    def set_key(path, key, value):
        if not os.path.exists(path):
            with open(path, 'w') as f:
                f.write(f"{key}={value}\n")
            return
        
        lines = []
        found = False
        if os.path.exists(path):
            with open(path) as f:
                for line in f:
                    if line.strip() and not line.startswith('#') and '=' in line:
                        k, v = line.split('=', 1)
                        if k.strip() == key:
                            lines.append(f"{key}={value}\n")
                            found = True
                        else:
                            lines.append(line)
                    else:
                        lines.append(line)
        
        if not found:
            lines.append(f"{key}={value}\n")
        
        with open(path, 'w') as f:
            f.writelines(lines)

# Set up paths
SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
ENV_FILE = SCRIPT_DIR / ".env"
OBSIDIAN_DIR = SCRIPT_DIR / "obsidian"
SERVER_DIR = OBSIDIAN_DIR / "server"
CONFIG_FILE = SERVER_DIR / "config.json"
VENV_DIR = OBSIDIAN_DIR / ".venv"
UNIVERSAL_CLIENT = OBSIDIAN_DIR / "adapters" / "universal_client.py"

# Load environment variables
load_dotenv(ENV_FILE)
SERVER_LOG_FILE = os.getenv("MCP_LOG_FILE", OBSIDIAN_DIR / "server.log")
MCP_PORT = int(os.getenv("MCP_PORT", 5678))
MCP_HOST = os.getenv("MCP_HOST", "0.0.0.0")

# Terminal colors
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[0;33m'
    BLUE = '\033[0;34m'
    BOLD = '\033[1m'
    NC = '\033[0m'  # No Color

def colored_print(message, color=None, bold=False):
    """Print with color and formatting"""
    prefix = ""
    if bold:
        prefix += Colors.BOLD
    if color:
        prefix += color
    
    if prefix:
        print(f"{prefix}{message}{Colors.NC}")
    else:
        print(message)

def run_python_script(script_path, args=None):
    """Run a Python script with the appropriate interpreter"""
    if args is None:
        args = []
    
    # Try system interpreter first
    python_cmd = sys.executable
    cmd = [python_cmd, str(script_path)] + args
    
    try:
        return subprocess.run(cmd, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        # If it fails, try python3 command
        try:
            cmd[0] = 'python3'
            return subprocess.run(cmd, check=True, capture_output=True, text=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            # If that fails, try python command
            try:
                cmd[0] = 'python'
                return subprocess.run(cmd, check=True, capture_output=True, text=True)
            except (subprocess.CalledProcessError, FileNotFoundError):
                colored_print(f"Error executing {script_path}: {e}", Colors.RED)
                sys.exit(1)

def is_server_running():
    """Check if the server is running"""
    # First, try socket connection
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.connect(("localhost", MCP_PORT))
        s.close()
        return True
    except (socket.error, ConnectionRefusedError):
        s.close()
        
        # If socket connection fails, check saved PID as fallback
        try:
            pid = int(os.getenv("MCP_PID", 0))
            if pid <= 0:
                return False
            
            # Check if process is running
            if platform.system() == 'Windows':
                try:
                    # Windows-specific process check
                    subprocess.check_output(f"tasklist /FI \"PID eq {pid}\"", shell=True)
                    return True
                except subprocess.CalledProcessError:
                    return False
            else:
                # Unix-like systems
                try:
                    os.kill(pid, 0)  # Signal 0 is a no-op, just checks if process exists
                    return True
                except OSError:
                    return False
        except (ValueError, TypeError):
            return False

def create_virtual_env():
    """Create a virtual environment if it doesn't exist"""
    if not VENV_DIR.exists():
        colored_print("Creating virtual environment...", Colors.BLUE)
        
        # Create venv
        try:
            subprocess.run([sys.executable, "-m", "venv", str(VENV_DIR)], check=True)
        except subprocess.CalledProcessError:
            try:
                # Try with python3 if default python fails
                subprocess.run(["python3", "-m", "venv", str(VENV_DIR)], check=True)
            except (subprocess.CalledProcessError, FileNotFoundError):
                colored_print("Error: Failed to create virtual environment.", Colors.RED)
                sys.exit(1)
    
    # Install requirements
    colored_print("Installing dependencies...", Colors.BLUE)
    
    # Determine pip path based on platform
    if platform.system() == 'Windows':
        pip_path = VENV_DIR / "Scripts" / "pip"
    else:
        pip_path = VENV_DIR / "bin" / "pip"
    
    requirements_file = SERVER_DIR / "requirements.txt"
    try:
        # Install requests first (needed for health checks)
        subprocess.run([str(pip_path), "install", "requests"], check=True)
        # Install other requirements
        subprocess.run([str(pip_path), "install", "-r", str(requirements_file)], check=True)
    except subprocess.CalledProcessError:
        colored_print("Error: Failed to install dependencies.", Colors.RED)
        sys.exit(1)

def configure_server():
    """Configure the server settings"""
    colored_print(f"{Colors.BOLD}Configure Shared Memory Framework{Colors.NC}")
    print()
    
    # Check if config exists
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, 'r') as f:
                config = json.load(f)
                colored_print(f"Current vault path: {config.get('vault_path', 'Not set')}", Colors.BLUE)
        except (json.JSONDecodeError, IOError):
            colored_print("Current configuration is invalid or corrupted.", Colors.YELLOW)
    
    # Prompt for vault path
    vault_path = input("Enter the path to your Obsidian vault (press Enter to keep current): ").strip()
    
    if not vault_path:
        colored_print("No changes made to configuration.", Colors.YELLOW)
        return
    
    # Validate path
    if not os.path.isdir(vault_path):
        colored_print(f"Error: The specified path does not exist: {vault_path}", Colors.RED)
        return
    
    # Save config
    try:
        os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
        with open(CONFIG_FILE, 'w') as f:
            json.dump({"vault_path": vault_path}, f)
        colored_print("Configuration saved successfully.", Colors.GREEN)
    except IOError as e:
        colored_print(f"Error saving configuration: {e}", Colors.RED)

def start_server():
    """Start the Shared Memory Framework Server"""
    if is_server_running():
        colored_print("Shared Memory Framework Server is already running.", Colors.YELLOW)
        return
    
    # Create virtual environment and install dependencies
    create_virtual_env()
    
    # Check if config exists
    if not CONFIG_FILE.exists():
        colored_print("Server not configured yet.", Colors.YELLOW)
        configure_server()
        if not CONFIG_FILE.exists():
            colored_print("Server configuration is required before starting.", Colors.RED)
            return
    
    # Determine python path based on platform
    if platform.system() == 'Windows':
        python_path = VENV_DIR / "Scripts" / "python"
    else:
        python_path = VENV_DIR / "bin" / "python"
    
    # Start the server
    colored_print("Starting Shared Memory Framework Server on port 5678...", Colors.BLUE)
    
    try:
        # Change to server directory
        os.chdir(SERVER_DIR)
        
        # Start server as a background process
        if platform.system() == 'Windows':
            # Windows process creation
            from subprocess import CREATE_NEW_CONSOLE
            process = subprocess.Popen(
                [str(python_path), "app.py"],
                creationflags=CREATE_NEW_CONSOLE,
                stdout=open(SERVER_LOG_FILE, 'w'),
                stderr=subprocess.STDOUT
            )
        else:
            # Unix-like systems
            process = subprocess.Popen(
                [str(python_path), "app.py"],
                stdout=open(SERVER_LOG_FILE, 'w'),
                stderr=subprocess.STDOUT,
                start_new_session=True  # Equivalent to nohup
            )
        
        # Save PID to env file
        set_key(ENV_FILE, "MCP_PID", str(process.pid))
        
        # Wait a moment to ensure server starts
        import time
        time.sleep(2)
        
        # Check if server started successfully
        try:
            # Import requests inside try block to ensure it's available
            import requests
            response = requests.get("http://localhost:5678/health", timeout=5)
            if response.status_code == 200:
                colored_print("Server started successfully! Available at http://localhost:5678", Colors.GREEN)
                colored_print(f"Server logs available at: {SERVER_LOG_FILE}", Colors.BLUE)
            else:
                colored_print(f"Server started but returned status code {response.status_code}", Colors.YELLOW)
        except Exception as e:
            colored_print(f"Server may have failed to start. Check logs at {SERVER_LOG_FILE}: {e}", Colors.RED)
    
    except Exception as e:
        colored_print(f"Error starting server: {e}", Colors.RED)

def stop_server():
    """Stop the Shared Memory Framework Server"""
    colored_print("Stopping Shared Memory Framework Server...", Colors.BLUE)
    
    # Get PID from env file
    try:
        pid = int(os.getenv("MCP_PID", 0))
        if pid <= 0:
            colored_print("No valid PID found. Server may not be running.", Colors.YELLOW)
            # Try to find and kill process anyway
            try:
                if platform.system() == 'Windows':
                    subprocess.run("taskkill /f /im python.exe /fi \"WINDOWTITLE eq Shared Memory Framework Server\"", shell=True)
                else:
                    subprocess.run("pkill -f 'python.*app.py'", shell=True)
            except subprocess.SubprocessError:
                pass
            return
        
        colored_print(f"Stopping Shared Memory Framework Server (PID: {pid})...", Colors.BLUE)
        
        # Kill the process
        try:
            if platform.system() == 'Windows':
                subprocess.run(f"taskkill /f /pid {pid}", shell=True)
            else:
                import signal
                os.kill(pid, signal.SIGTERM)
        except (subprocess.SubprocessError, OSError) as e:
            colored_print(f"Error stopping server: {e}", Colors.RED)
            return
        
        # Reset PID in env file
        set_key(ENV_FILE, "MCP_PID", "0")
        
        colored_print("Server stopped.", Colors.GREEN)
    except (ValueError, TypeError):
        colored_print("Invalid PID format in environment settings.", Colors.RED)

def check_status():
    """Check the status of all knowledge connectors"""
    colored_print(f"{Colors.BOLD}Shared Memory Framework Status{Colors.NC}")
    print()
    
    # Check Obsidian connector
    colored_print(f"{Colors.BOLD}Obsidian Connector:{Colors.NC}")
    
    server_running = is_server_running()
    if server_running:
        colored_print("  Status: Running", Colors.GREEN)
        
        # Get server health
        try:
            # Use curl instead of requests to check health
            result = subprocess.run(["curl", "-s", "http://localhost:5678/health"], 
                                  capture_output=True, text=True, check=False)
            if result.returncode == 0 and "healthy" in result.stdout:
                colored_print("  Health: Healthy", Colors.GREEN)
                colored_print("  URL: http://localhost:5678")
            else:
                colored_print("  Health: Not responding properly", Colors.RED)
        except Exception as e:
            colored_print(f"  Health: Not responding - {e}", Colors.RED)
    else:
        colored_print("  Status: Not running", Colors.RED)
    
    print()
    
    # Check Claude MCP integration
    colored_print(f"{Colors.BOLD}Claude MCP Integration:{Colors.NC}")
    
    # Check if claude CLI is installed
    claude_installed = False
    try:
        subprocess.run(["claude", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        claude_installed = True
    except (subprocess.SubprocessError, FileNotFoundError):
        pass
    
    if claude_installed:
        # Check if MCP is registered
        try:
            result = subprocess.run(["claude", "mcp", "list"], 
                                 capture_output=True, text=True, check=False)
            if "obsidian" in result.stdout:
                colored_print("  Status: Registered", Colors.GREEN)
            else:
                colored_print("  Status: Not registered", Colors.YELLOW)
                client_path = SCRIPT_DIR / "obsidian" / "adapters" / "universal_client.py"
                colored_print(f"  Note: Run '{Colors.BOLD}claude mcp add obsidian -- python {client_path}{Colors.NC}' to register")
        except subprocess.SubprocessError:
            colored_print("  Status: Error checking MCP registration", Colors.RED)
    else:
        colored_print("  Status: Claude CLI not installed", Colors.YELLOW)

def repair_mcp():
    """Check and repair MCP connectivity issues"""
    colored_print(f"{Colors.BOLD}MCP Connectivity Repair{Colors.NC}")
    print()
    
    # First, check if Claude CLI is installed
    claude_installed = False
    try:
        subprocess.run(["claude", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        claude_installed = True
    except (subprocess.SubprocessError, FileNotFoundError):
        colored_print("❌ Claude CLI not installed. You need to install the Claude CLI first.", Colors.RED)
        print("Visit https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview for installation instructions.")
        return
    
    # Check if server is running
    server_running = is_server_running()
    if not server_running:
        colored_print("❌ Server not running. Starting server...", Colors.YELLOW)
        start_server()
        server_running = is_server_running()
    
    if server_running:
        colored_print("✅ Server is running", Colors.GREEN)
    else:
        colored_print("❌ Failed to start server", Colors.RED)
        return
    
    # Check MCP registration
    mcp_registered = False
    try:
        result = subprocess.run(["claude", "mcp", "list"], 
                             capture_output=True, text=True, check=False)
        mcp_registered = "obsidian" in result.stdout
    except subprocess.SubprocessError:
        pass
    
    if not mcp_registered:
        colored_print("❌ MCP not registered with Claude. Attempting to register...", Colors.YELLOW)
        client_path = SCRIPT_DIR / "obsidian" / "adapters" / "universal_client.py"
        
        try:
            result = subprocess.run(
                ["claude", "mcp", "add", "obsidian", "--", sys.executable, str(client_path), "--jsonrpc"],
                capture_output=True, text=True, check=False
            )
            
            if "successfully" in result.stdout.lower():
                colored_print("✅ MCP registered successfully", Colors.GREEN)
            else:
                colored_print(f"❌ Failed to register MCP: {result.stdout}", Colors.RED)
                colored_print(f"Error: {result.stderr}", Colors.RED)
        except subprocess.SubprocessError as e:
            colored_print(f"❌ Error registering MCP: {e}", Colors.RED)
    else:
        colored_print("✅ MCP already registered", Colors.GREEN)
    
    # Test JSON-RPC functionality
    colored_print("\nTesting JSON-RPC functionality...", Colors.BLUE)
    try:
        # Find path to smf.py
        smf_path = SCRIPT_DIR / "smf.py"
        
        if os.path.exists(smf_path):
            result = subprocess.run(
                [sys.executable, smf_path, "test-jsonrpc"],
                capture_output=True, text=True, check=False
            )
            print(result.stdout)
            
            if "Test passed" in result.stdout:
                colored_print("\n✅ JSON-RPC test passed. MCP should be working correctly.", Colors.GREEN)
            else:
                colored_print("\n❌ JSON-RPC test failed. MCP might not work correctly.", Colors.RED)
                if "Server not configured" in result.stdout:
                    colored_print("The server is not configured. Please run 'python manage-mcp.py configure'", Colors.YELLOW)
        else:
            colored_print(f"❌ SMF CLI not found at {smf_path}", Colors.RED)
    except Exception as e:
        colored_print(f"❌ Error testing JSON-RPC: {e}", Colors.RED)
    
    print()
    colored_print(f"{Colors.BOLD}Next steps:{Colors.NC}")
    print("1. Restart your terminal or Claude Code session")
    print("2. Use the '/mcp' command in Claude Code to verify connectivity")
    print("3. If issues persist, try 'claude mcp remove obsidian' and then run repair again")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="Shared Memory Framework Management Tool"
    )
    parser.add_argument("command", nargs="?", choices=["start", "stop", "status", "configure", "repair", "help"],
                      default="help", help="Command to run")
    
    args = parser.parse_args()
    
    if args.command == "start":
        start_server()
    elif args.command == "stop":
        stop_server()
    elif args.command == "status":
        check_status()
    elif args.command == "configure":
        configure_server()
    elif args.command == "repair":
        repair_mcp()
    else:  # help
        parser.print_help()
        print("\nExamples:")
        print("  manage-mcp.py start    # Start the Shared Memory Framework Server")
        print("  manage-mcp.py status   # Check status of running servers")
        print("  manage-mcp.py repair   # Check and repair MCP connectivity issues")

if __name__ == "__main__":
    main()