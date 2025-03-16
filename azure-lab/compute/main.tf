terraform {
  backend "azurerm" {}
}

# ----------------------------------------
# Resource Groups (local)
# ----------------------------------------
resource "azurerm_resource_group" "lab" {
  name     = "Compute"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
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
    "acr"                      = ""
  }

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [data.azurerm_key_vault.compute]
}

# ----------------------------------------
# Azure Compute Gallery
# ----------------------------------------
resource "azurerm_shared_image_gallery" "compute_gallery" {
  name                = "ComputeGallery"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  provider            = azurerm.lab
  description         = "Production image gallery for compute resources"

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
# Shared Image Definition for win2025-base
# ----------------------------------------
resource "azurerm_shared_image" "win2025_base" {
  name                = "win2025-base"
  gallery_name        = azurerm_shared_image_gallery.compute_gallery.name
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  provider            = azurerm.lab

  os_type            = "Windows"
  hyper_v_generation = "V2" # Use "V1" if appropriate for your environment
  identifier {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter-smalldisk"
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}