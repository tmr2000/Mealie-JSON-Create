#Requires -Version 5.1
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
$folder=Join-Path ([IO.Path]::GetTempPath()) ('MealieReleaseTest-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($folder)
try {
    $path=Join-Path $folder 'notes.md'
    $metadata=& "$PSScriptRoot\Get-ReleaseMetadata.ps1" -Tag "v$script:AppVersion" -NotesPath $path
    $notes=Get-Content -LiteralPath $path -Raw
    if ($metadata.Version -cne $script:AppVersion -or $metadata.Prerelease -ne ($script:AppVersion -match '-rc\.')) { throw 'Incorrect release metadata' }
    if ($notes -notmatch '(?m)^- \S' -or $notes -match '(?m)^## \[' -or $notes -match '\[Unreleased\]') { throw 'Notes extraction leaked another version or omitted changes' }
    $failed=$false
    try { & "$PSScriptRoot\Get-ReleaseMetadata.ps1" -Tag 'v999.0.0' -NotesPath $path | Out-Null } catch { $failed=$true }
    if (-not $failed) { throw 'Mismatched tag accepted' }
    Write-Output 'Release metadata checks passed.'
} finally {
    if (Test-Path -LiteralPath (Join-Path $folder 'notes.md')) { Remove-Item -LiteralPath (Join-Path $folder 'notes.md') }
    Remove-Item -LiteralPath $folder
}
