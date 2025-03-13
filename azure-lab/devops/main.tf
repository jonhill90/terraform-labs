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

module "compute_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Compute"
  description         = "Compute Managed by Terraform"
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

module "database_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Database"
  description         = "Database Managed by Terraform"
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

module "storage_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Storage"
  description         = "Storage Managed by Terraform"
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

module "application_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Applications"
  description         = "Applications Managed by Terraform"
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

resource "azuredevops_serviceendpoint_azurerm" "compute" {
  project_id                             = module.compute_project.devops_project_id
  service_endpoint_name                  = "Compute-SC"
  service_endpoint_authentication_scheme = "ServicePrincipal"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lab_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [module.compute_project]
}

resource "azuredevops_serviceendpoint_azurerm" "database" {
  project_id                             = module.database_project.devops_project_id
  service_endpoint_name                  = "Database-SC"
  service_endpoint_authentication_scheme = "ServicePrincipal"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lab_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [module.database_project]
}

resource "azuredevops_serviceendpoint_azurerm" "storage" {
  project_id                             = module.storage_project.devops_project_id
  service_endpoint_name                  = "Storage-SC"
  service_endpoint_authentication_scheme = "ServicePrincipal"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lab_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [module.storage_project]
}

resource "azuredevops_serviceendpoint_azurerm" "application" {
  project_id                             = module.application_project.devops_project_id
  service_endpoint_name                  = "Application-SC"
  service_endpoint_authentication_scheme = "ServicePrincipal"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lab_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [module.application_project]
}
# Get ClientID and ID for the Service Principal
# Currently Getting Service Principal Object ID from Azure Portal by going through the IAM Role Assignment wizard for a vault needed for security to grant the service principal access to the vault.
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

resource "azuredevops_serviceendpoint_github" "compute" {
  project_id            = module.compute_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.compute_project]
}

resource "azuredevops_serviceendpoint_github" "database" {
  project_id            = module.database_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.database_project]
}

resource "azuredevops_serviceendpoint_github" "storage" {
  project_id            = module.storage_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.storage_project]
}


resource "azuredevops_serviceendpoint_github" "application" {
  project_id            = module.application_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.application_project]
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

data "azurerm_key_vault" "compute" {
  name                = var.compute_vault_name
  resource_group_name = "Security"
  provider            = azurerm.lab
}

data "azurerm_key_vault" "database" {
  name                = var.database_vault_name
  resource_group_name = "Security"
  provider            = azurerm.lab
}

data "azurerm_key_vault" "storage" {
  name                = var.storage_vault_name
  resource_group_name = "Security"
  provider            = azurerm.lab
}

data "azurerm_key_vault" "application" {
  name                = var.application_vault_name
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
    "computevaultname"         = ""
    "databasevaultname"        = ""
    "storagevaultname"         = ""
    "applicationvaultname"     = ""
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
    "computevaultname",
    "databasevaultname",
    "storagevaultname",
    "applicationvaultname",
    "githubtoken"
  ]

  depends_on = [data.azurerm_key_vault.devops]
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
    "twingateapikey",
    "acr"
  ]
  depends_on = [data.azurerm_key_vault.networking]
}

module "compute_variable_group" {
  source                     = "../../modules/azure-devops/variable-group"
  project_id                 = module.compute_project.devops_project_id
  variable_group_name        = "Compute"
  variable_group_description = "Compute Variable Group"
  key_vault_name             = var.compute_vault_name
  service_endpoint_id        = azuredevops_serviceendpoint_azurerm.compute.id
  secrets = [
    "backendContainer",
    "backendResourceGroup",
    "backendStorageAccount",
    "labsubscriptionid",
    "managementsubscriptionid",
    "tenantid",
    "vaultname",
    "acr"
  ]

  depends_on = [data.azurerm_key_vault.compute]
}

module "database_variable_group" {
  source                     = "../../modules/azure-devops/variable-group"
  project_id                 = module.database_project.devops_project_id
  variable_group_name        = "Database"
  variable_group_description = "Database Variable Group"
  key_vault_name             = var.database_vault_name
  service_endpoint_id        = azuredevops_serviceendpoint_azurerm.database.id
  secrets = [
    "backendContainer",
    "backendResourceGroup",
    "backendStorageAccount",
    "labsubscriptionid",
    "managementsubscriptionid",
    "tenantid",
    "vaultname",
  ]

  depends_on = [data.azurerm_key_vault.database]
}

module "storage_variable_group" {
  source                     = "../../modules/azure-devops/variable-group"
  project_id                 = module.storage_project.devops_project_id
  variable_group_name        = "Storage"
  variable_group_description = "Storage Variable Group"
  key_vault_name             = var.storage_vault_name
  service_endpoint_id        = azuredevops_serviceendpoint_azurerm.storage.id
  secrets = [
    "backendContainer",
    "backendResourceGroup",
    "backendStorageAccount",
    "labsubscriptionid",
    "managementsubscriptionid",
    "tenantid",
    "vaultname",
  ]

  depends_on = [data.azurerm_key_vault.storage]
}

module "application_variable_group" {
  source                     = "../../modules/azure-devops/variable-group"
  project_id                 = module.application_project.devops_project_id
  variable_group_name        = "Application"
  variable_group_description = "Application Variable Group"
  key_vault_name             = var.application_vault_name
  service_endpoint_id        = azuredevops_serviceendpoint_azurerm.application.id
  secrets = [
    "backendContainer",
    "backendResourceGroup",
    "backendStorageAccount",
    "labsubscriptionid",
    "managementsubscriptionid",
    "tenantid",
    "vaultname",
  ]

  depends_on = [data.azurerm_key_vault.application]
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

resource "azuredevops_build_definition" "compute_ci" {
  project_id = module.compute_project.devops_project_id
  name       = "Compute-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/compute-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.compute.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.compute]
}

resource "azuredevops_build_definition" "database_ci" {
  project_id = module.database_project.devops_project_id
  name       = "Database-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/database-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.database.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.database]
}

resource "azuredevops_build_definition" "storage_ci" {
  project_id = module.storage_project.devops_project_id
  name       = "Storage-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/storage-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.storage.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.storage]
}

resource "azuredevops_build_definition" "appsingle_ci" {
  project_id = module.application_project.devops_project_id
  name       = "AppSingle-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/app-single-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.application.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.application]
}

resource "azuredevops_build_definition" "appmulti_ci" {
  project_id = module.application_project.devops_project_id
  name       = "AppMulti-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/app-multi-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.application.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.application]
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

resource "azuredevops_build_definition" "compute_cd" {
  project_id = module.compute_project.devops_project_id
  name       = "Compute-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/compute-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.compute.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.compute, azuredevops_build_definition.compute_ci]
}

resource "azuredevops_build_definition" "database_cd" {
  project_id = module.database_project.devops_project_id
  name       = "Database-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/database-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.database.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.database, azuredevops_build_definition.database_ci]
}

resource "azuredevops_build_definition" "appsingle_cd" {
  project_id = module.application_project.devops_project_id
  name       = "AppSingle-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/app-single-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.application.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.application, azuredevops_build_definition.appsingle_ci]
}

resource "azuredevops_build_definition" "appmulti_cd" {
  project_id = module.application_project.devops_project_id
  name       = "AppMulti-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/app-multi-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.application.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.application, azuredevops_build_definition.appmulti_ci]
}