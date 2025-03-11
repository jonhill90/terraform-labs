terraform {
  backend "azurerm" {}
}

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

module "networking_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Networking"
  description         = "Networking Managed by Terraform"
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

resource "azuredevops_serviceendpoint_azurerm" "networking" {
  project_id                             = module.networking_project.devops_project_id
  service_endpoint_name                  = "Networking-SC"
  service_endpoint_authentication_scheme = "ServicePrincipal"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lab_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [module.networking_project]
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

resource "azuredevops_serviceendpoint_github" "networking" {
  project_id            = module.networking_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.networking_project]
}

# --------------------------------------------------
# Secure Vault
# --------------------------------------------------
data "azurerm_key_vault" "devops" {
  name                = var.devops_vault_name
  resource_group_name = "Security"
  provider            = azurerm.lab
}

data "azurerm_key_vault" "networking" {
  name                = var.networking_vault_name
  resource_group_name = "Security"
  provider            = azurerm.lab
}

# --------------------------------------------------
# Create Empty Secrets
# --------------------------------------------------
module "devops_secrets" {
  source       = "../../modules/azurerm/security/secret"
  key_vault_id = data.azurerm_key_vault.devops.id
  secrets = {
    "devopspat"                = ""
    "devopsorgname"            = ""
    "backendContainer"         = ""
    "backendResourceGroup"     = ""
    "backendStorageAccount"    = ""
    "clientid"                 = ""
    "clientsecret"             = ""
    "labsubscriptionid"        = ""
    "managementsubscriptionid" = ""
    "tenantid"                 = ""
    "devopsvaultname"          = ""
    "networkingvaultname"      = ""
    "githubtoken"              = ""
  }

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [data.azurerm_key_vault.devops]
}

# --------------------------------------------------
# Azure DevOps Variable Groups
# --------------------------------------------------
module "devops_variable_group" {
  source                     = "../../modules/azure-devops/variable-group"
  project_id                 = module.devops_project.devops_project_id
  variable_group_name        = "DevOps"
  variable_group_description = "DevOps Variable Group"
  key_vault_name             = var.devops_vault_name
  service_endpoint_id        = azuredevops_serviceendpoint_azurerm.devops.id
  secrets = [
    "devopspat",
    "devopsorgname",
    "backendContainer",
    "backendResourceGroup",
    "backendStorageAccount",
    "clientid",
    "clientsecret",
    "labsubscriptionid",
    "managementsubscriptionid",
    "tenantid",
    "devopsvaultname",
    "networkingvaultname",
    "githubtoken"
  ]

  depends_on = [module.devops_secrets]
}

module "networking_variable_group" {
  source                     = "../../modules/azure-devops/variable-group"
  project_id                 = module.networking_project.devops_project_id
  variable_group_name        = "Networking"
  variable_group_description = "Networking Variable Group"
  key_vault_name             = var.networking_vault_name
  service_endpoint_id        = azuredevops_serviceendpoint_azurerm.networking.id
  secrets = [
    "backendContainer",
    "backendResourceGroup",
    "backendStorageAccount",
    "labsubscriptionid",
    "managementsubscriptionid",
    "tenantid",
    "vaultname",
    "twingatenetwork",
    "twingateapikey"
  ]

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

resource "azuredevops_build_definition" "networking_ci" {
  project_id = module.networking_project.devops_project_id
  name       = "Networking-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/networking-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.networking.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.networking]
}

# Add Agent Pool to the Build Pipeline via DevOps Portal
# Approve Pipeline to use the Agent Pool vis DevOps Portal

# --------------------------------------------------
# Azure DevOps Release Pipeline (CD)
# --------------------------------------------------
resource "azuredevops_build_definition" "devops_cd" {
  project_id = module.devops_project.devops_project_id
  name       = "DevOps-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/devops-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.github, azuredevops_build_definition.devops_ci]
}

resource "azuredevops_build_definition" "networking_cd" {
  project_id = module.networking_project.devops_project_id
  name       = "Networking-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/networking-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.networking.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.networking, azuredevops_build_definition.networking_ci]
}