# COPILOT.md

This file provides guidance to GitHub Copilot when working with code in this repository.

## MCP Integration

GitHub Copilot can connect to the Shared Memory Framework (SMF) using the Model Context Protocol (MCP). The SMF server supports both SSE and stdio modes, as per VS Code's specifications.

### Setup Instructions

#### Option 1: SSE Mode (Recommended)

1. Generate VS Code configuration automatically:
   ```bash
   python ./tools/mcp/manage-mcp.py config-vscode
   ```
   This creates the `.vscode/mcp.json` file for you.

2. Start the MCP server:
   ```bash
   python ./tools/mcp/manage-mcp.py start
   ```

3. Verify that VS Code and GitHub Copilot can connect to the server.

#### Option 2: stdio Mode

1. For direct stdio communication, modify your `.vscode/mcp.json` file to use the stdio wrapper script.

2. Restart VS Code for the changes to take effect.

#### Troubleshooting

If you encounter issues with tool discovery:
- Ensure only one MCP server is running (`python ./tools/mcp/manage-mcp.py status`)
- Check server logs in the designated location
- Try repair command: `python ./tools/mcp/manage-mcp.py repair`

### Knowledge Reference Format

When you need to use existing knowledge:

1. Reference contexts using:
   ```
   Please use the knowledge from [[AI/Memory/Contexts/Shared/TerraformBestPractices]]
   ```

2. Reference system prompts using:
   ```
   Please apply the system prompt from [[AI/Memory/System_Prompts/Shared/TerraformRefactoring]]
   ```

3. Reference past conversations using:
   ```
   Continue from our previous conversation: [[AI/Memory/Conversations/Claude/20250419-SharedMemoryFramework]]
   ```

## Code Style Guidelines
- **Terraform**: Use snake_case for resources/variables, 2-space indentation
- **Python**: Use snake_case, standard imports first followed by third-party
- **PowerShell**: Use PascalCase for functions, camelCase for variables

## Git Workflow
- Commit messages should be descriptive and use present tense
- Use the standard workflow: add, commit, pull, push