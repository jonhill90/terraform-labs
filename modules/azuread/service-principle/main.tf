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