# VS Code Integration with Shared Memory Framework

This guide explains how to integrate the Shared Memory Framework Server with VS Code, enabling seamless access to knowledge for both developers and AI assistants like GitHub Copilot and Claude for VS Code.

## Quick Start

1. **Start the MCP server**:
   ```bash
   # From the repository root
   ./tools/mcp/manage-mcp.sh start
   ```

2. **Install the VS Code integration** (if available):
   ```bash
   cd tools/mcp/obsidian/adapters
   npm install -g vscode-knowledge-connector  # Example package name
   ```

3. **Connect to Claude Code** (for Claude for VS Code):
   ```bash
   claude mcp add obsidian -- python /path/to/tools/mcp/obsidian/adapters/universal_client.py
   ```

## VS Code Extension Options

### Option 1: Knowledge Navigator Extension (Recommended)

A VS Code extension that provides:

- Sidebar to browse your knowledge base
- Search functionality within your knowledge
- Insert knowledge into comments with a click
- Direct knowledge reference for AI tools

#### Extension Features
- **Knowledge Browser**: Navigate your Obsidian vault structure
- **Search**: Find knowledge across your entire vault
- **Insert**: Add knowledge as formatted comments
- **Reference**: Create direct knowledge references for AI tools
- **Create**: Save new knowledge directly from VS Code

### Option 2: Universal Client Script Integration

Use the universal client directly with VS Code tasks:

1. Create a VS Code task in `.vscode/tasks.json`:
   ```json
   {
     "version": "2.0.0",
     "tasks": [
       {
         "label": "Search Knowledge",
         "type": "shell",
         "command": "python ${workspaceFolder}/tools/mcp/obsidian/adapters/universal_client.py search \"${input:searchQuery}\" | code -",
         "problemMatcher": []
       },
       {
         "label": "Read Knowledge",
         "type": "shell",
         "command": "python ${workspaceFolder}/tools/mcp/obsidian/adapters/universal_client.py read \"${input:notePath}\" | code -",
         "problemMatcher": []
       }
     ],
     "inputs": [
       {
         "id": "searchQuery",
         "description": "Search query",
         "default": "terraform",
         "type": "promptString"
       },
       {
         "id": "notePath",
         "description": "Note path (e.g. AI/Memory/Contexts/Shared/TerraformBestPractices.md)",
         "default": "",
         "type": "promptString"
       }
     ]
   }
   ```

2. Run the tasks from the Command Palette: `Tasks: Run Task`

### Option 3: Knowledge Comment Format

If you don't want to use an extension, you can use standardized comment formats:

```python
# KNOWLEDGE_REF: [[AI/Memory/Contexts/Shared/TerraformBestPractices]]
# 
# This code implements infrastructure using Terraform following best practices:
# - Use modules for reusable components
# - Separate environments with tfvars files
# - Follow naming conventions described in the knowledge base
```

Both GitHub Copilot and Claude for VS Code will learn from these comments.

## Knowledge-Enhanced Terraform Development

Create Terraform files with knowledge references:

```terraform
# KNOWLEDGE_REF: [[AI/Memory/Contexts/Shared/TerraformBestPractices]]
# 
# Module structure best practices:
# - One resource per file if complex
# - Group related resources in sensible files
# - Use snake_case for all resource names
# - Always use description in variables

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
  
  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
```

## Building a VS Code Extension

To build a custom VS Code extension for the Shared Memory Framework:

1. **Create a new extension**:
   ```bash
   npm install -g yo generator-code
   yo code
   ```

2. **Add API client** to connect to the Shared Memory Framework Server:
   ```typescript
   // client.ts
   export async function searchKnowledge(query: string): Promise<any> {
     const response = await fetch(`http://localhost:5678/search?query=${encodeURIComponent(query)}`);
     return response.json();
   }
   
   export async function readKnowledge(path: string): Promise<any> {
     const response = await fetch(`http://localhost:5678/read?path=${encodeURIComponent(path)}`);
     return response.json();
   }
   ```

3. **Create UI components** for browsing and inserting knowledge

4. **Publish your extension** to the VS Code Marketplace

## Integration with Claude for VS Code

When using Claude for VS Code:

1. Make sure the MCP server is running
2. Register Claude with the MCP server
3. Use knowledge references in your conversations with Claude:
   ```
   Please help me improve this Terraform code based on our best practices in [[AI/Memory/Contexts/Shared/TerraformBestPractices]]
   ```

Claude will automatically access the knowledge and apply it to your code.