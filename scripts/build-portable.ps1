[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$')]
    [string] $Version = '1.0.0',

    [ValidateSet('win-x64', 'win-arm64')]
    [string] $Runtime = 'win-x64'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $projectRoot 'windows\CreateShareableRegionWindow.csproj'
$readmePath = Join-Path $projectRoot 'windows\packaging\PORTABLE-README.txt'
$artifactDirectory = Join-Path $projectRoot 'artifacts'
$workingDirectory = Join-Path $projectRoot "windows\obj\portable\$([Guid]::NewGuid().ToString('N'))"
$packageDirectory = Join-Path $workingDirectory 'Create Shareable Region Window'
$archivePath = Join-Path $artifactDirectory "CreateShareableRegionWindow-$Version-$Runtime-portable.zip"

New-Item -ItemType Directory -Force -Path $packageDirectory, $artifactDirectory | Out-Null

dotnet publish $projectPath `
    --configuration Release `
    --runtime $Runtime `
    --self-contained true `
    --output $packageDirectory `
    -p:PublishProfile=win-x64-portable `
    -p:RuntimeIdentifier=$Runtime `
    -p:Version=$Version

if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish failed with exit code $LASTEXITCODE."
}

$executablePath = Join-Path $packageDirectory 'CreateShareableRegionWindow.exe'
if (-not (Test-Path -LiteralPath $executablePath)) {
    throw "The portable executable was not produced at $executablePath."
}

Copy-Item -LiteralPath $readmePath -Destination (Join-Path $packageDirectory 'README.txt')
Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $packageDirectory).FullName `
    -DestinationPath $archivePath `
    -CompressionLevel Optimal `
    -Force

$archive = Get-Item -LiteralPath $archivePath
$hash = Get-FileHash -LiteralPath $archivePath -Algorithm SHA256

Write-Host "Portable release created: $($archive.FullName)"
Write-Host "Size: $([Math]::Round($archive.Length / 1MB, 1)) MB"
Write-Host "SHA256: $($hash.Hash)"
