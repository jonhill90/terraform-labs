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
$DomainCreds = New-Object System.Management.Automation.PSCredential("$DomainName\$DomainAdminUsername", $SecurePassword)


$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "localhost"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}

Configuration SetupDomainController
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory

    Node $ServerName
    {
        WindowsFeature ADDSInstall {
            Name   = "AD-Domain-Services"
            Ensure = "Present"
        }

        WindowsFeature DNS {
            Name      = "DNS"
            Ensure    = "Present"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomain NewForest {
            DomainName                    = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds.Password
            DependsOn                     = @("[WindowsFeature]ADDSInstall", "[WindowsFeature]DNS")
        }
    }
}

SetupDomainController -ConfigurationData $ConfigData -OutputPath $DSCOutputPath
Start-DscConfiguration -Path $DSCOutputPath -ComputerName "localhost" -Force -Verbose -Wait