param (
    [string]$ServerName
)

Write-Host "Invoking PreConfig on remote server: $ServerName"

try {
    $Username = $env:PRECONFIG_USERNAME
    $PlainPassword = $env:PRECONFIG_PASSWORD

    if (-not $Username -or -not $PlainPassword) {
        throw "Username or Password environment variables not set."
    }

    $SecurePassword = ConvertTo-SecureString $PlainPassword -AsPlainText -Force
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
    Write-Error "❌ PreConfig failed on $ServerName $_"
    exit 1
}