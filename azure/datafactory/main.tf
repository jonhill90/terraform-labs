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

# ----------------------------------------
#region Storage Accounts (sa)
# ----------------------------------------
data "azurerm_storage_account" "datafactory" {
  name                = var.datafactory_storage_account_name
  resource_group_name = azurerm_resource_group.rg_datafactory_lzp1.name
  provider            = azurerm.lzp1
}
# ----------------------------------------
#region Storage Containers (sc)
# ----------------------------------------
data "azurerm_storage_container" "datafactory" {
  name                  = "datafactory"
  storage_account_name  = data.azurerm_storage_account.datafactory.name
  provider             = azurerm.lzp1
}

# ----------------------------------------
#region Linked Services (ls)
# ----------------------------------------
resource "azurerm_data_factory_linked_service_azure_blob_storage" "blob_ls" {
  name                = "ls-blob-${var.environment}-lzp1"
  data_factory_id     = azurerm_data_factory.df_lzp1.id
  connection_string   = data.azurerm_storage_account.datafactory.primary_connection_string
  provider            = azurerm.lzp1
}
/*
# ----------------------------------------
#region Datasets (ds)
# ----------------------------------------
resource "azurerm_data_factory_dataset_binary" "json_scraper_data" {
  name                = "ds-json-scraper-${var.environment}-lzp1"
  data_factory_id     = azurerm_data_factory.df_lzp1.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.blob_ls.name
  folder              = "datasets"
  provider            = azurerm.lzp1

  azure_blob_storage_location {
    container = data.azurerm_storage_container.datafactory.name
    path      = "scraper/json/"
    filename  = "tolkien_events.json"
  }
}
*/