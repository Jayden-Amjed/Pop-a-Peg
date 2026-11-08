param([switch]$Render)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$blender = Join-Path $taskRoot '.tools/blender-4.5.9-windows-x64/blender.exe'
if (!(Test-Path -LiteralPath $blender)) { throw 'Run scripts/setup-blender.ps1 first' }
$arguments = @('--background', '--factory-startup', '--python-exit-code', '1', '--python', (Join-Path $PSScriptRoot 'models/build_models.py'), '--')
if ($Render) { $arguments += '--render' }
& $blender @arguments
if ($LASTEXITCODE -ne 0) { throw 'Model build failed' }
& $blender --background --factory-startup --python-exit-code 1 --python (Join-Path $PSScriptRoot 'models/audit_motion.py') -- --output (Join-Path $taskRoot 'build/model-exports/motion-audit.json')
if ($LASTEXITCODE -ne 0) { throw 'Model motion audit failed' }
