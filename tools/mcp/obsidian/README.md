# Obsidian-Based Shared Memory Framework Server

A universal, tool-agnostic server that provides a unified interface for all AI tools to access and manipulate knowledge stored in your Obsidian-based Shared Memory Framework.

## Features

- RESTful API for shared memory access
- Search notes by query
- Read note contents
- Write new notes or update existing ones
- Time-aware conversation sorting and organization
- Templated knowledge creation for conversations, contexts, and prompts
- Compatible with any AI system that can make HTTP requests
- Seamless integration with all AI tools through Python

## Setup

1. **Use the Python management script** (recommended):

   ```bash
   # From the top-level mcp directory
   python ../manage-mcp.py configure
   python ../manage-mcp.py start
   ```

   The server will run on port 5678 by default.

2. **Check server status and troubleshoot if needed**:

   ```bash
   # Check status
   python ../manage-mcp.py status
   
   # Test the server connectivity
   python ../smf.py test-jsonrpc
   
   # Repair if issues are found
   python ../manage-mcp.py repair
   ```

## API Endpoints

The server provides the following endpoints:

- `GET /health` - Check server health and configuration status
- `GET /search?query=<term>` - Search for notes matching the query
- `GET /read?path=<path>` - Read note content (can specify multiple paths)
- `POST /write` - Write content to a note (JSON body with path and content)
- `GET /metadata` - Get metadata about the vault structure

## Integration with AI Tools

This server can be used with any AI tool that can make HTTP requests:

### AI Tool Integration

- **Large Language Models**: Any LLM with web access or function calling capabilities can use this API
- **IDE Assistants**: Tools like GitHub Copilot, Cody, or Cursor can connect through VS Code extensions
- **Chat Interfaces**: ChatGPT, Claude, Bard, etc. can access knowledge through Python commands
- **Custom AI Tools**: Any custom AI tool can connect directly to the API

## SMF CLI (Recommended Interface)

The recommended way to interact with the Shared Memory Framework is through the SMF CLI:

```bash
# List recent conversations (time-sorted)
python ../smf.py recent --limit 10

# Search for notes
python ../smf.py search "terraform"

# Read a note
python ../smf.py read "AI/Memory/Contexts/Shared/TerraformBestPractices.md"

# Create a conversation log with timestamp
python ../smf.py conversation "Claude" "Topic" --content "Conversation summary"

# Create a context file
python ../smf.py context "Shared" "ContextName" --content "Reusable knowledge" 

# Create a system prompt
python ../smf.py prompt "Shared" "PromptName" --content "System instructions"
```

## Universal Client (Lower-Level Access)

For direct access to the API without templates and additional features, the universal client is available:

```bash
# Check server status
python ./adapters/universal_client.py status

# Search for notes
python ./adapters/universal_client.py search "terraform"

# Read a note
python ./adapters/universal_client.py read "AI/Memory/Contexts/Shared/TerraformBestPractices.md"

# Write a note with direct content
python ./adapters/universal_client.py write "AI/Memory/Contexts/Test/NewNote.md" "# Test Note\n\nThis is a test."

# Write a note using content from a file
python ./adapters/universal_client.py write "AI/Memory/Contexts/Test/NewNote.md" "" --file /path/to/content.md
```

## Why Use This Server?

The Shared Memory Framework Server provides a centralized access point for all your AI tools to connect to your knowledge base. This ensures:

1. **Consistency**: All tools access the same knowledge in the same way
2. **Interoperability**: Knowledge referenced in one AI tool can be found by another
3. **Efficiency**: Single point of maintenance and updates for your knowledge framework
4. **Future-proofing**: As new AI tools emerge, they can easily integrate with your existing knowledge

For detailed API documentation, see [server/api_docs.md](server/api_docs.md).  
For tool-specific integration guides, see the [adapters](adapters/) directory.