# Build a disposable Studio-only shop fixture without changing the game mapping.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$projectPath = Join-Path $root ('scratch/shop-prototype-' + [guid]::NewGuid().ToString('N') + '.project.json')
$outputPath = Join-Path $root 'build/Pop-a-Peg-SHOP-PROTOTYPE.rbxlx'

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
    $project.name = 'PopAPegShopPrototype'
    $project.tree.ServerScriptService.Server = Map-ScriptDirectory 'src/server'
    $project.tree.StarterPlayer.StarterPlayerScripts.Client = Map-ScriptDirectory 'src/client'
    $project.tree.StarterPlayer.StarterPlayerScripts | Add-Member -NotePropertyName ShopPrototype -NotePropertyValue ([pscustomobject]@{
        '$path' = 'tests/studio/ShopPrototype.client.luau'
    })
    $project.tree.StarterGui.'$properties'.ScreenOrientation = 'LandscapeSensor'
    $project.tree | Add-Member -NotePropertyName Players -NotePropertyValue @{
        '$className' = 'Players'
        '$properties' = @{ CharacterAutoLoads = $false }
    }
    Resolve-ProjectPaths $project.tree
    [IO.File]::WriteAllText($projectPath, ($project | ConvertTo-Json -Depth 100), [Text.UTF8Encoding]::new($false))
    & .\.tools\rojo.exe build $projectPath --output $outputPath
    if ($LASTEXITCODE -ne 0) { throw 'Shop prototype Rojo build failed' }

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
    $fixture = $place.SelectSingleNode("//Item[@class='LocalScript'][Properties/string[@name='Name']='ShopPrototype']")
    if ($null -eq $fixture) { throw 'Missing opt-in shop fixture' }
    Write-Output "Shop prototype built: $outputPath"
    Write-Output 'Both ordinary game entry scripts are disabled. Open the local file in Studio and press Play.'
} finally {
    if (Test-Path -LiteralPath $projectPath) { Remove-Item -LiteralPath $projectPath }
    Pop-Location
}
