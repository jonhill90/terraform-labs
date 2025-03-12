# ----------------------------------------
# Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "appmulti-${var.environment}"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}