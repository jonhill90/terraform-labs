/*terraform {
  backend "azurerm" {}
}
*/

# ----------------------------------------
#region Resource Groups (rg)
# ----------------------------------------
resource "azurerm_resource_group" "rg_mdp_lza2" {
  name     = "rg-mdp-lab"
  location = "eastus"
  provider = azurerm.lza2

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}