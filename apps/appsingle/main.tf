/*terraform {
  backend "azurerm" {}
}
*/
# ----------------------------------------
#region Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "rg_appsingle_lza2" {
  name     = "rg-appsingle-lab"
  location = "eastus"
  provider = azurerm.lza2

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
#region Key Vault (kv)
# ----------------------------------------
module "appsingle_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.appsingle_vault_name
  resource_group_name        = azurerm_resource_group.rg_appsingle_lza2.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lza2
  }

  depends_on = [azurerm_resource_group.rg_appsingle_lza2]
}