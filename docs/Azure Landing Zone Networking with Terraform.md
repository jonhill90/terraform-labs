# Azure Landing Zone Networking with Terraform

## Overview
This guide explains how to set up networking in an **Azure Landing Zone** using Terraform and Microsoft’s recommended **hub-and-spoke** network topology.

The networking configuration includes:
- A **VNet Hub** deployed into the `Connectivity` subscription.
- **Spoke VNets** deployed into individual **Landing Zone** subscriptions (e.g., `Landing Zone P1`, `Landing Zone A2`).
- **VNet peering** between each Spoke and the Hub.
- **Applications** deployed into Landing Zone subscriptions that consume spoke subnets via **data blocks** (not resource creation).

## Terraform Structure
- A **Terraform Workspace** handles all networking resources.
- **Multiple aliased providers** are used to authenticate and deploy into different Azure subscriptions.
- VNets and Subnets are **declared in their respective subscriptions**, while peering is managed centrally from the Hub.

## Provider Configuration
To deploy into **multiple subscriptions**, you must **alias** the `azurerm` provider for each one:

### `providers.tf`
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  alias           = "management"
  subscription_id = var.management_subscription_id
  features        = {}
}

provider "azurerm" {
  alias           = "identity"
  subscription_id = var.identity_subscription_id
  features        = {}
}

provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.connectivity_subscription_id
  features        = {}
}

provider "azurerm" {
  alias           = "landing_zone_p1"
  subscription_id = var.landing_zone_p1_subscription_id
  features        = {}
}

provider "azurerm" {
  alias           = "landing_zone_a2"
  subscription_id = var.landing_zone_a2_subscription_id
  features        = {}
}

provider "azurerm" {
  alias           = "sandbox"
  subscription_id = var.sandbox_subscription_id
  features        = {}
}
```

## VNet Creation Examples

### Hub VNet in Connectivity Subscription
```hcl
resource "azurerm_virtual_network" "hub" {
  provider            = azurerm.connectivity
  name                = "vnet-hub"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.connectivity_rg
}
```

### Spoke VNet in Landing Zone P1 Subscription
```hcl
resource "azurerm_virtual_network" "spoke_p1" {
  provider            = azurerm.landing_zone_p1
  name                = "vnet-spoke-p1"
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  resource_group_name = var.landing_zone_p1_rg
}
```

## VNet Peering (Spoke to Hub)
```hcl
resource "azurerm_virtual_network_peering" "spoke_p1_to_hub" {
  provider                  = azurerm.landing_zone_p1
  name                      = "peer-spoke-p1-hub"
  resource_group_name       = var.landing_zone_p1_rg
  virtual_network_name      = azurerm_virtual_network.spoke_p1.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke_p1" {
  provider                  = azurerm.connectivity
  name                      = "peer-hub-spoke-p1"
  resource_group_name       = var.connectivity_rg
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_p1.id
  allow_forwarded_traffic   = true
}
```

## Applications Consuming Spoke Subnets via Data Reference
Instead of creating new networks, applications reference the existing **spoke subnets**.

```hcl
data "azurerm_subnet" "app_subnet" {
  provider                 = azurerm.landing_zone_p1
  name                     = "subnet-app"
  virtual_network_name     = azurerm_virtual_network.spoke_p1.name
  resource_group_name      = var.landing_zone_p1_rg
}
```

## Summary
- **Providers are aliased for each subscription** to deploy resources in their respective environments.
- **Hub & Spoke Model** ensures a **centralized connectivity model**.
- **Data Sources** allow applications to consume **existing spoke subnets**.
- **VNet Peering** enables secure **interconnectivity between spokes and the hub**.