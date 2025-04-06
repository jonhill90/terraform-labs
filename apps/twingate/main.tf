terraform {
  backend "azurerm" {}
}

# ----------------------------------------
# Resource Groups
# ----------------------------------------
data "azurerm_resource_group" "rg_networking_connectivity" {
  name     = "rg-networking-connectivity"
  provider = azurerm.connectivity
}

data "azurerm_resource_group" "rg_compute_lzp1" {
  name     = "rg-compute-lzp1"
  provider = azurerm.lzp1
}

# ----------------------------------------
# Networking
# ----------------------------------------
data "azurerm_virtual_network" "vnet_hub_connectivity" {
  name                = "vnet-hub-connectivity"
  resource_group_name = data.azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity

  depends_on = [data.azurerm_resource_group.rg_networking_connectivity]
}

data "azurerm_subnet" "snet_aci" {
  name                 = "snet-aci"
  virtual_network_name = data.azurerm_virtual_network.vnet_hub_connectivity.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_connectivity.name
  provider             = azurerm.connectivity

  depends_on = [data.azurerm_virtual_network.vnet_hub_connectivity]
}

# ----------------------------------------
# Azure Container Registry (ACR)
# ----------------------------------------
data "azurerm_container_registry" "acr" {
  name                = var.acr
  resource_group_name = data.azurerm_resource_group.rg_compute_lzp1.name
  provider            = azurerm.lzp1

  depends_on = [data.azurerm_resource_group.rg_compute_lzp1]
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
  source              = "../../modules/twingate/network"
  remote_network_name = "Lab"
  connector_name      = "lab-connector"
  twingate_api_key    = var.twingate_api_key
  twingate_network    = var.twingate_network

  subnet_map = {
    "compute" = "10.40.5.0/24"
  }

  access_groups = values(module.twingate_groups.group_ids)

  providers = {
    twingate = twingate
  }

  depends_on = [data.azurerm_container_registry.acr, module.twingate_groups]
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
  location              = data.azurerm_resource_group.rg_networking_connectivity.location
  resource_group        = data.azurerm_resource_group.rg_networking_connectivity.name
  registry_login_server = data.azurerm_container_registry.acr.login_server
  registry_username     = data.azurerm_container_registry.acr.admin_username
  registry_password     = data.azurerm_container_registry.acr.admin_password
  image                 = "twingate-connector"
  image_tag             = "latest"
  cpu                   = "1"
  memory                = "1.5"
  subnet_id             = data.azurerm_subnet.snet_aci.id

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