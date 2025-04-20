#!/usr/bin/env python3
import requests
import json
import os
import sys
import argparse
import platform
import subprocess
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Default server URL
SERVER_URL = "http://localhost:5678"
DEFAULT_TIMEOUT = 10  # seconds

# Standard JSON-RPC 2.0 error codes
PARSE_ERROR = -32700
INVALID_REQUEST = -32600
METHOD_NOT_FOUND = -32601
INVALID_PARAMS = -32602
INTERNAL_ERROR = -32603
SERVER_ERROR_START = -32000
SERVER_ERROR_END = -32099

# Create a session with retry logic and connection pooling
session = requests.Session()
retry_strategy = Retry(
    total=3,
    backoff_factor=0.5,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["HEAD", "GET", "POST", "PUT", "DELETE", "OPTIONS", "TRACE"]
)
adapter = HTTPAdapter(max_retries=retry_strategy)
session.mount("http://", adapter)
session.mount("https://", adapter)

def search_notes(query):
    """Search for notes matching the query"""
    try:
        response = session.get(f"{SERVER_URL}/search", params={"query": query}, timeout=DEFAULT_TIMEOUT)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.ConnectionError:
        return {"error": {"code": SERVER_ERROR_START, "message": "Transport error: Could not connect to server"}}
    except requests.exceptions.Timeout:
        return {"error": {"code": SERVER_ERROR_START + 1, "message": "Server timeout"}}
    except requests.exceptions.HTTPError as e:
        return {"error": {"code": SERVER_ERROR_START + 2, "message": f"HTTP error: {e}"}}
    except requests.exceptions.RequestException as e:
        return {"error": {"code": SERVER_ERROR_START + 3, "message": f"Transport error: {str(e)}"}}
    except ValueError as e:  # JSON decode error
        return {"error": {"code": PARSE_ERROR, "message": f"Parse error: {str(e)}"}}

def read_notes(paths):
    """Read one or more notes by path"""
    params = []
    for path in paths:
        params.append(("path", path))
    
    try:
        response = session.get(f"{SERVER_URL}/read", params=params, timeout=DEFAULT_TIMEOUT)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.ConnectionError:
        return {"error": {"code": SERVER_ERROR_START, "message": "Transport error: Could not connect to server"}}
    except requests.exceptions.Timeout:
        return {"error": {"code": SERVER_ERROR_START + 1, "message": "Server timeout"}}
    except requests.exceptions.HTTPError as e:
        return {"error": {"code": SERVER_ERROR_START + 2, "message": f"HTTP error: {e}"}}
    except requests.exceptions.RequestException as e:
        return {"error": {"code": SERVER_ERROR_START + 3, "message": f"Transport error: {str(e)}"}}
    except ValueError as e:  # JSON decode error
        return {"error": {"code": PARSE_ERROR, "message": f"Parse error: {str(e)}"}}

def list_notes(path):
    """List files in a directory"""
    try:
        response = session.get(f"{SERVER_URL}/list", params={"path": path}, timeout=DEFAULT_TIMEOUT)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.ConnectionError:
        return {"error": {"code": SERVER_ERROR_START, "message": "Transport error: Could not connect to server"}}
    except requests.exceptions.Timeout:
        return {"error": {"code": SERVER_ERROR_START + 1, "message": "Server timeout"}}
    except requests.exceptions.HTTPError as e:
        return {"error": {"code": SERVER_ERROR_START + 2, "message": f"HTTP error: {e}"}}
    except requests.exceptions.RequestException as e:
        return {"error": {"code": SERVER_ERROR_START + 3, "message": f"Transport error: {str(e)}"}}
    except ValueError as e:  # JSON decode error
        return {"error": {"code": PARSE_ERROR, "message": f"Parse error: {str(e)}"}}

def write_note(path, content):
    """Write content to a note"""
    data = {
        "path": path,
        "content": content
    }
    
    try:
        response = session.post(f"{SERVER_URL}/write", json=data, timeout=DEFAULT_TIMEOUT)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.ConnectionError:
        return {"error": {"code": SERVER_ERROR_START, "message": "Transport error: Could not connect to server"}}
    except requests.exceptions.Timeout:
        return {"error": {"code": SERVER_ERROR_START + 1, "message": "Server timeout"}}
    except requests.exceptions.HTTPError as e:
        return {"error": {"code": SERVER_ERROR_START + 2, "message": f"HTTP error: {e}"}}
    except requests.exceptions.RequestException as e:
        return {"error": {"code": SERVER_ERROR_START + 3, "message": f"Transport error: {str(e)}"}}
    except ValueError as e:  # JSON decode error
        return {"error": {"code": PARSE_ERROR, "message": f"Parse error: {str(e)}"}}

def check_server():
    """Check if the server is running and configured"""
    try:
        response = session.get(f"{SERVER_URL}/health", timeout=DEFAULT_TIMEOUT)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.ConnectionError:
        return {"status": "error", "message": "Cannot connect to server"}
    except requests.exceptions.Timeout:
        return {"status": "error", "message": "Server timeout"}
    except requests.exceptions.RequestException as e:
        return {"status": "error", "message": f"Request error: {str(e)}"}
    except ValueError as e:  # JSON decode error
        return {"status": "error", "message": f"Invalid server response: {str(e)}"}

def get_capabilities():
    """Get server capabilities"""
    try:
        response = session.get(f"{SERVER_URL}/capabilities", timeout=DEFAULT_TIMEOUT)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.ConnectionError:
        return {"error": {"code": SERVER_ERROR_START, "message": "Transport error: Could not connect to server"}}
    except requests.exceptions.Timeout:
        return {"error": {"code": SERVER_ERROR_START + 1, "message": "Server timeout"}}
    except requests.exceptions.HTTPError as e:
        return {"error": {"code": SERVER_ERROR_START + 2, "message": f"HTTP error: {e}"}}
    except requests.exceptions.RequestException as e:
        return {"error": {"code": SERVER_ERROR_START + 3, "message": f"Transport error: {str(e)}"}}
    except ValueError as e:  # JSON decode error
        return {"error": {"code": PARSE_ERROR, "message": f"Parse error: {str(e)}"}}

def process_single_request(request):
    """Process a single JSON-RPC request"""
    method = request.get("method")
    params = request.get("params", {})
    request_id = request.get("id")
    
    if not method:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {
                "code": INVALID_REQUEST,
                "message": "Invalid Request: Method is required"
            }
        }
    
    result = handle_jsonrpc_method(method, params)
    
    # Check if result contains an error
    if isinstance(result, dict) and "error" in result:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": result["error"]
        }
    else:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": result
        }

def handle_batch_request(operations):
    """Handle batch operations"""
    results = {}
    for operation in operations:
        operation_id = operation.get("id", "")
        method = operation.get("method")
        params = operation.get("params", {})
        
        if not method:
            results[operation_id] = {
                "error": {
                    "code": INVALID_REQUEST,
                    "message": "Invalid operation: Method is required"
                }
            }
            continue
        
        # Execute the operation
        result = handle_jsonrpc_method(method, params)
        results[operation_id] = result
    
    return results

# MCP-compliant JSON-RPC method handler
def handle_jsonrpc_method(method, params=None):
    """Handle a JSON-RPC method according to MCP protocol"""
    if params is None:
        params = {}
    
    # Map method names to functions
    if method == "get":
        if "path" in params:
            paths = [params["path"]]
            result = read_notes(paths)
            if isinstance(result, dict) and "error" in result:
                return result
            return result.get(params["path"], "")
        return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Path parameter required"}}
    
    elif method == "search":
        if "query" in params:
            return search_notes(params["query"])
        return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Query parameter required"}}
    
    elif method == "write":
        if "path" in params and "content" in params:
            return write_note(params["path"], params["content"])
        return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Path and content parameters required"}}
    
    elif method == "list":
        path = params.get("path", "AI/Memory")
        return list_notes(path)
    
    elif method == "batch":
        if "operations" in params and isinstance(params["operations"], list):
            return handle_batch_request(params["operations"])
        return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Operations parameter required as a list"}}
    
    elif method == "capabilities":
        return get_capabilities()
    
    elif method == "status":
        return check_server()
    
    elif method == "python_info":
        # Added to help diagnose Python environment issues
        return {
            "version": sys.version,
            "executable": sys.executable,
            "platform": platform.system(),
            "path": sys.path,
            "env_path": os.environ.get("PATH", "")
        }
    
    else:
        return {"error": {"code": METHOD_NOT_FOUND, "message": f"Method not found: {method}"}}

# MCP JSON-RPC request handler
def handle_jsonrpc(request):
    """Handle JSON-RPC requests from MCP clients"""
    # Validate jsonrpc version
    if not isinstance(request, dict) or request.get("jsonrpc") != "2.0":
        return {
            "jsonrpc": "2.0",
            "id": None,
            "error": {
                "code": INVALID_REQUEST,
                "message": "Invalid Request: jsonrpc must be 2.0"
            }
        }
    
    # Process the request
    return process_single_request(request)

# Special handling for VSCode MCP integration
def create_python_symlink():
    """Create a symlink for python -> python3 if needed and possible"""
    try:
        # Only attempt on MacOS or Linux
        if platform.system() not in ("Darwin", "Linux"):
            return False
        
        # Check if python command exists
        python_exists = os.system("command -v python >/dev/null 2>&1") == 0
        if python_exists:
            return True  # Python already exists
        
        # Check if python3 exists
        python3_exists = os.system("command -v python3 >/dev/null 2>&1") == 0
        if not python3_exists:
            return False  # No python3 either
            
        # Check if we have permission to create symlink
        bin_dir = os.path.expanduser("~/bin")
        if not os.path.exists(bin_dir):
            os.makedirs(bin_dir, exist_ok=True)
            
        # Add to PATH if needed
        if bin_dir not in os.environ.get("PATH", ""):
            with open(os.path.expanduser("~/.bashrc"), "a") as f:
                f.write(f'\n# Added by SMF Tool\nexport PATH="$PATH:{bin_dir}"\n')
                
        # Create the symlink
        python3_path = subprocess.check_output("which python3", shell=True).decode().strip()
        symlink_path = os.path.join(bin_dir, "python")
        if not os.path.exists(symlink_path):
            os.symlink(python3_path, symlink_path)
            
        return os.path.exists(symlink_path)
    except Exception as e:
        print(f"Error creating python symlink: {e}", file=sys.stderr)
        return False

if __name__ == "__main__":
    # Add automatic symlink creation if needed
    create_python_symlink()
    
    # Check if this is a JSON-RPC call from Claude MCP
    if len(sys.argv) > 1 and sys.argv[1] == "--jsonrpc":
        # Read the JSON-RPC request from stdin
        try:
            # Read stdin safely with timeout handling
            request_data = ""
            for line in sys.stdin:
                request_data += line
            
            if not request_data.strip():
                error_response = {
                    "jsonrpc": "2.0",
                    "id": None,
                    "error": {
                        "code": PARSE_ERROR,
                        "message": "Parse error: Empty request"
                    }
                }
                print(json.dumps(error_response))
                sys.exit(1)
                
            request = json.loads(request_data)
            
            # Handle batch requests
            if isinstance(request, list):
                responses = []
                for req in request:
                    responses.append(handle_jsonrpc(req))
                print(json.dumps(responses))
                sys.exit(0)
            
            # Handle single request
            response = handle_jsonrpc(request)
            print(json.dumps(response))
            sys.exit(0)
        except json.JSONDecodeError as e:
            error_response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {
                    "code": PARSE_ERROR,
                    "message": f"Parse error: {str(e)}"
                }
            }
            print(json.dumps(error_response))
            sys.exit(1)
        except Exception as e:
            error_response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {
                    "code": INTERNAL_ERROR,
                    "message": f"Error processing JSON-RPC request: {str(e)}"
                }
            }
            print(json.dumps(error_response))
            sys.exit(1)
    
    # Regular command-line interface
    parser = argparse.ArgumentParser(description="Universal client for Shared Memory Framework Server")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Search command
    search_parser = subparsers.add_parser("search", help="Search for notes")
    search_parser.add_argument("query", help="Search query")
    
    # Read command
    read_parser = subparsers.add_parser("read", help="Read one or more notes")
    read_parser.add_argument("paths", nargs="+", help="Note paths to read")
    
    # List command
    list_parser = subparsers.add_parser("list", help="List files in a directory")
    list_parser.add_argument("--path", default="AI/Memory", help="Directory path to list (default: AI/Memory)")
    
    # Write command
    write_parser = subparsers.add_parser("write", help="Write content to a note")
    write_parser.add_argument("path", help="Note path to write")
    write_parser.add_argument("content", help="Content to write")
    write_parser.add_argument("--file", help="Read content from file instead of argument")
    
    # Status command
    status_parser = subparsers.add_parser("status", help="Check server status")
    
    # Capabilities command
    capabilities_parser = subparsers.add_parser("capabilities", help="Get server capabilities")
    
    # Debug command
    debug_parser = subparsers.add_parser("debug", help="Print debugging information")
    
    args = parser.parse_args()
    
    if args.command == "search":
        results = search_notes(args.query)
        # Handle error format for CLI differently than JSON-RPC
        if isinstance(results, dict) and "error" in results:
            print(f"Error: {results['error'].get('message', 'Unknown error')}")
            sys.exit(1)
        print(json.dumps(results, indent=2))
    
    elif args.command == "read":
        results = read_notes(args.paths)
        # Handle error format for CLI differently than JSON-RPC
        if isinstance(results, dict) and "error" in results:
            print(f"Error: {results['error'].get('message', 'Unknown error')}")
            sys.exit(1)
        print(json.dumps(results, indent=2))
    
    elif args.command == "list":
        path = getattr(args, "path", "AI/Memory")
        results = list_notes(path)
        # Handle error format for CLI differently than JSON-RPC
        if isinstance(results, dict) and "error" in results:
            print(f"Error: {results['error'].get('message', 'Unknown error')}")
            sys.exit(1)
        print(json.dumps(results, indent=2))
    
    elif args.command == "write":
        content = args.content
        if args.file:
            try:
                with open(args.file, 'r') as f:
                    content = f.read()
            except Exception as e:
                print(f"Error reading file: {e}")
                sys.exit(1)
        result = write_note(args.path, content)
        # Handle error format for CLI differently than JSON-RPC
        if isinstance(result, dict) and "error" in result:
            print(f"Error: {result['error'].get('message', 'Unknown error')}")
            sys.exit(1)
        print(json.dumps(result, indent=2))
    
    elif args.command == "status":
        status = check_server()
        if status.get("status") == "error":
            print(f"Error: {status.get('message', 'Unknown error')}")
            sys.exit(1)
        print(json.dumps(status, indent=2))
    
    elif args.command == "capabilities":
        capabilities = get_capabilities()
        if isinstance(capabilities, dict) and "error" in capabilities:
            print(f"Error: {capabilities['error'].get('message', 'Unknown error')}")
            sys.exit(1)
        print(json.dumps(capabilities, indent=2))
        
    elif args.command == "debug":
        debug_info = {
            "python_version": sys.version,
            "python_executable": sys.executable,
            "platform": platform.system(),
            "python_path": sys.path,
            "env_path": os.environ.get("PATH", ""),
            "home_dir": os.path.expanduser("~"),
            "working_dir": os.getcwd(),
            "script_dir": os.path.dirname(os.path.abspath(__file__))
        }
        print(json.dumps(debug_info, indent=2))
    
    else:
        parser.print_help()