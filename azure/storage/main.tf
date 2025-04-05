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
#region Storage Account (sa)
# ----------------------------------------
resource "azurerm_storage_account" "lotr" {
  name                     = "lotrscraperstore"
  resource_group_name      = azurerm_resource_group.rg_storage_lzp1.name
  location                 = azurerm_resource_group.rg_storage_lzp1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  provider                 = azurerm.lzp1
}

resource "azurerm_storage_container" "lotr_data" {
  name                  = "lotr-data"
  storage_account_name  = azurerm_storage_account.lotr.name
  container_access_type = "private"
  provider              = azurerm.lzp1
}