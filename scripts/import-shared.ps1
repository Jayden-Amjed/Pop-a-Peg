param([Parameter(Mandatory = $true)][string]$InputModel)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$inputPath = (Resolve-Path -LiteralPath $InputModel).Path
if ([IO.Path]::GetExtension($inputPath) -ne '.rbxmx') { throw 'Export exactly one Shared folder as .rbxmx' }
[xml]$model = Get-Content -LiteralPath $inputPath -Raw
$items = @($model.roblox.Item)
if ($items.Count -ne 1 -or $items[0].class -ne 'Folder' -or
    $items[0].SelectSingleNode('Properties/string[@name="Name"]').InnerText -ne 'Shared') {
    throw 'Expected one root Folder named Shared; no place or broad syncback input is accepted'
}
# Never sync back over authoritative files. Every run gets a new disposable directory.
$stage = Join-Path $root ('scratch/import-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'src/shared') -Destination (Join-Path $stage 'shared') -Recurse
$project = Join-Path $stage 'shared.project.json'
$projectJson = '{"name":"Shared","emitLegacyScripts":true,"tree":{"$className":"Folder","$path":"shared"}}'
[IO.File]::WriteAllText($project, $projectJson, (New-Object System.Text.UTF8Encoding($false)))
& (Join-Path $root '.tools/rojo.exe') syncback $project --input $inputPath --dry-run --list
if ($LASTEXITCODE -ne 0) { throw 'Syncback preview failed' }
& (Join-Path $root '.tools/rojo.exe') syncback $project --input $inputPath --non-interactive --list
if ($LASTEXITCODE -ne 0) { throw 'Staged syncback failed' }
Write-Host "Staged only: $stage"
Write-Host "Review: git diff --no-index -- src/shared `"$stage/shared`""
Write-Host 'Copy only intended .luau edits into src/shared, inspect git diff, and run scripts/check.ps1.'
