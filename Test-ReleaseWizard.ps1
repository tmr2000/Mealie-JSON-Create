#Requires -Version 5.1
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
. "$PSScriptRoot\Release.Helpers.ps1"
$root=Join-Path ([IO.Path]::GetTempPath()) ('MealieWizardTest-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($root)
function Reset-Fixture {
    [IO.File]::WriteAllText((Join-Path $root 'Recipe.Core.ps1'),"`$script:AppVersion='0.3.1-rc.2'`r`n# Keep me`r`n")
    [IO.File]::WriteAllText((Join-Path $root 'README.md'),"# App`r`nCurrent local release candidate: **0.3.1-rc.2** old text`r`nOther docs.`r`n")
    [IO.File]::WriteAllText((Join-Path $root 'CHANGELOG.md'),"# Changelog`r`n`r`n## [Unreleased]`r`n`r`n### Added`r`n`r`n- New capability with `$literal text.`r`n- Version impact: minor compatible capability; release version not yet assigned.`r`n`r`n## [0.3.1-rc.2] - 2026-11-14`r`n`r`n- Historical notes stay identical.`r`n")
}
function Assert($Value,$Message) { if (-not $Value) { throw $Message } }
try {
    Reset-Fixture
    $before=[IO.File]::ReadAllText((Join-Path $root 'CHANGELOG.md'))
    Update-ReleaseFiles $root '0.4.0-rc.1' '2026-11-14' | Out-Null
    $log=[IO.File]::ReadAllText((Join-Path $root 'CHANGELOG.md'))
    Assert ($log.Contains('## [Unreleased]') -and $log.Contains('## [0.4.0-rc.1] - 2026-11-14')) 'Missing version headings'
    Assert ($log.Contains('- New capability with $literal text.') -and -not $log.Contains('Version impact:')) 'Notes changed or bookkeeping retained'
    $oldHeading='## [0.3.1-rc.2]'
    Assert ($before.Substring($before.IndexOf($oldHeading)) -ceq $log.Substring($log.IndexOf($oldHeading))) 'Historical release notes were modified'
    Assert ([IO.File]::ReadAllText((Join-Path $root 'Recipe.Core.ps1')).Contains("`$script:AppVersion='0.4.0-rc.1'")) 'AppVersion not updated'
    Assert ([IO.File]::ReadAllText((Join-Path $root 'README.md')).Contains('MealieJsonCreate-0.4.0-rc.1-Setup.exe')) 'README version not updated'
    Update-ReleaseFiles $root '0.4.0-rc.1' '2026-11-15' | Out-Null
    Assert ($log -ceq [IO.File]::ReadAllText((Join-Path $root 'CHANGELOG.md'))) 'Resume rewrote prepared release notes'
    foreach ($bad in @('0.3.0','0.4.0-rc.0','v0.4.0','0.4.0-beta.1','01.4.0')) {
        $failed=$false
        try { Update-ReleaseFiles $root $bad '2026-11-14' | Out-Null } catch { $failed=$true }
        Assert $failed "Invalid/downgrade version accepted: $bad"
    }
    Update-ReleaseFiles $root '0.4.0' '2026-11-14' | Out-Null
    $finalLog=[IO.File]::ReadAllText((Join-Path $root 'CHANGELOG.md'))
    Assert ($finalLog.Contains('### Changes from 0.4.0-rc.1') -and $finalLog.Contains('## [0.4.0] - 2026-11-14')) 'Final release omitted candidate notes'
    Update-ReleaseFiles $root '0.5.0' '2026-11-14' 2>$null | Out-Null
    throw 'An empty Unreleased section must not permit a new unrelated version'
} catch {
    if ($_.Exception.Message -ne 'Add actual changes under Unreleased before preparing a release.') { throw }
    Reset-Fixture
    $readmePath=Join-Path $root 'README.md'
    [IO.File]::WriteAllText($readmePath,'Missing current release line')
    $originalCore=[IO.File]::ReadAllText((Join-Path $root 'Recipe.Core.ps1'))
    $failed=$false
    try { Update-ReleaseFiles $root '0.4.0' '2026-11-14' | Out-Null } catch { $failed=$true }
    Assert $failed 'Malformed README accepted'
    Assert ($originalCore -ceq [IO.File]::ReadAllText((Join-Path $root 'Recipe.Core.ps1'))) 'Validation failure partially modified source'
    Write-Output 'Release wizard checks passed: promotion, literal notes, historical preservation, resume, versions and failure before writes.'
} finally {
    foreach ($name in @('Recipe.Core.ps1','README.md','CHANGELOG.md')) {
        $path=Join-Path $root $name
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
    }
    Remove-Item -LiteralPath $root
}
