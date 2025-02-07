output "group_ids" {
  description = "Map of Twingate Group Names to IDs"
  value       = { for k, v in twingate_group.groups : k => v.id }
}