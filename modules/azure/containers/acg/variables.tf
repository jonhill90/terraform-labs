variable "container_name" {
  description = "The name of the Azure Container Group"
  type        = string
}

variable "location" {
  description = "The Azure region where the container group will be deployed"
  type        = string
}

variable "resource_group" {
  description = "The name of the resource group where the container group will be created"
  type        = string
}

variable "registry_login_server" {
  description = "The login server URL of the Azure Container Registry"
  type        = string
}

variable "registry_username" {
  description = "The username for accessing the Azure Container Registry"
  type        = string
  sensitive   = true
}

variable "registry_password" {
  description = "The password for accessing the Azure Container Registry"
  type        = string
  sensitive   = true
}

variable "image" {
  description = "The name of the Docker image to deploy in the container"
  type        = string
}

variable "image_tag" {
  description = "The tag of the Docker image to deploy"
  type        = string
}

variable "cpu" {
  description = "The amount of CPU to allocate to the container"
  type        = string
}

variable "memory" {
  description = "The amount of memory to allocate to the container"
  type        = string
}

variable "environment_variables" {
  description = "Map of standard environment variables"
  type        = map(string)
}

variable "secure_environment_variables" {
  description = "Map of secure environment variables"
  type        = map(string)
  sensitive   = true
}