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

variable "management_subscription_id" {
  description = "Management Azure Subscription ID"
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
variable "datahub_vault_name" {
  description = "Data Hub Vault Name"
  type        = string
  sensitive   = true
}

# ----------------------------------------
#region Storage Account
# ----------------------------------------
variable "datahub_sa" {
  description = "Data Hub Storage Account Name"
  type        = string
  sensitive   = true
}

# ----------------------------------------
#region SQL Credentials
# ----------------------------------------
variable "sql_administrator_login" {
  description = "SQL Administrator Login"
  type        = string
  sensitive   = true
}

variable "sql_administrator_login_password" {
  description = "SQL Administrator Login Password"
  type        = string
  sensitive   = true
}