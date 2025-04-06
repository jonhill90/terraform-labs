terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  alias           = "lza2"
  subscription_id = var.lza2_subscription_id
  features {}
}