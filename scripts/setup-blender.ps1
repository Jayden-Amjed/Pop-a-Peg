$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$version = '4.5.9'
$expected = '41da973b9bf95bb312cbeff4d1982feb13259b43c821686b9bafea4dfe5477cf'
$toolsDir = Join-Path $taskRoot '.tools'
$archive = Join-Path $toolsDir "blender-$version-windows-x64.zip"
$executable = Join-Path $toolsDir "blender-$version-windows-x64/blender.exe"
New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
if (!(Test-Path -LiteralPath $archive)) {
    Invoke-WebRequest -Uri "https://download.blender.org/release/Blender4.5/blender-$version-windows-x64.zip" -OutFile $archive
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expected) {
    throw 'Blender archive SHA256 mismatch. Refusing to extract or execute.'
}
if (!(Test-Path -LiteralPath $executable)) {
    Expand-Archive -LiteralPath $archive -DestinationPath $toolsDir
}
& $executable --version
if ($LASTEXITCODE -ne 0) { throw 'Blender setup validation failed' }
