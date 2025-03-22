$tmp_dir = "$env:SystemDrive\Windows\Temp"
$log_file = Join-Path $tmp_dir "AzureDevOps-UserData.log"
"=== custom_data.ps1 START ===" | Out-File -FilePath $log_file -Encoding UTF8 -Append

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

try {
    # Enable WinRM (Remote Management)
    Write-Log "Starting WinRM configuration..."
    try {
        Write-Log "Enabling WinRM..."
        winrm quickconfig -q
        winrm set winrm/config/service/auth @{Basic="true"}
        winrm set winrm/config/service @{AllowUnencrypted="true"}
        winrm set winrm/config/client @{AllowUnencrypted="true"}
        Enable-PSRemoting -Force
    } catch {
        Write-Log "ERROR enabling WinRM: $($_.Exception.Message)" "ERROR"
    }

    # Configure WinRM HTTPS with a self-signed certificate
    Write-Log "Starting WinRM HTTPS configuration..."
    try {
        $expectedDns = "${WINRM_DNS_NAME}"
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My |
            Where-Object { $_.Subject -eq "CN=$expectedDns" } |
            Sort-Object NotBefore -Descending |
            Select-Object -First 1

        if (-not $cert) {
            Write-Log "No matching certificate found for $expectedDns. Creating new one..."
            $cert = New-SelfSignedCertificate -DnsName $expectedDns -CertStoreLocation Cert:\LocalMachine\My
        } else {
            Write-Log "Found certificate for $expectedDns. Reusing it."
        }

        $thumbprint = $cert.Thumbprint
        Write-Log "Using certificate with Thumbprint: $thumbprint"
    } catch {
        Write-Log "ERROR configuring certificate: $($_.Exception.Message)" "ERROR"
    }

    # Ensure WinRM HTTPS listener is bound to correct cert
    try {
        $httpsListener = Get-ChildItem -Path WSMan:\Localhost\Listener |
            Where-Object { $_.Keys -match 'Transport=HTTPS' }

        if ($httpsListener) {
            Write-Log "Removing existing HTTPS listener to bind correct certificate..."
            $httpsListener | Remove-Item -Recurse -Force
        }

        Write-Log "Creating new HTTPS listener with correct certificate..."
        New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $thumbprint -Force
        Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
    } catch {
        Write-Log "ERROR creating HTTPS listener: $($_.Exception.Message)" "ERROR"
    }

    # Restart WinRM to apply changes
    try {
        Write-Log "Restarting WinRM service..."
        Restart-Service WinRM
        Write-Log "WinRM configuration complete."
        Enable-NetFirewallRule -Name "WINRM-HTTPS-In-TCP"
    } catch {
        Write-Log "ERROR restarting WinRM or enabling firewall rule: $($_.Exception.Message)" "ERROR"
    }

    # Enable RDP
    Write-Log "Starting RDP configuration..."
    try {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        Write-Log "RDP configuration complete."
    } catch {
        Write-Log "ERROR configuring RDP: $($_.Exception.Message)" "ERROR"
    }

    Write-Log "RDP and WinRM are fully enabled."
    Write-Log "custom_data.ps1 execution complete."
} catch {
    Write-Log "ERROR: $($_.Exception.Message)" "ERROR"
    Write-Log "StackTrace: $($_.ScriptStackTrace)" "ERROR"
}