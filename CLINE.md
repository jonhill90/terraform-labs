# CLINE.md

This file provides guidance for using Cline with a shared memory framework.

## What is Cline?

Cline is a command-line interface for Claude that can be integrated with a shared memory framework stored in Obsidian. This integration enhances Cline's capabilities by providing access to persistent knowledge.

## Shared Memory Framework

The shared memory framework is an Obsidian-based knowledge management system that allows Cline to:

1. Access structured knowledge contexts
2. Use specialized system prompts for specific tasks
3. Save valuable conversations for future reference

If a CLINE.local.md file exists, it contains specific path information and setup instructions for accessing this framework.

## Knowledge Structure

A typical shared memory framework includes:

- **Contexts/** - Reusable knowledge on specific topics
- **Conversations/** - Logs of important conversations
- **System_Prompts/** - Specialized prompts for specific tasks
- **Templates/** - Templates for creating new memory files

## Knowledge Reference Format

When you want to use existing knowledge:

1. Reference contexts using: `[[AI/Memory/Contexts/Category/Name]]`
2. Apply system prompts using: `[[AI/Memory/System_Prompts/Category/Name]]`
3. Reference conversations using: `[[AI/Memory/Conversations/Agent/YYYYMMDD-Topic]]`

## Knowledge Storage

After completing significant tasks, you can ask Cline to store valuable knowledge in the shared memory framework.

## Benefits

- **Knowledge Persistence**: Retain valuable information across sessions
- **Contextual Awareness**: Quickly bring Cline up to speed on complex topics
- **Standardized Approaches**: Apply consistent methodologies to similar tasks
- **Knowledge Sharing**: Share knowledge between different AI assistants
- **Continuous Improvement**: Iteratively improve system prompts and contexts
