variable "dns_zone_name" {
  description = "The DNS zone name"
  type        = string
}

variable "dns_resource_group" {
  description = "The name of the existing resource group for DNS"
  type        = string
}

variable "dns_location" {
  description = "The Azure region for the DNS resource group"
  type        = string
}

variable "dns_records" {
  description = "DNS records for the zone"
  type = object({
    a_records     = map(object({ ttl = number, values = list(string) }))
    ns_records    = object({ ttl = number, values = list(string) })
    txt_records   = map(object({ ttl = number, value = string }))
    cname_records = map(object({ ttl = number, value = string }))
  })
}