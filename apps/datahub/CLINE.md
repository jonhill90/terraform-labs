# CLINE.md

This file provides guidance for using Cline with a shared memory framework when working with the Azure DataHub workspace.

## What is Cline?

Cline is a command-line interface for Claude that can be integrated with a shared memory framework stored in Obsidian. This integration enhances Cline's capabilities by providing access to persistent knowledge about Azure data platforms.

## Shared Memory Framework

The shared memory framework is an Obsidian-based knowledge management system that allows Cline to:

1. Access structured knowledge contexts about Azure data platforms
2. Use specialized system prompts for data platform tasks
3. Save valuable conversations about data platforms for future reference

If a CLINE.local.md file exists, it contains specific path information and setup instructions for accessing this framework.

## Knowledge Structure for DataHub

The shared memory framework includes these data platform-related components:

- **Contexts/Shared/AzureDataHub** - Reusable knowledge about Azure DataHub architecture
- **Contexts/Shared/AzureDataServices** - Information about Azure data services integration
- **System_Prompts/Shared/AzureDataPlatform** - Specialized prompts for data platform development

## Azure DataHub Architecture

This workspace implements a modern data platform with:

- Azure Data Lake Storage Gen2 with hierarchical namespace
- Azure Data Factory for data orchestration and movement
- Azure Synapse Analytics for data warehousing
- Private endpoints for secure connectivity
- Integration with the landing zone VNet through snet-data subnet

## Build/Lint/Test Commands

- Terraform init: `terraform init`
- Terraform validate: `terraform validate`
- Terraform plan: `terraform plan -var-file=env/[environment].tfvars`
- Terraform apply: `terraform apply -var-file=env/[environment].tfvars`

## Code Style Guidelines

- Use snake_case for resources/variables with 2-space indentation
- Use #region comments to organize code by resource type
- Follow Azure naming conventions (e.g., rg-datahub-lzp1, sa-datahub, pe-datahub-blob)
- Organize variables by category with #region comments
- Use relative paths with ../../modules pattern for module references
- Use explicit depends_on for resource dependencies
- Store environment-specific variables in env/[environment].tfvars files
- Apply consistent tags (environment, owner, project) across resources

## Benefits of Shared Memory for DataHub

- **Knowledge Persistence**: Retain valuable information about data platforms across sessions
- **Contextual Awareness**: Quickly bring Cline up to speed on complex data platform topics
- **Standardized Approaches**: Apply consistent methodologies to similar data platform tasks
- **Knowledge Sharing**: Share data platform knowledge between different AI assistants
- **Continuous Improvement**: Iteratively improve system prompts and contexts for data platforms
