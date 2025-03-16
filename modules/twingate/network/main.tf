# Create the Remote Network in Twingate
resource "twingate_remote_network" "remote_network" {
  name = var.remote_network_name
}

# Create a single Twingate Connector inside the Remote Network
resource "twingate_connector" "connector" {
  name              = var.connector_name
  remote_network_id = twingate_remote_network.remote_network.id
}

# Generate Twingate Connector tokens
resource "twingate_connector_tokens" "connector_tokens" {
  connector_id = twingate_connector.connector.id
}

# Create multiple Twingate Resources (one per subnet)
resource "twingate_resource" "resources" {
  for_each          = var.subnet_map
  name              = each.key
  address           = each.value
  remote_network_id = twingate_remote_network.remote_network.id
}

# Attach each Twingate group to each resource
resource "twingate_resource_group" "resource_groups" {
  for_each = { for k, v in var.subnet_map : k => v if length(var.access_groups) > 0 }

  resource_id = twingate_resource.resources[each.key].id
  group_id    = var.access_groups[0]  # Assign first group in the list (adjust if needed)
}