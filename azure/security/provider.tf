terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.6.0"
    }
  }
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

provider "azurerm" {
  alias           = "identity"
  subscription_id = var.identity_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "lzp1"
  subscription_id = var.lzp1_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "lza2"
  subscription_id = var.lza2_subscription_id
  features {}
}

provider "azuread" {
  alias         = "impressiveit"
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

provider "azuredevops" {
  org_service_url = "https://dev.azure.com/${var.devops_org_name}"

  use_msi = var.use_msi # Enable Managed Identity if true

  # Use the Service Principal created in Terraform
  client_id     = var.use_msi ? null : var.client_id
  client_secret = var.use_msi ? null : var.client_secret
  tenant_id     = var.use_msi ? null : var.tenant_id

  # If neither MSI nor SP authentication is enabled, fallback to PAT
  personal_access_token = var.use_msi ? null : var.devops_pat
}