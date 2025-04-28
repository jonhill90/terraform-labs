# PowerShell script to clean up resources created in lab 10 of the DP-203 course
# This script drops tables created during the lab and removes uploaded files

param(
    [Parameter(Mandatory=$false)]
    [switch]$KeepTables,
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepFiles,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestConnection,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName
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

# Import environment variables
Import-DotEnv

# Get environment variables for SQL connection
$SqlServer = $env:SQL_SERVER
$SqlDatabase = $env:SQL_DATABASE
$SqlUser = $env:SQL_USER
$SqlPassword = $env:SQL_PASSWORD

# Validate required variables
if (-not $SqlServer -or -not $SqlDatabase -or -not $SqlUser -or -not $SqlPassword) {
    Write-Error "Required environment variables are missing. Please check your .env file."
    Write-Host "Required variables: SQL_SERVER, SQL_DATABASE, SQL_USER, SQL_PASSWORD" -ForegroundColor Yellow
    exit 1
}

# Display connection information
Write-Host "Connecting to: $SqlServer" -ForegroundColor Green
Write-Host "Database: $SqlDatabase" -ForegroundColor Green

# Test database connection if requested
if ($TestConnection) {
    try {
        Write-Host "Testing connection to SQL Server..." -ForegroundColor Cyan
        $query = "SELECT @@VERSION AS SQLVersion;"
        $result = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDatabase -Username $SqlUser -Password $SqlPassword -Query $query -ErrorAction Stop
        Write-Host "Connection successful!" -ForegroundColor Green
        Write-Host "SQL Server version: $($result.SQLVersion)" -ForegroundColor Green
        exit 0
    }
    catch {
        Write-Error "Connection test failed: $_"
        exit 1
    }
}

# Drop tables unless KeepTables is specified
if (-not $KeepTables) {
    Write-Host "Dropping tables created in lab 10..." -ForegroundColor Cyan
    
    $dropTablesQuery = @"
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DimProduct') 
    DROP TABLE [dbo].[DimProduct];
"@
    
    try {
        Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDatabase -Username $SqlUser -Password $SqlPassword -Query $dropTablesQuery -ErrorAction Stop
        Write-Host "Tables and views dropped successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Error dropping tables: $_"
    }
}
else {
    Write-Host "Keeping tables (-KeepTables specified)" -ForegroundColor Yellow
}

# Delete files from Azure Data Lake Storage unless KeepFiles is specified
if (-not $KeepFiles) {
    Write-Host ""
    Write-Host "Removing data files from Azure Data Lake Storage..." -ForegroundColor Cyan
    
    # If storage account name not provided, try to get it from environment variables
    if (-not $StorageAccountName) {
        $StorageAccountName = $env:AZURE_STORAGE_ACCOUNT
        if (-not $StorageAccountName) {
            Write-Host "StorageAccountName parameter or AZURE_STORAGE_ACCOUNT environment variable is required for Azure file removal." -ForegroundColor Yellow
            Write-Host "Skipping Azure file removal." -ForegroundColor Yellow
            return
        }
    }
    
    # Check if Azure CLI is installed
    try {
        $azVersion = az --version
        Write-Host "Azure CLI detected: $($azVersion[0])" -ForegroundColor Green
    }
    catch {
        Write-Error "Azure CLI is required for Azure operations. Please install it and try again."
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
    
    # Remove lab 10 directory from bronze container
    try {
        az storage fs directory delete --account-name $StorageAccountName --file-system bronze --name "dp203/10" --auth-mode login --recursive --yes
        Write-Host "Removed directory: dp203/10" -ForegroundColor Green
    }
    catch {
        Write-Error "Error removing directory: $_"
    }
}
else {
    Write-Host "Keeping Azure Data Lake files (-KeepFiles specified)" -ForegroundColor Yellow
}

# Clear sensitive variables from memory
$SqlPassword = $null
Remove-Variable -Name SqlPassword -Force -ErrorAction SilentlyContinue
[System.GC]::Collect()

# Show help message
Write-Host @"

Uninstall completed! The following operations were performed:
$( if (-not $KeepTables) { "- Dropped tables created in lab 10" } else { "- Kept tables (due to -KeepTables flag)" } )
$( if (-not $KeepFiles) { "- Removed Azure Data Lake files" } else { "- Kept Azure Data Lake files (due to -KeepFiles flag)" } )

"@ -ForegroundColor Cyan