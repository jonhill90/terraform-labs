# PowerShell script to load data into SQL Server for lab 08 of the DP-203 course
# This script connects to the SQL Server defined in .env file, downloads necessary files from GitHub,
# and loads data into SQL Server.

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
        [string]$SourcePath = "Allfiles/labs/08",
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
    
    # Download data files (.txt and .fmt files)
    $dataFilePatterns = @(
        "DimAccount", "DimCurrency", "DimCustomer", "DimDate", 
        "DimDepartmentGroup", "DimEmployee", "DimGeography", 
        "DimOrganization", "DimProduct", "DimProductCategory", 
        "DimProductSubCategory", "DimPromotion", "DimReseller", 
        "DimSalesTerritory", "FactInternetSales", "FactResellerSales"
    )
    
    # Create arrays to store successfully downloaded files
    $downloadedFiles = New-Object System.Collections.ArrayList
    
    # Try different case variations for each file pattern
    foreach ($pattern in $dataFilePatterns) {
        # First try the original case
        $fmtUrl = "$baseUrl/data/$pattern.fmt"
        $fmtDestination = "$dataDirPath/$pattern.fmt"
        $txtUrl = "$baseUrl/data/$pattern.txt"
        $txtDestination = "$dataDirPath/$pattern.txt"
        
        $fmtSuccess = $false
        $txtSuccess = $false
        
        try {
            Invoke-WebRequest -Uri $fmtUrl -OutFile $fmtDestination
            $fmtSuccess = $true
            Write-Host "Downloaded: $pattern.fmt" -ForegroundColor Green
        } catch {
            Write-Host "Could not download $pattern.fmt with original case, trying alternative cases..." -ForegroundColor Yellow
            # Try lowercase
            $fmtUrl = "$baseUrl/data/$($pattern.ToLower()).fmt"
            try {
                Invoke-WebRequest -Uri $fmtUrl -OutFile $fmtDestination
                $fmtSuccess = $true
                Write-Host "Downloaded: $pattern.fmt (lowercase variant)" -ForegroundColor Green
            } catch {
                # Try uppercase first letter and lowercase rest
                $firstUpper = $pattern.Substring(0,1).ToUpper() + $pattern.Substring(1).ToLower()
                $fmtUrl = "$baseUrl/data/$firstUpper.fmt"
                try {
                    Invoke-WebRequest -Uri $fmtUrl -OutFile $fmtDestination
                    $fmtSuccess = $true
                    Write-Host "Downloaded: $pattern.fmt (first uppercase variant)" -ForegroundColor Green
                } catch {
                    Write-Error "Failed to download $pattern.fmt with any case variation"
                }
            }
        }
        
        try {
            Invoke-WebRequest -Uri $txtUrl -OutFile $txtDestination
            $txtSuccess = $true
            Write-Host "Downloaded: $pattern.txt" -ForegroundColor Green
        } catch {
            Write-Host "Could not download $pattern.txt with original case, trying alternative cases..." -ForegroundColor Yellow
            # Try lowercase
            $txtUrl = "$baseUrl/data/$($pattern.ToLower()).txt"
            try {
                Invoke-WebRequest -Uri $txtUrl -OutFile $txtDestination
                $txtSuccess = $true
                Write-Host "Downloaded: $pattern.txt (lowercase variant)" -ForegroundColor Green
            } catch {
                # Try uppercase first letter and lowercase rest
                $firstUpper = $pattern.Substring(0,1).ToUpper() + $pattern.Substring(1).ToLower()
                $txtUrl = "$baseUrl/data/$firstUpper.txt"
                try {
                    Invoke-WebRequest -Uri $txtUrl -OutFile $txtDestination
                    $txtSuccess = $true
                    Write-Host "Downloaded: $pattern.txt (first uppercase variant)" -ForegroundColor Green
                } catch {
                    Write-Error "Failed to download $pattern.txt with any case variation"
                }
            }
        }
        
        # Add successfully downloaded files to our list
        if ($fmtSuccess) {
            $downloadedFiles.Add("$pattern.fmt") | Out-Null
        }
        if ($txtSuccess) {
            $downloadedFiles.Add("$pattern.txt") | Out-Null
        }
    }
    
    # Convert downloaded files to array for later use
    $dataFiles = $downloadedFiles.ToArray()
    
    # Files already downloaded in the loop above
    
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
                        Write-Host "Batch content: $batch" -ForegroundColor Yellow
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
    -KeepFiles         : Keep downloaded temporary files after completion
    -GitHubRepo        : URL to the GitHub repository for downloading data files

EXAMPLES:
    .\setup.ps1                                      : Run the full data load process
    .\setup.ps1 -TestConnection                      : Test the SQL connection only
    .\setup.ps1 -ListTables                          : List all available tables
    .\setup.ps1 -SingleTable DimProduct              : Load only the DimProduct table
    .\setup.ps1 -SkipCreateTables                    : Skip table creation, just load data
    .\setup.ps1 -KeepFiles                           : Keep downloaded files for troubleshooting
    .\setup.ps1 -GitHubRepo "https://github.com/other/repo" : Use a different repository source

ENVIRONMENT VARIABLES:
    SQL_SERVER         : SQL Server name
    SQL_DATABASE       : SQL Database name
    SQL_USER           : SQL Server username
    SQL_PASSWORD       : SQL Server password

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