resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = var.hub_to_spoke_peering_name
  provider                  = azurerm.hub
  resource_group_name       = var.hub_vnet_resource_group
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = var.spoke_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = var.use_remote_gateways
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = var.spoke_to_hub_peering_name
  provider                  = azurerm.spoke
  resource_group_name       = var.spoke_vnet_resource_group
  virtual_network_name      = var.spoke_vnet_name
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = var.use_remote_gateways
}