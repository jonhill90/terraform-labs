resource "azurerm_role_assignment" "role" {
  provider             = azurerm
  scope                = var.role_scope
  role_definition_name = var.role_name
  principal_id         = var.principal_id
}