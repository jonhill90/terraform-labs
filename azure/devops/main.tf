terraform {
  backend "azurerm" {}
}

# ----------------------------------------
#region Repositories
# ----------------------------------------
module "github_repo" {
  source = "../../modules/github/repo"

  repo_name          = "terraform-labs"
  description        = "Terraform repository for managing cloud infrastructure, security policies, and automation workflows."
  visibility         = "public"
  auto_init          = true
  has_issues         = true
  has_projects       = false
  has_wiki           = false
  allow_merge_commit = true
  allow_squash_merge = true
  allow_rebase_merge = true
}

# --------------------------------------------------
#region Azure DevOps Projects
# --------------------------------------------------
module "devops_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = var.project
  description         = "DevOps Managed by Terraform"
  visibility          = "private"
  devops_pat          = var.devops_pat

  features = {
    repositories = "disabled"
    testplans    = "disabled"
    artifacts    = "enabled"
    pipelines    = "enabled"
    boards       = "disabled"
  }
}

module "networking_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Networking"
  description         = "Networking Managed by Terraform"
  visibility          = "private"
  devops_pat          = var.devops_pat

  features = {
    repositories = "disabled"
    testplans    = "disabled"
    artifacts    = "enabled"
    pipelines    = "enabled"
    boards       = "disabled"
  }
}

module "compute_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Compute"
  description         = "Compute Managed by Terraform"
  visibility          = "private"
  devops_pat          = var.devops_pat

  features = {
    repositories = "disabled"
    testplans    = "disabled"
    artifacts    = "enabled"
    pipelines    = "enabled"
    boards       = "disabled"
  }
}

module "database_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Database"
  description         = "Database Managed by Terraform"
  visibility          = "private"
  devops_pat          = var.devops_pat

  features = {
    repositories = "disabled"
    testplans    = "disabled"
    artifacts    = "enabled"
    pipelines    = "enabled"
    boards       = "disabled"
  }
}

module "storage_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Storage"
  description         = "Storage Managed by Terraform"
  visibility          = "private"
  devops_pat          = var.devops_pat

  features = {
    repositories = "disabled"
    testplans    = "disabled"
    artifacts    = "enabled"
    pipelines    = "enabled"
    boards       = "disabled"
  }
}

module "application_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "Applications"
  description         = "Applications Managed by Terraform"
  visibility          = "private"
  devops_pat          = var.devops_pat

  features = {
    repositories = "disabled"
    testplans    = "disabled"
    artifacts    = "enabled"
    pipelines    = "enabled"
    boards       = "disabled"
  }
}

module "datahub_project" {
  source = "../../modules/azure-devops/project"

  devops_org_name     = var.devops_org_name
  devops_project_name = "DataHub"
  description         = "DataHub Managed by Terraform"
  visibility          = "private"
  devops_pat          = var.devops_pat

  features = {
    repositories = "enabled"
    testplans    = "disabled"
    artifacts    = "enabled"
    pipelines    = "enabled"
    boards       = "disabled"
  }
}

# ----------------------------------------
#region Resource Groups
# ----------------------------------------
resource "azurerm_resource_group" "rg_devops_management" {
  name     = "rg-devops-management"
  location = "eastus"
  provider = azurerm.management

  tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }
}

# --------------------------------------------------
#region Azure DevOps Service Endpoints (github)
# --------------------------------------------------
resource "azuredevops_serviceendpoint_github" "github" {
  project_id            = module.devops_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.devops_project]
}

resource "azuredevops_serviceendpoint_github" "networking" {
  project_id            = module.networking_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.networking_project]
}

resource "azuredevops_serviceendpoint_github" "compute" {
  project_id            = module.compute_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.compute_project]
}

resource "azuredevops_serviceendpoint_github" "database" {
  project_id            = module.database_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.database_project]
}

resource "azuredevops_serviceendpoint_github" "storage" {
  project_id            = module.storage_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.storage_project]
}

resource "azuredevops_serviceendpoint_github" "application" {
  project_id            = module.application_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.application_project]
}

resource "azuredevops_serviceendpoint_github" "datahub" {
  project_id            = module.datahub_project.devops_project_id
  service_endpoint_name = "GitHub Connection"
  description           = "GitHub service connection for Terraform Labs"

  auth_personal {
    # Use a GitHub PAT for authentication
    personal_access_token = var.github_token
  }

  depends_on = [module.datahub_project]
}

# --------------------------------------------------
#region Key Vault (kv)
# --------------------------------------------------
module "devops_vault" {
  source                     = "../../modules/azurerm/security/vault"
  key_vault_name             = var.devops_vault_name
  resource_group_name        = azurerm_resource_group.rg_devops_management.name
  location                   = "eastus"
  sku_name                   = "standard"
  purge_protection           = false
  soft_delete_retention_days = 90

  tenant_id = var.tenant_id

  providers = {
    azurerm = azurerm.management
  }

  depends_on = [azurerm_resource_group.rg_devops_management]
}


# --------------------------------------------------
#region Azure DevOps Build Pipeline (CI)
# --------------------------------------------------
resource "azuredevops_build_definition" "devops_ci" {
  project_id = module.devops_project.devops_project_id
  name       = "DevOps-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/devops-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.github]
}

resource "azuredevops_build_definition" "networking_ci" {
  project_id = module.networking_project.devops_project_id
  name       = "Networking-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/networking-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.networking.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.networking]
}

resource "azuredevops_build_definition" "compute_ci" {
  project_id = module.compute_project.devops_project_id
  name       = "Compute-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/compute-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.compute.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.compute]
}

resource "azuredevops_build_definition" "database_ci" {
  project_id = module.database_project.devops_project_id
  name       = "Database-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/database-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.database.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.database]
}

resource "azuredevops_build_definition" "storage_ci" {
  project_id = module.storage_project.devops_project_id
  name       = "Storage-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/storage-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.storage.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.storage]
}

resource "azuredevops_build_definition" "appsingle_ci" {
  project_id = module.application_project.devops_project_id
  name       = "AppSingle-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/application/app-single-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.application.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.application]
}

resource "azuredevops_build_definition" "appmulti_ci" {
  project_id = module.application_project.devops_project_id
  name       = "AppMulti-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/application/app-multi-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.application.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.application]
}

resource "azuredevops_build_definition" "win2025_base_ci" {
  project_id = module.compute_project.devops_project_id
  name       = "windows-2025-base-ci"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/image-bakery/windows-2025-base-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.compute.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.compute]
}

resource "azuredevops_build_definition" "win2025_core_ci" {
  project_id = module.compute_project.devops_project_id
  name       = "windows-2025-core-ci"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/image-bakery/windows-2025-core-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.compute.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.compute]
}

resource "azuredevops_build_definition" "twingate_ci" {
  project_id = module.networking_project.devops_project_id
  name       = "Twingate-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/application/twingate-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.networking.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.application]
}

resource "azuredevops_build_definition" "datahub_ci" {
  project_id = module.datahub_project.devops_project_id
  name       = "DataHub-CI"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/application/datahub-ci.yml"
    service_connection_id = azuredevops_serviceendpoint_github.datahub.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.datahub]
}

# Add Agent Pool to the Build Pipeline via DevOps Portal
# Approve Pipeline to use the Agent Pool vis DevOps Portal

# --------------------------------------------------
#region Azure DevOps Release Pipeline (CD)
# --------------------------------------------------
resource "azuredevops_build_definition" "devops_cd" {
  project_id = module.devops_project.devops_project_id
  name       = "DevOps-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/devops-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.github, azuredevops_build_definition.devops_ci]
}

resource "azuredevops_build_definition" "networking_cd" {
  project_id = module.networking_project.devops_project_id
  name       = "Networking-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/networking-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.networking.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.networking, azuredevops_build_definition.networking_ci]
}

resource "azuredevops_build_definition" "compute_cd" {
  project_id = module.compute_project.devops_project_id
  name       = "Compute-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/compute-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.compute.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.compute, azuredevops_build_definition.compute_ci]
}

resource "azuredevops_build_definition" "database_cd" {
  project_id = module.database_project.devops_project_id
  name       = "Database-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/database-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.database.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.database, azuredevops_build_definition.database_ci]
}

resource "azuredevops_build_definition" "storage_cd" {
  project_id = module.storage_project.devops_project_id
  name       = "Storage-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/infrastructure/storage-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.storage.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.storage, azuredevops_build_definition.storage_ci]
}

resource "azuredevops_build_definition" "appsingle_cd" {
  project_id = module.application_project.devops_project_id
  name       = "AppSingle-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/application/app-single-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.application.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.application, azuredevops_build_definition.appsingle_ci]
}

resource "azuredevops_build_definition" "appmulti_cd" {
  project_id = module.application_project.devops_project_id
  name       = "AppMulti-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/application/app-multi-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.application.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.application, azuredevops_build_definition.appmulti_ci]
}

resource "azuredevops_build_definition" "win2025_base_cd" {
  project_id = module.compute_project.devops_project_id
  name       = "windows-2025-base-cd"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/image-bakery/windows-2025-base-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.compute.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.compute, azuredevops_build_definition.win2025_base_ci]
}

resource "azuredevops_build_definition" "win2025_core_cd" {
  project_id = module.compute_project.devops_project_id
  name       = "windows-2025-core-cd"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/image-bakery/windows-2025-core-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.compute.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.compute, azuredevops_build_definition.win2025_core_ci]
}

resource "azuredevops_build_definition" "twingate_cd" {
  project_id = module.networking_project.devops_project_id
  name       = "Twingate-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/application/twingate-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.networking.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.networking, azuredevops_build_definition.twingate_ci]
}

resource "azuredevops_build_definition" "datahub_cd" {
  project_id = module.datahub_project.devops_project_id
  name       = "DataHub-CD"
  path       = "\\"

  repository {
    repo_type             = "GitHub"
    repo_id               = var.github_repo_id
    branch_name           = "main"
    yml_path              = "pipelines/application/datahub-cd.yml"
    service_connection_id = azuredevops_serviceendpoint_github.datahub.id
  }

  ci_trigger {
    use_yaml = true
  }
  depends_on = [azuredevops_serviceendpoint_github.datahub, azuredevops_build_definition.datahub_ci]
}