# 🏗️ Packer CI/CD Pipeline for Windows 2025 Base Image

## 📌 Overview

This project automates the creation of a **Windows Server 2025 golden image** using **Packer** and **Azure DevOps Pipelines**. The pipeline is broken into CI and CD stages for modularity, control, and scalability.

- ✅ CI: Creates and publishes Packer artifacts (no builds)
- ✅ CD: Validates and builds the image using Azure credentials and publishes to a **Shared Image Gallery**

---

## 🚧 Folder Structure

```
/azure
│── /image-bakery
│   ├── /windows
│   │   ├── win2025-base.pkr.hcl                # Main Packer template
│   │   ├── windows-2025-base.pkrvars.hcl       # Tokenized variables file
│   │   ├── scripts/
│   │       ├── sysprep.ps1                     # Windows generalization script
│   │       ├── install-choco.ps1               # Example: Additional install script
│   │       ├── apply-dsc.ps1                   # Example: DSC configuration entry point
│
│── /templates
│   ├── template-packer-ci.yml                  # Shared CI template
│   ├── template-packer-validate.yml            # Validation logic
│   ├── template-packer-cd.yml                  # Build logic
```

---

## ⚙️ How It Works

### 🧱 Packer Template (`win2025-base.pkr.hcl`)
- Builds a **Windows Server 2025 image** in Azure
- Injects secrets (like client ID, secret) via pipeline token replacement
- Runs `sysprep.ps1` to generalize the image
- Publishes the result to a **Shared Image Gallery**

### 🔐 Variable Token Replacement (`*.pkrvars.hcl`)
Secrets and environment-specific values are written like this:

```hcl
subscription_id = "__subscriptionid__"
client_id       = "__clientid__"
client_secret   = "__clientsecret__"
```

These tokens are replaced automatically by the CD pipeline using `replacetokens@6`.

---

## 🚀 CI Pipeline – Artifact Creation

### 📄 File: `windows-2025-base-ci.yml`

Triggered when:
- Code is pushed to `master`
- `win2025-base.pkr.hcl` is modified

### 💠 CI Steps
1. **Checkout repository**
2. **Copy relevant Packer files**
3. **Publish build artifact** (e.g., `windows-2025-base-artifacts`)

🧐 CI **does not run packer**, just prepares files.

---

## 🥪 CD Pipeline – Validate & Build Image

### 📄 File: `windows-2025-base-cd.yml`

Triggered after CI completes.

### 💡 Stages

#### ✅ 1. Validate (via `template-packer-validate.yml`)
- Installs Packer
- Replaces tokens in variables file
- Runs `packer init` and `packer validate`
- Ensures the config is safe before build

#### 🏐 2. Build (via `template-packer-cd.yml`)
- Replaces tokens again
- Runs `packer init`, `validate`, and `build`
- Executes `sysprep.ps1` inside the image
- Publishes image to Shared Image Gallery (SIG)

---

## 🏪 Adding More Provisioners

You can easily expand the image building process by including additional PowerShell or DSC (Desired State Configuration) scripts using the `provisioner` block in the Packer template.

### 💪 PowerShell Scripts
You can run multiple PowerShell scripts sequentially:

```hcl
provisioner "powershell" {
  script = "./scripts/install-choco.ps1"
}

provisioner "powershell" {
  script = "./scripts/sysprep.ps1"
}
```

### 🏰 DSC Scripts
You can also apply DSC configurations during image creation:

```hcl
provisioner "powershell" {
  inline = [
    "Start-DscConfiguration -Path C:\\configs -Wait -Force -Verbose"
  ]
}
```

> Ensure all DSC modules and resources are present or install them in a prior step. DSC is powerful for enforcing configuration consistency across your environment.

This approach enables full automation of any Windows image customization.

---

## 🔐 Security Best Practices

- ❌ No secrets in source control
- ✅ Secrets injected at runtime with token replacement
- ✅ State and builds are validated before execution
- ✅ Uses Azure Key Vault & variable groups securely

---

## 🧪 Live Demo Flow

1. Modify `win2025-base.pkr.hcl`
2. Push to `master` → CI publishes artifacts
3. CD runs validation → build
4. Image lands in Shared Image Gallery
5. Use the image for VMSS, AKS nodes, etc.

---

## ✅ Summary

| Stage | Action |
|-------|--------|
| CI | Packages and publishes Packer artifacts |
| CD (Validate) | Validates template syntax and secrets |
| CD (Build) | Builds sysprepped image and publishes to Shared Image Gallery |

- 🔄 Modular and reusable for other images
- 🔐 Secrets handled securely
- 🚀 Ready for enterprise image pipelines