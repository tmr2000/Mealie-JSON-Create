#Requires -Version 5.1
param([switch]$Live,[string]$Model='qwen2.5:7b',[string]$Endpoint='http://localhost:11434')
$ErrorActionPreference='Stop'
. "$PSScriptRoot\Recipe.Core.ps1"
$corpusRoot=Join-Path $PSScriptRoot 'Tests\corpus'
$cases=Get-Content (Join-Path $corpusRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$reportDirectory=Join-Path $PSScriptRoot '.qa'
[void][IO.Directory]::CreateDirectory($reportDirectory)
$mode=if ($Live) { 'live' } else { 'offline' }
$reportPath=Join-Path $reportDirectory ("recipe-corpus-$mode.json")
$results=@()
[IO.File]::WriteAllText($reportPath,'[]',[Text.UTF8Encoding]::new($false))
if (-not $Live) {
    function Invoke-RestMethod {
        param($Uri,$Method,$ContentType,$Body,$TimeoutSec)
        $request=[Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
        if ($request.format.properties.PSObject.Properties.Name -contains 'titleIds') {
            # The hand-written oracle supplies grouping in offline mode. Live mode tests the model's decisions.
            $data=$request.prompt | ConvertFrom-Json
            $plan=$script:currentCase.organisation
            $used=@{}
            function Resolve-Ids($Texts) {
                foreach ($text in $Texts) {
                    $matches=@($data.lines.PSObject.Properties | Where-Object { $_.Value -ceq $text })
                    if ($matches.Count -ne 1) { throw "Corpus grouping oracle cannot resolve: $text" }
                    $used[$matches[0].Name]=$true
                    $matches[0].Name
                }
            }
            $answer=@{titleIds=@(Resolve-Ids $plan.title);descriptionIds=@(Resolve-Ids $plan.description);ingredients=@();method=@();notesIds=@();ignoredIds=@()}
            foreach ($field in @('ingredients','method')) {
                $answer[$field]=@(foreach ($group in $plan.$field) { @{lineIds=@(Resolve-Ids $group)} })
            }
            $answer.notesIds=@(Resolve-Ids $plan.notes)
            $answer.ignoredIds=@($data.lines.PSObject.Properties.Name | Where-Object { -not $used.ContainsKey($_) })
            return @{response=($answer | ConvertTo-Json -Depth 10)}
        }
        if ($request.format.properties.PSObject.Properties.Name -contains 'tags') {
            return @{response='{"categories":[],"tags":[],"evidence":[]}'}
        }
        $answer=@{}
        foreach ($field in $request.format.required) { $answer[$field]='' }
        return @{response=($answer | ConvertTo-Json)}
    }
}
foreach ($case in $cases) {
    $script:currentCase=$case
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $failure=''
    $recipe=$null
    try {
        $text=Get-Content (Join-Path $corpusRoot $case.file) -Raw -Encoding UTF8
        $conversionError=$null
        try {
            $json=ConvertTo-RecipeJson -Text $text -SourceUrl $case.sourceUrl -UseOllama -Endpoint $Endpoint -Model $Model
            $recipe=$json | ConvertFrom-Json
        } catch { $conversionError=$_.Exception.Message }
        if ($case.expectedError) {
            if (-not $conversionError -or $conversionError -notmatch [regex]::Escape($case.expectedError)) { throw "Expected rejection '$($case.expectedError)', got '$conversionError'." }
        } else {
            if ($conversionError) { throw $conversionError }
            [IO.File]::WriteAllText((Join-Path $reportDirectory ("corpus-$mode-$($case.id).json")),$json,[Text.UTF8Encoding]::new($false))
            foreach ($field in @('ingredients','steps')) {
                $expected=@($case.$field)
                $actual=@(if ($field -eq 'ingredients') { $recipe.recipeIngredient } else { $recipe.recipeInstructions | ForEach-Object { $_.text } })
                if ($actual.Count -ne $expected.Count) { throw "$field count: expected $($expected.Count), got $($actual.Count)." }
                for ($index=0;$index -lt $expected.Count;$index++) {
                    if ($actual[$index] -cne $expected[$index]) { throw "$field entry $($index+1) changed. Expected '$($expected[$index])', got '$($actual[$index])'." }
                }
            }
            $metadataFields=@{'Total time'='totalTime';'Prep time'='prepTime';'Cook time'='cookTime';'Servings'='recipeYield';'Serves'='recipeYield'}
            foreach ($property in $case.metadata.PSObject.Properties) {
                $field=$property.Name;$expected=$property.Value
                if ($metadataFields.ContainsKey($field)) {
                    $field=$metadataFields[$field]
                    if ($field -ne 'recipeYield') { $expected='PT'+($expected -replace ' minutes','M') }
                }
                if ($recipe.$field -cne $expected) { throw "Source $field changed: expected '$expected', got '$($recipe.$field)'." }
            }
            if ($case.sourceUrl -and $recipe.url -ne $case.sourceUrl) { throw 'Source attribution lost.' }
            $config=$script:ClassificationJson | ConvertFrom-Json
            $allowedTags=@($config.tagGroups | ForEach-Object { $_.labels })
            if (@($recipe.keywords | Where-Object { $allowedTags -notcontains $_ }).Count) { throw 'Unknown tag exported.' }
            if ($recipe.recipeCategory.Count -gt 2 -or @($recipe.recipeCategory | Where-Object { $config.categories.name -notcontains $_ }).Count) { throw 'Invalid category exported.' }
        }
    } catch { $failure=$_.Exception.Message }
    $watch.Stop()
    $status=if ($failure) { 'FAIL' } else { 'PASS' }
    $result=[pscustomobject]@{id=$case.id;mode=$mode;model=$(if ($Live) {$Model} else {'mock'});status=$status;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2);error=$failure}
    $results+=$result
    [IO.File]::WriteAllText($reportPath,($results | ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
    Write-Output "$status [$mode] $($case.id) ($($result.seconds)s) $failure"
}
if (-not $Live) { Remove-Item Function:\Invoke-RestMethod }
$failures=@($results | Where-Object { $_.status -eq 'FAIL' })
if ($failures.Count) { throw "$($failures.Count)/$($cases.Count) corpus cases failed. Details: $reportPath" }
Write-Output "Recipe corpus passed $($cases.Count)/$($cases.Count) cases ($mode)."
