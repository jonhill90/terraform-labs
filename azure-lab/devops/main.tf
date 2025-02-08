# ----------------------------------------
# GitHub Repository (local)
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

# ----------------------------------------
# Resource Groups (local)
# ----------------------------------------
resource "azurerm_resource_group" "devops" {
  name     = "DevOps"
  location = "eastus"
  provider = azurerm.management

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# --------------------------------------------------
# Secure Vault (local)
# --------------------------------------------------
module "devops_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = substr("${var.environment}-${var.project}", 0, 24)
  resource_group_name        = azurerm_resource_group.devops.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.management
  }
}


# --------------------------------------------------
# Secure Vault Access (local / Azure Admin Account)
# --------------------------------------------------
module "vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.devops_vault.key_vault_id

  access_policies = [
    {
      tenant_id         = var.tenant_id
      object_id         = var.admin_object_id
      key_permissions   = ["Get", "List"]
      secret_permissions = ["Get", "List", "Set", "Delete"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.management
  }
}

# --------------------------------------------------
# AzureAD Service Principal - DevOps (local)
# --------------------------------------------------
module "devops_service_principal" {
  source                = "../../modules/azuread/service-principle"
  name                  = "devops"
  password_lifetime     = "8760h"
  key_vault_id          = module.devops_vault.key_vault_id
  store_secret_in_vault = true

  providers = {
    azuread = azuread.impressiveit
    azurerm = azurerm.management
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}
# --------------------------------------------------
# Service Principal Role Assignment - DevOps (local)
# --------------------------------------------------
module "devops_sp_role_assignment" {
  source       = "../../modules/azurerm/security/role-assignment"
  role_scope   = "/subscriptions/${var.management_subscription_id}"
  role_name    = "Contributor"
  principal_id = module.devops_service_principal.service_principal_id

  providers = {
    azurerm = azurerm.management
  }
}

# --------------------------------------------------
# Secure Vault Access (Service Principal)
# --------------------------------------------------
module "sp_vault_access" {
  source       = "../../modules/azurerm/security/vault-access"
  key_vault_id = module.devops_vault.key_vault_id

  access_policies = [
    {
      tenant_id         = var.tenant_id
      object_id         = module.devops_service_principal.service_principal_id
      key_permissions   = ["Get", "List"]
      secret_permissions = ["Get", "List", "Set", "Delete"]
      certificate_permissions = ["Get", "List"]
    }
  ]

  providers = {
    azurerm = azurerm.management
  }
}

