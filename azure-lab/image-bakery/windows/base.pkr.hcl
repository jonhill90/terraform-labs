packer {
  required_plugins {
    azure = {
      version = ">= 1.5.0"
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

source "azure-arm" "win_base" {
  subscription_id     = var.subscription_id
  resource_group_name = var.resource_group
  location            = var.location
  vm_size             = "Standard_D2s_v3"

  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = var.windows_version

  temporary_resource_group_name = "packer-temp-rg"

  capture_name_prefix = var.image_name
}

build {
  sources = ["source.azure-arm.win_base"]

  provisioner "powershell" {
    inline = [
      "Write-Host 'Configuring Windows Server ${var.windows_version} Base Image...'",
      "powershell.exe -ExecutionPolicy Bypass -File C:\\image-setup\\scripts\\base.ps1"
    ]
  }

  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep to Generalize the Image...'",
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /generalize /oobe /shutdown /mode:vm"
    ]
  }

  post-processor "azure-arm" {
    image_name               = var.image_name
    resource_group_name      = var.resource_group
    gallery_name             = var.gallery_name
    replication_regions      = ["eastus"]
    gallery_image_definition = var.image_name
    subscription_id          = var.subscription_id
  }
}