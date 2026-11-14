#Requires -Version 5.1
<#
.SYNOPSIS
Prepare, check, review, commit and send a versioned GitHub release.
.EXAMPLE
.\Release.ps1
.EXAMPLE
.\Release.ps1 -Version 0.4.0-rc.1 -PrepareOnly
#>
param([string]$Version,[switch]$PrepareOnly)
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Release.Helpers.ps1"
Push-Location $PSScriptRoot
try {
    Write-Host "`nMealie JSON Create - release wizard" -ForegroundColor Cyan
    . "$PSScriptRoot\Recipe.Core.ps1"
    $current=ConvertTo-ReleaseVersion $script:AppVersion
    $suggested=if ($script:AppVersion -match '-rc\.(\d+)$') { ($script:AppVersion -replace '-rc\.\d+$',('-rc.' + (1+[long]$Matches[1]))) } else { "$($current.Base.Major).$($current.Base.Minor + 1).0-rc.1" }
    $developmentNotes=[regex]::Match((Get-Content (Join-Path $PSScriptRoot 'CHANGELOG.md') -Raw -Encoding UTF8),'(?ms)^## \[Unreleased\][ \t]*\r?\n(.*?)(?=^## |\z)').Groups[1].Value
    if ($developmentNotes -match 'Version impact: minor') { $suggested="$($current.Base.Major).$($current.Base.Minor + 1).0-rc.1" }
    Write-Host "Current version: $script:AppVersion"
    if (-not $Version) {
        $Version=Read-Host "New version (Enter for $suggested; or enter an already prepared version to resume)"
        if ([string]::IsNullOrWhiteSpace($Version)) { $Version=$suggested }
    }
    $Version=$Version.Trim()
    $null=ConvertTo-ReleaseVersion $Version
    $branch=& git symbolic-ref --quiet --short HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Check out a branch before releasing.' }
    $origin=& git remote get-url origin
    if ($LASTEXITCODE -ne 0) { throw 'Set up the origin Git remote first.' }
    Write-Host "Target: $origin / $branch / v$Version"
    $localTags=@(& git tag --list "v$Version")
    if ($LASTEXITCODE -ne 0) { throw 'Could not read local tags.' }
    if ($localTags.Count) { throw 'This local tag exists already. Inspect the prior release attempt; tags are never replaced.' }
    if (-not $PrepareOnly) {
        $remoteTags=@(& git ls-remote --tags origin "refs/tags/v$Version")
        if ($LASTEXITCODE -ne 0) { throw 'Could not authenticate/read remote tags. Fix Git access, or use -PrepareOnly to work offline.' }
        if ($remoteTags.Count) { throw 'This version tag already exists on GitHub. Choose a new version.' }
    }
    $zone=[TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')
    $date=[TimeZoneInfo]::ConvertTimeFromUtc([datetime]::UtcNow,$zone).ToString('yyyy-MM-dd')
    Update-ReleaseFiles -Root $PSScriptRoot -Version $Version -Date $date
    $metadata=& "$PSScriptRoot\Get-ReleaseMetadata.ps1" -Tag "v$Version"
    Write-Host "`nRelease notes" -ForegroundColor Cyan
    Get-Content -LiteralPath $metadata.NotesPath | ForEach-Object { Write-Host $_ }
    foreach ($test in @('Test-Core.ps1','Test-Update.ps1','Test-Release.ps1','Test-ReleaseWizard.ps1','Test-RecipeQa.ps1','Test-SourceQa.ps1','Test-Gui.ps1')) {
        Write-Host "`nRunning $test..." -ForegroundColor Cyan
        & powershell.exe -NoProfile -STA -File (Join-Path $PSScriptRoot $test)
        if ($LASTEXITCODE -ne 0) { throw "$test failed. Prepared files remain for correction; nothing was committed or pushed." }
    }
    Write-Host "`nAll local checks passed. Changes to include:" -ForegroundColor Green
    & git status --short
    if ($LASTEXITCODE -ne 0) { throw 'Could not read Git status.' }
    & git diff --stat HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Could not summarise changes.' }
    & git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Fix whitespace errors before releasing.' }
    if ($PrepareOnly) { Write-Host "`nPrepared and tested only. Review the files, then rerun with -Version $Version to commit and publish.";return }
    Write-Host "`nReview the files above in your editor/GitHub Desktop before continuing."
    Write-Host 'Continuing stages ALL changes (including deletions and untracked files), creates a release commit when needed, and pushes the branch and tag.'
    Write-Host 'GitHub will automatically build and PUBLICLY PUBLISH the release if its checks pass. No local installer build is needed.' -ForegroundColor Yellow
    $answer=Read-Host "Type RELEASE $Version to commit and publish; anything else stops here"
    if ($answer -cne "RELEASE $Version") { Write-Host 'Stopped. Prepared files are kept; no commit, tag or push was made.';return }
    & git add --all
    if ($LASTEXITCODE -ne 0) { throw 'Could not stage changes.' }
    & git diff --cached --quiet
    $stagedExit=$LASTEXITCODE
    if ($stagedExit -eq 1) {
        & git commit -m "Release $Version"
        if ($LASTEXITCODE -ne 0) { throw 'Commit failed. Fix Git identity/hooks, then rerun the same version.' }
    } elseif ($stagedExit -ne 0) { throw 'Could not inspect staged changes.' }
    & "$PSScriptRoot\Send-Release.ps1"
    Write-Host "`nFollow the build: https://github.com/tmr2000/Mealie-JSON-Create/actions" -ForegroundColor Green
    Write-Host 'Download the installer from Releases when the run succeeds; clean install/upgrade and Mealie import still need manual testing.'
} finally { Pop-Location }
