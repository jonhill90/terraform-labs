output "service_principal_id" {
  description = "Service Principal ID"
  value       = azuread_service_principal.sp.id
}

output "object_id" {
  description = "Service Principal Object ID"
  value       = azuread_service_principal.sp.object_id
}

output "client_id" {
  description = "Service Principal Client ID"
  value       = azuread_application.sp.client_id
}

output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = var.tenant_id
}