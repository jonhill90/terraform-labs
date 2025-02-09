output "assigned_api_permissions" {
  description = "List of assigned API permissions"
  value       = [for p in azuread_app_role_assignment.api_permissions : p.id]
}

output "debug_service_principal_object_id" {
  value = var.service_principal_object_id
}