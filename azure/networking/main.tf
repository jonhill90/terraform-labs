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
    snet-adf-data = {
      address_prefixes = ["10.40.80.0/24"]
    }
    snet-adf-integration = {
      address_prefixes     = ["10.40.85.0/24"]
      enforce_private_link = true
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
    snet-mdp-adf = {
      address_prefixes = ["10.50.20.0/24"]
    }
    snet-mdp-adf-private-endpoints = {
      address_prefixes                          = ["10.50.25.0/24"]
      private_endpoint_network_policies_enabled = false
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
# ----------------------------------------
#region DNS
# ----------------------------------------
/*
module "dns" {
  source = "../../modules/azurerm/network/dns"

  dns_zone_name      = "impressiveit.net"
  dns_resource_group = azurerm_resource_group.networking_connectivity.name
  dns_location       = azurerm_resource_group.networking_connectivity.location

  dns_records = {
    a_records = {
      "@" = { ttl = 3600, values = [] }
    }
    ns_records = {
      ttl = 172800
      values = [
        "ns1-01.azure-dns.com.",
        "ns2-01.azure-dns.net.",
        "ns3-01.azure-dns.org.",
        "ns4-01.azure-dns.info."
      ]
    }
    txt_records = {}
    cname_records = {
      "cdnverify"      = { ttl = 3600, value = "cdnverify.impressiveitweb-fd.azureedge.net" }
      "test"           = { ttl = 3600, value = "" }
      "cdnverify.test" = { ttl = 3600, value = "cdnverify.impressiveit-fd.azureedge.net" }
      "www"            = { ttl = 3600, value = "" }
    }
  }

  providers = {
    azurerm = azurerm.connectivity
  }

  depends_on = [azurerm_resource_group.networking_connectivity]
}
*/