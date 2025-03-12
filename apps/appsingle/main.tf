# ----------------------------------------
# Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "lab" {
  name     = "AppSingle-Lab"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}