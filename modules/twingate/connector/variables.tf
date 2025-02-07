variable "registry_login_server" {
  description = "Azure Container Registry login server"
  type        = string
}

variable "acr_id" {
  description = "ID of the Azure Container Registry"
  type        = string
}

variable "connector_id" {
  description = "ID of the Twingate Connector"
  type        = string
}

variable "image_name" { 
  description = "The name of the Docker image to push"
  type        = string
}

variable "image_tag" { 
  description = "The tag for the Docker image"
  type        = string
}