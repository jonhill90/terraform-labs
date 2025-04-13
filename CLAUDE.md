# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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