/*
terraform {
  backend "azurerm" {}
}
*/
# ----------------------------------------
# Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "AppMulti-${var.environment}"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}