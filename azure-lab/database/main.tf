# ----------------------------------------
# Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "database" {
  name     = "Database"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}