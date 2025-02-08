output "spoke_to_hub_peering_ids" {
  description = "IDs of Spoke to Hub Peering Connections"
  value       = { for k, v in azurerm_virtual_network_peering.spoke_to_hub : k => v.id }
}

output "hub_to_spoke_peering_ids" {
  description = "IDs of Hub to Spoke Peering Connections"
  value       = { for k, v in azurerm_virtual_network_peering.hub_to_spoke : k => v.id }
}