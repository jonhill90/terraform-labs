# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Lint/Test Commands
- Terraform init: `terraform init`
- Terraform validate: `terraform validate`
- Terraform plan: `terraform plan -var-file=env/[environment].tfvars`
- Terraform apply: `terraform apply -var-file=env/[environment].tfvars`

## Code Style Guidelines
- **Terraform**: Use snake_case for resources/variables, 2-space indentation, descriptive resource names
- **Resource Organization**: Use #region comments to organize code by resource type
- **Azure Naming**: Follow Azure naming conventions (e.g., rg-datahub-lzp1, sa-datahub, pe-datahub-blob)
- **Variables**: Organize variables by category with #region comments, include descriptions
- **Modules**: Use relative paths with ../../modules pattern for module references
- **Dependencies**: Use explicit depends_on for resource dependencies
- **Environment Separation**: Store environment-specific variables in env/[environment].tfvars files
- **Tags**: Apply consistent tags (environment, owner, project) across resources

## Shared Knowledge Framework
This workspace uses the shared memory framework for AI agents. Reference the framework for detailed knowledge about the Azure DataHub implementation.

### Knowledge Reference Format
Reference these contexts in the shared memory system:
- DataHub Architecture: `[[AI/Memory/Contexts/Shared/AzureDataHub]]`
- Data Services Integration: `[[AI/Memory/Contexts/Shared/AzureDataServices]]`
- Data Platform Development: `[[AI/Memory/System_Prompts/Shared/AzureDataPlatform]]`

### DataHub Overview
This workspace implements a modern data platform with:
- Azure Data Lake Storage Gen2 with hierarchical namespace
- Azure Data Factory for data orchestration and movement
- Azure Synapse Analytics for data warehousing
- Private endpoints for secure connectivity
- Integration with the landing zone VNet through snet-data subnet