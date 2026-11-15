#Requires -Version 5.1
param([switch]$Live)
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
$source=Get-Content (Join-Path $PSScriptRoot 'Tests\slow-cooker-chicken-curry.txt') -Raw -Encoding UTF8
# Deliberately reproduce the observed failures, plus missing/changed source facts.
$script:qaResponse=[ordered]@{
    name='Easy no-waste slow cooker chicken curry';description='A flavourful vegetarian curry.'
    yield='8 portions';prepTime='PT20M';cookTime='PT6H';totalTime='PT6H'
    metadataNote='Times estimated.'
    categories=@('Main courses','Desserts')
    tags=@('Chicken','Vegetarian','Vegan','Slow cooker','Make ahead','Freezer friendly','Quick (30 minutes or less)')
    ingredients=@('900g chicken','1 onion')
    instructions=@('Cook on HIGH for 2 hours. Discard the spinach.')
}
function Invoke-RestMethod {
    param($Uri,$Method,$ContentType,$Body,$TimeoutSec)
    @{response=($script:qaResponse | ConvertTo-Json -Depth 12)}
}
$result=ConvertTo-RecipeJson -Text $source -UseOllama | ConvertFrom-Json
if ($result.recipeIngredient.Count -ne 12 -or $result.recipeIngredient[0] -notmatch '^500g' -or $result.recipeIngredient[-1] -ne '300g basmati rice, to serve') { throw 'Source ingredients not preserved' }
if ($result.recipeInstructions.Count -ne 5 -or $result.recipeInstructions[2].text -notmatch 'LOW for 6.7 hours.*HIGH for 3.4 hours' -or $result.recipeInstructions[3].text -notmatch '10.15 minutes') { throw 'Source method/options not preserved' }
if ($result.recipeYield -ne '4 portions' -or $result.cookTime -ne 'PT7H' -or $result.totalTime -ne 'PT7H20M') { throw 'Source yield/time basis or total consistency failed' }
if ($result.description -or ($result.recipeCategory -join '|') -ne 'Main courses' -or $result.keywords -notcontains 'Curry' -or @($script:qaResponse.tags | Where-Object { $_ -notin @('Vegetarian','Vegan') -and $result.keywords -notcontains $_ }).Count -or $result.keywords -contains 'Vegetarian' -or $result.keywords -contains 'Vegan') { throw 'Unsupported claims/classification survived' }
if ($result.comment -notmatch 'retained verbatim' -or $result.comment -notmatch 'upper bound' -or $result.comment -notmatch 'Inconsistent total' -or $result.comment -notmatch 'Prep time is a model estimate') { throw 'QA corrections not disclosed' }
$script:qaResponse.categories=@('Main courses','Cakes & baking')
$again=ConvertTo-RecipeJson -Text $source -UseOllama | ConvertFrom-Json
if ($again.recipeCategory -contains 'Cakes & baking') { throw 'Unsupported baking category survived' }
# Positive controls: useful tags/categories must not always be stripped.
$script:qaResponse.categories=@('Desserts','Cakes & baking')
$script:qaResponse.tags=@('Make ahead','Freezer friendly','Quick (30 minutes or less)')
$script:qaResponse.cookTime='PT10M';$script:qaResponse.prepTime='PT5M';$script:qaResponse.totalTime='PT15M'
$positive=ConvertTo-RecipeJson -Text "Chocolate cake dessert.`nIngredients`nChocolate`nMethod`nBake the cake.`nNotes`nPrepare the cake in advance.`nFreeze in portions." -UseOllama | ConvertFrom-Json
if ($positive.recipeCategory.Count -ne 2 -or $positive.keywords -notcontains 'Make ahead' -or $positive.keywords -notcontains 'Freezer friendly' -or $positive.keywords -notcontains 'Quick (30 minutes or less)') { throw 'Supported evidence rejected' }
# Negated storage guidance cannot qualify as affirmative planning evidence.
$negative=ConvertTo-RecipeJson -Text "Chicken curry`nIngredients`nChicken`nMethod`nCook the chicken.`nNotes`nDo not prepare in advance. Do not freeze." -UseOllama | ConvertFrom-Json
if ($negative.keywords -notcontains 'Make ahead' -or $negative.keywords -notcontains 'Freezer friendly') { throw 'Negated guidance accepted' }
Remove-Item Function:\Invoke-RestMethod
Write-Output 'Recipe QA checks passed: source preservation, cooking options, yield, timing, categories, dietary claims, planning evidence and positive controls.'
if ($Live) {
    foreach ($model in @(Get-OllamaModels)) {
        try {
            $actual=ConvertTo-RecipeJson -Text $source -UseOllama -Model $model | ConvertFrom-Json
            if ($actual.recipeIngredient.Count -ne 12 -or $actual.recipeInstructions.Count -ne 5 -or $actual.cookTime -ne 'PT7H' -or $actual.recipeYield -ne '4 portions') { throw 'Protected source facts changed' }
            if (@($actual.recipeCategory | Where-Object { $_ -in @('Desserts','Cakes & baking') }).Count) { throw 'Known unsupported labels survived' }
            Write-Output ("Live protected-facts PASS [$model] (estimates still need review): prep=$($actual.prepTime), cook=$($actual.cookTime), total=$($actual.totalTime); categories=$($actual.recipeCategory -join ', '); tags=$($actual.keywords -join ', ')")
        } catch { throw "Live QA failed [$model]: $($_.Exception.Message)" }
    }
}
