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
function Invoke-RestMethod {
    param($Uri,$Method,$ContentType,$Body,$TimeoutSec)
    $request=[Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
    if ($request.options.temperature -ne 0 -or $request.options.seed -ne 42 -or $request.stream -ne $false) { throw 'Invalid generation settings' }
    if ($request.system -notmatch 'cookbook' -or $request.system -notmatch 'Do not invent a method') { throw 'Cookbook expansion safeguards missing' }
    return @{response='{"name":"Soup","description":"simple soup","yield":"2 servings","ingredients":["500 ml stock"],"instructions":["heat the stock"]}'}
}
$ai=ConvertTo-RecipeJson -Text 'unstructured source' -UseOllama | ConvertFrom-Json
if ($ai.recipeInstructions[0].text -cne 'Heat the stock.') { throw 'Model response normalization failed' }
Remove-Item Function:\Invoke-RestMethod
function Invoke-RestMethod {
    param($Uri,$Method,$TimeoutSec,$ErrorAction)
    if ($Uri -ne 'http://localhost:11434/api/tags' -or $Method -ne 'Get') { throw 'Wrong discovery endpoint' }
    [pscustomobject]@{models=@([pscustomobject]@{name='z-model:latest'},[pscustomobject]@{name='a-model:7b'},[pscustomobject]@{name='a-model:7b'})}
}
$names=@(Get-OllamaModels -Endpoint 'http://localhost:11434/')
if ($names.Count -ne 2 -or $names[0] -ne 'a-model:7b') { throw 'Model discovery failed' }
Remove-Item Function:\Invoke-RestMethod
Write-Output 'Core checks passed.'
