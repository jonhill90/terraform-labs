resource "azuredevops_variable_group" "this" {
  project_id   = var.project_id
  name         = var.variable_group_name
  description  = var.variable_group_description
  allow_access = true

  key_vault {
    name                = var.key_vault_name
    service_endpoint_id = var.service_endpoint_id
  }

  dynamic "variable" {
    for_each = var.secrets
    content {
      name = variable.value
    }
  }
}