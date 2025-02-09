variable "devops_org_name" {
  description = "The name of the Azure DevOps Organization"
  type        = string
}

variable "devops_project_name" {
  description = "The name of the Azure DevOps Project"
  type        = string
}

variable "description" {
  description = "Project description"
  type        = string
}

variable "visibility" {
  description = "Project visibility (private or public)"
  type        = string
  default     = "private"
}

# Authentication variables
variable "devops_pat" {
  description = "Azure DevOps Personal Access Token (PAT) for authentication"
  type        = string
  sensitive   = true
  default     = null  # Optional, only needed if not using SP
}

variable "use_msi" {
  description = "Use Managed Identity for authentication instead of a PAT or Service Principal"
  type        = bool
  default     = false
}

variable "sp_client_id" {
  description = "Azure AD Service Principal Client ID (Required if not using PAT or MSI)"
  type        = string
  sensitive   = true
  default     = null
}

variable "sp_client_secret" {
  description = "Azure AD Service Principal Client Secret (Required if using SP auth)"
  type        = string
  sensitive   = true
  default     = null
}

variable "tenant_id" {
  description = "Azure AD Tenant ID (Required if using SP auth)"
  type        = string
  sensitive   = true
  default     = null
}

variable "features" {
  description = "Azure DevOps Project Features (repositories, test plans, artifacts, pipelines, boards, service connections)"
  type        = map(string)
  default = {
    repositories      = "enabled"
    testplans        = "disabled"
    artifacts        = "disabled"
    pipelines        = "enabled"
    boards           = "enabled"
  }
}