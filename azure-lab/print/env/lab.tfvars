# ----------------------------------------
#region Azure Settings
# ----------------------------------------
tenant_id                    = "__tenantid__"
management_subscription_id   = "__managementsubscriptionid__"
connectivity_subscription_id = "__connectivitysubscriptionid__"
identity_subscription_id     = "__identitysubscriptionid__"

# ----------------------------------------
#region Printers
# ----------------------------------------
printers = [
  {
    name           = "Xerox-Lobby"
    location       = "1st Floor Lobby"
    connector_name = "print-connector-01"
    group_access   = ["print-users", "hr-staff"]
    driver_name    = "Xerox Global Print Driver PCL6"
    ip_address     = "10.0.1.25"
    floor          = "1"
    model          = "Xerox VersaLink C405"
  },
  {
    name           = "Xerox-IT"
    location       = "3rd Floor IT Wing"
    connector_name = "print-connector-02"
    group_access   = ["print-users", "it-staff"]
    driver_name    = "Xerox Global Print Driver PS"
    ip_address     = "10.0.3.15"
    floor          = "3"
    model          = "Xerox AltaLink B8155"
  }
]
