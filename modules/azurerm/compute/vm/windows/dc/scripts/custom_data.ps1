New-Item -Path "C:\Windows\Temp\custom-data-was-here.txt" -ItemType File -Force


$tmp_dir = "$env:SystemDrive\Windows\Temp"
$log_file = Join-Path $tmp_dir "AzureDevOps-UserData.log"

Function Write-Log {
    param (
        [string]$message,
        [string]$level = "INFO"
    )

    $date_stamp = Get-Date -Format s
    $log_entry = "$date_stamp - $level - $message"

    try {
        $log_entry | Out-File -FilePath $log_file -Encoding UTF8 -Append
    } catch {
        Write-Host "LOGGING FAILED: $log_entry"
    }
}

# Enable WinRM (Remote Management)
Write-Log "Enabling WinRM..."
winrm quickconfig -q
winrm set winrm/config/service/auth @{Basic="true"}
winrm set winrm/config/service @{AllowUnencrypted="true"}
winrm set winrm/config/client @{AllowUnencrypted="true"}
Enable-PSRemoting -Force

# Configure WinRM HTTPS with a self-signed certificate
Write-Log "Configuring WinRM HTTPS..."
$cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName "${WINRM_DNS_NAME}"
$thumbprint = $cert.Thumbprint
Write-Log "Generated certificate with Thumbprint: $thumbprint"
New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $thumbprint -Force

# Restart WinRM to apply changes
Write-Log "Restarting WinRM service..."
Restart-Service WinRM
Write-Log "WinRM configuration complete."

# Enable RDP
Write-Log "Enabling RDP..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Optional: Disable Network Level Authentication
# Write-Log "Disabling Network Level Authentication for RDP..."
# Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0

Write-Log "RDP and WinRM are fully enabled."