# Enable WinRM (Remote Management)
Write-Output "Enabling WinRM..."
winrm quickconfig -q
winrm set winrm/config/service/auth @{Basic="true"}
winrm set winrm/config/service @{AllowUnencrypted="true"}
winrm set winrm/config/client @{AllowUnencrypted="true"}
Enable-PSRemoting -Force

# Configure WinRM HTTPS with a self-signed certificate
Write-Output "Configuring WinRM HTTPS..."
$cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName "${WINRM_DNS_NAME}"
$thumbprint = $cert.Thumbprint
New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $thumbprint -Force

# Restart WinRM to apply changes
Restart-Service WinRM
Write-Output "WinRM configuration complete."

# Enable RDP
Write-Output "Enabling RDP..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Set Network Level Authentication (Optional, uncomment to disable)
# Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0

Write-Output "RDP and WinRM are enabled."