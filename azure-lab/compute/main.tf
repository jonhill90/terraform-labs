# ----------------------------------------
# Resource Groups (local)
# ----------------------------------------
resource "azurerm_resource_group" "lab" {
  name     = "Compute-Lab"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "dev" {
  name     = "Compute-Dev"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = "Dev"
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "test" {
  name     = "Compute-Test"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = "Test"
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "prod" {
  name     = "Compute-Prod"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = "Prod"
    owner       = var.owner
    project     = var.project
  }
}