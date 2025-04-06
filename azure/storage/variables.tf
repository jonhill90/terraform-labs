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

variable "connectivity_subscription_id" {
  description = "Connectivity Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  sensitive   = true
}

# ----------------------------------------
#region Vault Settings
# ----------------------------------------
variable "storage_vault_name" {
  description = "Storage Vault Name"
  type        = string
}

# ----------------------------------------
#region Storage Accounts
# ----------------------------------------
variable "lotr_storage_account_name" {
  description = "Storage Account Name"
  type        = string
  sensitive   = true
}

variable "datafactory_storage_account_name" {
  description = "Data Factory Storage Account Name"
  type        = string
  sensitive   = true
}