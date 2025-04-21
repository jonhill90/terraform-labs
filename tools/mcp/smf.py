#!/usr/bin/env python3
"""
SMF CLI - Shared Memory Framework Command Line Interface
A cross-platform (Windows, Mac, Linux) CLI for interacting with the Shared Memory Framework
"""

import argparse
import json
import os
import subprocess
import sys
import datetime

# Set the path to the universal client
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CLIENT_PATH = os.path.join(SCRIPT_DIR, "obsidian", "adapters", "universal_client.py")


def check_dependencies():
    """Check if required dependencies are installed"""
    # Try to import requests in the client environment instead
    # We'll let any errors in the client itself be handled by the run_client function
    pass


def check_client_exists():
    """Check if the universal client exists"""
    if not os.path.isfile(CLIENT_PATH):
        print(f"Error: Universal client not found at {CLIENT_PATH}")
        sys.exit(1)


def run_client(args):
    """Run the universal client with the given arguments"""
    # First, try using the same Python interpreter as this script
    cmd = [sys.executable, CLIENT_PATH] + args
    
    try:
        # Try running with the current Python interpreter
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        # If the error is about missing modules, try with system python
        if "ModuleNotFoundError: No module named" in e.stderr:
            try:
                # Try with 'python3' command (common on most systems)
                cmd[0] = 'python3'
                result = subprocess.run(cmd, capture_output=True, text=True, check=True)
                return result.stdout
            except (subprocess.CalledProcessError, FileNotFoundError) as e2:
                # If python3 fails, try with 'python' command
                try:
                    cmd[0] = 'python'
                    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
                    return result.stdout
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


def search_notes(query):
    """Search for notes matching the query"""
    result = run_client(["search", query])
    try:
        data = json.loads(result)
        print(json.dumps(data, indent=2))
    except json.JSONDecodeError:
        print(result)


def get_recent_conversations(agent="Claude", limit=5):
    """
    Get recent conversations for a specific agent, sorted by date/time (most recent first)
    
    Args:
        agent: The agent name (default: "Claude")
        limit: Maximum number of conversations to return (default: 5)
        
    Returns:
        List of sorted conversation paths with date/time information
    """
    result = run_client(["search", agent])
    try:
        data = json.loads(result)
        # Filter conversations only
        conversations = [path for path in data if f"AI/Memory/Conversations/{agent}/" in path]
        
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
    except json.JSONDecodeError:
        print("Error parsing JSON response")
        return []


def read_note(path):
    """Read a note by path"""
    result = run_client(["read", path])
    try:
        data = json.loads(result)
        print(json.dumps(data, indent=2))
    except json.JSONDecodeError:
        print(result)


def write_note(path, content):
    """Write content to a note"""
    result = run_client(["write", path, content])
    try:
        data = json.loads(result)
        print(json.dumps(data, indent=2))
    except json.JSONDecodeError:
        print(result)


def check_status():
    """Check server status"""
    result = run_client(["status"])
    try:
        data = json.loads(result)
        print(json.dumps(data, indent=2))
    except json.JSONDecodeError:
        print(result)

def test_jsonrpc():
    """Test JSON-RPC connectivity for MCP"""
    print("Testing JSON-RPC connectivity for MCP...")
    
    # Test basic search request
    sample_request = {
        "jsonrpc": "2.0",
        "method": "search",
        "params": {"query": "test"},
        "id": 1
    }
    
    # Write request to a temporary file
    test_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "test_jsonrpc.json")
    with open(test_file, 'w') as f:
        json.dump(sample_request, f)
    
    # Call the client with JSON-RPC mode
    try:
        cmd = [sys.executable, CLIENT_PATH, "--jsonrpc"]
        result = subprocess.run(cmd, input=json.dumps(sample_request), 
                              capture_output=True, text=True, check=False)
        
        print("=== JSON-RPC Test Results ===")
        print(f"Exit code: {result.returncode}")
        print("--- Response ---")
        
        try:
            response = json.loads(result.stdout)
            print(json.dumps(response, indent=2))
            
            if "error" in response:
                print("❌ Test failed: Received error response")
            else:
                print("✅ Test passed: Received successful response")
        except json.JSONDecodeError:
            print("❌ Raw output (not valid JSON):")
            print(result.stdout)
            print("--- Error output ---")
            print(result.stderr)
    
    except Exception as e:
        print(f"❌ Test error: {e}")
    
    # Clean up
    if os.path.exists(test_file):
        os.remove(test_file)


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
    
    # Write the file
    write_note(filepath, template)
    return filepath


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
    
    # Write the file
    write_note(filepath, template)
    return filepath


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
    
    # Write the file
    write_note(filepath, template)
    return filepath


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
    check_dependencies()

    parser = argparse.ArgumentParser(
        description="SMF - Shared Memory Framework CLI"
    )
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # Search command
    search_parser = subparsers.add_parser("search", help="Search for notes")
    search_parser.add_argument("query", help="Search query")

    # Read command
    read_parser = subparsers.add_parser("read", help="Read a note by path")
    read_parser.add_argument("path", help="Note path")

    # Write command
    write_parser = subparsers.add_parser("write", help="Write content to a note")
    write_parser.add_argument("path", help="Note path")
    write_parser.add_argument("content", help="Content to write")

    # Status command
    subparsers.add_parser("status", help="Check server status")
    
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