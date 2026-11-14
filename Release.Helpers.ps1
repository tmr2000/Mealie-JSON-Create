#Requires -Version 5.1
function ConvertTo-ReleaseVersion {
    param([string]$Version)
    if ($Version -notmatch '^(?<major>0|[1-9][0-9]*)\.(?<minor>0|[1-9][0-9]*)\.(?<patch>0|[1-9][0-9]*)(?:-rc\.(?<rc>[1-9][0-9]*))?$') { throw 'Use MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-rc.N (without v).' }
    [pscustomobject]@{Base=[version]("$($Matches.major).$($Matches.minor).$($Matches.patch)");Rc=if ($Matches['rc']) { [long]$Matches['rc'] } else { [long]::MaxValue }}
}
function Update-ReleaseFiles {
    param([string]$Root,[string]$Version,[string]$Date)
    $next=ConvertTo-ReleaseVersion $Version
    $corePath=Join-Path $Root 'Recipe.Core.ps1'
    $logPath=Join-Path $Root 'CHANGELOG.md'
    $readmePath=Join-Path $Root 'README.md'
    $core=[IO.File]::ReadAllText($corePath)
    $log=[IO.File]::ReadAllText($logPath)
    $readme=[IO.File]::ReadAllText($readmePath)
    $versionPattern='(?m)^\$script:AppVersion=''([^'']+)''\s*$'
    $versions=[regex]::Matches($core,$versionPattern)
    if ($versions.Count -ne 1) { throw 'Expected exactly one AppVersion assignment.' }
    $currentVersion=$versions[0].Groups[1].Value
    $current=ConvertTo-ReleaseVersion $currentVersion
    if ($next.Base -lt $current.Base -or ($next.Base -eq $current.Base -and $next.Rc -lt $current.Rc)) { throw 'Release version must not go backwards.' }
    $unreleasedPattern='(?ms)^## \[Unreleased\][ \t]*\r?\n(?<notes>.*?)(?=^## |\z)'
    $sections=[regex]::Matches($log,$unreleasedPattern)
    if ($sections.Count -ne 1) { throw 'Expected exactly one Unreleased section.' }
    $notes=$sections[0].Groups['notes'].Value.Trim()
    $existing=[regex]::Matches($log,('(?m)^## \[' + [regex]::Escape($Version) + '\] - \d{4}-\d{2}-\d{2}[ \t]*\r?$'))
    if ($Version -ceq $currentVersion -and $existing.Count -eq 1 -and $notes -notmatch '(?m)^- \S') {
        Write-Output "Release $Version is already prepared; resuming checks."
        return
    }
    if ($Version -ceq $currentVersion -or $existing.Count) { throw 'This version already exists. Choose a new release version.' }
    # Development bookkeeping is not a published change.
    $notes=[regex]::Replace($notes,'(?m)^- Version impact:[^\r\n]*(?:\r?\n)?','').Trim()
    # A stable final must include the changes tested across all its candidates.
    if ($next.Rc -eq [long]::MaxValue -and $next.Base -eq $current.Base -and $current.Rc -ne [long]::MaxValue) {
        $candidatePattern='(?ms)^## \[(?<version>' + [regex]::Escape($next.Base.ToString(3)) + '-rc\.[1-9][0-9]*)\] - \d{4}-\d{2}-\d{2}[^\n]*\n(?<notes>.*?)(?=^## |\z)'
        foreach ($candidate in [regex]::Matches($log,$candidatePattern)) {
            $candidateNotes=$candidate.Groups['notes'].Value.Trim()
            if ($candidateNotes -match '(?m)^- \S') {
                $candidateNotes=[regex]::Replace($candidateNotes,'(?m)^### ','#### ')
                $notes += "`r`n`r`n### Changes from $($candidate.Groups['version'].Value)`r`n`r`n$candidateNotes"
            }
        }
        $notes=$notes.Trim()
    }
    if ($notes -notmatch '(?m)^- \S') { throw 'Add actual changes under Unreleased before preparing a release.' }
    $parsedDate=[datetime]::MinValue
    if (-not [datetime]::TryParseExact($Date,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$parsedDate)) { throw 'Invalid release date.' }
    $heading=if ($Version -match '-rc\.') { 'Current release candidate' } else { 'Current release' }
    $summary=$heading + ': **' + $Version + '** (`MealieJsonCreate-' + $Version + '.exe`, `MealieJsonCreate-' + $Version + '-Setup.exe`). See CHANGELOG.md for changes. Downloads become available after the release pipeline succeeds.'
    $introPattern='(?m)^Current (?:local )?release(?: candidate)?:[^\r\n]*'
    if ([regex]::Matches($readme,$introPattern).Count -ne 1) { throw 'Could not identify the current release line in README.md.' }
    $newCore=[regex]::Replace($core,$versionPattern,('$script:AppVersion=''' + $Version + "'"))
    $replacement="## [Unreleased]`r`n`r`n## [$Version] - $Date`r`n`r`n$notes`r`n`r`n"
    $newLog=$log.Substring(0,$sections[0].Index) + $replacement + $log.Substring($sections[0].Index+$sections[0].Length)
    $newReadme=[regex]::Replace($readme,$introPattern,[Text.RegularExpressions.MatchEvaluator]{param($match) $summary})
    $utf8=New-Object Text.UTF8Encoding($true)
    [IO.File]::WriteAllText($corePath,$newCore,$utf8)
    [IO.File]::WriteAllText($logPath,$newLog,$utf8)
    [IO.File]::WriteAllText($readmePath,$newReadme,$utf8)
    Write-Output "Prepared $Version and promoted Unreleased notes to $Date."
}
