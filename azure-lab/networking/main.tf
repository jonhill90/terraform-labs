# ----------------------------------------
# Resource Groups (local)
# ----------------------------------------
resource "azurerm_resource_group" "networking" {
  name     = "networking"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
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
module "vnet" {
  source = "../../modules/azurerm/network/vnet"

  vnet_name           = "${var.project}-vnet"
  vnet_location       = azurerm_resource_group.networking.location
  vnet_resource_group = azurerm_resource_group.networking.name
  vnet_address_space  = ["10.100.0.0/16"]

  subnets = {
    management = { address_prefixes = ["10.100.1.0/24"] }
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