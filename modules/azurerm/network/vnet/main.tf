resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  provider            = azurerm
  location            = var.vnet_location
  resource_group_name = var.vnet_resource_group
  address_space       = var.vnet_address_space

  dns_servers         = var.dns_servers

  tags = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.key
  provider             = azurerm
  resource_group_name  = var.vnet_resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = (each.value.delegation_name != null && each.value.delegation_service != null) ? [1] : []
    content {
      name = each.value.delegation_name

      service_delegation {
        name    = each.value.delegation_service
        actions = each.value.delegation_actions
      }
    }
  }
}