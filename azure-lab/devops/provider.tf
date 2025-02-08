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
      version = "~> 1.6.0" # Use latest stable version
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
/*
provider "azuredevops" {
  org_service_url    = "https://dev.azure.com/${var.devops_org_name}"
  client_id          = data.azurerm_key_vault_secret.devops_sp_client_id.value
  client_secret_path = data.azurerm_key_vault_secret.devops_sp_client_secret.value
  tenant_id          = var.tenant_id
}
*/
