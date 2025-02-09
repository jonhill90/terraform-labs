output "devops_project_id" {
  description = "The ID of the created Azure DevOps project"
  value       = azuredevops_project.devops_project.id
}

output "devops_project_name" {
  description = "The name of the created Azure DevOps project"
  value       = azuredevops_project.devops_project.name
}

output "auth_method_used" {
  description = "Indicates which authentication method was used (MSI, SP, or PAT)"
  value       = var.use_msi ? "Managed Identity" : (var.sp_client_id != null ? "Service Principal" : "Personal Access Token (PAT)")
}