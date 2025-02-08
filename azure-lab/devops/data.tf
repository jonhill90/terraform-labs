data "azurerm_key_vault_secret" "devops_sp_client_id" {
  name         = "devops-sp-client-id"
  key_vault_id = module.devops_vault.key_vault_id
}

data "azurerm_key_vault_secret" "devops_sp_client_secret" {
  name         = "devops-sp-client-secret"
  key_vault_id = module.devops_vault.key_vault_id
}