param (
    [string]$ServerName,
    [string]$LCMOutputPath = ".\\LCM"
)

[DSCLocalConfigurationManager()]
Configuration LCMConfig {
    Node $ServerName {
        Settings {
            RefreshMode = 'Push'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
            AllowModuleOverwrite = $true
        }
    }
}

LCMConfig -OutputPath $LCMOutputPath

Set-DscLocalConfigurationManager -Path $LCMOutputPath -ComputerName $ServerName -Force -Verbose