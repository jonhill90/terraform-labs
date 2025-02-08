variable "role_scope" {
  description = "The scope for role assignment (subscription, resource group, etc.)"
  type        = string
}

variable "role_name" {
  description = "Role assigned to the identity"
  type        = string
}

variable "principal_id" {
  description = "The ID of the User, Group, Service Principal, or Managed Identity"
  type        = string
}