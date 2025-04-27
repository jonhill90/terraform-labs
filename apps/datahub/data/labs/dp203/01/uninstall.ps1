# PowerShell script to remove the tables created by setup.ps1
# This script connects to the SQL Server defined in .env file and drops the tables

param(
    [Parameter(Mandatory=$false)]
    [string]$SingleTable,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListTables,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestConnection,
    
    [Parameter(Mandatory=$false)]
    [switch]$Confirm = $false
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

# List of tables to drop, in the correct order to avoid foreign key constraint issues
$tables = @(
    "FactInternetSales",
    "DimCustomer",
    "DimDate",
    "DimGeography",
    "DimProduct",
    "DimProductSubcategory",
    "DimProductCategory",
    "DimSalesTerritory",
    "DimPromotion",
    "DimCurrency"
)

# List tables if requested
if ($ListTables) {
    Write-Host "Tables that will be dropped:" -ForegroundColor Cyan
    foreach ($table in $tables) {
        # Check if table exists
        $query = "SELECT OBJECT_ID('dbo.$table', 'U') AS TableID;"
        $result = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDatabase -Username $SqlUser -Password $SqlPassword -Query $query -ErrorAction Stop
        
        if ($result.TableID) {
            Write-Host "  - $table (Exists)" -ForegroundColor Yellow
        } else {
            Write-Host "  - $table (Does not exist)" -ForegroundColor DarkGray
        }
    }
    exit 0
}

# Filter tables if a single table is specified
if ($SingleTable) {
    if ($tables -contains $SingleTable) {
        $tables = @($SingleTable)
        Write-Host "Only dropping table: $SingleTable" -ForegroundColor Yellow
    } else {
        Write-Error "Table '$SingleTable' not found. Available tables: $($tables -join ', ')"
        exit 1
    }
}

# Ask for confirmation if not already provided
if (-not $Confirm) {
    Write-Host ""
    Write-Host "WARNING: This will drop the following tables from $SqlDatabase" -ForegroundColor Red
    foreach ($table in $tables) {
        # Check if table exists
        $query = "SELECT OBJECT_ID('dbo.$table', 'U') AS TableID;"
        $result = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDatabase -Username $SqlUser -Password $SqlPassword -Query $query -ErrorAction Stop
        
        if ($result.TableID) {
            Write-Host "  - $table" -ForegroundColor Yellow
        }
    }
    
    $confirmResponse = Read-Host -Prompt "Are you sure you want to proceed? (y/n)"
    if ($confirmResponse -ne "y" -and $confirmResponse -ne "Y") {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

# Drop tables
Write-Host "Dropping tables..." -ForegroundColor Cyan

$totalTables = $tables.Count
$processedTables = 0
$successTables = 0
$skippedTables = 0

foreach ($table in $tables) {
    $processedTables++
    
    # Check if table exists before dropping
    $checkQuery = "SELECT OBJECT_ID('dbo.$table', 'U') AS TableID;"
    $checkResult = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDatabase -Username $SqlUser -Password $SqlPassword -Query $checkQuery -ErrorAction Stop
    
    if ($checkResult.TableID) {
        Write-Host "[$processedTables/$totalTables] Dropping table: dbo.$table" -ForegroundColor Cyan
        
        try {
            $dropQuery = "DROP TABLE [dbo].[$table];"
            Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDatabase -Username $SqlUser -Password $SqlPassword -Query $dropQuery -ErrorAction Stop
            Write-Host "Successfully dropped table: dbo.$table" -ForegroundColor Green
            $successTables++
        }
        catch {
            Write-Error "Error dropping table dbo.$table $_"
        }
    }
    else {
        Write-Host "[$processedTables/$totalTables] Table dbo.$table does not exist, skipping" -ForegroundColor Yellow
        $skippedTables++
    }
}

Write-Host ""
Write-Host "Uninstall process completed!" -ForegroundColor Green
Write-Host "Results: $successTables tables dropped, $skippedTables tables skipped, $processedTables total tables processed" -ForegroundColor Cyan

# Clear sensitive variables from memory
$SqlPassword = $null
Remove-Variable -Name SqlPassword -Force -ErrorAction SilentlyContinue
[System.GC]::Collect()

# Help message
function Show-Help {
    Write-Host @"

USAGE:
    .\uninstall.ps1 [options]

OPTIONS:
    -TestConnection  : Test the database connection and exit
    -ListTables      : List tables that would be dropped and exit
    -SingleTable name: Only drop the specified table
    -Confirm         : Skip confirmation prompt (use with caution)

EXAMPLES:
    .\uninstall.ps1                        : Run the full uninstall process with confirmation
    .\uninstall.ps1 -TestConnection        : Test the SQL connection only
    .\uninstall.ps1 -ListTables            : List all tables that will be dropped
    .\uninstall.ps1 -SingleTable DimProduct: Only drop the DimProduct table
    .\uninstall.ps1 -Confirm               : Run the uninstall without confirmation prompt

"@ -ForegroundColor Cyan
}

# Show help if no arguments
if ($MyInvocation.BoundParameters.Count -eq 0 -and $args.Count -eq 0) {
    Show-Help
}