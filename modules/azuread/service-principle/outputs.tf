output "client_id" {
  description = "Azure AD Application (Service Principal) Client ID"
  value       = azuread_application.sp.client_id
}

output "client_secret" {
  description = "Service Principal Client Secret"
  value       = azuread_service_principal_password.sp.value
  sensitive   = true
}

output "service_principal_id" {
  description = "Service Principal ID"
  value       = azuread_service_principal.sp.id
}