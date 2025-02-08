output "assigned_api_permissions" {
  description = "List of assigned API permissions"
  value       = [for p in azuread_app_role_assignment.api_permissions : p.id]
}