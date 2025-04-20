#!/usr/bin/env python3
import os
import json
import re
from flask import Flask, request, jsonify
from flask_cors import CORS

# Configuration - will be loaded from config file or environment variables
DEFAULT_PORT = 5678

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

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

@app.route('/config', methods=['GET', 'POST'])
def manage_config():
    """Get or update server configuration"""
    if request.method == 'GET':
        # Return sanitized config (no sensitive data)
        return jsonify({
            "vault_configured": config["vault_path"] is not None,
            "api_version": "0.1.0"
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

# Load config on startup
load_config()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', DEFAULT_PORT))
    app.run(host='0.0.0.0', port=port, debug=True)