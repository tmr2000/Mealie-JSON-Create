param([switch]$Snapshots)
$ErrorActionPreference='Stop'
$script:takeSnapshots=$Snapshots
$script:qaFolder=Join-Path $PSScriptRoot '.qa'
$source=Get-Content "$PSScriptRoot\MealieJsonCreate.ps1" -Raw
$smoke=@'
function Get-AppUpdate { param($CurrentVersion) return }
function Get-OllamaModels {
    param($Endpoint)
    if ($Endpoint -eq 'http://localhost:11434') { 'test-model:latest';'second-model:7b';'qwen3:8b';'gemma3:4b';'mistral:latest';'deepseek-r1:8b' }
    elseif ($Endpoint -eq 'http://empty:11434') { return }
    else { throw 'Test connection failure' }
}
function ConvertTo-RecipeJson {
    param($Text,$Title,$SourceUrl,$UseOllama,$Endpoint,$Model,$ClassificationJson,$IncludeClassificationReview)
    if (-not $UseOllama) { throw 'GUI must always use Ollama' }
    if ($Text -eq 'Not a complete recipe') { throw 'Missing ingredients and method' }
    Start-Sleep -Milliseconds 300
    $json='{"name":"Tomato & basil pasta","description":"A simple supper with a rich tomato sauce.","recipeYield":"2 servings","prepTime":"PT10M","cookTime":"PT20M","totalTime":"PT30M","comment":"QA: 3 ingredients preserved; 2 steps preserved.\n\nTimes estimated.","recipeCategory":["Main courses"],"keywords":["Pasta","Italian"],"recipeIngredient":["200 g pasta","1 tin chopped tomatoes","1 handful fresh basil"],"recipeInstructions":[{"text":"Cook the pasta according to the packet instructions. Drain well, then return it to the pan."},{"text":"Add the tomatoes and stir until the pasta is coated. Fold through the basil and serve."}]}'
    if ($IncludeClassificationReview) {
        $recipe=$json | ConvertFrom-Json
        $context=[pscustomobject]@{Intro='Italian pasta main course';Source=$Text;Ingredients=@($recipe.recipeIngredient);Method=@($recipe.recipeInstructions | ForEach-Object { $_.text });Notes=@();Structured=$true;TotalTime=$recipe.totalTime;TotalIsExplicit=$false;ModelCategories=@('Main courses');ModelTags=@('Pasta','Italian');Claims=@()}
        return [pscustomobject]@{Json=$json;Context=$context;Review=(Get-RecipeClassification -Context $context -ClassificationJson $ClassificationJson)}
    }
    return $json

}
function Click-Button($Button) {
    $Button.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
}
function Save-UiSnapshot([string]$Name) {
    if (-not $script:takeSnapshots) { return }
    [void][IO.Directory]::CreateDirectory($script:qaFolder)
    $form.UpdateLayout()
    $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new([int]$form.Content.ActualWidth,[int]$form.Content.ActualHeight,96,96,[Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($form.Content)
    $encoder=New-Object Windows.Media.Imaging.PngBitmapEncoder
    $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $stream=[IO.File]::Create((Join-Path $script:qaFolder $Name))
    try { $encoder.Save($stream) } finally { $stream.Dispose() }
}
$sample=@"
Tomato & basil pasta
A simple supper with a rich tomato sauce.
Serves: 2
Ingredients
200 g pasta
1 tin chopped tomatoes
1 handful fresh basil
Method
Cook the pasta according to the packet instructions. Drain well, then return it to the pan.
Add the tomatoes and stir until the pasta is coated. Fold through the basil and serve.
"@
$check=New-Object Windows.Threading.DispatcherTimer
$check.Interval=[TimeSpan]::FromMilliseconds(250)
$script:smokeTicks=0;$script:guiStage=-3;$script:guiFailure=$null
$check.Add_Tick({
    try {
        $script:smokeTicks++
        switch ($script:guiStage) {
            -3 {
                if (-not $script:updateWorker) {
                    if ($updateButton.Visibility -ne 'Collapsed') { throw 'Update button visible without an update' }
                    function Get-AppUpdate { param($CurrentVersion) [pscustomobject]@{Version='999.0.0'} }
                    Start-AppUpdateWork 'check';$script:guiStage=-2
                }
            }
            -2 {
                if (-not $script:updateWorker) {
                    if ($updateButton.Visibility -ne 'Visible' -or $updateButton.Content -ne 'Update available' -or $updateButton.ToolTip -notlike '*999.0.0*') { throw 'Available update not displayed' }
                    function Get-AppUpdate { param($CurrentVersion) throw 'Mock network failure' }
                    Start-AppUpdateWork 'check'
                    if ($updateButton.Visibility -ne 'Collapsed') { throw 'Update button visible during checking' }
                    $script:guiStage=-1
                }
            }
            -1 {
                if (-not $script:updateWorker) {
                    if ($updateButton.Visibility -ne 'Collapsed') { throw 'Update button visible after failed check' }
                    $script:guiStage=0
                }
            }
            0 {
                if ($model.Items.Count -eq 6) {
                    if ($null -eq $form.Icon -or -not $form.Icon.IsFrozen) { throw 'Window icon failed to load' }
                    if ($model.IsEditable -or $model.SelectedItem -ne 'test-model:latest') { throw 'Model dropdown failed' }
                    if ($form.FindName('VersionText').Text -ne "v$script:AppVersion" -or $status.Text) { throw 'Version footer failed' }
                    if ($xaml.OuterXml -match 'Your next recipe starts here|RECIPE WORKSPACE|From inspiration|Paste a recipe, polish') { throw 'Removed text still present' }
                    if ($model.IsVisible) { throw 'AI controls remain on the recipe screen' }
                    if ($inputBox.Text.Length -or $copy.IsEnabled -or $null -ne $form.FindName('InputPlaceholder')) { throw 'Initial state failed' }
                    if ($paste.BorderThickness.Left -ne 1 -or $clear.BorderThickness.Left -ne 1 -or $paste.Background.ToString() -eq '#00FFFFFF') { throw 'Paste and clear button styling failed' }
                    $savedRows=$script:logicRows;$savedConfig=$script:nextClassification;$savedFile=$script:logicFile
                    $script:logicRows=@(Get-LogicRows)
                    $script:logicFile=Join-Path $env:TEMP ('mealie-settings-'+[guid]::NewGuid()+'.json')
                    try {
                        $factory=$script:factoryClassification | ConvertFrom-Json
                        $legacy=@(Get-LogicRows)
                        $legacySoup=@($legacy | Where-Object { $_.Kind -eq 'Tag' -and $_.Name -eq 'Soup' })[0]
                        $legacySoup.Logic=@($factory.tagGroups | Where-Object { $_.labels -contains 'Soup' })[0].rules
                        $customCurry=@($legacy | Where-Object { $_.Name -eq 'Curry' })[0]
                        $customCurry.Logic='My own curry instruction.'
                        $migrated=@(Update-DefaultLogicRows $legacy)
                        if (@($migrated | Where-Object Name -eq Soup)[0].Logic -eq $legacySoup.Logic -or @($migrated | Where-Object Name -eq Curry)[0].Logic -ne 'My own curry instruction.') { throw 'Legacy instruction migration lost defaults or custom edits' }
                        $defaultConfig=(ConvertTo-LogicConfig $script:logicRows) | ConvertFrom-Json
                        if ($defaultConfig.customSelections.Count -or @($defaultConfig.tagGroups | ForEach-Object { $_.labels }).Count -ne @($factory.tagGroups | ForEach-Object { $_.labels }).Count) { throw 'Default definitions treated as custom or lost labels' }
                        Click-Button $form.FindName('LogicButton')
                        $form.FindName('AiSettingsTab').IsSelected=$true;$form.UpdateLayout()
                        if (-not $model.IsVisible) { throw 'AI controls missing from settings' }
                        $model.SelectedIndex=1
                        Save-AiSettings
                        $storedAi=Get-Content $script:aiFile -Raw | ConvertFrom-Json
                        if ($storedAi.Model -ne 'second-model:7b' -or $storedAi.Endpoint -ne 'http://localhost:11434') { throw 'AI settings persistence failed' }
                        $script:preferredModel='';Read-AiSettings
                        if ($script:preferredModel -ne 'second-model:7b') { throw 'AI default did not load' }
                        Click-Button $form.FindName('LogicCancel')
                        if ($model.SelectedItem -ne 'test-model:latest') { throw 'Cancel did not restore model selection' }
                        Click-Button $form.FindName('LogicButton')
                        $model.SelectedIndex=0
                        $form.FindName('AiSettingsTab').IsSelected=$false
                        $form.FindName('AiSettingsTab').Parent.SelectedIndex=0
                        $soup=@($form.FindName('TagRows').Children | Where-Object { $_.Content -eq 'Soup' })[0]
                        $curry=@($form.FindName('TagRows').Children | Where-Object { $_.Content -eq 'Curry' })[0]
                        Click-Button $soup;$soupText=$form.FindName('TagRule').Text
                        Click-Button $curry
                        if ($soupText -eq $form.FindName('TagRule').Text -or $soupText -notmatch 'Select Soup' -or $form.FindName('TagRule').Text -notmatch 'Select Curry') { throw 'Per-tag instructions or GUI selection incorrect' }
                        $form.UpdateLayout()
                        $chips=$form.FindName('TagRows').Children
                        if (-not $chips.Count -or -not $chips[0].IsVisible -or $chips[0].ActualWidth -lt 10 -or $chips[0].ActualHeight -lt 10) { throw 'Tag list not visible' }
                        Save-UiSnapshot 'settings-tags.png'
                        Click-Button $form.FindName('AddTag')
                        $new=$form.FindName('TagRows').Children | Select-Object -Last 1
                        $form.FindName('TagName').Text='Test tag';$form.FindName('TagRule').Text='Select for a test recipe.'
                        $first=$form.FindName('CategoryRows').Children[0]
                        Click-Button $first
                        $form.FindName('CategoryName').Text='Morning meals'
                        Click-Button $form.FindName('LogicSave')
                        if (-not [IO.File]::Exists($script:logicFile)) { throw ('Settings save failed: '+$status.Text) }
                        $stored=Get-Content $script:logicFile -Raw | ConvertFrom-Json
                        $settings=(ConvertTo-LogicConfig $stored) | ConvertFrom-Json
                        if ($settings.categories.name -notcontains 'Morning meals' -or $settings.customSelections -notcontains 'tags|Test tag') { throw 'Settings round trip failed' }
                        Click-Button $form.FindName('LogicButton')
                        $last=$form.FindName('TagRows').Children | Select-Object -Last 1
                        if ($form.FindName('TagDetail').Visibility -ne 'Collapsed') { throw 'Settings should open with only names visible' }
                        Click-Button $last
                        if ($form.FindName('TagRule').Text -ne 'Select for a test recipe.') { throw 'Selected rule missing' }
                        Click-Button $form.FindName('RemoveTag')
                        Click-Button $form.FindName('LogicSave')
                        if (($script:nextClassification | ConvertFrom-Json).customSelections -contains 'tags|Test tag') { throw "Tag removal failed: $($status.Text); rows=$($form.FindName('TagRows').Children.Count)" }
                    } finally {
                        Remove-Item -LiteralPath $script:logicFile,($script:logicFile+'.bak') -ErrorAction SilentlyContinue
                        $script:logicFile=$savedFile;$script:logicRows=$savedRows;$script:nextClassification=$savedConfig
                    }
                    Save-UiSnapshot 'empty.png'
                    Click-Button $convert
                    if ($status.Text -ne 'Paste a recipe to get started.') { throw 'Empty input validation failed' }
                    $model.SelectedIndex=1;Save-AiSettings
                    $model.SelectedIndex=-1;Read-AiSettings
                    Click-Button $refresh;$script:guiStage=1
                }
            }
            1 {
                if (-not $script:modelWorker) {
                    if ($model.SelectedItem -ne 'second-model:7b') { throw 'Selection not preserved' }
                    Click-Button $form.FindName('LogicButton')
                    $form.FindName('AiSettingsTab').IsSelected=$true;$form.UpdateLayout()
                    $model.IsDropDownOpen=$true;$script:guiStage=2
                }
            }
            2 {
                if (-not $model.IsDropDownOpen) { throw 'Dropdown did not open' }
                $last=$model.ItemContainerGenerator.ContainerFromIndex(5)
                if ($null -eq $last -or -not $last.IsVisible -or $last.ActualHeight -le 0) { throw 'Multiple models are not visible in dropdown' }
                $model.SelectedIndex=5
                if ($model.SelectedItem -ne 'deepseek-r1:8b') { throw 'Last model cannot be selected' }
                $model.IsDropDownOpen=$false
                Click-Button $form.FindName('LogicCancel')
                if ($null -ne $form.FindName('OllamaToggle') -or $inputStage.Visibility -ne 'Visible' -or $outputStage.Visibility -ne 'Collapsed') { throw 'Mandatory Ollama/input stage failed' }
                $endpoint.Text='http://empty:11434';$script:guiStage=3
            }
            3 {
                if ($modelStatus.Text -like 'No models*') {
                    if ($model.Items.Count -ne 0 -or $model.IsEnabled) { throw 'Empty model list failed' }
                    $endpoint.Text='http://failed:11434';$script:guiStage=4
                }
            }
            4 {
                if ($modelStatus.Text -like 'Cannot connect*') {
                    $title.Text='Tomato & basil pasta';$source.Text='https://example.com/pasta'
                    $inputBox.Text=$sample
                    if (-not $clear.IsEnabled) { throw 'Input state failed' }
                    Click-Button $convert
                    if ($script:worker -or $status.Text -notlike 'Select an available*') { throw 'Missing model did not block conversion' }
                    $endpoint.Text='http://localhost:11434';$script:guiStage=10
                }
            }
            5 {
                if ($copy.IsEnabled) {
                    if ($generationProgress.IsIndeterminate -or $generationProgress.Visibility -ne 'Collapsed') { throw 'Progress bar still running after success' }
                    $r=$outputBox.Text | ConvertFrom-Json
                    if ($r.name -ne 'Tomato & basil pasta' -or $r.recipeIngredient.Count -ne 3) { throw 'GUI conversion failed' }
                    if ($preview.Children.Count -lt 3 -or $outputPlaceholder.Visibility -ne 'Collapsed' -or -not $save.IsEnabled) { throw 'Recipe preview failed' }
                    $r | Add-Member -NotePropertyName recipeCategory -NotePropertyValue @('Main courses') -Force
                    $r | Add-Member -NotePropertyName keywords -NotePropertyValue @('Pasta','Italian') -Force
                    Show-RecipePreview ($r | ConvertTo-Json -Depth 12)
                    $chipText=@($metadata.Children | Where-Object { $_ -is [Windows.Controls.WrapPanel] } | ForEach-Object { $_.Children } | ForEach-Object { $_.Child.Text })
                    if (@($metadata.Children | Where-Object { $_ -is [Windows.Controls.TextBlock] -and $_.Text -eq 'QA SUMMARY' }).Count -ne 1 -or $chipText -notcontains '3 ingredients preserved; 2 steps preserved.') { throw 'QA summary not presented separately' }
                    if ($chipText -notcontains 'Main courses' -or $chipText -notcontains 'Italian') { throw 'Classification chips failed' }
                    if ($inputStage.Visibility -ne 'Collapsed' -or $outputStage.Visibility -ne 'Visible') { throw 'Output stage failed' }
                    $endpoint.Text='http://localhost:11434';$script:guiStage=6
                } elseif ($status.Text -like 'Conversion failed*') { throw $status.Text }
            }
            6 {
                if (-not $script:modelWorker -and $model.Items.Count -eq 6) {
                    if ($status.Text -notlike 'Recipe ready*') { throw 'Model discovery overwrote conversion status' }
                    Save-UiSnapshot 'recipe.png'
                    $script:classificationContext | Add-Member -NotePropertyName ContradictionDecisions -NotePropertyValue @([pscustomobject]@{tag='No cook';action='remove';reason='Old method';evidence='Old text'}) -Force
                    Open-DetailEditor 'timing'
                    Click-Button $form.FindName('EditorApply')
                    if ($script:classificationContext.ContradictionDecisions.Count) { throw 'Timing confirmation retained stale model decisions' }
                    if (-not $script:classificationContext.TotalIsExplicit -or -not $script:classificationStale) { throw 'Applying unchanged timings did not confirm estimated total' }
                    Invoke-ClassificationRecheck
                    if (($outputBox.Text | ConvertFrom-Json).keywords -notcontains 'Quick (30 minutes or less)') { throw 'Confirmed qualifying total did not update Quick' }
                    $script:detailInputs.recipeYield.Text='6 servings'
                    $script:detailInputs.prepTime.Text=''
                    $script:detailInputs.cookTime.Text='25'
                    $script:detailInputs.totalTime.Text='35'
                    foreach ($choice in $script:detailChoices.keywords) { $choice.IsChecked=([string]$choice.Content -eq 'Soup') }
                    foreach ($choice in $script:detailChoices.recipeCategory) { $choice.IsChecked=$false }
                    if ($copy.IsEnabled -or $save.IsEnabled) { throw 'Pending edits allow export' }
                    Click-Button $script:applyDetails
                    $edited=$outputBox.Text | ConvertFrom-Json
                    if ($edited.recipeYield -ne '6 servings' -or $edited.prepTime -or $edited.cookTime -ne 'PT25M' -or $edited.recipeCategory.Count -or $edited.keywords.Count -ne 1 -or $edited.keywords[0] -ne 'Soup' -or -not $copy.IsEnabled) { throw 'Manual detail edits failed' }
                    $script:detailInputs.totalTime.Text='invalid';Click-Button $script:applyDetails
                    if ($copy.IsEnabled -or $outputBox.Text -notmatch '6 servings') { throw 'Invalid edit was applied' }
                    $script:detailInputs.totalTime.Text='35';Click-Button $script:applyDetails
                    if ($form.FindName('OutputTabs').Items.Count -ne 3) { throw 'Ingredients/Recipe/JSON tabs missing' }
                    if (@($metadata.Children | Where-Object { $_ -is [Windows.Controls.DockPanel] }).Count -ne 4) { throw 'Section edit buttons missing' }
                    $beforeEditor=$outputBox.Text
                    Open-DetailEditor 'yield'
                    if ($script:detailInputs.prepTime.Visibility -ne 'Collapsed' -or $script:detailInputs.recipeYield.Visibility -ne 'Visible') { throw 'Editor did not isolate yield' }
                    if ($form.OwnedWindows.Count -or $form.FindName('EditorStage').Visibility -ne 'Visible' -or $copy.IsEnabled -or $back.IsEnabled) { throw 'Editor is not inline or exports enabled' }
                    $script:detailInputs.recipeYield.Text='Discard this'
                    Click-Button $form.FindName('EditorCancel')
                    if ($outputBox.Text -ne $beforeEditor -or -not $copy.IsEnabled) { throw 'Cancel changed metadata or export state' }
                    Open-DetailEditor 'timing'
                    $script:detailInputs.cookTime.Text='26'
                    Click-Button $script:applyDetails
                    if (($outputBox.Text | ConvertFrom-Json).cookTime -ne 'PT26M') { throw 'Inline timing editor failed' }
                    Open-DetailEditor 'tags'
                    Save-UiSnapshot 'tags-editor.png'
                    $choice=$script:detailChoices.keywords[0]
                    $choice.ApplyTemplate()
                    if (-not $choice.Template.FindName('TickBox',$choice)) { throw 'Themed checkbox template missing' }
                    Click-Button $form.FindName('EditorCancel')
                    Open-ContentEditor 'ingredients'
                    if ($script:contentRows.Children.Count -ne 3 -or $form.OwnedWindows.Count) { throw 'Ingredient rows missing or window spawned' }
                    $script:contentRows.Children[0].Tag.Text='250 g pasta'
                    $script:contentRows.Children[1].Tag.Text='2 tomatoes'
                    Click-Button $script:contentRows.Children[2].Children[0]
                    Click-Button $form.FindName('EditorApply')
                    $script:classificationContext.ContradictionDecisions=@([pscustomobject]@{tag='No cook';action='remove';reason='Old method';evidence='Old text'})
                    Open-ContentEditor 'method'
                    if ($script:contentRows.Children.Count -ne 2) { throw 'Individual method steps missing' }
                    $script:contentRows.Children[0].Tag.Text="Boil the pasta.`nKeep a little cooking water."
                    $script:contentRows.Children[1].Tag.Text='Add tomatoes and serve.'
                    Add-ContentEditorRow 'Finish with basil.'
                    Save-UiSnapshot 'method-editor.png'
                    $form.Width=$form.MinWidth;$form.Height=$form.MinHeight
                    Save-UiSnapshot 'editor-compact.png'
                    foreach ($control in @($form.FindName('EditorApply'),$form.FindName('EditorCancel'),$form.FindName('EditorScroll'))) {
                        $p=$control.TranslatePoint([Windows.Point]::new(0,0),$form)
                        if ($p.X -lt 0 -or $p.Y -lt 0 -or $p.X+$control.ActualWidth -gt $form.ActualWidth -or $p.Y+$control.ActualHeight -gt $form.ActualHeight) { throw 'Inline editor clipped at minimum size' }
                    }
                    Click-Button $form.FindName('EditorApply')
                    $edited=$outputBox.Text | ConvertFrom-Json
                    if ($script:classificationContext.ContradictionDecisions.Count) { throw 'Content edits retained stale model decisions' }
                    if ($edited.recipeIngredient.Count -ne 2 -or $edited.recipeInstructions.Count -ne 3 -or $edited.recipeInstructions[0].text -notmatch 'cooking water' -or $edited.comment -notmatch 'Manual edits:') { throw 'Content edits failed' }
                    $before=$outputBox.Text
                    Open-ContentEditor 'method'
                    $script:contentRows.Children[0].Tag.Text=''
                    Click-Button $form.FindName('EditorApply')
                    if ($outputBox.Text -ne $before -or $copy.IsEnabled -or -not $form.FindName('EditorError').Text) { throw 'Empty step applied or error missing' }
                    Click-Button $form.FindName('EditorCancel')
                    Open-ContentEditor 'ingredients'
                    $script:contentRows.Children.Clear()
                    Click-Button $form.FindName('EditorApply')
                    if ($outputBox.Text -ne $before -or $copy.IsEnabled) { throw 'Empty ingredients changed export' }
                    Click-Button $form.FindName('EditorCancel')
                    if (-not $script:classificationStale -or -not $script:classificationReview) { throw 'Content edit did not invalidate classification evidence' }
                    Open-DetailEditor 'tags'
                    foreach ($choice in $script:detailChoices.keywords) { $choice.IsChecked=([string]$choice.Content -eq 'Soup') }
                    Click-Button $form.FindName('EditorApply')
                    Invoke-ClassificationRecheck
                    $rechecked=$outputBox.Text | ConvertFrom-Json
                    if ($script:classificationStale -or $rechecked.keywords -notcontains 'Soup' -or $rechecked.keywords -contains 'Pasta') { throw 'Recheck lost manual additions/removals' }
                    if ($rechecked.PSObject.Properties.Name -contains 'Context' -or $rechecked.PSObject.Properties.Name -contains 'Review') { throw 'Internal review data leaked into JSON' }
                    Open-DetailEditor 'tags';Save-UiSnapshot 'classification-evidence.png';Click-Button $form.FindName('EditorCancel')
                    $form.FindName('OutputTabs').SelectedIndex=1;Save-UiSnapshot 'recipe-steps.png'
                    $form.FindName('OutputTabs').SelectedIndex=2;$script:guiStage=7
                }
            }
            7 { Save-UiSnapshot 'json.png';$form.Width=$form.MinWidth;$form.Height=$form.MinHeight;$script:guiStage=8 }
            8 {
                Save-UiSnapshot 'compact.png'
                foreach ($control in @($back,$copy,$save,$metadata.Parent,$outputBox)) {
                    $p=$control.TranslatePoint([Windows.Point]::new(0,0),$form)
                    if ($p.X -lt 0 -or $p.Y -lt 0 -or ($p.X+$control.ActualWidth) -gt $form.ActualWidth -or ($p.Y+$control.ActualHeight) -gt $form.ActualHeight) { throw "Control $($control.Name) clipped at minimum size" }
                }
                Click-Button $back
                    if ($inputStage.Visibility -ne 'Visible' -or $inputBox.Text -ne $sample -or $title.Text -ne 'Tomato & basil pasta' -or $source.Text -ne 'https://example.com/pasta' -or $model.SelectedItem -ne 'second-model:7b') { throw 'Back lost input or saved default model' }
                $form.UpdateLayout()
                foreach ($control in @($convert,$inputBox,$paste,$clear)) {
                    $p=$control.TranslatePoint([Windows.Point]::new(0,0),$form)
                    if (-not $control.IsVisible -or $control.ActualWidth -le 0 -or $p.X+$control.ActualWidth -gt $form.ActualWidth -or $p.Y+$control.ActualHeight -gt $form.ActualHeight) { throw 'Input stage control clipped' }
                }
                Save-UiSnapshot 'input-compact.png'
                Click-Button $clear
                if ($inputBox.Text.Length -or $clear.IsEnabled) { throw 'Clear text failed' }
                $inputBox.Text='Not a complete recipe';Click-Button $convert;$script:guiStage=9
            }
            10 {
                if (-not $script:modelWorker -and $model.Items.Count -eq 6) {
                    Click-Button $convert
                    if ($outputStage.Visibility -ne 'Visible' -or $inputStage.Visibility -ne 'Collapsed' -or $copy.IsEnabled) { throw 'Conversion progress stage failed' }
                    if (-not $generationProgress.IsIndeterminate -or $generationProgress.Visibility -ne 'Visible') { throw 'Progress bar not running during conversion' }
                    Save-UiSnapshot 'progress.png'
                    $script:guiStage=5
                }
            }
            9 {
                if ($status.Text -like 'Conversion failed*') {
                    if ($generationProgress.IsIndeterminate -or $generationProgress.Visibility -ne 'Collapsed') { throw 'Progress bar still running after failure' }
                    if ($copy.IsEnabled -or $save.IsEnabled -or $preview.Children.Count) { throw 'Stale output left enabled after failure' }
                    Write-Host 'WPF checks passed: model discovery, updates, conversion, Ingredients/Recipe/JSON tabs, inline editors, per-entry fields, themed checkboxes, apply/cancel, validation, compact layout and navigation.'
                    $check.Stop();$form.Close()
                }
            }
        }
        if ($script:smokeTicks -gt 100) { throw "GUI checks timed out at stage $script:guiStage. Status: $($status.Text)" }
    } catch { $script:guiFailure=$_;$check.Stop();$form.Close() }
})
$check.Start()
[void]$form.ShowDialog()
$check.Stop()
if ($script:guiFailure) { throw $script:guiFailure }
'@
$source=$source.Replace('[void]$form.ShowDialog()',$smoke)
$source=$source.Replace('. "$PSScriptRoot\Recipe.Core.ps1"',(". '" + $PSScriptRoot + "\Recipe.Core.ps1'"))
foreach ($file in @('Recipe.Update.ps1','Recipe.UpdateUi.ps1')) {
    $source=$source.Replace(('. "$PSScriptRoot\' + $file + '"'),(". '" + $PSScriptRoot.Replace("'","''") + '\' + $file + "'"))
}
$iconPath=Join-Path $PSScriptRoot 'Assets\MealieJsonCreate.ico'
$source=$source.Replace("(Join-Path `$PSScriptRoot 'Assets\MealieJsonCreate.ico')", ("'" + $iconPath.Replace("'", "''") + "'"))
$testAiFile=Join-Path $env:TEMP ('mealie-ai-'+[guid]::NewGuid()+'.json')
$source=[regex]::Replace($source, '(?m)^\$script:aiFile=.*$', ('$script:aiFile=' + "'" + $testAiFile.Replace("'","''") + "'"))
try { & ([scriptblock]::Create($source)) }
finally { if ([IO.File]::Exists($testAiFile)) { [IO.File]::Delete($testAiFile) } }
