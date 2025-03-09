variable "key_vault_id" {
  description = "The ID of the Azure Key Vault."
  type        = string
}

variable "secrets" {
  description = "A map of secret names to their initial values."
  type        = map(string)
  default     = {}
}