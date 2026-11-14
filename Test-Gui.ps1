param([switch]$Snapshots)
$ErrorActionPreference='Stop'
$script:takeSnapshots=$Snapshots
$script:qaFolder=Join-Path $PSScriptRoot '.qa'
$source=Get-Content "$PSScriptRoot\MealieJsonCreate.ps1" -Raw
$smoke=@'
function Get-OllamaModels {
    param($Endpoint)
    if ($Endpoint -eq 'http://localhost:11434') { 'test-model:latest';'second-model:7b';'qwen3:8b';'gemma3:4b';'mistral:latest';'deepseek-r1:8b' }
    elseif ($Endpoint -eq 'http://empty:11434') { return }
    else { throw 'Test connection failure' }
}
function ConvertTo-RecipeJson {
    param($Text,$Title,$SourceUrl,$UseOllama,$Endpoint,$Model,$ClassificationJson)
    if (-not $UseOllama) { throw 'GUI must always use Ollama' }
    if ($Text -eq 'Not a complete recipe') { throw 'Missing ingredients and method' }
    Start-Sleep -Milliseconds 300
    '{"name":"Tomato & basil pasta","description":"A simple supper with a rich tomato sauce.","recipeYield":"2 servings","prepTime":"PT10M","cookTime":"PT20M","totalTime":"PT30M","comment":"QA: 3 ingredients preserved; 2 steps preserved.\n\nTimes estimated.","recipeCategory":["Main courses"],"keywords":["Pasta","Italian"],"recipeIngredient":["200 g pasta","1 tin chopped tomatoes","1 handful fresh basil"],"recipeInstructions":[{"text":"Cook the pasta according to the packet instructions. Drain well, then return it to the pan."},{"text":"Add the tomatoes and stir until the pasta is coated. Fold through the basil and serve."}]}'
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
$script:smokeTicks=0;$script:guiStage=0;$script:guiFailure=$null
$check.Add_Tick({
    try {
        $script:smokeTicks++
        switch ($script:guiStage) {
            0 {
                if ($model.Items.Count -eq 6) {
                    if ($null -eq $form.Icon -or -not $form.Icon.IsFrozen) { throw 'Window icon failed to load' }
                    if ($model.IsEditable -or $model.SelectedItem -ne 'test-model:latest') { throw 'Model dropdown failed' }
                    if ($form.FindName('VersionText').Text -ne "v$script:AppVersion" -or $status.Text) { throw 'Version footer failed' }
                    if ($xaml.OuterXml -match 'Your next recipe starts here|RECIPE WORKSPACE|From inspiration|Paste a recipe, polish') { throw 'Removed text still present' }
                    $refreshPoint=$refresh.TranslatePoint([Windows.Point]::new(0,0),$form)
                    $modelPoint=$model.TranslatePoint([Windows.Point]::new(0,0),$form)
                    if ([Math]::Abs($refreshPoint.Y-$modelPoint.Y) -gt 2 -or $refreshPoint.X -le $modelPoint.X) { throw 'Refresh icon is not beside model dropdown' }
                    if ($inputBox.Text.Length -or $copy.IsEnabled -or $null -ne $form.FindName('InputPlaceholder')) { throw 'Initial state failed' }
                    if ($paste.BorderThickness.Left -ne 1 -or $clear.BorderThickness.Left -ne 1 -or $paste.Background.ToString() -eq '#00FFFFFF') { throw 'Paste and clear button styling failed' }
                    Save-UiSnapshot 'empty.png'
                    Click-Button $convert
                    if ($status.Text -ne 'Paste a recipe to get started.') { throw 'Empty input validation failed' }
                    $model.SelectedIndex=1;Click-Button $refresh;$script:guiStage=1
                }
            }
            1 {
                if (-not $script:modelWorker) {
                    if ($model.SelectedItem -ne 'second-model:7b') { throw 'Selection not preserved' }
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
                    if ($preview.Children.Count -lt 10 -or $outputPlaceholder.Visibility -ne 'Collapsed' -or -not $save.IsEnabled) { throw 'Recipe preview failed' }
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
                if ($inputStage.Visibility -ne 'Visible' -or $inputBox.Text -ne $sample -or $title.Text -ne 'Tomato & basil pasta' -or $source.Text -ne 'https://example.com/pasta' -or $model.SelectedItem -ne 'test-model:latest') { throw 'Back lost input' }
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
                    Write-Host 'WPF checks passed: models, refresh, dropdown, mandatory AI, stage navigation, errors, conversion, preview, tabs, compact layout and clear.'
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
& ([scriptblock]::Create($source))
