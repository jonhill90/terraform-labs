terraform {
  backend "azurerm" {}
}

# ----------------------------------------
# Resource Groups (local)
# ----------------------------------------
resource "azurerm_resource_group" "lab" {
  name     = "Compute"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

data "azurerm_resource_group" "security" {
  name     = "Security"
  provider = azurerm.lab
}
# ----------------------------------------
# Compute Network
# ----------------------------------------
data "azurerm_virtual_network" "networking" {
  name                = "lab-vnet"
  resource_group_name = "Networking"
  provider            = azurerm.lab
}

data "azurerm_subnet" "compute" {
  name                 = "compute"
  virtual_network_name = data.azurerm_virtual_network.networking.name
  resource_group_name  = "Networking"
  provider             = azurerm.lab
}

# ----------------------------------------
# Azure Compute Gallery
# ----------------------------------------
resource "azurerm_shared_image_gallery" "compute_gallery" {
  name                = "ComputeGallery"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  provider            = azurerm.lab
  description         = "Production image gallery for compute resources"

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
# Azure Compute Gallery Image Definitions
# ----------------------------------------
resource "azurerm_shared_image" "win2025_base" {
  name                = "win2025-base"
  gallery_name        = azurerm_shared_image_gallery.compute_gallery.name
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  provider            = azurerm.lab

  os_type            = "Windows"
  hyper_v_generation = "V1" # Use "V2" if appropriate for your environment
  identifier {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter-smalldisk"
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
# Test VM
# ----------------------------------------
module "test_vm" {
  source = "../../modules/azurerm/compute/vm/windows"

  vm_name                = "TestVM"
  vm_size                = "Standard_D2s_v3"
  location              = azurerm_resource_group.lab.location
  resource_group        = azurerm_resource_group.lab.name
  gallery_name          = azurerm_shared_image_gallery.compute_gallery.name
  image_name            = azurerm_shared_image.win2025_base.name
  subnet_id             = data.azurerm_subnet.compute.id
  admin_username        = "azureuser"
  admin_password        = var.admin_password

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [
    data.azurerm_virtual_network.networking,
    data.azurerm_subnet.compute,
    azurerm_shared_image_gallery.compute_gallery,
    azurerm_shared_image.win2025_base
  ]
}