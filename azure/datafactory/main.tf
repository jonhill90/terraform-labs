/*terraform {
  backend "azurerm" {}
}
*/

# ----------------------------------------
#region Resource Groups (rg)
# ----------------------------------------
resource "azurerm_resource_group" "rg_datafactory_lzp1" {
  name     = "rg-datafactory-lzp1"
  location = "eastus"
  provider = azurerm.lzp1

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
#region Data Factory (df)
# ----------------------------------------
resource "azurerm_data_factory" "df_lzp1" {
  name                = "df-${var.environment}-lzp1"
  location            = azurerm_resource_group.rg_datafactory_lzp1.location
  resource_group_name = azurerm_resource_group.rg_datafactory_lzp1.name
  provider            = azurerm.lzp1

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}