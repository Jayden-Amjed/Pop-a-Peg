# Build a disposable Studio-only UI fixture without changing the game mapping.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$projectPath = Join-Path $root ('scratch/ui-preview-' + [guid]::NewGuid().ToString('N') + '.project.json')
$outputPath = Join-Path $root 'build/Pop-a-Peg-UI-PREVIEW.rbxlx'

function Resolve-ProjectPaths($node) {
    if ($node -is [System.Management.Automation.PSCustomObject]) {
        foreach ($property in $node.PSObject.Properties) {
            if ($property.Name -eq '$path') {
                $property.Value = [IO.Path]::GetFullPath((Join-Path $root $property.Value))
            } else {
                Resolve-ProjectPaths $property.Value
            }
        }
    } elseif ($node -is [array]) {
        foreach ($child in $node) { Resolve-ProjectPaths $child }
    } elseif ($node -is [System.Collections.IDictionary]) {
        foreach ($key in @($node.Keys)) {
            if ($key -eq '$path') {
                $node[$key] = [IO.Path]::GetFullPath((Join-Path $root $node[$key]))
            } else {
                Resolve-ProjectPaths $node[$key]
            }
        }
    }
}

function Map-ScriptDirectory($relativePath) {
    # Explicit children allow overriding Main without colliding with Rojo's
    # directory-inferred Main. Sources themselves remain in their owning paths.
    $mapping = [ordered]@{ '$className' = 'Folder' }
    foreach ($entry in Get-ChildItem -LiteralPath (Join-Path $root $relativePath)) {
        if (-not $entry.PSIsContainer -and $entry.Extension -ne '.luau') {
            throw "Unexpected script-directory entry: $($entry.FullName)"
        }
        $name = if ($entry.PSIsContainer) { $entry.Name } else {
            [IO.Path]::GetFileNameWithoutExtension($entry.Name) -replace '\.(client|server)$', ''
        }
        $child = [pscustomobject]@{ '$path' = (Join-Path $relativePath $entry.Name) }
        if ($name -eq 'Main') {
            $child | Add-Member -NotePropertyName '$properties' -NotePropertyValue @{ Disabled = $true }
        }
        $mapping[$name] = $child
    }
    return [pscustomobject]$mapping
}

Push-Location $root
try {
    New-Item -ItemType Directory -Path build, scratch -Force | Out-Null
    $project = Get-Content default.project.json -Raw | ConvertFrom-Json
    $project.name = 'PopAPegUiPreview'
    $project.tree.ServerScriptService.Server = Map-ScriptDirectory 'src/server'
    $project.tree.StarterPlayer.StarterPlayerScripts.Client = Map-ScriptDirectory 'src/client'
    $project.tree.StarterPlayer.StarterPlayerScripts | Add-Member -NotePropertyName UiPreview -NotePropertyValue ([pscustomobject]@{
        '$path' = 'tests/studio/UiPreview.client.luau'
    })
    $project.tree.StarterGui.'$properties'.ScreenOrientation = 'LandscapeSensor'
    $project.tree | Add-Member -NotePropertyName Players -NotePropertyValue @{
        '$className' = 'Players'
        '$properties' = @{ CharacterAutoLoads = $false }
    }
    $project.tree.ReplicatedStorage | Add-Member -NotePropertyName UiPreviewLibrary -NotePropertyValue @{
        '$className' = 'Folder'
        ArcadeSessions = @{ '$path' = 'src/server/ArcadeSessions.luau' }
        PlaytestAccess = @{ '$path' = 'src/server/PlaytestAccess.luau' }
        HubWorld = @{ '$path' = 'src/server/HubWorld.luau' }
    }
    Resolve-ProjectPaths $project.tree
    [IO.File]::WriteAllText($projectPath, ($project | ConvertTo-Json -Depth 100), [Text.UTF8Encoding]::new($false))
    & .\.tools\rojo.exe build $projectPath --output $outputPath
    if ($LASTEXITCODE -ne 0) { throw 'UI preview Rojo build failed' }

    [xml]$place = Get-Content $outputPath -Raw
    foreach ($path in @('ServerScriptService/Server/Main', 'StarterPlayer/StarterPlayerScripts/Client/Main')) {
        $node = $place.roblox
        foreach ($name in $path.Split('/')) {
            $node = $node.SelectSingleNode("Item[Properties/string[@name='Name']='$name']")
            if ($null -eq $node) { throw "Missing disabled entry script: $path" }
        }
        if ($node.SelectSingleNode("Properties/bool[@name='Disabled']").InnerText -ne 'true') {
            throw "Game entry script is not disabled: $path"
        }
    }
    $fixture = $place.SelectSingleNode("//Item[@class='LocalScript'][Properties/string[@name='Name']='UiPreview']")
    if ($null -eq $fixture) { throw 'Missing opt-in UI fixture' }
    Write-Output "UI preview built: $outputPath"
    Write-Output 'Both ordinary game entry scripts are disabled. Open the local file in Studio and press Play.'
} finally {
    if (Test-Path -LiteralPath $projectPath) { Remove-Item -LiteralPath $projectPath }
    Pop-Location
}

