## **Terraform Sandbox**
---
### Documentation:
- [🧭 Architecture Overview](https://github.com/jonhill90/terraform-labs/blob/main/docs/Architecture%20Overview.md)
- [🏖️ Terraform-Sandbox Overview](https://github.com/jonhill90/terraform-labs/blob/main/docs/Terraform-Sandbox%20Overview.md)
- [🧰 VS Code Workflow Setup](https://github.com/jonhill90/terraform-labs/blob/main/docs/VS%20Code%20Workflow%20Setup.md)
- [🚀 Future-Proofing Infrastructure for AI with Azure + Terraform](https://github.com/jonhill90/terraform-labs/blob/main/docs/Furure-Proofing%20Infrastructure%20for%20AI%20with%20Azure%20%2B%20Terraform.md)
- [🧠 AI Ops System](https://github.com/jonhill90/terraform-labs/blob/main/docs/AI%20Ops.md)
- [🌐 Networking Landing Zone Best Practice](https://github.com/jonhill90/terraform-labs/blob/main/docs/Azure%20Landing%20Zone%20Networking%20with%20Terraform.md)
- [🖥 Server Build](https://github.com/jonhill90/terraform-labs/blob/main/azure-lab/server-build/README.md)
- [📦 Packer Image Bakery](https://github.com/jonhill90/terraform-labs/blob/main/azure-lab/image-bakery/README.md)
---
### Infrastructure Pipelines:
| Team | Plan | Apply |
|---|:-----:|:-----:|
| 🖥️ Compute | [![Build Status](https://dev.azure.com/ImpressiveIT/Compute/_apis/build/status%2FCompute-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Compute/_build/latest?definitionId=57&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Compute/_apis/build/status%2FCompute-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Compute/_build/latest?definitionId=57&branchName=main) |
| 🌐 Networking | [![Build Status](https://dev.azure.com/ImpressiveIT/Networking/_apis/build/status%2FNetworking-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Networking/_build/latest?definitionId=55&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Networking/_apis/build/status%2FNetworking-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Networking/_build/latest?definitionId=55&branchName=main) |
| 🛢 Database | [![Build Status](https://dev.azure.com/ImpressiveIT/Database/_apis/build/status%2FDatabase-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Database/_build/latest?definitionId=59&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Database/_apis/build/status%2FDatabase-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Database/_build/latest?definitionId=59&branchName=main) |
| 🔑 Security | [![Build Status](https://dev.azure.com/ImpressiveIT/Security/_apis/build/status%2FSecurity-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Security/_build/latest?definitionId=51&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Security/_apis/build/status%2FSecurity-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Security/_build/latest?definitionId=51&branchName=main) |
| 🗄️ Storage | [![Build Status](https://dev.azure.com/ImpressiveIT/Storage/_apis/build/status%2FStorage-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Storage/_build/latest?definitionId=61&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Storage/_apis/build/status%2FStorage-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Storage/_build/latest?definitionId=61&branchName=main) |
| 🔨 DevOps | [![Build Status](https://dev.azure.com/ImpressiveIT/DevOps/_apis/build/status%2FDevOps-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/DevOps/_build/latest?definitionId=53&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/DevOps/_apis/build/status%2FDevOps-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/DevOps/_build/latest?definitionId=53&branchName=main) |
| 🖨️ Printing | In Progress | In Progress |
---
### Image Bakery Pipelines:
| OS | Validate | Build |
|---|:-----:|:-----:|
| Windows Server 2025 Base | [![Build Status](https://dev.azure.com/ImpressiveIT/Compute/_apis/build/status%2Fwindows-2025-base-cd?branchName=main&stageName=Packer%20Validate%20-%20Development&jobName=Packer%20Init%20%26%20Validate%20-%20Development)](https://dev.azure.com/ImpressiveIT/Compute/_build/latest?definitionId=41&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Compute/_apis/build/status%2Fwindows-2025-base-cd?branchName=main&stageName=Packer%20Build%20-%20Development&jobName=Packer%20Build%20-%20Development)](https://dev.azure.com/ImpressiveIT/Compute/_build/latest?definitionId=41&branchName=main) |
| Windows Server 2025 Core | [![Build Status](https://dev.azure.com/ImpressiveIT/Compute/_apis/build/status%2Fwindows-2025-core-cd?branchName=main&stageName=Packer%20Validate%20-%20Development&jobName=Packer%20Init%20%26%20Validate%20-%20Development)](https://dev.azure.com/ImpressiveIT/Compute/_build/latest?definitionId=43&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Compute/_apis/build/status%2Fwindows-2025-core-cd?branchName=main&stageName=Packer%20Build%20-%20Development&jobName=Packer%20Build%20-%20Development)](https://dev.azure.com/ImpressiveIT/Compute/_build/latest?definitionId=43&branchName=main) |
---
### Server Build Pipeline:
|  | Validate | Build |
|---|:-----:|:-----:|
| 🔧 Server Build | In Progress | In Progress |

### Staged Server Build Pipeline:
|  | Dev | Test | Prod |
|---|:-----:|:-----:|:-----:|
| 🔧 Server Build | In Progress | In Progress | In Progress |
---
### Application Pipelines:
| Team | Plan | Apply |
|---|:-----:|:-----:|
| AppSingle | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FAppSingle-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=63&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FAppSingle-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=63&branchName=main) |
| Twingate | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FTwingate-CD?branchName=main&stageName=Terraform%20Plan%20-%20Development&jobName=Terraform%20Init%20%26%20Plan%20-%20Development)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=45&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FTwingate-CD?branchName=main&stageName=Terraform%20Plan%20-%20Development&jobName=Terraform%20Apply%20-%20Development)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=45&branchName=main) |
| blackglass | In Progress | In Progress |

### Staged Application Pipelines:
| Application | Dev | Test | Prod |
|---|:-----:|:-----:|:-----:|
| AppMulti | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FAppMulti-CD?branchName=main&stageName=Terraform%20Plan%20-%20Development&jobName=Terraform%20Apply%20-%20Development)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=37&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FAppMulti-CD?branchName=main&stageName=Terraform%20Plan%20-%20Test%20Environment&jobName=Terraform%20Apply%20-%20Test%20Environment)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=37&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FAppMulti-CD?branchName=main&stageName=Terraform%20Plan%20-%20Production%20Environment&jobName=Terraform%20Apply%20-%20Production%20Environment)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=37&branchName=main) |

---