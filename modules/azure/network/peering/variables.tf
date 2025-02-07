variable "hub_vnet_id" {
  description = "The ID of the Hub Virtual Network"
  type        = string
}

variable "hub_vnet_name" {
  description = "The name of the Hub Virtual Network"
  type        = string
}

variable "hub_resource_group" {
  description = "The resource group of the Hub Virtual Network"
  type        = string
}

variable "spoke_vnet_ids" {
  description = "Map of Spoke VNet names to their IDs"
  type        = map(string)
}

variable "spoke_vnet_names" {
  description = "Map of Spoke VNet names to their actual names"
  type        = map(string)
}

variable "spoke_resource_groups" {
  description = "Map of Spoke VNet names to their resource groups"
  type        = map(string)
}