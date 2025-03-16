resource "azurerm_container_group" "acg" {
  name                = var.container_name
  location            = var.location
  resource_group_name = var.resource_group
  os_type             = "Linux"

  provider = azurerm

  ip_address_type = "Private"
  restart_policy  = "Always"

  subnet_ids = [var.subnet_id]

  container {
    name   = var.container_name
    image  = "${var.registry_login_server}/${var.image}:${var.image_tag}"
    cpu    = var.cpu
    memory = var.memory

    environment_variables        = var.environment_variables
    secure_environment_variables = var.secure_environment_variables

    ports {
      port     = 443
      protocol = "TCP"
    }
  }

  image_registry_credential {
    server   = var.registry_login_server
    username = var.registry_username
    password = var.registry_password
  }
}