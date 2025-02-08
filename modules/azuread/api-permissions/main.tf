resource "azuread_app_role_assignment" "api_permissions" {
  count                = length(var.api_permissions)
  principal_object_id  = var.service_principal_object_id
  app_role_id          = var.api_permissions[count.index].app_role_id
  resource_object_id   = var.api_permissions[count.index].resource_object_id
}