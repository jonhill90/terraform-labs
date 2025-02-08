output "role_assignment_id" {
  description = "The ID of the role assignment"
  value       = azurerm_role_assignment.role.id
}

output "role_scope" {
  description = "The scope where the role is assigned"
  value       = azurerm_role_assignment.role.scope
}

output "role_name" {
  description = "The name of the role assigned"
  value       = azurerm_role_assignment.role.role_definition_name
}

output "principal_id" {
  description = "The ID of the identity that received the role"
  value       = azurerm_role_assignment.role.principal_id
}