$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
$sample=@'
Tomato pasta
Serves: 2
Ingredients
- 200 g pasta
- 1 tin tomatoes
Method
1. boil the pasta
2. Add the tomatoes and stir.
'@
$json=ConvertTo-RecipeJson -Text $sample
$recipe=$json | ConvertFrom-Json
if ($recipe.'@type' -ne 'Recipe' -or $recipe.recipeIngredient.Count -ne 2 -or $recipe.recipeInstructions.Count -ne 2) { throw 'Invalid recipe shape' }
if ($recipe.recipeInstructions[0].text -cne 'Boil the pasta.') { throw 'Sentence formatting failed' }
if ((ConvertTo-RecipeJson -Text $sample) -cne $json) { throw 'Offline conversion is not deterministic' }
if ($recipe.recipeIngredient[0] -cne '200 g pasta') { throw 'Quantity changed' }
$single=ConvertTo-RecipeJson -Text "Soup`nIngredients`n500 ml stock`nMethod`nHeat the stock" -Title 'Stock soup' -SourceUrl 'https://example.com/soup' | ConvertFrom-Json
if ($single.recipeIngredient -isnot [array] -or $single.recipeInstructions -isnot [array] -or $single.name -ne 'Stock soup') { throw 'Single-item arrays or title override failed' }
foreach ($bad in @('Only a title',"Soup`nIngredients`nWater")) {
    $failed=$false
    try { $null=ConvertTo-RecipeJson -Text $bad } catch { $failed=$true }
    if (-not $failed) { throw 'Incomplete recipe was accepted' }
}
# Exercise structured model response handling without requiring an Ollama install.
$script:ExpectedTag='Soup'
$script:MockClassification='normal'
$script:MockResponse='{"name":"Soup","description":"simple soup","yield":"2 servings","prepTime":"PT5M","cookTime":"PT10M","totalTime":"PT15M","metadataNote":"Times estimated.","categories":["Main courses","main courses"],"tags":["Soup","soup"],"ingredients":["500 ml stock"],"instructions":["heat the stock"]}'
function Invoke-RestMethod {
    param($Uri,$Method,$ContentType,$Body,$TimeoutSec)
    $request=[Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
    if ($request.options.temperature -ne 0 -or $request.options.seed -ne 42 -or $request.stream -ne $false) { throw 'Invalid generation settings' }
    if ($script:MockClassification -eq 'duration') { return @{response=$script:MockResponse} }
    if ($request.format.properties.PSObject.Properties.Name -contains 'tags' -and $request.format.properties.tags.items.enum -notcontains $script:ExpectedTag) { throw 'Classification configuration not supplied' }
    if ($script:MockClassification -eq 'unknown') { return @{response=$script:MockResponse.Replace('"Soup","soup"','"Invented tag"')} }
    if ($script:MockClassification -eq 'empty') { return @{response=$script:MockResponse.Replace('["Soup","soup"]','[]').Replace('["Main courses","main courses"]','[]')} }
    return @{response='{"name":"Soup","description":"simple soup","yield":"2 servings","prepTime":"PT5M","cookTime":"PT10M","totalTime":"PT15M","metadataNote":"Times estimated.","categories":["Main courses","main courses"],"tags":["Soup","soup"],"ingredients":["500 ml stock"],"instructions":["heat the stock"]}'}
}
$ai=ConvertTo-RecipeJson -Text "Soup source`nIngredients`n500 ml stock`nMethod`nheat the stock" -UseOllama | ConvertFrom-Json
if ($ai.recipeInstructions[0].text -cne 'Heat the stock.') { throw 'Model response normalization failed' }
if ($ai.totalTime -ne 'PT15M' -or $ai.recipeYield -ne '2 servings' -or $ai.comment -notmatch 'estimated') { throw 'Model metadata lost' }
if ($ai.recipeCategory.Count -ne 0 -or @($ai.keywords | Where-Object { $_ -eq 'Soup' }).Count -ne 1 -or $ai.keywords[0] -cne 'Soup') { throw 'Classification normalization failed' }
$script:MockClassification='unknown'
$failed=$false
try { $null=ConvertTo-RecipeJson -Text "Soup source`nIngredients`n500 ml stock`nMethod`nheat the stock" -UseOllama } catch { $failed=$_.Exception.Message -match 'unknown tags label' }
if (-not $failed) { throw 'Unknown model tags were accepted' }
$script:MockClassification='empty'
$empty=ConvertTo-RecipeJson -Text "Soup source`nIngredients`n500 ml stock`nMethod`nheat the stock" -UseOllama | ConvertFrom-Json
if ($empty.keywords -isnot [array] -or $empty.keywords -notcontains 'Soup' -or $empty.recipeCategory.Count) { throw 'Empty classification arrays failed' }
$script:MockClassification='normal'
$originalResponse=$script:MockResponse
$script:MockClassification='duration'
$script:MockResponse=$originalResponse

$script:MockClassification='duration'
foreach ($case in @(
    @{tags=@('Chicken','Vegetarian','Vegan');ingredient='200 g chicken';expected=@('Chicken')},
    @{tags=@('Vegetarian','Vegan');ingredient='200 ml chicken stock';expected=@()},
    @{tags=@('Fish','Vegetarian','Vegan');ingredient='200 g salmon';expected=@('Fish')},
    @{tags=@('Eggs','Vegetarian','Vegan');ingredient='2 eggs';expected=@('Eggs','Vegetarian')},
    @{tags=@('Vegetarian','Vegan');ingredient='100 ml milk';expected=@('Vegetarian')},
    @{tags=@('Vegetarian','Vegan');ingredient='1 tbsp honey';expected=@('Vegetarian')},
    @{tags=@('Vegetarian','Vegan');ingredient='1 tsp gelatine';expected=@()},
    @{tags=@('Vegetarian','Vegan');ingredient='200 g lentils';expected=@('Vegetarian','Vegan')},
    @{tags=@();ingredient='200 g lentils';expected=@()}
)) {
    $mock=$originalResponse | ConvertFrom-Json
    $mock.tags=@($case.tags)
    $mock.ingredients=@($case.ingredient)
    $script:MockResponse=$mock | ConvertTo-Json -Depth 8
    $checked=ConvertTo-RecipeJson -Text ($case.ingredient + "`nIngredients`n" + $case.ingredient + "`nMethod`nPrepare and serve.") -UseOllama | ConvertFrom-Json
    if ((@($checked.keywords | Where-Object { $_ -in @('Vegetarian','Vegan') }) -join '|') -cne (@($case.expected | Where-Object { $_ -in @('Vegetarian','Vegan') }) -join '|')) { throw "Dietary conflict handling failed: $($case.ingredient)" }
}
$script:MockResponse=$originalResponse.Replace('PT10M','PT6H-PT7H').Replace('PT15M','PT7H5M')
$ranged=ConvertTo-RecipeJson -Text "Soup source`nIngredients`n500 ml stock`nMethod`nheat the stock" -UseOllama | ConvertFrom-Json
if ($ranged.cookTime -ne 'PT7H' -or $ranged.comment -notmatch 'upper bound of cookTime range PT6H-PT7H') { throw 'Model duration range recovery failed' }
foreach ($badDuration in @('PT7H-PT6H','PT6H-banana','PT')) {
    $script:MockResponse=$originalResponse.Replace('PT10M',$badDuration)
    $failed=$false
    try { $null=ConvertTo-RecipeJson -Text "Soup source`nIngredients`n500 ml stock`nMethod`nheat the stock" -UseOllama } catch { $failed=$true }
    if (-not $failed) { throw "Invalid model duration accepted: $badDuration" }
}
$script:MockResponse=$originalResponse
$script:MockClassification='normal'
$custom=$script:ClassificationJson | ConvertFrom-Json
$custom.tagGroups[1].labels=@('Broth')
$script:ExpectedTag='Broth'
$failed=$false
try { $null=ConvertTo-RecipeJson -Text "Soup source`nIngredients`n500 ml stock`nMethod`nheat the stock" -UseOllama -ClassificationJson ($custom | ConvertTo-Json -Depth 12) } catch { $failed=$_.Exception.Message -match 'unknown tags label' }
if (-not $failed) { throw 'Custom configuration did not affect validation/schema' }
# Match the GUI's isolated conversion runspace: configuration must be passed explicitly.
$script:ExpectedTag='Soup'
$worker=[powershell]::Create()
try {
    $setup="function Format-RecipeLine { ${function:Format-RecipeLine} }; function Get-RecipeClassification { ${function:Get-RecipeClassification} }; function ConvertTo-RecipeJson { ${function:ConvertTo-RecipeJson} }; function Invoke-RestMethod { param(`$Uri,`$Method,`$ContentType,`$Body,`$TimeoutSec) @{response='" + $script:MockResponse + "'} }"
    [void]$worker.AddScript($setup)
    [void]$worker.AddStatement().AddCommand('ConvertTo-RecipeJson').AddParameter('Text',"Soup source`nIngredients`n500 ml stock`nMethod`nheat the stock").AddParameter('UseOllama',$true).AddParameter('ClassificationJson',$script:ClassificationJson)
    $isolated=($worker.Invoke() -join "`n") | ConvertFrom-Json
    if ($worker.HadErrors -or $isolated.keywords[0] -ne 'Soup') { throw 'Isolated classification conversion failed' }
} finally { $worker.Dispose() }
# Verify build embedding without generating or replacing a release executable.
$core=Get-Content (Join-Path $PSScriptRoot 'Recipe.Core.ps1') -Raw
$core=$core.Replace("Get-Content (Join-Path `$PSScriptRoot 'Recipe.Classification.json') -Raw -Encoding UTF8", ("'" + $script:ClassificationJson.Replace("'", "''") + "'"))
$worker=[powershell]::Create()
try {
    [void]$worker.AddScript($core)
    [void]$worker.AddStatement().AddScript('$script:ClassificationJson')
    $embedded=$worker.Invoke() -join "`n"
    if ($worker.HadErrors -or $embedded -cne $script:ClassificationJson) { throw 'Embedded classification differs from source configuration' }
} finally { $worker.Dispose() }
Remove-Item Function:\Invoke-RestMethod
function Invoke-RestMethod {
    param($Uri,$Method,$TimeoutSec,$ErrorAction)
    if ($Uri -ne 'http://localhost:11434/api/tags' -or $Method -ne 'Get') { throw 'Wrong discovery endpoint' }
    [pscustomobject]@{models=@([pscustomobject]@{name='z-model:latest'},[pscustomobject]@{name='a-model:7b'},[pscustomobject]@{name='a-model:7b'})}
}
$names=@(Get-OllamaModels -Endpoint 'http://localhost:11434/')
if ($names.Count -ne 2 -or $names[0] -ne 'a-model:7b') { throw 'Model discovery failed' }
Remove-Item Function:\Invoke-RestMethod


$timed = ConvertTo-RecipeJson -Text ($sample + "`nPrep time: 10 minutes`nCook time: 1 hour 20 minutes`nTotal time: PT2H") | ConvertFrom-Json
if ($timed.prepTime -ne 'PT10M' -or $timed.cookTime -ne 'PT1H20M' -or $timed.totalTime -ne 'PT2H' -or $timed.recipeInstructions.Count -ne 2) { throw 'Offline timing extraction failed' }
if ($single.recipeYield -ne '' -or $single.comment -notmatch 'not supplied') { throw 'Missing metadata not disclosed' }

Write-Output 'Core checks passed.'

# Missing optional metadata must reach review, including absent/null model fields.
function Invoke-RestMethod { param($Uri,$Method,$ContentType,$Body,$TimeoutSec) return @{response=$script:MockResponse} }
$script:MockClassification='duration'
foreach ($metadata in @('"yield":"","prepTime":"","cookTime":"","totalTime":"","categories":[],"tags":[]', '"yield":null,"prepTime":null,"categories":null', '"metadataNote":""')) {
    $script:MockResponse='{"name":"Soup","description":"","ingredients":["water"],"instructions":["Heat water"],' + $metadata + '}'
    if ($metadata -notmatch 'metadataNote') { $script:MockResponse=$script:MockResponse.TrimEnd('}') + ',"metadataNote":""}' }
    $optional=ConvertTo-RecipeJson -Text "Unidentified dish`nIngredients`nwater`nMethod`nHeat water" -UseOllama | ConvertFrom-Json
    if ($optional.recipeYield -or $optional.prepTime -or $optional.totalTime -or $optional.keywords.Count -or $optional.recipeCategory.Count) { throw 'Missing metadata was populated or rejected' }
}
Write-Host 'Optional metadata checks passed.'
