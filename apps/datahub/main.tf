terraform {
  backend "azurerm" {}
}

# ----------------------------------------
#region Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "rg_datahub_lzp1" {
  name     = "rg-datahub-lzp1"
  location = "eastus"
  provider = azurerm.lzp1

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# Networking - LZP1 Regional VNet
data "azurerm_resource_group" "rg_networking_lzp1" {
  name     = "rg-networking-lzp1"
  provider = azurerm.lzp1
}

# Networking - Centralized Connectivity Resources (DNS zones, etc.)
data "azurerm_resource_group" "rg_networking_connectivity" {
  name     = "rg-networking-connectivity"
  provider = azurerm.connectivity
}

# ----------------------------------------
#region Vault (kv)
# ----------------------------------------
module "datahub_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.datahub_vault_name
  resource_group_name        = azurerm_resource_group.rg_datahub_lzp1.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id
  
  # Network ACLs configuration
  network_acls_enabled = true
  virtual_network_subnet_ids = [
    data.azurerm_subnet.snet_vault.id,
    data.azurerm_subnet.snet_compute.id
  ]

  providers = {
    azurerm = azurerm.lzp1
  }

  depends_on = [azurerm_resource_group.rg_datahub_lzp1]
}

# ----------------------------------------
#region Networking
# ----------------------------------------
# Virtual Network - LZP1
data "azurerm_virtual_network" "vnet_lzp1" {
  name                = "vnet-spoke-lzp1"
  resource_group_name = data.azurerm_resource_group.rg_networking_lzp1.name
  provider            = azurerm.lzp1
}

# Subnets
data "azurerm_subnet" "snet_compute" {
  name                 = "snet-compute"
  virtual_network_name = data.azurerm_virtual_network.vnet_lzp1.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_lzp1.name
  provider             = azurerm.lzp1
}

data "azurerm_subnet" "snet_data" {
  name                 = "snet-data"
  virtual_network_name = data.azurerm_virtual_network.vnet_lzp1.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_lzp1.name
  provider             = azurerm.lzp1
}

# Private DNS Zones
data "azurerm_private_dns_zone" "dns_adf" {
  name                = "privatelink.adf.azure.com"
  resource_group_name = data.azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity
}

data "azurerm_private_dns_zone" "dns_synapse_dev" {
  name                = "privatelink.dev.azuresynapse.net"
  resource_group_name = data.azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity
}

data "azurerm_private_dns_zone" "dns_synapse_sql" {
  name                = "privatelink.sql.azuresynapse.net"
  resource_group_name = data.azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity
}

data "azurerm_private_dns_zone" "dns_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity
}

data "azurerm_private_dns_zone" "dns_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.rg_networking_connectivity.name
  provider            = azurerm.connectivity
}

data "azurerm_subnet" "snet_vault" {
  name                 = "snet-vault"
  virtual_network_name = data.azurerm_virtual_network.vnet_lzp1.name
  resource_group_name  = data.azurerm_resource_group.rg_networking_lzp1.name
  provider             = azurerm.lzp1
}

# ----------------------------------------
#region Storage Accounts (sa)
# ----------------------------------------
resource "azurerm_storage_account" "sa_datahub" {
  name                     = var.datahub_sa
  resource_group_name      = azurerm_resource_group.rg_datahub_lzp1.name
  location                 = azurerm_resource_group.rg_datahub_lzp1.location
  provider                 = azurerm.lzp1
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = [
      data.azurerm_subnet.snet_compute.id,
      data.azurerm_subnet.snet_data.id
    ]
    bypass = ["AzureServices"]
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "adls_bronze" {
  name               = "bronze"
  storage_account_id = azurerm_storage_account.sa_datahub.id
  provider           = azurerm.lzp1
}

resource "azurerm_storage_data_lake_gen2_filesystem" "adls_silver" {
  name               = "silver"
  storage_account_id = azurerm_storage_account.sa_datahub.id
  provider           = azurerm.lzp1
}

resource "azurerm_storage_data_lake_gen2_filesystem" "adls_gold" {
  name               = "gold"
  storage_account_id = azurerm_storage_account.sa_datahub.id
  provider           = azurerm.lzp1
}
/*
# ----------------------------------------
#region Data Factory (df)
# ----------------------------------------
resource "azurerm_data_factory" "df_datahub" {
  name                = "df-datahub-lzp1"
  location            = azurerm_resource_group.rg_datahub_lzp1.location
  resource_group_name = azurerm_resource_group.rg_datahub_lzp1.name
  provider            = azurerm.lzp1

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# ----------------------------------------
#region Azure Synapse (synapse)
# ----------------------------------------
resource "azurerm_synapse_workspace" "synapse_datahub" {
  name                                 = "syn-datahub-lzp1"
  location                             = azurerm_resource_group.rg_datahub_lzp1.location
  resource_group_name                  = azurerm_resource_group.rg_datahub_lzp1.name
  provider                             = azurerm.lzp1
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.sc_files.id
  sql_administrator_login              = var.sql_administrator_login
  sql_administrator_login_password     = var.sql_administrator_login_password
  managed_virtual_network_enabled      = true
  managed_resource_group_name          = "rg-datahub-lzp1-syn-managed"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_storage_account.sa_datahub, azurerm_storage_data_lake_gen2_filesystem.sc_files]
}

# Spark Pool for lab and development purposes (cost-optimized)
resource "azurerm_synapse_spark_pool" "spark_datahub" {
  name                 = "labspark"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_datahub.id
  provider             = azurerm.lzp1
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  cache_size           = 0
  spark_version        = "3.3"

  # Very cost-effective configuration with minimal nodes
  auto_scale {
    max_node_count = 3
    min_node_count = 3
  }

  # Set to pause after 15 minutes of inactivity to minimize costs
  auto_pause {
    delay_in_minutes = 15
  }

  session_level_packages_enabled = true

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
    purpose     = "lab"
  }

  depends_on = [azurerm_synapse_workspace.synapse_datahub]
}

# SQL Pool (Dedicated SQL Pool) - Small size for lab purposes
resource "azurerm_synapse_sql_pool" "sql_datahub" {
  name                  = "labsql"
  synapse_workspace_id  = azurerm_synapse_workspace.synapse_datahub.id
  provider              = azurerm.lzp1
  sku_name              = "DW100c"
  create_mode           = "Default"
  storage_account_type  = "LRS"  # Locally redundant storage for lab environment
  geo_backup_policy_enabled = false  # Must be false when using LRS storage

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
    purpose     = "lab"
  }

  depends_on = [azurerm_synapse_workspace.synapse_datahub]
}

# Note: We already have a role assignment for Synapse workspace MSI
# via the ra_synapse_storage_contributor resource above

# ----------------------------------------
#region Private Endpoints (pe)
# ----------------------------------------
# Synapse Managed Private Endpoint for DFS (Spark pool access)
resource "azurerm_synapse_managed_private_endpoint" "mpe_spark_storage" {
  name                 = "mpe-synapse-storage-dfs"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_datahub.id
  target_resource_id   = azurerm_storage_account.sa_datahub.id
  subresource_name     = "dfs"
  provider             = azurerm.lzp1

  depends_on = [
    azurerm_synapse_workspace.synapse_datahub,
    azurerm_storage_account.sa_datahub,
    azurerm_synapse_spark_pool.spark_datahub
  ]
}

# ADLS Private Endpoint
resource "azurerm_private_endpoint" "pe_datahub_blob" {
  name                = "pe-datahub-blob"
  location            = azurerm_resource_group.rg_datahub_lzp1.location
  resource_group_name = azurerm_resource_group.rg_datahub_lzp1.name
  subnet_id           = data.azurerm_subnet.snet_data.id
  provider            = azurerm.lzp1

  private_service_connection {
    name                           = "psc-datahub-blob"
    private_connection_resource_id = azurerm_storage_account.sa_datahub.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dns_blob.id]
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_storage_account.sa_datahub, data.azurerm_private_dns_zone.dns_blob]
}

# Data Factory Private Endpoint
resource "azurerm_private_endpoint" "pe_datahub_df" {
  name                = "pe-datahub-df"
  location            = azurerm_resource_group.rg_datahub_lzp1.location
  resource_group_name = azurerm_resource_group.rg_datahub_lzp1.name
  subnet_id           = data.azurerm_subnet.snet_data.id
  provider            = azurerm.lzp1

  private_service_connection {
    name                           = "psc-datahub-df"
    private_connection_resource_id = azurerm_data_factory.df_datahub.id
    subresource_names              = ["dataFactory"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dns_adf.id]
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_data_factory.df_datahub, data.azurerm_private_dns_zone.dns_adf]
}

# Synapse SQL Private Endpoint
resource "azurerm_private_endpoint" "pe_datahub_synapse_sql" {
  name                = "pe-datahub-synapse-sql"
  location            = azurerm_resource_group.rg_datahub_lzp1.location
  resource_group_name = azurerm_resource_group.rg_datahub_lzp1.name
  subnet_id           = data.azurerm_subnet.snet_data.id
  provider            = azurerm.lzp1

  private_service_connection {
    name                           = "psc-datahub-synapse-sql"
    private_connection_resource_id = azurerm_synapse_workspace.synapse_datahub.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dns_synapse_sql.id]
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_synapse_workspace.synapse_datahub, data.azurerm_private_dns_zone.dns_synapse_sql]
}

# Synapse Dev Private Endpoint
resource "azurerm_private_endpoint" "pe_datahub_synapse_dev" {
  name                = "pe-datahub-synapse-dev"
  location            = azurerm_resource_group.rg_datahub_lzp1.location
  resource_group_name = azurerm_resource_group.rg_datahub_lzp1.name
  subnet_id           = data.azurerm_subnet.snet_data.id
  provider            = azurerm.lzp1

  private_service_connection {
    name                           = "psc-datahub-synapse-dev"
    private_connection_resource_id = azurerm_synapse_workspace.synapse_datahub.id
    subresource_names              = ["Dev"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dns_synapse_dev.id]
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [azurerm_synapse_workspace.synapse_datahub, data.azurerm_private_dns_zone.dns_synapse_dev]
}

# Key Vault Private Endpoint
resource "azurerm_private_endpoint" "pe_datahub_vault" {
  name                = "pe-${var.datahub_vault_name}"
  location            = azurerm_resource_group.rg_datahub_lzp1.location
  resource_group_name = azurerm_resource_group.rg_datahub_lzp1.name
  subnet_id           = data.azurerm_subnet.snet_vault.id
  provider            = azurerm.lzp1

  private_service_connection {
    name                           = "psc-${var.datahub_vault_name}"
    private_connection_resource_id = module.datahub_vault.key_vault_id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dns_vault.id]
  }

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  depends_on = [module.datahub_vault, data.azurerm_private_dns_zone.dns_vault]
}

# ----------------------------------------
#region RBAC Role Assignments
# ----------------------------------------
# Grant Data Factory MSI access to ADLS Gen2
resource "azurerm_role_assignment" "ra_df_storage_contributor" {
  scope                = azurerm_storage_account.sa_datahub.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.df_datahub.identity[0].principal_id
  provider             = azurerm.lzp1

  depends_on = [azurerm_data_factory.df_datahub, azurerm_storage_account.sa_datahub]
}

# Grant Synapse MSI access to ADLS Gen2
resource "azurerm_role_assignment" "ra_synapse_storage_contributor" {
  scope                = azurerm_storage_account.sa_datahub.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse_datahub.identity[0].principal_id
  provider             = azurerm.lzp1

  depends_on = [azurerm_synapse_workspace.synapse_datahub, azurerm_storage_account.sa_datahub]
}

# ----------------------------------------
#region Linked Services (ls)
# ----------------------------------------
# ADF Linked Service for ADLS Gen2
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "ls_adls" {
  name                = "ls_datahub_adls"
  data_factory_id     = azurerm_data_factory.df_datahub.id
  provider            = azurerm.lzp1
  url                 = "https://${azurerm_storage_account.sa_datahub.name}.dfs.core.windows.net"
  use_managed_identity = true

  depends_on = [azurerm_data_factory.df_datahub, azurerm_storage_account.sa_datahub]
}

# Synapse Linked Service for ADLS Gen2
resource "azurerm_synapse_linked_service" "ls_synapse_adls" {
  name                 = "ls_synapse_adls"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_datahub.id
  provider             = azurerm.lzp1
  type                 = "AzureBlobFS"
  type_properties_json = <<JSON
{
  "url": "https://${azurerm_storage_account.sa_datahub.name}.dfs.core.windows.net",
  "connectVia": {
    "referenceName": "AutoResolveIntegrationRuntime",
    "type": "IntegrationRuntimeReference"
  },
  "servicePrincipalId": null,
  "authenticationType": "ManagedServiceIdentity",
  "tenant": null
}
JSON

  depends_on = [azurerm_synapse_workspace.synapse_datahub, azurerm_storage_account.sa_datahub]
}
*/