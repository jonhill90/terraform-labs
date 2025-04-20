# CODEX.md

This file provides guidance to Codex when working with code in this repository.

## Build/Lint/Test Commands
- Terraform init: `terraform init`
- Terraform validate: `terraform validate`
- Terraform plan: `terraform plan -var-file=env/[environment].tfvars`
- Terraform apply: `terraform apply -var-file=env/[environment].tfvars`
- Packer validate: `packer validate -var-file=variables/[config].pkrvars.hcl [template].pkr.hcl`
- Python tests: `python -m pytest apps/mdp-adf/tests/[test_file.py]`

## Code Style Guidelines
- **Terraform**: Use snake_case for resources/variables, 2-space indentation, descriptive resource names
- **Python**: Use snake_case, standard imports first followed by third-party, f-strings for interpolation
- **PowerShell**: Use PascalCase for functions, camelCase for variables, try/catch for error handling
- **Structure**: Maintain modular approach with reusable components and environment separation
- **Documentation**: Include descriptive comments for complex operations
- **Pipelines**: Follow established CI/CD patterns in the pipelines/ directory

## Git Workflow
- **Commit Process**: Always commit changes following this workflow:
  ```bash
  git add . && git commit -m "your message" && git pull && git push
  ```
- **Message Format**: Use descriptive, present-tense commit messages that explain what the change accomplishes

## Shared Knowledge Framework
This repository uses an Obsidian-based shared memory framework for AI agents. If a CODEX.local.md file exists, it contains path information for accessing this framework.

### Framework Access
The Shared Memory Framework is accessible via MCP (Model Context Protocol). This is the preferred access method. If MCP is not available, fall back to direct filesystem access as specified in CODEX.local.md.

To ensure the MCP server is running:
```bash
python ./tools/mcp/manage-mcp.py start
```

To check MCP server status, use the `/mcp` command.

### Knowledge Reference Format
When a user mentions "shared memory" or asks to use existing knowledge:
1. Look for structured knowledge in the shared memory system
2. Reference contexts using: `[[AI/Memory/Contexts/Category/Name]]`
3. Reference system prompts using: `[[AI/Memory/System_Prompts/Category/Name]]`
4. Reference conversations using: `[[AI/Memory/Conversations/Agent/YYYYMMDD-Topic]]`

### Previous Conversation Continuity
At the start of new sessions, proactively ask the user if they would like to continue a previous conversation:

1. Use the SMF recent command to find time-sorted conversations:
   ```bash
   python ./tools/mcp/smf.py recent --limit 5
   ```

2. Present the most recent 2-3 conversations with a prompt:
   "Would you like to continue a previous conversation? I found these recent topics:"
   - [Topic 1] from [Date]
   - [Topic 2] from [Date]
   
3. If the user selects a conversation, load it using:
   ```bash
   python ./tools/mcp/smf.py read "AI/Memory/Conversations/Codex/YYYYMMDD-Topic.md"
   ```

### Knowledge Storage
After completing significant tasks, automatically log the conversation to the shared memory framework using the MCP connection.

```bash
# Using the SMF CLI to write conversations
python ./tools/mcp/smf.py conversation "Codex" "Topic" --content "Conversation content here"

# Or create a context file with reusable knowledge
python ./tools/mcp/smf.py context "Shared" "ContextName" --content "Context information here"

# Alternatively write directly to a specific path
python ./tools/mcp/smf.py write "AI/Memory/Conversations/Codex/$(date +%Y%m%d)-Topic.md" "Conversation content here"

# Using the universal client directly (not recommended)
python ./tools/mcp/obsidian/adapters/universal_client.py write "AI/Memory/Conversations/Codex/$(date +%Y%m%d)-Topic.md" "Conversation content here"
```