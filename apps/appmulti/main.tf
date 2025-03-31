/*terraform {
  backend "azurerm" {}
}
*/
# ----------------------------------------
# Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "rg_appmulti_lza2" {
  name     = "rg-appmulti-${var.environment}"
  location = "eastus"
  provider = azurerm.lza2

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}