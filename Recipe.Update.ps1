#Requires -Version 5.1
# Fixed public repository; no credentials are stored or sent.
function Get-AppUpdate {
    param([string]$CurrentVersion)
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $release=Invoke-RestMethod -Uri 'https://api.github.com/repos/tmr2000/Mealie-JSON-Create/releases/latest' -Headers @{'User-Agent'='MealieJsonCreate';Accept='application/vnd.github+json'} -TimeoutSec 15
    Select-AppUpdate -Release $release -CurrentVersion $CurrentVersion
}
function Select-AppUpdate {
    param($Release,[string]$CurrentVersion)
    if ($Release.draft -or $Release.prerelease) { return }
    $remote=[string]$Release.tag_name -replace '^v',''
    if ($remote -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { return }
    $localBase=$CurrentVersion -replace '-rc\.[1-9][0-9]*$',''
    if ([version]$remote -lt [version]$localBase) { return }
    if ([version]$remote -eq [version]$localBase -and $CurrentVersion -notmatch '-rc\.') { return }
    $name="MealieJsonCreate-$remote-Setup.exe"
    $assets=@($Release.assets | Where-Object { $_.name -ceq $name })
    if ($assets.Count -ne 1) { return }
    $asset=$assets[0]
    $expected="https://github.com/tmr2000/Mealie-JSON-Create/releases/download/$($Release.tag_name)/$name"
    if ($asset.browser_download_url -cne $expected -or $asset.digest -notmatch '^sha256:[a-fA-F0-9]{64}$' -or [long]$asset.size -le 0) { return }
    [pscustomobject]@{Version=$remote;Url=$expected;Digest=$asset.digest.Substring(7);Size=[long]$asset.size;Name=$name}
}
function Save-AppUpdate {
    param($Update)
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $folder=Join-Path ([IO.Path]::GetTempPath()) ('MealieJsonCreate-' + [guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($folder)
    $path=Join-Path $folder $Update.Name
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Update.Url -OutFile $path -TimeoutSec 300
        if ((Get-Item -LiteralPath $path).Length -ne $Update.Size -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine $Update.Digest) { throw 'Installer verification failed. Nothing has been installed.' }
        $path
    } catch {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
        throw
    }
}
