terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    twingate = {
      source  = "twingate/twingate"
      version = "~> 3.0.15"
    }
  }
}

provider "azurerm" {
  alias           = "lab"
  subscription_id = var.lab_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "management"
  subscription_id = var.management_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.connectivity_subscription_id
  features {}
}

provider "twingate" {
  api_token = var.twingate_api_key
  network   = var.twingate_network
}