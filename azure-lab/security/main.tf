
terraform {
  backend "azurerm" {}
}

# --------------------------------------------------
# Azure DevOps Project (Security)
# --------------------------------------------------
module "security_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = var.project
  description         = "Security Managed by Terraform"
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

# --------------------------------------------------
# Azure DevOps Service Endpoint (AzureRM)
# --------------------------------------------------
resource "azuredevops_serviceendpoint_azurerm" "security" {
  project_id                             = module.security_project.devops_project_id
  service_endpoint_name                  = "Security-SC"
  service_endpoint_authentication_scheme = "ManagedServiceIdentity"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lab_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [module.security_project]
}

# --------------------------------------------------
# Azure DevOps Service Endpoint (github)
# --------------------------------------------------
resource "azuredevops_serviceendpoint_github" "github" {
  project_id            = module.security_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.security_project]
}


# --------------------------------------------------
# Azure DevOps Build Pipeline (CI)
# --------------------------------------------------
resource "azuredevops_build_definition" "security_ci" {
  project_id = module.security_project.devops_project_id
  name       = "Security-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/security-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.github]
}

# --------------------------------------------------
# Azure DevOps Release Pipeline (CD)
# --------------------------------------------------
resource "azuredevops_build_definition" "security_cd" {
  project_id = module.security_project.devops_project_id
  name       = "Security-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/security-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.github]
}

# ----------------------------------------
# Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "security" {
  name     = "security"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
# Storage Accounts
# ----------------------------------------
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account
  resource_group_name      = azurerm_resource_group.security.name
  location                 = azurerm_resource_group.security.location
  provider                 = azurerm.lab
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.security]
}

# ----------------------------------------
# Storage Account Container
# ----------------------------------------
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
  provider              = azurerm.lab

  depends_on = [azurerm_storage_account.tfstate]
}

# --------------------------------------------------
# Secure Vault
# --------------------------------------------------
module "vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.vault_name
  resource_group_name        = azurerm_resource_group.security.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [azurerm_resource_group.security]
}

module "security_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.security_vault_name
  resource_group_name        = azurerm_resource_group.security.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [azurerm_resource_group.security]
}

module "networking_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.networking_vault_name
  resource_group_name        = azurerm_resource_group.security.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [azurerm_resource_group.security]
}

# --------------------------------------------------
# Secure Vault Access (Azure Admin Account)
# --------------------------------------------------
module "vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = var.admin_object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [module.vault]
}

module "security_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.security_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = var.admin_object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [module.security_vault]
}


module "networking_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.networking_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = var.admin_object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [module.networking_vault]
}

# --------------------------------------------------
# Secure Vault Access (Service Principal)
# --------------------------------------------------
module "sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = var.sp_object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [module.vault]
}

module "security_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.security_vault.key_vault_id

  access_policies = [
    {
      tenant_id = var.tenant_id
      object_id = azuredevops_serviceendpoint_azurerm.security.id
      #object_id               = var.sp_object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [module.security_vault, module.vault_access]
}

module "networking_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.networking_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = var.sp_object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [module.networking_vault]
}

# --------------------------------------------------
# Create Empty Secrets
# --------------------------------------------------
module "security_secrets" {
  source       = "../../modules/azurerm/security/secret" # Adjust to your module path
  key_vault_id = module.security_vault.key_vault_id
  secrets = {
    "devopspat"                = ""
    "devopsorgname"            = ""
    "networkingvaultname"      = ""
    "adminobjectid"            = ""
    "backendContainer"         = ""
    "backendResourceGroup"     = ""
    "backendStorageAccount"    = ""
    "clientid"                 = ""
    "clientsecret"             = ""
    "labsubscriptionid"        = ""
    "managementsubscriptionid" = ""
    "spobjectid"               = ""
    "storageaccount"           = ""
    "tenantid"                 = ""
    "vaultname"                = ""
    "githubtoken"              = ""
  }

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [module.sp_vault_access]
}

module "networking_secrets" {
  source       = "../../modules/azurerm/security/secret" # Adjust to your module path
  key_vault_id = module.networking_vault.key_vault_id
  secrets = {
    "devopspat"                = ""
    "devopsorgname"            = ""
    "networkingvaultname"      = ""
    "adminobjectid"            = ""
    "backendContainer"         = ""
    "backendResourceGroup"     = ""
    "backendStorageAccount"    = ""
    "clientid"                 = ""
    "clientsecret"             = ""
    "labsubscriptionid"        = ""
    "managementsubscriptionid" = ""
    "spobjectid"               = ""
    "storageaccount"           = ""
    "tenantid"                 = ""
    "vaultname"                = ""
    "githubtoken"              = ""
  }

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [module.networking_vault, module.sp_vault_access]
}

# --------------------------------------------------
# Azure DevOps Variable Group (Security)
# --------------------------------------------------
module "security_variable_group" {
  source                      = "../../modules/azure-devops/variable-group"
  project_id                  = module.security_project.devops_project_id
  variable_group_name         = "Security"
  variable_group_description  = "Security Variable Group"
  key_vault_name              = var.security_vault_name
  service_endpoint_id         = azuredevops_serviceendpoint_azurerm.security.id
  secrets = [
    "devopspat",
    "devopsorgname",
    "networkingvaultname",
    "adminobjectid",
    "backendContainer",
    "backendResourceGroup",
    "backendStorageAccount",
    "clientid",
    "clientsecret",
    "labsubscriptionid",
    "managementsubscriptionid",
    "spobjectid",
    "storageaccount",
    "tenantid",
    "vaultname",
    "githubtoken"
  ]

  depends_on = [module.security_secrets]
}