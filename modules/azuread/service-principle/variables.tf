variable "name" {
  description = "The name of the Service Principal"
  type        = string
}

variable "password_lifetime" {
  description = "Duration before the Service Principal password expires (e.g., '8760h' for 1 year)"
  type        = string
  default     = "8760h"
}

variable "tags" {
  description = "Tags for the Azure AD Application"
  type        = map(string)
}