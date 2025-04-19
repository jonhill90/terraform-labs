terraform {
  backend "azurerm" {}
}

# ----------------------------------------
#region Resource Groups (local)
# ----------------------------------------
resource "azurerm_resource_group" "rg_storage_lzp1" {
  name     = "rg-storage-lzp1"
  location = "eastus"
  provider = azurerm.lzp1

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

data "azurerm_resource_group" "rg_networking_lzp1" {
  name     = "rg-networking-lzp1"
  provider = azurerm.lzp1
}

data "azurerm_resource_group" "rg_datafactory_lzp1" {
  name     = "rg-datafactory-lzp1"
  provider = azurerm.lzp1
}

# ----------------------------------------
#region Key Vault (kv)
# ----------------------------------------
module "storage_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.storage_vault_name
  resource_group_name        = azurerm_resource_group.rg_storage_lzp1.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.rg_storage_lzp1]
}

# ----------------------------------------
#region Networking
# ----------------------------------------
data "azurerm_virtual_network" "vnet_spoke_lzp1" {
  name                = "vnet-spoke-lzp1"
  resource_group_name = data.azurerm_resource_group.rg_networking_lzp1.name
  provider            = azurerm.lzp1

  depends_on = [data.azurerm_resource_group.rg_networking_lzp1]
}

data "azurerm_subnet" "snet_storage_private_lzp1" {
  name                 = "snet-storage-private"
  virtual_network_name = data.azurerm_virtual_network.vnet_spoke_lzp1.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_lzp1.name
  provider             = azurerm.lzp1

  depends_on = [data.azurerm_virtual_network.vnet_spoke_lzp1]
}

data "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "rg-networking-connectivity"
  provider            = azurerm.connectivity

  depends_on = [data.azurerm_resource_group.rg_networking_lzp1]
}

# ----------------------------------------
#region Storage Accounts (sa)
# ----------------------------------------

# ----------------------------------------
#region Storage Containers (sc)
# ----------------------------------------

# ----------------------------------------
#region Private Endpoints (pe)
# ----------------------------------------
