terraform {
  backend "azurerm" {}
}

# --------------------------------------------------
#region Management Group (mg)
# --------------------------------------------------
data "azurerm_management_group" "mg" {
  name     = "ImpressiveIT"
  provider = azurerm.management
}

# --------------------------------------------------
#region Subscriptions (sub)
# --------------------------------------------------
data "azurerm_subscription" "management" {
  subscription_id = var.management_subscription_id
  provider        = azurerm.management
}

data "azurerm_subscription" "connectivity" {
  subscription_id = var.connectivity_subscription_id
  provider        = azurerm.connectivity
}

data "azurerm_subscription" "identity" {
  subscription_id = var.identity_subscription_id
  provider        = azurerm.identity
}

data "azurerm_subscription" "lzp1" {
  subscription_id = var.lzp1_subscription_id
  provider        = azurerm.lzp1
}

data "azurerm_subscription" "lza2" {
  subscription_id = var.lza2_subscription_id
  provider        = azurerm.lza2
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

data "azuredevops_project" "datahub" {
  name = "DataHub"
}

# --------------------------------------------------
#region Azure DevOps Service Endpoints (devops)
# --------------------------------------------------
resource "azuredevops_serviceendpoint_azurerm" "security" {
  project_id                             = module.security_project.devops_project_id
  service_endpoint_name                  = "Security-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.management_subscription_id
  azurerm_subscription_name              = "Management"

  depends_on = [module.security_project]
}

data "azuread_service_principal" "security_sp" {
  client_id  = azuredevops_serviceendpoint_azurerm.security.service_principal_id
  provider   = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.security]
}

resource "azuredevops_serviceendpoint_azurerm" "devops" {
  project_id                             = data.azuredevops_project.devops.id
  service_endpoint_name                  = "DevOps-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.management_subscription_id
  azurerm_subscription_name              = "Management"

  depends_on = [data.azuredevops_project.devops]
}

data "azuread_service_principal" "devops_sp" {
  client_id  = azuredevops_serviceendpoint_azurerm.devops.service_principal_id
  provider   = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.devops]
}

resource "azuredevops_serviceendpoint_azurerm" "networking" {
  project_id                             = data.azuredevops_project.networking.id
  service_endpoint_name                  = "Networking-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.management_subscription_id
  azurerm_subscription_name              = "Management"

  depends_on = [data.azuredevops_project.networking]
}

data "azuread_service_principal" "networking_sp" {
  client_id  = azuredevops_serviceendpoint_azurerm.networking.service_principal_id
  provider   = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.networking]
}

resource "azuredevops_serviceendpoint_azurerm" "compute" {
  project_id                             = data.azuredevops_project.compute.id
  service_endpoint_name                  = "Compute-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.management_subscription_id
  azurerm_subscription_name              = "Management"

  depends_on = [data.azuredevops_project.compute]
}

data "azuread_service_principal" "compute_sp" {
  client_id  = azuredevops_serviceendpoint_azurerm.compute.service_principal_id
  provider   = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.compute]
}

resource "azuredevops_serviceendpoint_azurerm" "database" {
  project_id                             = data.azuredevops_project.database.id
  service_endpoint_name                  = "Database-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.management_subscription_id
  azurerm_subscription_name              = "Management"

  depends_on = [data.azuredevops_project.database]
}

data "azuread_service_principal" "database_sp" {
  client_id  = azuredevops_serviceendpoint_azurerm.database.service_principal_id
  provider   = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.database]
}

resource "azuredevops_serviceendpoint_azurerm" "storage" {
  project_id                             = data.azuredevops_project.storage.id
  service_endpoint_name                  = "Storage-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.management_subscription_id
  azurerm_subscription_name              = "Management"

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
  azurerm_subscription_id                = var.management_subscription_id
  azurerm_subscription_name              = "Management"

  depends_on = [data.azuredevops_project.application]
}

data "azuread_service_principal" "application_sp" {
  client_id = azuredevops_serviceendpoint_azurerm.application.service_principal_id
  provider  = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.application]
}

resource "azuredevops_serviceendpoint_azurerm" "datahub" {
  project_id                             = data.azuredevops_project.datahub.id
  service_endpoint_name                  = "DataHub-SC"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = var.tenant_id
  azurerm_subscription_id                = var.management_subscription_id
  azurerm_subscription_name              = "Management"

  depends_on = [data.azuredevops_project.datahub]
}

data "azuread_service_principal" "datahub_sp" {
  client_id = azuredevops_serviceendpoint_azurerm.datahub.service_principal_id
  provider  = azuread.impressiveit
  depends_on = [azuredevops_serviceendpoint_azurerm.datahub]
}

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
    azurerm = azurerm.lzp1
  }

  depends_on = [data.azuread_service_principal.compute_sp]
}

module "database_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_subscription.lzp1.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.database_sp.object_id

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [data.azuread_service_principal.database_sp]
}

module "storage_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_management_group.mg.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.storage_sp.object_id
  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [data.azuread_service_principal.storage_sp]
}

module "application_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_subscription.lza2.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.application_sp.object_id

  providers = {
    azurerm = azurerm.lza2
  }

  depends_on = [data.azuread_service_principal.application_sp]
}

module "datahub_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = data.azurerm_subscription.lzp1.id
  role_name    = "Contributor"
  principal_id = data.azuread_service_principal.datahub_sp.object_id

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [data.azuread_service_principal.datahub_sp]
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
resource "azuredevops_build_definition" "security_ci" {
  project_id = module.security_project.devops_project_id
  name       = "Security-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/security-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.github]
}

# --------------------------------------------------
#region Azure DevOps Release Pipeline (cd)
# --------------------------------------------------
resource "azuredevops_build_definition" "security_cd" {
  project_id = module.security_project.devops_project_id
  name       = "Security-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/security-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.github]
}

# ----------------------------------------
#region Resource Groups (rg)
# ----------------------------------------
resource "azurerm_resource_group" "rg_security_management" {
  name     = "rg-security-management"
  location = "eastus"
  provider = azurerm.management

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

data "azurerm_resource_group" "rg_devops_management" {
  name     = "rg-devops-management"
  provider = azurerm.management
}

data "azurerm_resource_group" "rg_networking_connectivity" {
  name     = "rg-networking-connectivity"
  provider = azurerm.connectivity
}

data "azurerm_resource_group" "rg_networking_management" {
  name     = "rg-networking-management"
  provider = azurerm.management
}

data "azurerm_resource_group" "rg_compute_lzp1" {
  name     = "rg-compute-lzp1"
  provider = azurerm.lzp1
}

data "azurerm_resource_group" "rg_database_lzp1" {
  name     = "rg-database-lzp1"
  provider = azurerm.lzp1
}

data "azurerm_resource_group" "rg_storage_lzp1" {
  name     = "rg-storage-lzp1"
  provider = azurerm.lzp1
}

data "azurerm_resource_group" "rg_appsingle_lab" {
  name     = "rg-appsingle-lab"
  provider = azurerm.lza2
}

data "azurerm_resource_group" "rg_appmulti_shared" {
  name     = "rg-appmulti-shared"
  provider = azurerm.lza2
}

data "azurerm_resource_group" "rg_datahub_lzp1" {
  name     = "rg-datahub-lzp1"
  provider = azurerm.lzp1
}

# ----------------------------------------
#region Networking
# ----------------------------------------
data "azurerm_virtual_network" "vnet_spoke_management" {
  name                = "vnet-spoke-management"
  resource_group_name = data.azurerm_resource_group.rg_networking_management.name
  provider            = azurerm.management

  depends_on = [data.azurerm_resource_group.rg_networking_management]
}

data "azurerm_subnet" "snet_storage_private_management" {
  name                 = "snet-storage-private"
  virtual_network_name = data.azurerm_virtual_network.vnet_spoke_management.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_management.name
  provider             = azurerm.management

  depends_on = [data.azurerm_virtual_network.vnet_spoke_management]
}

data "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "rg-networking-connectivity"
  provider            = azurerm.connectivity

  depends_on = [data.azurerm_resource_group.rg_networking_connectivity]
}

# ----------------------------------------
#region Storage Accounts (sa)
# ----------------------------------------
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account
  resource_group_name      = azurerm_resource_group.rg_security_management.name
  location                 = azurerm_resource_group.rg_security_management.location
  provider                 = azurerm.management
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    virtual_network_subnet_ids = [
      data.azurerm_subnet.snet_storage_private_management.id
    ]
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_security_management]
}

# ----------------------------------------
#region Storage Account Container (blob)
# ----------------------------------------
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
  provider              = azurerm.management

  depends_on = [azurerm_storage_account.tfstate]
}

# --------------------------------------------------
#region Key Vaults (kv)
# --------------------------------------------------
module "security_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.security_vault_name
  resource_group_name        = azurerm_resource_group.rg_security_management.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [azurerm_resource_group.rg_security_management]
}

data "azurerm_key_vault" "devops" {
  name                = var.devops_vault_name
  resource_group_name = data.azurerm_resource_group.rg_devops_management.name
  provider            = azurerm.management
}

data "azurerm_key_vault" "networking" {
  name                = var.networking_vault_name
  resource_group_name = data.azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity
}

data "azurerm_key_vault" "compute" {
  name                = var.compute_vault_name
  resource_group_name = data.azurerm_resource_group.rg_compute_lzp1.name
  provider            = azurerm.lzp1
}

data "azurerm_key_vault" "database" {
  name                = var.database_vault_name
  resource_group_name = data.azurerm_resource_group.rg_database_lzp1.name
  provider            = azurerm.lzp1
}

data "azurerm_key_vault" "storage" {
  name                = var.storage_vault_name
  resource_group_name = data.azurerm_resource_group.rg_storage_lzp1.name
  provider            = azurerm.lzp1
}

data "azurerm_key_vault" "appsingle" {
  name                = var.appsingle_vault_name
  resource_group_name = data.azurerm_resource_group.rg_appsingle_lab.name
  provider            = azurerm.lza2
}

data "azurerm_key_vault" "appmulti" {
  name                = var.appmulti_vault_name
  resource_group_name = data.azurerm_resource_group.rg_appmulti_shared.name
  provider            = azurerm.lza2
}

data "azurerm_key_vault" "datahub" {
  name                = var.datahub_vault_name
  resource_group_name = data.azurerm_resource_group.rg_datahub_lzp1.name
  provider            = azurerm.lzp1
}

# ----------------------------------------
#region Private Endpoints (pe)
# ----------------------------------------
resource "azurerm_private_endpoint" "tfstate_pe" {
  name                = "pe-tfstate"
  location            = azurerm_resource_group.rg_security_management.location
  resource_group_name = azurerm_resource_group.rg_security_management.name
  subnet_id           = data.azurerm_subnet.snet_storage_private_management.id
  provider            = azurerm.management

  private_service_connection {
    name                           = "psc-tfstate"
    private_connection_resource_id = azurerm_storage_account.tfstate.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
  }

  depends_on = [azurerm_storage_account.tfstate]
}

# --------------------------------------------------
#region Azure Entra Users (ad)
# --------------------------------------------------
data "azuread_users" "security_admins" {
  object_ids = [var.admin_object_id]
}

data "azuread_users" "devops_admins" {
  object_ids = [var.admin_object_id]
}

data "azuread_users" "networking_admins" {
  object_ids = [var.admin_object_id]
}

data "azuread_users" "compute_admins" {
  object_ids = [var.admin_object_id]
}

data "azuread_users" "database_admins" {
  object_ids = [var.admin_object_id]
}

data "azuread_users" "storage_admins" {
  object_ids = [var.admin_object_id]
}

data "azuread_users" "appsingle_admins" {
  object_ids = [var.admin_object_id]
}

data "azuread_users" "appmulti_admins" {
  object_ids = [var.admin_object_id]
}

data "azuread_users" "datahub_admins" {
  object_ids = [var.admin_object_id]
}

# --------------------------------------------------
#region Azure Entra Groups (ad)
# --------------------------------------------------
resource "azuread_group" "security_admins" {
  display_name     = "Security Admins"
  mail_enabled     = true
  mail_nickname    = "SecurityAdmins"
  security_enabled = true
  types            = ["Unified"]

  owners  = data.azuread_users.security_admins.object_ids
  members = data.azuread_users.security_admins.object_ids

  depends_on = [data.azuread_users.security_admins]
}

resource "azuread_group" "devops_admins" {
  display_name     = "DevOps Admins"
  mail_enabled     = true
  mail_nickname    = "DevOpsAdmins"
  security_enabled = true
  types            = ["Unified"]

  owners  = data.azuread_users.devops_admins.object_ids
  members = data.azuread_users.devops_admins.object_ids

  depends_on = [data.azuread_users.devops_admins]
}

resource "azuread_group" "networking_admins" {
  display_name     = "Networking Admins"
  mail_enabled     = true
  mail_nickname    = "NetworkingAdmins"
  security_enabled = true
  types            = ["Unified"]

  owners  = data.azuread_users.networking_admins.object_ids
  members = data.azuread_users.networking_admins.object_ids

  depends_on = [data.azuread_users.networking_admins]
}

resource "azuread_group" "compute_admins" {
  display_name     = "Compute Admins"
  mail_enabled     = true
  mail_nickname    = "ComputeAdmins"
  security_enabled = true
  types            = ["Unified"]

  owners  = data.azuread_users.compute_admins.object_ids
  members = data.azuread_users.compute_admins.object_ids

  depends_on = [data.azuread_users.compute_admins]
}

resource "azuread_group" "database_admins" {
  display_name     = "Database Admins"
  mail_enabled     = true
  mail_nickname    = "DatabaseAdmins"
  security_enabled = true
  types            = ["Unified"]

  owners  = data.azuread_users.database_admins.object_ids
  members = data.azuread_users.database_admins.object_ids

  depends_on = [data.azuread_users.database_admins]
}

resource "azuread_group" "storage_admins" {
  display_name     = "Storage Admins"
  mail_enabled     = true
  mail_nickname    = "StorageAdmins"
  security_enabled = true
  types            = ["Unified"]

  owners  = data.azuread_users.storage_admins.object_ids
  members = data.azuread_users.storage_admins.object_ids

  depends_on = [data.azuread_users.storage_admins]
}

resource "azuread_group" "appsingle_admins" {
  display_name     = "AppSingle Admins"
  mail_enabled     = true
  mail_nickname    = "AppSingleAdmins"
  security_enabled = true
  types            = ["Unified"]

  owners  = data.azuread_users.appsingle_admins.object_ids
  members = data.azuread_users.appsingle_admins.object_ids

  depends_on = [data.azuread_users.appsingle_admins]
}

resource "azuread_group" "appmulti_admins" {
  display_name     = "AppMulti Admins"
  mail_enabled     = true
  mail_nickname    = "AppMultiAdmins"
  security_enabled = true
  types            = ["Unified"]

  owners  = data.azuread_users.appmulti_admins.object_ids
  members = data.azuread_users.appmulti_admins.object_ids

  depends_on = [data.azuread_users.appmulti_admins]
}

resource "azuread_group" "datahub_admins" {
  display_name     = "DataHub Admins"
  mail_enabled     = true
  mail_nickname    = "DataHubAdmins"
  security_enabled = true
  types            = ["Unified"]

  owners  = data.azuread_users.datahub_admins.object_ids
  members = data.azuread_users.datahub_admins.object_ids

  depends_on = [data.azuread_users.datahub_admins]
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
      object_id               = resource.azuread_group.security_admins.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [module.security_vault, resource.azuread_group.security_admins]
}

module "devops_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.devops.id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = resource.azuread_group.devops_admins.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [data.azurerm_key_vault.devops, resource.azuread_group.devops_admins]
}

module "networking_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.networking.id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = resource.azuread_group.networking_admins.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.connectivity
  }

  depends_on = [data.azurerm_key_vault.networking, resource.azuread_group.networking_admins]
}

module "compute_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.compute.id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = resource.azuread_group.compute_admins.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [data.azurerm_key_vault.compute, resource.azuread_group.compute_admins]
}

module "database_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.database.id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = resource.azuread_group.database_admins.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [data.azurerm_key_vault.database, resource.azuread_group.database_admins]
}

module "storage_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.storage.id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = resource.azuread_group.storage_admins.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [data.azurerm_key_vault.storage, resource.azuread_group.storage_admins]
}
module "appsingle_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.appsingle.id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = resource.azuread_group.appsingle_admins.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lza2
  }

  depends_on = [data.azurerm_key_vault.appsingle, resource.azuread_group.appsingle_admins]
}

module "appmulti_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.appmulti.id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = resource.azuread_group.appmulti_admins.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lza2
  }

  depends_on = [data.azurerm_key_vault.appmulti, resource.azuread_group.appmulti_admins]
}

module "datahub_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.datahub.id

  access_policies = [
    {
      tenant_id               = var.tenant_id
      object_id               = resource.azuread_group.datahub_admins.object_id
      key_permissions         = ["Get", "List"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [data.azurerm_key_vault.datahub, resource.azuread_group.datahub_admins]
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
    azurerm = azurerm.management
  }

  depends_on = [module.security_vault, data.azuread_service_principal.security_sp]
}

module "devops_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.devops.id

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
    azurerm = azurerm.management
  }

  depends_on = [data.azurerm_key_vault.devops, data.azuread_service_principal.devops_sp]
}

module "networking_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.networking.id

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
    azurerm = azurerm.connectivity
  }

  depends_on = [data.azurerm_key_vault.networking, data.azuread_service_principal.networking_sp]
}

module "compute_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.compute.id

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

  depends_on = [data.azurerm_key_vault.compute, data.azuread_service_principal.compute_sp]
}

module "database_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.database.id

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

  depends_on = [data.azurerm_key_vault.database, data.azuread_service_principal.database_sp]
}

module "storage_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.storage.id

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

  depends_on = [data.azurerm_key_vault.storage, data.azuread_service_principal.storage_sp]
}

module "appsingle_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.appsingle.id

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
    azurerm = azurerm.lza2
  }

  depends_on = [data.azurerm_key_vault.appsingle, data.azuread_service_principal.application_sp]
}

module "appmulti_sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = data.azurerm_key_vault.appmulti.id

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
    azurerm = azurerm.lza2
  }

  depends_on = [data.azurerm_key_vault.appmulti, data.azuread_service_principal.application_sp]
}