# Model Context Protocol (MCP) Tools

This directory contains tools for connecting AI systems to external knowledge sources using both universal and protocol-specific approaches.

## Quick Start

```bash
# Start the Shared Memory Framework
python ./manage-mcp.py start

# Check server status
python ./manage-mcp.py status

# Configure your knowledge sources
python ./manage-mcp.py configure

# Interact with the knowledge base (using SMF CLI)
python ./smf.py search "terraform"  # Search for content (cross-platform)
python ./smf.py read "path/to/file.md"  # Read content
python ./smf.py write "path/to/file.md" "content"  # Write content
python ./smf.py recent  # List recent conversations sorted by date/time
python ./smf.py conversation "Claude" "Topic" --content "Conversation summary"  # Log a conversation

# Repair MCP connectivity issues
python ./manage-mcp.py repair

# Stop the server when done
python ./manage-mcp.py stop
```

## Available Knowledge Connectors

### Obsidian

The Shared Memory Framework Server provides a universal REST API that connects any AI tool to an Obsidian-based knowledge vault.

The server provides endpoints for searching, reading, and writing to your knowledge base. For complete documentation, see the [Obsidian MCP README](obsidian/README.md).

## Using the Framework with Claude and GitHub Copilot

The knowledge framework works with multiple AI assistants:

### Claude Integration

Claude interacts with the knowledge framework through Python commands, making it more platform-agnostic and flexible:

1. **Start the MCP server**:
   ```bash
   python ./manage-mcp.py start
   ```

2. **Verify the server is running**:
   ```bash
   python ./manage-mcp.py status
   ```

3. **Claude uses the Python SMF CLI directly**:
   ```bash
   # Search for knowledge
   python ./smf.py search "terraform"
   
   # Read specific contexts
   python ./smf.py read "AI/Memory/Contexts/Shared/TerraformBestPractices.md"
   
   # List recent conversations (sorted by date/time)
   python ./smf.py recent --limit 5
   
   # Create new memory entries
   python ./smf.py conversation "Claude" "Topic" --content "Conversation summary"
   ```

4. **Reference knowledge in conversations using wikilinks**:
   ```
   Please use the knowledge from [[AI/Memory/Contexts/Shared/TerraformBestPractices]]
   ```

### GitHub Copilot Integration

GitHub Copilot can access the knowledge framework through the VS Code MCP extension:

1. **Generate the VS Code configuration**:
   ```bash
   python ./manage-mcp.py config-vscode
   ```

2. **Use the stdio mode configuration for best compatibility**:
   - Copy `.vscode/mcp-copilot.json` to `.vscode/mcp.json`
   
   This configuration uses stdio mode which is more reliable for Copilot integration.

3. **Start the stdio server manually if needed**:
   ```bash
   python ./tools/mcp/start-stdio.py
   ```

4. **Troubleshoot GitHub Copilot integration**:
   ```bash
   # Check server logs
   tail -f ./tools/mcp/obsidian/server.log
   
   # Repair MCP connections
   python ./manage-mcp.py repair
   ```

5. **Available tools for GitHub Copilot**:
   - Search: Find notes containing specific text
   - Create Note: Create a new note in the knowledge base
   - Context Search: Search for specific contexts
   - Conversation Search: Search for conversations
   - Knowledge Summary: Get a summary of available knowledge

## Using the SMF CLI (Simplified Interface)

The SMF CLI provides a simplified interface for interacting with your knowledge base.

### Python Version (Cross-Platform - Windows, Mac, Linux)

The Python version works on Windows, macOS, and Linux, making it the preferred choice for cross-platform compatibility.

```bash
# Search for notes
python ./smf.py search "terraform"

# Read a specific note
python ./smf.py read "AI/Memory/Contexts/Shared/TerraformBestPractices.md"

# List recent conversations (sorted by date/time)
python ./smf.py recent --limit 10

# Write a new note or update an existing one
python ./smf.py write "AI/Memory/Conversations/Claude/YYYYMMDD-Topic.md" "Content here"

# Create a conversation log with timestamp
python ./smf.py conversation "Claude" "Topic" --content "Conversation summary"

# Create a context file
python ./smf.py context "Shared" "ContextName" --content "Reusable knowledge"

# Create a system prompt
python ./smf.py prompt "Shared" "PromptName" --content "System instructions"

# Check server status
python ./smf.py status

# Test JSON-RPC connectivity 
python ./smf.py test-jsonrpc

# View help information
python ./smf.py --help
```

Prerequisites:
- Python 3.6+
- Requests library (`pip install requests`)
- SMF CLI automatically tries to handle dependency issues by trying multiple Python interpreters

### Benefits of SMF CLI

- Cross-platform compatibility with the Python version
- Shorter, more intuitive commands than using the universal client directly
- Consistent interface for all operations
- Time-aware conversation continuity for chronological sorting
- Enhanced content creation with templates for various knowledge types
- Helpful error messages and built-in documentation
- Intelligent Python interpreter detection for handling dependencies

## Using the Universal Client Directly

The universal client provides the underlying functionality for the SMF CLI and can be used directly if needed:

```bash
# Search for notes
python ./obsidian/adapters/universal_client.py search "terraform"

# Read a specific note
python ./obsidian/adapters/universal_client.py read "AI/Memory/Contexts/Shared/TerraformBestPractices.md"

# Write a new note or update an existing one
python ./obsidian/adapters/universal_client.py write "AI/Memory/Conversations/Claude/YYYYMMDD-Topic.md" "Content here"

# Write using content from a file
python ./obsidian/adapters/universal_client.py write "AI/Memory/Conversations/Claude/YYYYMMDD-Topic.md" "" --file path_to_content.md
```

However, the SMF CLI is recommended as it offers additional features like time-aware conversation sorting, templated content creation, and a more user-friendly interface.

## Future Integrations

Additional knowledge source connectors are planned for future development, including:

- Document Management Systems
- Enterprise Knowledge Bases
- Code Repositories
- Additional Note-taking Applications

Each connector will follow the same universal interface pattern, allowing AI tools to access knowledge consistently regardless of the source.

## Universal Interface Principles

All MCP tools in this repository follow these principles:

1. **Universal Access**: Any AI tool can connect, not just specific models
2. **Consistent API**: Common patterns for searching, reading, and writing
3. **Local-first**: Data remains under your control with local processing
4. **Extensible**: Easy to add new knowledge sources while maintaining the same interface

## Complete Setup Guide

To set up the Shared Memory Framework with your Obsidian vault:

1. **Configure the server** with your vault path:
   ```bash
   python ./manage-mcp.py configure
   ```

2. **Start the server**:
   ```bash
   python ./manage-mcp.py start
   ```

3. **Add instructions to CLAUDE.md and CLAUDE.local.md**:
   - Add SMF documentation to instruct Claude how to use the framework
   - Include examples of referencing and creating knowledge
   - Specify the time-aware conversation continuity format

4. **Verify everything is working**:
   ```bash
   python ./manage-mcp.py status
   python ./smf.py test-jsonrpc
   ```

5. **Troubleshoot if needed**:
   ```bash
   python ./manage-mcp.py repair
   ```