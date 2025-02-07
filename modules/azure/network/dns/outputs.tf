output "dns_zone_id" {
  description = "The ID of the DNS zone"
  value       = azurerm_dns_zone.dns_zone.id
}

output "dns_zone_name" {
  description = "The name of the DNS zone"
  value       = azurerm_dns_zone.dns_zone.name
}

output "dns_zone_resource_group" {
  description = "The resource group name where the DNS zone is located"
  value       = azurerm_dns_zone.dns_zone.resource_group_name
}

output "dns_zone_name_servers" {
  description = "List of name servers assigned to the DNS zone"
  value       = azurerm_dns_zone.dns_zone.name_servers
}

output "dns_zone_soa" {
  description = "SOA record for the DNS zone (retrieved from DNS Zone resource)"
  value = {
    name_servers = azurerm_dns_zone.dns_zone.name_servers
  }
}