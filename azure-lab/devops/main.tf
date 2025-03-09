# ----------------------------------------
# GitHub Repository
# ----------------------------------------
module "github_repo" {
  source = "../../modules/github/repo"

  repo_name          = "terraform-labs"
  description        = "Terraform repository for managing cloud infrastructure, security policies, and automation workflows."
  visibility         = "public"
  auto_init          = true
  has_issues         = true
  has_projects       = false
  has_wiki           = false
  allow_merge_commit = true
  allow_squash_merge = true
  allow_rebase_merge = true
}

# --------------------------------------------------
# Azure DevOps Projects
# --------------------------------------------------
module "devops_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = var.project
  description         = "DevOps Managed by Terraform"
  visibility          = "private"
  devops_pat          = var.devops_pat

  features = {
    repositories = "disabled"
    testplans    = "disabled"
    artifacts    = "enabled"
    pipelines    = "enabled"
    boards       = "disabled"
  }
}

# ----------------------------------------
# Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "devops" {
  name     = "DevOps"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# --------------------------------------------------
# Azure DevOps Service Endpoints (AzureRM)
# --------------------------------------------------
resource "azuredevops_serviceendpoint_azurerm" "devops" {
  project_id                             = module.devops_project.devops_project_id
  service_endpoint_name                  = "DevOps-SC"
  service_endpoint_authentication_scheme = "ServicePrincipal"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lab_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [module.devops_project]
}
# Get ClientID and ID for the Service Principal
# Currently Getting Service Principal Object ID from Azure Portal by going through the IAM Role Assignment wizard for a vault
# az ad sp list --query "[].{DisplayName:displayName, ClientID:appId, ID:id}" --output table
# Create Secret for the Service Principal via Portal

# --------------------------------------------------
# Azure DevOps Service Endpoint (github)
# --------------------------------------------------
resource "azuredevops_serviceendpoint_github" "github" {
  project_id            = module.devops_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.devops_project]
}

# --------------------------------------------------
# Azure DevOps Build Pipeline (CI)
# --------------------------------------------------
resource "azuredevops_build_definition" "devops_ci" {
  project_id = module.devops_project.devops_project_id
  name       = "DevOps-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/devops-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.github]
}

# Add Agent Pool to the Build Pipeline via DevOps Portal
# Approve Pipeline to use the Agent Pool vis DevOps Portal
