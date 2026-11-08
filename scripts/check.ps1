$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    $lock = Get-Content tools.lock.json -Raw | ConvertFrom-Json
    foreach ($tool in $lock.tools) {
        if ($tool.binarySha256) {
            if ((Get-FileHash (Join-Path '.tools' ($tool.name + '.exe')) -Algorithm SHA256).Hash -ne $tool.binarySha256) {
                throw "Incorrect $($tool.name) executable; run scripts/setup.ps1"
            }
            continue
        }
        $actual = & (Join-Path '.tools' ($tool.name + '.exe')) --version
        if ($LASTEXITCODE -ne 0 -or "$actual" -notmatch ('\b' + [regex]::Escape($tool.version) + '$')) {
            throw "Incorrect tool version: $actual; run scripts/setup.ps1"
        }
    }
    & .\.tools\stylua.exe --check src tests
    if ($LASTEXITCODE -ne 0) { throw 'Formatting failed' }
    & .\.tools\selene.exe src tests
    if ($LASTEXITCODE -ne 0) { throw 'Lint failed' }
    & .\.tools\luau.exe tests/run.luau
    if ($LASTEXITCODE -ne 0) { throw 'Gameplay tests failed' }
    & "$PSScriptRoot/build.ps1"
    [xml]$place = Get-Content build/dev.rbxlx -Raw
    $mappings = @(
        @{ Path = 'ReplicatedStorage/Shared/Stages'; Class = 'ModuleScript'; Source = 'src/shared/Stages.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/EvolutionDisplay'; Class = 'ModuleScript'; Source = 'src/client/EvolutionDisplay.luau' },
        @{ Path = 'ServerScriptService/Server/Main'; Class = 'Script'; Source = 'src/server/Main.server.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/Main'; Class = 'LocalScript'; Source = 'src/client/Main.client.luau' },
        @{ Path = 'ReplicatedStorage/Shared/Run'; Class = 'ModuleScript'; Source = 'src/shared/Run.luau' },
        @{ Path = 'ReplicatedStorage/Shared/Board'; Class = 'ModuleScript'; Source = 'src/shared/Board.luau' },
        @{ Path = 'ReplicatedStorage/Shared/Simulation'; Class = 'ModuleScript'; Source = 'src/shared/Simulation.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/Presentation'; Class = 'ModuleScript'; Source = 'src/client/Presentation.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/HoverInspector'; Class = 'ModuleScript'; Source = 'src/client/HoverInspector.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/BoardArt'; Class = 'ModuleScript'; Source = 'src/client/BoardArt.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/Feedback'; Class = 'ModuleScript'; Source = 'src/client/Feedback.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/ItemModels'; Class = 'ModuleScript'; Source = 'src/client/ItemModels.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/ItemMotion'; Class = 'ModuleScript'; Source = 'src/client/ItemMotion.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/InventorySelection'; Class = 'ModuleScript'; Source = 'src/client/InventorySelection.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/ShopLayout'; Class = 'ModuleScript'; Source = 'src/client/ShopLayout.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/ChoiceLayout'; Class = 'ModuleScript'; Source = 'src/client/ChoiceLayout.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/UiTheme'; Class = 'ModuleScript'; Source = 'src/client/UiTheme.luau' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts/Client/SoundEffects'; Class = 'ModuleScript'; Source = 'src/client/SoundEffects.luau' },
        @{ Path = 'ReplicatedStorage/Shared/RewardTimeline'; Class = 'ModuleScript'; Source = 'src/shared/RewardTimeline.luau' },
        @{ Path = 'ReplicatedStorage/Shared/ItemFeedback'; Class = 'ModuleScript'; Source = 'src/shared/ItemFeedback.luau' }
    )
    foreach ($mapping in $mappings) {
        $node = $place.roblox
        foreach ($name in $mapping.Path.Split('/')) {
            $node = $node.SelectSingleNode("Item[Properties/string[@name='Name']='$name']")
            if ($null -eq $node) { throw "Missing instance: $($mapping.Path)" }
        }
        if ($node.class -ne $mapping.Class) { throw "Wrong script class: $($mapping.Path)" }
        $actualSource = $node.SelectSingleNode('Properties/string[@name="Source"]').InnerText -replace "`r`n", "`n"
        $expectedSource = (Get-Content $mapping.Source -Raw) -replace "`r`n", "`n"
        if ($actualSource -cne $expectedSource) { throw "Source mismatch: $($mapping.Path)" }
        Write-Host "PASS mapping/source: $($mapping.Path) [$($mapping.Class)]"
    }
    # Only inspect maintained docs, not generated files or other worktrees.
    $docs = @(Get-Item README.md, AGENTS.md, PROJECT_STATUS.md) +
        @(Get-ChildItem docs,tasks -Filter *.md -Recurse) +
        @(Get-Item .github/PULL_REQUEST_TEMPLATE.md)
    foreach ($doc in $docs) {
        $body = Get-Content -LiteralPath $doc.FullName -Raw
        foreach ($match in [regex]::Matches($body, '\[[^\]]*\]\(([^)]+)\)')) {
            $link = $match.Groups[1].Value
            if ($link -match '^(https?://|mailto:|#)') { continue }
            $path = ($link -split '#')[0]
            if ($path -and -not (Test-Path -LiteralPath (Join-Path $doc.DirectoryName $path))) {
                throw "Broken local link in $($doc.Name): $link"
            }
        }
    }
    $status = Get-Content PROJECT_STATUS.md -Raw
    foreach ($field in @('State Version:', 'Reviewed:', 'Objective:', 'Accepted source:', 'Studio-tested source:', 'Published:', 'Next action:')) {
        if (-not $status.Contains($field)) { throw "Missing status field: $field" }
    }
    if ($status -notmatch 'State Version:\s*\d+') { throw 'State Version must be an integer' }
    foreach ($task in Get-ChildItem tasks/RBX-*.md) {
        $body = Get-Content $task -Raw
        foreach ($field in @('Owner:', 'Status:', 'Starting main:', 'Branch:', 'PR:', 'Acceptance', 'Checks', 'Handoff')) {
            if (-not $body.Contains($field)) { throw "Missing $field in $($task.Name)" }
        }
    }
    Write-Host 'PASS documentation links and essential status/task fields'
} finally { Pop-Location }
