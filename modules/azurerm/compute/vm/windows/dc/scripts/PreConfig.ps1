param (
    [Parameter(Mandatory = $true)][string]$ServerName,
    [Parameter(Mandatory = $true)][string]$Username,
    [Parameter(Mandatory = $true)][string]$Password
)

Write-Host "📡 Invoking PreConfig on remote server: $ServerName"

try {
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

    Invoke-Command -ComputerName $ServerName -Credential $Cred -Authentication Negotiate -ScriptBlock {
        Write-Host "🛠 Running PreConfig script on $env:COMPUTERNAME"

        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -Force
        }

        if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }

        $modules = @("xActiveDirectory", "PSDesiredStateConfiguration")
        foreach ($module in $modules) {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                Write-Host "📦 Installing $module..."
                Install-Module -Name $module -Force -AllowClobber -Scope AllUsers
            } else {
                Write-Host "✔️ $module already installed."
            }
        }

        Write-Host "✅ PreConfig completed successfully."
    } -ErrorAction Stop
}
catch {
    Write-Error "❌ PreConfig failed on $ServerName: $_"
    exit 1
}