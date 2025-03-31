# ----------------------------------------
#region Tags
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
#region Azure Settings
# ----------------------------------------
variable "lzp1_subscription_id" {
  description = "Landing zone P1 Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "lza2_subscription_id" {
  description = "Landing zone A2 Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "management_subscription_id" {
  description = "Management Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "connectivity_subscription_id" {
  description = "Connectivity Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "identity_subscription_id" {
  description = "Identity Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  sensitive   = true
}

# ----------------------------------------
#region Vault
# ----------------------------------------
variable "compute_vault_name" {
  description = "Compute Vault Name"
  type        = string
  sensitive   = true
}

# ----------------------------------------
#region Azure Container Registry
# ----------------------------------------
variable "acr" {
  description = "Azure Container Registry Name"
  type        = string
}

# ----------------------------------------
#region Admin Password
# ----------------------------------------
variable "admin_password" {
  description = "Admin Password for VMs"
  type        = string
  sensitive   = true
}

# ----------------------------------------
#region Domain Controller
# ----------------------------------------
variable "domain_name" {
  type = string
}

variable "da_admin_password" {
  type      = string
  sensitive = true
}