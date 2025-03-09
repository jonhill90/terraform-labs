variable "name" {
  description = "The name of the Network Watcher"
  type        = string
  default     = "network-watcher"
}

variable "location" {
  description = "Azure region for Network Watcher"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for Network Watcher"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources in the Virtual Network"
  type        = map(string)
  default     = {}
}