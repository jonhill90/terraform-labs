# Universal Print - Print Team Module

This Terraform setup provisions Universal Print infrastructure across multiple subscriptions and domains in accordance with Microsoft's enterprise landing zone architecture.

## Overview

This module automates the provisioning and configuration of printers for Azure Virtual Desktop (AVD) and traditional cloud-first environments using Microsoft Universal Print. It follows a domain-driven design where print-related resources are separated into their own team domain under `azure-lab/print`.

## Subscriptions Used

The solution is designed to span across the following Azure subscriptions:

- **Management Subscription**
  - Centralized logging (e.g., Log Analytics)
  - Policy management
  - Azure Update Manager
  - Defender for Cloud

- **Identity Subscription**
  - Azure AD group management
  - Role-based access control (RBAC)
  - Group-based printer assignment

- **Landing Zone Subscription (e.g., P1, A2)**
  - Universal Print Connector VM deployments
  - Site-specific or region-specific printer resources

## Module Inputs

Printers are defined using `printers.auto.tfvars` and support the following structure:

```hcl
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
  }
]
```

## How It Works

- The module loops through all printer definitions and provisions group access using the AzureAD provider.
- A placeholder `null_resource` is used for future integration with:
  - DSC scripts
  - PowerShell printer registration
  - Microsoft Graph API automation

## Future Enhancements

- Replace `null_resource` with automated Universal Print registration (via Graph or PowerShell)
- Integrate monitoring and logging with centralized dashboards
- Build Intune printer deployment profiles dynamically from Terraform data

## Dependencies

- Azure AD tenant with Universal Print licensing
- Universal Print Connector VM (if using non-native printers)
- Access to the required subscriptions and RBAC roles

## Intune Integration

Although this module doesn't deploy printers directly to end-user devices, Intune is the recommended method for provisioning Universal Print printers to Azure AD-joined devices and Azure Virtual Desktop (AVD) environments.

Once a printer is provisioned and shared via this module:
- Intune can deploy the printer to users based on Azure AD group membership (defined here)
- This ensures seamless printer mapping for users without relying on legacy GPOs
- It supports modern endpoint management and works well with FSLogix for AVD scenarios

For future enhancements, Intune Configuration Profiles can be dynamically generated based on Terraform-managed printer definitions.