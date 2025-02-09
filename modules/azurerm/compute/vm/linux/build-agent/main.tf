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
    public_key = var.ssh_public_key
  }

  # Updated path to cloud-init.yaml in scripts folder
  custom_data = filebase64("${path.module}/scripts/cloud-init.yaml") 

  tags = var.tags
}

resource "null_resource" "ansible_provisioner" {
  depends_on = [azurerm_linux_virtual_machine.vm]

  provisioner "local-exec" {
    command = <<EOT
      ansible-playbook -i '${azurerm_linux_virtual_machine.vm.public_ip_address},' \
        --private-key ~/.ssh/id_rsa -u ${var.admin_username} ${path.module}/scripts/ansible/playbook.yml
    EOT
  }
}