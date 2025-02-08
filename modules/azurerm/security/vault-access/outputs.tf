output "access_policies" {
  description = "The applied Key Vault access policies"
  value       = azurerm_key_vault_access_policy.policies[*].id
}