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

  dynamic "access_group" {
    for_each = var.access_groups != null ? var.access_groups : []
    content {
      id = access_group.value
    }
  }
}