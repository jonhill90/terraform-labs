# 🔹 Compute POC – High-Level Plan

## 📌 1. Image Creation – Packer (Golden Image)

### Objective:
Standardize Windows Server builds using a hardened, pre-configured base image.

✅ **Start with Azure CIS Level 2 Hardened Image**
   - Download CIS Benchmark Level 2 image for Windows Server 2022 from Azure Marketplace.
   - Apply baseline security hardening.

✅ **Modify Image for DevOps Compatibility**
   - Remove restrictions on PowerShell execution policies.
   - Enable WinRM over HTTPS for Terraform remote execution.

✅ **Apply Company Branding & Configuration**
   - Set custom background & wallpaper with system specs.

✅ **Install OS & Security Updates**
   - Apply latest Windows updates & security patches.

✅ **Store Final Image in Azure Compute Gallery**
   - Converted into a shared image to be consumed by Terraform deployments.

---

## 📌 2. Server Request Process – ServiceNow

### Objective:
Automate the server provisioning process with an approval workflow.

✅ **Approval Workflow**
   - Server request **submitted** via ServiceNow.
   - Sent to **Server Build Team for review & approval**.
   - Approved request **triggers an update** to `server_requests.tfvars`.
   - Terraform **Plan runs** & outputs result back to ServiceNow for review.
   - Server Build Team **approves execution** → **Terraform Apply runs**.

✅ **Terraform `server_requests.tfvars` Example**
```hcl
servers = [
  {
    name         = "prod-db-01"
    environment  = "prod"
    os_version   = "Windows Server 2022"
    image        = "golden-image-db"
    vm_size      = "Standard_D8s_v3"
    disk_size_gb = 200
    domain_join  = true
    network      = "vnet-prod"
    subnet       = "subnet-db"
    role         = "db"
  },
  {
    name         = "dev-web-01"
    environment  = "dev"
    os_version   = "Windows Server 2022"
    image        = "golden-image-web"
    vm_size      = "Standard_D4s_v3"
    disk_size_gb = 100
    domain_join  = true
    network      = "vnet-dev"
    subnet       = "subnet-web"
    role         = "web"
  }
]
```

✅ **Terraform `main.tf` Example**
```hcl
# Variables for global settings
variable "servers" {}

# Using the Windows Server module dynamically
module "windows_servers" {
  source          = "./modules/windows_server"
  servers        = var.servers
  resource_group = var.resource_group
  location       = var.location
  admin_username = var.admin_username
  admin_password = var.admin_password
  network_rg     = var.network_rg
}
```

---

## 📌 3. Terraform Pipeline Execution – CyberArk Secret Injection

### Objective:
Securely manage secrets using CyberArk and automate infrastructure deployment.

✅ **CI/CD Pipeline Overview**
   - ServiceNow **triggers pipeline execution** upon approval.
   - Terraform Plan runs & outputs changes for **final review** in ServiceNow.
   - Once approved, Terraform **applies changes & provisions VMs**.

✅ **CyberArk Integration for Secrets Management**
   - Retrieve Active Directory credentials dynamically from CyberArk.
   - Inject credentials into Terraform & PowerShell to **avoid hardcoded credentials**.
   - Automatically replace tokens in `tfvars` and scripts before execution.

---

## 📌 4. VM Bootstrapping – UserData Execution

### Objective:
Execute initial system setup at VM boot.

✅ **Terraform Passes UserData to VM**
   - UserData script configures WinRM over HTTPS.
   - Enables logging and system readiness for remote provisioning.

✅ **UserData Execution on First Boot**
   - Ensures VM is in a provision-ready state.
   - Prepares networking, authentication, and logging.

---

## 📌 5. Pre-Configuration Step (Terraform Remote Execution)

### Objective:
Perform initial server configuration tasks remotely.

✅ **Terraform Executes Pre-Config Scripts**
   - **Rename Computer** (`Rename-Computer -NewName $ServerName`).
   - **Join Active Directory Domain**.
   - **Move Server to Appropriate AD Organizational Unit (OU)**.
   - **Configure Auto-Login for Subsequent Steps**.

---

## 📌 6. Post-Configuration – Monitoring & Compliance

### Objective:
Register server with monitoring tools.

✅ **Register System with SolarWinds**
   - Adds the server to monitoring for health checks and performance tracking.

✅ **Register with Other IT Asset Tools**
   - Potential integrations with Axonius, CMDB, etc.

---

## 📌 7. Software Installation – SCCM & Azure Arc

### Objective:
Deploy standard software & agent installations.

✅ **Chocolatey DSC for Base Software**
   - SCCM agent, Azure Arc, and SentinelOne (S1) are installed at deployment.
   - Additional software can be added to DSC script in module.

✅ **Chocolatey DSC for Roles and Features**
   - IIS, .NET, etc...

---

## 📌 8. Ongoing Compliance – SCCM & Azure Arc

### Objective:
Ensure servers remain compliant with security and software updates.

✅ **SCCM & Azure Arc Handle Patch Management**
   - Windows Updates applied via SCCM.
   - Configuration and drift detection handled by Azure Arc.

✅ **Reboots Managed by Compliance Policies**
   - **Choco Packages Mark Pending Reboot Instead of Forcing It**.

---

## 📌 9. Server Decommissioning – Triggered via ServiceNow

### Objective:
Automate server decommissioning & resource cleanup.

✅ **Decommissioning Workflow**
   - Decom request **submitted via ServiceNow**.
   - ServiceNow removes the entry from `server_requests.tfvars`.
   - Server Build Team **reviews & approves**.
   - Terraform **Plan runs** & outputs result back to ServiceNow for review.
   - Server Build Team **approves execution** → **Terraform Apply runs**.
   - **Approved removal triggers Terraform Apply**.
   - **Terraform runs local-exec provisioner to execute `Decom-Server.ps1`**:
     - **Removes AD Object**.
     - **Deregisters from S1**.
     - **Deletes DNS Entries**.
     - **Deregisters from SolarWinds**.

---

## 🔹 Summary of Key Components:

📌 **Packer Golden Image**
   - CIS-hardened, DevOps-compatible, pre-patched Windows Server images.

📌 **ServiceNow Request System**
   - Automated approvals & Terraform execution.

📌 **Terraform with CyberArk**
   - Secure, automated infrastructure provisioning.

📌 **UserData for Initial Configuration**
   - Ensures VMs are bootstrapped for remote provisioning.

📌 **Terraform Remote Execution (Pre-Config)**
   - Joins domain, renames machine, configures Auto-Login.

📌 **Post-Config (Monitoring & Compliance)**
   - Registers with SolarWinds and other monitoring tools.

📌 **Software Management with SCCM & Azure Arc**
   - SCCM for patching, Azure Arc for configuration.

📌 **Automated Decommissioning via ServiceNow**
   - Approved decom requests trigger Terraform cleanup.