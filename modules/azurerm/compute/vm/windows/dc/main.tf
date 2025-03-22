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
  name                  = var.vm_name
  resource_group_name   = var.resource_group
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_id = data.azurerm_shared_image.custom_image.id
  custom_data = base64encode(templatefile("${path.module}/scripts/custom_data.ps1", {
    WINRM_DNS_NAME = "${var.vm_name}.${var.domain_name}"
  }))

  lifecycle {
    ignore_changes = [
      custom_data
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
      powershell -Command "
        \$entry = '${self.private_ip_address} ${var.vm_name}.${var.domain_name}';
        \$path = 'C:\\Windows\\System32\\drivers\\etc\\hosts';
        if (-not (Select-String -Path \$path -Pattern [regex]::Escape(\$entry))) {
          Add-Content -Path \$path -Value \"`n\$entry\";
        } else {
          Write-Host 'Hosts entry already exists. Skipping.';
        }"
    EOT
  }

  provisioner "file" {
    source      = "${path.module}/scripts/FormatDisks.ps1"
    destination = "C:/Windows/Temp/FormatDisks.ps1"
    connection {
      type     = "winrm"
      host     = "${var.vm_name}.${var.domain_name}"
      user     = var.admin_username
      password = var.admin_password
      https    = true
      port     = 5986
      timeout  = "5m"
      insecure = false
    }
  }

  provisioner "remote-exec" {
    connection {
      type     = "winrm"
      host     = "${var.vm_name}.${var.domain_name}"
      user     = var.admin_username
      password = var.admin_password
      https    = true
      port     = 5986
      timeout  = "2m"
      insecure = false
    }
    inline = [
      "powershell -ExecutionPolicy Bypass -File C:\\Windows\\Temp\\FormatDisks.ps1"
    ]
  }

  provisioner "local-exec" {
    command = "powershell -ExecutionPolicy Bypass -File ./scripts/LCM-Configuration.ps1 -ServerName ${self.name} -LCMOutputPath ${var.LCMOutputPath} -DomainName ${var.domain_name} -SafeModeAdminPassword ${var.da_admin_password}"
  }

  provisioner "local-exec" {
    command = "powershell -ExecutionPolicy Bypass -File ./scripts/DSC-Configuration.ps1 -ServerName ${self.name} -DSCOutputPath ${var.DSCOutputPath} -DomainName ${var.domain_name} -SafeModeAdminPassword ${var.da_admin_password}"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = <<EOT
      powershell -Command "
        \$entry = '${self.private_ip_address} ${var.vm_name}.${var.domain_name}';
        \$path = 'C:\\Windows\\System32\\drivers\\etc\\hosts';
        if (Test-Path \$path) {
          \$content = Get-Content \$path | Where-Object { \$_ -notmatch [regex]::Escape(\$entry) };
          Set-Content -Path \$path -Value \$content;
        }"
    EOT
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}