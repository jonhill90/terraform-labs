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
  type = map(object({
    address_prefixes   = list(string)
    delegation_name    = optional(string)
    delegation_service = optional(string)
    delegation_actions = optional(list(string))
    enforce_private_link = optional(bool)
  }))
}

variable "tags" {
  description = "Tags to apply to all resources in the Virtual Network"
  type        = map(string)
  default     = {}
}

variable "dns_servers" {
  description = "List of custom DNS server IP addresses"
  type        = list(string)
  default     = []
}