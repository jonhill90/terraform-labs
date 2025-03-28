# ----------------------------------------
# Tags
# ----------------------------------------
variable "environment" {
  description = "Environment Name (e.g., dev, prod)"
  type        = string
}

variable "owner" {
  description = "Owning Team"
  type        = string
}

variable "project" {
  description = "Project Name"
  type        = string
}

# ----------------------------------------
# Azure Settings
# ----------------------------------------
variable "lab_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "management_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "connectivity_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  sensitive   = true
}

# ----------------------------------------
# Vault
# ----------------------------------------
variable "vault_name" {
  description = "Networking Vault Name"
  type        = string
  sensitive   = true
}

# ----------------------------------------
# Azure Container Registry
# ----------------------------------------
variable "acr" {
  description = "Azure Container Registry Name"
  type        = string
}

# ----------------------------------------
# Admin Password
# ----------------------------------------
variable "admin_password" {
  description = "Admin Password for VMs"
  type        = string
  sensitive   = true
}

# ----------------------------------------
# Domain Controller
# ----------------------------------------
variable "domain_name" {
  type = string
}

variable "da_admin_password" {
  type      = string
  sensitive = true
}