#Requires -Version 5.1
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
$configuration=$script:ClassificationJson | ConvertFrom-Json
$approvedTags=@($configuration.tagGroups | ForEach-Object { $_.labels })
foreach ($name in $approvedTags) {
    $definition=@($configuration.tagDefinitions | Where-Object { $_.name -ceq $name })
    if ($definition.Count -ne 1 -or [string]::IsNullOrWhiteSpace($definition[0].description)) { throw "Missing or duplicate tag definition: $name" }
}
if (@($configuration.tagDefinitions.description | Select-Object -Unique).Count -ne $approvedTags.Count) { throw 'Tag-specific default instructions are duplicated' }
function New-Context {
    param([string]$Intro='Unidentified dish',[string[]]$Ingredients=@(),[string[]]$Method=@('Prepare and serve.'),[string[]]$Tags=@(),[string[]]$Categories=@())
    [pscustomobject]@{Intro=$Intro;Source=$Intro;Ingredients=$Ingredients;Method=$Method;Notes=@();Structured=$true;TotalTime='';TotalIsExplicit=$false;ModelTags=$Tags;ModelCategories=$Categories;Claims=@()}
}
function Decision($Result,[string]$Label) { @($Result.Decisions | Where-Object { $_.Label -eq $Label })[0] }
$context=New-Context -Intro "Traditional British shepherd's pie with lamb" -Ingredients @('Lamb Layer: 1kg minced lamb','625 ml beef stock','2kg potatoes','50 g butter')
$context.TotalTime='PT1H50M';$context.TotalIsExplicit=$true
$result=Get-RecipeClassification $context
foreach ($label in @('British','Lamb','Pie & tart')) { if ($result.Tags -notcontains $label) { throw "Missed supported tag: $label" } }
if ($result.Categories -notcontains 'Main courses' -or $result.Tags -contains 'Beef' -or $result.Tags -contains 'Quick (30 minutes or less)') { throw 'Shepherd pie roles/timing failed' }
if ((Decision $result 'Beef').Evidence -ne '625 ml beef stock' -or (Decision $result 'Beef').Status -ne 'excluded') { throw 'Stock evidence or exclusion lost' }
if ((Decision $result 'Lamb').Evidence -ne 'Lamb Layer: 1kg minced lamb') { throw 'Raw source evidence not retained' }
if ((Decision $result 'Vegetarian').Status -ne 'excluded') { throw 'Meat contradiction missed' }
$context=New-Context -Intro 'Chicken curry' -Ingredients @('500g chicken','1 onion') -Method @('Place the chicken in the slow cooker. Cook on LOW.')
$result=Get-RecipeClassification $context
foreach ($label in @('Curry','Chicken','Slow cooker')) { if ($result.Tags -notcontains $label) { throw "Missing-model-tag recovery failed: $label" } }
$context=New-Context -Intro 'Chicken curry' -Ingredients @('500g chicken thighs','1 chicken stock cube','1 tin coconut milk','1 tin chickpeas') -Tags @('Chicken','Vegetarian','Vegan')
$result=Get-RecipeClassification $context
if ($result.Tags -contains 'Vegetarian' -or $result.Tags -contains 'Vegan' -or $result.Tags -notcontains 'Chicken') { throw 'Chicken curry kept contradictory automatic dietary tags' }
$custom=$script:ClassificationJson | ConvertFrom-Json
$custom | Add-Member -NotePropertyName customSelections -NotePropertyValue @('tags|Vegetarian')
$result=Get-RecipeClassification $context -ClassificationJson ($custom | ConvertTo-Json -Depth 16)
if ($result.Tags -contains 'Vegetarian') { throw 'Custom dietary prompt bypassed ingredient contradiction check' }
$result=Get-RecipeClassification $context -Overrides @{'tags|Vegetarian'=$true}
if ($result.Tags -notcontains 'Vegetarian') { throw 'Deliberate manual choice was lost' }
$context=New-Context -Intro 'Beef soup' -Ingredients @('500 ml beef stock','10 g herbs')
$result=Get-RecipeClassification $context
if ($result.Tags -contains 'Beef') { throw 'Dish title turned stock into a main ingredient' }
$context=New-Context -Intro 'Tomato soup' -Ingredients @('1 tbsp soy sauce','2 tomatoes') -Tags @('Chinese','Make ahead','Freezer friendly')
$context.Source="Tomato soup`nDo not freeze. Never prepare in advance."
$result=Get-RecipeClassification $context
if ($result.Tags -notcontains 'Chinese' -or $result.Tags -notcontains 'Make ahead' -or (Decision $result 'Freezer friendly').Status -ne 'excluded') { throw 'Unsupported cuisine or negated planning exported' }
if ((Decision $result 'Chinese').Status -ne 'review') { throw 'Uncertain cuisine suggestion not retained for review' }
$context.Source="Tomato soup`nPrepare the soup in advance.`nFreeze in portions."
$result=Get-RecipeClassification $context
if ($result.Tags -notcontains 'Make ahead' -or $result.Tags -notcontains 'Freezer friendly') { throw 'Affirmative planning guidance missed' }
$context.TotalTime='PT25M'
$result=Get-RecipeClassification $context
if ($result.Tags -notcontains 'Quick (30 minutes or less)' -or (Decision $result 'Quick (30 minutes or less)').Status -ne 'review') { throw 'Estimated Quick exported without review' }
$context.TotalIsExplicit=$true
$result=Get-RecipeClassification $context
if ($result.Tags -notcontains 'Quick (30 minutes or less)') { throw 'Explicit Quick not selected' }
$context.TotalTime=''
$result=Get-RecipeClassification $context
if ($result.Tags -contains 'Quick (30 minutes or less)') { throw 'Missing total qualified for Quick' }
$context=New-Context -Intro 'Vegan lentil soup' -Ingredients @('200g lentils','200ml coconut milk','1 tbsp peanut butter','100g vegan chicken') -Tags @('Vegetarian','Vegan')
$result=Get-RecipeClassification $context
if ($result.Tags -notcontains 'Vegan' -or $result.Tags -contains 'Chicken') { throw 'Plant alternatives misclassified' }
$context.Ingredients+= 'Optional: 100g bacon'
$result=Get-RecipeClassification $context
if ($result.Tags -contains 'Vegan' -or $result.Tags -contains 'Vegetarian' -or (Decision $result 'Vegan').Status -ne 'excluded') { throw 'Optional meat ignored' }
$context=New-Context -Intro 'Pasta' -Ingredients @('200g pasta','50g parmesan') -Tags @('Vegetarian')
$result=Get-RecipeClassification $context
if ($result.Tags -notcontains 'Vegetarian' -or (Decision $result 'Vegetarian').Status -ne 'review') { throw 'Ambiguous cheese certified' }
$context=New-Context -Intro 'Lamb stew' -Ingredients @('500g lamb') -Method @('Do not use a slow cooker. Bake the lamb.') -Tags @('Slow cooker')
$result=Get-RecipeClassification $context
if ($result.Tags -notcontains 'Slow cooker' -or (Decision $result 'Slow cooker').Status -ne 'excluded') { throw 'Negated method exported' }
$context.Method=@('Alternatively, place the lamb in a slow cooker.')
$result=Get-RecipeClassification $context
if ($result.Tags -notcontains 'Slow cooker' -or (Decision $result 'Slow cooker').Status -ne 'review') { throw 'Optional appliance automatically selected' }
$context=New-Context -Intro 'No cook salad' -Ingredients @('1 potato') -Method @('Boil the potato.')
$result=Get-RecipeClassification $context
if ($result.Tags -notcontains 'No cook' -or (Decision $result 'No cook').Status -ne 'review') { throw 'Contradictory no-cook identity exported' }
$context=New-Context -Intro 'Soup' -Ingredients @('2 carrots')
$context.Claims=@([pscustomobject]@{field='tags';label='British';scope='intro';quote='Invented British quote'})
$result=Get-RecipeClassification $context
if ((Decision $result 'British').Evidence -or (Decision $result 'British').Candidate) { throw 'Invented citation accepted' }
$context.Claims=@([pscustomobject]@{field='tags';label='British';scope=@('intro','ingredients');quote='2 carrots'})
$malformed=Get-RecipeClassification $context
if ((Decision $malformed 'British').Candidate) { throw 'Malformed optional evidence was accepted' }
$context.Claims=@([pscustomobject]@{field='tags';label='British';scope='ingredients';quote='2 carrots'})
$result=Get-RecipeClassification $context
if ((Decision $result 'British').Status -ne 'review' -or $result.Tags -notcontains 'British') { throw 'Exact quotation treated as proof of cuisine' }
$overrides=@{'tags|Soup'=$false;'tags|British'=$true}
$result=Get-RecipeClassification $context -Overrides $overrides
if ($result.Tags -contains 'Soup' -or $result.Tags -notcontains 'British' -or (Decision $result 'British').Origin -ne 'manual') { throw 'Manual inclusion/removal lost on recheck' }
$context=New-Context -Intro 'Breakfast pancake snack dessert cake' -Ingredients @('1 egg')
$result=Get-RecipeClassification $context
if ($result.Categories.Count -gt 2 -or @($result.Decisions | Where-Object { $_.Field -eq 'categories' -and $_.Status -eq 'review' }).Count -lt 3) { throw 'Ambiguous multi-category selection was forced' }
# Report is separate from schema.org JSON; default callers retain the JSON-string contract.
function Invoke-RestMethod {
    param($Uri,$Method,$ContentType,$Body,$TimeoutSec)
    $request=[Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
    $script:stageRequests+=@($request)
    @{response='{"name":"Chicken curry","description":"","yield":"","prepTime":"","cookTime":"","totalTime":"","metadataNote":"","categories":[],"tags":[],"ingredients":[],"instructions":[]}'}
}
$source="Chicken curry`nIngredients`n500g chicken`nMethod`nSimmer the chicken."
$script:stageRequests=@()
$wrapped=ConvertTo-RecipeJson -Text $source -UseOllama -IncludeClassificationReview
if ($script:stageRequests.Count -ne 3 -or $script:stageRequests[0].format.required -notcontains 'prepTime' -or $script:stageRequests[1].format.required -notcontains 'evidence' -or $script:stageRequests[1].prompt -match 'sourcePattern') { throw 'Stage routing failed' }
$payload=$script:stageRequests[1].prompt | ConvertFrom-Json
$definitions=@($payload.tagGroups | ForEach-Object { $_.definitions })
$soupRule=@($definitions | Where-Object name -eq Soup)[0].description
$curryRule=@($definitions | Where-Object name -eq Curry)[0].description
if ($soupRule -eq $curryRule -or $soupRule -notmatch 'Select Soup' -or $curryRule -notmatch 'Select Curry') { throw 'Classification request lost per-tag definitions' }
$json=$wrapped.Json | ConvertFrom-Json
if ($json.keywords -notcontains 'Chicken' -or $json.keywords -notcontains 'Curry' -or -not $wrapped.Review -or -not $wrapped.Context) { throw 'Conversion engine integration failed' }
if ($json.PSObject.Properties.Name -contains 'Review' -or $json.PSObject.Properties.Name -contains 'Context') { throw 'Internal evidence leaked into Mealie JSON' }
$custom=$script:ClassificationJson | ConvertFrom-Json
$custom.tagGroups+=@([pscustomobject]@{group='Custom';labels=@('Test tag');rules='Select only for this custom test.'})
$script:stageRequests=@()
$null=ConvertTo-RecipeJson -Text $source -UseOllama -ClassificationJson ($custom | ConvertTo-Json -Depth 16)
$customPayload=$script:stageRequests[1].prompt | ConvertFrom-Json
$customDefinition=@($customPayload.tagGroups | Where-Object group -eq Custom)[0].definitions[0].description
if ($customDefinition -ne 'Select only for this custom test.') { throw 'Custom tag instruction did not reach classification request' }
$plain=ConvertTo-RecipeJson -Text $source -UseOllama
if ($plain -isnot [string]) { throw 'JSON API compatibility failed' }
Write-Output 'Classification checks passed: missed tags, scoped evidence, central roles, planning, estimates, dietary conflicts, plant alternatives, citations, manual overrides, category limits and conversion integration.'

# Exercise the focused check through the normal conversion entry point.
$script:contradictionMode='valid'
function Invoke-RestMethod {
    param($Uri,$Method,$ContentType,$Body,$TimeoutSec)
    $request=[Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
    if ($request.format.properties.PSObject.Properties.Name -contains 'decisions') {
        $data=$request.prompt | ConvertFrom-Json
        if ($script:contradictionMode -ne 'plant' -and $data.tags -contains 'Vegan') { throw 'Deterministic dietary exclusion was bypassed' }
        $decisions=@(foreach ($tag in $data.tags) {
            $action=if ($tag -eq 'No cook') { 'remove' } else { 'keep' }
            $ids=if ($action -eq 'remove') { @('M1') } else { @('I1') }
            if ($script:contradictionMode -eq 'invalid') { $ids=@('M999') }
            [pscustomobject]@{tag=$tag;action=$action;reason='Compare with the supplied cooking method.';evidenceIds=@($ids)}
        })
        if ($script:contradictionMode -eq 'missing') { $decisions=@($decisions | Select-Object -Skip 1) }
        if ($script:contradictionMode -eq 'duplicate') { $decisions+=@($decisions[0]) }
        return @{response=(@{decisions=$decisions} | ConvertTo-Json -Depth 8)}
    }
    if ($script:contradictionMode -eq 'plant') { return @{response='{"categories":["Main courses"],"tags":["Vegetarian","Vegan"],"evidence":[]}'} }
    return @{response='{"categories":["Main courses"],"tags":["Chicken","Vegetables","No cook","Vegan"],"evidence":[]}'}
}
$source="Chicken vegetable stew`nServes 4`nPrep time: 10 minutes`nCook time: 20 minutes`nTotal time: 30 minutes`nIngredients`n500g chicken`n2 carrots`nMethod`nSimmer the chicken and carrots for 20 minutes."
$checked=ConvertTo-RecipeJson -Text $source -UseOllama -IncludeClassificationReview
$recipe=$checked.Json | ConvertFrom-Json
if ($recipe.keywords -notcontains 'Chicken' -or $recipe.keywords -notcontains 'Vegetables' -or $recipe.keywords -contains 'No cook' -or $recipe.keywords -contains 'Vegan') { throw 'Focused contradiction resolution lost compatible tags or kept contradictions' }
if ((Decision $checked.Review 'No cook').Evidence -notmatch 'Simmer' -or (Decision $checked.Review 'No cook').Reason -notmatch 'Model contradiction') { throw 'Contradiction evidence not displayed in decision report' }
$again=Get-RecipeClassification -Context $checked.Context
if ($again.Tags -contains 'No cook') { throw 'Local recheck lost model resolution' }
$manual=Get-RecipeClassification -Context $checked.Context -Overrides @{'tags|No cook'=$true}
if ($manual.Tags -notcontains 'No cook') { throw 'Model resolution overrode manual selection' }
foreach ($mode in @('invalid','duplicate')) {
$script:contradictionMode=$mode
$invalid=ConvertTo-RecipeJson -Text $source -UseOllama | ConvertFrom-Json
if ($invalid.keywords -notcontains 'No cook' -or $invalid.comment -notmatch 'contradiction check unavailable or invalid') { throw 'Invalid model review changed tags or hid its failure' }
}
Write-Output 'Focused contradiction checks passed: compatible labels, evidence-backed removal, dietary checks, manual overrides, recheck and invalid-response fallback.'

$script:contradictionMode='plant'
$plantSource=$source.Replace('Chicken vegetable stew','Lentil stew').Replace('500g chicken','200g lentils').Replace('chicken and carrots','lentils and carrots')
$plant=ConvertTo-RecipeJson -Text $plantSource -UseOllama | ConvertFrom-Json
if ($plant.keywords -notcontains 'Vegan' -or $plant.keywords -notcontains 'Vegetarian') { throw 'Compatible Vegan and Vegetarian tags were removed' }

$script:contradictionMode='missing'
$partial=ConvertTo-RecipeJson -Text $source -UseOllama -IncludeClassificationReview
if (($partial.Json | ConvertFrom-Json).keywords -contains 'No cook' -or -not @($partial.Review.Decisions | Where-Object { $_.Reason -match 'returned no decision' }).Count) { throw 'Missing model decision lost valid removals or was not flagged' }
