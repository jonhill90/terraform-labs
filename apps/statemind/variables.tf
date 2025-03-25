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

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  sensitive   = true
}

# ----------------------------------------
# Azure Storage Account
# ----------------------------------------
variable "tfstate_storage_account_name" {
  description = "Azure Storage Account for Terraform State"
  type        = string
}