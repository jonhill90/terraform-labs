resource "twingate_group" "groups" {
  for_each = var.groups

  name = each.value
}