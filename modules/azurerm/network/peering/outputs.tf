output "hub_to_spoke_peering_id" {
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
  description = "ID of the peering from Hub to Spoke."
}

output "spoke_to_hub_peering_id" {
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
  description = "ID of the peering from Spoke to Hub."
}