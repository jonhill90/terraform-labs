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

  dynamic "network_acls" {
    for_each = var.network_acls_enabled ? [1] : []
    content {
      default_action = "Deny"
      bypass         = "AzureServices"
      ip_rules       = var.ip_rules
      virtual_network_subnet_ids = var.virtual_network_subnet_ids
    }
  }
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to IP rules to avoid unnecessary updates
      network_acls[0].ip_rules
    ]
  }
}
