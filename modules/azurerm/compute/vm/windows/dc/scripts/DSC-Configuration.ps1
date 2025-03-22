param
(
    [string]$ServerName,
    [string]$DSCOutputPath,
    [string]$DomainName = $null,
    [string]$SafeModeAdminPassword = $null
)

if (-not $DomainName -or -not $SafeModeAdminPassword) {
    throw "DomainName and SafeModeAdminPassword must be provided."
}

$securePassword = ConvertTo-SecureString $SafeModeAdminPassword -AsPlainText -Force

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = $ServerName
        }
    )
}

Configuration SetupDomainController
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory

    Node $ServerName
    {
        # Install the AD DS Role
        WindowsFeature ADDSInstall {
            Name   = "AD-Domain-Services"
            Ensure = "Present"
        }

        # Install the DNS Role
        WindowsFeature DNS {
            Name   = "DNS"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        # Promote the server to Domain Controller for a new forest
        xADDomain NewForest {
            DomainName                    = $DomainName
            DomainAdministratorCredential = (New-Object PSCredential("Administrator", $securePassword))
            SafemodeAdministratorPassword = $securePassword
            DependsOn                     = @("[WindowsFeature]ADDSInstall", "[WindowsFeature]DNS")
        }
    }
}

SetupDomainController -ConfigurationData $ConfigurationData -OutputPath $DSCOutputPath
Start-DscConfiguration -Path $DSCOutputPath -ComputerName $ServerName -Force -Verbose -Wait