# Requires Windows x64 and PowerShell 5.1+; no global tool installation.
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT' -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'This tool lock targets Windows x64. Use that platform locally and in CI.'
}
$root = Split-Path $PSScriptRoot -Parent
$toolDir = Join-Path $root '.tools'
New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
$lock = Get-Content (Join-Path $root 'tools.lock.json') -Raw | ConvertFrom-Json
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
foreach ($tool in $lock.tools) {
    $archive = Join-Path $toolDir ($tool.name + '-' + $tool.version + '.zip')
    if (-not (Test-Path $archive) -or (Get-FileHash $archive -Algorithm SHA256).Hash -ne $tool.sha256) {
        Invoke-WebRequest -UseBasicParsing -Uri $tool.url -OutFile $archive
    }
    if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $tool.sha256) {
        throw "Checksum mismatch: $($tool.name)"
    }
    $unpack = Join-Path $toolDir ($tool.name + '-' + $tool.version)
    Expand-Archive -LiteralPath $archive -DestinationPath $unpack -Force
    $executables = @(Get-ChildItem -LiteralPath $unpack -Recurse -Filter ($tool.name + '.exe'))
    if ($executables.Count -ne 1) { throw "Expected one $($tool.name).exe in release" }
    Copy-Item -LiteralPath $executables[0].FullName -Destination (Join-Path $toolDir ($tool.name + '.exe')) -Force
    & (Join-Path $toolDir ($tool.name + '.exe')) --version
    if ($LASTEXITCODE -ne 0) { throw "Could not run $($tool.name)" }
}
