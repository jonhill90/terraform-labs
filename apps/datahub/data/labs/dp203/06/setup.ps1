# PowerShell script to download required files from GitHub and upload them to Azure Data Lake Storage
# This script is intended for lab 06 of the DP-203 course

param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipAzureCopy,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepFiles,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "https://github.com/MicrosoftLearning/dp-203-azure-data-engineer"
)

# Load environment variables from .env file
function Import-DotEnv {
    param(
        [string]$EnvFile = "$PSScriptRoot/.env"
    )
    
    if (Test-Path $EnvFile) {
        Write-Host "Loading environment variables from $EnvFile" -ForegroundColor Cyan
        $content = Get-Content $EnvFile
        foreach ($line in $content) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            if ($line.StartsWith("#")) { continue }
            
            $keyValue = $line -split "=", 2
            if ($keyValue.Length -eq 2) {
                $key = $keyValue[0].Trim()
                $value = $keyValue[1].Trim()
                # Remove quotes if present
                if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
                
                # Set as environment variable
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
                Write-Host "Loaded $key" -ForegroundColor DarkGray
            }
        }
    }
    else {
        Write-Error "Environment file not found at $EnvFile"
        Write-Host "Please create a .env file by copying .env-template and updating the values" -ForegroundColor Yellow
        exit 1
    }
}

# Function to download files from GitHub
function Download-GitHubFiles {
    param(
        [string]$RepoUrl,
        [string]$Branch = "master",
        [string]$SourcePath = "Allfiles/labs/06",
        [string]$DestinationPath = "$PSScriptRoot/temp",
        [switch]$Force
    )
    
    Write-Host "Downloading required files from GitHub..." -ForegroundColor Cyan
    
    # Create destination directory if it doesn't exist
    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        Write-Host "Created temporary directory: $DestinationPath" -ForegroundColor Green
    } elseif ($Force) {
        # Clean directory if Force is specified
        Remove-Item -Path "$DestinationPath/*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleaned temporary directory: $DestinationPath" -ForegroundColor Yellow
    }
    
    # Create data subdirectory
    $dataDirPath = "$DestinationPath/data"
    if (-not (Test-Path $dataDirPath)) {
        New-Item -Path $dataDirPath -ItemType Directory -Force | Out-Null
    }
    
    # Create notebooks subdirectory
    $notebooksDirPath = "$DestinationPath/notebooks"
    if (-not (Test-Path $notebooksDirPath)) {
        New-Item -Path $notebooksDirPath -ItemType Directory -Force | Out-Null
    }
    
    # Format URLs
    $rawUrl = $RepoUrl.Replace("github.com", "raw.githubusercontent.com")
    if ($rawUrl.EndsWith("/")) {
        $rawUrl = $rawUrl.Substring(0, $rawUrl.Length - 1)
    }
    $baseUrl = "$rawUrl/$Branch/$SourcePath"
    
    # Download CSV files
    $csvFiles = @("2019.csv", "2020.csv", "2021.csv")
    
    foreach ($file in $csvFiles) {
        $url = "$baseUrl/data/$file"
        $destination = "$dataDirPath/$file"
        try {
            Invoke-WebRequest -Uri $url -OutFile $destination
            Write-Host "Downloaded: $file" -ForegroundColor Green
        } catch {
            Write-Error "Failed to download $file : $_"
        }
    }
    
    # Download notebook file
    $notebookFile = "Spark Transform.ipynb"
    $url = "$baseUrl/notebooks/$notebookFile"
    $destination = "$notebooksDirPath/$notebookFile"
    try {
        Invoke-WebRequest -Uri $url -OutFile $destination
        Write-Host "Downloaded: $notebookFile" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download $notebookFile : $_"
    }
    
    Write-Host "File download completed!" -ForegroundColor Green
    return $DestinationPath
}

# Function to clean up downloaded files
function Remove-TempFiles {
    param(
        [string]$TempPath
    )
    
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
    if (Test-Path $TempPath) {
        Remove-Item -Path $TempPath -Recurse -Force
        Write-Host "Removed temporary directory: $TempPath" -ForegroundColor Green
    }
}

# Import environment variables
Import-DotEnv

# Download required files from GitHub
$TempPath = "$PSScriptRoot/temp"
Download-GitHubFiles -RepoUrl $GitHubRepo -DestinationPath $TempPath -Force

# Copy data to Azure Data Lake Storage
if (-not $SkipAzureCopy) {
    Write-Host ""
    Write-Host "Copying data files to Azure Data Lake Storage..." -ForegroundColor Cyan
    
    # If storage account name not provided, try to get it from environment variables
    if (-not $StorageAccountName) {
        $StorageAccountName = $env:AZURE_STORAGE_ACCOUNT
        if (-not $StorageAccountName) {
            Write-Host "StorageAccountName parameter or AZURE_STORAGE_ACCOUNT environment variable is required for Azure copy operation." -ForegroundColor Yellow
            Write-Host "Skipping Azure copy operation." -ForegroundColor Yellow
            return
        }
    }
    
    # Check if Azure CLI is installed
    try {
        $azVersion = az --version
        Write-Host "Azure CLI detected: $($azVersion[0])" -ForegroundColor Green
    }
    catch {
        Write-Error "Azure CLI is required for Azure copy operations. Please install it and try again."
        Write-Host "Installation instructions: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
        return
    }
    
    # Check if logged in to Azure
    try {
        $account = az account show | ConvertFrom-Json
        Write-Host "Logged in to Azure as: $($account.user.name)" -ForegroundColor Green
    }
    catch {
        Write-Error "Not logged in to Azure. Please run 'az login' first."
        return
    }

    # Create directories in the bronze container
    Write-Host "Creating destination directories in the bronze container..." -ForegroundColor Cyan
    
    # Create directory for data files
    try {
        az storage fs directory create --account-name $StorageAccountName --file-system bronze --name "dp203/06/data" --auth-mode login
        Write-Host "Created directory: dp203/06/data" -ForegroundColor Green
    }
    catch {
        Write-Error "Error creating data directory: $_"
        # Continue even if there's an error (directory might already exist)
    }
    
    # Create directory for notebook files
    try {
        az storage fs directory create --account-name $StorageAccountName --file-system bronze --name "dp203/06/notebooks" --auth-mode login
        Write-Host "Created directory: dp203/06/notebooks" -ForegroundColor Green
    }
    catch {
        Write-Error "Error creating notebooks directory: $_"
        # Continue even if there's an error (directory might already exist)
    }
    
    # Upload CSV files
    Write-Host "Uploading CSV files to Azure Data Lake Storage..." -ForegroundColor Cyan
    $csvFiles = @("2019.csv", "2020.csv", "2021.csv")
    
    foreach ($file in $csvFiles) {
        $filePath = "$TempPath/data/$file"
        if (Test-Path $filePath) {
            try {
                az storage fs file upload --account-name $StorageAccountName --file-system bronze --path "dp203/06/data/$file" --source $filePath --auth-mode login
                Write-Host "Uploaded $file to dp203/06/data" -ForegroundColor Green
            }
            catch {
                Write-Error "Error uploading $file $_"
            }
        }
        else {
            Write-Error "CSV file not found at: $filePath"
        }
    }
    
    # Upload notebook file
    Write-Host "Uploading notebook file to Azure Data Lake Storage..." -ForegroundColor Cyan
    $notebookFile = "Spark Transform.ipynb"
    $notebookPath = "$TempPath/notebooks/$notebookFile"
    
    if (Test-Path $notebookPath) {
        try {
            az storage fs file upload --account-name $StorageAccountName --file-system bronze --path "dp203/06/notebooks/$notebookFile" --source $notebookPath --auth-mode login
            Write-Host "Uploaded $notebookFile to dp203/06/notebooks" -ForegroundColor Green
        }
        catch {
            Write-Error "Error uploading $notebookFile $_"
        }
    }
    else {
        Write-Error "Notebook file not found at: $notebookPath"
    }
    
    Write-Host ""
    Write-Host "Azure Data Lake Storage file upload completed!" -ForegroundColor Green
}

# Clean up temporary files unless KeepFiles is specified
if (-not $KeepFiles) {
    Remove-TempFiles -TempPath $TempPath
} else {
    Write-Host "Temporary files kept at: $TempPath" -ForegroundColor Yellow
}

# Help message
function Show-Help {
    Write-Host @"

USAGE:
    .\setup.ps1 [options]

OPTIONS:
    -SkipAzureCopy     : Skip copying files to Azure Data Lake Storage
    -StorageAccountName: Azure Storage Account name for file uploads
    -KeepFiles         : Keep downloaded temporary files after completion
    -GitHubRepo        : URL to the GitHub repository for downloading data files

EXAMPLES:
    .\setup.ps1                                      : Run the full data load process
    .\setup.ps1 -SkipAzureCopy                       : Skip Azure storage upload
    .\setup.ps1 -StorageAccountName "mystorageacct"  : Specify Azure Storage Account name
    .\setup.ps1 -KeepFiles                           : Keep downloaded files for troubleshooting
    .\setup.ps1 -GitHubRepo "https://github.com/other/repo" : Use a different repository source

ENVIRONMENT VARIABLES:
    AZURE_STORAGE_ACCOUNT: Azure Storage Account name (alternative to -StorageAccountName)

"@ -ForegroundColor Cyan
}

# Show help if no arguments
if ($MyInvocation.BoundParameters.Count -eq 0 -and $args.Count -eq 0) {
    Show-Help
}