# ----------------------------------------
#region Azure Universal Print
# ----------------------------------------
module "printers" {
  source = "../../modules/azurerm/print/universal_print_printer"

  for_each = { for printer in var.printers : printer.name => printer }

  name           = each.value.name
  location       = each.value.location
  connector_name = each.value.connector_name
  group_access   = each.value.group_access
  driver_name    = each.value.driver_name
  ip_address     = each.value.ip_address
  floor          = each.value.floor
  model          = each.value.model
}