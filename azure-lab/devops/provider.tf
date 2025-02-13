terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
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
    twingate = {
      source  = "twingate/twingate"
      version = "~> 3.0.15"
    }
  }
}

provider "github" {
  token = var.github_token
}

provider "azurerm" {
  alias           = "management"
  subscription_id = var.management_subscription_id
  features {}
}

provider "azuread" {
  alias     = "impressiveit"
  tenant_id = var.tenant_id
}

provider "azuredevops" {
  org_service_url = "https://dev.azure.com/${var.devops_org_name}"

  use_msi = var.use_msi # Enable Managed Identity if true

  # Use the Service Principal created in Terraform
  client_id     = var.use_msi ? null : module.devops_service_principal.client_id
  client_secret = var.use_msi ? null : data.azurerm_key_vault_secret.devops_client_secret.value
  tenant_id     = var.use_msi ? null : module.devops_service_principal.tenant_id

  # If neither MSI nor SP authentication is enabled, fallback to PAT
  personal_access_token = var.use_msi ? null : var.devops_pat
}

provider "twingate" {
  api_token = var.twingate_api_key
  network   = var.twingate_network
}