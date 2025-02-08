output "devops_project_id" {
  description = "The ID of the created Azure DevOps project"
  value       = azuredevops_project.devops_project.id
}

output "devops_project_name" {
  description = "The name of the created Azure DevOps project"
  value       = azuredevops_project.devops_project.name
}