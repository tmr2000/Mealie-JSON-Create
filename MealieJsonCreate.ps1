#Requires -Version 5.1
param([switch]$CoreOnly)

# Embedded at build time for a single-file executable; dot-source for development.
. "$PSScriptRoot\Recipe.Core.ps1"
if ($CoreOnly) { return }
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    throw 'Start the app with: powershell.exe -NoProfile -STA -File .\MealieJsonCreate.ps1'
}
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Native, scalable vector artwork and embedded styles keep EXE packaging self-contained.
[xml]$xaml=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Mealie JSON Create" Width="1320" Height="900" MinWidth="1080" MinHeight="700"
        WindowStartupLocation="CenterScreen" Background="#191919" Foreground="#F4F1ED"
        FontFamily="Segoe UI" FontSize="14" UseLayoutRounding="True" SnapsToDevicePixels="True">
  <Window.Resources>
    <SolidColorBrush x:Key="{x:Static SystemColors.ControlBrushKey}" Color="#232221"/>
    <Style TargetType="TextBlock"><Setter Property="TextWrapping" Value="Wrap"/></Style>
    <Style x:Key="Caption" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#AAA6A0"/><Setter Property="FontSize" Value="12"/>
      <Setter Property="Margin" Value="0,0,0,8"/>
    </Style>
    <Style TargetType="ToolTip">
      <Setter Property="Background" Value="#36322E"/><Setter Property="Foreground" Value="#F4F1ED"/><Setter Property="Padding" Value="10,6"/>
    </Style>
    <Style x:Key="ScrollPage" TargetType="RepeatButton">
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="RepeatButton"><Border Background="Transparent"/></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="ScrollThumb" TargetType="Thumb">
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Thumb">
        <Border x:Name="Handle" Background="#62594F" CornerRadius="4" Margin="2"/>
        <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Handle" Property="Background" Value="#A67B53"/></Trigger></ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="10"/><Setter Property="Background" Value="#232221"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar">
        <Border Background="{TemplateBinding Background}" CornerRadius="5">
          <Track x:Name="PART_Track" IsDirectionReversed="True" Orientation="Vertical">
            <Track.DecreaseRepeatButton><RepeatButton Style="{StaticResource ScrollPage}" Command="ScrollBar.PageUpCommand"/></Track.DecreaseRepeatButton>
            <Track.Thumb><Thumb Style="{StaticResource ScrollThumb}"/></Track.Thumb>
            <Track.IncreaseRepeatButton><RepeatButton Style="{StaticResource ScrollPage}" Command="ScrollBar.PageDownCommand"/></Track.IncreaseRepeatButton>
          </Track>
        </Border>
      </ControlTemplate></Setter.Value></Setter>
      <Style.Triggers><Trigger Property="Orientation" Value="Horizontal">
        <Setter Property="Width" Value="Auto"/><Setter Property="Height" Value="10"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar">
          <Border Background="{TemplateBinding Background}" CornerRadius="5">
            <Track x:Name="PART_Track" IsDirectionReversed="False" Orientation="Horizontal">
              <Track.DecreaseRepeatButton><RepeatButton Style="{StaticResource ScrollPage}" Command="ScrollBar.PageLeftCommand"/></Track.DecreaseRepeatButton>
              <Track.Thumb><Thumb Style="{StaticResource ScrollThumb}"/></Track.Thumb>
              <Track.IncreaseRepeatButton><RepeatButton Style="{StaticResource ScrollPage}" Command="ScrollBar.PageRightCommand"/></Track.IncreaseRepeatButton>
            </Track>
          </Border>
        </ControlTemplate></Setter.Value></Setter>
      </Trigger></Style.Triggers>
    </Style>
    <Style TargetType="Button">
      <Setter Property="Background" Value="#30302F"/><Setter Property="Foreground" Value="#F4F1ED"/>
      <Setter Property="BorderBrush" Value="#484540"/><Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="16,10"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="HorizontalContentAlignment" Value="Center"/><Setter Property="VerticalContentAlignment" Value="Center"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="Surface" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="7" Padding="{TemplateBinding Padding}">
          <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center" RecognizesAccessKey="True"/>
        </Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Surface" Property="BorderBrush" Value="#E58325"/></Trigger>
          <Trigger Property="IsPressed" Value="True"><Setter TargetName="Surface" Property="Opacity" Value="0.75"/></Trigger>
          <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Surface" Property="BorderBrush" Value="#FFB66E"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Surface" Property="Opacity" Value="0.35"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="PrimaryButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="Background" Value="#E58325"/><Setter Property="BorderBrush" Value="#E58325"/>
      <Setter Property="Foreground" Value="#20180F"/><Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style x:Key="QuietButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="Background" Value="Transparent"/><Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Foreground" Value="#EFA45D"/><Setter Property="Padding" Value="10,7"/>
    </Style>
    <Style TargetType="TextBox">
      <Setter Property="Background" Value="#1D1D1D"/><Setter Property="Foreground" Value="#F4F1ED"/>
      <Setter Property="CaretBrush" Value="#EFA45D"/><Setter Property="SelectionBrush" Value="#94531E"/>
      <Setter Property="BorderBrush" Value="#45423F"/><Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="11,9"/><Setter Property="VerticalContentAlignment" Value="Center"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="TextBox">
        <Border x:Name="Field" CornerRadius="6" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
          <ScrollViewer x:Name="PART_ContentHost"/>
        </Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsKeyboardFocusWithin" Value="True"><Setter TargetName="Field" Property="BorderBrush" Value="#E58325"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="ComboBoxItem">
      <Setter Property="Foreground" Value="#F4F1ED"/><Setter Property="Padding" Value="12,9"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ComboBoxItem">
        <Border x:Name="Item" Padding="{TemplateBinding Padding}" Background="Transparent"><ContentPresenter/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsHighlighted" Value="True"><Setter TargetName="Item" Property="Background" Value="#443224"/></Trigger>
          <Trigger Property="IsSelected" Value="True"><Setter TargetName="Item" Property="Background" Value="#533A25"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="ComboBox">
      <Setter Property="Foreground" Value="#F4F1ED"/><Setter Property="Background" Value="#1D1D1D"/>
      <Setter Property="BorderBrush" Value="#45423F"/><Setter Property="MinHeight" Value="40"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ComboBox">
        <Grid>
          <ToggleButton x:Name="Toggle" Focusable="False" ClickMode="Press" IsChecked="{Binding IsDropDownOpen, RelativeSource={RelativeSource TemplatedParent}, Mode=TwoWay}">
            <ToggleButton.Template><ControlTemplate TargetType="ToggleButton">
              <Border x:Name="ComboBorder" Background="#1D1D1D" BorderBrush="#45423F" BorderThickness="1" CornerRadius="6">
                <Path Data="M 0 0 L 4 4 L 8 0" Stroke="#B5AEA6" StrokeThickness="1.5" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,13,0"/>
              </Border>
              <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="ComboBorder" Property="BorderBrush" Value="#E58325"/></Trigger></ControlTemplate.Triggers>
            </ControlTemplate></ToggleButton.Template>
          </ToggleButton>
          <TextBlock Margin="11,8,32,8" VerticalAlignment="Center" IsHitTestVisible="False" Text="{TemplateBinding SelectionBoxItem}" TextWrapping="NoWrap" TextTrimming="CharacterEllipsis"/>
          <Popup x:Name="PART_Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Fade">
            <Border Background="#292725" BorderBrush="#56504B" BorderThickness="1" CornerRadius="6" MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}" MaxHeight="280">
              <ScrollViewer CanContentScroll="True" VerticalScrollBarVisibility="Auto"><ItemsPresenter KeyboardNavigation.DirectionalNavigation="Contained"/></ScrollViewer>
            </Border>
          </Popup>
        </Grid>
        <ControlTemplate.Triggers>
          <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
          <Trigger Property="IsKeyboardFocusWithin" Value="True"><Setter TargetName="Toggle" Property="Opacity" Value="0.8"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#F4F1ED"/>
      <Setter Property="Cursor" Value="Hand"/><Setter Property="VerticalContentAlignment" Value="Center"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="CheckBox">
        <StackPanel Orientation="Horizontal">
          <Border x:Name="Track" Width="36" Height="20" CornerRadius="10" Background="#55514D" Margin="0,0,10,0">
            <Ellipse x:Name="Thumb" Width="14" Height="14" Fill="#F4F1ED" HorizontalAlignment="Left" Margin="3,0"/>
          </Border>
          <ContentPresenter VerticalAlignment="Center"/>
        </StackPanel>
        <ControlTemplate.Triggers>
          <Trigger Property="IsChecked" Value="True"><Setter TargetName="Track" Property="Background" Value="#E58325"/><Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/></Trigger>
          <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Track" Property="BorderBrush" Value="#FFCF9C"/><Setter TargetName="Track" Property="BorderThickness" Value="2"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="TabItem">
      <Setter Property="Foreground" Value="#AFA9A1"/><Setter Property="Padding" Value="15,9"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="TabItem">
        <Border x:Name="Tab" Background="Transparent" CornerRadius="5" Padding="{TemplateBinding Padding}" Margin="0,0,4,0"><ContentPresenter ContentSource="Header"/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsSelected" Value="True"><Setter TargetName="Tab" Property="Background" Value="#443224"/><Setter Property="Foreground" Value="#FFB979"/></Trigger>
          <Trigger Property="IsMouseOver" Value="True"><Setter Property="Foreground" Value="#F4F1ED"/></Trigger>
          <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Tab" Property="BorderBrush" Value="#E58325"/><Setter TargetName="Tab" Property="BorderThickness" Value="1"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="TabControl">
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="TabControl">
        <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
          <TabPanel IsItemsHost="True" Margin="0,0,0,16"/>
          <ContentPresenter Grid.Row="1" ContentSource="SelectedContent"/>
        </Grid>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
  </Window.Resources>
  <Grid Background="#191919">
    <Grid.RowDefinitions><RowDefinition Height="88"/><RowDefinition Height="*"/><RowDefinition Height="48"/></Grid.RowDefinitions>
    <Border Background="#222120" BorderBrush="#34312E" BorderThickness="0,0,0,1" Padding="28,0">
      <Grid>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <Border Background="#E58325" Width="44" Height="44" CornerRadius="12" Margin="0,0,14,0">
            <Viewbox Width="28" Height="28"><Canvas Width="32" Height="32">
              <Path Data="M 4 16 C 4 29 28 29 28 16 Z M 2 15 L 30 15 M 10 29 L 22 29" Stroke="#251A10" StrokeThickness="2" StrokeLineJoin="Round"/>
              <Path Data="M 11 10 C 6 6 15 5 11 1 M 21 10 C 16 6 25 5 21 1" Stroke="#251A10" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
            </Canvas></Viewbox>
          </Border>
          <StackPanel><TextBlock Text="mealie" FontSize="25" FontWeight="SemiBold"/><TextBlock Text="JSON CREATE" Foreground="#AFA69C" FontSize="10" Margin="1,0,0,0"/></StackPanel>
        </StackPanel>
      </Grid>
    </Border>
    <Grid Grid.Row="1" Margin="24,24,24,18">
      <Grid.ColumnDefinitions><ColumnDefinition Width="272"/><ColumnDefinition Width="24"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <Border Background="#232221" CornerRadius="12" BorderBrush="#383430" BorderThickness="1">
        <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
          <StackPanel Margin="20">
            <TextBlock Text="Recipe settings" FontSize="18" FontWeight="SemiBold" Margin="0,0,0,4"/>
            <TextBlock Text="A few details before you convert." Style="{StaticResource Caption}" Margin="0,0,0,18"/>
            <TextBlock Text="RECIPE DETAILS" Foreground="#EBA76A" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,17"/>
            <TextBlock Text="Title override" Style="{StaticResource Caption}"/>
            <TextBox x:Name="TitleInput" AutomationProperties.Name="Title override" ToolTip="Optional. Leave blank to use the title from your recipe."/>
            <TextBlock Text="Optional; otherwise use the recipe title." Style="{StaticResource Caption}" FontSize="11" Margin="0,6,0,12"/>
            <TextBlock Text="Source URL" Style="{StaticResource Caption}"/>
            <TextBox x:Name="SourceInput" AutomationProperties.Name="Source URL" ToolTip="Optional attribution URL. This app does not fetch the page."/>
            <TextBlock Text="Keep a link to the original recipe." Style="{StaticResource Caption}" FontSize="11" Margin="0,6,0,18"/>
            <Border Height="1" Background="#3A3530" Margin="0,0,0,18"/>
            <TextBlock Text="LOCAL AI" Foreground="#EBA76A" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,17"/>
            <CheckBox x:Name="OllamaToggle" Content="Cookbook rewrite" ToolTip="Use Ollama to extract mixed text and expand instructions in cookbook style."/>
            <TextBlock x:Name="ModeHint" Text="Offline mode uses Ingredients and Method headings." Foreground="#AAA6A0" FontSize="12" Margin="0,10,0,20"/>
            <TextBlock Text="Ollama server" Style="{StaticResource Caption}"/>
            <TextBox x:Name="EndpointInput" Text="http://localhost:11434" AutomationProperties.Name="Ollama server"/>
            <TextBlock Text="Model" Style="{StaticResource Caption}" Margin="0,17,0,8"/>
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="8"/><ColumnDefinition Width="40"/></Grid.ColumnDefinitions>
              <ComboBox x:Name="ModelSelect" IsEnabled="False" AutomationProperties.Name="Ollama model" ToolTip="Installed models on the selected server"/>
              <Button Grid.Column="2" x:Name="RefreshButton" Padding="10" Width="40" Height="40" ToolTip="Refresh models" AutomationProperties.Name="Refresh models">
                <Viewbox Width="17" Height="17"><Path Data="M 19 8 A 8 8 0 1 0 20 15 M 19 2 L 19 8 L 13 8" Stroke="#EFA45D" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"/></Viewbox>
              </Button>
            </Grid>
            <TextBlock x:Name="ModelStatus" Text="Checking local models..." FontSize="11" Foreground="#AAA6A0" Margin="0,5,0,0"/>
          </StackPanel>
        </ScrollViewer>
      </Border>
      <Grid Grid.Column="2">
        <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Grid Grid.Row="0">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*" MinWidth="260"/><ColumnDefinition Width="18"/><ColumnDefinition Width="*" MinWidth="260"/></Grid.ColumnDefinitions>
          <Border Background="#232221" CornerRadius="12" BorderBrush="#383430" BorderThickness="1" Padding="20">
            <Grid>
              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
              <Grid Margin="0,0,0,8">
                <TextBlock Text="01  /  Recipe text" FontSize="16" FontWeight="SemiBold" VerticalAlignment="Center"/>
                <Button x:Name="PasteButton" Content="Paste" Padding="14,6" HorizontalAlignment="Right" ToolTip="Paste text from your clipboard"/>
              </Grid>
              <TextBlock Grid.Row="1" Text="From a website, a chat, or your own notes." Style="{StaticResource Caption}" Margin="0,0,0,16"/>
              <Grid Grid.Row="2">
                <TextBox x:Name="RecipeInput" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" VerticalContentAlignment="Top" Padding="14" FontSize="14" BorderBrush="#45403A" AutomationProperties.Name="Recipe text"/>
              </Grid>
              <Grid Grid.Row="3" Margin="0,12,0,0">
                <TextBlock x:Name="InputCount" Text="0 characters" Foreground="#938B82" FontSize="11" VerticalAlignment="Center"/>
                <Button x:Name="ClearButton" Content="Clear text" FontSize="12" Padding="14,6" HorizontalAlignment="Right"/>
              </Grid>
            </Grid>
          </Border>
          <Border Grid.Column="2" Background="#232221" CornerRadius="12" BorderBrush="#383430" BorderThickness="1" Padding="20">
            <Grid>
              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
              <TextBlock Text="02  /  Ready for Mealie" FontSize="16" FontWeight="SemiBold" Margin="0,7,0,14"/>
              <TextBlock Grid.Row="1" Text="Check the recipe before adding it to your collection." Style="{StaticResource Caption}" Margin="0,0,0,16"/>
              <Grid Grid.Row="2">
                <TabControl x:Name="OutputTabs">
                  <TabItem Header="Recipe preview">
                    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><StackPanel x:Name="PreviewContent" Margin="0,4,8,0"/></ScrollViewer>
                  </TabItem>
                  <TabItem Header="JSON">
                    <TextBox x:Name="JsonOutput" IsReadOnly="True" AcceptsReturn="True" TextWrapping="NoWrap" VerticalContentAlignment="Top" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" Foreground="#DCC2A5" AutomationProperties.Name="Mealie import JSON"/>
                  </TabItem>
                </TabControl>
                <Border x:Name="OutputPlaceholder" Background="#232221" Margin="0,54,0,0" IsHitTestVisible="False">
                  <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" MaxWidth="260" Margin="8,0">
                    <Border Background="#30281F" Width="64" Height="64" CornerRadius="12" HorizontalAlignment="Center" Margin="0,0,0,20">
                      <Viewbox Width="28" Height="28"><Path Data="M 3 1 L 17 1 L 23 7 L 23 29 L 3 29 Z M 17 1 L 17 8 L 23 8 M 8 14 L 18 14 M 8 19 L 18 19 M 8 24 L 15 24" Stroke="#E58325" StrokeThickness="1.7"/></Viewbox>
                    </Border>
                    <TextBlock Text="A new home for your recipe" FontSize="16" FontWeight="SemiBold" TextAlignment="Center"/>
                    <TextBlock Text="Convert your text to see a readable preview and Mealie-ready JSON here." Foreground="#AAA6A0" TextAlignment="Center" FontSize="13" Margin="0,10,0,0" LineHeight="21"/>
                  </StackPanel>
                </Border>
              </Grid>
            </Grid>
          </Border>
        </Grid>
        <Grid Grid.Row="1" Margin="0,18,0,0">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <Button x:Name="ConvertButton" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Left" Padding="22,12" ToolTip="Convert recipe (Ctrl+Enter)">
            <StackPanel Orientation="Horizontal"><TextBlock Text="Convert recipe"/><Path Data="M 0 5 L 12 5 M 7 0 L 12 5 L 7 10" Stroke="#251A10" StrokeThickness="1.7" Width="14" Height="12" Margin="14,2,0,0"/></StackPanel>
          </Button>
          <Button Grid.Column="1" x:Name="CopyButton" Content="Copy JSON" IsEnabled="False" Margin="10,0,0,0"/>
          <Button Grid.Column="2" x:Name="SaveButton" Content="Save JSON" IsEnabled="False" Margin="10,0,0,0"/>
        </Grid>
      </Grid>
    </Grid>
    <Border Grid.Row="2" BorderBrush="#34312E" BorderThickness="0,1,0,0" Padding="26,0">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <TextBlock x:Name="VersionText" Foreground="#AAA6A0" FontSize="12" VerticalAlignment="Center"/>
        <TextBlock Grid.Column="1" x:Name="StatusText" Text="" Margin="24,0" Foreground="#BBB3A9" FontSize="12" TextWrapping="NoWrap" TextTrimming="CharacterEllipsis" VerticalAlignment="Center"/>
        <TextBlock Grid.Column="2" Text="schema.org Recipe  /  UTF-8" Foreground="#8D857B" FontSize="11" VerticalAlignment="Center"/>
      </Grid>
    </Border>
  </Grid>
</Window>
'@
$reader=New-Object System.Xml.XmlNodeReader $xaml
$form=[Windows.Markup.XamlReader]::Load($reader)
$reader.Close()
# The EXE build embeds the ICO so the finished app needs no sidecar asset.
[string]$script:EmbeddedIcon=''
$iconBytes=if ($script:EmbeddedIcon) {
    [Convert]::FromBase64String($script:EmbeddedIcon)
} else {
    [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'Assets\MealieJsonCreate.ico'))
}
$iconStream=[IO.MemoryStream]::new([byte[]]$iconBytes)
try {
    $form.Icon=[Windows.Media.Imaging.BitmapFrame]::Create($iconStream,[Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,[Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
    $form.Icon.Freeze()
} finally { $iconStream.Dispose() }

# Keep the initial window inside the desktop work area on smaller laptop screens.
$workArea=[Windows.SystemParameters]::WorkArea
$form.Width=[Math]::Max($form.MinWidth,[Math]::Min($form.Width,$workArea.Width-24))
$form.Height=[Math]::Max($form.MinHeight,[Math]::Min($form.Height,$workArea.Height-24))
$title=$form.FindName('TitleInput');$source=$form.FindName('SourceInput')
$ollama=$form.FindName('OllamaToggle');$endpoint=$form.FindName('EndpointInput');$model=$form.FindName('ModelSelect')
$refresh=$form.FindName('RefreshButton');$modelStatus=$form.FindName('ModelStatus');$modeHint=$form.FindName('ModeHint')
$inputBox=$form.FindName('RecipeInput');$outputBox=$form.FindName('JsonOutput')
$convert=$form.FindName('ConvertButton');$copy=$form.FindName('CopyButton');$save=$form.FindName('SaveButton')
$paste=$form.FindName('PasteButton');$clear=$form.FindName('ClearButton')
$status=$form.FindName('StatusText')
$form.FindName('VersionText').Text="v$script:AppVersion"
$preview=$form.FindName('PreviewContent');$outputPlaceholder=$form.FindName('OutputPlaceholder')
$inputCount=$form.FindName('InputCount')
$script:worker=$null;$script:pending=$null;$script:modelWorker=$null;$script:modelPending=$null;$script:modelEndpoint=''

function Set-AppStatus([string]$Message,[string]$Kind='ready') {
    $status.Text=$Message;$status.ToolTip=$Message
    $colour=switch ($Kind) { 'error' {'#EF9A8F'} 'busy' {'#E58325'} default {'#9CB58D'} }
    $status.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString($colour)
}
function Add-PreviewText([string]$Text,[double]$Size=14,[string]$Colour='#D4CDC5',[string]$Weight='Normal',[string]$Margin='0,0,0,12') {
    $block=New-Object Windows.Controls.TextBlock
    $block.Text=$Text;$block.TextWrapping='Wrap';$block.FontSize=$Size;$block.Foreground=$Colour
    $block.FontWeight=$Weight;$block.Margin=$Margin;$block.LineHeight=$Size*1.6
    [void]$preview.Children.Add($block)
}
function Show-RecipePreview([string]$Json) {
    $recipe=$Json | ConvertFrom-Json -ErrorAction Stop
    $preview.Children.Clear()
    Add-PreviewText $recipe.name 23 '#F4F1ED' 'SemiBold' '0,0,0,10'
    if ($recipe.recipeYield) { Add-PreviewText ("Yield: " + $recipe.recipeYield) 12 '#EBA76A' }
    if ($recipe.description) { Add-PreviewText $recipe.description 13 '#AAA6A0' 'Normal' '0,0,0,20' }
    Add-PreviewText 'Ingredients' 16 '#F4F1ED' 'SemiBold'
    foreach ($ingredient in $recipe.recipeIngredient) { Add-PreviewText ([char]0x2022 + '  ' + $ingredient) 13 '#D4CDC5' 'Normal' '0,0,0,8' }
    Add-PreviewText 'Method' 16 '#F4F1ED' 'SemiBold' '0,18,0,12'
    $number=0
    foreach ($step in $recipe.recipeInstructions) {
        $number++
        Add-PreviewText ("STEP $number") 10 '#EBA76A' 'SemiBold' '0,4,0,6'
        Add-PreviewText $step.text 14 '#D4CDC5' 'Normal' '0,0,0,18'
    }
    $outputPlaceholder.Visibility='Collapsed'
}
function Update-InputState {
    $inputCount.Text=('{0:N0} characters' -f $inputBox.Text.Length)
    $clear.IsEnabled=$inputBox.Text.Length -gt 0
}
$inputBox.Add_TextChanged({ Update-InputState });Update-InputState
$paste.Add_Click({
    try { if ([Windows.Clipboard]::ContainsText()) { $inputBox.Text=[Windows.Clipboard]::GetText();[void]$inputBox.Focus();Set-AppStatus 'Recipe text pasted' } else { Set-AppStatus 'Your clipboard does not contain text.' 'error' } }
    catch { Set-AppStatus 'Could not read the clipboard. Try pasting directly into the recipe field.' 'error' }
})
$clear.Add_Click({ $inputBox.Clear();[void]$inputBox.Focus() })

$modelTimer=New-Object Windows.Threading.DispatcherTimer;$modelTimer.Interval=[TimeSpan]::FromMilliseconds(150)
$endpointTimer=New-Object Windows.Threading.DispatcherTimer;$endpointTimer.Interval=[TimeSpan]::FromMilliseconds(600)
function Start-ModelRefresh {
    $endpointTimer.Stop()
    if ($script:modelWorker) { return }
    $script:modelEndpoint=$endpoint.Text.Trim();$script:previousModel=[string]$model.SelectedItem
    $model.Items.Clear();$model.IsEnabled=$false;$refresh.IsEnabled=$false
    $modelStatus.Text='Loading available models...';$modelStatus.Foreground='#AAA6A0';$modelStatus.ToolTip=$null
    $script:modelWorker=[powershell]::Create()
    $loader=${function:Get-OllamaModels}.ToString()
    [void]$script:modelWorker.AddScript("function Get-OllamaModels { $loader }")
    [void]$script:modelWorker.AddStatement().AddCommand('Get-OllamaModels').AddParameter('Endpoint',$script:modelEndpoint)
    $script:modelPending=$script:modelWorker.BeginInvoke();$modelTimer.Start()
}
$modelTimer.Add_Tick({
    if ($script:modelPending -and $script:modelPending.IsCompleted) {
        $modelTimer.Stop();$stale=$script:modelEndpoint -ne $endpoint.Text.Trim()
        try {
            $names=@($script:modelWorker.EndInvoke($script:modelPending))
            if ($script:modelWorker.HadErrors) { throw ($script:modelWorker.Streams.Error | Out-String) }
            if (-not $stale) {
                foreach ($name in $names) { [void]$model.Items.Add([string]$name) }
                if ($model.Items.Count) {
                    if ($model.Items.Contains($script:previousModel)) { $model.SelectedItem=$script:previousModel } else { $model.SelectedIndex=0 }
                    $model.IsEnabled=$true;$modelStatus.Text=('{0} model(s) available' -f $model.Items.Count);$modelStatus.Foreground='#AFC29D'
                    $modelStatus.ToolTip="Installed models reported by $script:modelEndpoint"
                } else { $modelStatus.Text='No models installed on this server.';$modelStatus.Foreground='#DDB286' }
            }
        } catch {
            if (-not $stale) { $modelStatus.Text='Cannot connect. Check the server URL and refresh.';$modelStatus.Foreground='#EF9A8F';$modelStatus.ToolTip=$_.Exception.Message }
        } finally { $script:modelWorker.Dispose();$script:modelWorker=$null;$script:modelPending=$null;$refresh.IsEnabled=$true }
        if ($stale) { Start-ModelRefresh }
    }
})
$refresh.Add_Click({ Start-ModelRefresh })
$endpoint.Add_TextChanged({ $model.Items.Clear();$model.IsEnabled=$false;$endpointTimer.Stop();$endpointTimer.Start() })
$endpointTimer.Add_Tick({ Start-ModelRefresh })
function Update-OllamaMode {
    if ($ollama.IsChecked) {
        $modeHint.Text='Fuller cookbook-style steps, powered by your Ollama model.'
        if (-not $model.Items.Count) { Start-ModelRefresh }
    } else { $modeHint.Text='Offline mode uses Ingredients and Method headings.' }
}
$ollama.Add_Checked({ Update-OllamaMode });$ollama.Add_Unchecked({ Update-OllamaMode })
$form.Add_ContentRendered({ Start-ModelRefresh;[void]$inputBox.Focus() })
$timer=New-Object Windows.Threading.DispatcherTimer;$timer.Interval=[TimeSpan]::FromMilliseconds(150)
function Start-RecipeConversion {
    if ($script:worker) { return }
    if ([string]::IsNullOrWhiteSpace($inputBox.Text)) { Set-AppStatus 'Paste a recipe to get started.' 'error';[void]$inputBox.Focus();return }
    if ($ollama.IsChecked -and ($script:modelWorker -or $model.SelectedIndex -lt 0)) { Set-AppStatus 'Select an available Ollama model before converting.' 'error';return }
    $copy.IsEnabled=$false;$save.IsEnabled=$false;$outputBox.Clear();$preview.Children.Clear();$outputPlaceholder.Visibility='Visible';$convert.IsEnabled=$false
    Set-AppStatus $(if ($ollama.IsChecked) {'Writing your cookbook-style recipe...'} else {'Preparing your recipe...'}) 'busy'
    $script:worker=[powershell]::Create()
    $code=${function:Format-RecipeLine}.ToString();$converter=${function:ConvertTo-RecipeJson}.ToString()
    [void]$script:worker.AddScript("function Format-RecipeLine { $code }; function ConvertTo-RecipeJson { $converter }")
    [void]$script:worker.AddStatement().AddCommand('ConvertTo-RecipeJson').AddParameter('Text',$inputBox.Text).AddParameter('Title',$title.Text).AddParameter('SourceUrl',$source.Text).AddParameter('UseOllama',[bool]$ollama.IsChecked).AddParameter('Endpoint',$endpoint.Text).AddParameter('Model',[string]$model.SelectedItem)
    $script:pending=$script:worker.BeginInvoke();$timer.Start()
}
$convert.Add_Click({ Start-RecipeConversion })
$form.Add_PreviewKeyDown({
    if ($_.Key -eq 'Return' -and ([Windows.Input.Keyboard]::Modifiers -band [Windows.Input.ModifierKeys]::Control)) { Start-RecipeConversion;$_.Handled=$true }
})
$timer.Add_Tick({
    if ($script:pending -and $script:pending.IsCompleted) {
        $timer.Stop()
        try {
            $result=$script:worker.EndInvoke($script:pending)
            if ($script:worker.HadErrors) { throw ($script:worker.Streams.Error | Out-String) }
            $outputBox.Text=($result -join [Environment]::NewLine);Show-RecipePreview $outputBox.Text
            $copy.IsEnabled=$true;$save.IsEnabled=$true;Set-AppStatus 'Recipe ready. Review quantities and instructions, then copy or save your JSON.'
        } catch { Set-AppStatus ('Conversion failed: ' + $_.Exception.Message.Trim()) 'error' }
        finally { $script:worker.Dispose();$script:worker=$null;$script:pending=$null;$convert.IsEnabled=$true }
    }
})
$copy.Add_Click({ try { [Windows.Clipboard]::SetText($outputBox.Text);Set-AppStatus 'JSON copied. Paste it into Mealie''s HTML/JSON import.' } catch { Set-AppStatus 'Could not copy JSON. Try again or save it as a file.' 'error' } })
$save.Add_Click({
    $dialog=New-Object Microsoft.Win32.SaveFileDialog;$dialog.Filter='JSON files (*.json)|*.json';$dialog.FileName='recipe.json';$dialog.DefaultExt='.json'
    try { if ($dialog.ShowDialog($form)) { [IO.File]::WriteAllText($dialog.FileName,$outputBox.Text,(New-Object Text.UTF8Encoding($false)));Set-AppStatus 'Recipe JSON saved.' } }
    catch { Set-AppStatus ('Could not save JSON: ' + $_.Exception.Message) 'error' }
})
$form.Add_Closed({
    $timer.Stop();$modelTimer.Stop();$endpointTimer.Stop()
    if ($script:worker) { $script:worker.Stop();$script:worker.Dispose() }
    if ($script:modelWorker) { $script:modelWorker.Stop();$script:modelWorker.Dispose() }
})
[void]$form.ShowDialog()
