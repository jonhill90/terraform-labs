resource "azuredevops_build_definition" "pipeline" {
  project_id = var.devops_project_id
  name       = var.pipeline_name

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = var.repo_type
    repo_id     = var.repo_id
    branch_name = var.default_branch
    yml_path    = var.pipeline_yaml_path
  }

  variable {
    name  = "TF_VAR_agent_pool"
    value = var.agent_pool_name
  }
}