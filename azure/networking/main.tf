terraform {
  backend "azurerm" {}
}


# ----------------------------------------
#region Resource Groups (rg)
# ----------------------------------------
resource "azurerm_resource_group" "rg_networking_connectivity" {
  name     = "rg-networking-connectivity"
  location = "eastus"
  provider = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "rg_networking_management" {
  name     = "rg-networking-management"
  location = "eastus"
  provider = azurerm.management

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "rg_networking_identity" {
  name     = "rg-networking-identity"
  location = "eastus"
  provider = azurerm.identity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "rg_networking_lzp1" {
  name     = "rg-networking-lzp1"
  location = "eastus"
  provider = azurerm.lzp1

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "rg_networking_lza2" {
  name     = "rg-networking-lza2"
  location = "eastus"
  provider = azurerm.lza2

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
#region Key Vaults (kv)
# ----------------------------------------
module "networking_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.networking_vault_name
  resource_group_name        = azurerm_resource_group.rg_networking_connectivity.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.connectivity
  }

  depends_on = [azurerm_resource_group.rg_networking_connectivity]
}

# ----------------------------------------
#region Network Watchers (nw)
# ----------------------------------------
module "nw_connectivity" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "nw-connectivity"
  resource_group_name = azurerm_resource_group.rg_networking_connectivity.name
  location            = azurerm_resource_group.rg_networking_connectivity.location

  providers = {
    azurerm = azurerm.connectivity
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_connectivity]
}

module "nw_management" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "nw-management"
  resource_group_name = azurerm_resource_group.rg_networking_management.name
  location            = azurerm_resource_group.rg_networking_management.location

  providers = {
    azurerm = azurerm.management
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_management]
}

module "nw_identity" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "nw-identity"
  resource_group_name = azurerm_resource_group.rg_networking_identity.name
  location            = azurerm_resource_group.rg_networking_identity.location

  providers = {
    azurerm = azurerm.identity
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_identity]
}

module "nw_lzp1" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "nw-lzp1"
  resource_group_name = azurerm_resource_group.rg_networking_lzp1.name
  location            = azurerm_resource_group.rg_networking_lzp1.location

  providers = {
    azurerm = azurerm.lzp1
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_lzp1]
}

module "nw_lza2" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "nw-lza2"
  resource_group_name = azurerm_resource_group.rg_networking_lza2.name
  location            = azurerm_resource_group.rg_networking_lza2.location

  providers = {
    azurerm = azurerm.lza2
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_lza2]
}

# ----------------------------------------
#region vNet Hub (vnet)
# ----------------------------------------
module "vnet_hub" {
  source = "../../modules/azurerm/network/vnet"

  vnet_name           = "vnet-hub-connectivity"
  vnet_location       = azurerm_resource_group.rg_networking_connectivity.location
  vnet_resource_group = azurerm_resource_group.rg_networking_connectivity.name
  vnet_address_space  = ["10.10.0.0/16"]
  dns_servers         = []

  subnets = {
    snet-default = {
      address_prefixes = ["10.10.1.0/24"]
    }

    snet-aci = {
      address_prefixes   = ["10.10.10.0/24"]
      delegation_name    = "aciDelegation"
      delegation_service = "Microsoft.ContainerInstance/containerGroups"
      delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  providers = {
    azurerm = azurerm.connectivity
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_connectivity, module.nw_connectivity]
}

# ----------------------------------------
#region vNet Spokes (vnet)
# ----------------------------------------
module "vnet_spoke_management" {
  source              = "../../modules/azurerm/network/vnet"
  vnet_name           = "vnet-spoke-management"
  vnet_location       = azurerm_resource_group.rg_networking_management.location
  vnet_resource_group = azurerm_resource_group.rg_networking_management.name
  vnet_address_space  = ["10.20.0.0/16"]
  dns_servers         = []

  subnets = {
    snet-default = {
      address_prefixes = ["10.20.1.0/24"]
    }
    snet-storage-private = {
      address_prefixes     = ["10.20.20.0/24"]
      enforce_private_link = true
      service_endpoints    = ["Microsoft.Storage"]
    }
  }

  providers = {
    azurerm = azurerm.management
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_management, module.nw_management]
}

module "vnet_spoke_identity" {
  source              = "../../modules/azurerm/network/vnet"
  vnet_name           = "vnet-spoke-identity"
  vnet_location       = azurerm_resource_group.rg_networking_identity.location
  vnet_resource_group = azurerm_resource_group.rg_networking_identity.name
  vnet_address_space  = ["10.30.0.0/16"]
  dns_servers         = []

  subnets = {
    snet-default = {
      address_prefixes = ["10.30.1.0/24"]
    }
  }

  providers = {
    azurerm = azurerm.identity
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_identity, module.nw_identity]
}

module "vnet_spoke_lzp1" {
  source              = "../../modules/azurerm/network/vnet"
  vnet_name           = "vnet-spoke-lzp1"
  vnet_location       = azurerm_resource_group.rg_networking_lzp1.location
  vnet_resource_group = azurerm_resource_group.rg_networking_lzp1.name
  vnet_address_space  = ["10.40.0.0/16"]
  dns_servers         = []

  subnets = {
    snet-default = {
      address_prefixes = ["10.40.1.0/24"]
    }
    snet-compute = {
      address_prefixes = ["10.40.5.0/24"]
    }
    snet-storage-private = {
     address_prefixes     = ["10.40.20.0/24"]
     enforce_private_link = true
     service_endpoints    = ["Microsoft.Storage"]
    }
    snet-adf-ir = {
      address_prefixes   = ["10.40.30.0/24"]
      delegation_name    = "adfIntegrationRuntimeDelegation"
      delegation_service = "Microsoft.DataFactory/factories"
      delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
    snet-synapse = {
      address_prefixes     = ["10.40.40.0/24"]
      enforce_private_link = true
      service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]
    }
    snet-synapse-pe = {
      address_prefixes     = ["10.40.50.0/24"]
      enforce_private_link = true
      service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]
    }
  }

  providers = {
    azurerm = azurerm.lzp1
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_lzp1, module.nw_lzp1]
}

module "vnet_spoke_lza2" {
  source              = "../../modules/azurerm/network/vnet"
  vnet_name           = "vnet-spoke-lza2"
  vnet_location       = azurerm_resource_group.rg_networking_lza2.location
  vnet_resource_group = azurerm_resource_group.rg_networking_lza2.name
  vnet_address_space  = ["10.50.0.0/16"]
  dns_servers         = []

  subnets = {
    snet-default = {
      address_prefixes = ["10.50.1.0/24"]
    }
  }

  providers = {
    azurerm = azurerm.lza2
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_lza2, module.nw_lza2]
}

# ----------------------------------------
#region vNet Peering
# ----------------------------------------
module "vnet_peering_management" {
  source = "../../modules/azurerm/network/peering"

  hub_to_spoke_peering_name = "hub-to-management-peering"
  hub_vnet_name             = module.vnet_hub.vnet_name
  hub_vnet_resource_group   = azurerm_resource_group.rg_networking_connectivity.name
  hub_vnet_id               = module.vnet_hub.vnet_id

  spoke_to_hub_peering_name = "management-to-hub-peering"
  spoke_vnet_name           = module.vnet_spoke_management.vnet_name
  spoke_vnet_resource_group = azurerm_resource_group.rg_networking_management.name
  spoke_vnet_id             = module.vnet_spoke_management.vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false

  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm.management
  }

  depends_on = [module.vnet_hub, module.vnet_spoke_management]
}

module "vnet_peering_identity" {
  source = "../../modules/azurerm/network/peering"

  hub_to_spoke_peering_name = "hub-to-identity-peering"
  hub_vnet_name             = module.vnet_hub.vnet_name
  hub_vnet_resource_group   = azurerm_resource_group.rg_networking_connectivity.name
  hub_vnet_id               = module.vnet_hub.vnet_id

  spoke_to_hub_peering_name = "identity-to-hub-peering"
  spoke_vnet_name           = module.vnet_spoke_identity.vnet_name
  spoke_vnet_resource_group = azurerm_resource_group.rg_networking_identity.name
  spoke_vnet_id             = module.vnet_spoke_identity.vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false

  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm.identity
  }

  depends_on = [module.vnet_hub, module.vnet_spoke_identity]
}

module "vnet_peering_lzp1" {
  source = "../../modules/azurerm/network/peering"

  hub_to_spoke_peering_name = "hub-to-lzp1-peering"
  hub_vnet_name             = module.vnet_hub.vnet_name
  hub_vnet_resource_group   = azurerm_resource_group.rg_networking_connectivity.name
  hub_vnet_id               = module.vnet_hub.vnet_id

  spoke_to_hub_peering_name = "lzp1-to-hub-peering"
  spoke_vnet_name           = module.vnet_spoke_lzp1.vnet_name
  spoke_vnet_resource_group = azurerm_resource_group.rg_networking_lzp1.name
  spoke_vnet_id             = module.vnet_spoke_lzp1.vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false

  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm.lzp1
  }

  depends_on = [module.vnet_hub, module.vnet_spoke_lzp1]
}

module "vnet_peering_lza2" {
  source = "../../modules/azurerm/network/peering"

  hub_to_spoke_peering_name = "hub-to-lza2-peering"
  hub_vnet_name             = module.vnet_hub.vnet_name
  hub_vnet_resource_group   = azurerm_resource_group.rg_networking_connectivity.name
  hub_vnet_id               = module.vnet_hub.vnet_id

  spoke_to_hub_peering_name = "lza2-to-hub-peering"
  spoke_vnet_name           = module.vnet_spoke_lza2.vnet_name
  spoke_vnet_resource_group = azurerm_resource_group.rg_networking_lza2.name
  spoke_vnet_id             = module.vnet_spoke_lza2.vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false

  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm.lza2
  }

  depends_on = [module.vnet_hub, module.vnet_spoke_lza2]
}

module "vnet_peering_lzp1_to_management" {
  source = "../../modules/azurerm/network/peering"

  hub_to_spoke_peering_name = "lzp1-to-management-peering"
  hub_vnet_name             = module.vnet_spoke_lzp1.vnet_name
  hub_vnet_resource_group   = azurerm_resource_group.rg_networking_lzp1.name
  hub_vnet_id               = module.vnet_spoke_lzp1.vnet_id

  spoke_to_hub_peering_name = "management-to-lzp1-peering"
  spoke_vnet_name           = module.vnet_spoke_management.vnet_name
  spoke_vnet_resource_group = azurerm_resource_group.rg_networking_management.name
  spoke_vnet_id             = module.vnet_spoke_management.vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false

  providers = {
    azurerm.hub   = azurerm.lzp1
    azurerm.spoke = azurerm.management
  }

  depends_on = [module.vnet_spoke_lzp1, module.vnet_spoke_management]
}

# ----------------------------------------
#region Azure Private DNS Zones
# ----------------------------------------
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg_networking_connectivity.name
  provider = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
  depends_on = [azurerm_resource_group.rg_networking_connectivity]
}

resource "azurerm_private_dns_zone" "adf" {
  name                = "privatelink.adf.azure.com"
  resource_group_name = azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity
  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_private_dns_zone" "synapse_dev" {
  name                = "privatelink.dev.azuresynapse.net"
  resource_group_name = azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity
  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_private_dns_zone" "synapse_sql" {
  name                = "privatelink.sql.azuresynapse.net"
  resource_group_name = azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity
  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
#region Internal DNS Zone
# ----------------------------------------
resource "azurerm_private_dns_zone" "internal" {
  name                = "impressiveit.local"
  resource_group_name = azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.rg_networking_connectivity]
}

# ----------------------------------------
#region Internal DNS CNAME Records
# ----------------------------------------
/*
resource "azurerm_private_dns_cname_record" "lotr_alias" {
  name                = "lotrstore"
  zone_name           = azurerm_private_dns_zone.internal.name
  resource_group_name = azurerm_resource_group.rg_networking_connectivity.name
  ttl                 = 300
  record              = "lotrscraperstore.blob.core.windows.net"
  provider            = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
  
  depends_on          = [azurerm_private_dns_zone.internal]
}
*/

# -------------------------------------------------------------
#region Private DNS Zone Virtual Network Links - Internal Zone
# -------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "internal_hub" {
  name                  = "internal-link-hub"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = module.vnet_hub.vnet_id
  registration_enabled  = false
  provider              = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_private_dns_zone.internal, module.vnet_hub]
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal_management" {
  name                  = "internal-link-management"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = module.vnet_spoke_management.vnet_id
  registration_enabled  = false
  provider              = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_private_dns_zone.internal, module.vnet_spoke_management]
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal_identity" {
  name                  = "internal-link-identity"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = module.vnet_spoke_identity.vnet_id
  registration_enabled  = false
  provider              = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_private_dns_zone.internal, module.vnet_spoke_identity]
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal_lzp1" {
  name                  = "internal-link-lzp1"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = module.vnet_spoke_lzp1.vnet_id
  registration_enabled  = false
  provider              = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_private_dns_zone.internal, module.vnet_spoke_lzp1]
}

resource "azurerm_private_dns_zone_virtual_network_link" "internal_lza2" {
  name                  = "internal-link-lza2"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = module.vnet_spoke_lza2.vnet_id
  registration_enabled  = false
  provider              = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_private_dns_zone.internal, module.vnet_spoke_lza2]
}

# --------------------------------------------------------------
#region Private DNS Zone Virtual Network Links - Azure Services
# --------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "blob_management" {
  name                  = "blob-link-management"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = module.vnet_spoke_management.vnet_id
  registration_enabled  = false
  provider              = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_private_dns_zone.blob, module.vnet_spoke_management]
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_lzp1" {
  name                  = "blob-link-lzp1"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = module.vnet_spoke_lzp1.vnet_id
  registration_enabled  = false
  provider = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_private_dns_zone.blob, module.vnet_spoke_lzp1]
}

resource "azurerm_private_dns_zone_virtual_network_link" "adf_lzp1" {
  name                  = "adf-link-lzp1"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.adf.name
  virtual_network_id    = module.vnet_spoke_lzp1.vnet_id
  registration_enabled  = false
  provider              = azurerm.connectivity
  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "synapse_dev_lzp1" {
  name                  = "synapse-dev-link-lzp1"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.synapse_dev.name
  virtual_network_id    = module.vnet_spoke_lzp1.vnet_id
  registration_enabled  = false
  provider              = azurerm.connectivity
  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "synapse_sql_lzp1" {
  name                  = "synapse-sql-link-lzp1"
  resource_group_name   = azurerm_resource_group.rg_networking_connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.synapse_sql.name
  virtual_network_id    = module.vnet_spoke_lzp1.vnet_id
  registration_enabled  = false
  provider              = azurerm.connectivity
  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}