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