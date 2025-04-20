# Model Context Protocol (MCP) Tools

This directory contains tools for connecting AI systems to external knowledge sources using both universal and protocol-specific approaches.

## Quick Start

```bash
# Start the Shared Memory Framework
./manage-mcp.sh start

# Check server status
./manage-mcp.sh status

# Configure your knowledge sources
./manage-mcp.sh configure

# Interact with the knowledge base (using SMF CLI)
python ./tools/mcp/smf.py search "terraform"  # Search for content (cross-platform)
python ./tools/mcp/smf.py read "path/to/file.md"  # Read content
python ./tools/mcp/smf.py write "path/to/file.md" "content"  # Write content

# Stop the server when done
./manage-mcp.sh stop
```

## Available Knowledge Connectors

### Obsidian

The Shared Memory Framework Server provides a universal REST API that connects any AI tool to an Obsidian-based knowledge vault.

The server provides endpoints for searching, reading, and writing to your knowledge base. For complete documentation, see the [Obsidian MCP README](obsidian/README.md).

## Setting Up Claude Code with MCP

1. **Start the MCP server**:
   ```bash
   ./manage-mcp.sh start
   ```

2. **Register Claude Code with the MCP server**:
   ```bash
   claude mcp add obsidian -- python ./tools/mcp/obsidian/adapters/universal_client.py
   ```

3. **Verify the connection**:
   ```bash
   ./manage-mcp.sh status
   ```
   Or in Claude Code, use the `/mcp` command

4. **Reference knowledge in conversations with Claude**:
   ```
   Please use the knowledge from [[AI/Memory/Contexts/Shared/TerraformBestPractices]]
   ```

## Using the SMF CLI (Simplified Interface)

The SMF CLI provides a simplified interface for interacting with your knowledge base.

### Python Version (Cross-Platform - Windows, Mac, Linux)

The Python version works on Windows, macOS, and Linux, making it the preferred choice for cross-platform compatibility.

```bash
# Search for notes
python ./tools/mcp/smf.py search "terraform"

# Read a specific note
python ./tools/mcp/smf.py read "AI/Memory/Contexts/Shared/TerraformBestPractices.md"

# Write a new note or update an existing one
python ./tools/mcp/smf.py write "AI/Memory/Conversations/Claude/YYYYMMDD-Topic.md" "Content here"

# Check server status
python ./tools/mcp/smf.py status

# View help information
python ./tools/mcp/smf.py --help
```

Prerequisites:
- Python 3.6+
- Requests library (`pip install requests`)
- SMF CLI automatically tries to handle dependency issues by trying multiple Python interpreters

### Shell Script Version (Unix/Mac Only)

The shell script version is only compatible with Unix-based systems like macOS and Linux.

```bash
# Search for notes
./tools/mcp/smf.sh search "terraform"

# Read a specific note
./tools/mcp/smf.sh read "AI/Memory/Contexts/Shared/TerraformBestPractices.md"

# Write a new note or update an existing one
./tools/mcp/smf.sh write "AI/Memory/Conversations/Claude/YYYYMMDD-Topic.md" "Content here"

# Check server status
./tools/mcp/smf.sh status

# View help information
./tools/mcp/smf.sh help
```

### Benefits of SMF CLI

- Cross-platform compatibility with the Python version
- Shorter, more intuitive commands than using the universal client directly
- Consistent interface for all operations
- Helpful error messages and built-in documentation
- Intelligent Python interpreter detection for handling dependencies

## Using the Universal Client Directly

The universal client provides the underlying functionality for the SMF CLI and can be used directly:

```bash
# Search for notes
python ./tools/mcp/obsidian/adapters/universal_client.py search "terraform"

# Read a specific note
python ./tools/mcp/obsidian/adapters/universal_client.py read "AI/Memory/Contexts/Shared/TerraformBestPractices.md"

# Write a new note or update an existing one
python ./tools/mcp/obsidian/adapters/universal_client.py write "AI/Memory/Conversations/Claude/YYYYMMDD-Topic.md" "Content here"

# Write using content from a file (new method)
python ./tools/mcp/obsidian/adapters/universal_client.py write "AI/Memory/Conversations/Claude/YYYYMMDD-Topic.md" "" --file path_to_content.md
```

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
   ./manage-mcp.sh configure
   ```

2. **Start the server**:
   ```bash
   ./manage-mcp.sh start
   ```

3. **Register Claude Code** with the MCP server:
   ```bash
   claude mcp add obsidian -- python ./tools/mcp/obsidian/adapters/universal_client.py
   ```

4. **Add instructions to CLAUDE.md and CLAUDE.local.md**:
   - Add MCP documentation to instruct Claude how to use the framework
   - Include examples of referencing and creating knowledge

5. **Verify everything is working**:
   ```bash
   ./manage-mcp.sh status
   ```