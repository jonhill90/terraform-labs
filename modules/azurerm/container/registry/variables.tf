variable "acr_name" {
  description = "The name of the Azure Container Registry"
  type        = string
}

variable "acr_resource_group" {
  description = "The resource group for the Azure Container Registry"
  type        = string
}

variable "acr_location" {
  description = "The location for the Azure Container Registry"
  type        = string
}

variable "acr_sku" {
  description = "The SKU for the Azure Container Registry (e.g., Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

variable "tags" {
  description = "Tags for the ACR resource"
  type        = map(string)
}