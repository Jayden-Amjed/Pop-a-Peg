param([ValidateRange(1024, 65535)][int]$Port = 34872)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    & .\.tools\rojo.exe serve default.project.json --address 127.0.0.1 --port $Port
    if ($LASTEXITCODE -ne 0) { throw 'Rojo serve failed' }
} finally { Pop-Location }
