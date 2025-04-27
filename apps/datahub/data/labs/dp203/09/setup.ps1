# PowerShell script to create tables in SQL Server for lab 09 of the DP-203 course
# This script connects to the SQL Server defined in .env file, downloads necessary files from GitHub,
# creates tables in SQL Server, and uploads CSV files to Azure Data Lake Storage.

param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipCreateTables,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListTables,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestConnection,
    
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
        [string]$SourcePath = "Allfiles/labs/09",
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
    
    # Create subdirectories
    $dataDirPath = "$DestinationPath/data"
    
    if (-not (Test-Path $dataDirPath)) {
        New-Item -Path $dataDirPath -ItemType Directory -Force | Out-Null
    }
    
    # Format URLs
    $rawUrl = $RepoUrl.Replace("github.com", "raw.githubusercontent.com")
    if ($rawUrl.EndsWith("/")) {
        $rawUrl = $rawUrl.Substring(0, $rawUrl.Length - 1)
    }
    $baseUrl = "$rawUrl/$Branch/$SourcePath"
    
    # Download setup.sql
    $setupSqlUrl = "$baseUrl/setup.sql"
    $setupSqlDestination = "$PSScriptRoot/setup.sql"
    try {
        Invoke-WebRequest -Uri $setupSqlUrl -OutFile $setupSqlDestination
        Write-Host "Downloaded: setup.sql" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download setup.sql : $_"
    }
    
    # Download CSV files
    $csvFiles = @(
        "Customer.csv", "Product.csv"
    )
    
    foreach ($file in $csvFiles) {
        $url = "$baseUrl/data/$file"
        $destination = "$dataDirPath/$file"
        try {
            Invoke-WebRequest -Uri $url -OutFile $destination
            Write-Host "Downloaded: $file" -ForegroundColor Green
        } catch {
            Write-Error "Failed to download $file : $_"
            # Try lowercase version
            $lowerFile = $file.ToLower()
            $url = "$baseUrl/data/$lowerFile"
            try {
                Invoke-WebRequest -Uri $url -OutFile $destination
                Write-Host "Downloaded: $file (lowercase variant)" -ForegroundColor Green
            } catch {
                # Try first letter uppercase
                $firstUpper = $file.Substring(0,1).ToUpper() + $file.Substring(1).ToLower()
                $url = "$baseUrl/data/$firstUpper"
                try {
                    Invoke-WebRequest -Uri $url -OutFile $destination
                    Write-Host "Downloaded: $file (first uppercase variant)" -ForegroundColor Green
                } catch {
                    Write-Error "Failed to download $file with any case variation"
                }
            }
        }
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

# Get environment variables for SQL connection
$SqlServer = $env:SQL_SERVER
$SqlDatabase = $env:SQL_DATABASE
$SqlUser = $env:SQL_USER
$SqlPassword = $env:SQL_PASSWORD

# Download required files from GitHub
$TempPath = "$PSScriptRoot/temp"
Download-GitHubFiles -RepoUrl $GitHubRepo -DestinationPath $TempPath -Force

# Set path to the downloaded data files
$DataPath = "$TempPath/data"

# Validate required variables
if (-not $SqlServer -or -not $SqlDatabase -or -not $SqlUser -or -not $SqlPassword) {
    Write-Error "Required environment variables are missing. Please check your .env file."
    Write-Host "Required variables: SQL_SERVER, SQL_DATABASE, SQL_USER, SQL_PASSWORD" -ForegroundColor Yellow
    exit 1
}

# Display connection information
Write-Host "Connecting to: $SqlServer" -ForegroundColor Green
Write-Host "Database: $SqlDatabase" -ForegroundColor Green
Write-Host "Using data files from: $DataPath" -ForegroundColor Green

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

# Get available tables from setup.sql
if ($ListTables) {
    Write-Host "Available tables to create:" -ForegroundColor Cyan
    $SetupSqlPath = "$PSScriptRoot/setup.sql"
    if (Test-Path $SetupSqlPath) {
        $sqlContent = Get-Content -Path $SetupSqlPath -Raw
        $tableMatches = [regex]::Matches($sqlContent, "CREATE TABLE \[dbo\]\.\[([^\]]+)\]")
        $viewMatches = [regex]::Matches($sqlContent, "CREATE VIEW \[dbo\]\.\[([^\]]+)\]")
        
        foreach ($match in $tableMatches) {
            $tableName = $match.Groups[1].Value
            Write-Host "  - $tableName (Table)" -ForegroundColor Yellow
        }
        
        foreach ($match in $viewMatches) {
            $viewName = $match.Groups[1].Value
            Write-Host "  - $viewName (View)" -ForegroundColor Green
        }
    }
    exit 0
}

# Create database tables if requested
if (-not $SkipCreateTables) {
    Write-Host "Creating database tables..." -ForegroundColor Cyan
    $SetupSqlPath = "$PSScriptRoot/setup.sql"
    if (Test-Path $SetupSqlPath) {
        try {
            Write-Host "Executing SQL setup script from $SetupSqlPath" -ForegroundColor Cyan
            
            # Read the SQL script
            $sqlContent = Get-Content -Path $SetupSqlPath -Raw
            
            # Split by GO statements
            $sqlBatches = $sqlContent -split '\r?\nGO\r?\n'
            
            # Execute each batch separately
            foreach ($batch in $sqlBatches) {
                if (![string]::IsNullOrWhiteSpace($batch)) {
                    try {
                        Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDatabase -Username $SqlUser -Password $SqlPassword -Query $batch -QueryTimeout 360 -ErrorAction Stop
                    }
                    catch {
                        Write-Error "Error executing SQL batch: $_"
                    }
                }
            }
            
            Write-Host "SQL setup script executed successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Error processing SQL setup script: $_"
            Write-Host "Make sure you have the SqlServer module installed. If not, run: Install-Module -Name SqlServer -Force" -ForegroundColor Yellow
            exit 1
        }
    }
    else {
        Write-Error "SQL setup script not found at: $SetupSqlPath"
        exit 1
    }
}
else {
    Write-Host "Skipping database table creation (-SkipCreateTables specified)" -ForegroundColor Yellow
}

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

    # Create directory in the bronze container
    Write-Host "Creating destination directory in the bronze container..." -ForegroundColor Cyan
    
    # Create dp203/09/data directory
    try {
        az storage fs directory create --account-name $StorageAccountName --file-system bronze --name "dp203/09/data" --auth-mode login
        Write-Host "Created directory: dp203/09/data" -ForegroundColor Green
    }
    catch {
        Write-Error "Error creating data directory: $_"
        # Continue even if there's an error (directory might already exist)
    }
    
    # Upload CSV files
    Write-Host "Uploading CSV files to Azure Data Lake Storage..." -ForegroundColor Cyan
    
    $csvFiles = Get-ChildItem "$DataPath/*.csv" -File
    if ($csvFiles.Count -eq 0) {
        Write-Error "No .csv files found in $DataPath"
    }
    else {
        $totalFiles = $csvFiles.Count
        $processedFiles = 0
        $successFiles = 0
        $failedFiles = 0
        
        foreach ($file in $csvFiles) {
            $processedFiles++
            $filePath = $file.FullName
            $fileName = $file.Name
            
            try {
                az storage fs file upload --account-name $StorageAccountName --file-system bronze --path "dp203/09/data/$fileName" --source $filePath --auth-mode login
                Write-Host "Uploaded $fileName to dp203/09/data" -ForegroundColor Green
                $successFiles++
            }
            catch {
                Write-Error "Error uploading $fileName $_"
                $failedFiles++
            }
        }
        
        Write-Host ""
        Write-Host "Azure Data Lake Storage file upload completed!" -ForegroundColor Green
        Write-Host "Results: $successFiles successful, $failedFiles failed, $processedFiles total files processed" -ForegroundColor Cyan
    }
}

# Clear sensitive variables from memory
$SqlPassword = $null
Remove-Variable -Name SqlPassword -Force -ErrorAction SilentlyContinue
[System.GC]::Collect()

# Help message
function Show-Help {
    Write-Host @"

USAGE:
    .\setup.ps1 [options]

OPTIONS:
    -TestConnection    : Test the database connection and exit
    -SkipCreateTables  : Skip the database table creation step
    -ListTables        : List available tables and exit
    -SkipAzureCopy     : Skip copying files to Azure Data Lake Storage
    -StorageAccountName: Azure Storage Account name for file uploads
    -KeepFiles         : Keep downloaded temporary files after completion
    -GitHubRepo        : URL to the GitHub repository for downloading data files

EXAMPLES:
    .\setup.ps1                                      : Run the full setup process
    .\setup.ps1 -TestConnection                      : Test the SQL connection only
    .\setup.ps1 -ListTables                          : List all available tables
    .\setup.ps1 -SkipCreateTables                    : Skip table creation, just upload CSV files
    .\setup.ps1 -SkipAzureCopy                       : Skip Azure storage upload
    .\setup.ps1 -StorageAccountName "mystorageacct"  : Specify Azure Storage Account name
    .\setup.ps1 -KeepFiles                           : Keep downloaded files for troubleshooting
    .\setup.ps1 -GitHubRepo "https://github.com/other/repo" : Use a different repository source

ENVIRONMENT VARIABLES:
    SQL_SERVER         : SQL Server name
    SQL_DATABASE       : SQL Database name
    SQL_USER           : SQL Server username
    SQL_PASSWORD       : SQL Server password
    AZURE_STORAGE_ACCOUNT: Azure Storage Account name (alternative to -StorageAccountName)

"@ -ForegroundColor Cyan
}

# Clean up temporary files unless KeepFiles is specified
if (-not $KeepFiles) {
    Remove-TempFiles -TempPath $TempPath
} else {
    Write-Host "Temporary files kept at: $TempPath" -ForegroundColor Yellow
}

# Show help if no arguments and nothing was done
if ($MyInvocation.BoundParameters.Count -eq 0 -and $args.Count -eq 0) {
    Show-Help
}