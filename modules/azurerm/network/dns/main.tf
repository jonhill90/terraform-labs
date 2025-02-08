resource "azurerm_dns_zone" "dns_zone" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_resource_group
}

# A Records
resource "azurerm_dns_a_record" "a_records" {
  for_each            = var.dns_records.a_records
  name                = each.key
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = var.dns_resource_group
  ttl                 = each.value.ttl
  records             = each.value.values
}

# NS Records
resource "azurerm_dns_ns_record" "ns_records" {
  name                = "@"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = var.dns_resource_group
  ttl                 = var.dns_records.ns_records.ttl
  records             = var.dns_records.ns_records.values
}

# TXT Records
resource "azurerm_dns_txt_record" "txt_records" {
  for_each            = var.dns_records.txt_records
  name                = each.key
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = var.dns_resource_group
  ttl                 = each.value.ttl
  record {
    value = each.value.value
  }
}

# CNAME Records
resource "azurerm_dns_cname_record" "cname_records" {
  for_each = { for key, value in var.dns_records.cname_records : key => value if length(value.value) > 0 }

  name                = each.key
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = var.dns_resource_group
  ttl                 = each.value.ttl
  record              = each.value.value
}