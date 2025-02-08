# ----------------------------------------
# GitHub Repository (local)
# ----------------------------------------
module "github_repo" {
  source = "../../modules/github/repo"

  repo_name         = "terraform-labs"
  description       = "Terraform repository for managing cloud infrastructure, security policies, and automation workflows."
  visibility        = "public"
  auto_init         = true
  has_issues        = true
  has_projects      = false
  has_wiki          = false
  allow_merge_commit = true
  allow_squash_merge = true
  allow_rebase_merge = true
}

# --------------------------------------------------
# AzureAD Service Principal - DevOps (local)
# --------------------------------------------------
module "devops_service_principal" {
  source            = "../../modules/azuread/service-principle"
  name              = "devops"
  password_lifetime = "8760h"

  providers = {
    azuread = azuread.impressiveit
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

# ----------------------------------------
# Resource Groups
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