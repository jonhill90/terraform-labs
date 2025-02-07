variable "repo_name" {
  description = "The name of the GitHub repository"
  type        = string
}

variable "description" {
  description = "Description of the repository"
  type        = string
  default     = "Terraform-managed repository"
}

variable "visibility" {
  description = "Visibility of the repository (public/private)"
  type        = string
  default     = "public"
}

variable "auto_init" {
  description = "Initialize with a README"
  type        = bool
  default     = true
}

variable "has_issues" {
  description = "Enable GitHub Issues"
  type        = bool
  default     = true
}

variable "has_projects" {
  description = "Enable GitHub Projects"
  type        = bool
  default     = false
}

variable "has_wiki" {
  description = "Enable GitHub Wiki"
  type        = bool
  default     = false
}

variable "is_template" {
  description = "Allow this repo to be used as a template"
  type        = bool
  default     = false
}

variable "allow_merge_commit" {
  description = "Allow merge commits"
  type        = bool
  default     = true
}

variable "allow_squash_merge" {
  description = "Allow squash merging"
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Allow rebase merging"
  type        = bool
  default     = true
}