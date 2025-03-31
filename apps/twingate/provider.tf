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
  alias           = "connectivity"
  subscription_id = var.connectivity_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "lzp1"
  subscription_id = var.lzp1_subscription_id
  features {}
}

provider "twingate" {
  api_token = var.twingate_api_key
  network   = var.twingate_network
}