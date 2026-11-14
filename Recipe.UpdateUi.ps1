# UI integration, loaded after the main form and conversion handlers.
$script:updateWorker=$null
$script:updatePending=$null
$script:availableUpdate=$null
$script:downloadedInstaller=$null
$script:updateAction=''
$updateButton=$form.FindName('UpdateButton')
$updateTimer=New-Object Windows.Threading.DispatcherTimer
$updateTimer.Interval=[TimeSpan]::FromMilliseconds(250)
function Start-AppUpdateWork([string]$Action) {
    if ($script:updateWorker) { return }
    $script:updateAction=$Action
    $updateButton.IsEnabled=$false
    $updateButton.Content=if ($Action -eq 'download') { 'Downloading update...' } else { 'Checking updates...' }
    $script:updateWorker=[powershell]::Create()
    foreach ($name in @('Get-AppUpdate','Select-AppUpdate','Save-AppUpdate')) {
        [void]$script:updateWorker.AddScript("function $name { $((Get-Item function:$name).Definition) }")
    }
    if ($Action -eq 'download') { [void]$script:updateWorker.AddStatement().AddCommand('Save-AppUpdate').AddParameter('Update',$script:availableUpdate) }
    else { [void]$script:updateWorker.AddStatement().AddCommand('Get-AppUpdate').AddParameter('CurrentVersion',$script:AppVersion) }
    $script:updatePending=$script:updateWorker.BeginInvoke();$updateTimer.Start()
}
$updateTimer.Add_Tick({
    if (-not $script:updatePending.IsCompleted) { return }
    $updateTimer.Stop()
    try {
        $result=@($script:updateWorker.EndInvoke($script:updatePending))
        if ($script:updateWorker.HadErrors) { throw ($script:updateWorker.Streams.Error | Out-String) }
        if ($script:updateAction -eq 'check') {
            $script:availableUpdate=if ($result.Count) { $result[0] } else { $null }
            $updateButton.Content=if ($script:availableUpdate) { "Update to $($script:availableUpdate.Version)" } else { 'Check for updates' }
            $updateButton.ToolTip=if ($script:availableUpdate) { 'Download the verified installer from GitHub.' } else { 'No newer stable release with a verified installer is available.' }
        } else {
            $script:downloadedInstaller=[string]$result[0]
            $updateButton.Content='Install update'
            $updateButton.ToolTip='Installer downloaded and verified. Save your recipe before installing.'
        }
    } catch {
        $updateButton.Content=if ($script:availableUpdate) { "Update to $($script:availableUpdate.Version)" } else { 'Check for updates' }
        $updateButton.ToolTip=('Update failed; you can retry. ' + $_.Exception.Message)
    } finally { $script:updateWorker.Dispose();$script:updateWorker=$null;$updateButton.IsEnabled=$true }
})
$updateButton.Add_Click({
    if ($script:downloadedInstaller) {
        if ($script:worker) { [void][Windows.MessageBox]::Show($form,'Wait for recipe conversion to finish before installing.','Update');return }
        $answer=[Windows.MessageBox]::Show($form,'Installing closes this app and discards unsaved recipe text, edits and JSON. Save or copy anything you need first. Continue? Windows will ask for administrator approval.','Install update','YesNo','Warning')
        if ($answer -ne 'Yes') { return }
        try {
            if ((Get-FileHash -LiteralPath $script:downloadedInstaller -Algorithm SHA256).Hash -ine $script:availableUpdate.Digest) { throw 'Installer verification failed.' }
            Start-Process -FilePath $script:downloadedInstaller -Verb RunAs -ErrorAction Stop
            $form.Close()
        } catch { [void][Windows.MessageBox]::Show($form,('Could not start setup. The app remains open. ' + $_.Exception.Message),'Update') }
    } elseif ($script:availableUpdate) { Start-AppUpdateWork 'download' }
    else { Start-AppUpdateWork 'check' }
})
$form.Add_ContentRendered({
    if ([IO.Path]::GetFileName([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) -like 'MealieJsonCreate-*.exe') { Start-AppUpdateWork 'check' }
})
$form.Add_Closed({
    $updateTimer.Stop()
    if ($script:updateWorker) { $script:updateWorker.Stop();$script:updateWorker.Dispose() }
})
