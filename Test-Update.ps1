#Requires -Version 5.1
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Update.ps1"
function Assert($Value,$Message) { if (-not $Value) { throw $Message } }
$asset=[pscustomobject]@{name='MealieJsonCreate-0.4.0-Setup.exe';browser_download_url='https://github.com/tmr2000/Mealie-JSON-Create/releases/download/v0.4.0/MealieJsonCreate-0.4.0-Setup.exe';digest=('sha256:' + ('a'*64));size=12}
$release=[pscustomobject]@{tag_name='v0.4.0';draft=$false;prerelease=$false;assets=@($asset)}
Assert ($null -ne (Select-AppUpdate $release '0.3.1-rc.2')) 'New stable release missing'
Assert ($null -ne (Select-AppUpdate $release '0.4.0-rc.2')) 'Final should replace same-base RC'
Assert ($null -eq (Select-AppUpdate $release '0.4.0')) 'Same stable version offered'
Assert ($null -eq (Select-AppUpdate $release '0.5.0-rc.1')) 'Downgrade offered'
$release.prerelease=$true
Assert ($null -eq (Select-AppUpdate $release '0.3.0')) 'Prerelease offered'
$release.prerelease=$false;$asset.digest=''
Assert ($null -eq (Select-AppUpdate $release '0.3.0')) 'Missing digest accepted'
$asset.digest='sha256:' + ('a'*64);$asset.browser_download_url='https://example.com/setup.exe'
Assert ($null -eq (Select-AppUpdate $release '0.3.0')) 'Foreign download accepted'
$asset.browser_download_url='https://github.com/tmr2000/Mealie-JSON-Create/releases/download/v0.4.0/MealieJsonCreate-0.4.0-Setup.exe'
$release.assets=@($asset,$asset)
Assert ($null -eq (Select-AppUpdate $release '0.3.0')) 'Duplicate assets accepted'
# Mock transport to exercise integrity failure and successful staging without network.
function Invoke-WebRequest { param([switch]$UseBasicParsing,$Uri,$OutFile,$TimeoutSec) [IO.File]::WriteAllText($OutFile,'test') }
$update=[pscustomobject]@{Name=$asset.name;Url=$asset.browser_download_url;Size=4;Digest=('a'*64)}
$failed=$false
try { Save-AppUpdate $update } catch { $failed=$true }
Assert $failed 'Tampered download accepted'
$sha=[Security.Cryptography.SHA256]::Create()
try { $update.Digest=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes('test')))).Replace('-','') } finally { $sha.Dispose() }
$path=Save-AppUpdate $update
Assert (Test-Path -LiteralPath $path) 'Verified download missing'
Remove-Item -LiteralPath $path
Write-Output 'Update checks passed.'

