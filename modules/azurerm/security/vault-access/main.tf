resource "azurerm_key_vault_access_policy" "policies" {
  count        = length(var.access_policies)
  key_vault_id = var.key_vault_id
  tenant_id    = var.access_policies[count.index].tenant_id
  object_id    = var.access_policies[count.index].object_id

  key_permissions         = var.access_policies[count.index].key_permissions
  secret_permissions      = var.access_policies[count.index].secret_permissions
  certificate_permissions = var.access_policies[count.index].certificate_permissions
}