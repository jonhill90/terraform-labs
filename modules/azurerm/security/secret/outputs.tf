output "secret_ids" {
  description = "The IDs of the created Key Vault secrets."
  value       = { for k, v in azurerm_key_vault_secret.this : k => v.id }
}