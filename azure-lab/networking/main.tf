terraform {
  backend "azurerm" {}
}

# ----------------------------------------
#region Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "networking_connectivity" {
  name     = "Networking"
  location = "eastus"
  provider = azurerm.connectivity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}
/*
resource "azurerm_resource_group" "networking_management" {
  name     = "Networking"
  location = "eastus"
  provider = azurerm.management

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}
*/
resource "azurerm_resource_group" "networking_identity" {
  name     = "Networking"
  location = "eastus"
  provider = azurerm.identity

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_resource_group" "networking" {
  name     = "Networking"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
#region Network - Watchers
# ----------------------------------------
module "network-watcher-connectivity" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "network-watcher"
  resource_group_name = azurerm_resource_group.networking_connectivity.name
  location            = azurerm_resource_group.networking_connectivity.location

  providers = {
    azurerm = azurerm.connectivity
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.networking_connectivity]
}
/*
module "network-watcher-management" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "network-watcher"
  resource_group_name = azurerm_resource_group.networking_management.name
  location            = azurerm_resource_group.networking_management.location

  providers = {
    azurerm = azurerm.management
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.networking_management]
}
*/
module "network-watcher-identity" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "network-watcher"
  resource_group_name = azurerm_resource_group.networking_identity.name
  location            = azurerm_resource_group.networking_identity.location

  providers = {
    azurerm = azurerm.identity
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.networking_identity]
}

module "network-watcher" {
  source              = "../../modules/azurerm/network/network-watcher"
  name                = "network-watcher"
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location

  providers = {
    azurerm = azurerm.lab
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_resource_group.networking]
}

# ----------------------------------------
#region vNet Hub
# ----------------------------------------
module "hub_vnet" {
  source = "../../modules/azurerm/network/vnet"

  vnet_name           = "hub-vnet"
  vnet_location       = azurerm_resource_group.networking.location
  vnet_resource_group = azurerm_resource_group.networking.name
  vnet_address_space  = ["10.10.0.0/16"]
  dns_servers         = []

  subnets = {
    default = { address_prefixes = ["10.10.1.0/24"] }
  }

  providers = {
    azurerm = azurerm.connectivity
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
  depends_on = [azurerm_resource_group.networking_connectivity, module.network-watcher-connectivity]
}
# ----------------------------------------
#region vNet Spokes
# ----------------------------------------
module "lab_vnet" {
  source = "../../modules/azurerm/network/vnet"

  vnet_name           = "lab-vnet"
  vnet_location       = azurerm_resource_group.networking.location
  vnet_resource_group = azurerm_resource_group.networking.name
  vnet_address_space  = ["10.100.0.0/16"]
  dns_servers         = []

  subnets = {
    default     = { address_prefixes = ["10.100.1.0/24"] }
    compute     = { address_prefixes = ["10.100.5.0/24"] }
    database    = { address_prefixes = ["10.100.10.0/24"] }
    storage     = { address_prefixes = ["10.100.15.0/24"] }
    application = { address_prefixes = ["10.100.20.0/24"] }
  }

  providers = {
    azurerm = azurerm.lab
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
  depends_on = [azurerm_resource_group.networking, module.network-watcher]
}
/*
module "mgmt_vnet" {
  source = "../../modules/azurerm/network/vnet"

  vnet_name           = "mgmt-vnet"
  vnet_location       = azurerm_resource_group.networking_management.location
  vnet_resource_group = azurerm_resource_group.networking_management.name
  vnet_address_space  = ["10.20.0.0/16"]
  dns_servers         = []

  subnets = {
    default = { address_prefixes = ["10.20.1.0/24"] }
    compute = { address_prefixes = ["10.20.5.0/24"] }
  }

  providers = {
    azurerm = azurerm.management
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
  depends_on = [azurerm_resource_group.networking, module.network-watcher]
}
*/
module "identity_vnet" {
  source = "../../modules/azurerm/network/vnet"

  vnet_name           = "identity-vnet"
  vnet_location       = azurerm_resource_group.networking_identity.location
  vnet_resource_group = azurerm_resource_group.networking_identity.name
  vnet_address_space  = ["10.30.0.0/16"]
  dns_servers         = []

  subnets = {
    default = { address_prefixes = ["10.30.1.0/24"] }
  }

  providers = {
    azurerm = azurerm.identity
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
  depends_on = [azurerm_resource_group.networking, module.network-watcher]
}

# ----------------------------------------
#region vNet Peering
# ----------------------------------------
module "vnet_peering" {
  source = "../../modules/azurerm/network/peering"

  hub_to_spoke_peering_name = "hub-to-lab-peering"
  hub_vnet_name             = module.hub_vnet.vnet_name
  hub_vnet_resource_group   = azurerm_resource_group.networking_connectivity.name
  hub_vnet_id               = module.hub_vnet.vnet_id

  spoke_to_hub_peering_name = "lab-to-hub-peering"
  spoke_vnet_name           = module.lab_vnet.vnet_name
  spoke_vnet_resource_group = azurerm_resource_group.networking.name
  spoke_vnet_id             = module.lab_vnet.vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false

  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm.lab
  }
}
/*
module "vnet_peering_mgmt" {
  source = "../../modules/azurerm/network/peering"

  hub_to_spoke_peering_name = "hub-to-mgmt-peering"
  hub_vnet_name             = module.hub_vnet.vnet_name
  hub_vnet_resource_group   = azurerm_resource_group.networking_connectivity.name
  hub_vnet_id               = module.hub_vnet.vnet_id

  spoke_to_hub_peering_name = "mgmt-to-hub-peering"
  spoke_vnet_name           = module.mgmt_vnet.vnet_name
  spoke_vnet_resource_group = azurerm_resource_group.networking_management.name
  spoke_vnet_id             = module.mgmt_vnet.vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false

  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm.management
  }
}
*/
module "vnet_peering_identity" {
  source = "../../modules/azurerm/network/peering"

  hub_to_spoke_peering_name = "hub-to-identity-peering"
  hub_vnet_name             = module.hub_vnet.vnet_name
  hub_vnet_resource_group   = azurerm_resource_group.networking_connectivity.name
  hub_vnet_id               = module.hub_vnet.vnet_id

  spoke_to_hub_peering_name = "identity-to-hub-peering"
  spoke_vnet_name           = module.identity_vnet.vnet_name
  spoke_vnet_resource_group = azurerm_resource_group.networking_identity.name
  spoke_vnet_id             = module.identity_vnet.vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false

  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm.identity
  }
}

# ----------------------------------------
#region Subnets with Service Delegation
# ----------------------------------------
resource "azurerm_subnet" "aci" {
  name                 = "aci"
  resource_group_name  = azurerm_resource_group.networking_connectivity.name
  virtual_network_name = module.hub_vnet.vnet_name
  address_prefixes     = ["10.10.10.0/24"]
  provider             = azurerm.connectivity

  delegation {
    name = "aci-delegation"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      ]
    }
  }
}
/*
resource "azurerm_subnet" "aci_mgmt" {
  name                 = "aci"
  resource_group_name  = azurerm_resource_group.networking_management.name
  virtual_network_name = module.mgmt_vnet.vnet_name
  address_prefixes     = ["10.20.10.0/24"]
  provider             = azurerm.management

  delegation {
    name = "aci-delegation"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      ]
    }
  }
}
*/
# ----------------------------------------
#region DNS
# ----------------------------------------
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