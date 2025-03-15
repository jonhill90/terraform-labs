# Terraform Labs - CI/CD Pipeline Overview

## Introduction
This repository follows **Azure Landing Zone best practices** by using **Terraform workspaces** for different teams and infrastructure components. The CI/CD pipeline ensures **structured deployments**, **workspace isolation**, and **automated infrastructure provisioning**.

For more details on best practices, refer to:
- [Azure Landing Zone Design Areas](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-areas)
- [HashiCorp Terraform Recommended Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices/part3.3)

<p align="left">
  <a href="https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-areas" target="_blank">
    <img src="https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/media/azure-landing-zone-architecture-diagram-hub-spoke.svg" width="50%" alt="Azure Landing Zone Architecture">
  </a>
</p>

## Repository Structure
```plaintext
terraform-labs-main/
|-- apps/
|   |-- appmulti/  # Workspace for appmulti team
|   |-- appsingle/  # Workspace for appsingle team
|
|-- azure-lab/
|   |-- compute/   # Workspace for compute team
|   |-- networking/  # Workspace for networking team
|   |-- security/   # Workspace for security team
|   |-- storage/    # Workspace for storage team
|
|-- pipelines/
|   |-- app-multi-ci.yml
|   |-- compute-ci.yml
|   |-- networking-ci.yml
|
|-- modules/
```

## How This Uses Azure Landing Zone Best Practices
This Terraform structure aligns with **Microsoft's Cloud Adoption Framework**:
- **Subscription Segmentation** → Workloads are split across different **Azure Landing Zone subscriptions**.
- **Workspaces per Team** → Each team folder is a **Terraform workspace**, isolating infrastructure.
- **Networking & Security** → Uses **Hub-Spoke VNet Peering, ExpressRoute, VPNs, and Firewalls**.
- **RBAC & Policies** → Access is **restricted per team**, following **least privilege principles**.
- **Logging & Cost Management** → **Azure Monitor & Log Analytics** centralize operations.

### **Subscription Breakdown**
| Subscription Type | Purpose |
|-------------------|---------|
| **Management** | Centralized logging, monitoring, and security (Azure Monitor, Defender for Cloud). |
| **Identity** | Manages Microsoft Entra ID, DNS, and IAM roles. |
| **Connectivity** | Hosts networking (VNet Peering, ExpressRoute, VPN Gateways, Firewalls). |
| **Landing Zones** | Hosts applications, databases, compute, and storage. |
| **Sandbox** | Used for POC/testing environments. |

## CI/CD Flow
1. **User makes a change** in their respective team folder and commits to the repository.
2. The **CI (Continuous Integration) pipeline** is triggered:
   - Copies Terraform files for the **specific team workspace**.
   - Packages files into an **artifact**.
   - Publishes the artifact for deployment.
3. The **CD (Continuous Deployment) pipeline** runs after CI:
   - **Initializes Terraform** (`terraform init`).
   - **Plans infrastructure changes** (`terraform plan`).
   - **Applies changes** (`terraform apply`, if approved).

## Pipeline Execution
### CI Pipeline - Builds Terraform Artifacts
```yaml
stages:
  - stage: Build
    displayName: 'Build Stage'
    jobs:
      - job: Build
        steps:
          - checkout: self
          - task: CopyFiles@2
            inputs:
              SourceFolder: '$(Build.SourcesDirectory)/azure-lab/$(team)'
              TargetFolder: '$(Build.ArtifactStagingDirectory)/$(artifactName)/azure-lab/$(team)'
          - task: PublishBuildArtifacts
            inputs:
              path: '$(Build.ArtifactStagingDirectory)'
              artifact: '$(artifactName)'
```

### CD Pipeline - Deploys Terraform Configurations
```yaml
stages:
  - stage: TerraformPlan
    displayName: "Terraform Plan"
    jobs:
      - deployment: Terraform_Plan
        steps:
          - task: TerraformCLI@0
            inputs:
              command: 'init'
              workingDirectory: '$(Pipeline.Workspace)/$(artifactName)'
          - task: TerraformCLI@0
            inputs:
              command: 'plan'
              workingDirectory: '$(Pipeline.Workspace)/$(artifactName)'
  - stage: TerraformApply
    displayName: "Terraform Apply"
    jobs:
      - deployment: Terraform_Apply
        steps:
          - task: TerraformCLI@0
            inputs:
              command: 'apply'
              workingDirectory: '$(Pipeline.Workspace)/$(artifactName)'
```

## Summary
- **Each team folder is a Terraform workspace**, aligning with **Azure Landing Zone designs**.
- **Subscriptions are segmented** to separate management, identity, networking, and workloads.
- **CI/CD follows best practices**, ensuring controlled and structured deployments.
- **Networking & Security** are enforced using **Azure Firewall, VPNs, and VNet Peering**.
- **Logging & Cost Management** are centralized with **Azure Monitor & Log Analytics**.

For more details, check out:
- [Azure Landing Zone Design Areas](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-areas)
- [HashiCorp Terraform Recommended Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices/part3.3)

This setup ensures **scalability, security, and automation**, following **Microsoft’s Cloud Adoption Framework** for Terraform-based infrastructure.