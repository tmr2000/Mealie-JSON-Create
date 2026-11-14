#Requires -Version 5.1
param([switch]$Installer,[string]$IsccPath)
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
if ($script:AppVersion -notmatch '^(?<base>(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*))(?:-rc\.[1-9][0-9]*)?$') { throw 'AppVersion must use MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-rc.N format (N starts at 1).' }
# Windows requires numeric file metadata; derive it from the single AppVersion.
$windowsVersion=$Matches['base'] + '.0'
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
$classificationJson=Get-Content (Join-Path $PSScriptRoot 'Recipe.Classification.json') -Raw -Encoding UTF8
$null=$classificationJson | ConvertFrom-Json -ErrorAction Stop
$core=$core.Replace("Get-Content (Join-Path `$PSScriptRoot 'Recipe.Classification.json') -Raw -Encoding UTF8", ("'" + $classificationJson.Replace("'", "''") + "'"))
$gui=Get-Content (Join-Path $PSScriptRoot 'MealieJsonCreate.ps1') -Raw
$bundle=$gui.Replace('. "$PSScriptRoot\Recipe.Core.ps1"',$core)
$bundle=$bundle.Replace('. "$PSScriptRoot\Recipe.Update.ps1"',(Get-Content (Join-Path $PSScriptRoot 'Recipe.Update.ps1') -Raw))
$bundle=$bundle.Replace('. "$PSScriptRoot\Recipe.UpdateUi.ps1"',(Get-Content (Join-Path $PSScriptRoot 'Recipe.UpdateUi.ps1') -Raw))
$iconPath=Join-Path $PSScriptRoot 'Assets\MealieJsonCreate.ico'
if (-not (Test-Path -LiteralPath $iconPath)) { throw 'Missing application icon. Run Assets\Generate-Icon.ps1 first.' }
$iconBase64=[Convert]::ToBase64String([IO.File]::ReadAllBytes($iconPath))
$bundle=$bundle.Replace('[string]$script:EmbeddedIcon=' + "''", "[string]`$script:EmbeddedIcon='$iconBase64'")
$bundlePath=Join-Path $destination "MealieJsonCreate-$script:AppVersion.bundled.ps1"
[IO.File]::WriteAllText($bundlePath,$bundle,(New-Object Text.UTF8Encoding($true)))
Invoke-PS2EXE -InputFile $bundlePath -OutputFile (Join-Path $destination "MealieJsonCreate-$script:AppVersion.exe") -IconFile $iconPath -NoConsole -STA -Title 'Mealie JSON Create' -Version $windowsVersion
if ($Installer) {
    if (-not $IsccPath) {
        $compiler=Get-Command ISCC.exe -ErrorAction SilentlyContinue
        if ($compiler) { $IsccPath=$compiler.Source }
        else { $IsccPath=Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe' }
    }
    if (-not (Test-Path -LiteralPath $IsccPath)) { throw 'Install Inno Setup, then use Build.ps1 -Installer -IsccPath <path to ISCC.exe>.' }
    & $IsccPath "/DAppVersion=$script:AppVersion" "/DWindowsVersion=$windowsVersion" (Join-Path $PSScriptRoot 'Installer.iss')
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code $LASTEXITCODE" }
}
