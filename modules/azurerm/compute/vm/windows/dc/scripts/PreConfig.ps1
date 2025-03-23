param (
    [string]$ServerName,
    [string]$Username,
    [string]$Password
)

Write-Host "Invoking PreConfig on remote server: $ServerName"

try {
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

    Invoke-Command -ComputerName $ServerName -Credential $Cred -Authentication Default -ScriptBlock {
        Write-Host "Running PreConfig script on $env:COMPUTERNAME"

        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -Force
        }

        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

        $modules = @("xActiveDirectory", "PSDesiredStateConfiguration")
        foreach ($module in $modules) {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                Write-Host "Installing $module..."
                Install-Module -Name $module -Force -AllowClobber
            }
        }

        Write-Host "✅ Required modules installed."
    }
}
catch {
    Write-Error "❌ Failed to execute PreConfig on $ServerName $_"
    exit 1
}