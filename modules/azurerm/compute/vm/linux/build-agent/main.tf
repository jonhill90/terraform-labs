resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.servername}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "${var.servername}-ssh-private-key"
  value        = tls_private_key.ssh_key.private_key_pem
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "${var.servername}-ssh-public-key"
  value        = tls_private_key.ssh_key.public_key_openssh
  key_vault_id = var.key_vault_id
}

# Fetch SSH public key from Key Vault
data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "${var.servername}-ssh-public-key"
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_key_vault_secret.ssh_public_key]
}

# Fetch the SSH private key from Key Vault**
data "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "${var.servername}-ssh-private-key"
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_key_vault_secret.ssh_private_key]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.servername
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.vm_nic.id]
  disable_password_authentication = true

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_type
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = data.azurerm_key_vault_secret.ssh_public_key.value
  }

  # Injects the DevOps org name & PAT into cloud-init dynamically
  custom_data = base64encode(templatefile("${path.module}/scripts/cloud-init.yaml", {
    DEVOPS_ORG_NAME = var.devops_org_name,
    DEVOPS_PAT      = var.devops_pat
  }))

  tags = var.tags
}
/*
resource "null_resource" "ansible_provisioner" {
  depends_on = [azurerm_key_vault_secret.ssh_private_key, azurerm_linux_virtual_machine.vm]

  provisioner "local-exec" {
    command = <<EOT
      echo "${data.azurerm_key_vault_secret.ssh_private_key.value}" > /tmp/ssh_key.pem
      chmod 600 /tmp/ssh_key.pem
      ansible-playbook -i '${azurerm_linux_virtual_machine.vm.public_ip_address},' \
        --private-key /tmp/ssh_key.pem -u ${var.admin_username} ${path.module}/scripts/playbook.yml
    EOT
  }
}
*/