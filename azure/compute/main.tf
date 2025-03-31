terraform {
  backend "azurerm" {}
}

# ----------------------------------------
#region Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "rg_compute_lzp1" {
  name     = "rg-compute-lzp1"
  location = "eastus"
  provider = azurerm.lzp1

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

data "azurerm_resource_group" "rg_networking_lzp1" {
  name     = "rg-networking-lzp1"
  provider = azurerm.lzp1
}

# ----------------------------------------
#region Vault (kv)
# ----------------------------------------
module "compute_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.compute_vault_name
  resource_group_name        = azurerm_resource_group.rg_compute_lzp1.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.rg_compute_lzp1]
}

# ----------------------------------------
#region Networking
# ----------------------------------------
data "azurerm_virtual_network" "vnet_spoke_lzp1" {
  name                = "vnet-spoke-lzp1"
  resource_group_name = data.azurerm_resource_group.rg_networking_lzp1.name
  provider            = azurerm.lzp1

  depends_on = [data.azurerm_resource_group.rg_networking_lzp1]
}

data "azurerm_subnet" "snet_compute" {
  name                 = "snet-compute"
  virtual_network_name = data.azurerm_virtual_network.vnet_spoke_lzp1.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_lzp1.name
  provider             = azurerm.lzp1

  depends_on = [data.azurerm_virtual_network.vnet_spoke_lzp1]
}

# ----------------------------------------
#region Azure Container Registry (ACR)
# ----------------------------------------
module "container_registry" {
  source             = "../../modules/azurerm/container/registry"
  acr_name           = var.acr
  acr_resource_group = azurerm_resource_group.rg_compute_lzp1.name
  acr_location       = azurerm_resource_group.rg_compute_lzp1.location

  providers = {
    azurerm = azurerm.lzp1
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
#region Azure Compute Gallery (gal)
# ----------------------------------------
resource "azurerm_shared_image_gallery" "gal_compute" {
  name                = "SharedImageGallary"
  resource_group_name = azurerm_resource_group.rg_compute_lzp1.name
  location            = azurerm_resource_group.rg_compute_lzp1.location
  provider            = azurerm.lzp1
  description         = "Production image gallery for compute resources"

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
#region Azure Compute Gallery Image Definitions
# ----------------------------------------
resource "azurerm_shared_image" "windows_2025_base" {
  name                = "windows-2025-base"
  gallery_name        = azurerm_shared_image_gallery.gal_compute.name
  resource_group_name = azurerm_resource_group.rg_compute_lzp1.name
  location            = azurerm_resource_group.rg_compute_lzp1.location
  provider            = azurerm.lzp1

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

resource "azurerm_shared_image" "windows_2025_core" {
  name                = "windows-2025-core"
  gallery_name        = azurerm_shared_image_gallery.gal_compute.name
  resource_group_name = azurerm_resource_group.rg_compute_lzp1.name
  location            = azurerm_resource_group.rg_compute_lzp1.location
  provider            = azurerm.lzp1

  os_type            = "Windows"
  hyper_v_generation = "V1" # Use "V2" if appropriate for your environment
  identifier {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter-Core-smalldisk"
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}
/*
# ----------------------------------------
#region Virtual Machines
# ----------------------------------------
/*
module "build_agent" {
  source = "../../modules/azurerm/compute/vm/windows/base"

  vm_name                = "build-agent"
  vm_size                = "Standard_D2s_v3"
  location              = azurerm_resource_group.lab.location
  resource_group        = azurerm_resource_group.lab.name
  gallery_name          = azurerm_shared_image_gallery.compute_gallery.name
  image_name            = azurerm_shared_image.windows_2025_core.name
  subnet_id             = data.azurerm_subnet.compute.id
  admin_username        = "azureuser"
  admin_password        = var.admin_password

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [
    data.azurerm_virtual_network.networking,
    data.azurerm_subnet.compute,
    azurerm_shared_image_gallery.compute_gallery,
    azurerm_shared_image.windows_2025_core
  ]
}

/*
module "dc01" {
  source = "../../modules/azurerm/compute/vm/windows/dc"

  vm_name                = "dc01"
  vm_size                = "Standard_D2s_v3"
  location              = azurerm_resource_group.lab.location
  resource_group        = azurerm_resource_group.lab.name
  gallery_name          = azurerm_shared_image_gallery.compute_gallery.name
  image_name            = azurerm_shared_image.windows_2025_base.name
  subnet_id             = data.azurerm_subnet.compute.id
  admin_username        = "azureuser"
  admin_password        = var.admin_password
  domain_name           = var.domain_name
  da_admin_password     = var.da_admin_password

  providers = {
    azurerm = azurerm.lab
  }

  depends_on = [
    data.azurerm_virtual_network.networking,
    data.azurerm_subnet.compute,
    azurerm_shared_image_gallery.compute_gallery,
    azurerm_shared_image.windows_2025_base
  ]
}
*/