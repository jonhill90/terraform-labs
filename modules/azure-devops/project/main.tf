resource "azuredevops_project" "devops_project" {
  name        = var.devops_project_name
  description = var.description
  visibility  = var.visibility

  features = {
    repositories      = var.features["repositories"]
    testplans        = var.features["testplans"]
    artifacts        = var.features["artifacts"]
    pipelines        = var.features["pipelines"]
    boards           = var.features["boards"]
  }

  depends_on = [null_resource.auth_config]
}

# Ensures authentication is properly set before project creation
resource "null_resource" "auth_config" {
  triggers = {
    use_msi  = var.use_msi
    sp_used  = var.sp_client_id != null ? "true" : "false"
    pat_used = var.devops_pat != null ? "true" : "false"
  }
}