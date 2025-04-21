#!/usr/bin/env python3
import requests
import json
import os
import sys
import argparse
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Default server URL
SERVER_URL = "http://localhost:5678"
DEFAULT_TIMEOUT = 10  # seconds

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
        return {"error": {"code": -32003, "message": "Transport error: Could not connect to server"}}
    except requests.exceptions.Timeout:
        return {"error": {"code": -32002, "message": "Server timeout"}}
    except requests.exceptions.HTTPError as e:
        return {"error": {"code": -32001, "message": f"HTTP error: {e}"}}
    except requests.exceptions.RequestException as e:
        return {"error": {"code": -32000, "message": f"Transport error: {str(e)}"}}
    except ValueError as e:  # JSON decode error
        return {"error": {"code": -32700, "message": f"Parse error: {str(e)}"}}

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
        return {"error": {"code": -32003, "message": "Transport error: Could not connect to server"}}
    except requests.exceptions.Timeout:
        return {"error": {"code": -32002, "message": "Server timeout"}}
    except requests.exceptions.HTTPError as e:
        return {"error": {"code": -32001, "message": f"HTTP error: {e}"}}
    except requests.exceptions.RequestException as e:
        return {"error": {"code": -32000, "message": f"Transport error: {str(e)}"}}
    except ValueError as e:  # JSON decode error
        return {"error": {"code": -32700, "message": f"Parse error: {str(e)}"}}

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
        return {"error": {"code": -32003, "message": "Transport error: Could not connect to server"}}
    except requests.exceptions.Timeout:
        return {"error": {"code": -32002, "message": "Server timeout"}}
    except requests.exceptions.HTTPError as e:
        return {"error": {"code": -32001, "message": f"HTTP error: {e}"}}
    except requests.exceptions.RequestException as e:
        return {"error": {"code": -32000, "message": f"Transport error: {str(e)}"}}
    except ValueError as e:  # JSON decode error
        return {"error": {"code": -32700, "message": f"Parse error: {str(e)}"}}

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

# Claude MCP API compatibility functions
def handle_jsonrpc(method, params=None):
    """Handle JSON-RPC requests from Claude MCP"""
    try:
        if params is None:
            params = {}
            
        if method == "get":
            if "path" in params:
                paths = [params["path"]]
                result = read_notes(paths)
                if isinstance(result, dict) and "error" in result:
                    return result
                # Handle case where result is not a dictionary or doesn't contain the path
                if not isinstance(result, dict):
                    return {"error": {"code": -32000, "message": f"Unexpected result format: {type(result)}"}}
                return result.get(params["path"], "")
            return {"error": {"code": -32602, "message": "Invalid params: Path parameter required"}}
        elif method == "search":
            if "query" in params:
                return search_notes(params["query"])
            return {"error": {"code": -32602, "message": "Invalid params: Query parameter required"}}
        elif method == "write":
            if "path" in params and "content" in params:
                return write_note(params["path"], params["content"])
            return {"error": {"code": -32602, "message": "Invalid params: Path and content parameters required"}}
        else:
            return {"error": {"code": -32601, "message": f"Method not found: {method}"}}
    except Exception as e:
        return {"error": {"code": -32000, "message": f"Internal error: {str(e)}"}}

if __name__ == "__main__":
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
                        "code": -32700,
                        "message": "Parse error: Empty request"
                    }
                }
                print(json.dumps(error_response))
                sys.exit(1)
                
            request = json.loads(request_data)
            method = request.get("method")
            params = request.get("params", {})
            request_id = request.get("id")
            
            if method is None:
                error_response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {
                        "code": -32600,
                        "message": "Invalid Request: Method is required"
                    }
                }
                print(json.dumps(error_response))
                sys.exit(1)
            
            result = handle_jsonrpc(method, params)
            
            # Check if result contains an error
            if isinstance(result, dict) and "error" in result:
                error_response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": result["error"]
                }
                print(json.dumps(error_response))
            else:
                response = {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": result
                }
                print(json.dumps(response))
            sys.exit(0)
        except json.JSONDecodeError as e:
            error_response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {
                    "code": -32700,
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
                    "code": -32000,
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
    
    # Write command
    write_parser = subparsers.add_parser("write", help="Write content to a note")
    write_parser.add_argument("path", help="Note path to write")
    write_parser.add_argument("content", help="Content to write")
    write_parser.add_argument("--file", help="Read content from file instead of argument")
    
    # Status command
    status_parser = subparsers.add_parser("status", help="Check server status")
    
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
    
    else:
        parser.print_help()