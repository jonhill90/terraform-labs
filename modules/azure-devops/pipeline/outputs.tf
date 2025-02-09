output "pipeline_id" {
  description = "The ID of the created Azure DevOps pipeline"
  value       = azuredevops_build_definition.pipeline.id
}