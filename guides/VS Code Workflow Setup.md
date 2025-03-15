# VS Code Workflow Setup for Terraform

## Prerequisites
Ensure you have administrative privileges before proceeding.

## Step 1: Install Chocolatey
Open **Command Prompt** as Administrator and run the following command:

```cmd
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
```

## Step 2: Open PowerShell as Administrator
Once Chocolatey is installed, open **PowerShell** as Administrator.

## Step 3: Install Required Applications
Run the following command to install the required applications using Chocolatey:

```powershell
choco install vscode git azure-cli terraform -y
```

### Installed Applications:
- **Visual Studio Code** (`vscode`)
- **Git for Windows** (`git`)
- **Azure CLI** (`azure-cli`)
- **Terraform** (`terraform`)

## Step 4: Setup a Basic VS Code Workspace
To keep your projects organized, create a **workspaces** folder in your Documents directory:

```powershell
mkdir "$env:USERPROFILE\Documents\workspaces"
```

Alternatively, you can save your workspaces in the root of your user folder if you prefer.

### Creating a Workspace in VS Code
1. Open **VS Code**.
2. Go to **File > Save Workspace As...**.
3. Navigate to `Documents\workspaces` and save your workspace there.
4. Add folders to the workspace using **File > Add Folder to Workspace...**.

## Step 5: Create a Directory for Repositories
To keep your repositories organized, create a directory for storing them. A common location is `C:\source\repos`.

Run the following command to create it:

```powershell
mkdir C:\source\repos
```

This directory will serve as a central place to clone and manage all your Git repositories.

## Step 6: Configure Git Username and Email
To ensure your Git commits are properly attributed, configure your Git username and email:

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

To verify your settings, run:

```powershell
git config --global --list
```

This will display your configured Git username and email.

## Step 7: Install the "HashiCorp Terraform" Extension
To install the Terraform extension in VS Code:
1. Open **VS Code**.
2. Press `Ctrl+Shift+X` to open the Extensions panel.
3. Search for **HashiCorp Terraform**.
4. Click **Install**.

## Step 8: Clone a Repository from Azure DevOps in VS Code
To clone a repository from **Azure DevOps** into **VS Code**, follow these steps:

### 1. Open Azure DevOps and Navigate to Your Repository
- Go to **Azure DevOps** and open the **Repos** section.
- Select the repository you want to clone.
- Click the **Clone** button in the upper-right corner.

### 2. Clone Using VS Code
- In the **Clone Repository** window, select the **HTTPS** tab.
- Copy the repository URL or choose **Clone in VS Code** under the **IDE** section.
- If prompted, allow VS Code to open.

### 3. Choose a Local Folder for Your Repository
- When VS Code opens, it will ask where to save the cloned repository.
- Navigate to `C:\source\repos` (or your preferred directory) and select it.
- Click **Select Repository Location** to start cloning.

### 4. Open the Cloned Repository in VS Code
- Once the cloning process finishes, VS Code will ask if you want to open the repository.
- Click **Open** to start working with your files.

### Alternative: Clone via Command Line
If you prefer using the terminal, you can clone the repository manually by running:

```powershell
git clone https://dev.azure.com/your-organization/your-repo-name.git C:\source\repos\your-repo
```

## Step 9: Managing Workspaces in VS Code
When working with VS Code, make sure your workspace is open before opening individual files. If you open a file before opening your workspace, VS Code will launch in an empty workspace and set the default workspace to the empty session.

To avoid this:
- Always open **VS Code first**, then open your workspace from **File > Open Workspace...**.
- If a file opens in an empty workspace, manually switch back to your correct workspace.

## Step 10: Verify Installations
After installation, verify each application:

```powershell
code --version  # Check VS Code version
git --version   # Check Git version
az --version    # Check Azure CLI version
terraform -version  # Check Terraform version
```

## Notes
- Ensure that Chocolatey is added to the system `PATH` environment variable.
- Restart your PowerShell or Command Prompt session if the commands are not recognized.

---
Happy Coding! 🚀