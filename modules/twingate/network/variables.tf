variable "remote_network_name" {
  description = "The name of the Twingate Remote Network"
  type        = string
}

variable "connector_name" {
  description = "The name of the Twingate Connector"
  type        = string
}

variable "subnet_map" {
  description = "Mapping of subnet names to their CIDR blocks (for Twingate Resources)"
  type        = map(string)
}

variable "twingate_api_key" {
  description = "API Key for Twingate authentication"
  type        = string
}

variable "twingate_network" {
  description = "Twingate Network name"
  type        = string
}

variable "access_groups" {
  type        = list(string)
  description = "List of Twingate Group IDs for access control"
  default     = []
}

variable "custom_dns" {
  description = "Optional custom DNS settings for the Twingate Remote Network (e.g., { primary = \"168.63.129.16\", secondary = \"1.1.1.1\" })"
  type        = map(string)
  default     = null
}