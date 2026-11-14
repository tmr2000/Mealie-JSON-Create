#Requires -Version 5.1
param([switch]$Live)
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
$source=Get-Content (Join-Path $PSScriptRoot 'Tests\shepherds-pie.txt') -Raw -Encoding UTF8
$script:response=@{
    name="Traditional Shepherd's Pie";description='An invented pressure cooker curry.'
    yield='20 portions';prepTime='PT0M';cookTime='PT9H';totalTime='PT9H'
    metadataNote='Chosen for LOW; the original recipe uses a pressure cooker.'
    ingredients=@('Lamb Layer','Mash Layer');instructions=@('Bake for 2 minutes.')
    categories=@('Main courses');tags=@('British','Lamb','Pie & tart','Curry','Pressure cooker','Slow cooker')
}
$script:calls=0
function Invoke-RestMethod {
    param($Uri,$Method,$ContentType,$Body,$TimeoutSec)
    $script:calls++
    @{response=($script:response | ConvertTo-Json -Depth 12)}
}
$r=ConvertTo-RecipeJson -Text $source -UseOllama | ConvertFrom-Json
if ($r.recipeIngredient.Count -ne 21 -or $r.recipeInstructions.Count -ne 6) { throw 'Grouped ingredient/step counts failed' }
if ($r.recipeIngredient[0] -notmatch '^Lamb Layer: 1kg / 2.2lb Minced/Ground Lamb$' -or $r.recipeIngredient[15] -notmatch '^Mash Layer: 4.4lb / 2kg White Potatoes') { throw 'Group identity or quantities lost' }
if ($r.recipeInstructions[3].text -notmatch 'Preheat the oven to 200C/390F' -or $r.recipeInstructions[4].text -notmatch '20-25mins') { throw 'Cooking instructions lost' }
if ($r.prepTime -ne 'PT25M' -or $r.cookTime -ne 'PT1H25M' -or $r.totalTime -ne 'PT1H50M' -or $r.recipeYield -ne '6 - 8') { throw 'Labelled source metadata not authoritative' }
if (($r.keywords -join '|') -ne 'British|Lamb|Pie & tart' -or $r.description) { throw 'Invented labels/description survived' }
if ($r.comment -match 'original recipe uses a pressure cooker|Chosen for LOW' -or $r.comment -notmatch 'QA: 21 ingredients preserved; 6 steps preserved; 3 source time fields used; 3 unsupported selections removed') { throw 'Untrusted model note or inaccurate QA summary' }
if ($r.comment -notmatch 'Source notes:|substitute more beef stock' -or $r.comment -match '963kcal') { throw 'Source notes/boundary failure' }
# Entries are source-locked, even when model arrays are empty.
$script:response.ingredients=@();$script:response.instructions=@()
$again=ConvertTo-RecipeJson -Text $source -UseOllama | ConvertFrom-Json
if ($again.recipeIngredient.Count -ne 21 -or $again.recipeInstructions.Count -ne 6) { throw 'Empty model arrays lost source facts' }
# Ambiguous explicit sections block before contacting Ollama.
foreach ($bad in @("Ingredients\n#### Lamb Layer\nMethod\n- Cook the lamb", "Ingredients\n- 1kg lamb\nMethod")) {
    $bad=$bad.Replace('\n',"`n")
    $prior=$script:calls;$blocked=$false
    try { $null=ConvertTo-RecipeJson -Text $bad -UseOllama } catch { $blocked=$_.Exception.Message -match 'Source QA blocked' }
    if (-not $blocked -or $script:calls -ne $prior) { throw 'Ambiguous source did not fail closed before generation' }
}
$wrapped="Ingredients`n- 500g lamb`n  finely minced`nMethod`n- Fry the lamb.`n  Stir until browned.`nNotes`nUse a large pan.`nEquipment`n- Knife"
$w=ConvertTo-RecipeJson -Text $wrapped -UseOllama | ConvertFrom-Json
if ($w.recipeIngredient.Count -ne 1 -or $w.recipeIngredient[0] -notmatch 'finely minced' -or $w.recipeInstructions[0].text -notmatch 'Stir until browned') { throw 'Indented continuation lost' }
# Actual method use is required, not an equipment-list mention.
$script:response.tags=@('Pressure cooker','Slow cooker')
$used=ConvertTo-RecipeJson -Text "Ingredients`n- 500g lamb`nMethod`n- Pressure cook the lamb for 20 minutes." -UseOllama | ConvertFrom-Json
if (($used.keywords -join '|') -ne 'Pressure cooker') { throw 'Method appliance evidence failed' }
$negated=ConvertTo-RecipeJson -Text "Ingredients`n- 500g lamb`nMethod`n- Do not use a pressure cooker or slow cooker. Bake the lamb." -UseOllama | ConvertFrom-Json
if ($negated.keywords.Count) { throw 'Negated appliance evidence accepted' }
# Conflicting/physically inconsistent source labels must not be silently repaired.
foreach ($timings in @("Prep Time10 minutes`nCook Time20 minutes`nTotal Time5 minutes", "Cook Time20 minutes`nCook Time30 minutes")) {
    $blocked=$false
    try { $null=ConvertTo-RecipeJson -Text ($timings + "`n" + $wrapped) -UseOllama } catch { $blocked=$_.Exception.Message -match 'Source QA blocked' }
    if (-not $blocked) { throw 'Invalid source timing labels were not blocked' }
}
# Star bullet syntax and wrapped source text must survive italic normalisation.
$stars="Ingredients`n* 500g *lamb*`nMethod`n* Fry the lamb."
$starResult=ConvertTo-RecipeJson -Text $stars -UseOllama | ConvertFrom-Json
if ($starResult.recipeIngredient[0] -ne '500g lamb') { throw 'Star bullets/italics were not preserved correctly' }
# Plain website copy: equal indentation means new ingredients, not continuations.
$steak=Get-Content (Join-Path $PSScriptRoot 'Tests\steak-pie.txt') -Raw -Encoding UTF8
$pie=ConvertTo-RecipeJson -Text $steak -UseOllama | ConvertFrom-Json
if ($pie.recipeIngredient.Count -ne 10 -or $pie.recipeInstructions.Count -ne 7 -or $pie.recipeYield -ne '4') { throw 'Plain steak pie entries/yield lost' }
if ($pie.recipeIngredient[0] -ne '900g/2lb braising steak, cut into cubes' -or $pie.recipeIngredient[-1] -ne '1 free-range egg, beaten') { throw 'Plain ingredient boundaries changed' }
if ($pie.recipeInstructions[4].text -ne 'Preheat the oven to 190C/375F/Gas 5.' -or -not $pie.recipeInstructions[-1].text.Contains('1-1½ hours. If the pastry gets too brown, cover it with foil. Serve hot.')) { throw 'Steak pie temperatures or cooking options lost' }
# Removing common indentation does not change recipe facts or paragraph grouping.
$flat=ConvertTo-RecipeJson -Text ($steak -replace '(?m)^    ','') -UseOllama | ConvertFrom-Json
if (($flat.recipeIngredient -join '|') -ne ($pie.recipeIngredient -join '|') -or ($flat.recipeInstructions.text -join '|') -ne ($pie.recipeInstructions.text -join '|')) { throw 'Plain parsing depends on copied indentation' }
$paragraph="Ingredients`n500g beef`n1 onion`nMethod`nFry the beef.`nStir until browned.`n`nAdd the onion.`nNotes`nServe hot."
$pg=ConvertTo-RecipeJson -Text $paragraph -UseOllama | ConvertFrom-Json
if ($pg.recipeIngredient.Count -ne 2 -or $pg.recipeInstructions.Count -ne 2 -or $pg.recipeInstructions[0].text -ne 'Fry the beef. Stir until browned.') { throw 'Plain wrapped paragraphs not preserved' }
Remove-Item Function:\Invoke-RestMethod
Write-Output 'Source QA checks passed: grouped ingredients, bulleted methods, source metadata, lost-step recovery, notes, boundaries, appliance evidence, false claims and fail-closed handling.'

if ($Live) {
    foreach ($model in @(Get-OllamaModels)) {
        $actual=ConvertTo-RecipeJson -Text $source -UseOllama -Model $model | ConvertFrom-Json
        if ($actual.recipeIngredient.Count -ne 21 -or $actual.recipeInstructions.Count -ne 6 -or $actual.prepTime -ne 'PT25M' -or $actual.cookTime -ne 'PT1H25M' -or $actual.totalTime -ne 'PT1H50M' -or $actual.recipeYield -ne '6 - 8') { throw "Protected source facts failed [$model]" }
        if (@($actual.keywords | Where-Object { $_ -in @('Curry','Slow cooker','Pressure cooker') }).Count) { throw "Unsupported tag survived [$model]" }
        Write-Output "Live protected-facts PASS [$model]: 21 ingredients; 6 steps; source durations and yield retained. Classification still requires review."
    }
}
