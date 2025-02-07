output "connector_tokens" {
  description = "Twingate Connector Tokens (Access & Refresh)"
  value = {
    access_token  = twingate_connector_tokens.connector_tokens.access_token
    refresh_token = twingate_connector_tokens.connector_tokens.refresh_token
  }
  sensitive = true
}

output "remote_network_id" {
  description = "ID of the Twingate Remote Network"
  value       = twingate_remote_network.remote_network.id
}

output "connector_id" {
  description = "ID of the Twingate Connector"
  value       = twingate_connector.connector.id
}

output "twingate_network" {
  description = "Twingate Network Name"
  value       = var.twingate_network
}