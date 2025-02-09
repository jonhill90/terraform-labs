output "service_principal_id" {
  description = "Service Principal ID"
  value       = azuread_service_principal.sp.id
}

output "client_id" {
  description = "Service Principal Client ID"
  value       = azuread_application.sp.client_id
}

output "client_secret_vault_uri" {
  description = "The URI of the Key Vault secret storing the client secret"
  value       = var.store_secret_in_vault ? "https://${var.key_vault_id}.vault.azure.net/secrets/sp-${var.name}-client-secret" : null
}

output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = var.tenant_id
}