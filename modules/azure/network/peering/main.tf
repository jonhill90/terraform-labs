resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spoke_vnet_ids

  name                         = "spoke-to-hub-${each.key}"
  resource_group_name          = var.spoke_resource_groups[each.key]
  virtual_network_name         = var.spoke_vnet_names[each.key]
  remote_virtual_network_id    = var.hub_vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_vnet_ids

  name                         = "hub-to-spoke-${each.key}"
  resource_group_name          = var.hub_resource_group
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = each.value
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}