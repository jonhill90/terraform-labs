[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [String]$EndState = 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE'
)

function Get-ImageState {
    try {
        return (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State' -Name ImageState).ImageState
    } catch {
        Write-Warning "Failed to retrieve ImageState from the registry: $_"
        return $null
    }
}

Write-Verbose 'Starting Sysprep process...'

$sysprepPath = "${Env:SystemRoot}\System32\Sysprep\Sysprep.exe"

if (-Not (Test-Path $sysprepPath)) {
    Write-Error "Sysprep executable not found at $sysprepPath. Aborting."
    exit 1
}

try {
    & $sysprepPath /oobe /generalize /quiet /quit /mode:vm
    Write-Verbose 'Sysprep executed successfully.'
} catch {
    Write-Error "Sysprep execution failed: $_"
    exit 1
}

Write-Verbose 'Waiting for image state transition...'
do {
    $imageState = Get-ImageState
    Write-Output "Current ImageState: $imageState"

    if ($imageState -eq $EndState) {
        Write-Verbose 'Desired state reached. Shutting down.'
        break
    }

    Start-Sleep -Seconds 10
} while ($true)