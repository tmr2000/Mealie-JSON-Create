#Requires -Version 5.1
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
if (-not (Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue)) {
    throw 'Install PS2EXE first: Install-Module ps2exe -Scope CurrentUser'
}
$destination=Join-Path $PSScriptRoot 'dist'
[void][IO.Directory]::CreateDirectory($destination)
$core=Get-Content (Join-Path $PSScriptRoot 'Recipe.Core.ps1') -Raw
$gui=Get-Content (Join-Path $PSScriptRoot 'MealieJsonCreate.ps1') -Raw
$bundle=$gui.Replace('. "$PSScriptRoot\Recipe.Core.ps1"',$core)
$bundlePath=Join-Path $destination 'MealieJsonCreate.bundled.ps1'
[IO.File]::WriteAllText($bundlePath,$bundle,(New-Object Text.UTF8Encoding($true)))
Invoke-PS2EXE -InputFile $bundlePath -OutputFile (Join-Path $destination 'MealieJsonCreate.exe') -NoConsole -STA -Title 'Mealie JSON Create' -Version "$script:AppVersion.0"
