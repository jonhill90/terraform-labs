# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Lint/Test Commands
- Terraform init: `terraform init`
- Terraform validate: `terraform validate`
- Terraform plan: `terraform plan -var-file=env/[environment].tfvars`
- Terraform apply: `terraform apply -var-file=env/[environment].tfvars`

## Code Style Guidelines
- **Terraform**: Use snake_case for resources/variables, 2-space indentation, descriptive resource names
- **Naming Conventions**: Use prefix patterns (rg- for resource groups, vnet- for networks, snet- for subnets)
- **Structure**: Maintain modular approach with reusable components and environment separation
- **Documentation**: Include descriptive comments for complex operations
- **Tagging**: Consistent use of tags for environment, owner, and project
- **Variables**: Clear type definitions, with sensitive variables appropriately marked
- **Organization**: Logical separation of resources by type and purpose within files
- **Modules**: Organized module structure with clear dependencies using depends_on

## Shared Knowledge Framework
This workspace uses the shared memory framework for AI agents. Reference the framework for detailed knowledge about Azure networking architecture and operations.

### Knowledge Reference Format
Reference these contexts in the shared memory system:
- Network Architecture: `[[AI/Memory/Contexts/Shared/AzureNetworking]]`
- Common Operations: `[[AI/Memory/Contexts/Shared/AzureNetworkCommonOperations]]`
- Modification Guide: `[[AI/Memory/System_Prompts/Shared/AzureNetworkingModifications]]`

### Network Architecture Overview
This workspace implements a hub-and-spoke Azure networking architecture:

- Hub VNet (10.10.0.0/16) with ACI delegation subnet
- Spoke VNets for Management, Identity, and Landing Zones
- Multi-subscription model with provider aliases
- VNet peering between hub and all spokes
- Private DNS zones for Azure services and internal domains