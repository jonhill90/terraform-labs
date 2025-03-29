terraform {
  backend "azurerm" {}
}
/*
# ----------------------------------------
# Resource Groups
# ----------------------------------------
data "azurerm_resource_group" "networking" {
  name     = "Networking"
  provider = azurerm.connectivity
}

data "azurerm_resource_group" "compute_connectivity" {
  name     = "Compute"
  provider = azurerm.connectivity
}

# ----------------------------------------
# Networking
# ----------------------------------------
data "azurerm_virtual_network" "networking" {
  name                = "hub-vnet"
  resource_group_name = data.azurerm_resource_group.networking.name
  provider            = azurerm.connectivity
}

data "azurerm_subnet" "aci" {
  name                 = "aci"
  virtual_network_name = data.azurerm_virtual_network.networking.name
  resource_group_name  = data.azurerm_resource_group.networking.name
  provider             = azurerm.connectivity
}

# ----------------------------------------
# Azure Container Registry (ACR)
# ----------------------------------------
data "azurerm_container_registry" "acr" {
  name                = var.acr
  resource_group_name = data.azurerm_resource_group.compute_connectivity.name
  provider            = azurerm.connectivity

  depends_on = [data.azurerm_resource_group.compute_connectivity]
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
    "compute" = "10.100.5.0/24"
  }
  twingate_api_key = var.twingate_api_key
  twingate_network = var.twingate_network

  # Pass only the group IDs dynamically
  access_groups = values(module.twingate_groups.group_ids)
  depends_on    = [module.twingate_groups]
}

# Twingate Image Push Module (Pushes Docker Image to ACR)
module "twingate_image_push" {
  source                = "../../modules/twingate/connector"
  registry_login_server = data.azurerm_container_registry.acr.login_server
  acr_id                = data.azurerm_container_registry.acr.id
  connector_id          = module.twingate_resource.connector_id
  image_name            = "twingate-connector"
  image_tag             = "latest"

  depends_on = [data.azurerm_container_registry.acr, module.twingate_resource]
}

# Twingate ACG Module (Deploys Azure Container Group)
module "twingate_acg" {
  source                = "../../modules/azurerm/container/group"
  container_name        = "twingate-connector"
  location              = data.azurerm_resource_group.networking.location
  resource_group        = data.azurerm_resource_group.networking.name
  registry_login_server = data.azurerm_container_registry.acr.login_server
  registry_username     = data.azurerm_container_registry.acr.admin_username
  registry_password     = data.azurerm_container_registry.acr.admin_password
  image                 = "twingate-connector"
  image_tag             = "latest"
  cpu                   = "1"
  memory                = "1.5"
  subnet_id             = data.azurerm_subnet.aci.id

  providers = {
    azurerm = azurerm.connectivity
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
*/