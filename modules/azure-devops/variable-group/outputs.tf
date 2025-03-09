output "variable_group_id" {
  description = "The ID of the created Azure DevOps Variable Group."
  value       = azuredevops_variable_group.this.id
}