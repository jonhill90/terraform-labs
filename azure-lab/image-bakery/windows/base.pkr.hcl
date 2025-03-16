packer {
  required_plugins {
    azure = {
      version = ">= 2.1.6"
      source  = "github.com/hashicorp/azure"
    }
  }
}

variable "subscription_id" {}
variable "resource_group" {}
variable "location" {}
variable "gallery_name" {}
variable "image_name" {}
variable "windows_version" {}
variable "tenant_id" {}
variable "client_id" {}
variable "client_secret" {}

source "azure-arm" "win_base" {
  subscription_id = var.subscription_id
  location        = var.location
  vm_size         = "Standard_D2s_v3"

  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = var.windows_version

  managed_image_name                 = var.image_name
  managed_image_resource_group_name  = var.resource_group
  managed_image_storage_account_type = "Standard_LRS"

  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret

  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_username = "packer"
}

build {
  sources = ["source.azure-arm.win_base"]

  provisioner "powershell" {
    script = "./scripts/sysprep.ps1"
  }
}