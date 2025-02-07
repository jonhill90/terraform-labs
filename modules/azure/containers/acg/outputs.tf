output "acg_id" {
  description = "ID of the Azure Container Group"
  value       = azurerm_container_group.acg.id
}

output "acg_fqdn" {
  description = "Fully Qualified Domain Name (FQDN) of the deployed container"
  value       = azurerm_container_group.acg.fqdn
}