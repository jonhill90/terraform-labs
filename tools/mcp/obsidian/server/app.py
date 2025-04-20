#!/usr/bin/env python3
import os
import json
import re
import sys
import time
from flask import Flask, request, jsonify
from flask_cors import CORS

# Configuration - will be loaded from config file or environment variables
DEFAULT_PORT = 5678

# Standard JSON-RPC error codes
PARSE_ERROR = -32700
INVALID_REQUEST = -32600
METHOD_NOT_FOUND = -32601
INVALID_PARAMS = -32602
INTERNAL_ERROR = -32603
SERVER_ERROR_START = -32000
SERVER_ERROR_END = -32099

app = Flask(__name__)
# Enable CORS for all routes with explicit settings for better VS Code compatibility
CORS(app, resources={r"/*": {"origins": "*", "methods": ["GET", "POST", "OPTIONS"], "allow_headers": "*"}})

# Add a special route to handle CORS preflight requests directly
@app.route('/', methods=['OPTIONS'])
@app.route('/<path:path>', methods=['OPTIONS'])
def cors_preflight(path=None):
    """Handle CORS preflight requests for all routes"""
    response = app.make_default_options_response()
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = '*'
    return response

# Add CORS headers to every response
@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    return response

# Global config that will be loaded at startup
config = {
    "vault_path": None,
    "memory_path": None
}

def load_config():
    """Load configuration from file or environment variables"""
    # First try environment variables
    vault_path = os.environ.get('OBSIDIAN_VAULT_PATH')
    
    # Then try config file
    config_path = os.path.join(os.path.dirname(__file__), 'config.json')
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                file_config = json.load(f)
                if 'vault_path' in file_config:
                    vault_path = file_config['vault_path']
        except Exception as e:
            print(f"Error loading config file: {e}")
    
    if not vault_path:
        # We'll handle this in each route, allowing partial functionality
        print("WARNING: No vault path configured")
    else:
        config["vault_path"] = vault_path
        config["memory_path"] = os.path.join(vault_path, "AI/Memory")

@app.route('/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    is_configured = config["vault_path"] is not None
    
    return jsonify({
        "status": "healthy",
        "configured": is_configured,
        "version": "0.1.0",
        "name": "Shared Memory Framework Server"
    })

@app.route('/capabilities', methods=['GET'])
def capabilities():
    """Return server capabilities (MCP standard)"""
    is_configured = config["vault_path"] is not None
    
    return jsonify({
        "methods": ["get", "search", "list", "write", "batch", "capabilities", "status"],
        "version": "1.0",
        "name": "Shared Memory Framework MCP Server",
        "configured": is_configured
    })

@app.route('/config', methods=['GET', 'POST'])
def manage_config():
    """Get or update server configuration"""
    if request.method == 'GET':
        # Return sanitized config (no sensitive data)
        return jsonify({
            "vault_configured": config["vault_path"] is not None,
            "api_version": "1.0"
        })
    
    elif request.method == 'POST':
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "Invalid request"}), 400
        
        # Update config
        if 'vault_path' in data:
            vault_path = data['vault_path']
            
            # Validate path exists
            if not os.path.exists(vault_path):
                return jsonify({"error": f"Vault path does not exist: {vault_path}"}), 400
            
            # Save to config file
            config_path = os.path.join(os.path.dirname(__file__), 'config.json')
            try:
                with open(config_path, 'w') as f:
                    json.dump({"vault_path": vault_path}, f)
                
                # Update running config
                config["vault_path"] = vault_path
                config["memory_path"] = os.path.join(vault_path, "AI/Memory")
                
                return jsonify({"status": "Configuration updated successfully"})
            except Exception as e:
                return jsonify({"error": f"Failed to save configuration: {str(e)}"}), 500
        
        return jsonify({"error": "No valid configuration options provided"}), 400

@app.route('/search', methods=['GET'])
def search_notes():
    """Search for notes matching a query"""
    if not config["memory_path"]:
        return jsonify({"error": "Server not configured. Set vault_path first."}), 500
    
    query = request.args.get('query', '')
    if not query:
        return jsonify({"error": "Query parameter required"}), 400
    
    # Case-insensitive search in files
    results = []
    for root, _, files in os.walk(config["memory_path"]):
        for file in files:
            if file.endswith('.md'):
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, config["vault_path"])
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Check if query matches filename or content
                    if re.search(query, file, re.IGNORECASE) or re.search(query, content, re.IGNORECASE):
                        results.append(rel_path)
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")
    
    return jsonify(results)

@app.route('/read', methods=['GET'])
def read_notes():
    """Read one or more notes by path"""
    if not config["vault_path"]:
        return jsonify({"error": "Server not configured. Set vault_path first."}), 500
    
    paths = request.args.getlist('path')
    if not paths:
        return jsonify({"error": "At least one path parameter required"}), 400
    
    results = {}
    for path in paths:
        full_path = os.path.join(config["vault_path"], path.lstrip('/'))
        
        try:
            if os.path.exists(full_path) and full_path.endswith('.md'):
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                results[path] = content
            else:
                results[path] = {"error": f"File not found or not a markdown file: {path}"}
        except Exception as e:
            results[path] = {"error": f"Error reading file: {str(e)}"}
    
    return jsonify(results)

@app.route('/list', methods=['GET'])
def list_files():
    """List files in a directory (MCP standard)"""
    if not config["vault_path"]:
        return jsonify({"error": "Server not configured. Set vault_path first."}), 500
    
    path = request.args.get('path', 'AI/Memory')
    full_path = os.path.join(config["vault_path"], path.lstrip('/'))
    
    if not os.path.exists(full_path) or not os.path.isdir(full_path):
        return jsonify({"error": f"Directory not found: {path}"}), 400
    
    # List files and directories
    results = []
    try:
        for item in os.listdir(full_path):
            item_path = os.path.join(full_path, item)
            rel_path = os.path.join(path, item)
            if os.path.isdir(item_path):
                results.append({
                    "path": rel_path,
                    "type": "directory",
                    "name": item
                })
            elif item.endswith('.md'):
                results.append({
                    "path": rel_path,
                    "type": "file",
                    "name": item
                })
    except Exception as e:
        return jsonify({"error": f"Error listing directory: {str(e)}"}), 500
    
    return jsonify(results)

@app.route('/write', methods=['POST'])
def write_note():
    """Write content to a note"""
    if not config["vault_path"]:
        return jsonify({"error": "Server not configured. Set vault_path first."}), 500
    
    data = request.get_json()
    
    if not data or 'path' not in data or 'content' not in data:
        return jsonify({"error": "Path and content are required"}), 400
    
    path = data['path']
    content = data['content']
    
    full_path = os.path.join(config["vault_path"], path.lstrip('/'))
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    
    try:
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return jsonify({"status": "success", "path": path})
    except Exception as e:
        return jsonify({"error": f"Failed to write file: {str(e)}"}), 500

@app.route('/jsonrpc', methods=['POST', 'GET'])
def jsonrpc_endpoint():
    """JSON-RPC 2.0 endpoint for MCP compatibility"""
    try:
        print("===== Original /jsonrpc endpoint accessed =====")
        print(f"Method: {request.method}")
        print(f"Query params: {request.args}")
        
        # Special handler for tools/list method
        if request.method == 'GET' and request.args.get('method') == 'tools/list':
            print("Direct handling of tools/list GET request")
            print(f"Request headers: {request.headers}")
            
            # Get tools list directly from the method handler
            # GitHub Copilot expects tools as a direct array, not wrapped in an object
            tools_list = handle_jsonrpc_method("tools/list", {})
            
            # Make sure we have a tools list regardless of the return format
            if not isinstance(tools_list, list):
                if isinstance(tools_list, dict) and "tools" in tools_list:
                    tools_list = tools_list.get("tools", [])
                else:
                    tools_list = []
            
            # Detect if this is GitHub Copilot
            user_agent = request.headers.get('User-Agent', '').lower()
            is_copilot = any(name in user_agent for name in ['github', 'copilot'])
            
            if is_copilot:
                print(f"GitHub Copilot detected via User-Agent: {user_agent}")
                print(f"Returning {len(tools_list)} tools in GitHub Copilot format")
                
                # Return tools directly (not wrapped in an object)
                resp = {
                    "jsonrpc": "2.0",
                    "id": request.args.get('id', 'tools-request'),
                    "result": tools_list  # Direct array at top level as GitHub Copilot expects
                }
                return jsonify(resp)
            else:
                # Standard MCP format
                print(f"Returning {len(tools_list)} tools for GET tools/list (standard format)")
                
                # Return tools directly (not wrapped in an object)
                resp = {
                    "jsonrpc": "2.0",
                    "id": request.args.get('id', 'tools-request'),
                    "result": tools_list  # Direct array at top level
                }
                return jsonify(resp)
            
        # Check for SSE request via accept header
        wants_sse = request.headers.get('Accept') == 'text/event-stream'
        
        # Handle regular GET requests with SSE support
        if request.method == 'GET':
            # Get full capabilities with proper namespaces
            methods = [
                "resources/list", "resources/read", "resources/write",
                "tools/list", "tools/call",
                "prompts/list", "prompts/get",  # Standard MCP prompts namespace
                "initialize", "shutdown",  # LSP methods for IDE integration
                # Legacy methods for backward compatibility
                "get", "search", "list", "write", "batch", 
                "capabilities", "status"
            ]
            
            capabilities_response = {
                "jsonrpc": "2.0",
                "id": "capabilities",
                "result": {
                    "methods": methods,
                    "version": "1.0",
                    "name": "Shared Memory Framework MCP Server",
                    "configured": config["vault_path"] is not None,
                    "spec": "https://modelcontextprotocol.io/llms-full.txt",
                    "auth": {
                        "required": False
                    },
                    # Add experimental capabilities flag
                    "experimental": {
                        "supports": ["batch", "sse", "lsp"],
                        "supportsLSP": True  # For GitHub Copilot
                    }
                }
            }
            
            # Direct to the SSE endpoint if client requests SSE
            if wants_sse:
                return sse_endpoint()
            else:
                # Regular JSON response
                return jsonify(capabilities_response)
            
        # Check for CORS preflight requests
        if request.method == 'OPTIONS':
            response = app.make_default_options_response()
            response.headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
            response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
            return response
            
        # For POST requests, process the full JSON-RPC protocol
        request_data = request.get_json()
        
        # Validate request
        if not request_data:
            error_response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {
                    "code": PARSE_ERROR,
                    "message": "Parse error: Empty request"
                }
            }
            return jsonify(error_response), 400
        
        # Handle batch requests
        if isinstance(request_data, list):
            responses = [process_jsonrpc_request(req) for req in request_data]
            return jsonify(responses)
        else:
            # Process JSON-RPC 2.0 request
            if not isinstance(request_data, dict):
                error_response = {
                    "jsonrpc": "2.0",
                    "id": None,
                    "error": {
                        "code": INVALID_REQUEST,
                        "message": "Invalid request: Expected object"
                    }
                }
                return jsonify(error_response), 400
                
            # Handle LSP/MCP version - support both jsonrpc and vanilla LSP
            if not ("jsonrpc" in request_data or "method" in request_data):
                error_response = {
                    "jsonrpc": "2.0",
                    "id": request_data.get("id"),
                    "error": {
                        "code": INVALID_REQUEST,
                        "message": "Invalid request: must contain jsonrpc or method"
                    }
                }
                return jsonify(error_response), 400
                
            # Add jsonrpc field if it's missing (for LSP compatibility)
            if "jsonrpc" not in request_data and "method" in request_data:
                request_data["jsonrpc"] = "2.0"
                
            return jsonify(process_jsonrpc_request(request_data))
    except json.JSONDecodeError:
        # Handle JSON parse errors specifically
        error_response = {
            "jsonrpc": "2.0",
            "id": None,
            "error": {
                "code": PARSE_ERROR,
                "message": "Parse error: Invalid JSON"
            }
        }
        return jsonify(error_response), 400
    except Exception as e:
        # Handle all other errors
        import traceback
        traceback_str = traceback.format_exc()
        print(f"Internal error: {str(e)}\n{traceback_str}")
        
        error_response = {
            "jsonrpc": "2.0",
            "id": None,
            "error": {
                "code": INTERNAL_ERROR,
                "message": f"Internal error: {str(e)}",
                "data": {
                    "type": type(e).__name__
                }
            }
        }
        return jsonify(error_response), 500

def process_jsonrpc_request(request_data):
    """Process a single JSON-RPC request"""
    # Check that it's a dictionary at minimum
    if not isinstance(request_data, dict):
        return {
            "jsonrpc": "2.0",
            "id": None,
            "error": {
                "code": INVALID_REQUEST,
                "message": "Invalid Request: Expected object"
            }
        }
    
    # LSP might not include jsonrpc field but must have method
    if "jsonrpc" not in request_data:
        request_data["jsonrpc"] = "2.0"  # Add it for backward compatibility
    
    method = request_data.get("method")
    params = request_data.get("params", {})
    request_id = request_data.get("id")
    
    if not method:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {
                "code": INVALID_REQUEST,
                "message": "Invalid Request: Method is required"
            }
        }
    
    # Dispatch to appropriate method handler
    result = handle_jsonrpc_method(method, params)
    
    # Check if result contains an error
    if isinstance(result, dict) and "error" in result:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": result["error"]
        }
    else:
        # Special handling for tools/list method to ensure GitHub Copilot compatibility
        # When the method is tools/list, always return tools directly in the result field
        if method == "tools/list" or method == "$/tools/list":
            # Log that we're returning tools directly for GitHub Copilot
            print(f"Processing tools/list response for request ID: {request_id}")
            
            # Since handle_jsonrpc_method already returns a direct array for tools/list,
            # we can just use that result directly
            if isinstance(result, list):
                print(f"Returning {len(result)} tools as direct array in result")
                # IMPORTANT: GitHub Copilot requires tools to be a direct array at the top level of result
                return {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": result  # Direct array of tools at top level
                }
            # If for some reason result is wrapped in a dict with a 'tools' key, unwrap it
            elif isinstance(result, dict) and "tools" in result:
                tools_list = result.get("tools", [])
                print(f"Unwrapping tools from dict, returning {len(tools_list)} tools")
                # IMPORTANT: GitHub Copilot requires tools to be a direct array at the top level of result
                return {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": tools_list  # Direct array of tools at top level
                }
        
        # Standard response for other methods
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": result
        }

def handle_jsonrpc_method(method, params):
    """Handle a JSON-RPC method according to MCP protocol"""
    # Special handling for tools/list to directly return the array
    if method == "tools/list":
        tools = [
            {
                "id": "search",
                "name": "Search",
                "description": "Search for notes containing specific text",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "The search query"
                        }
                    },
                    "required": ["query"]
                }
            },
            {
                "id": "create_note",
                "name": "Create Note",
                "description": "Create a new note in the knowledge base",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Path where to create the note"
                        },
                        "title": {
                            "type": "string",
                            "description": "Title of the note"
                        },
                        "content": {
                            "type": "string",
                            "description": "Content of the note"
                        }
                    },
                    "required": ["path", "title", "content"]
                }
            },
            {
                "id": "context_search",
                "name": "Context Search",
                "description": "Search for specific contexts in the knowledge base",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "The context search query"
                        },
                        "category": {
                            "type": "string",
                            "description": "Optional category to filter by (e.g., 'Shared', 'Claude')"
                        }
                    },
                    "required": ["query"]
                }
            },
            {
                "id": "conversation_search",
                "name": "Conversation Search",
                "description": "Search for conversations in the knowledge base",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string", 
                            "description": "The conversation search query"
                        },
                        "agent": {
                            "type": "string",
                            "description": "Optional agent to filter by (e.g., 'Claude', 'GPT')"
                        },
                        "date_from": {
                            "type": "string",
                            "description": "Optional start date in YYYYMMDD format"
                        },
                        "date_to": {
                            "type": "string",
                            "description": "Optional end date in YYYYMMDD format"
                        }
                    },
                    "required": ["query"]
                }
            },
            {
                "id": "knowledge_summary",
                "name": "Knowledge Summary",
                "description": "Get a summary of available knowledge in the SMF",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "category": {
                            "type": "string",
                            "description": "Optional category to filter by (e.g., 'Contexts', 'Conversations')"
                        }
                    }
                }
            },
            {
                "id": "batch",
                "name": "Batch Operations",
                "description": "Execute multiple operations in parallel",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "operations": {
                            "type": "array",
                            "description": "List of operations to execute",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "method": {
                                        "type": "string",
                                        "description": "The method to call"
                                    },
                                    "params": {
                                        "type": "object",
                                        "description": "Parameters for the method"
                                    },
                                    "id": {
                                        "type": "string",
                                        "description": "Operation ID"
                                    }
                                },
                                "required": ["method"]
                            }
                        }
                    },
                    "required": ["operations"]
                }
            }
        ]
        
        # Log the tools being returned
        print(f"Returning {len(tools)} tools from tools/list method handler")
        # CRITICAL: Always return the tools directly as an array for GitHub Copilot compatibility
        # GitHub Copilot expects tools to be a direct array, not wrapped in an object
        return tools  # Return direct array, not wrapped
        
    # Language Server Protocol (LSP) methods for IDE integration
    if method == "initialize":
        # Handle LSP initialization request for GitHub Copilot
        print(f"Initialize method called with params: {json.dumps(params)}")
        
        # Get the tools list to include in the response
        tools_list = handle_jsonrpc_method("tools/list", {})
        
        # Make sure tools is a list
        if not isinstance(tools_list, list):
            if isinstance(tools_list, dict) and "tools" in tools_list:
                tools_list = tools_list.get("tools", [])
            else:
                tools_list = []
                
        capabilities = [
            "resources/list", "resources/read", "resources/write",
            "tools/list", "tools/call",
            "prompts/list", "prompts/get",
            "get", "search", "list", "write", "batch", 
            "capabilities", "status"
        ]
        
        # Detect if this is GitHub Copilot by examining the parameters
        # Copilot has specific initialization parameters
        is_copilot = False
        client_info = params.get("clientInfo", {})
        if client_info:
            client_name = client_info.get("name", "").lower()
            if any(name in client_name for name in ["github", "copilot"]):
                is_copilot = True
                print(f"GitHub Copilot detected in initialize request: {client_name}")
        
        # Standard LSP response for initialize
        response = {
            "capabilities": {
                "textDocumentSync": 1,  # Full document sync
                "completionProvider": {
                    "resolveProvider": True,
                    "triggerCharacters": ["."]
                },
                "documentFormattingProvider": True,
                "documentLinkProvider": {
                    "resolveProvider": True
                },
                "hoverProvider": True,
                "documentSymbolProvider": True,
                "executeCommandProvider": {
                    "commands": ["mcp.search", "mcp.read", "mcp.write"]
                },
                "experimental": {
                    "mcpMethods": capabilities,
                    "mcpSupport": True,
                    "supportsLSP": True
                }
            },
            # Tools MUST be at top level for GitHub Copilot
            "tools": tools_list,
            "serverInfo": {
                "name": "Shared Memory Framework MCP Server",
                "version": "1.0"
            }
        }
        
        print(f"Initialize response with {len(tools_list)} tools")
        return response
    
    # MCP client shutdown request
    elif method == "shutdown":
        return {}
    
    # Standard MCP methods for resources
    elif method == "resources/read":
        if "path" in params:
            path = params["path"]
            full_path = os.path.join(config["vault_path"], path.lstrip('/'))
            
            try:
                if os.path.exists(full_path) and full_path.endswith('.md'):
                    with open(full_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    return {
                        "content": content,
                        "metadata": {
                            "path": path,
                            "type": "text/markdown",
                            "modifiedAt": os.path.getmtime(full_path)
                        }
                    }
                else:
                    return {"error": {"code": SERVER_ERROR_START, "message": f"Resource not found or not a markdown file: {path}"}}
            except Exception as e:
                return {"error": {"code": SERVER_ERROR_START, "message": f"Error reading resource: {str(e)}"}}
        return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Path parameter required"}}
    
    elif method == "resources/list":
        path = params.get("path", "AI/Memory")
        full_path = os.path.join(config["vault_path"], path.lstrip('/'))
        
        if not os.path.exists(full_path) or not os.path.isdir(full_path):
            return {"error": {"code": SERVER_ERROR_START, "message": f"Directory not found: {path}"}}
        
        # List files and directories
        results = []
        try:
            for item in os.listdir(full_path):
                item_path = os.path.join(full_path, item)
                rel_path = os.path.join(path, item)
                if os.path.isdir(item_path):
                    results.append({
                        "path": rel_path,
                        "type": "directory",
                        "name": item
                    })
                elif item.endswith('.md'):
                    results.append({
                        "path": rel_path,
                        "type": "file",
                        "name": item,
                        "contentType": "text/markdown",
                        "modifiedAt": os.path.getmtime(item_path)
                    })
        except Exception as e:
            return {"error": {"code": SERVER_ERROR_START, "message": f"Error listing resources: {str(e)}"}}
        
        return {
            "resources": results,
            "metadata": {
                "path": path,
                "type": "directory"
            }
        }
    
    elif method == "resources/write":
        if "path" in params and "content" in params:
            path = params["path"]
            content = params["content"]
            
            if not config["vault_path"]:
                return {"error": {"code": SERVER_ERROR_START, "message": "Server not configured. Set vault_path first."}}
            
            full_path = os.path.join(config["vault_path"], path.lstrip('/'))
            
            # Ensure directory exists
            try:
                os.makedirs(os.path.dirname(full_path), exist_ok=True)
                
                with open(full_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                return {
                    "success": True,
                    "path": path,
                    "metadata": {
                        "path": path,
                        "modifiedAt": os.path.getmtime(full_path),
                        "type": "text/markdown"
                    }
                }
            except Exception as e:
                return {"error": {"code": SERVER_ERROR_START, "message": f"Failed to write resource: {str(e)}"}}
        return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Path and content parameters required"}}
    
    # Prompts support (MCP standard)
    elif method == "prompts/list":
        # Look for prompts in the System_Prompts directory
        prompts_path = os.path.join(config["memory_path"], "System_Prompts") if config["memory_path"] else None
        prompts = []
        
        if prompts_path and os.path.exists(prompts_path):
            for root, dirs, files in os.walk(prompts_path):
                for file in files:
                    if file.endswith('.md'):
                        file_path = os.path.join(root, file)
                        rel_path = os.path.relpath(file_path, config["vault_path"])
                        # Extract prompt name from filename
                        prompt_name = os.path.splitext(file)[0]
                        try:
                            with open(file_path, 'r', encoding='utf-8') as f:
                                content = f.read()
                                # Extract description from content (first line after title)
                                description = ""
                                lines = content.split('\n')
                                for i, line in enumerate(lines):
                                    if line.startswith('# '):
                                        # Look for the next non-empty line
                                        for j in range(i+1, min(i+5, len(lines))):
                                            if lines[j].strip() and not lines[j].startswith('#'):
                                                description = lines[j].strip()
                                                break
                                        break
                            
                            prompts.append({
                                "id": rel_path,
                                "name": prompt_name,
                                "description": description,
                                "path": rel_path
                            })
                        except Exception as e:
                            print(f"Error reading prompt {file_path}: {e}")
        
        return {"prompts": prompts}
    
    elif method == "prompts/get":
        if "id" in params:
            prompt_id = params["id"]
            full_path = os.path.join(config["vault_path"], prompt_id.lstrip('/'))
            
            try:
                if os.path.exists(full_path) and full_path.endswith('.md'):
                    with open(full_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Parse metadata from prompt content
                    metadata = {}
                    # Simple frontmatter extraction
                    if content.startswith('---'):
                        parts = content.split('---', 2)
                        if len(parts) >= 3:
                            frontmatter = parts[1].strip()
                            for line in frontmatter.split('\n'):
                                if ':' in line:
                                    key, value = line.split(':', 1)
                                    metadata[key.strip()] = value.strip().strip('"\'')
                    
                    return {
                        "id": prompt_id,
                        "content": content,
                        "metadata": {
                            "path": prompt_id,
                            "created": metadata.get("date", ""),
                            "author": metadata.get("agent", ""),
                            "tags": metadata.get("tags", "")
                        }
                    }
                else:
                    return {"error": {"code": SERVER_ERROR_START, "message": f"Prompt not found: {prompt_id}"}}
            except Exception as e:
                return {"error": {"code": SERVER_ERROR_START, "message": f"Error reading prompt: {str(e)}"}}
        return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Prompt ID required"}}
    
    # Tools support
    elif method == "tools/list":
        tools = [
            {
                "id": "search",
                "name": "Search",
                "description": "Search for notes containing specific text",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "The search query"
                        }
                    },
                    "required": ["query"]
                }
            },
            {
                "id": "create_note",
                "name": "Create Note",
                "description": "Create a new note in the knowledge base",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Path where to create the note"
                        },
                        "title": {
                            "type": "string",
                            "description": "Title of the note"
                        },
                        "content": {
                            "type": "string",
                            "description": "Content of the note"
                        }
                    },
                    "required": ["path", "title", "content"]
                }
            },
            {
                "id": "context_search",
                "name": "Context Search",
                "description": "Search for specific contexts in the knowledge base",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "The context search query"
                        },
                        "category": {
                            "type": "string",
                            "description": "Optional category to filter by (e.g., 'Shared', 'Claude')"
                        }
                    },
                    "required": ["query"]
                }
            },
            {
                "id": "conversation_search",
                "name": "Conversation Search",
                "description": "Search for conversations in the knowledge base",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string", 
                            "description": "The conversation search query"
                        },
                        "agent": {
                            "type": "string",
                            "description": "Optional agent to filter by (e.g., 'Claude', 'GPT')"
                        },
                        "date_from": {
                            "type": "string",
                            "description": "Optional start date in YYYYMMDD format"
                        },
                        "date_to": {
                            "type": "string",
                            "description": "Optional end date in YYYYMMDD format"
                        }
                    },
                    "required": ["query"]
                }
            },
            {
                "id": "knowledge_summary",
                "name": "Knowledge Summary",
                "description": "Get a summary of available knowledge in the SMF",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "category": {
                            "type": "string",
                            "description": "Optional category to filter by (e.g., 'Contexts', 'Conversations')"
                        }
                    }
                }
            },
            {
                "id": "batch",
                "name": "Batch Operations",
                "description": "Execute multiple operations in parallel",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "operations": {
                            "type": "array",
                            "description": "List of operations to execute",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "method": {
                                        "type": "string",
                                        "description": "The method to call"
                                    },
                                    "params": {
                                        "type": "object",
                                        "description": "Parameters for the method"
                                    },
                                    "id": {
                                        "type": "string",
                                        "description": "Operation ID"
                                    }
                                },
                                "required": ["method"]
                            }
                        }
                    },
                    "required": ["operations"]
                }
            }
        ]
        
        # Log the tools being returned
        print(f"Returning {len(tools)} tools from tools/list endpoint")
        
        # Special formatting for GitHub Copilot
        # Return tools both inside the standard "tools" field and at the top level
        response = {
            "tools": tools  # Standard MCP format
        }
        
        # For clients that need the response in jsonrpc format with tools as a result
        print("Sending multiple tool formats to ensure client compatibility")
        
        # Try to detect if this is GitHub Copilot based on any available info
        try:
            user_agent = request.headers.get('User-Agent', '')
            if 'GitHub' in user_agent or 'Copilot' in user_agent:
                print(f"GitHub Copilot detected via User-Agent: {user_agent}")
                # Direct return with tools at top level
                return tools
        except Exception:
            pass
            
        return response
    
    elif method == "tools/call":
        if "tool" not in params or "params" not in params:
            return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: tool and params required"}}
            
        tool_id = params["tool"]
        tool_params = params["params"]
        
        print(f"Processing tools/call for tool '{tool_id}' with params: {json.dumps(tool_params)}")
        
        if tool_id == "search":
            if "query" in tool_params:
                query = tool_params["query"]
                if not config["memory_path"]:
                    return {"error": {"code": SERVER_ERROR_START, "message": "Server not configured. Set vault_path first."}}
                
                # Case-insensitive search in files
                results = []
                for root, _, files in os.walk(config["memory_path"]):
                    for file in files:
                        if file.endswith('.md'):
                            file_path = os.path.join(root, file)
                            rel_path = os.path.relpath(file_path, config["vault_path"])
                            
                            try:
                                with open(file_path, 'r', encoding='utf-8') as f:
                                    content = f.read()
                                
                                # Check if query matches filename or content
                                if re.search(query, file, re.IGNORECASE) or re.search(query, content, re.IGNORECASE):
                                    results.append({
                                        "path": rel_path,
                                        "type": "file",
                                        "name": file,
                                        "contentType": "text/markdown"
                                    })
                            except Exception as e:
                                print(f"Error reading {file_path}: {e}")
                
                print(f"Search completed, found {len(results)} results")
                return {"results": results}
            return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Query parameter required"}}
        
        elif tool_id == "batch":
            return handle_jsonrpc_method("batch", tool_params)
        
        elif tool_id == "create_note":
            required_params = ["path", "title", "content"]
            if all(param in tool_params for param in required_params):
                path = tool_params["path"]
                title = tool_params["title"]
                content = tool_params["content"]
                
                # Format content with title
                formatted_content = f"# {title}\n\n{content}"
                
                # Write the note
                return handle_jsonrpc_method("resources/write", {
                    "path": path,
                    "content": formatted_content
                })
            else:
                return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: path, title, and content required"}}
        
        elif tool_id == "context_search":
            if "query" in tool_params:
                query = tool_params["query"]
                category = tool_params.get("category", "")
                
                if not config["memory_path"]:
                    return {"error": {"code": SERVER_ERROR_START, "message": "Server not configured. Set vault_path first."}}
                
                # Search in context files
                contexts_path = os.path.join(config["memory_path"], "Contexts")
                if not os.path.exists(contexts_path):
                    return {"results": []}
                
                results = []
                for root, _, files in os.walk(contexts_path):
                    # If category specified, only search in that directory
                    if category and os.path.basename(root) != category:
                        continue
                        
                    for file in files:
                        if file.endswith('.md'):
                            file_path = os.path.join(root, file)
                            rel_path = os.path.relpath(file_path, config["vault_path"])
                            
                            try:
                                with open(file_path, 'r', encoding='utf-8') as f:
                                    content = f.read()
                                
                                # Check if query matches filename or content
                                if re.search(query, file, re.IGNORECASE) or re.search(query, content, re.IGNORECASE):
                                    # Extract title and snippet
                                    title = os.path.splitext(file)[0]
                                    
                                    # Try to extract actual title from markdown
                                    title_match = re.search(r'# (.*?)(\n|$)', content)
                                    if title_match:
                                        title = title_match.group(1).strip()
                                    
                                    # Get a snippet of content
                                    snippet = content[:200] + '...' if len(content) > 200 else content
                                    
                                    results.append({
                                        "path": rel_path,
                                        "title": title,
                                        "snippet": snippet,
                                        "category": os.path.basename(root)
                                    })
                            except Exception as e:
                                print(f"Error reading {file_path}: {e}")
                
                print(f"Context search completed, found {len(results)} results")
                return {"results": results}
            return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Query parameter required"}}
        
        elif tool_id == "conversation_search":
            if "query" in tool_params:
                query = tool_params["query"]
                agent = tool_params.get("agent", "")
                date_from = tool_params.get("date_from", "")
                date_to = tool_params.get("date_to", "")
                
                if not config["memory_path"]:
                    return {"error": {"code": SERVER_ERROR_START, "message": "Server not configured. Set vault_path first."}}
                
                # Search in conversation files
                conversations_path = os.path.join(config["memory_path"], "Conversations")
                if not os.path.exists(conversations_path):
                    return {"results": []}
                
                results = []
                for root, _, files in os.walk(conversations_path):
                    # If agent specified, only search in that directory
                    if agent and os.path.basename(root) != agent:
                        continue
                        
                    for file in files:
                        if file.endswith('.md'):
                            # Check date range if specified
                            if date_from or date_to:
                                date_parts = file.split('-')[0]
                                if len(date_parts) >= 8:  # YYYYMMDD format
                                    file_date = date_parts
                                    if date_from and file_date < date_from:
                                        continue
                                    if date_to and file_date > date_to:
                                        continue
                            
                            file_path = os.path.join(root, file)
                            rel_path = os.path.relpath(file_path, config["vault_path"])
                            
                            try:
                                with open(file_path, 'r', encoding='utf-8') as f:
                                    content = f.read()
                                
                                # Check if query matches filename or content
                                if re.search(query, file, re.IGNORECASE) or re.search(query, content, re.IGNORECASE):
                                    # Extract title and snippet
                                    title = os.path.splitext(file)[0]
                                    
                                    # Try to extract actual title from markdown
                                    title_match = re.search(r'# (.*?)(\n|$)', content)
                                    if title_match:
                                        title = title_match.group(1).strip()
                                    
                                    # Get a snippet of content
                                    snippet = content[:200] + '...' if len(content) > 200 else content
                                    
                                    results.append({
                                        "path": rel_path,
                                        "title": title,
                                        "snippet": snippet,
                                        "agent": os.path.basename(root),
                                        "date": file.split('-')[0] if '-' in file else ""
                                    })
                            except Exception as e:
                                print(f"Error reading {file_path}: {e}")
                
                print(f"Conversation search completed, found {len(results)} results")
                return {"results": results}
            return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Query parameter required"}}
            
        elif tool_id == "knowledge_summary":
            category = tool_params.get("category", "")
            
            if not config["memory_path"]:
                return {"error": {"code": SERVER_ERROR_START, "message": "Server not configured. Set vault_path first."}}
            
            # Count files in various categories
            contexts_count = 0
            conversations_count = 0
            system_prompts_count = 0
            
            # Count contexts
            contexts_path = os.path.join(config["memory_path"], "Contexts")
            if os.path.exists(contexts_path) and (not category or category.lower() == "contexts"):
                for root, _, files in os.walk(contexts_path):
                    contexts_count += sum(1 for f in files if f.endswith('.md'))
            
            # Count conversations
            conversations_path = os.path.join(config["memory_path"], "Conversations")
            if os.path.exists(conversations_path) and (not category or category.lower() == "conversations"):
                for root, _, files in os.walk(conversations_path):
                    conversations_count += sum(1 for f in files if f.endswith('.md'))
            
            # Count system prompts
            prompts_path = os.path.join(config["memory_path"], "System_Prompts")
            if os.path.exists(prompts_path) and (not category or category.lower() == "prompts"):
                for root, _, files in os.walk(prompts_path):
                    system_prompts_count += sum(1 for f in files if f.endswith('.md'))
            
            return {
                "summary": {
                    "contexts": contexts_count,
                    "conversations": conversations_count,
                    "system_prompts": system_prompts_count,
                    "total": contexts_count + conversations_count + system_prompts_count
                }
            }
            
        return {"error": {"code": METHOD_NOT_FOUND, "message": f"Tool not found: {tool_id}"}}
    
    # Legacy method support for backward compatibility
    elif method == "get":
        return handle_jsonrpc_method("resources/read", params)
    
    elif method == "search":
        if "query" in params:
            tool_result = handle_jsonrpc_method("tools/call", {"tool": "search", "params": {"query": params["query"]}})
            if "results" in tool_result:
                return [res["path"] for res in tool_result["results"]]
            return tool_result
        return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Query parameter required"}}
    
    elif method == "list":
        return handle_jsonrpc_method("resources/list", params)
    
    elif method == "write":
        return handle_jsonrpc_method("resources/write", params)
    
    elif method == "batch":
        if "operations" in params and isinstance(params["operations"], list):
            operations = params["operations"]
            results = {}
            
            for operation in operations:
                operation_id = operation.get("id", "")
                sub_method = operation.get("method")
                sub_params = operation.get("params", {})
                
                if not sub_method:
                    results[operation_id] = {
                        "error": {
                            "code": INVALID_REQUEST,
                            "message": "Invalid operation: Method is required"
                        }
                    }
                    continue
                
                # Execute the sub-operation
                sub_result = handle_jsonrpc_method(sub_method, sub_params)
                results[operation_id] = sub_result
            
            return results
        return {"error": {"code": INVALID_PARAMS, "message": "Invalid params: Operations parameter required as a list"}}
    
    # System methods
    elif method == "capabilities":
        methods = [
            "resources/list", "resources/read", "resources/write",
            "tools/list", "tools/call",
            "prompts/list", "prompts/get",
            # Legacy methods for backward compatibility
            "get", "search", "list", "write", "batch", 
            "capabilities", "status"
        ]
        return {
            "methods": methods,
            "version": "1.0",
            "name": "Shared Memory Framework MCP Server",
            "configured": config["vault_path"] is not None,
            "spec": "https://modelcontextprotocol.io/llms-full.txt",
            "auth": {
                "required": False
            },
            "experimental": {
                "supports": ["batch", "sse", "notifications"]
            }
        }
    
    elif method == "status":
        return {
            "status": "healthy",
            "configured": config["vault_path"] is not None,
            "version": "1.0",
            "name": "Shared Memory Framework Server",
            "uptime": os.path.getmtime(__file__) - time.time()
        }
    
    else:
        return {"error": {"code": METHOD_NOT_FOUND, "message": f"Method not found: {method}"}}

@app.route('/metadata', methods=['GET'])
def get_vault_metadata():
    """Get metadata about the vault structure"""
    if not config["memory_path"]:
        return jsonify({"error": "Server not configured. Set vault_path first."}), 500
    
    # Return basic structure and stats about the vault
    stats = {
        "contexts": 0,
        "conversations": 0,
        "system_prompts": 0,
        "projects": 0
    }
    
    # Walk through the AI Memory directory and count files
    for root, _, files in os.walk(config["memory_path"]):
        if "Contexts" in root:
            stats["contexts"] += sum(1 for f in files if f.endswith('.md'))
        elif "Conversations" in root:
            stats["conversations"] += sum(1 for f in files if f.endswith('.md'))
        elif "System_Prompts" in root:
            stats["system_prompts"] += sum(1 for f in files if f.endswith('.md'))
        elif "Projects" in root:
            stats["projects"] += sum(1 for f in files if f.endswith('.md'))
    
    return jsonify({
        "vault_configured": config["vault_path"] is not None,
        "stats": stats
    })


# Dedicated LSP endpoint for GitHub Copilot
@app.route('/lsp', methods=['POST', 'GET'])
def lsp_endpoint():
    """Language Server Protocol endpoint for IDE integration"""
    try:
        # Get tools list for inclusion in various responses
        tools_list = handle_jsonrpc_method("tools/list", {})
        if isinstance(tools_list, dict) and "tools" in tools_list:
            tools = tools_list["tools"]
        else:
            tools = []
            
        print(f"LSP endpoint found {len(tools)} tools")
            
        # For GET requests (capabilities check)
        if request.method == 'GET':
            print("LSP GET request - returning capabilities")
            return jsonify({
                "capabilities": {
                    "textDocumentSync": 1,
                    "completionProvider": {
                        "resolveProvider": True,
                        "triggerCharacters": ["."]
                    },
                    "documentFormattingProvider": True,
                    "experimental": {
                        "mcpSupport": True,
                        "tools": tools  # Include tools in experimental
                    }
                },
                "tools": tools,  # Include tools at top level for GitHub Copilot
                "serverInfo": {
                    "name": "SMF Knowledge Server",
                    "version": "1.0"
                }
            })
        
        # For POST requests (LSP commands)
        request_data = request.get_json()
        if not request_data:
            return jsonify({"error": "Invalid request"}), 400
        
        # Log the LSP request for debugging
        print(f"LSP Request: {json.dumps(request_data)}")
        
        # Check if this is GitHub Copilot based on request
        copilot_detected = False
        user_agent = request.headers.get('User-Agent', '')
        if 'GitHub' in user_agent or 'Copilot' in user_agent or 'github' in user_agent.lower():
            copilot_detected = True
            print(f"GitHub Copilot detected via User-Agent: {user_agent}")
        
        # Handle initialize method specially
        if request_data.get("method") == "initialize":
            print("Handling initialize request in LSP endpoint")
            lsp_capabilities = {
                "capabilities": {
                    "textDocumentSync": 1,  # Full text sync
                    "completionProvider": {
                        "resolveProvider": True,
                        "triggerCharacters": ["."]
                    },
                    "documentFormattingProvider": True,
                    "hoverProvider": True,
                    "documentSymbolProvider": True,
                    "executeCommandProvider": {
                        "commands": ["mcp.search", "mcp.read", "mcp.write"]
                    },
                    # MCP specific capabilities
                    "experimental": {
                        "mcpSupport": True,
                        "supportsLSP": True,
                        "mcpMethods": [
                            "resources/list", "resources/read", "resources/write",
                            "tools/list", "tools/call",
                            "prompts/list", "prompts/get"
                        ],
                        "tools": tools  # Include tools in experimental
                    }
                },
                "tools": tools,  # Include tools at top level for GitHub Copilot
                "serverInfo": {
                    "name": "SMF Knowledge Server",
                    "version": "1.0"
                }
            }
            
            response = jsonify(lsp_capabilities)
            
            # Send additional notification for tools registration after initialize
            # This is not right for REST but helps with some LSP clients
            if copilot_detected:
                print("Sending additional tool notifications for GitHub Copilot")
                # Send additional notification about tools in response headers
                response.headers['X-MCP-Tools-Count'] = str(len(tools))
                response.headers['X-MCP-Tools-Version'] = '1.0'
                
            return response
        
        # Handle shutdown method
        if request_data.get("method") == "shutdown":
            return jsonify({})
            
        # Special handling for tools-related methods
        if request_data.get("method") == "tools/list" or request_data.get("method") == "$/tools/list":
            print("Handling tools list request in LSP endpoint")
            
            # Get tools list directly from the method handler
            # GitHub Copilot expects tools as a direct array
            tools_list = handle_jsonrpc_method("tools/list", {})
            
            # Make sure we have a tools list regardless of the return format
            if not isinstance(tools_list, list):
                if isinstance(tools_list, dict) and "tools" in tools_list:
                    tools_list = tools_list.get("tools", [])
                else:
                    tools_list = []
            
            # For GitHub Copilot and VS Code, always return tools directly at the top level
            # This is what both GitHub Copilot and VS Code expect
            print(f"Returning {len(tools_list)} tools from LSP endpoint")
            return jsonify({
                "jsonrpc": "2.0",
                "id": request_data.get("id", "tools-id"),
                "result": tools_list  # Return tools directly at top level
            })
        
        # Handle regular methods by mapping to our MCP methods
        method = request_data.get("method", "")
        params = request_data.get("params", {})
        id = request_data.get("id")
        
        # Map LSP methods to MCP methods
        if method.startswith("mcp/"):
            # Already using MCP namespace
            mcp_method = method[4:]  # Remove 'mcp/' prefix
        elif method == "$/mcp.search":
            mcp_method = "search"
        elif method == "$/mcp.read" or method == "textDocument/mcp.read":
            mcp_method = "resources/read"
        elif method == "$/mcp.list" or method == "workspace/mcp.list":
            mcp_method = "resources/list"
        elif method == "$/mcp.write":
            mcp_method = "resources/write"
        else:
            # Pass through other methods as-is
            mcp_method = method
        
        result = handle_jsonrpc_method(mcp_method, params)
        
        # Format response as LSP
        if isinstance(result, dict) and "error" in result:
            response = {
                "id": id,
                "error": result["error"]
            }
        else:
            response = {
                "id": id,
                "result": result
            }
        
        # Add jsonrpc field if client expects it
        if "jsonrpc" in request_data:
            response["jsonrpc"] = request_data["jsonrpc"]
        
        return jsonify(response)
        
    except Exception as e:
        import traceback
        traceback_str = traceback.format_exc()
        print(f"LSP Error: {str(e)}\n{traceback_str}")
        
        return jsonify({
            "id": request_data.get("id") if request_data else None,
            "error": {
                "code": -32603,
                "message": f"Internal error: {str(e)}"
            }
        }), 500

# Better SSE endpoint for MCP client (GitHub Copilot)
@app.route('/sse', methods=['GET', 'POST', 'OPTIONS'])
def sse_endpoint():
    """Direct SSE endpoint for GitHub Copilot and other MCP clients"""
    from flask import Response, stream_with_context
    import time
    import uuid
    
    print("===== VS CODE MCP SSE ENDPOINT ACCESSED =====")
    print(f"SSE Request Method: {request.method}")
    print(f"SSE Request Headers: {request.headers}")
    print(f"SSE Request URI: {request.url}")
    
    # Extract query parameters - VS Code might send initialize as a query param
    method_param = request.args.get('method')
    id_param = request.args.get('id')
    
    print(f"SSE Query Params: method={method_param}, id={id_param}")
    
    # Get the tools list that will be included in responses
    tools_list = handle_jsonrpc_method("tools/list", {})
    
    # Make sure we have a tools list regardless of the return format
    if not isinstance(tools_list, list):
        if isinstance(tools_list, dict) and "tools" in tools_list:
            tools_list = tools_list.get("tools", [])
        else:
            tools_list = []
    
    print(f"SSE endpoint has {len(tools_list)} tools available to send")
    for tool in tools_list:
        print(f"  - Tool: {tool.get('name')} ({tool.get('id')})")
    
    # Try to detect if this is VS Code's GitHub Copilot
    is_vscode = 'vscode' in request.headers.get('User-Agent', '').lower()
    is_copilot = any(name in request.headers.get('User-Agent', '').lower() for name in ['github', 'copilot'])
    
    if is_vscode:
        print("DETECTED VS CODE CONNECTION")
    if is_copilot:
        print(f"DETECTED GITHUB COPILOT CONNECTION VIA USER AGENT: {request.headers.get('User-Agent', '')}")
    
    # If there's an initialize method parameter in the query, respond with a direct JSON response
    # VS Code MCP may try to initialize via query param before establishing SSE connection
    if method_param == 'initialize' and request.method == 'GET':
        print(f"Handling initialize request from query params with ID: {id_param}")
        
        # Handle initialize directly without SSE for VS Code
        initialize_resp = {
            "jsonrpc": "2.0",
            "id": id_param or "initialize-request",
            "result": {
                "capabilities": {
                    "textDocumentSync": 1,
                    "completionProvider": {
                        "resolveProvider": True,
                        "triggerCharacters": ["."]
                    },
                    "documentFormattingProvider": True,
                    "executeCommandProvider": {
                        "commands": ["mcp.search", "mcp.read", "mcp.write"]
                    }
                },
                # Tools at top level - critical for VS Code/GitHub Copilot
                "tools": tools_list,
                "serverInfo": {
                    "name": "SMF Knowledge Server",
                    "version": "1.0.0"
                }
            }
        }
        
        print(f"Returning direct initialize response with {len(tools_list)} tools")
        return jsonify(initialize_resp)
    
    # Handle tools/list request in query params (VS Code style)
    if method_param == 'tools/list' and request.method == 'GET':
        print(f"Handling tools/list request from query params with ID: {id_param}")
        
        # Hardcoded tools for GitHub Copilot
        simple_tools = [
            {
                "id": "search",
                "name": "Search", 
                "description": "Search for notes containing specific text",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {
                            "type": "string",
                            "description": "The search query"
                        }
                    },
                    "required": ["query"]
                }
            },
            {
                "id": "create_note",
                "name": "Create Note",
                "description": "Create a new note",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Path where to create the note"
                        },
                        "content": {
                            "type": "string",
                            "description": "Content of the note"
                        }
                    },
                    "required": ["path", "content"]
                }
            }
        ]
        
        tools_resp = {
            "jsonrpc": "2.0",
            "id": id_param or "tools-request",
            "result": simple_tools  # Direct array at top level
        }
        
        response = jsonify(tools_resp)
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = '*'
        
        print(f"Returning direct tools/list response with {len(simple_tools)} tools")
        return response
        
    # Handle CORS preflight requests
    if request.method == "OPTIONS":
        print("Handling OPTIONS preflight request for SSE endpoint")
        response = app.make_default_options_response()
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = '*'
        return response
    
    # Handle POST requests - needed for JSON-RPC over POST
    if request.method == "POST":
        print("Processing POST request to SSE endpoint")
        
        # Try to parse request body
        try:
            if request.is_json:
                req_data = request.get_json()
                print(f"POST request body (JSON): {json.dumps(req_data)}")
                
                # Handle initialize method
                if req_data.get("method") == "initialize":
                    req_id = req_data.get("id", "initialize-request")
                    print(f"Initialize request received with ID {req_id}")
                    
                    # Response format per VS Code docs - tools must be at top level
                    resp = {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "result": {
                            "capabilities": {
                                "textDocumentSync": 1,
                                "completionProvider": {
                                    "resolveProvider": True,
                                    "triggerCharacters": ["."]
                                },
                                "documentFormattingProvider": True,
                                "executeCommandProvider": {
                                    "commands": ["mcp.search", "mcp.read", "mcp.write"]
                                }
                            },
                            # Tools MUST be at top level for GitHub Copilot to discover them
                            "tools": tools_list,
                            "serverInfo": {
                                "name": "SMF Knowledge Server",
                                "version": "1.0.0"
                            }
                        }
                    }
                    
                    print(f"Returning initialize response with {len(tools_list)} tools")
                    return jsonify(resp)
                
                # Handle tools/list method directly
                if req_data.get("method") == "tools/list" or req_data.get("method") == "$/tools/list":
                    req_id = req_data.get("id", "tools-list-request")
                    print(f"Tools list request received with ID {req_id}")
                    
                    # ALWAYS return tools directly at top level
                    resp = {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "result": tools_list  # Direct tools array at top level
                    }
                    
                    print(f"Returning tools list response with {len(tools_list)} tools")
                    return jsonify(resp)
                
                # Handle other regular methods
                method = req_data.get("method")
                params = req_data.get("params", {})
                req_id = req_data.get("id")
                
                if method:
                    print(f"Processing method: {method}")
                    result = handle_jsonrpc_method(method, params)
                    
                    # Return the result
                    if isinstance(result, dict) and "error" in result:
                        return jsonify({"jsonrpc": "2.0", "id": req_id, "error": result["error"]})
                    else:
                        return jsonify({"jsonrpc": "2.0", "id": req_id, "result": result})
            else:
                print("Request is not JSON, returning error")
                return jsonify({"error": "Invalid request format, expected JSON"}), 400
                
        except Exception as e:
            print(f"Error processing POST body: {e}")
            return jsonify({"error": f"Request processing error: {str(e)}"}), 500
    
    # For a pure GET request without method params, we'll establish an SSE connection
    print("Setting up an SSE stream for VS Code...")
    
    def generate():
        """Generate SSE events for VS Code and GitHub Copilot"""
        event_id = 0
        
        print("Starting SSE stream generation...")
        
        # FIRST: Send an initialize response with tools - clients need this even without a request
        # The message ID must be predictable for clients to identify
        initialize_response = {
            "jsonrpc": "2.0",
            "id": "vscode-initialize",  # Fixed ID that clients can identify
            "result": {
                "capabilities": {
                    "textDocumentSync": 1,
                    "documentFormattingProvider": True
                },
                # Tools MUST be at top level of result
                "tools": tools_list,
                "serverInfo": {
                    "name": "SMF Knowledge Server",
                    "version": "1.0.0"
                }
            }
        }
        
        print(f"SSE: Sending initialize response with {len(tools_list)} tools")
        event_id += 1
        yield f"data: {json.dumps(initialize_response)}\n\n"
        
        # If there was a specific initialization request, also send a response with the matching ID
        if id_param:
            initialize_response_with_id = {
                "jsonrpc": "2.0",
                "id": id_param,  # Use the exact ID from the request
                "result": {
                    "capabilities": {
                        "textDocumentSync": 1,
                        "completionProvider": {
                            "resolveProvider": True,
                            "triggerCharacters": ["."]
                        },
                        "documentFormattingProvider": True,
                        "executeCommandProvider": {
                            "commands": ["mcp.search", "mcp.read", "mcp.write"]
                        }
                    },
                    # Tools MUST be at top level of result
                    "tools": tools_list,
                    "serverInfo": {
                        "name": "SMF Knowledge Server",
                        "version": "1.0.0"
                    }
                }
            }
            
            print(f"SSE: Sending initialize response with request ID: {id_param}")
            event_id += 1
            yield f"data: {json.dumps(initialize_response_with_id)}\n\n"
        
        # SECOND: Send tools notification in standard MCP format
        vscode_tools_format = {
            "jsonrpc": "2.0",
            "method": "$/mcp.tools.list",
            "params": {
                "tools": tools_list
            }
        }
        event_id += 1
        print(f"SSE: Sending tools notification")
        yield f"data: {json.dumps(vscode_tools_format)}\n\n"
        
        # THIRD: Send tools list response with a fixed ID for GitHub Copilot
        # GitHub Copilot needs tools at the result level as a direct array
        copilot_tools_result = {
            "jsonrpc": "2.0", 
            "id": "tools-list",
            "result": tools_list  # Direct array at top level of result
        }
        event_id += 1
        print(f"SSE: Sending GitHub Copilot tools list result")
        yield f"data: {json.dumps(copilot_tools_result)}\n\n"
        
        # FOURTH: Send VS Code specific tools notification
        vscode_tools_result = {
            "jsonrpc": "2.0",
            "method": "workspace/didChangeConfiguration", 
            "params": {
                "settings": {
                    "tools": tools_list
                }
            }
        }
        event_id += 1
        print(f"SSE: Sending VS Code workspace configuration notification")
        yield f"data: {json.dumps(vscode_tools_result)}\n\n"
        
        # FIFTH: Send client/registerCapability notification (GitHub Copilot format)
        copilot_capability_notification = {
            "jsonrpc": "2.0",
            "method": "client/registerCapability",
            "params": {
                "registrations": [{
                    "id": "tools-capability",
                    "method": "workspace/didChangeConfiguration",
                    "registerOptions": {
                        "tools": tools_list
                    }
                }]
            }
        }
        event_id += 1
        print(f"SSE: Sending GitHub Copilot capability registration")
        yield f"data: {json.dumps(copilot_capability_notification)}\n\n"
        
        # SIXTH: Connection established notification
        connection_msg = {
            "jsonrpc": "2.0",
            "method": "$/mcp.connection.established",
            "params": {
                "timestamp": time.time(),
                "tools_count": len(tools_list)
            }
        }
        event_id += 1
        print(f"SSE: Sending connection established notification")
        yield f"data: {json.dumps(connection_msg)}\n\n"
        
        # HEARTBEAT LOOP: Send regular heartbeats to keep connection alive
        print(f"SSE: Starting heartbeat loop")
        interval = 5  # Shorter interval for better responsiveness
        
        # First heartbeat should be sent immediately
        event_id += 1
        heartbeat_msg = {
            "jsonrpc": "2.0",
            "method": "$/mcp.heartbeat",
            "params": {
                "timestamp": time.time(),
                "interval": interval
            }
        }
        yield f"data: {json.dumps(heartbeat_msg)}\n\n"
        
        # Continue with regular heartbeats
        while True:
            try:
                time.sleep(interval)
                event_id += 1
                heartbeat_msg = {
                    "jsonrpc": "2.0",
                    "method": "$/mcp.heartbeat",
                    "params": {
                        "timestamp": time.time(),
                        "interval": interval
                    }
                }
                yield f"data: {json.dumps(heartbeat_msg)}\n\n"
            except Exception as e:
                print(f"SSE Heartbeat error: {e}")
                break
    
    # Create simple SSE response with minimal headers - clients are sensitive to headers
    response = Response(stream_with_context(generate()), mimetype='text/event-stream')
    
    # Set essential SSE headers that clients need
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    response.headers['Content-Type'] = 'text/event-stream'
    
    # Add CORS headers for better cross-origin support
    response.headers['Access-Control-Allow-Origin'] = '*' 
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = '*'
    
    # Don't add Transfer-Encoding header - can cause issues with some proxies/clients
    
    print(f"SSE: Created response with headers: {response.headers}")
    return response

# Server-sent events endpoint for continuous connection (MCP standard)
@app.route('/events', methods=['GET', 'POST'])
def events():
    """Event stream for MCP clients that expect SSE format"""
    print("===== /events endpoint accessed =====")
    print(f"Method: {request.method}")
    print(f"Headers: {request.headers}")
    return sse_endpoint()  # Reuse the same implementation

# Handle WebSocket upgrade requests for VS Code compatibility
@app.route('/ws', methods=['GET', 'POST'])
def ws_endpoint():
    """WebSocket endpoint for VS Code compatibility"""
    print("===== /ws endpoint accessed =====")
    print(f"Method: {request.method}")
    print(f"Headers: {request.headers}")
    
    # If this is a WebSocket upgrade request, we can't actually handle it,
    # but we can respond with an SSE connection which VS Code might accept
    if request.headers.get('Upgrade', '').lower() == 'websocket':
        print("WebSocket upgrade requested, redirecting to SSE")
        return sse_endpoint()
    
    # Otherwise just treat it as a regular request
    return sse_endpoint()

# Handle VSCode initialize requests directly
@app.route('/initialize', methods=['POST', 'GET'])
def handle_initialize():
    """Special endpoint to handle initialize requests from VSCode and GitHub Copilot"""
    print("===== /initialize endpoint accessed =====")
    print(f"Request method: {request.method}")
    print(f"Request headers: {request.headers}")
    
    # Define hardcoded tools for GitHub Copilot
    tools_list = [
        {
            "id": "search",
            "name": "Search",
            "description": "Search for notes containing specific text",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The search query"
                    }
                },
                "required": ["query"]
            }
        },
        {
            "id": "create_note",
            "name": "Create Note",
            "description": "Create a new note in the knowledge base",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path where to create the note"
                    },
                    "title": {
                        "type": "string",
                        "description": "Title of the note"
                    },
                    "content": {
                        "type": "string",
                        "description": "Content of the note"
                    }
                },
                "required": ["path", "title", "content"]
            }
        },
        {
            "id": "conversation_search",
            "name": "Conversation Search",
            "description": "Search for conversations in the knowledge base",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string", 
                        "description": "The conversation search query"
                    }
                },
                "required": ["query"]
            }
        }
    ]
    
    # Get request data if available
    req_id = "initialize-request"
    if request.is_json:
        try:
            data = request.get_json()
            req_id = data.get("id", req_id)
            print(f"Initialize request JSON: {json.dumps(data)}")
        except Exception as e:
            print(f"Error parsing JSON from request: {e}")
            
    # If an ID is passed as a query parameter, use that instead
    if request.args.get('id'):
        req_id = request.args.get('id')
        print(f"Using ID from query parameter: {req_id}")
    
    # Simplified response format for GitHub Copilot
    # The key difference is tools must be at the top level in the result object
    resp = {
        "jsonrpc": "2.0",
        "id": req_id,
        "result": {
            "capabilities": {
                "textDocumentSync": 1,
                "documentFormattingProvider": True
            },
            # CRITICAL: Place tools at top level in result for GitHub Copilot compatibility
            "tools": tools_list,
            "serverInfo": {
                "name": "SMF Knowledge Server",
                "version": "1.0.0"
            }
        }
    }
    
    # Set response headers for CORS
    response = jsonify(resp)
    response.headers['Access-Control-Allow-Origin'] = '*' 
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = '*'
    
    print(f"Returning initialize response with {len(tools_list)} tools")
    return response

# VS Code WebSocket-style endpoint with path parameters
@app.route('/<path:urlpath>', methods=['POST', 'GET'])
def handle_vscode_path_requests(urlpath):
    """Handle VS Code requests with path parameters"""
    print(f"===== VS Code path request: /{urlpath} =====")
    print(f"Request method: {request.method}")
    print(f"Request headers: {request.headers}")
    print(f"Query parameters: {request.args}")
    
    # If the path includes 'initialize' or similar initialization pattern
    if 'initialize' in urlpath.lower():
        print(f"Handling initialize request via path: /{urlpath}")
        return handle_initialize()
    # If the path includes 'tools' or 'tool-list'
    elif any(tool_path in urlpath.lower() for tool_path in ['tools', 'tool-list', 'tools/list']):
        print(f"Handling tools request via path: /{urlpath}")
        # Get tools list directly
        tools = handle_jsonrpc_method("tools/list", {})
        # Make sure tools is a list
        if not isinstance(tools, list):
            if isinstance(tools, dict) and "tools" in tools:
                tools = tools.get("tools", [])
            else:
                tools = []
        # Return tools directly
        return jsonify(tools)
    # Check for SSE connection request
    elif 'sse' in urlpath.lower() or 'events' in urlpath.lower():
        print(f"Routing to SSE endpoint via path: /{urlpath}")
        return sse_endpoint()
    # If it looks like a websocket connection request
    elif 'ws' in urlpath.lower() or 'websocket' in urlpath.lower():
        print(f"Routing to WebSocket-compatible endpoint via path: /{urlpath}")
        return sse_endpoint()
    # For unknown paths, try to handle as a standard JSON-RPC request
    else:
        print(f"Treating as JSON-RPC request: /{urlpath}")
        # Try to extract method from path
        method = urlpath.split('/')[-1]
        # Get JSON-RPC request from query parameters or body
        params = {}
        for key, value in request.args.items():
            params[key] = value
        # Try to handle the method
        result = handle_jsonrpc_method(method, params)
        # Return result
        return jsonify({
            "jsonrpc": "2.0",
            "id": request.args.get('id', "path-request"),
            "result": result
        })

# Special endpoint that GitHub Copilot may use to discover tools
@app.route('/tools', methods=['GET'])
def get_tools():
    """Endpoint for VS Code/GitHub Copilot to directly fetch tools list"""
    print("===== /tools endpoint accessed =====")
    print(f"Request headers: {request.headers}")
    
    # Hardcoded tools list for GitHub Copilot
    tools_list = [
        {
            "id": "search",
            "name": "Search",
            "description": "Search for notes containing specific text",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The search query"
                    }
                },
                "required": ["query"]
            }
        },
        {
            "id": "create_note",
            "name": "Create Note",
            "description": "Create a new note in the knowledge base",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path where to create the note"
                    },
                    "title": {
                        "type": "string",
                        "description": "Title of the note"
                    },
                    "content": {
                        "type": "string",
                        "description": "Content of the note"
                    }
                },
                "required": ["path", "title", "content"]
            }
        },
        {
            "id": "conversation_search",
            "name": "Conversation Search",
            "description": "Search for conversations in the knowledge base",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string", 
                        "description": "The conversation search query"
                    }
                },
                "required": ["query"]
            }
        }
    ]
    
    print(f"Returning {len(tools_list)} tools directly from /tools endpoint")
    
    # Some clients might expect a JSON-RPC formatted response
    if request.args.get('format') == 'jsonrpc':
        response = jsonify({
            "jsonrpc": "2.0",
            "id": request.args.get('id', 'tools-request'),
            "result": tools_list  # Return as top-level array in the result
        })
        response.headers['Access-Control-Allow-Origin'] = '*'
        return response
    
    # Default: return direct array with appropriate headers
    response = jsonify(tools_list)  # Return the array directly, not in an object
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = '*'
    return response

# VS Code specific JSON-RPC over HTTP endpoint
@app.route('/jsonrpc-vscode', methods=['GET', 'POST'])
def jsonrpc_vscode_endpoint():
    """Simplified JSON-RPC endpoint specifically for VS Code"""
    print("===== VS Code JSON-RPC endpoint accessed =====")
    print(f"Method: {request.method}")
    print(f"Headers: {request.headers}")
    
    # Get tools list for initialize and tools/list methods
    tools_list = handle_jsonrpc_method("tools/list", {})
    
    # Make sure tools is a list
    if not isinstance(tools_list, list):
        if isinstance(tools_list, dict) and "tools" in tools_list:
            tools_list = tools_list.get("tools", [])
        else:
            tools_list = []
    
    # For GET requests, handle query parameters
    if request.method == 'GET':
        method = request.args.get('method')
        req_id = request.args.get('id', 'vscode-request')
        
        # Special handling for initialize
        if method == 'initialize':
            print(f"Handling VS Code initialize request with ID: {req_id}")
            return jsonify({
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "capabilities": {
                        "textDocumentSync": 1,
                        "completionProvider": {
                            "resolveProvider": True,
                            "triggerCharacters": ["."]
                        },
                        "documentFormattingProvider": True
                    },
                    # Tools at top level
                    "tools": tools_list,
                    "serverInfo": {
                        "name": "SMF Knowledge Server",
                        "version": "1.0.0"
                    }
                }
            })
        
        # Special handling for tools/list
        elif method == 'tools/list':
            print(f"Handling VS Code tools/list request with ID: {req_id}")
            return jsonify({
                "jsonrpc": "2.0",
                "id": req_id,
                "result": tools_list  # Direct array
            })
    
    # For POST requests, handle JSON body
    if request.method == 'POST' and request.is_json:
        data = request.get_json()
        if not data:
            return jsonify({"error": "Invalid request"}), 400
        
        method = data.get('method')
        params = data.get('params', {})
        req_id = data.get('id', 'vscode-request')
        
        # Special handling for initialize
        if method == 'initialize':
            print(f"Handling VS Code initialize POST request with ID: {req_id}")
            return jsonify({
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "capabilities": {
                        "textDocumentSync": 1,
                        "completionProvider": {
                            "resolveProvider": True,
                            "triggerCharacters": ["."]
                        },
                        "documentFormattingProvider": True,
                        "executeCommandProvider": {
                            "commands": ["mcp.search", "mcp.read", "mcp.write"]
                        }
                    },
                    # Tools at top level
                    "tools": tools_list,
                    "serverInfo": {
                        "name": "SMF Knowledge Server",
                        "version": "1.0.0"
                    }
                }
            })
        
        # Special handling for tools/list
        elif method == 'tools/list':
            print(f"Handling VS Code tools/list POST request with ID: {req_id}")
            return jsonify({
                "jsonrpc": "2.0",
                "id": req_id,
                "result": tools_list  # Direct array
            })
            
        # Process other methods
        else:
            print(f"Handling VS Code method: {method}")
            result = handle_jsonrpc_method(method, params)
            
            if isinstance(result, dict) and "error" in result:
                return jsonify({
                    "jsonrpc": "2.0", 
                    "id": req_id,
                    "error": result["error"]
                })
            else:
                return jsonify({
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": result
                })
    
    # Default response with capabilities
    return jsonify({
        "jsonrpc": "2.0",
        "id": "vscode-default",
        "result": {
            "capabilities": {
                "textDocumentSync": 1,
                "completionProvider": {
                    "resolveProvider": True,
                    "triggerCharacters": ["."]
                },
                "documentFormattingProvider": True
            },
            "tools": tools_list,  # Tools at top level
            "serverInfo": {
                "name": "SMF Knowledge Server",
                "version": "1.0.0"
            }
        }
    })


# Load config on startup
load_config()

# Define a clean entry point for stdio mode
def run_stdio_mode():
    """Run the server in stdio mode instead of HTTP mode"""
    from io import StringIO
    import sys
    import time
    
    print("Starting SMF Knowledge Server in stdio mode...", file=sys.stderr)
    
    # Load config at startup
    load_config()
    
    # Helper function to write JSON-RPC responses
    def write_response(response):
        """Write JSON-RPC response to stdout with proper headers"""
        json_response = json.dumps(response)
        content_length = len(json_response)
        sys.stdout.write(f"Content-Length: {content_length}\r\n\r\n")
        sys.stdout.write(json_response)
        sys.stdout.flush()
        print(f"Sent response: {content_length} bytes", file=sys.stderr)
    
    # Helper function to read JSON-RPC requests
    def read_request():
        """Read a JSON-RPC request from stdin using Content-Length headers"""
        headers = {}
        content_length = 0
        
        # Read headers
        while True:
            try:
                line = sys.stdin.readline().strip()
                if not line:
                    break
                    
                if ':' not in line:
                    print(f"Invalid header line: {line}", file=sys.stderr)
                    continue
                    
                key, value = line.split(':', 1)
                headers[key.strip()] = value.strip()
            except Exception as e:
                print(f"Error reading header: {e}", file=sys.stderr)
                # If we can't read headers, simulate an initialize request
                return {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "initialize"
                }
        
        # Get content length
        if 'Content-Length' in headers:
            try:
                content_length = int(headers['Content-Length'])
            except ValueError:
                print(f"Invalid Content-Length: {headers['Content-Length']}", file=sys.stderr)
                return None
        else:
            print("Missing Content-Length header, simulating initialize request", file=sys.stderr)
            # If there's no content length, simulate an initialize request
            return {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize"
            }
        
        # Read content
        try:
            content = sys.stdin.read(content_length)
            
            # Parse JSON
            try:
                request = json.loads(content)
                print(f"Successfully parsed request: {json.dumps(request)}", file=sys.stderr)
                return request
            except json.JSONDecodeError as e:
                print(f"JSON parse error: {e}", file=sys.stderr)
                # If we can't parse the JSON, simulate an initialize request
                return {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "initialize"
                }
        except Exception as e:
            print(f"Error reading content: {e}", file=sys.stderr)
            # If we can't read content, simulate an initialize request
            return {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize"
            }
            
    # Get tools list - define hardcoded tools for GitHub Copilot compatibility
    tools_list = [
        {
            "id": "search",
            "name": "Search",
            "description": "Search for notes containing specific text",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The search query"
                    }
                },
                "required": ["query"]
            }
        },
        {
            "id": "create_note",
            "name": "Create Note",
            "description": "Create a new note in the knowledge base",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path where to create the note"
                    },
                    "title": {
                        "type": "string",
                        "description": "Title of the note"
                    },
                    "content": {
                        "type": "string",
                        "description": "Content of the note"
                    }
                },
                "required": ["path", "title", "content"]
            }
        },
        {
            "id": "context_search",
            "name": "Context Search",
            "description": "Search for specific contexts in the knowledge base",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The context search query"
                    },
                    "category": {
                        "type": "string",
                        "description": "Optional category to filter by (e.g., 'Shared', 'Claude')"
                    }
                },
                "required": ["query"]
            }
        },
        {
            "id": "conversation_search",
            "name": "Conversation Search",
            "description": "Search for conversations in the knowledge base",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string", 
                        "description": "The conversation search query"
                    },
                    "agent": {
                        "type": "string",
                        "description": "Optional agent to filter by (e.g., 'Claude', 'GPT')"
                    },
                    "date_from": {
                        "type": "string",
                        "description": "Optional start date in YYYYMMDD format"
                    },
                    "date_to": {
                        "type": "string",
                        "description": "Optional end date in YYYYMMDD format"
                    }
                },
                "required": ["query"]
            }
        },
        {
            "id": "knowledge_summary",
            "name": "Knowledge Summary",
            "description": "Get a summary of available knowledge in the SMF",
            "parameters": {
                "type": "object",
                "properties": {
                    "category": {
                        "type": "string",
                        "description": "Optional category to filter by (e.g., 'Contexts', 'Conversations')"
                    }
                }
            }
        }
    ]
    
    print(f"Using {len(tools_list)} hardcoded tools for GitHub Copilot compatibility", file=sys.stderr)
    
    # Send an initial initialize response specifically formatted for GitHub Copilot
    print("Sending initial initialize response for GitHub Copilot", file=sys.stderr)
    initialize_response = {
        "jsonrpc": "2.0",
        "id": 1,
        "result": {
            "capabilities": {
                "textDocumentSync": 1,
                "completionProvider": {
                    "resolveProvider": True,
                    "triggerCharacters": ["."]
                },
                "documentFormattingProvider": True,
                "hoverProvider": True,
                "documentSymbolProvider": True,
                "executeCommandProvider": {
                    "commands": ["mcp.search", "mcp.read", "mcp.write"]
                },
                "experimental": {
                    "mcpSupport": True,
                    "supportsLSP": True,
                    "tools": tools_list  # Include tools here for VS Code
                }
            },
            # Include tools at the top level - this is what GitHub Copilot expects
            "tools": tools_list,
            "serverInfo": {
                "name": "SMF Knowledge Server",
                "version": "1.0.0"
            }
        }
    }
    write_response(initialize_response)
    
    # Wait a bit for the initialize response to be processed
    time.sleep(0.5)
    
    # Send tools notification specifically in GitHub Copilot format
    print("Sending tools notification in GitHub Copilot format", file=sys.stderr)
    copilot_tools_notification = {
        "jsonrpc": "2.0",
        "method": "client/registerCapability",
        "params": {
            "registrations": [{
                "id": "tools-capability",
                "method": "workspace/didChangeConfiguration",
                "registerOptions": {
                    "tools": tools_list
                }
            }]
        }
    }
    write_response(copilot_tools_notification)
    time.sleep(0.1)
    
    # Send standard VS Code MCP tools notification
    vscode_format = {
        "jsonrpc": "2.0",
        "method": "$/mcp.tools.list",
        "params": {
            "tools": tools_list
        }
    }
    write_response(vscode_format)
    time.sleep(0.1)
    
    # Simple format without namespace
    simple_format = {
        "jsonrpc": "2.0",
        "method": "tools/list",
        "result": {
            "tools": tools_list
        }
    }
    write_response(simple_format)
    
    # Process requests in a loop
    print("Waiting for requests...", file=sys.stderr)
    while True:
        try:
            request = read_request()
            if not request:
                print("Empty request received, sending heartbeat", file=sys.stderr)
                # Send a heartbeat message
                write_response({
                    "jsonrpc": "2.0",
                    "method": "$/mcp.heartbeat",
                    "params": {"timestamp": time.time()}
                })
                continue
                
            print(f"Processing request: {json.dumps(request)}", file=sys.stderr)
            
            # Special handling for initialize requests
            if request.get("method") == "initialize":
                print("Received initialize request", file=sys.stderr)
                
                # Send the initialize response again
                print("Sending initialize response", file=sys.stderr)
                initialize_response["id"] = request.get("id", 1)
                write_response(initialize_response)
                
                # Wait a bit for the initialize response to be processed
                time.sleep(0.5)
                
                # Send tools notification specifically in GitHub Copilot format
                print("Sending tools notification in GitHub Copilot format", file=sys.stderr)
                copilot_tools_notification = {
                    "jsonrpc": "2.0",
                    "method": "client/registerCapability",
                    "params": {
                        "registrations": [{
                            "id": "tools-capability",
                            "method": "workspace/didChangeConfiguration",
                            "registerOptions": {
                                "tools": tools_list
                            }
                        }]
                    }
                }
                write_response(copilot_tools_notification)
                time.sleep(0.1)
                
                # Send standard VS Code MCP tools notification
                vscode_format = {
                    "jsonrpc": "2.0",
                    "method": "$/mcp.tools.list",
                    "params": {
                        "tools": tools_list
                    }
                }
                write_response(vscode_format)
                continue
            
            # Special handling for capability requests and tool-related methods
            elif request.get("method") == "capabilities" or request.get("method") == "$/getCapabilities":
                capabilities_response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id", "capabilities-id"),
                    "result": {
                        "capabilities": {
                            "textDocumentSync": 1,
                            "completionProvider": {
                                "resolveProvider": True,
                                "triggerCharacters": ["."]
                            },
                            "documentFormattingProvider": True,
                            "experimental": {
                                "mcpSupport": True,
                                "tools": tools_list
                            }
                        },
                        "tools": tools_list,  # Include at top level for GitHub Copilot
                        "serverInfo": {
                            "name": "SMF Knowledge Server",
                            "version": "1.0.0"
                        }
                    }
                }
                write_response(capabilities_response)
                continue
            
            elif request.get("method") == "tools/list" or request.get("method") == "$/tools/list":
                tools_response = {
                    "jsonrpc": "2.0",
                    "id": request.get("id", "tools-id"),
                    "result": {
                        "tools": tools_list
                    }
                }
                write_response(tools_response)
                continue
                
            # Handle other methods
            method = request.get("method", "")
            params = request.get("params", {})
            request_id = request.get("id")
            
            if not method:
                print("Invalid request: missing method", file=sys.stderr)
                write_response({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {
                        "code": INVALID_REQUEST,
                        "message": "Invalid Request: Method is required"
                    }
                })
                continue
                
            # Process the method
            print(f"Handling method: {method}", file=sys.stderr)
            result = handle_jsonrpc_method(method, params)
            
            # Check if result contains an error
            if isinstance(result, dict) and "error" in result:
                print(f"Method returned error: {result['error']}", file=sys.stderr)
                write_response({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": result["error"]
                })
            else:
                print(f"Method returned success", file=sys.stderr)
                write_response({
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": result
                })
                
        except Exception as e:
            print(f"Error processing request: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc(file=sys.stderr)

# Choose which mode to run based on environment variable
if __name__ == '__main__':
    # Enable GitHub Copilot debugging
    print("=== SMF Knowledge Server starting up ===")
    print(f"Python version: {sys.version}")
    print(f"Environment variables: MCP_MODE={os.environ.get('MCP_MODE', 'sse')}")
    print(f"Arguments: {sys.argv}")
    
    # Check if we should run in stdio mode
    stdio_mode = os.environ.get('MCP_MODE', 'sse').lower() == 'stdio'
    
    if stdio_mode:
        print("=== Starting in stdio mode for GitHub Copilot integration ===")
        # Run in stdio mode
        run_stdio_mode()
    else:
        print(f"=== Starting in HTTP/SSE mode on port {os.environ.get('PORT', DEFAULT_PORT)} ===")
        # Run in HTTP/SSE mode
        port = int(os.environ.get('PORT', DEFAULT_PORT))
        app.run(host='0.0.0.0', port=port, debug=True)