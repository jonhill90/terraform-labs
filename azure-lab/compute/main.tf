terraform {
  backend "azurerm" {}
}

# ----------------------------------------
# Resource Groups (local)
# ----------------------------------------
resource "azurerm_resource_group" "lab" {
  name     = "Compute-Lab"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "dev" {
  name     = "Compute-Dev"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = "Dev"
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "test" {
  name     = "Compute-Test"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = "Test"
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "prod" {
  name     = "Compute-Prod"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = "Prod"
    owner       = var.owner
    project     = var.project
  }
}

data "azurerm_resource_group" "security" {
  name     = "Security"
  provider = azurerm.lab
}

# --------------------------------------------------
# Secure Vault
# --------------------------------------------------
data "azurerm_key_vault" "compute" {
  name                = var.vault_name
  resource_group_name = data.azurerm_resource_group.security.name
  provider            = azurerm.lab
}

# --------------------------------------------------
# Create Empty Secrets
# --------------------------------------------------
module "compute_secrets" {
  source       = "../../modules/azurerm/security/secret"
  key_vault_id = data.azurerm_key_vault.compute.id
  secrets = {
    "backendContainer"         = ""
    "backendResourceGroup"     = ""
    "backendStorageAccount"    = ""
    "labsubscriptionid"        = ""
    "managementsubscriptionid" = ""
    "tenantid"                 = ""
    "vaultname"                = ""
  }

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [data.azurerm_key_vault.compute]
}