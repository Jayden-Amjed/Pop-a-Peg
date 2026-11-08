$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    New-Item -ItemType Directory -Path build -Force | Out-Null
    & .\.tools\rojo.exe build default.project.json --output build\dev.rbxlx
    if ($LASTEXITCODE -ne 0) { throw 'Rojo build failed' }
} finally { Pop-Location }
