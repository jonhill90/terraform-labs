variable "vnet_name" {
  description = "The name of the Virtual Network"
  type        = string
}

variable "vnet_location" {
  description = "The Azure region where the Virtual Network will be created"
  type        = string
}

variable "vnet_resource_group" {
  description = "The name of the Resource Group containing the Virtual Network"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network"
  type        = list(string)
}

variable "subnets" {
  description = "A map of subnets to create inside the Virtual Network"
  type        = map(object({
    address_prefixes = list(string)
  }))
}

variable "tags" {
  description = "Tags to apply to all resources in the Virtual Network"
  type        = map(string)
  default     = {}
}