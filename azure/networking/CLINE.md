# CLINE.md

This file provides guidance for using Cline with a shared memory framework when working with the Azure networking workspace.

## What is Cline?

Cline is a command-line interface for Claude that can be integrated with a shared memory framework stored in Obsidian. This integration enhances Cline's capabilities by providing access to persistent knowledge about Azure networking.

## Shared Memory Framework

The shared memory framework is an Obsidian-based knowledge management system that allows Cline to:

1. Access structured knowledge contexts about Azure networking
2. Use specialized system prompts for networking tasks
3. Save valuable conversations about networking for future reference

If a CLINE.local.md file exists, it contains specific path information and setup instructions for accessing this framework.

## Knowledge Structure for Networking

The shared memory framework includes these networking-related components:

- **Contexts/Shared/AzureNetworking** - Reusable knowledge about Azure networking architecture
- **Contexts/Shared/AzureNetworkCommonOperations** - Common operations for Azure networking
- **System_Prompts/Shared/AzureNetworkingModifications** - Specialized prompts for modifying Azure networking

## Azure Networking Architecture

This workspace implements a hub-and-spoke Azure networking architecture:

- Hub VNet (10.10.0.0/16) in Connectivity subscription
- Spoke VNets for Management (10.20.0.0/16), Identity (10.30.0.0/16), and Landing Zones (10.40.0.0/16, 10.50.0.0/16)
- VNet peering between hub and all spokes, plus direct peering between LZP1 and Management
- Private DNS zones for Azure services (blob, adf, synapse) and internal domain (impressiveit.local)
- Standardized subnet naming with consistent CIDR allocation

## Build/Lint/Test Commands

- Terraform init: `terraform init`
- Terraform validate: `terraform validate`
- Terraform plan: `terraform plan -var-file=env/[environment].tfvars`
- Terraform apply: `terraform apply -var-file=env/[environment].tfvars`

## Code Style Guidelines

- Use snake_case for resources/variables with 2-space indentation
- Follow naming conventions: rg- for resource groups, vnet- for networks, snet- for subnets
- Maintain consistent tagging for environment, owner, and project
- Mark sensitive variables appropriately
- Use logical separation of resources by type and purpose
- Organize modules with clear dependencies using depends_on

## Benefits of Shared Memory for Networking

- **Knowledge Persistence**: Retain valuable information about networking across sessions
- **Contextual Awareness**: Quickly bring Cline up to speed on complex networking topics
- **Standardized Approaches**: Apply consistent methodologies to similar networking tasks
- **Knowledge Sharing**: Share networking knowledge between different AI assistants
- **Continuous Improvement**: Iteratively improve system prompts and contexts for networking
