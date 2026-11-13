#Requires -Version 5.1
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
if ($script:AppVersion -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { throw 'AppVersion must use MAJOR.MINOR.PATCH format.' }
$changelog=Get-Content (Join-Path $PSScriptRoot 'CHANGELOG.md') -Raw
if ($changelog -notmatch ('(?m)^## \[' + [regex]::Escape($script:AppVersion) + '\] - \d{4}-\d{2}-\d{2}\s*$')) {
    throw "Add dated release notes for $script:AppVersion to CHANGELOG.md before building."
}
if (-not (Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue)) {
    throw 'Install PS2EXE first: Install-Module ps2exe -Scope CurrentUser'
}
$destination=Join-Path $PSScriptRoot 'dist'
[void][IO.Directory]::CreateDirectory($destination)
$core=Get-Content (Join-Path $PSScriptRoot 'Recipe.Core.ps1') -Raw
$gui=Get-Content (Join-Path $PSScriptRoot 'MealieJsonCreate.ps1') -Raw
$bundle=$gui.Replace('. "$PSScriptRoot\Recipe.Core.ps1"',$core)
$iconPath=Join-Path $PSScriptRoot 'Assets\MealieJsonCreate.ico'
if (-not (Test-Path -LiteralPath $iconPath)) { throw 'Missing application icon. Run Assets\Generate-Icon.ps1 first.' }
$iconBase64=[Convert]::ToBase64String([IO.File]::ReadAllBytes($iconPath))
$bundle=$bundle.Replace('[string]$script:EmbeddedIcon=' + "''", "[string]`$script:EmbeddedIcon='$iconBase64'")
$bundlePath=Join-Path $destination "MealieJsonCreate-$script:AppVersion.bundled.ps1"
[IO.File]::WriteAllText($bundlePath,$bundle,(New-Object Text.UTF8Encoding($true)))
Invoke-PS2EXE -InputFile $bundlePath -OutputFile (Join-Path $destination "MealieJsonCreate-$script:AppVersion.exe") -IconFile $iconPath -NoConsole -STA -Title 'Mealie JSON Create' -Version "$script:AppVersion.0"
