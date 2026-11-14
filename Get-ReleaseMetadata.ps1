#Requires -Version 5.1
param([Parameter(Mandatory=$true)][string]$Tag,[string]$NotesPath=(Join-Path $PSScriptRoot 'dist\release-notes.md'))
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
if ($script:AppVersion -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-rc\.[1-9][0-9]*)?$') { throw 'Invalid AppVersion.' }
if ($Tag -cne "v$script:AppVersion") { throw "Release tag $Tag must match AppVersion v$script:AppVersion." }
$text=Get-Content (Join-Path $PSScriptRoot 'CHANGELOG.md') -Raw -Encoding UTF8
$pattern='(?ms)^## \[' + [regex]::Escape($script:AppVersion) + '\] - (\d{4}-\d{2}-\d{2})\s*\r?\n(.*?)(?=^## |\z)'
$sections=[regex]::Matches($text,$pattern)
if ($sections.Count -ne 1) { throw 'Expected exactly one dated changelog section for this version.' }
$notes=$sections[0].Groups[2].Value.Trim()
if ($notes -notmatch '(?m)^- \S') { throw 'Release notes must contain at least one change.' }
[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($NotesPath)))
[IO.File]::WriteAllText($NotesPath,($notes + [Environment]::NewLine),(New-Object Text.UTF8Encoding($false)))
[pscustomobject]@{Version=$script:AppVersion;Tag=$Tag;Prerelease=($script:AppVersion -match '-rc\.');NotesPath=$NotesPath}
