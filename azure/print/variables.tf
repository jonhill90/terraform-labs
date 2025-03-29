# ----------------------------------------
#region Azure Subscriptions
# ----------------------------------------
variable "management_subscription_id" {
  description = "Management Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "connectivity_subscription_id" {
  description = "Connectivity Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "identity_subscription_id" {
  description = "Identity Azure Subscription ID"
  type        = string
  sensitive   = true
}
# ----------------------------------------
#region Azure Tenant
# ----------------------------------------
variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  sensitive   = true
}

# ----------------------------------------
#region Azure Service Principal Credentials
# ----------------------------------------
variable "client_id" {
  description = "Azure AD application (client) ID used to authenticate with Microsoft Graph"
  type        = string
}

variable "client_secret" {
  description = "Azure AD application (client) secret used for authentication"
  type        = string
  sensitive   = true
}

# ----------------------------------------
#region Printer Configuration
# ----------------------------------------
variable "printers" {
  description = "List of printers to provision and share"
  type = list(object({
    name           = string
    location       = string
    connector_name = string
    group_access   = list(string)
    driver_name    = string
    ip_address     = string
    floor          = string
    model          = string
  }))
}