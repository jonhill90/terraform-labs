terraform {
  backend "azurerm" {}
}

# ----------------------------------------
# Resource Groups (local)
# ----------------------------------------
resource "azurerm_resource_group" "networking" {
  name     = "Networking"
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
data "azurerm_key_vault" "networking" {
  name                = var.vault_name
  resource_group_name = data.azurerm_resource_group.security.name
  provider            = azurerm.lab
}

# --------------------------------------------------
# Create Empty Secrets
# --------------------------------------------------
module "networking_secrets" {
  source       = "../../modules/azurerm/security/secret"
  key_vault_id = data.azurerm_key_vault.networking.id
  secrets = {
    "backendContainer"         = ""
    "backendResourceGroup"     = ""
    "backendStorageAccount"    = ""
    "labsubscriptionid"        = ""
    "managementsubscriptionid" = ""
    "tenantid"                 = ""
    "vaultname"                = ""
    "twingatenetwork"          = ""
    "twingateapikey"           = ""
    "acr"                      = ""
  }

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [data.azurerm_key_vault.networking]
}

# ----------------------------------------
# Network - Watcher
# ----------------------------------------
module "network-watcher" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "network-watcher"
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location

  providers = {
    azurerm = azurerm.lab
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.networking]
}

# ----------------------------------------
# Network - VNet
# ----------------------------------------
module "lab_vnet" {
  source = "../../modules/azurerm/network/vnet"

  vnet_name           = "lab-vnet"
  vnet_location       = azurerm_resource_group.networking.location
  vnet_resource_group = azurerm_resource_group.networking.name
  vnet_address_space  = ["10.100.0.0/16"]

  subnets = {
    default    = { address_prefixes = ["10.100.1.0/24"] }
    management = { address_prefixes = ["10.100.2.0/24"] }
    server     = { address_prefixes = ["10.100.5.0/24"] }
    app        = { address_prefixes = ["10.100.10.0/24"] }
    db         = { address_prefixes = ["10.100.20.0/24"] }
  }

  providers = {
    azurerm = azurerm.lab
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
  depends_on = [azurerm_resource_group.networking, module.network-watcher]
}

# ----------------------------------------
# Azure Container Registry (ACR)
# ----------------------------------------
module "container_registry" {
  source             = "../../modules/azurerm/container/registry"
  acr_name           = var.acr
  acr_resource_group = azurerm_resource_group.networking.name
  acr_location       = azurerm_resource_group.networking.location
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

# ----------------------------------------
# Twingate
# ----------------------------------------
module "twingate_groups" {
  source = "../../modules/twingate/group"

  groups = {
    admins = "Admin Team"
  }
}

module "twingate_resource" {
  source = "../../modules/twingate/network"

  providers = {
    twingate = twingate
  }

  remote_network_name = "Lab"
  connector_name      = "lab-connector"
  subnet_map = {
    "management-subnet" = "10.100.2.0/24"
  }
  twingate_api_key = var.twingate_api_key
  twingate_network = var.twingate_network

}

# Twingate Image Push Module (Pushes Docker Image to ACR)
module "twingate_image_push" {
  source                = "../../modules/twingate/connector"
  registry_login_server = module.container_registry.acr_login_server
  acr_id                = module.container_registry.acr_id
  connector_id          = module.twingate_resource.connector_id
  image_name            = "twingate-connector"
  image_tag             = "latest"

  depends_on = [module.container_registry]
}

# **Twingate ACG Module (Deploys Azure Container Group)**
module "twingate_acg" {
  source                = "../../modules/azurerm/container/group"
  container_name        = "twingate-connector"
  location              = azurerm_resource_group.networking.location
  resource_group        = azurerm_resource_group.networking.name
  registry_login_server = module.container_registry.acr_login_server
  registry_username     = module.container_registry.acr_admin_username
  registry_password     = module.container_registry.acr_admin_password
  image                 = "twingate-connector"
  image_tag             = "latest"
  cpu                   = "1"
  memory                = "1.5"

  providers = {
    azurerm = azurerm.lab
  }

  environment_variables = {
    TWINGATE_NETWORK = module.twingate_resource.twingate_network
  }

  secure_environment_variables = {
    TWINGATE_ACCESS_TOKEN  = module.twingate_resource.connector_tokens.access_token
    TWINGATE_REFRESH_TOKEN = module.twingate_resource.connector_tokens.refresh_token
  }

  depends_on = [module.twingate_image_push]
}