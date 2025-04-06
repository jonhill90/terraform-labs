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
resource "azurerm_storage_account" "lotr" {
  name                     = var.lotr_storage_account_name
  resource_group_name      = azurerm_resource_group.rg_storage_lzp1.name
  location                 = azurerm_resource_group.rg_storage_lzp1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  provider                 = azurerm.lzp1

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
  depends_on = [azurerm_resource_group.rg_storage_lzp1]

  network_rules {
    default_action             = "Deny"
    bypass                    = ["AzureServices"]
    virtual_network_subnet_ids = [
      data.azurerm_subnet.snet_storage_private_lzp1.id
    ]
  }
}

resource "azurerm_storage_account" "datafactory" {
  name                     = var.datafactory_storage_account_name
  resource_group_name      = data.azurerm_resource_group.rg_datafactory_lzp1.name
  location                 = data.azurerm_resource_group.rg_datafactory_lzp1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  provider                 = azurerm.lzp1

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
  depends_on = [data.azurerm_resource_group.rg_datafactory_lzp1]
}

# ----------------------------------------
#region Storage Containers (sc)
# ----------------------------------------
resource "azurerm_storage_container" "lotr_data" {
  name                  = "lotr-data"
  storage_account_name  = azurerm_storage_account.lotr.name
  container_access_type = "private"
  provider              = azurerm.lzp1
}

resource "azurerm_storage_container" "datafactory" {
  name                  = "datafactory"
  storage_account_name  = azurerm_storage_account.datafactory.name
  container_access_type = "private"
  provider              = azurerm.lzp1

  depends_on = [azurerm_storage_account.datafactory]
}

# ----------------------------------------
#region Private Endpoints (pe)
# ----------------------------------------
resource "azurerm_private_endpoint" "lotr_sa_pe" {
  name                = "pe-lotr-sa"
  location            = azurerm_resource_group.rg_storage_lzp1.location
  resource_group_name = azurerm_resource_group.rg_storage_lzp1.name
  subnet_id           = data.azurerm_subnet.snet_storage_private_lzp1.id
  provider            = azurerm.lzp1

  private_service_connection {
    name                           = "psc-lotr-sa"
    private_connection_resource_id = azurerm_storage_account.lotr.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  depends_on = [azurerm_storage_account.lotr]
}

# ----------------------------------------
#region Private DNS Zone Groups (pdzg)
# ----------------------------------------
resource "azurerm_private_dns_zone_group" "lotr_blob_dns" {
  name                 = "default"
  private_endpoint_id  = azurerm_private_endpoint.lotr_sa_pe.id
  private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
  provider             = azurerm.lzp1

  depends_on = [azurerm_private_endpoint.lotr_sa_pe]
}