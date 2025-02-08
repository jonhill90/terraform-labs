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

variable "devops_pat" {
  description = "Azure DevOps Personal Access Token (PAT) for authentication"
  type        = string
  sensitive   = true
}