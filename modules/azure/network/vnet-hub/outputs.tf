output "vnet_id" {
  description = "The ID of the created Hub Virtual Network"
  value       = azurerm_virtual_network.hub_vnet.id
}

output "vnet_name" {
  description = "The name of the created Hub VNet"
  value       = azurerm_virtual_network.hub_vnet.name
}

output "subnet_names" {
  description = "Map of subnet names to their IDs"
  value       = { for s in azurerm_subnet.subnets : s.name => s.id }
}

output "subnet_ids" {
  description = "A map of subnet names to their IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}