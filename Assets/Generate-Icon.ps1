#Requires -Version 5.1
# Run with powershell.exe -NoProfile -STA -File .\Assets\Generate-Icon.ps1
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework
[xml]$art=@'
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="44" Height="44" Background="#E58325" CornerRadius="12">
  <Viewbox Width="28" Height="28"><Canvas Width="32" Height="32">
    <Path Data="M 4 16 C 4 29 28 29 28 16 Z M 2 15 L 30 15 M 10 29 L 22 29" Stroke="#251A10" StrokeThickness="2" StrokeLineJoin="Round"/>
    <Path Data="M 11 10 C 6 6 15 5 11 1 M 21 10 C 16 6 25 5 21 1" Stroke="#251A10" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
  </Canvas></Viewbox>
</Border>
'@
$reader=New-Object Xml.XmlNodeReader $art
$logo=[Windows.Markup.XamlReader]::Load($reader)
$reader.Close()
$frames=@()
foreach ($size in @(16,24,32,48,64,128,256)) {
    $view=New-Object Windows.Controls.Viewbox
    $view.Width=$size;$view.Height=$size;$view.Child=$logo
    $view.Measure([Windows.Size]::new($size,$size))
    $view.Arrange([Windows.Rect]::new(0,0,$size,$size))
    $view.UpdateLayout()
    $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new($size,$size,96,96,[Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($view)
    $encoder=New-Object Windows.Media.Imaging.PngBitmapEncoder
    $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $memory=New-Object IO.MemoryStream
    $encoder.Save($memory)
    $frames+=@{Size=$size;Bytes=$memory.ToArray()}
    if ($size -eq 256) { [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot 'MealieJsonCreate.png'),$memory.ToArray()) }
    $memory.Dispose();$view.Child=$null
}
$stream=[IO.File]::Create((Join-Path $PSScriptRoot 'MealieJsonCreate.ico'))
$writer=New-Object IO.BinaryWriter $stream
try {
    $writer.Write([uint16]0);$writer.Write([uint16]1);$writer.Write([uint16]$frames.Count)
    $offset=6+16*$frames.Count
    foreach ($frame in $frames) {
        $dimension=if ($frame.Size -eq 256) {0} else {$frame.Size}
        $writer.Write([byte]$dimension);$writer.Write([byte]$dimension)
        $writer.Write([byte]0);$writer.Write([byte]0)
        $writer.Write([uint16]1);$writer.Write([uint16]32)
        $writer.Write([uint32]$frame.Bytes.Length);$writer.Write([uint32]$offset)
        $offset+=$frame.Bytes.Length
    }
    foreach ($frame in $frames) { $writer.Write([byte[]]$frame.Bytes) }
} finally { $writer.Dispose() }
Write-Output 'Generated application icon (16, 24, 32, 48, 64, 128 and 256 px).'
