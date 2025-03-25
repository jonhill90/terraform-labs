param
(
    [string]$ServerName,
    [string]$DSCOutputPath,
    [string]$DomainName = $null,
    [string]$DomainAdminUsername = "Administrator",
    [string]$SafeModeAdminPassword
)

if (-not $DomainName) {
    throw "DomainName must be provided."
}

$SecurePassword = ConvertTo-SecureString $SafeModeAdminPassword -AsPlainText -Force
[System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential("$DomainName\$DomainAdminUsername", $SecurePassword)

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = $ServerName
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        }
    )
}

Configuration SetupDomainController {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory

    Node $ServerName {
        WindowsFeature ADDSInstall {
            Name   = "AD-Domain-Services"
            Ensure = "Present"
        }

        WindowsFeature DNS {
            Name      = "DNS"
            Ensure    = "Present"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature RSAT_AD_Tools {
            Name      = "RSAT-AD-Tools"
            Ensure    = "Present"
            DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature RSAT_DNS_Server {
            Name      = "RSAT-DNS-Server"
            Ensure    = "Present"
            DependsOn = "[WindowsFeature]RSAT_AD_Tools"
        }

        xADDomain NewForest {
            DomainName                    = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DependsOn                     = @("[WindowsFeature]ADDSInstall", "[WindowsFeature]DNS", "[WindowsFeature]RSAT_AD_Tools", "[WindowsFeature]RSAT_DNS_Server")
        }
    }
}

SetupDomainController -ConfigurationData $ConfigData -OutputPath $DSCOutputPath
Start-DscConfiguration -Path $DSCOutputPath -ComputerName $ServerName -Force -Verbose -Wait