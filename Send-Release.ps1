#Requires -Version 5.1
# Explicitly invoked only after reviewing and committing a prepared release.
param([switch]$DryRun)
$ErrorActionPreference='Stop'
Push-Location $PSScriptRoot
try {
    $dirty=@(& git status --porcelain)
    if ($LASTEXITCODE -ne 0) { throw 'Could not read Git status.' }
    if ($dirty.Count) { throw 'Review and commit all changes before sending a release.' }
    $branch=& git symbolic-ref --quiet --short HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Check out a branch before releasing.' }
    . "$PSScriptRoot\Recipe.Core.ps1"
    $tag="v$script:AppVersion"
    $metadata=& "$PSScriptRoot\Get-ReleaseMetadata.ps1" -Tag $tag
    & git show-ref --verify --quiet "refs/tags/$tag"
    if ($LASTEXITCODE -eq 0) { throw "Local tag $tag already exists; do not reuse release versions." }
    $remoteTags=@(& git ls-remote --tags origin "refs/tags/$tag")
    if ($LASTEXITCODE -ne 0) { throw 'Could not check remote release tags.' }
    if ($remoteTags.Count) { throw "Remote tag $tag already exists; choose a new version." }
    if ($DryRun) { Write-Output "Would tag HEAD as $tag and atomically push branch $branch and tag to origin. GitHub Actions would build and publish using $($metadata.NotesPath).";return }
    & git tag -a $tag -m "Release $tag"
    if ($LASTEXITCODE -ne 0) { throw 'Could not create release tag.' }
    & git push --atomic origin "HEAD:refs/heads/$branch" "refs/tags/$tag"
    if ($LASTEXITCODE -ne 0) { throw "Push failed. Local tag $tag remains for inspection; nothing was force-pushed. Resolve the push failure and push the same branch and tag, or remove the unpushed tag before retrying." }
    Write-Output "Sent $tag. Follow the Release workflow at https://github.com/tmr2000/Mealie-JSON-Create/actions"
} finally { Pop-Location }
