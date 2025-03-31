cd \
mkdir agent
cd agent
Add-Type -AssemblyName System.Net.Http
$client = New-Object System.Net.Http.HttpClient
$url = "https://vstsagentpackage.azureedge.net/agent/4.252.0/vsts-agent-win-x64-4.252.0.zip"
$destination = Join-Path $PWD "vsts-agent-win-x64-4.252.0.zip"
$bytes = $client.GetByteArrayAsync($url).Result
[System.IO.File]::WriteAllBytes($destination, $bytes)


Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipPath = "C:\agent\vsts-agent-win-x64-4.252.0.zip"
$extractPath = "C:\agent"

[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)