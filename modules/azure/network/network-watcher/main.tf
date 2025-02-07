resource "azurerm_network_watcher" "network_watcher" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
}