terraform {
  backend "azurerm" {}
}

# ----------------------------------------
#region Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "rg_appsingle_lza2" {
  name     = "rg-appsingle-lab"
  location = "eastus"
  provider = azurerm.lza2

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}