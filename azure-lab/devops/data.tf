# Fetch the Service Principal Client ID (Not a secret, so use module output)
data "azuread_service_principal" "devops" {
  object_id = module.devops_service_principal.service_principal_id
}

# Fetch the Service Principal Client Secret securely from Key Vault
data "azurerm_key_vault_secret" "devops_client_secret" {
  name         = "sp-devops-client-secret"
  key_vault_id = module.devops_vault.key_vault_id
  provider     = azurerm.management

  depends_on = [module.devops_service_principal] 
}