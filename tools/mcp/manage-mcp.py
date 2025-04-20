#!/usr/bin/env python3
"""
Shared Memory Framework Management Tool
A cross-platform tool for managing the Shared Memory Framework
Supports both web server and stdio-based MCP communication
"""

import os
import sys
import subprocess
import json
import argparse
import platform
import shutil
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
STDIO_WRAPPER = SERVER_DIR / "stdio_wrapper.py"

# Load environment variables
load_dotenv(ENV_FILE)
SERVER_LOG_FILE = os.getenv("MCP_LOG_FILE", OBSIDIAN_DIR / "server.log")
MCP_PORT = int(os.getenv("MCP_PORT", 5678))
MCP_HOST = os.getenv("MCP_HOST", "0.0.0.0")
MCP_MODE = os.getenv("MCP_MODE", "sse") # Can be 'sse', 'stdio', or 'both'

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
    """Start the Shared Memory Framework Server in SSE mode"""
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
    colored_print(f"Starting Shared Memory Framework Server in SSE mode on port {MCP_PORT}...", Colors.BLUE)
    
    try:
        # Change to server directory
        os.chdir(SERVER_DIR)
        
        # Set environment variable to indicate SSE mode
        env = os.environ.copy()
        env["MCP_MODE"] = "sse"
        
        # Start server as a background process
        if platform.system() == 'Windows':
            # Windows process creation
            from subprocess import CREATE_NEW_CONSOLE
            process = subprocess.Popen(
                [str(python_path), "app.py"],
                creationflags=CREATE_NEW_CONSOLE,
                stdout=open(SERVER_LOG_FILE, 'w'),
                stderr=subprocess.STDOUT,
                env=env
            )
        else:
            # Unix-like systems
            process = subprocess.Popen(
                [str(python_path), "app.py"],
                stdout=open(SERVER_LOG_FILE, 'w'),
                stderr=subprocess.STDOUT,
                start_new_session=True,  # Equivalent to nohup
                env=env
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
            response = requests.get(f"http://localhost:{MCP_PORT}/health", timeout=5)
            if response.status_code == 200:
                colored_print(f"Server started successfully! Available at http://localhost:{MCP_PORT}", Colors.GREEN)
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
    
    # Server information only
    print()

def repair_mcp():
    """Check and repair MCP connectivity issues"""
    colored_print(f"{Colors.BOLD}MCP Server Repair{Colors.NC}")
    print()
    
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
                colored_print("\n✅ JSON-RPC test passed. MCP server should be working correctly.", Colors.GREEN)
            else:
                colored_print("\n❌ JSON-RPC test failed. MCP server might not work correctly.", Colors.RED)
                if "Server not configured" in result.stdout:
                    colored_print("The server is not configured. Please run 'python manage-mcp.py configure'", Colors.YELLOW)
        else:
            colored_print(f"❌ SMF CLI not found at {smf_path}", Colors.RED)
    except Exception as e:
        colored_print(f"❌ Error testing JSON-RPC: {e}", Colors.RED)
    
    print()
    colored_print(f"{Colors.BOLD}Next steps:{Colors.NC}")
    print("1. Make sure the server is properly configured")
    print("2. Restart the server if needed with 'python ./tools/mcp/manage-mcp.py start'")

def start_stdio_server():
    """Start the MCP server in stdio mode (for VS Code direct integration)"""
    colored_print("Starting Shared Memory Framework Server in stdio mode...", Colors.BLUE)
    
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
    
    # Set environment variable to indicate stdio mode
    env = os.environ.copy()
    env["MCP_MODE"] = "stdio"
    
    # Execute the app.py script directly with stdio mode environment variable
    # The script will take over stdin/stdout for JSON-RPC communication
    os.chdir(SERVER_DIR)  # Change to server directory
    os.execve(str(python_path), [str(python_path), "app.py"], env)

def generate_vscode_config():
    """Generate VS Code configuration files for MCP integration"""
    colored_print("Generating VS Code configuration for MCP...", Colors.BLUE)
    
    # Create .vscode directory if it doesn't exist
    vscode_dir = Path(os.getcwd()) / ".vscode"
    os.makedirs(vscode_dir, exist_ok=True)
    
    # Create mcp.json configuration with both SSE and stdio options
    # Determine Python path based on platform
    if platform.system() == 'Windows':
        python_path = str(VENV_DIR / "Scripts" / "python")
    else:
        python_path = str(VENV_DIR / "bin" / "python")
    
    mcp_config = {
        "servers": {
            "SMF Knowledge Server (SSE)": {
                "type": "sse",
                "url": f"http://localhost:{MCP_PORT}/sse"
            }
        }
    }
    
    with open(vscode_dir / "mcp.json", 'w') as f:
        json.dump(mcp_config, f, indent=2)
    
    colored_print(f"VS Code MCP configuration created at {vscode_dir / 'mcp.json'}", Colors.GREEN)
    
    # Create stdio-specific config
    stdio_config = {
        "servers": {
            "SMF Knowledge Server (stdio)": {
                "type": "stdio",
                "command": python_path,
                "args": [str(SERVER_DIR / "app.py")],
                "env": {
                    "MCP_MODE": "stdio"
                }
            }
        }
    }
    
    with open(vscode_dir / "mcp-stdio.json", 'w') as f:
        json.dump(stdio_config, f, indent=2)
    
    colored_print(f"VS Code stdio configuration created at {vscode_dir / 'mcp-stdio.json'}", Colors.GREEN)
    
    # Create combined config with both options
    combined_config = {
        "servers": {
            "SMF Knowledge Server (SSE)": {
                "type": "sse",
                "url": f"http://localhost:{MCP_PORT}/sse"
            },
            "SMF Knowledge Server (stdio)": {
                "type": "stdio",
                "command": python_path,
                "args": [str(SERVER_DIR / "app.py")],
                "env": {
                    "MCP_MODE": "stdio"
                }
            }
        }
    }
    
    with open(vscode_dir / "mcp-combined.json", 'w') as f:
        json.dump(combined_config, f, indent=2)
    
    colored_print(f"VS Code combined configuration created at {vscode_dir / 'mcp-combined.json'}", Colors.GREEN)
    colored_print("You can choose which configuration to use by copying the desired file to mcp.json", Colors.BLUE)

def config_copilot():
    """Generate a GitHub Copilot-specific VS Code configuration"""
    colored_print("Generating GitHub Copilot configuration for VS Code...", Colors.BLUE)
    
    # Create .vscode directory if it doesn't exist
    vscode_dir = Path(os.getcwd()) / ".vscode"
    os.makedirs(vscode_dir, exist_ok=True)
    
    # Determine Python path based on platform
    if platform.system() == 'Windows':
        python_path = str(VENV_DIR / "Scripts" / "python")
    else:
        python_path = str(VENV_DIR / "bin" / "python")
    
    # Create GitHub Copilot optimized configuration
    copilot_config = {
        "servers": {
            "SMF Knowledge Server": {
                "type": "stdio",
                "command": python_path,
                "args": [str(SERVER_DIR / "app.py")],
                "env": {
                    "MCP_MODE": "stdio",
                    "PYTHONUNBUFFERED": "1"
                }
            }
        }
    }
    
    # Write the GitHub Copilot configuration
    with open(vscode_dir / "mcp-copilot.json", 'w') as f:
        json.dump(copilot_config, f, indent=2)
    
    colored_print(f"GitHub Copilot configuration created at {vscode_dir / 'mcp-copilot.json'}", Colors.GREEN)
    colored_print("To use this configuration, copy it to mcp.json:", Colors.BLUE)
    colored_print(f"  cp {vscode_dir / 'mcp-copilot.json'} {vscode_dir / 'mcp.json'}", Colors.NC)

def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="Shared Memory Framework Management Tool"
    )
    parser.add_argument("command", nargs="?", 
                      choices=["start", "stop", "status", "configure", "repair", "stdio", 
                               "config-vscode", "config-copilot", "help"],
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
    elif args.command == "stdio":
        start_stdio_server()
    elif args.command == "config-vscode":
        generate_vscode_config()
    elif args.command == "config-copilot":
        config_copilot()
    else:  # help
        parser.print_help()
        print("\nExamples:")
        print("  manage-mcp.py start         # Start the Shared Memory Framework Server (HTTP/SSE)")
        print("  manage-mcp.py stdio         # Start the server in stdio mode (for VS Code)")
        print("  manage-mcp.py config-vscode # Generate VS Code configuration files")
        print("  manage-mcp.py config-copilot # Generate GitHub Copilot configuration for VS Code")
        print("  manage-mcp.py status        # Check status of running servers")
        print("  manage-mcp.py repair        # Check and repair MCP connectivity issues")

if __name__ == "__main__":
    main()