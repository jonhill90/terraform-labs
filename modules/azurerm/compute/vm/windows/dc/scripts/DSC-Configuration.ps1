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

# Convert to SecureString and PSCredential
$securePassword = ConvertTo-SecureString $SafeModeAdminPassword -AsPlainText -Force
$domainCred = New-Object -TypeName PSCredential -ArgumentList $DomainAdminUsername, $securePassword
$safemodeCred = New-Object -TypeName PSCredential -ArgumentList "Administrator", $securePassword

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
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $safemodeCred
            DependsOn                     = @("[WindowsFeature]ADDSInstall", "[WindowsFeature]DNS")
        }
    }
}

SetupDomainController -ConfigurationData $ImportedConfigData -OutputPath $DSCOutputPath
Start-DscConfiguration -Path $DSCOutputPath -ComputerName $ServerName -Force -Verbose -Wait