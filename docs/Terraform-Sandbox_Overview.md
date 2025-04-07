## **Overview of Terraform CI/CD Flow**
### **Goal:** 
- Automate infrastructure deployment using **Terraform & Azure DevOps**.
- **Ensure security, control, and approval gates**.
- **CI:** Create Terraform **artifact only**.
- **CD:** Execute Terraform commands (**init, plan, apply**).

---

### **Workspaces in Terraform**
Terraform workspaces allow teams to isolate environments while using the same configuration. Each team has a dedicated workspace that corresponds to a specific infrastructure component.
```
/terraform
│── /apps
│   ├── /appmulti <--- Multi Staged Application Workspace
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── provider.tf
│   │   ├── env/
│   │       ├── dev.tfvars
│   │       ├── test.tfvars
│   │       ├── prod.tfvars
│   ├── /appsingle <--- Single Staged Application Workspace
│       ├── main.tf
│       ├── variables.tf
│       ├── provider.tf
│       ├── env/
│           ├── sandbox.tfvars
│
│── /azure
│   ├── /compute <--- Compute Team Workspace
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── env/
│   │       ├── sandbox.tfvars
│   ├── /database <--- Database Team Workspace
│   ├── /devops <--- DevOps Team Workspace
│   ├── /network <--- Networking Team Workspace
│   ├── /security <--- IAM Team Workspace
│   ├── /storage <--- Storage Team Workspace
│
│── /modules <--- Shared Modules
│   ├── /azurerm
│   ├── /azuread
│   ├── /azure-devops
```
### **How This Works**
- Each **workspace has its own Terraform configuration** under `/azure/` or `/apps/`.
- The **`env/` directory holds environment-specific variables** for `dev`, `test`, `prod`, and `sandbox`.
- Modules in `/modules/` are **reused across workspaces** for consistency.
- The **CI pipeline triggers artifact creation per workspace**, and the **CD pipeline applies Terraform per workspace** based on approvals.

🚀 This structure ensures **isolation, modularity, and scalability**.

---

## **CI Pipeline – Artifact Creation**
### **Trigger:**
- **Runs when a team updates their Terraform workspace**.

### **Steps:**
1. **Checkout Repository** → Fetch latest Terraform code.
2. **Copy Team-Specific Terraform Files** → Ensure only relevant files are included.
3. **Copy Shared Terraform Modules** → Maintain modularity.
4. **Publish Terraform Artifact** → Store in Azure DevOps Artifacts.

### **Key Takeaways:**
✅ **CI does NOT execute Terraform commands**.  
✅ **Creates a Terraform artifact for CD to consume**.  
✅ **Each team has its own workspace**.

---

## **CD Pipeline – Terraform Execution**
### **Trigger:**
- **Runs after artifact is created**.
- **Executes Terraform Plan in the against the plan Environment first**.
- **Sandbox environment requires manual approval before Apply**.

### **Steps:**
1. **Install Terraform** → Ensures latest version is used.
2. **Initialize Backend (`terraform init`)** → Uses Azure Storage for remote state.
3. **Token Replacement (`__SECRET__`)** → Injects Key Vault secrets dynamically.
4. **Terraform Plan (`terraform plan`)** → Runs in the **Plan Environment** to validate infrastructure changes.
5. **Approval Step (if sandbox)** → Requires manual validation before proceeding.
6. **Terraform Apply (`terraform apply`)** → Runs in the **Sandbox Environment after approval**, executing changes based on `tfplan`.
7. **Cleanup** → Removes temporary files after execution.

### **Key Takeaways:**
✅ **Only applies approved changes**.  
✅ **Uses Terraform state stored in Azure Storage**.  
✅ **Secures secrets via Azure Key Vault**.  
✅ **Executes Plan in the Plan Environment before applying in Sandbox**.  
✅ **Sandbox requires manual approval before Terraform Apply**.

---

## **Security & Compliance Best Practices**
- **Secrets are never stored in source control** (Key Vault + Token Replacement).
- **Terraform state is managed remotely in Azure Storage** (prevents corruption & conflicts).
- **Approval gates prevent unintended changes** (sandbox approval step).
- **Dynamic `.tfvars` selection ensures correct environment configuration**.

---

## **Live Demo**
1. **Commit a Terraform Change** → Push an update to a Terraform-Sandbox repo.
2. **CI Runs → Creates Terraform Artifact**.
3. **CD Runs → Plan in Plan Environment → Approval Step (if sandbox)**.
4. **Terraform Apply → Deploys Changes in Sandbox Environment**.
5. **Verify Resources in Azure Portal**.

---

## **Summary & Next Steps**
✅ **CI creates Terraform artifacts only**.  
✅ **CD executes Terraform with approval gates**.  
✅ **Terraform Plan runs in Plan Environment before Apply**.  
✅ **Security is enforced via Key Vault & Azure Storage**.  
✅ **This process is scalable for multiple teams & environments**.

🚀 **Questions? Discussion?**