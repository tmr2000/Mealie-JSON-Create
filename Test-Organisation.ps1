#Requires -Version 5.1
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
$script:mode='valid'
function Invoke-RestMethod {
    param($Uri,$Method,$ContentType,$Body,$TimeoutSec)
    $request=[Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
    if ($request.format.properties.PSObject.Properties.Name -contains 'titleIds') {
        if ($request.prompt -match 'example.com|Reset') { throw 'Page clutter reached organiser' }
        $ids=@{titleIds=@('L1');descriptionIds=@();ingredients=@(@{lineIds=@('L3','L4')});method=@(@{lineIds=@('L6','L7')});notesIds=@();ignoredIds=@('L2','L5')}
        if ($script:mode -eq 'missing') { $ids.ignoredIds=@('L2') }
        if ($script:mode -eq 'duplicate') { $ids.ignoredIds+= 'L3' }
        if ($script:mode -eq 'unknown') { $ids.ingredients[0].lineIds=@('L999') }
        return @{response=($ids | ConvertTo-Json -Depth 8)}
    }
    return @{response='{"categories":[],"tags":[],"yield":"","prepTime":"","cookTime":"","totalTime":""}'}
}
$source="Rice bowl`nPantry`nRice`n250g dry`nCooking directions`n1\. Cook rice`nBoil for 15 minutes.`nReset`n[Photo](https://example.com/image)"
$result=ConvertTo-RecipeJson -Text $source -UseOllama | ConvertFrom-Json
if ($result.recipeIngredient.Count -ne 1 -or $result.recipeIngredient[0] -ne 'Rice 250g dry' -or $result.recipeInstructions.Count -ne 1 -or $result.recipeInstructions[0].text -notmatch 'Boil for 15 minutes') { throw 'Source grouping changed content' }
foreach ($mode in @('missing','duplicate','unknown')) {
    $script:mode=$mode;$blocked=$false
    try { $null=ConvertTo-RecipeJson -Text $source -UseOllama } catch { $blocked=$true }
    if (-not $blocked) { throw "Invalid source grouping accepted: $mode" }
}
Write-Output 'Organisation checks passed: grouped quantities, step paragraphs, clutter, omitted IDs, duplicate IDs and invented IDs.'

$script:mode='valid'
$bowls=ConvertTo-RecipeJson -UseOllama -Text (Get-Content "$PSScriptRoot\Tests\burrito-bowls.txt" -Raw -Encoding UTF8) | ConvertFrom-Json
if ($bowls.recipeIngredient.Count -ne 14 -or $bowls.recipeInstructions.Count -ne 4 -or $bowls.recipeIngredient[1] -ne 'Long-grain rice 250g dry') { throw 'Shopping layout grouping failed' }
if ($bowls.recipeInstructions[2].text -notmatch '10–12 minutes') { throw 'Shopping layout changed cooking range' }
Write-Output 'Burrito bowl shopping layout passed.'
