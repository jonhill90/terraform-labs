resource "azurerm_key_vault" "vault" {
  name                       = var.key_vault_name
  provider                   = azurerm
  location                   = var.location
  resource_group_name        = var.resource_group_name
  sku_name                   = var.sku_name
  tenant_id                  = var.tenant_id
  enable_rbac_authorization  = false
  purge_protection_enabled   = var.purge_protection
  soft_delete_retention_days = var.soft_delete_retention_days
}
