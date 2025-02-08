resource "azuredevops_project" "devops_project" {
  name        = var.devops_project_name
  description = var.description
  visibility  = var.visibility
}