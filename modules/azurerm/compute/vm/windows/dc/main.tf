# Data source to fetch the latest image from the Compute Gallery
data "azurerm_shared_image" "custom_image" {
  name                = var.image_name
  gallery_name        = var.gallery_name
  resource_group_name = var.resource_group
}

# Create a Network Interface (NIC) for the VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create the Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_id = data.azurerm_shared_image.custom_image.id
  custom_data = base64encode(file("${path.module}/scripts/custom_data.ps1"))

  provisioner "local-exec" {
    command = "powershell -ExecutionPolicy Bypass -File ./scripts/LCM-Configuration.ps1 -ServerName ${self.name} -LCMOutputPath ${var.LCMOutputPath} -DomainName ${var.domain_name} -SafeModeAdminPassword ${var.da_admin_password}"
  }

  provisioner "local-exec" {
    command = "powershell -ExecutionPolicy Bypass -File ./scripts/DSC-Configuration.ps1 -ServerName ${self.name} -DSCOutputPath ${var.DSCOutputPath} -DomainName ${var.domain_name} -SafeModeAdminPassword ${var.da_admin_password}"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}