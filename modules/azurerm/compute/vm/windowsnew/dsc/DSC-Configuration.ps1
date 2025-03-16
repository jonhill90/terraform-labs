param
(
    $ServerName,
    $DSCOutputPath
)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = $ServerName
        }
    )
}

Configuration DSC-Configuration
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName cChoco

    Node $ServerName
    {
        # Install Chocolatey
        cChocoInstaller installChoco { 
            InstallDir = "C:\ProgramData\Chocolatey"
        }

        # Set Chocolatey Source
        cChocoSource Repo {
            Name   = 'choco'
            Source = 'https://community.chocolatey.org/api/v2'
            DependsOn = '[cChocoInstaller]installChoco'
        }

        # Install VS Code
        cChocoPackageInstaller InstallVSCode {            
            Name      = "vscode" 
            Version   = "latest" 
            Source    = "choco"
            DependsOn = '[cChocoSource]Repo'
        }
    }
}

# Compile DSC Configuration
DSC-Configuration -ConfigurationData $ConfigurationData -OutputPath $DSCOutputPath

# Apply DSC Configuration
Start-DscConfiguration -Path $DSCOutputPath -ComputerName $ServerName -Force -Verbose -Wait