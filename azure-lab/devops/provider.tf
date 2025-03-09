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
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.6.0"
    }
  }
}

provider "github" {
  token = var.github_token
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