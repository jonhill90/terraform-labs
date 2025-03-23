param (
    [string]$ServerName
)

Write-Host "Downloading required DSC modules to $env:ProgramFiles\WindowsPowerShell\Modules"

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
        Install-Module -Name $module -Force -AllowClobber
    }
}

Write-Host "Required modules installed. PreConfig completed on $ServerName"