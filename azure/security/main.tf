/*terraform {
  backend "azurerm" {}
}
*/

# --------------------------------------------------
#region Management Group (mg)
# --------------------------------------------------
data "azurerm_management_group" "mg" {
  name     = "ImpressiveIT"
  provider = azurerm.management
}

# --------------------------------------------------
#region Azure DevOps Projects (devops)
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

data "azuredevops_project" "devops" {
  name = "DevOps"
}

data "azuredevops_project" "networking" {
  name = "Networking"
}

data "azuredevops_project" "compute" {
  name = "Compute"
}

data "azuredevops_project" "database" {
  name = "Database"
}

data "azuredevops_project" "storage" {
  name = "Storage"
}

data "azuredevops_project" "application" {
  name = "Applications"
}

# --------------------------------------------------
#region Azure DevOps Service Endpoints (devops)
# --------------------------------------------------
/*
resource "azuredevops_serviceendpoint_azurerm" "security" {
  project_id                             = module.security_project.devops_project_id
  service_endpoint_name                  = "Security-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lzp1_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [module.security_project]
}

data "azuread_service_principal" "security_sp" {
  client_id = azuredevops_serviceendpoint_azurerm.security.service_principal_id
  provider  = azuread.impressiveit
  depends_on = [ azuredevops_serviceendpoint_azurerm.security ]
}

resource "azuredevops_serviceendpoint_azurerm" "devops" {
  project_id                             = data.azuredevops_project.devops.id
  service_endpoint_name                  = "DevOps-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lzp1_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [data.azuredevops_project.devops]
}

data "azuread_service_principal" "devops_sp" {
  client_id = azuredevops_serviceendpoint_azurerm.devops.service_principal_id
  provider  = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.devops]
}

resource "azuredevops_serviceendpoint_azurerm" "networking" {
  project_id                             = data.azuredevops_project.networking.id
  service_endpoint_name                  = "Networking-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lzp1_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [data.azuredevops_project.networking]
}

data "azuread_service_principal" "networking_sp" {
  client_id = azuredevops_serviceendpoint_azurerm.networking.service_principal_id
  provider  = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.networking]
}

resource "azuredevops_serviceendpoint_azurerm" "compute" {
  project_id                             = data.azuredevops_project.compute.id
  service_endpoint_name                  = "Compute-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lzp1_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [data.azuredevops_project.compute]
}

data "azuread_service_principal" "compute_sp" {
  client_id = azuredevops_serviceendpoint_azurerm.compute.service_principal_id
  provider  = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.compute]
}

resource "azuredevops_serviceendpoint_azurerm" "database" {
  project_id                             = data.azuredevops_project.database.id
  service_endpoint_name                  = "Database-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lzp1_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [data.azuredevops_project.database]
}

data "azuread_service_principal" "database_sp" {
  client_id = azuredevops_serviceendpoint_azurerm.database.service_principal_id
  provider  = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.database]
}

resource "azuredevops_serviceendpoint_azurerm" "storage" {
  project_id                             = data.azuredevops_project.storage.id
  service_endpoint_name                  = "Storage-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lzp1_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [data.azuredevops_project.storage]
}

data "azuread_service_principal" "storage_sp" {
  client_id = azuredevops_serviceendpoint_azurerm.storage.service_principal_id
  provider  = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.storage]
}

resource "azuredevops_serviceendpoint_azurerm" "application" {
  project_id                             = data.azuredevops_project.application.id
  service_endpoint_name                  = "Application-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.lzp1_subscription_id
  azurerm_subscription_name              = "Lab"

  depends_on = [data.azuredevops_project.application]
}

data "azuread_service_principal" "application_sp" {
  client_id = azuredevops_serviceendpoint_azurerm.application.service_principal_id
  provider  = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.application]
}
*/

# --------------------------------------------------
#region Service Principal Role Assignments (rc)
# --------------------------------------------------
module "security_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_management_group.mg.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.security_sp.object_id

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [data.azuread_service_principal.security_sp]
}

module "devops_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_management_group.mg.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.devops_sp.object_id

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [data.azuread_service_principal.devops_sp]
}

module "networking_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_management_group.mg.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.networking_sp.object_id

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [data.azuread_service_principal.networking_sp]
}

module "compute_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_management_group.mg.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.compute_sp.object_id

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [data.azuread_service_principal.compute_sp]
}

module "database_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_management_group.mg.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.database_sp.object_id

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [data.azuread_service_principal.database_sp]
}

module "storage_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_management_group.mg.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.storage_sp.object_id

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [data.azuread_service_principal.storage_sp]
}

module "application_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_management_group.mg.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.application_sp.object_id

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [data.azuread_service_principal.application_sp]
}

# --------------------------------------------------
#region Azure DevOps Service Endpoint (github)
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
#region Azure DevOps Build Pipeline (ci)
# --------------------------------------------------
/*
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
*/
# --------------------------------------------------
#region Azure DevOps Release Pipeline (cd)
# --------------------------------------------------
/*
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
*/
# ----------------------------------------
#region Resource Groups (rg)
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

resource "azurerm_resource_group" "security_mgmt" {
  name     = "security"
  location = "eastus"
  provider = azurerm.management

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

data "azurerm_resource_group" "devops" {
  name     = "DevOps"
  provider = azurerm.lab
}

data "azurerm_resource_group" "networking" {
  name     = "Networking"
  provider = azurerm.lab
}

# ----------------------------------------
#region Storage Accounts (sa)
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
#region Storage Account Container (blob)
# ----------------------------------------
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
  provider              = azurerm.lab

  depends_on = [azurerm_storage_account.tfstate]
}

# --------------------------------------------------
#region Key Vaults (kv)
# --------------------------------------------------
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
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.security]
}

module "devops_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.devops_vault_name
  resource_group_name        = azurerm_resource_group.security.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lzp1
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
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.security]
}

module "compute_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.compute_vault_name
  resource_group_name        = azurerm_resource_group.security.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.security]
}

module "database_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.database_vault_name
  resource_group_name        = azurerm_resource_group.security.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.security]
}

module "storage_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.storage_vault_name
  resource_group_name        = azurerm_resource_group.security.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.security]
}

module "application_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.application_vault_name
  resource_group_name        = azurerm_resource_group.security.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.security]
}

# --------------------------------------------------
#regions Secure Vault Access (pol)
# --------------------------------------------------
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
    azurerm = azurerm.lzp1
  }

  depends_on = [module.security_vault]
}

module "security_devops_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.devops_vault.key_vault_id

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
    azurerm = azurerm.lzp1
  }

  depends_on = [module.devops_vault]
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
    azurerm = azurerm.lzp1
  }

  depends_on = [module.networking_vault]
}

module "compute_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.compute_vault.key_vault_id

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
    azurerm = azurerm.lzp1
  }

  depends_on = [module.compute_vault]
}

module "database_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.database_vault.key_vault_id

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
    azurerm = azurerm.lzp1
  }

  depends_on = [module.database_vault]
}

module "storage_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.storage_vault.key_vault_id

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
    azurerm = azurerm.lzp1
  }

  depends_on = [module.storage_vault]
}

module "application_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.application_vault.key_vault_id

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
    azurerm = azurerm.lzp1
  }

  depends_on = [module.application_vault]
}

# --------------------------------------------------
#region Secure Vault Access (pol)
# --------------------------------------------------
module "security_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.security_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = data.azuread_service_principal.security_sp.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [module.security_vault, data.azuread_service_principal.security_sp]
}

module "devops_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.devops_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = data.azuread_service_principal.devops_sp.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [module.security_vault]
}

module "networking_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.networking_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = data.azuread_service_principal.networking_sp.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [module.networking_vault]
}

module "compute_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.compute_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = data.azuread_service_principal.compute_sp.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [module.compute_vault]
}

module "database_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.database_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = data.azuread_service_principal.database_sp.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [module.database_vault]
}

module "storage_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.storage_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = data.azuread_service_principal.storage_sp.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [module.storage_vault]
}

module "application_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.application_vault.key_vault_id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = data.azuread_service_principal.application_sp.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [module.application_vault]
}
