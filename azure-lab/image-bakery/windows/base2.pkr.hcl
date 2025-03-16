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
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  location        = var.location

  vm_size         = "Standard_D2s_v3"
  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = var.windows_version

  # Publish directly to the Shared Image Gallery
  shared_image_gallery_destination {
    subscription         = var.subscription_id
    resource_group       = var.resource_group
    gallery_name         = var.gallery_name
    image_name           = var.image_name
    image_version        = "1.0.0"
    storage_account_type = "Standard_LRS"

    target_region {
      name = var.location
    }
  }

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