param
(
    [string]$ServerName,
    [string]$DSCOutputPath,
    [string]$DomainName = $null,
    [string]$SafeModeAdminPassword = $null,
    [string]$DomainAdminUsername = "Administrator"
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

$ImportedConfigData = Import-PowerShellDataFile -Path "${PSScriptRoot}\DSCConfigData.psd1"

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
            DomainAdministratorCredential = New-Object -TypeName PSCredential -ArgumentList $DomainAdminUsername, $securePassword
            SafemodeAdministratorPassword = $securePassword
            DependsOn                     = @("[WindowsFeature]ADDSInstall", "[WindowsFeature]DNS")
        }
    }
}

SetupDomainController -ConfigurationData $ImportedConfigData -OutputPath $DSCOutputPath
Start-DscConfiguration -Path $DSCOutputPath -ComputerName $ServerName -Force -Verbose -Wait