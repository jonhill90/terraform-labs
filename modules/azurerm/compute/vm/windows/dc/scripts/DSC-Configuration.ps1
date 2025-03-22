param
(
    [string]$ServerName,
    [string]$DSCOutputPath,
    [string]$DomainName = "contoso.local", # Change this as needed
    [string]$SafeModeAdminPassword = "P@ssw0rd!" # Use a secure method in production
)

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

        # Promote the server to Domain Controller for a new forest
        xADDomain NewForest {
            DomainName                    = $DomainName
            DomainAdministratorCredential = (New-Object PSCredential("Administrator", $securePassword))
            SafemodeAdministratorPassword = $securePassword
            DependsOn                     = "[WindowsFeature]ADDSInstall"
        }
    }
}

SetupDomainController -ConfigurationData $ConfigurationData -OutputPath $DSCOutputPath
Start-DscConfiguration -Path $DSCOutputPath -ComputerName $ServerName -Force -Verbose -Wait