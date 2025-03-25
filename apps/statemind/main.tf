# ----------------------------------------
# Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "statemind" {
  name     = "StateMind-${var.environment}"
  location = "eastus"
  provider = azurerm.lab

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

data "azurerm_resource_group" "networking" {
  name     = "Networking"
  provider = azurerm.lab
}

# ----------------------------------------
# Networking
# ----------------------------------------
data "azurerm_virtual_network" "networking" {
  name                = "lab-vnet"
  resource_group_name = data.azurerm_resource_group.networking.name
  provider            = azurerm.lab
}

data "azurerm_subnet" "compute" {
  name                 = "compute"
  virtual_network_name = data.azurerm_virtual_network.networking.name
  resource_group_name  = data.azurerm_resource_group.networking.name
  provider             = azurerm.lab
}

# ----------------------------------------
# Azure Storage Account (RAG source)
# ----------------------------------------
data "azurerm_storage_account" "tfstate" {
  name                = var.tfstate_storage_account_name
  resource_group_name = azurerm_resource_group.statemind.name
  provider            = azurerm.lab
}

data "azurerm_storage_container" "tfstate" {
  name               = "tfstate"
  storage_account_id = data.azurerm_storage_account.tfstate.id
  provider           = azurerm.lab
}

# ----------------------------------------
# Azure Container Group for Langflow
# ----------------------------------------
resource "azurerm_container_group" "langflow" {
  name                = "langflow-${var.environment}"
  location            = azurerm_resource_group.statemind.location
  resource_group_name = azurerm_resource_group.statemind.name
  os_type             = "Linux"
  subnet_ids          = [data.azurerm_subnet.compute.id]
  dns_name_label      = "service-${var.environment}"

  container {
    name   = "langflow"
    image  = "langflowai/langflow:latest"
    cpu    = "1"
    memory = "2"

    ports {
      port     = 7860
      protocol = "TCP"
    }

    environment_variables = {
      LANGFLOW_PORT = "7860"
    }
  }

  tags = {
    environment = var.environment
    project     = var.project
    owner       = var.owner
  }
}

# ----------------------------------------
# Azure Container Group for etcd
# ----------------------------------------
resource "azurerm_container_group" "etcd" {
  name                = "etcd-${var.environment}"
  location            = azurerm_resource_group.statemind.location
  resource_group_name = azurerm_resource_group.statemind.name
  os_type             = "Linux"
  subnet_ids          = [data.azurerm_subnet.compute.id]
  dns_name_label      = "service-${var.environment}"

  container {
    name   = "milvus-etcd"
    image  = "quay.io/coreos/etcd:v3.5.14"
    cpu    = "1"
    memory = "1.5"

    ports {
      port     = 2379
      protocol = "TCP"
    }

    environment_variables = {
      ETCD_AUTO_COMPACTION_MODE      = "revision"
      ETCD_AUTO_COMPACTION_RETENTION = "1000"
      ETCD_QUOTA_BACKEND_BYTES       = "4294967296"
      ETCD_SNAPSHOT_COUNT            = "50000"
    }

    commands = [
      "etcd",
      "-advertise-client-urls=http://0.0.0.0:2379",
      "-listen-client-urls=http://0.0.0.0:2379",
      "--data-dir",
      "/etcd"
    ]
  }

  tags = {
    environment = var.environment
    project     = var.project
    owner       = var.owner
  }
}

# ----------------------------------------
# Azure Container Group for MinIO
# ----------------------------------------
resource "azurerm_container_group" "minio" {
  name                = "minio-${var.environment}"
  location            = azurerm_resource_group.statemind.location
  resource_group_name = azurerm_resource_group.statemind.name
  os_type             = "Linux"
  subnet_ids          = [data.azurerm_subnet.compute.id]
  dns_name_label      = "service-${var.environment}"

  container {
    name   = "milvus-minio"
    image  = "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    cpu    = "1"
    memory = "1.5"

    ports {
      port     = 9000
      protocol = "TCP"
    }

    ports {
      port     = 9001
      protocol = "TCP"
    }

    environment_variables = {
      MINIO_ROOT_USER     = "minioadmin"
      MINIO_ROOT_PASSWORD = "minioadmin"
    }

    commands = ["minio", "server", "/minio_data", "--console-address", ":9001"]
  }

  tags = {
    environment = var.environment
    project     = var.project
    owner       = var.owner
  }
}

# ----------------------------------------
# Azure Container Group for Milvus
# ----------------------------------------
resource "azurerm_container_group" "milvus" {
  name                = "milvus-${var.environment}"
  location            = azurerm_resource_group.statemind.location
  resource_group_name = azurerm_resource_group.statemind.name
  os_type             = "Linux"
  subnet_ids          = [data.azurerm_subnet.compute.id]
  dns_name_label      = "service-${var.environment}"

  container {
    name   = "milvus-standalone"
    image  = "milvusdb/milvus:v2.5.0-beta"
    cpu    = "2"
    memory = "4"

    ports {
      port     = 19530
      protocol = "TCP"
    }

    ports {
      port     = 9091
      protocol = "TCP"
    }

    environment_variables = {
      ETCD_ENDPOINTS = "milvus-etcd:2379"
      MINIO_ADDRESS  = "milvus-minio:9000"
      MINIO_REGION   = "us-east-1"
    }

    commands = ["milvus", "run", "standalone"]
  }

  tags = {
    environment = var.environment
    project     = var.project
    owner       = var.owner
  }
}