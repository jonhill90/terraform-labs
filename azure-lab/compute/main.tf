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
    "acr"                      = ""
  }

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [data.azurerm_key_vault.compute]
}

# ----------------------------------------
# Azure Container Registry (ACR)
# ----------------------------------------
module "container_registry" {
  source             = "../../modules/azurerm/container/registry"
  acr_name           = var.acr
  acr_resource_group = azurerm_resource_group.lab.name
  acr_location       = azurerm_resource_group.lab.location
  acr_sku            = "Basic"

  providers = {
    azurerm = azurerm.lab
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ---------------------------------------------------------
# Twingate Image Push Module (Pushes Docker Image to ACR)
# ---------------------------------------------------------
module "twingate_image_push" {
  source                = "../../modules/twingate/connector"
  registry_login_server = module.container_registry.acr_login_server
  acr_id                = module.container_registry.acr_id
  connector_id          = module.twingate_resource.connector_id
  image_name            = "twingate-connector"
  image_tag             = "latest"

  depends_on = [module.container_registry]
}