variable "vm_name" {
  description = "Name of the Virtual Machine"
  type        = string
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "location" {
  description = "Azure region where the VM will be deployed"
  type        = string
}

variable "resource_group" {
  description = "Resource group name"
  type        = string
}

variable "gallery_name" {
  description = "Shared Image Gallery name"
  type        = string
}

variable "image_name" {
  description = "Name of the image in the Shared Image Gallery"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the VM will be attached"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "LCMOutputPath" {
    type = "string"
    default = ".\\LCM"
}

variable "DSCOutputPath" {
    type = "string"
    default = ".\\DSC"
}