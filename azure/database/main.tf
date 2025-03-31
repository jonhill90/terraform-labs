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

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.rg_database_lzp1]
}