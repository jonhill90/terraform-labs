# Shared Memory Framework

This document outlines the Shared Memory Framework used for maintaining persistent knowledge across AI assistants in this project.

## Overview

The Shared Memory Framework is an Obsidian-based system that enables AI assistants to:
- Store and retrieve contextual knowledge
- Access standardized system prompts
- Reference past conversations
- Maintain continuity between sessions
- Share knowledge across different AI assistants

## Directory Structure

```
AI/Memory/
├── Contexts/              # Reusable knowledge chunks
│   ├── [Agent]/           # Agent-specific contexts
│   └── Shared/            # Contexts shared across all AIs
│
├── Conversations/         # Logs of important conversations
│   └── [Agent]/           # Agent-specific conversation logs
│
├── Projects/              # Project-specific information
│
├── System_Prompts/        # Reusable system prompts
│   ├── [Agent]/           # Agent-specific prompts
│   └── Shared/            # Prompts shared across all AIs
│
└── Templates/             # Templates for creating new files
```

## Reference Formats

Knowledge is referenced using Obsidian wikilinks:

1. Context references:
   ```
   [[AI/Memory/Contexts/Category/Name]]
   ```

2. System prompt references:
   ```
   [[AI/Memory/System_Prompts/Category/Name]]
   ```

3. Conversation references:
   ```
   [[AI/Memory/Conversations/Agent/YYYYMMDD-Topic]]
   ```

## Document Structure

Each file in the memory framework follows a standardized structure:

### Context Files

```markdown
---
title: "Context Title"
agent: "Agent Name"
date: "YYYY-MM-DD"
tags: [tag1, tag2]
status: "active|archived"
---

# Context Title

## Overview
Brief description

## Key Information
- Important fact 1
- Important fact 2

## Code Examples
```language
// Code example
```

## Related Contexts
- [[Link to related context]]

## Source Conversations
- [[Link to source conversation]]
```

### Conversation Logs

```markdown
---
title: "Agent Conversation: Topic"
agent: "Agent Name"
date: "YYYY-MM-DD"
project: "Project Name"
tags: [tag1, tag2]
---

# Agent Conversation: Topic

## Context
- Links to relevant memory files

## Conversation
- Key points and insights

## Actions
- Follow-up items
- Decisions made

## Memory Extraction
- New contexts to save
- Prompt improvements
```

### System Prompts

```markdown
---
title: "Prompt Title"
agent: "Agent Name"
date: "YYYY-MM-DD"
tags: [tag1, tag2]
status: "active|archived"
---

# Prompt Title

Detailed system prompt instructions that can be applied by AI assistants.
The format varies based on the specific prompt purpose.
```

## Agent Integration

Each AI assistant is integrated with the shared memory framework through agent-specific configuration files:

- **[AGENT].md / [AGENT].local.md**: Configuration files for each AI agent

These files provide:
1. Instructions for accessing the framework
2. Templates for creating new entries
3. Auto-logging instructions for capturing conversations

## Usage Examples

### Accessing Knowledge

```
Please use the knowledge from [[AI/Memory/Contexts/Shared/TerraformBestPractices]]
```

### Applying System Prompts

```
Please apply the system prompt from [[AI/Memory/System_Prompts/Shared/TerraformRefactoring]]
```

### Referencing Conversations

```
Continue from our previous conversation: [[AI/Memory/Conversations/Agent/20250419-Topic]]
```

## Auto-Logging

AI assistants are configured to automatically log significant conversations to the shared memory framework without user prompting. This ensures continuous knowledge capture and accumulation.

## Benefits

- **Continuity**: Maintains context between different sessions
- **Cross-AI Knowledge**: Shares information between different AI assistants
- **Standardization**: Ensures consistent application of best practices
- **Accumulation**: Builds a knowledge base over time
- **Specialization**: Allows each AI to contribute its strengths

## Implementation

To add a new AI agent to the framework:

1. Create directories for the agent in:
   - Contexts
   - Conversations
   - System_Prompts

2. Create configuration files:
   - [AGENT].md (committed to repository)
   - [AGENT].local.md (contains local paths, not committed)

3. Create an initial system prompt that instructs the agent to:
   - Reference the shared memory framework
   - Apply relevant system prompts
   - Log significant conversations

4. Update .gitignore to exclude [AGENT].local.md

## Future Enhancements

- Integration with version control systems
- Automated knowledge extraction and summarization
- Knowledge graph visualization
- Intelligence metrics and usage analytics