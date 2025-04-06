output "vnet_id" {
  description = "The ID of the created Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the created Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "subnet_names" {
  description = "Map of subnet names to their IDs"
  value       = { for s in azurerm_subnet.subnets : s.name => s.id }
}

output "subnet_ids" {
  description = "A map of subnet names to their IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_details" {
  description = "Detailed output of each subnet (name, id, address prefix, service endpoints)"
  value = {
    for k, v in azurerm_subnet.subnets : k => {
      id                 = v.id
      name               = v.name
      address_prefixes   = v.address_prefixes
      service_endpoints  = v.service_endpoints
    }
  }
}