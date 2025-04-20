#!/usr/bin/env python3
"""
SMF CLI - Shared Memory Framework Command Line Interface
A cross-platform (Windows, Mac, Linux) CLI for interacting with the Shared Memory Framework
using the official MCP (Model Context Protocol) standard
"""

import argparse
import json
import os
import subprocess
import sys
import datetime
import uuid

# Set the path to the universal client
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CLIENT_PATH = os.path.join(SCRIPT_DIR, "obsidian", "adapters", "universal_client.py")


def check_client_exists():
    """Check if the universal client exists"""
    if not os.path.isfile(CLIENT_PATH):
        print(f"Error: Universal client not found at {CLIENT_PATH}")
        sys.exit(1)


def run_jsonrpc_request(method, params=None, request_id=None):
    """
    Run a JSON-RPC request using the official MCP protocol
    
    Args:
        method: The method name (get, list, search, write, batch)
        params: Parameters for the method
        request_id: Optional request ID (defaults to random UUID)
        
    Returns:
        The result of the JSON-RPC request
    """
    if params is None:
        params = {}
    
    if request_id is None:
        request_id = str(uuid.uuid4())
    
    # Create a JSON-RPC 2.0 request
    request = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "id": request_id
    }
    
    # First, try using the same Python interpreter as this script
    cmd = [sys.executable, CLIENT_PATH, "--jsonrpc"]
    
    try:
        # Try running with the current Python interpreter
        result = subprocess.run(
            cmd, 
            input=json.dumps(request),
            capture_output=True, 
            text=True, 
            check=True
        )
        
        # Parse the JSON response
        try:
            response = json.loads(result.stdout)
            
            # Check for errors
            if "error" in response:
                print(f"Error: {response['error'].get('message', 'Unknown error')}")
                if "code" in response["error"]:
                    print(f"Error code: {response['error']['code']}")
                return None
            
            # Return the result
            return response.get("result")
        except json.JSONDecodeError:
            print(f"Error: Invalid JSON response")
            print(f"Response: {result.stdout}")
            return None
            
    except subprocess.CalledProcessError as e:
        # If the error is about missing modules, try with system python
        if "ModuleNotFoundError: No module named" in e.stderr:
            try:
                # Try with 'python3' command (common on most systems)
                cmd[0] = 'python3'
                result = subprocess.run(
                    cmd, 
                    input=json.dumps(request),
                    capture_output=True, 
                    text=True, 
                    check=True
                )
                
                try:
                    response = json.loads(result.stdout)
                    if "error" in response:
                        print(f"Error: {response['error'].get('message', 'Unknown error')}")
                        return None
                    return response.get("result")
                except json.JSONDecodeError:
                    print(f"Error: Invalid JSON response")
                    print(f"Response: {result.stdout}")
                    return None
                    
            except (subprocess.CalledProcessError, FileNotFoundError) as e2:
                # If python3 fails, try with 'python' command
                try:
                    cmd[0] = 'python'
                    result = subprocess.run(
                        cmd, 
                        input=json.dumps(request),
                        capture_output=True, 
                        text=True, 
                        check=True
                    )
                    
                    try:
                        response = json.loads(result.stdout)
                        if "error" in response:
                            print(f"Error: {response['error'].get('message', 'Unknown error')}")
                            return None
                        return response.get("result")
                    except json.JSONDecodeError:
                        print(f"Error: Invalid JSON response")
                        print(f"Response: {result.stdout}")
                        return None
                        
                except (subprocess.CalledProcessError, FileNotFoundError) as e3:
                    print("Error: Failed to run the universal client with any Python interpreter.")
                    print("Please ensure that the 'requests' package is installed in your Python environment.")
                    print("You can install it with: pip install requests")
                    sys.exit(1)
        else:
            print(f"Error executing command: {e}")
            if e.stderr:
                print(f"Error output: {e.stderr}")
            sys.exit(1)


def run_batch_request(operations):
    """
    Run a batch of operations in parallel using the MCP batch method
    
    Args:
        operations: List of operation objects with method, params, and optional id
        
    Returns:
        Dict of results keyed by operation ID
    """
    # Ensure each operation has an ID
    for operation in operations:
        if "id" not in operation:
            operation["id"] = str(uuid.uuid4())
    
    # Create batch request
    params = {
        "operations": operations
    }
    
    # Run the batch request
    return run_jsonrpc_request("batch", params)


def get_server_capabilities():
    """Get server capabilities"""
    return run_jsonrpc_request("capabilities", {})


def search_notes(query):
    """Search for notes matching the query using MCP protocol"""
    result = run_jsonrpc_request("search", {"query": query})
    if result is not None:
        print(json.dumps(result, indent=2))


def get_recent_conversations(agent="Claude", limit=5):
    """
    Get recent conversations for a specific agent, sorted by date/time (most recent first)
    
    Args:
        agent: The agent name (default: "Claude")
        limit: Maximum number of conversations to return (default: 5)
        
    Returns:
        List of sorted conversation paths with date/time information
    """
    result = run_jsonrpc_request("search", {"query": agent})
    if result is None:
        return []
    
    try:
        # Filter conversations only
        conversations = [path for path in result if f"AI/Memory/Conversations/{agent}/" in path]
        
        # Extract date/time information and create tuples for sorting
        conversation_dates = []
        for path in conversations:
            # Extract the date from the filename (format: YYYYMMDD-Topic.md or YYYYMMDD-HHMM-Topic.md)
            filename = os.path.basename(path)
            if "-" not in filename:
                continue
                
            # Try to parse with date and time first
            date_part = filename.split("-")[0]
            parts = filename.split("-")
            
            try:
                # For both formats, we always have at least a date
                date_time = datetime.datetime.strptime(date_part, "%Y%m%d")
                
                # Check if we have a timestamp component (format: YYYYMMDD-HHMM-Topic.md)
                if len(parts) >= 3 and len(parts[1]) == 4 and parts[1].isdigit():
                    # This is a timestamped conversation
                    time_part = parts[1]
                    time_obj = datetime.datetime.strptime(time_part, "%H%M").time()
                    date_time = datetime.datetime.combine(date_time.date(), time_obj)
                
                # Add to our list
                conversation_dates.append((path, date_time))
            except (ValueError, IndexError):
                # Fallback: just use the filename and put it at the end
                conversation_dates.append((path, datetime.datetime(1970, 1, 1)))
        
        # Sort by date/time, newest first
        conversation_dates.sort(key=lambda x: x[1], reverse=True)
        
        # Return the paths, limited to the requested number
        return conversation_dates[:limit]
    except Exception as e:
        print(f"Error parsing response: {e}")
        return []


def read_note(path):
    """Read a note by path using MCP protocol"""
    result = run_jsonrpc_request("get", {"path": path})
    if result is not None:
        print(json.dumps(result, indent=2) if isinstance(result, dict) else result)


def list_notes(path="AI/Memory"):
    """List notes in a directory using MCP protocol"""
    result = run_jsonrpc_request("list", {"path": path})
    if result is not None:
        print(json.dumps(result, indent=2))


def write_note(path, content):
    """Write content to a note using MCP protocol"""
    result = run_jsonrpc_request("write", {"path": path, "content": content})
    if result is not None:
        print(json.dumps(result, indent=2))


def check_status():
    """Check server status"""
    # Try to get server capabilities
    capabilities = get_server_capabilities()
    if capabilities is not None:
        print("Server status: Running")
        print("Supported methods:", capabilities.get("methods", []))
        print("Server version:", capabilities.get("version", "unknown"))
        print("Server name:", capabilities.get("name", "unknown"))
    else:
        print("Server status: Not running or not responding")


def test_jsonrpc():
    """Test JSON-RPC connectivity for MCP"""
    print("Testing JSON-RPC connectivity for MCP...")
    
    # Test capabilities request
    print("\nTesting capabilities endpoint...")
    capabilities = get_server_capabilities()
    if capabilities is not None:
        print("✅ Capabilities endpoint working")
        print(f"Server supports: {capabilities.get('methods', [])}")
    else:
        print("❌ Capabilities endpoint failed")
    
    # Test search method
    print("\nTesting search method...")
    search_result = run_jsonrpc_request("search", {"query": "test"})
    if search_result is not None:
        print("✅ Search method working")
    else:
        print("❌ Search method failed")
    
    # Test batch request if supported
    if capabilities and "batch" in capabilities.get("methods", []):
        print("\nTesting batch method...")
        batch_operations = [
            {"method": "search", "params": {"query": "test"}, "id": "search1"},
            {"method": "get", "params": {"path": "AI/Memory/README.md"}, "id": "get1"}
        ]
        batch_result = run_batch_request(batch_operations)
        if batch_result is not None:
            print("✅ Batch method working")
        else:
            print("❌ Batch method failed")
    
    print("\nJSON-RPC test completed.")


def create_conversation_log(agent, topic, content=None):
    """Create a new conversation log with the standard template"""
    now = datetime.datetime.now()
    date_only = now.strftime("%Y%m%d")
    time_stamp = now.strftime("%H%M")
    filepath = f"AI/Memory/Conversations/{agent}/{date_only}-{time_stamp}-{topic}.md"
    
    # Create template
    template = f"""---
title: "{agent} Conversation: {topic}"
agent: "{agent}"
date: "{now.strftime('%Y-%m-%d %H:%M')}"
project: "Terraform Labs"
tags: [terraform, conversation, {topic.lower()}]
---

# {agent} Conversation: {topic}

## Context
- Initial conversation about {topic}

## Conversation
{content if content else "- Key points and insights will be added here"}

## Actions
- Follow-up items to be determined

## Memory Extraction
- New contexts to be identified
"""
    
    # Write the file using MCP protocol
    result = write_note(filepath, template)
    if result is not None:
        print(f"Created conversation log: {filepath}")
        return filepath
    return None


def create_context_file(category, name, content=None):
    """Create a new context file with the standard template"""
    filepath = f"AI/Memory/Contexts/{category}/{name}.md"
    
    # Create template
    template = f"""---
title: "{name}"
agent: "{category}"
date: "{datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}"
tags: [terraform, context, {name.lower()}]
status: "active"
---

# {name}

## Overview
{content if content else "Brief description"}

## Key Information
- Important fact 1
- Important fact 2

## Code Examples
```terraform
# Code example
```

## Related Contexts
- Add related contexts here

## Source Conversations
- Add source conversations here
"""
    
    # Write the file using MCP protocol
    result = write_note(filepath, template)
    if result is not None:
        print(f"Created context file: {filepath}")
        return filepath
    return None


def create_system_prompt(category, name, content=None):
    """Create a new system prompt file with the standard template"""
    filepath = f"AI/Memory/System_Prompts/{category}/{name}.md"
    
    # Create template
    template = f"""---
title: "{name}"
agent: "{category}"
date: "{datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}"
tags: [terraform, system_prompt, {name.lower()}]
status: "active"
---

# {name}

{content if content else "Detailed system prompt instructions that can be applied by AI assistants."}
"""
    
    # Write the file using MCP protocol
    result = write_note(filepath, template)
    if result is not None:
        print(f"Created system prompt: {filepath}")
        return filepath
    return None


def list_recent_conversations(agent, limit):
    """Display a list of recent conversations sorted by date/time"""
    conversations = get_recent_conversations(agent, limit)
    
    if not conversations:
        print(f"No conversations found for agent '{agent}'")
        return
    
    print(f"\nRecent {agent} conversations (sorted by date/time):\n")
    
    for idx, (path, date_time) in enumerate(conversations, 1):
        # Extract the topic from the path
        filename = os.path.basename(path)
        parts = filename.split("-")
        
        # Handle both YYYYMMDD-Topic.md and YYYYMMDD-HHMM-Topic.md formats
        if len(parts) >= 3 and len(parts[1]) == 4 and parts[1].isdigit():
            # YYYYMMDD-HHMM-Topic.md format (we prioritize showing these)
            topic = "-".join(parts[2:]).replace(".md", "")
            time_str = f"{date_time.strftime('%Y-%m-%d %H:%M')}"
        else:
            # YYYYMMDD-Topic.md format
            topic = "-".join(parts[1:]).replace(".md", "")
            time_str = f"{date_time.strftime('%Y-%m-%d')}"
            
        print(f"{idx}. {topic} ({time_str})")
        print(f"   Path: {path}")
    
    print("\nTo read a conversation, use: python smf.py read \"PATH\"")
    print(f"Example: python smf.py read \"{conversations[0][0]}\"")


def main():
    """Main function"""
    check_client_exists()

    parser = argparse.ArgumentParser(
        description="SMF - Shared Memory Framework CLI (MCP Protocol Compatible)"
    )
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # Search command
    search_parser = subparsers.add_parser("search", help="Search for notes")
    search_parser.add_argument("query", help="Search query")

    # Read command
    read_parser = subparsers.add_parser("read", help="Read a note by path")
    read_parser.add_argument("path", help="Note path")
    
    # List command
    list_parser = subparsers.add_parser("list", help="List notes in a directory")
    list_parser.add_argument("--path", default="AI/Memory", help="Directory path to list (default: AI/Memory)")

    # Write command
    write_parser = subparsers.add_parser("write", help="Write content to a note")
    write_parser.add_argument("path", help="Note path")
    write_parser.add_argument("content", help="Content to write")

    # Status command
    subparsers.add_parser("status", help="Check server status and capabilities")
    
    # Test JSON-RPC command
    subparsers.add_parser("test-jsonrpc", help="Test JSON-RPC connectivity for MCP")
    
    # Recent conversations command
    recent_parser = subparsers.add_parser("recent", help="List recent conversations")
    recent_parser.add_argument("--agent", default="Claude", help="Agent name (default: Claude)")
    recent_parser.add_argument("--limit", type=int, default=10, help="Maximum number of conversations to show (default: 10)")
    
    # Create conversation log command
    conversation_parser = subparsers.add_parser("conversation", help="Create a new conversation log")
    conversation_parser.add_argument("agent", help="Agent name (e.g., Claude, GPT)")
    conversation_parser.add_argument("topic", help="Conversation topic")
    conversation_parser.add_argument("--content", help="Optional conversation content")
    
    # Create context file command
    context_parser = subparsers.add_parser("context", help="Create a new context file")
    context_parser.add_argument("category", help="Category (e.g., Shared, Claude)")
    context_parser.add_argument("name", help="Context name")
    context_parser.add_argument("--content", help="Optional context content")
    
    # Create system prompt command
    prompt_parser = subparsers.add_parser("prompt", help="Create a new system prompt")
    prompt_parser.add_argument("category", help="Category (e.g., Shared, Claude)")
    prompt_parser.add_argument("name", help="Prompt name")
    prompt_parser.add_argument("--content", help="Optional prompt content")

    # Parse arguments
    args = parser.parse_args()

    # Execute command
    if args.command == "search":
        search_notes(args.query)
    elif args.command == "read":
        read_note(args.path)
    elif args.command == "list":
        list_notes(args.path)
    elif args.command == "write":
        write_note(args.path, args.content)
    elif args.command == "status":
        check_status()
    elif args.command == "test-jsonrpc":
        test_jsonrpc()
    elif args.command == "recent":
        list_recent_conversations(args.agent, args.limit)
    elif args.command == "conversation":
        create_conversation_log(args.agent, args.topic, args.content)
    elif args.command == "context":
        create_context_file(args.category, args.name, args.content)
    elif args.command == "prompt":
        create_system_prompt(args.category, args.name, args.content)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()