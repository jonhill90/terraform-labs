variable "project_id" {
  description = "The ID of the Azure DevOps project."
  type        = string
}

variable "key_vault_name" {
  description = "The name of the Azure Key Vault."
  type        = string
}

variable "service_endpoint_id" {
  description = "The ID of the Azure DevOps service endpoint for Azure."
  type        = string
}

variable "secrets" {
  description = "A list of secret names to be added to the variable group."
  type        = list(string)
}

variable "variable_group_name" {
  description = "The name of the Azure DevOps Variable Group."
  type        = string
}

variable "variable_group_description" {
  description = "The description of the Azure DevOps Variable Group."
  type        = string
}