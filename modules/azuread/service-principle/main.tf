# Create an Azure AD Application (App Registration)
resource "azuread_application" "sp" {
  display_name = var.name

  # Store tags in the notes field as a JSON string (workaround)
  notes = jsonencode(var.tags)
}

# Create a Service Principal for the Application
resource "azuread_service_principal" "sp" {
  client_id = azuread_application.sp.client_id
}

# Create a Client Secret for the Service Principal
resource "azuread_service_principal_password" "sp" {
  service_principal_id = azuread_service_principal.sp.id
  end_date_relative    = var.password_lifetime
}

# Store Client Secret in Azure Key Vault securely
resource "azurerm_key_vault_secret" "sp_client_secret" {
  count        = var.store_secret_in_vault ? 1 : 0
  name         = "sp-${var.name}-client-secret"
  value        = azuread_service_principal_password.sp.value
  key_vault_id = var.key_vault_id

  # Prevent Terraform from tracking future changes to the secret
  lifecycle {
    ignore_changes = [value]
  }
}