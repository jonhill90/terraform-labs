# AI Integration Guides

This document provides guidance on integrating various AI tools with the Shared Memory Framework Server.

## Claude Code Integration

Claude Code has built-in support for the MCP protocol. To connect Claude Code to the Shared Memory Framework Server:

1. **Start the MCP server** using the management script:
   ```bash
   # From the top-level mcp directory
   ./manage-mcp.sh start
   ```

2. **Register the universal client** with Claude Code:
   ```bash
   # Replace with your actual path
   claude mcp add obsidian -- python /path/to/tools/mcp/obsidian/adapters/universal_client.py
   ```

3. **Verify the connection** using the `/mcp` command in Claude Code:
   ```
   /mcp
   ```
   
   You should see the obsidian client listed as registered.

4. **Reference knowledge** in your conversations with Claude:
   ```
   Please use the knowledge from [[AI/Memory/Contexts/Shared/TerraformBestPractices]]
   ```

5. **Store new knowledge** by asking Claude to save important information:
   ```
   Please save this conversation to the shared memory framework
   ```

### Knowledge Reference Patterns

Claude Code understands these reference patterns:

1. **Context files** - Reference existing knowledge:
   ```
   [[AI/Memory/Contexts/Category/Name]]
   ```

2. **System prompts** - Apply specific behavior instructions:
   ```
   [[AI/Memory/System_Prompts/Category/Name]]
   ```

3. **Conversations** - Reference previous discussions:
   ```
   [[AI/Memory/Conversations/Agent/YYYYMMDD-Topic]]
   ```

### Automatic Knowledge Storage

When you have significant conversations with Claude Code, it can automatically log them to your knowledge framework by running:

```bash
python ./tools/mcp/obsidian/adapters/universal_client.py write "AI/Memory/Conversations/Claude/$(date +%Y%m%d)-Topic.md" "Conversation content here"
```

## GitHub Copilot Integration

GitHub Copilot doesn't have a direct integration mechanism, but you can use structured comments:

1. Create a comment format that includes knowledge references:
   ```python
   # KNOWLEDGE: From UniversalKnowledge/TerraformBestPractices
   # 
   # Best practices for Terraform module development:
   # - Create modules for reusable infrastructure components
   # - Use consistent naming conventions
   # - Document all variables with descriptions
   # - Implement sensible defaults
   ```

2. Use a VS Code extension or script to fetch and insert knowledge from the server

## ChatGPT Integration

For ChatGPT, there are a few options:

1. **Custom GPTs with Knowledge Retrieval**:
   - Create a custom GPT that can access your knowledge server
   - Use API calls to fetch knowledge when needed

2. **Browser Extensions**:
   - Use extensions like WebGPT that allow ChatGPT to make API calls
   - Configure the extension to access your local knowledge server

3. **Copy-Paste Method**:
   - Use the universal client to retrieve knowledge
   - Copy and paste the knowledge into your ChatGPT conversation

## Browser Extension Development

A browser extension could be developed to:

1. Intercept prompts to AI tools
2. Scan for knowledge references like `[[Knowledge/Path]]`
3. Replace these references with actual content from the knowledge server
4. Forward the enhanced prompt to the AI tool

This would work across multiple AI platforms including ChatGPT, Claude (web), and others.