## **Terraform Sandbox**
---
### Documentation:
- [🧭 Architecture Overview](docs/Architecture_Overview.md)
- [🏖️ Terraform-Sandbox Overview](docs/Terraform-Sandbox_Overview.md)
- [🧰 VS Code Workflow Setup](docs/VS_Code_Workflow_Setup.md)
- [🚀 Future-Proofing Infrastructure for AI with Azure + Terraform](docs/Furure-Proofing_Infrastructure_for_AI_with_Azure_+_Terraform.md)
- [🧠 AI Ops System](docs/AI_Ops.md)
- [🔄 Shared Memory Framework](docs/Shared_Memory_Framework.md)
- [🌐 Networking](docs/Azure_Landing_Zone_Networking_with_Terraform.md)
- [🖥 Server Build](/azure/server-build/README.md)
- [📦 Packer Image Bakery](/azure/image-bakery/README.md)
- [🖨️ Universal Print](azure/print/README.md)
- [🌎 Terraform MCP Workflow](docs/Terraform_MCP_Workflow.md)
---
### Platform Pipelines:
| Team | Plan | Apply |
|---|:-----:|:-----:|
| 🖥️ Compute | [![Build Status](https://dev.azure.com/ImpressiveIT/Compute/_apis/build/status%2FCompute-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Compute/_build/latest?definitionId=57&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Compute/_apis/build/status%2FCompute-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Compute/_build/latest?definitionId=57&branchName=main) |
| 🌐 Networking | [![Build Status](https://dev.azure.com/ImpressiveIT/Networking/_apis/build/status%2FNetworking-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Networking/_build/latest?definitionId=55&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Networking/_apis/build/status%2FNetworking-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Networking/_build/latest?definitionId=55&branchName=main) |
| 🛢 Database | [![Build Status](https://dev.azure.com/ImpressiveIT/Database/_apis/build/status%2FDatabase-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Database/_build/latest?definitionId=59&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Database/_apis/build/status%2FDatabase-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Database/_build/latest?definitionId=59&branchName=main) |
| 🔑 Security | [![Build Status](https://dev.azure.com/ImpressiveIT/Security/_apis/build/status%2FSecurity-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Security/_build/latest?definitionId=51&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Security/_apis/build/status%2FSecurity-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Security/_build/latest?definitionId=51&branchName=main) |
| 🗄️ Storage | [![Build Status](https://dev.azure.com/ImpressiveIT/Storage/_apis/build/status%2FStorage-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Storage/_build/latest?definitionId=61&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Storage/_apis/build/status%2FStorage-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Storage/_build/latest?definitionId=61&branchName=main) |
| 🔨 DevOps | [![Build Status](https://dev.azure.com/ImpressiveIT/DevOps/_apis/build/status%2FDevOps-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/DevOps/_build/latest?definitionId=53&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/DevOps/_apis/build/status%2FDevOps-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/DevOps/_build/latest?definitionId=53&branchName=main) |
| 🖨️ Printing | In Progress | In Progress |
| 🏭 Data Factory | In Progress | In Progress |
| 🧱 Databricks | In Progress | In Progress |
| 🧵 Fabric | In Progress | In Progress |
| 🧠 Synapse | In Progress | In Progress |
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
| Twingate | [![Build Status](https://dev.azure.com/ImpressiveIT/Networking/_apis/build/status%2FTwingate-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Networking/_build/latest?definitionId=73&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Networking/_apis/build/status%2FTwingate-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/Networking/_build/latest?definitionId=73&branchName=main) |
| DataHub | [![Build Status](https://dev.azure.com/ImpressiveIT/DataHub/_apis/build/status%2FDataHub-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/DataHub/_build/latest?definitionId=75&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/DataHub/_apis/build/status%2FDataHub-CD?branchName=main)](https://dev.azure.com/ImpressiveIT/DataHub/_build/latest?definitionId=75&branchName=main) |
| MDP-ADF | In Progress | In Progress |
| MDP-Fabric | In Progress | In Progress |

### Staged Application Pipelines:
| Application | Dev | Test | Prod |
|---|:-----:|:-----:|:-----:|
| AppMulti | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FAppMulti-CD?branchName=main&stageName=Terraform%20Plan%20-%20Development&jobName=Terraform%20Apply%20-%20Development)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=37&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FAppMulti-CD?branchName=main&stageName=Terraform%20Plan%20-%20Test%20Environment&jobName=Terraform%20Apply%20-%20Test%20Environment)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=37&branchName=main) | [![Build Status](https://dev.azure.com/ImpressiveIT/Applications/_apis/build/status%2FAppMulti-CD?branchName=main&stageName=Terraform%20Plan%20-%20Production%20Environment&jobName=Terraform%20Apply%20-%20Production%20Environment)](https://dev.azure.com/ImpressiveIT/Applications/_build/latest?definitionId=37&branchName=main) |

---