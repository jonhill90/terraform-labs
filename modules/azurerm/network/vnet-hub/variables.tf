variable "vnet_name" {
  description = "The name of the Virtual Network"
  type        = string
}

variable "vnet_location" {
  description = "The Azure region where the VNet will be deployed"
  type        = string
}

variable "vnet_resource_group" {
  description = "The resource group name for the VNet"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network"
  type        = list(string)
}

variable "subnets" {
  description = "A map of subnets to create inside the Virtual Network"
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "tags" {
  description = "Tags for the VNet"
  type        = map(string)
  default     = {}
}

variable "spoke_vnet_ids" {
  description = "A set of Spoke VNet IDs for hub→spoke peering."
  type        = set(string)  # ✅ Using `set` instead of `list` for uniqueness
  default     = []
}