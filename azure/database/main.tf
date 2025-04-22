terraform {
  backend "azurerm" {}
}

# ----------------------------------------
#region Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "rg_database_lzp1" {
  name     = "rg-database-lzp1"
  location = "eastus"
  provider = azurerm.lzp1

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
#region Networking
# ----------------------------------------
data "azurerm_resource_group" "rg_networking_lzp1" {
  name     = "rg-networking-lzp1"
  provider = azurerm.lzp1
}

data "azurerm_virtual_network" "vnet_spoke_lzp1" {
  name                = "vnet-spoke-lzp1"
  resource_group_name = data.azurerm_resource_group.rg_networking_lzp1.name
  provider            = azurerm.lzp1

  depends_on = [data.azurerm_resource_group.rg_networking_lzp1]
}

data "azurerm_subnet" "snet_data" {
  name                 = "snet-data"
  virtual_network_name = data.azurerm_virtual_network.vnet_spoke_lzp1.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_lzp1.name
  provider             = azurerm.lzp1

  depends_on = [data.azurerm_virtual_network.vnet_spoke_lzp1]
}

data "azurerm_subnet" "snet_vault" {
  name                 = "snet-vault"
  virtual_network_name = data.azurerm_virtual_network.vnet_spoke_lzp1.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_lzp1.name
  provider             = azurerm.lzp1

  depends_on = [data.azurerm_virtual_network.vnet_spoke_lzp1]
}

data "azurerm_subnet" "snet_compute" {
  name                 = "snet-compute"
  virtual_network_name = data.azurerm_virtual_network.vnet_spoke_lzp1.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_lzp1.name
  provider             = azurerm.lzp1

  depends_on = [data.azurerm_virtual_network.vnet_spoke_lzp1]
}

data "azurerm_resource_group" "rg_networking_connectivity" {
  name     = "rg-networking-connectivity"
  provider = azurerm.connectivity
}

data "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity

  depends_on = [data.azurerm_resource_group.rg_networking_connectivity]
}

# ----------------------------------------
#region Key Vault (kv)
# ----------------------------------------
module "database_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.database_vault_name
  resource_group_name        = azurerm_resource_group.rg_database_lzp1.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id
  
  # Network ACLs configuration
  network_acls_enabled = true
  virtual_network_subnet_ids = [
    data.azurerm_subnet.snet_vault.id,
    data.azurerm_subnet.snet_compute.id
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.rg_database_lzp1]
}

# ----------------------------------------
#region Private Endpoints
# ----------------------------------------
resource "azurerm_private_endpoint" "pe_database_vault" {
  name                = "pe-${var.database_vault_name}"
  location            = azurerm_resource_group.rg_database_lzp1.location
  resource_group_name = azurerm_resource_group.rg_database_lzp1.name
  subnet_id           = data.azurerm_subnet.snet_vault.id
  provider            = azurerm.lzp1

  private_service_connection {
    name                           = "psc-${var.database_vault_name}"
    private_connection_resource_id = module.database_vault.key_vault_id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.vault.id]
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [module.database_vault]
}