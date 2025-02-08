variable "key_vault_id" {
  description = "The ID of the Azure Key Vault"
  type        = string
}

variable "access_policies" {
  description = "List of access policies for the Key Vault"
  type = list(object({
    tenant_id         = string
    object_id         = string
    key_permissions   = list(string)
    secret_permissions = list(string)
    certificate_permissions = list(string)
  }))
}