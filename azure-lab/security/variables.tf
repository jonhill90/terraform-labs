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

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  sensitive   = true
}

# ----------------------------------------
# Azure Service Principal
# ----------------------------------------
variable "client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
}

variable "admin_object_id" {
  description = "Admin Account"
  type        = string
  sensitive   = true
}

variable "sp_object_id" {
  description = "Service Principal Object ID"
  type        = string
  sensitive   = true
}

variable "security_sp_object_id" {
  description = "Security Service Principal Object ID"
  type        = string
  sensitive   = true
}

# ----------------------------------------
# Storage Account
# ----------------------------------------
variable "storage_account" {
  description = "Storage Account"
  type        = string
  sensitive   = true
}

# ----------------------------------------
# Vault
# ----------------------------------------
variable "security_vault_name" {
  description = "Security Vault Name"
  type        = string
  sensitive   = true
}

variable "networking_vault_name" {
  description = "Networking Vault Name"
  type        = string
  sensitive   = true
}

# ----------------------------------------
# Azure DevOps Settings
# ----------------------------------------
variable "devops_org_name" {
  description = "The name of the Azure DevOps Organization"
  type        = string
}

variable "use_msi" {
  description = "Use Managed Identity for authentication instead of a PAT or Service Principal"
  type        = bool
  default     = false
}

variable "devops_pat" {
  description = "Azure DevOps Personal Access Token (PAT) for authentication"
  type        = string
  sensitive   = true
  default     = null  # Optional, only needed if not using SP
}

# ----------------------------------------
# GitHub Settings
# ----------------------------------------
variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_repo_id" {
  description = "GitHub Repository ID"
  type        = string
}
