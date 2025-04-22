variable "key_vault_name" {
  description = "The name of the Azure Key Vault"
  type        = string
}

variable "resource_group_name" {
  description = "The resource group where the Key Vault is created"
  type        = string
}

variable "location" {
  description = "Azure region where the Key Vault is deployed"
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU ('standard' or 'premium')"
  type        = string
  default     = "standard"
}

variable "purge_protection" {
  description = "Enable purge protection"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention days"
  type        = number
  default     = 90
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  sensitive   = true
}

variable "virtual_network_subnet_ids" {
  description = "List of virtual network subnet IDs"
  type        = list(string)
  default     = []
}

variable "ip_rules" {
  description = "List of IP Addresses to allow access"
  type        = list(string)
  default     = []
}

variable "network_acls_enabled" {
  description = "Enable network ACLs"
  type        = bool
  default     = false
}