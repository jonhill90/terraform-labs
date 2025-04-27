# PowerShell script to load data into SQL Server and copy data to Azure Data Lake Storage
# This script connects to the SQL Server defined in .env file, downloads necessary files from GitHub,
# loads data into SQL Server, and uploads files to Azure Data Lake Storage.

param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipCreateTables,
    
    [Parameter(Mandatory=$false)]
    [string]$SingleTable,
    
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
        [string]$SourcePath = "Allfiles/labs/01",
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
    $filesDirPath = "$DestinationPath/files"
    $adventureworksDirPath = "$DestinationPath/adventureworks"
    
    if (-not (Test-Path $dataDirPath)) {
        New-Item -Path $dataDirPath -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path $filesDirPath)) {
        New-Item -Path $filesDirPath -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path $adventureworksDirPath)) {
        New-Item -Path $adventureworksDirPath -ItemType Directory -Force | Out-Null
    }
    
    # Format URLs
    $rawUrl = $RepoUrl.Replace("github.com", "raw.githubusercontent.com")
    if ($rawUrl.EndsWith("/")) {
        $rawUrl = $rawUrl.Substring(0, $rawUrl.Length - 1)
    }
    $baseUrl = "$rawUrl/$Branch/$SourcePath"
    
    # Download data files (.txt and .fmt files)
    $dataFiles = @(
        "DimCurrency.fmt", "DimCurrency.txt",
        "DimCustomer.fmt", "DimCustomer.txt",
        "DimDate.fmt", "DimDate.txt",
        "DimGeography.fmt", "DimGeography.txt",
        "DimProduct.fmt", "DimProduct.txt",
        "DimProductCategory.fmt", "DimProductCategory.txt",
        "DimProductSubcategory.fmt", "DimProductSubcategory.txt",
        "DimPromotion.fmt", "DimPromotion.txt",
        "DimSalesTerritory.fmt", "DimSalesTerritory.txt",
        "FactInternetSales.fmt", "FactInternetSales.txt"
    )
    
    foreach ($file in $dataFiles) {
        $url = "$baseUrl/data/$file"
        $destination = "$dataDirPath/$file"
        try {
            Invoke-WebRequest -Uri $url -OutFile $destination
            Write-Host "Downloaded: $file" -ForegroundColor Green
        } catch {
            Write-Error "Failed to download $file : $_"
        }
    }
    
    # Download files from /files directory
    $url = "$baseUrl/files/sales.csv"
    $destination = "$filesDirPath/sales.csv" 
    try {
        Invoke-WebRequest -Uri $url -OutFile $destination
        Write-Host "Downloaded: sales.csv" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download sales.csv: $_"
    }
    
    $url = "$baseUrl/files/ingest-data.kql"
    $destination = "$filesDirPath/ingest-data.kql"
    try {
        Invoke-WebRequest -Uri $url -OutFile $destination
        Write-Host "Downloaded: ingest-data.kql" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download ingest-data.kql: $_"
    }
    
    # Download adventureworks files
    $url = "$baseUrl/adventureworks/products.csv"
    $destination = "$adventureworksDirPath/products.csv"
    try {
        Invoke-WebRequest -Uri $url -OutFile $destination
        Write-Host "Downloaded: products.csv" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download products.csv: $_"
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

# Get available tables from data files
$dataFiles = Get-ChildItem "$DataPath/*.txt" -File
$availableTables = $dataFiles | ForEach-Object { $_.Name.Replace(".txt","") }

# List tables if requested
if ($ListTables) {
    Write-Host "Available tables to load:" -ForegroundColor Cyan
    foreach ($table in $availableTables) {
        Write-Host "  - $table" -ForegroundColor Yellow
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
            Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDatabase -Username $SqlUser -Password $SqlPassword -InputFile $SetupSqlPath -QueryTimeout 360 -ErrorAction Stop
            Write-Host "SQL setup script executed successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Error executing SQL setup script: $_"
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

# Load data
Write-Host "Loading data files..." -ForegroundColor Cyan

# Filter files if a single table is specified
if ($SingleTable) {
    $previousDataFiles = $dataFiles
    $dataFiles = $dataFiles | Where-Object { $_.Name -eq "$SingleTable.txt" }
    
    if ($dataFiles.Count -eq 0) {
        Write-Error "Table '$SingleTable' not found. Available tables: $($availableTables -join ', ')"
        exit 1
    }
    
    Write-Host "Filtered to load only table: $SingleTable" -ForegroundColor Yellow
}

if ($dataFiles.Count -eq 0) {
    Write-Error "No .txt data files found in $DataPath"
    exit 1
}

$totalFiles = $dataFiles.Count
$processedFiles = 0
$successFiles = 0
$failedFiles = 0

foreach ($file in $dataFiles) {
    $processedFiles++
    $fileName = $file.Name
    $filePath = $file.FullName
    $table = $fileName.Replace(".txt","")
    $formatFile = $filePath.Replace("txt", "fmt")
    
    Write-Host ""
    Write-Host "[$processedFiles/$totalFiles] Loading $fileName into dbo.$table" -ForegroundColor Cyan
    
    if (-not (Test-Path $formatFile)) {
        Write-Error "Format file not found: $formatFile"
        $failedFiles++
        continue
    }
    
    try {
        # Using BCP utility to bulk load data
        $bcpStartTime = Get-Date
        bcp dbo.$table in $filePath -S $SqlServer -U $SqlUser -P $SqlPassword -d $SqlDatabase -f $formatFile -q -k -E -b 5000
        $bcpEndTime = Get-Date
        $duration = ($bcpEndTime - $bcpStartTime).TotalSeconds
        
        Write-Host "Successfully loaded data into dbo.$table (Took $duration seconds)" -ForegroundColor Green
        $successFiles++
    }
    catch {
        Write-Error "Error loading data into dbo.$table $_"
        $failedFiles++
    }
}

Write-Host ""
Write-Host "Data loading process completed!" -ForegroundColor Green
Write-Host "Results: $successFiles successful, $failedFiles failed, $processedFiles total files processed" -ForegroundColor Cyan

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
    -SingleTable name  : Load only the specified table
    -ListTables        : List available tables and exit
    -SkipAzureCopy     : Skip copying files to Azure Data Lake Storage
    -StorageAccountName: Azure Storage Account name for file uploads
    -KeepFiles         : Keep downloaded temporary files after completion
    -GitHubRepo        : URL to the GitHub repository for downloading data files

EXAMPLES:
    .\setup.ps1                                      : Run the full data load process
    .\setup.ps1 -TestConnection                      : Test the SQL connection only
    .\setup.ps1 -ListTables                          : List all available tables
    .\setup.ps1 -SingleTable DimProduct              : Load only the DimProduct table
    .\setup.ps1 -SkipCreateTables                    : Skip table creation, just load data
    .\setup.ps1 -SkipAzureCopy                       : Skip Azure storage upload
    .\setup.ps1 -StorageAccountName "mystorageacct"  : Specify Azure Storage Account name
    .\setup.ps1 -KeepFiles                           : Keep downloaded files for troubleshooting
    .\setup.ps1 -GitHubRepo "https://github.com/other/repo" : Use a different repository source

ENVIRONMENT VARIABLES:
    AZURE_STORAGE_ACCOUNT: Azure Storage Account name (alternative to -StorageAccountName)

"@ -ForegroundColor Cyan
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

    # Create directories in the bronze container
    Write-Host "Creating destination directories in the bronze container..." -ForegroundColor Cyan
    
    # Create dp203/01/sales_data directory
    try {
        az storage fs directory create --account-name $StorageAccountName --file-system bronze --name "dp203/01/sales_data" --auth-mode login
        Write-Host "Created directory: dp203/01/sales_data" -ForegroundColor Green
    }
    catch {
        Write-Error "Error creating sales_data directory: $_"
        # Continue even if there's an error (directory might already exist)
    }
    
    # Create dp203/01/product_data directory
    try {
        az storage fs directory create --account-name $StorageAccountName --file-system bronze --name "dp203/01/product_data" --auth-mode login
        Write-Host "Created directory: dp203/01/product_data" -ForegroundColor Green
    }
    catch {
        Write-Error "Error creating product_data directory: $_"
        # Continue even if there's an error (directory might already exist)
    }
    
    # Upload files
    Write-Host "Uploading files to Azure Data Lake Storage..." -ForegroundColor Cyan
    
    # Upload sales.csv from files folder to dp203/01/sales_data
    $salesFilePath = "$TempPath/files/sales.csv"
    if (Test-Path $salesFilePath) {
        try {
            az storage fs file upload --account-name $StorageAccountName --file-system bronze --path "dp203/01/sales_data/sales.csv" --source $salesFilePath --auth-mode login
            Write-Host "Uploaded sales.csv to dp203/01/sales_data" -ForegroundColor Green
        }
        catch {
            Write-Error "Error uploading sales.csv: $_"
        }
    }
    else {
        Write-Error "Sales file not found at: $salesFilePath"
    }
    
    # Upload ingest-data.kql from files folder to dp203/01/sales_data
    $kqlFilePath = "$TempPath/files/ingest-data.kql"
    if (Test-Path $kqlFilePath) {
        try {
            az storage fs file upload --account-name $StorageAccountName --file-system bronze --path "dp203/01/sales_data/ingest-data.kql" --source $kqlFilePath --auth-mode login
            Write-Host "Uploaded ingest-data.kql to dp203/01/sales_data" -ForegroundColor Green
        }
        catch {
            Write-Error "Error uploading ingest-data.kql: $_"
        }
    }
    else {
        Write-Error "KQL file not found at: $kqlFilePath"
    }
    
    # Upload products.csv from adventureworks folder to dp203/01/product_data
    $productsFilePath = "$TempPath/adventureworks/products.csv"
    if (Test-Path $productsFilePath) {
        try {
            az storage fs file upload --account-name $StorageAccountName --file-system bronze --path "dp203/01/product_data/products.csv" --source $productsFilePath --auth-mode login
            Write-Host "Uploaded products.csv to dp203/01/product_data" -ForegroundColor Green
        }
        catch {
            Write-Error "Error uploading products.csv: $_"
        }
    }
    else {
        Write-Error "Products file not found at: $productsFilePath"
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

# Show help if no arguments and nothing was done
if ($MyInvocation.BoundParameters.Count -eq 0 -and $args.Count -eq 0 -and ($TestConnection -or $ListTables)) {
    Show-Help
}