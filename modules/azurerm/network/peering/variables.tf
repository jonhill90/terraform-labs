variable "hub_vnet_name" {
  type        = string
  description = "The name of the Hub VNet."
}

variable "hub_vnet_resource_group" {
  type        = string
  description = "The resource group of the Hub VNet."
}

variable "hub_vnet_id" {
  type        = string
  description = "The resource ID of the Hub VNet."
}

variable "spoke_vnet_name" {
  type        = string
  description = "The name of the Spoke VNet."
}

variable "spoke_vnet_resource_group" {
  type        = string
  description = "The resource group of the Spoke VNet."
}

variable "spoke_vnet_id" {
  type        = string
  description = "The resource ID of the Spoke VNet."
}

variable "hub_to_spoke_peering_name" {
  type        = string
  description = "The name for the peering from Hub to Spoke."
  default     = "hub-to-spoke-peering"
}

variable "spoke_to_hub_peering_name" {
  type        = string
  description = "The name for the peering from Spoke to Hub."
  default     = "spoke-to-hub-peering"
}

variable "allow_forwarded_traffic" {
  type        = bool
  description = "Allow forwarded traffic between the VNets."
  default     = true
}

variable "allow_gateway_transit" {
  type        = bool
  description = "Allow gateway transit on the peering."
  default     = false
}

variable "use_remote_gateways" {
  type        = bool
  description = "Use remote gateways for the peering."
  default     = false
}