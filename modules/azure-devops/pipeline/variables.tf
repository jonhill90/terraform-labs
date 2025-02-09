variable "devops_project_id" {
  description = "The ID of the Azure DevOps Project"
  type        = string
}

variable "pipeline_name" {
  description = "The name of the Azure DevOps Pipeline"
  type        = string
}

variable "repo_type" {
  description = "Repository type (GitHub or TfsGit for Azure Repos)"
  type        = string
  default     = "GitHub"
}

variable "repo_id" {
  description = "The repository ID or URL"
  type        = string
}

variable "default_branch" {
  description = "The default branch for the pipeline"
  type        = string
  default     = "main"
}

variable "pipeline_yaml_path" {
  description = "Path to the YAML pipeline file in the repo"
  type        = string
  default     = ".azure-pipelines.yml"
}

variable "agent_pool_name" {
  description = "The agent pool to use (set in YAML pipeline)"
  type        = string
  default     = "Azure Pipelines"
}