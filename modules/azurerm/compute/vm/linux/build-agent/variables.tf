variable "servername" {
  description = "Name of the Linux VM"
  type        = string
}

variable "resource_group_name" {
  description = "Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
}

variable "vm_size" {
  description = "Azure VM Size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "subnet_id" {
  description = "ID of the Azure Subnet"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH Public Key for authentication"
  type        = string
}

variable "os_disk_caching" {
  description = "OS Disk caching mode"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_type" {
  description = "OS Disk storage account type"
  type        = string
  default     = "Standard_LRS"
}

variable "image_publisher" {
  description = "The publisher of the OS image"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "The offer of the OS image"
  type        = string
  default     = "UbuntuServer"
}

variable "image_sku" {
  description = "The SKU of the OS image"
  type        = string
  default     = "20.04-LTS"
}

variable "image_version" {
  description = "The version of the OS image"
  type        = string
  default     = "latest"
}

# ----------------------------
# Tags
# ----------------------------
variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}