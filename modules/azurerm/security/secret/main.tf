resource "azurerm_key_vault_secret" "this" {
  for_each     = var.secrets
  name         = each.key
  provider     = azurerm
  value        = each.value
  key_vault_id = var.key_vault_id

  lifecycle {
    ignore_changes = [value] # Prevent Terraform from overwriting changes made in the portal
  }
}
