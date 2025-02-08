variable "service_principal_object_id" {
  description = "The Object ID of the Service Principal to assign API permissions"
  type        = string
}

variable "api_permissions" {
  description = "List of API permissions to assign (each entry must include resource object ID and app role ID)"
  type = list(object({
    resource_object_id = string # The ID of the API (e.g., Microsoft Graph)
    app_role_id        = string # The specific role to assign (e.g., 'Project.ReadWrite')
  }))
}