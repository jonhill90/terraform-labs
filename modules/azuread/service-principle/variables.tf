variable "name" {
  description = "The name of the Service Principal"
  type        = string
}

variable "password_lifetime" {
  description = "Duration before the Service Principal password expires (e.g., '8760h' for 1 year)"
  type        = string
  default     = "8760h"
}

variable "tags" {
  description = "Tags for the Azure AD Application"
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "The ID of the Azure Key Vault where the client secret will be stored"
  type        = string
}

variable "store_secret_in_vault" {
  description = "Whether to store the client secret in Azure Key Vault"
  type        = bool
  default     = true
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  sensitive   = true
}