param (
    [string]$ServerName,
    [string]$LCMOutputPath = ".\\LCM"
)

[DSCLocalConfigurationManager()]
Configuration LCMConfig {
    Node $ServerName {
        Settings {
            RefreshMode          = 'Push'
            ConfigurationMode    = 'ApplyOnly'
            RebootNodeIfNeeded   = $true
            AllowModuleOverwrite = $true
        }
    }
}

# Compile MOF
LCMConfig -OutputPath $LCMOutputPath

# Apply remotely over WinRM
Set-DscLocalConfigurationManager -ComputerName $ServerName -Path $LCMOutputPath -Force -Verbose