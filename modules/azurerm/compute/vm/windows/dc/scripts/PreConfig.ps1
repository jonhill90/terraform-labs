param (
    [string]$ServerName,
    [string]$Username,
    [string]$Password
)

Write-Host "Invoking PreConfig on remote server: $ServerName"

$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

Invoke-Command -ComputerName $ServerName -Credential $Cred -ScriptBlock {
    Write-Host "Running PreConfig script on $env:COMPUTERNAME"

    # Ensure NuGet is available
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -Force
    }

    # Trust PSGallery if not already
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    # Install required modules if not already present
    $modules = @("xActiveDirectory", "PSDesiredStateConfiguration")
    foreach ($module in $modules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Host "Installing $module..."
            Install-Module -Name $module -Force -AllowClobber
        }
    }

    Write-Host "Required modules installed. PreConfig completed."
}