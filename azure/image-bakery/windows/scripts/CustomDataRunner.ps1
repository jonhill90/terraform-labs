$path = "$env:SystemDrive\AzureData\CustomData.bin"
if (Test-Path $path) {
    $content = Get-Content $path -Raw
    try {
        Invoke-Expression $content
    } catch {
        "Failed to execute custom data script: $_" | Out-File C:\Windows\Temp\customdata-error.log -Append
    }
}