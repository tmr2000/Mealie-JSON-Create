#Requires -Version 5.1
param([switch]$CoreOnly)

# Embedded at build time for a single-file executable; dot-source for development.
. "$PSScriptRoot\Recipe.Core.ps1"
. "$PSScriptRoot\Recipe.Update.ps1"
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
    <Style x:Key="UpdateButtonStyle" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="Background" Value="#28543C"/><Setter Property="Foreground" Value="#E2F5E9"/>
      <Setter Property="BorderBrush" Value="#4A9469"/><Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="Surface" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="7" Padding="{TemplateBinding Padding}">
          <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Surface" Property="Background" Value="#326B4C"/><Setter TargetName="Surface" Property="BorderBrush" Value="#83D5A2"/></Trigger>
          <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Surface" Property="BorderBrush" Value="#B1EDC7"/></Trigger>
          <Trigger Property="IsPressed" Value="True"><Setter TargetName="Surface" Property="Opacity" Value="0.75"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Surface" Property="Opacity" Value="0.5"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E4D9CC"/><Setter Property="Padding" Value="10,8"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="CheckBox">
        <Border x:Name="Choice" Background="#302C28" BorderBrush="#4B4036" BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}">
          <DockPanel>
            <Border x:Name="TickBox" Width="18" Height="18" CornerRadius="4" Background="#1D1D1D" BorderBrush="#938B82" BorderThickness="1" Margin="0,0,9,0" VerticalAlignment="Center">
              <TextBlock x:Name="Tick" Text="&#xE73E;" FontFamily="Segoe MDL2 Assets" Foreground="#20180F" HorizontalAlignment="Center" VerticalAlignment="Center" Visibility="Collapsed"/>
            </Border>
            <ContentPresenter VerticalAlignment="Center" RecognizesAccessKey="True"/>
          </DockPanel>
        </Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsChecked" Value="True"><Setter TargetName="TickBox" Property="Background" Value="#E58325"/><Setter TargetName="TickBox" Property="BorderBrush" Value="#E58325"/><Setter TargetName="Tick" Property="Visibility" Value="Visible"/></Trigger>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Choice" Property="BorderBrush" Value="#EBA76A"/></Trigger>
          <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Choice" Property="BorderBrush" Value="#FFB66E"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Choice" Property="Opacity" Value="0.45"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
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
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <Border Background="#E58325" Width="44" Height="44" CornerRadius="12" Margin="0,0,14,0">
            <Viewbox Width="28" Height="28"><Canvas Width="32" Height="32">
              <Path Data="M 4 16 C 4 29 28 29 28 16 Z M 2 15 L 30 15 M 10 29 L 22 29" Stroke="#251A10" StrokeThickness="2" StrokeLineJoin="Round"/>
              <Path Data="M 11 10 C 6 6 15 5 11 1 M 21 10 C 16 6 25 5 21 1" Stroke="#251A10" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
            </Canvas></Viewbox>
          </Border>
          <StackPanel><TextBlock Text="mealie" FontSize="25" FontWeight="SemiBold"/><TextBlock Text="JSON CREATE" Foreground="#AFA69C" FontSize="10" Margin="1,0,0,0"/></StackPanel>
        </StackPanel>
        <Button Grid.Column="2" x:Name="LogicButton" Content="&#xE713;" FontFamily="Segoe MDL2 Assets" FontSize="18" VerticalAlignment="Center" Margin="12,0,0,0" ToolTip="Settings" AutomationProperties.Name="Settings"/>
        <Button Grid.Column="1" x:Name="UpdateButton" Content="Update available" Visibility="Collapsed" Style="{StaticResource UpdateButtonStyle}"
                VerticalAlignment="Center" Margin="24,0,0,0" AutomationProperties.Name="Application updates"/>
      </Grid>
    </Border>
    <Grid Grid.Row="1" Margin="24,24,24,18">
      <Grid x:Name="InputStage">
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
          </StackPanel>
        </ScrollViewer>
      </Border>
        <Grid Grid.Column="2">
          <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
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
          <Button Grid.Row="1" x:Name="ConvertButton" Content="Convert recipe  →" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Right" Margin="0,18,0,0" Padding="24,12" ToolTip="Convert recipe (Ctrl+Enter)"/>
        </Grid>
      </Grid>
      <Grid x:Name="OutputStage" Visibility="Collapsed">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <Grid Margin="0,0,0,18">
          <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <Button x:Name="BackButton" Content="← Back to recipe"/>
          <TextBlock Grid.Column="1" Text="02  /  Review your recipe" FontSize="20" FontWeight="SemiBold" VerticalAlignment="Center" Margin="22,0"/>
          <Button Grid.Column="2" x:Name="CopyButton" Content="Copy JSON" IsEnabled="False"/>
          <Button Grid.Column="3" x:Name="SaveButton" Content="Save JSON" IsEnabled="False" Margin="10,0,0,0" Style="{StaticResource PrimaryButton}"/>
        </Grid>
        <Grid Grid.Row="1">
          <Grid.ColumnDefinitions><ColumnDefinition Width="272"/><ColumnDefinition Width="24"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Background="#232221" CornerRadius="12" BorderBrush="#383430" BorderThickness="1" Padding="20">
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><StackPanel x:Name="MetadataContent"/></ScrollViewer>
          </Border>
          <Border Grid.Column="2" Background="#232221" CornerRadius="12" BorderBrush="#383430" BorderThickness="1" Padding="28">
            <Grid>
                <TabControl x:Name="OutputTabs">
                  <TabItem Header="Ingredients">
                    <ScrollViewer x:Name="IngredientsScroll" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><StackPanel x:Name="IngredientsContent" Margin="0,4,8,0"/></ScrollViewer>
                  </TabItem>
                  <TabItem Header="Recipe">
                    <ScrollViewer x:Name="PreviewScroll" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><StackPanel x:Name="PreviewContent" Margin="0,4,8,0"/></ScrollViewer>
                  </TabItem>
                  <TabItem Header="JSON">
                    <TextBox x:Name="JsonOutput" IsReadOnly="True" AcceptsReturn="True" TextWrapping="NoWrap" VerticalContentAlignment="Top" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" Foreground="#DCC2A5" AutomationProperties.Name="Mealie import JSON"/>
                  </TabItem>
                </TabControl>
              <Grid x:Name="EditorStage" Visibility="Collapsed" Background="#232221">
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <TextBlock x:Name="EditorTitle" FontSize="22" FontWeight="SemiBold" Margin="0,0,0,16"/>
                <ScrollViewer Grid.Row="1" x:Name="EditorScroll" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><StackPanel x:Name="EditorContent" Margin="0,0,12,12"/></ScrollViewer>
                <StackPanel Grid.Row="2" Margin="0,12,0,0">
                  <TextBlock x:Name="EditorError" Foreground="#EF9A8F" TextWrapping="Wrap" Margin="0,0,0,8"/>
                  <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="EditorCancel" Content="Cancel" Margin="0,0,10,0"/>
                    <Button x:Name="EditorApply" Content="Apply changes" Style="{StaticResource PrimaryButton}"/>
                  </StackPanel>
                </StackPanel>
              </Grid>
              <Border x:Name="OutputPlaceholder" Background="#232221">
                <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" MaxWidth="420">
                  <TextBlock x:Name="ProgressTitle" Text="Writing your recipe…" FontSize="24" FontWeight="SemiBold" TextAlignment="Center"/>
                  <TextBlock x:Name="ProgressDetail" Text="Ollama is extracting ingredients, organising the method and checking recipe details." Foreground="#AAA6A0" TextAlignment="Center" Margin="0,16,0,0"/>
                  <ProgressBar x:Name="GenerationProgress" Width="280" Height="8" Margin="0,24,0,0" Foreground="#E58325" Background="#39322B" BorderThickness="0" IsIndeterminate="False" Visibility="Collapsed" AutomationProperties.Name="Recipe conversion in progress"/>
                </StackPanel>
              </Border>
            </Grid>
          </Border>
        </Grid>
      </Grid>
    </Grid>
    <Grid x:Name="LogicScreen" Grid.Row="1" Background="#191919" Margin="0" Visibility="Collapsed">
      <DockPanel Margin="32,24">
        <TextBlock DockPanel.Dock="Top" Text="Settings" FontSize="23" FontWeight="SemiBold" Margin="0,0,0,12"/>
        <StackPanel DockPanel.Dock="Bottom" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
          <Button x:Name="LogicCancel" Content="Cancel" Margin="0,0,8,0"/><Button x:Name="LogicSave" Content="Save settings" Style="{StaticResource PrimaryButton}"/>
        </StackPanel>
        <TabControl>
          <TabItem Header="Tags">
            <DockPanel Margin="8,12">
              <Button DockPanel.Dock="Top" HorizontalAlignment="Left" x:Name="AddTag" Style="{StaticResource PrimaryButton}" Padding="16,8" Content="+  Add tag" AutomationProperties.Name="Add tag" Margin="0,0,0,12"/>
              <Border DockPanel.Dock="Bottom" x:Name="TagDetail" Visibility="Collapsed" Background="#272522" CornerRadius="8" Padding="16" Margin="0,12,0,0">
                <StackPanel>
                  <TextBlock Text="Tag name" Margin="0,0,0,4"/>
                  <TextBox x:Name="TagName"/>
                  <TextBlock Text="When should Ollama select this tag?" Margin="0,8,0,4"/>
                  <TextBox x:Name="TagRule" AcceptsReturn="True" TextWrapping="Wrap" Height="84" VerticalScrollBarVisibility="Auto"/>
                  <Button x:Name="RemoveTag" Content="Remove tag" HorizontalAlignment="Right" Margin="0,8,0,0"/>
                </StackPanel>
              </Border>
              <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><WrapPanel x:Name="TagRows"/></ScrollViewer>
            </DockPanel>
          </TabItem>
          <TabItem Header="Categories">
            <DockPanel Margin="8,12">
              <Button DockPanel.Dock="Top" HorizontalAlignment="Left" x:Name="AddCategory" Style="{StaticResource PrimaryButton}" Padding="16,8" Content="+  Add category" AutomationProperties.Name="Add category" Margin="0,0,0,12"/>
              <Border DockPanel.Dock="Bottom" x:Name="CategoryDetail" Visibility="Collapsed" Background="#272522" CornerRadius="8" Padding="16" Margin="0,12,0,0">
                <StackPanel>
                  <TextBlock Text="Category name" Margin="0,0,0,4"/>
                  <TextBox x:Name="CategoryName"/>
                  <TextBlock Text="When should Ollama select this category?" Margin="0,8,0,4"/>
                  <TextBox x:Name="CategoryRule" AcceptsReturn="True" TextWrapping="Wrap" Height="84" VerticalScrollBarVisibility="Auto"/>
                  <Button x:Name="RemoveCategory" Content="Remove category" HorizontalAlignment="Right" Margin="0,8,0,0"/>
                </StackPanel>
              </Border>
              <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><WrapPanel x:Name="CategoryRows"/></ScrollViewer>
            </DockPanel>
          </TabItem>
          <TabItem Header="Local AI" x:Name="AiSettingsTab">
            <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="16" MaxWidth="640" HorizontalAlignment="Left">
            <Border Height="1" Background="#3A3530" Margin="0,0,0,18"/>
            <TextBlock Text="LOCAL / NETWORK AI" Foreground="#EBA76A" FontSize="10" FontWeight="SemiBold" Margin="0,0,0,17"/>

            <TextBlock x:Name="ModeHint" Text="Ollama extracts and formats every recipe. A model on the selected local or network server is required." Foreground="#AAA6A0" FontSize="12" Margin="0,10,0,20"/>
            <TextBlock Text="Ollama server" Style="{StaticResource Caption}"/>
            <TextBox x:Name="EndpointInput" Text="http://localhost:11434" AutomationProperties.Name="Ollama server"/>
            <TextBlock Text="Default model" Style="{StaticResource Caption}" Margin="0,17,0,8"/>
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="8"/><ColumnDefinition Width="40"/></Grid.ColumnDefinitions>
              <ComboBox x:Name="ModelSelect" IsEnabled="False" AutomationProperties.Name="Ollama model" ToolTip="Installed models on the selected server"/>
              <Button Grid.Column="2" x:Name="RefreshButton" Padding="10" Width="40" Height="40" ToolTip="Refresh models" AutomationProperties.Name="Refresh models">
                <Viewbox Width="17" Height="17"><Path Data="M 19 8 A 8 8 0 1 0 20 15 M 19 2 L 19 8 L 13 8" Stroke="#EFA45D" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"/></Viewbox>
              </Button>
            </Grid>
            <TextBlock x:Name="ModelStatus" Text="Checking server models..." FontSize="11" Foreground="#AAA6A0" Margin="0,5,0,0"/>
            </StackPanel></ScrollViewer>
          </TabItem>
        </TabControl>
      </DockPanel>
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
$endpoint=$form.FindName('EndpointInput');$model=$form.FindName('ModelSelect')
$refresh=$form.FindName('RefreshButton');$modelStatus=$form.FindName('ModelStatus')
$inputBox=$form.FindName('RecipeInput');$outputBox=$form.FindName('JsonOutput')
$convert=$form.FindName('ConvertButton');$copy=$form.FindName('CopyButton');$save=$form.FindName('SaveButton')
$paste=$form.FindName('PasteButton');$clear=$form.FindName('ClearButton')
$status=$form.FindName('StatusText')
$form.FindName('VersionText').Text="v$script:AppVersion"
$preview=$form.FindName('PreviewContent');$outputPlaceholder=$form.FindName('OutputPlaceholder')
$inputCount=$form.FindName('InputCount')
$inputStage=$form.FindName('InputStage');$outputStage=$form.FindName('OutputStage')
$metadata=$form.FindName('MetadataContent');$back=$form.FindName('BackButton')
$generationProgress=$form.FindName('GenerationProgress')
$back.Add_Click({
    $outputStage.Visibility='Collapsed';$inputStage.Visibility='Visible'
    [void]$inputBox.Focus()
})
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
function Add-MetadataBox([string]$Label,[object[]]$Values) {
    $heading=New-Object Windows.Controls.TextBlock
    $heading.Text=$Label;$heading.FontSize=11;$heading.FontWeight='SemiBold';$heading.Foreground='#EBA76A';$heading.Margin='0,0,0,10'
    $editField=switch ($Label) { 'YIELD' {'yield'} 'TIMING' {'timing'} 'CATEGORIES' {'categories'} 'TAGS' {'tags'} }
    if ($editField) {
        $row=New-Object Windows.Controls.DockPanel
        $edit=New-Object Windows.Controls.Button;$edit.Content=New-PencilIcon;$edit.Tag=$editField;$edit.Padding='8,3';$edit.Margin='8,0,0,8'
        $edit.ToolTip='Edit ' + $Label.ToLowerInvariant()
        [Windows.Automation.AutomationProperties]::SetName($edit,$edit.ToolTip)
        [Windows.Controls.DockPanel]::SetDock($edit,'Right')
        $edit.Add_Click({Open-DetailEditor ([string]$this.Tag)})
        [void]$row.Children.Add($edit);[void]$row.Children.Add($heading);[void]$metadata.Children.Add($row)
    } else { [void]$metadata.Children.Add($heading) }
    $panel=New-Object Windows.Controls.WrapPanel
    $panel.Margin='0,0,0,20'
    if (-not $Values.Count) { $Values=@('None selected') }
    foreach ($value in $Values) {
        $box=New-Object Windows.Controls.Border
        $box.Background='#302C28';$box.BorderBrush='#4B4036';$box.BorderThickness='1';$box.CornerRadius='6';$box.Padding='10,7';$box.Margin='0,0,6,6'
        $text=New-Object Windows.Controls.TextBlock
        $text.Text=[string]$value;$text.TextWrapping='Wrap';$text.Foreground='#E4D9CC';$text.MaxWidth=190
        $box.Child=$text
        [void]$panel.Children.Add($box)
    }
    [void]$metadata.Children.Add($panel)
}
$script:classificationContext=$null;$script:classificationReview=$null;$script:classificationOverrides=@{};$script:classificationStale=$false;$script:editorSection=''
$script:editorActive=$false;$script:editorKind=''
function Show-MetadataEditor($Recipe) {
    $script:editPanel=New-Object Windows.Controls.StackPanel
    $panel=$script:editPanel
    $script:detailInputs=@{};$script:detailChoices=@{}
    $hint=New-Object Windows.Controls.TextBlock
    $hint.Text='Edit details, then apply before copying or saving. Blank values are allowed. Times are in minutes (0 means no time).';$hint.TextWrapping='Wrap';$hint.Margin='0,0,0,16'
    [void]$panel.Children.Add($hint)
    foreach ($field in @('recipeYield','prepTime','cookTime','totalTime')) {
        $label=New-Object Windows.Controls.TextBlock
        $label.Text=switch ($field) { 'recipeYield' {'Yield (for example 4 servings)'} 'prepTime' {'Prep time (minutes)'} 'cookTime' {'Cook time (minutes)'} 'totalTime' {'Total time (minutes)'} }
        $label.Tag=if ($field -eq 'recipeYield') { 'yield' } else { 'timing' }
        [void]$panel.Children.Add($label)
        $input=New-Object Windows.Controls.TextBox;$input.Margin='0,4,0,12'
        $input.Text=if ($field -eq 'recipeYield') { $Recipe.$field } elseif ($Recipe.$field) { [System.Xml.XmlConvert]::ToTimeSpan($Recipe.$field).TotalMinutes.ToString([Globalization.CultureInfo]::InvariantCulture) } else { '' }
        $input.Tag=$label.Tag
        $input.Add_TextChanged({$copy.IsEnabled=$false;$save.IsEnabled=$false;Set-AppStatus 'Apply detail changes before exporting.'})
        $script:detailInputs[$field]=$input;[void]$panel.Children.Add($input)
    }
    $config=$script:ClassificationJson | ConvertFrom-Json
    foreach ($field in @('recipeCategory','keywords')) {
        $label=New-Object Windows.Controls.TextBlock
        $label.Text=if ($field -eq 'recipeCategory') { 'Categories (up to two)' } else { 'Tags' }
        $label.Tag=if ($field -eq 'recipeCategory') { 'categories' } else { 'tags' }
        $label.Margin='0,12,0,8';[void]$panel.Children.Add($label)
        $choices=New-Object Windows.Controls.WrapPanel;$choices.Tag=$label.Tag
        $script:detailChoices[$field]=@()
        $labels=if ($field -eq 'recipeCategory') { @($config.categories | ForEach-Object { $_.name }) } else { @($config.tagGroups | ForEach-Object { $_.labels }) }
        foreach ($name in $labels) {
            $choice=New-Object Windows.Controls.CheckBox;$choice.Content=$name;$choice.IsChecked=($Recipe.$field -contains $name);$choice.Margin='0,0,16,10';$choice.Foreground='#E4D9CC'
            if ($script:classificationReview) {
                $decisionField=if ($field -eq 'keywords') { 'tags' } else { 'categories' }
                $decision=@($script:classificationReview.Decisions | Where-Object { $_.Field -eq $decisionField -and $_.Label -eq $name })
                if ($decision.Count) { $choice.ToolTip=$decision[0].Status + ': ' + $decision[0].Reason + "`n" + $decision[0].Evidence }
            }
            $choice.Add_Click({$copy.IsEnabled=$false;$save.IsEnabled=$false;Set-AppStatus 'Apply detail changes before exporting.'})
            $script:detailChoices[$field]+=$choice;[void]$choices.Children.Add($choice)
        }
        [void]$panel.Children.Add($choices)
        if ($script:classificationReview) {
            $decisionField=if ($field -eq 'keywords') { 'tags' } else { 'categories' }
            foreach ($decision in @($script:classificationReview.Decisions | Where-Object { $_.Field -eq $decisionField -and ($_.Candidate -or $_.Status -in @('supported','review')) })) {
                $explanation=New-Object Windows.Controls.TextBlock;$explanation.Tag=$label.Tag;$explanation.TextWrapping='Wrap';$explanation.Margin='0,0,0,10';$explanation.Foreground='#BBB3A9'
                $explanation.Text=$decision.Label + ' [evidence: ' + $decision.Status + '] - ' + $decision.Reason
                if ($decision.Evidence) { $explanation.Text += "`n" + $decision.Scope + ': ' + $decision.Evidence }
                if ($script:classificationStale) { $explanation.Text='Previous result (recheck needed): ' + $explanation.Text }
                [void]$panel.Children.Add($explanation)
            }
        }
    }
    $script:applyDetails=$form.FindName('EditorApply')
}
function Apply-RecipeDetails {
    try {
        $edited=$outputBox.Text | ConvertFrom-Json
        $edited.recipeYield=$script:detailInputs.recipeYield.Text.Trim()
        foreach ($field in @('prepTime','cookTime','totalTime')) {
            $value=$script:detailInputs[$field].Text.Trim()
            $edited.$field=''
            if ($value) {
                $minutes=0.0
                if (-not [double]::TryParse($value,[Globalization.NumberStyles]::AllowDecimalPoint,[Globalization.CultureInfo]::InvariantCulture,[ref]$minutes) -or [double]::IsInfinity($minutes) -or $minutes -lt 0) { throw 'Enter a non-negative number of minutes or leave the time blank.' }
                $edited.$field=[System.Xml.XmlConvert]::ToString([TimeSpan]::FromMinutes($minutes))
            }
        }
        foreach ($field in @('recipeCategory','keywords')) { $edited.$field=@($script:detailChoices[$field] | Where-Object { $_.IsChecked } | ForEach-Object { [string]$_.Content }) }
        if ($edited.recipeCategory.Count -gt 2) { throw 'Select at most two categories.' }
        if ($edited.totalTime) {
            foreach ($field in @('prepTime','cookTime')) {
                if ($edited.$field -and [System.Xml.XmlConvert]::ToTimeSpan($edited.$field) -gt [System.Xml.XmlConvert]::ToTimeSpan($edited.totalTime)) { throw 'Total time must be at least as long as prep or cook time individually.' }
            }
        }
        $previous=$outputBox.Text | ConvertFrom-Json
        if ($script:classificationContext) {
            $selectedField=switch ($script:editorSection) { 'categories' {'recipeCategory'} 'tags' {'keywords'} default {''} }
            if ($selectedField) {
                $engineField=if ($selectedField -eq 'keywords') { 'tags' } else { 'categories' }
                foreach ($choice in $script:detailChoices[$selectedField]) { $script:classificationOverrides[$engineField + '|' + [string]$choice.Content]=[bool]$choice.IsChecked }
                $script:classificationStale=$true
            }
            if ($previous.totalTime -ne $edited.totalTime -or $script:editorSection -eq 'timing') {
                if ($script:classificationContext.PSObject.Properties.Name -contains 'ContradictionDecisions') { $script:classificationContext.ContradictionDecisions=@() };$script:classificationContext.TotalTime=$edited.totalTime;$script:classificationContext.TotalIsExplicit=[bool]$edited.totalTime;$script:classificationStale=$true
            }
        }
        $outputBox.Text=$edited | ConvertTo-Json -Depth 12
        Show-RecipePreview $outputBox.Text
        $copy.IsEnabled=$true;$save.IsEnabled=$true
        Set-AppStatus 'Details applied. Preview and JSON updated.'
        Close-RecipeEditor
    } catch {
        Set-AppStatus $_.Exception.Message 'error'
        $form.FindName('EditorError').Text=$_.Exception.Message
    }
}
function Add-RecipeSection([string]$Label,[string]$Field,$Parent) {
    $area=New-Object Windows.Controls.Border
    $area.Background='#272522';$area.BorderBrush='#45403A';$area.BorderThickness='1';$area.CornerRadius='8';$area.Padding='18';$area.Margin='0,16,0,0'
    $content=New-Object Windows.Controls.StackPanel
    $row=New-Object Windows.Controls.DockPanel
    $edit=New-Object Windows.Controls.Button;$edit.Content=New-PencilIcon;$edit.Tag=$Field;$edit.Padding='12,5';$edit.Margin='12,0,0,12'
    $edit.ToolTip='Edit ' + $Label.ToLowerInvariant()
    [Windows.Automation.AutomationProperties]::SetName($edit,$edit.ToolTip)
    $edit.Add_Click({Open-ContentEditor ([string]$this.Tag)})
    [Windows.Controls.DockPanel]::SetDock($edit,'Right');[void]$row.Children.Add($edit)
    $heading=New-Object Windows.Controls.TextBlock;$heading.Text=$Label;$heading.FontSize=20;$heading.FontWeight='SemiBold';$heading.Margin='0,0,0,12'
    [void]$row.Children.Add($heading);[void]$content.Children.Add($row)
    $area.Child=$content;[void]$Parent.Children.Add($area)
    return $content
}
function New-PencilIcon {
    $icon=New-Object Windows.Controls.TextBlock
    $icon.FontFamily='Segoe MDL2 Assets';$icon.Text=[string][char]0xE70F;$icon.FontSize=15
    return $icon
}
function Show-RecipeEditor([string]$Title,[string]$Kind) {
    $script:editorActive=$true;$script:editorKind=$Kind
    $form.FindName('EditorTitle').Text=$Title;$form.FindName('EditorError').Text=''
    $form.FindName('OutputTabs').Visibility='Collapsed';$form.FindName('EditorStage').Visibility='Visible'
    $metadata.IsEnabled=$false;$back.IsEnabled=$false;$copy.IsEnabled=$false;$save.IsEnabled=$false
    $form.FindName('EditorScroll').ScrollToTop()
}
function Close-RecipeEditor {
    $form.FindName('EditorStage').Visibility='Collapsed';$form.FindName('OutputTabs').Visibility='Visible'
    $form.FindName('EditorContent').Children.Clear();$form.FindName('EditorError').Text=''
    $script:editorActive=$false;$script:editorKind='';$script:editorSection=''
    $metadata.IsEnabled=$true;$back.IsEnabled=$true;$copy.IsEnabled=$true;$save.IsEnabled=$true
    Show-MetadataEditor ($outputBox.Text | ConvertFrom-Json)
}
function Open-DetailEditor([string]$Section) {
    $script:editorSection=$Section
    Show-MetadataEditor ($outputBox.Text | ConvertFrom-Json)
    $script:editPanel.Children[0].Text=switch ($Section) {
        'tags' { 'Recommended tags start checked. Vegetarian/Vegan recommendations contradicted by ingredients are removed. Uncheck any that do not fit. Hover a choice or scroll below for decision reasons. Applying records your selections and removals for future rechecks.' }
        'categories' { 'Select up to two approved categories. Review suggestions do not export until selected. Applying records your choices for future rechecks; reasons appear below.' }
        'timing' { 'Enter minutes, or leave unknown times blank. Zero means no time. Applying confirms the displayed total for the Quick rule; use Recheck classification afterwards.' }
        default { 'Enter the yield, for example 4 servings or 12 muffins. Leave blank when unknown.' }
    }
    foreach ($child in $script:editPanel.Children) { if ($child.Tag -and $child.Tag -ne $Section) { $child.Visibility='Collapsed' } }
    $hostPanel=$form.FindName('EditorContent');$hostPanel.Children.Clear();[void]$hostPanel.Children.Add($script:editPanel)
    Show-RecipeEditor ('Edit ' + $Section) 'metadata'
}
function Apply-RecipeContent([string]$Field,[string[]]$Entries) {
    $edited=$outputBox.Text | ConvertFrom-Json
    if (-not $Entries.Count -or @($Entries | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count) { throw 'Each entry needs text. Remove unwanted rows or enter at least one item.' }
    if ($Field -eq 'ingredients') {
        $edited.recipeIngredient=@($Entries | ForEach-Object { $_.Trim() })
    } elseif ($Field -eq 'method') {
        $edited.recipeInstructions=@($Entries | ForEach-Object { [pscustomobject]@{'@type'='HowToStep';text=$_.Trim()} })
    } else { throw 'Unknown recipe section.' }
    if ($script:classificationContext) {
        if ($Field -eq 'ingredients') { $script:classificationContext.Ingredients=@($edited.recipeIngredient) }
        else { $script:classificationContext.Method=@($edited.recipeInstructions | ForEach-Object { $_.text }) }
        if ($script:classificationContext.PSObject.Properties.Name -contains 'ContradictionDecisions') { $script:classificationContext.ContradictionDecisions=@() };$script:classificationContext.Claims=@();$script:classificationStale=$true
    }
    $note='Manual edits: recipe content changed after conversion; source QA counts describe the original conversion. Review categories, tags and timings against your changes.'
    if ($edited.comment -notlike ('*' + $note + '*')) { $edited.comment=($edited.comment + "`n`n" + $note).Trim() }
    $outputBox.Text=$edited | ConvertTo-Json -Depth 12
    Show-RecipePreview $outputBox.Text
    Set-AppStatus 'Recipe section updated. Review classifications and timings after content changes.'
}
function Add-ContentEditorRow([string]$Text='') {
    $row=New-Object Windows.Controls.DockPanel;$row.Margin='0,0,0,12'
    $remove=New-Object Windows.Controls.Button;$remove.Content='Remove';$remove.Padding='10,7';$remove.Margin='10,0,0,0';$remove.VerticalAlignment='Top'
    [Windows.Controls.DockPanel]::SetDock($remove,'Right');[void]$row.Children.Add($remove)
    $label=New-Object Windows.Controls.TextBlock;$label.Width=65;$label.Margin='0,10,8,0'
    [Windows.Controls.DockPanel]::SetDock($label,'Left');[void]$row.Children.Add($label)
    $input=New-Object Windows.Controls.TextBox;$input.Text=$Text;$input.TextWrapping='Wrap';$input.VerticalContentAlignment='Top'
    $input.AcceptsReturn=($script:contentField -eq 'method');$input.MinHeight=if ($script:contentField -eq 'method') { 100 } else { 44 }
    $row.Tag=$input
    [void]$row.Children.Add($input);[void]$script:contentRows.Children.Add($row)
    $remove.Add_Click({$rowToRemove=$this.Parent;[void]$script:contentRows.Children.Remove($rowToRemove);Update-ContentRowLabels})
    Update-ContentRowLabels
}
function Update-ContentRowLabels {
    $number=0
    foreach ($row in $script:contentRows.Children) {
        $number++;$label=if ($script:contentField -eq 'method') { "Step $number" } else { "Item $number" }
        $row.Children[1].Text=$label
        [Windows.Automation.AutomationProperties]::SetName($row.Tag,$label)
    }
}
function Open-ContentEditor([string]$Field) {
    $recipe=$outputBox.Text | ConvertFrom-Json
    $script:contentField=$Field;$script:contentRows=New-Object Windows.Controls.StackPanel
    $hostPanel=$form.FindName('EditorContent');$hostPanel.Children.Clear()
    [void]$hostPanel.Children.Add($script:contentRows)
    $entries=if ($Field -eq 'ingredients') { @($recipe.recipeIngredient) } else { @($recipe.recipeInstructions | ForEach-Object { $_.text }) }
    foreach ($entry in $entries) { Add-ContentEditorRow $entry }
    $add=New-Object Windows.Controls.Button;$add.Content=if ($Field -eq 'ingredients') { 'Add ingredient' } else { 'Add step' };$add.HorizontalAlignment='Left'
    $add.Add_Click({Add-ContentEditorRow});[void]$hostPanel.Children.Add($add)
    Show-RecipeEditor $(if ($Field -eq 'ingredients') { 'Edit ingredients' } else { 'Edit recipe steps' }) 'content'
}
$form.FindName('EditorCancel').Add_Click({Close-RecipeEditor;Set-AppStatus 'Changes discarded.'})
$form.FindName('EditorApply').Add_Click({
    if ($script:editorKind -eq 'content') {
        try {
            $entries=@($script:contentRows.Children | ForEach-Object { $_.Tag.Text })
            Apply-RecipeContent $script:contentField $entries
            Close-RecipeEditor
        } catch { $form.FindName('EditorError').Text=$_.Exception.Message;Set-AppStatus $_.Exception.Message 'error' }
    } else { Apply-RecipeDetails }
})
function Invoke-ClassificationRecheck {
    if (-not $script:classificationContext -or $script:editorActive) { return }
    try {
        $context=$script:classificationContext
        # Rebuild evidence from the current section values, never the superseded source method.
        $context.Source=$context.Intro + "`nIngredients`n" + (@($context.Ingredients) -join "`n") + "`nMethod`n" + (@($context.Method) -join "`n") + "`nNotes`n" + (@($context.Notes) -join "`n")
        $review=Get-RecipeClassification -Context $context -ClassificationJson $script:ClassificationJson -Overrides $script:classificationOverrides
        if ($review.Categories.Count -gt 2) { throw 'Choose at most two categories before rechecking.' }
        $edited=$outputBox.Text | ConvertFrom-Json
        $edited.recipeCategory=@($review.Categories);$edited.keywords=@($review.Tags)
        $pending=@($review.Decisions | Where-Object { $_.Status -eq 'review' }).Count
        $summary="Classification: evidence rules applied; Recommended tags are preselected. Review the checked tags before import."
        if ($edited.comment -match '(?m)^Classification:.*$') { $edited.comment=$edited.comment -replace '(?m)^Classification:.*$',$summary } else { $edited.comment += "`n`n" + $summary }
        $script:classificationReview=$review;$script:classificationStale=$false
        $outputBox.Text=$edited | ConvertTo-Json -Depth 12
        Show-RecipePreview $outputBox.Text
        Set-AppStatus 'Classification rechecked. Manual choices retained; unchecked suggestions do not export.'
    } catch { Set-AppStatus $_.Exception.Message 'error' }
}
function Show-RecipePreview([string]$Json) {
    $recipe=$Json | ConvertFrom-Json -ErrorAction Stop
    Show-MetadataEditor $recipe
    $preview.Children.Clear()
    Add-PreviewText $recipe.name 23 '#F4F1ED' 'SemiBold' '0,0,0,10'
    $metadata.Children.Clear()
    Add-MetadataBox 'YIELD' @($recipe.recipeYield)
    $timings=@()
    foreach ($field in @('prepTime','cookTime','totalTime')) {
        if ($recipe.$field) {
            $duration=[System.Xml.XmlConvert]::ToTimeSpan($recipe.$field)
            $parts=@()
            if ($duration.Days) { $parts += "$($duration.Days) days" }
            if ($duration.Hours) { $parts += "$($duration.Hours) hr" }
            if ($duration.Minutes) { $parts += "$($duration.Minutes) min" }
            if ($duration.Seconds) { $parts += "$($duration.Seconds) sec" }
            if (-not $parts.Count) { $parts=@('0 min') }
            $label=switch ($field) { 'prepTime' {'Prep'} 'cookTime' {'Cook'} 'totalTime' {'Total'} }
            $timings += ($label + ': ' + ($parts -join ' '))
        }
    }
    Add-MetadataBox 'TIMING' $timings
    Add-MetadataBox 'CATEGORIES' @($recipe.recipeCategory)
    Add-MetadataBox 'TAGS' @($recipe.keywords)
    if ($script:classificationReview) {
        $pending=@($script:classificationReview.Decisions | Where-Object { $_.Status -eq 'review' }).Count
        $reviewText=if ($script:classificationStale) { 'Recipe or selections changed. Recheck to refresh reasons; manual choices are preserved.' } else { "Recommended tags are checked. Open the tag editor to review or remove them." }
        Add-MetadataBox 'CLASSIFICATION' @($reviewText)
        $recheck=New-Object Windows.Controls.Button;$recheck.Content='Recheck classification';$recheck.Margin='0,0,0,16'
        $recheck.Add_Click({Invoke-ClassificationRecheck});[void]$metadata.Children.Add($recheck)
    }
    if ($recipe.comment) {
        $notes=$recipe.comment
        if ($notes -match '^QA:[^\r\n]+') {
            Add-MetadataBox 'QA SUMMARY' @($Matches[0].Substring(4))
            $notes=$notes.Substring($Matches[0].Length).Trim()
        }
        if ($notes) { Add-MetadataBox 'REVIEW NOTES' @($notes) }
    }
    if ($recipe.PSObject.Properties.Name -contains 'url' -and $recipe.url) { Add-MetadataBox 'SOURCE' @($recipe.url) }
    if ($recipe.description) { Add-PreviewText $recipe.description 16 '#AAA6A0' 'Normal' '0,0,0,24' }
    $rootPreview=$preview
    $ingredientsPreview=$form.FindName('IngredientsContent');$ingredientsPreview.Children.Clear()
    $preview=Add-RecipeSection 'Ingredients' 'ingredients' $ingredientsPreview
    foreach ($ingredient in $recipe.recipeIngredient) { Add-PreviewText ([char]0x2022 + '  ' + $ingredient) 15 '#D4CDC5' 'Normal' '0,0,0,8' }
    $preview=Add-RecipeSection 'Method' 'method' $rootPreview
    $number=0
    foreach ($step in $recipe.recipeInstructions) {
        $number++
        Add-PreviewText ("STEP $number") 10 '#EBA76A' 'SemiBold' '0,4,0,6'
        Add-PreviewText $step.text 16 '#D4CDC5' 'Normal' '0,0,0,18'
    }
    $preview=$rootPreview
    $form.FindName('IngredientsScroll').ScrollToTop()
    $form.FindName('PreviewScroll').ScrollToTop()
    $metadata.Parent.ScrollToTop()
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
$script:aiFile=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'MealieJsonCreate\ai-settings.json'
$script:preferredModel=''
$script:preferredEndpoint='http://localhost:11434'
function Read-AiSettings {
    if (-not [IO.File]::Exists($script:aiFile)) { return }
    try {
        $settings=[IO.File]::ReadAllText($script:aiFile) | ConvertFrom-Json
        $uri=$null
        if (-not [uri]::TryCreate([string]$settings.Endpoint,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -notin @('http','https')) { throw 'Invalid Ollama server URL.' }
        $script:preferredModel=[string]$settings.Model
        $script:preferredEndpoint=[string]$settings.Endpoint
        if ($endpoint.Text -cne [string]$settings.Endpoint) { $endpoint.Text=[string]$settings.Endpoint }
    } catch { Set-AppStatus ('Could not load AI settings: '+$_.Exception.Message) 'error' }
}
function Save-AiSettings {
    $uri=$null
    if (-not [uri]::TryCreate($endpoint.Text.Trim(),[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -notin @('http','https')) { throw 'Enter an absolute HTTP or HTTPS Ollama server URL.' }
    if ($script:modelWorker) { throw 'Wait for model discovery to finish before saving settings.' }
    $selected=[string]$model.SelectedItem
    if (-not $selected -and $endpoint.Text.Trim() -eq $script:preferredEndpoint) { $selected=$script:preferredModel }
    $settings=[ordered]@{Endpoint=$endpoint.Text.Trim();Model=$selected}
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($script:aiFile))
    $temp=$script:aiFile+'.'+[guid]::NewGuid()+'.tmp'
    try {
        [IO.File]::WriteAllText($temp,($settings | ConvertTo-Json),[Text.UTF8Encoding]::new($false))
        if ([IO.File]::Exists($script:aiFile)) { [IO.File]::Copy($temp,$script:aiFile,$true) } else { [IO.File]::Move($temp,$script:aiFile) }
    } finally { if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) } }
    $script:preferredModel=$selected
    $script:preferredEndpoint=$endpoint.Text.Trim()
}
Read-AiSettings
function Start-ModelRefresh {
    $endpointTimer.Stop()
    if ($script:modelWorker) { return }
    $script:modelEndpoint=$endpoint.Text.Trim();$script:previousModel=[string]$model.SelectedItem
    if (-not $script:previousModel -and $script:modelEndpoint -eq $script:preferredEndpoint) { $script:previousModel=$script:preferredModel }
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
                    if ($script:previousModel -and -not $model.Items.Contains($script:previousModel)) { $modelStatus.Text+='; saved/previous model unavailable, using '+[string]$model.SelectedItem }
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
$form.Add_ContentRendered({ Start-ModelRefresh;[void]$inputBox.Focus() })
$timer=New-Object Windows.Threading.DispatcherTimer;$timer.Interval=[TimeSpan]::FromMilliseconds(150)
function Start-RecipeConversion {
    if ($form.FindName('LogicScreen').Visibility -eq 'Visible' -or $script:worker -or $inputStage.Visibility -ne 'Visible') { return }
    if ([string]::IsNullOrWhiteSpace($inputBox.Text)) { Set-AppStatus 'Paste a recipe to get started.' 'error';[void]$inputBox.Focus();return }
    if ($script:modelWorker -or $model.SelectedIndex -lt 0) { Set-AppStatus 'Select an available Ollama model in Settings > Local AI before converting.' 'error';return }
    $script:classificationContext=$null;$script:classificationReview=$null;$script:classificationOverrides=@{};$script:classificationStale=$false
    $copy.IsEnabled=$false;$save.IsEnabled=$false;$outputBox.Clear();$preview.Children.Clear();$form.FindName('IngredientsContent').Children.Clear();$outputPlaceholder.Visibility='Visible';$convert.IsEnabled=$false
    $metadata.Children.Clear();$inputStage.Visibility='Collapsed';$outputStage.Visibility='Visible'
    $form.FindName('OutputTabs').SelectedIndex=0
    $generationProgress.Visibility='Visible';$generationProgress.IsIndeterminate=$true
    $form.FindName('ProgressTitle').Text='Writing your recipe…'
    $form.FindName('ProgressDetail').Text='Ollama is extracting ingredients, organising the method and checking recipe details.'
    Set-AppStatus 'Preparing your recipe...' 'busy'
    $script:ClassificationJson=$script:nextClassification
    $script:worker=[powershell]::Create()
    $code=${function:Format-RecipeLine}.ToString();$converter=${function:ConvertTo-RecipeJson}.ToString();$classifier=${function:Get-RecipeClassification}.ToString()
    [void]$script:worker.AddScript("function Format-RecipeLine { $code }; function Get-RecipeClassification { $classifier }; function ConvertTo-RecipeJson { $converter }")
    [void]$script:worker.AddStatement().AddCommand('ConvertTo-RecipeJson').AddParameter('ClassificationJson',$script:ClassificationJson).AddParameter('Text',$inputBox.Text).AddParameter('Title',$title.Text).AddParameter('SourceUrl',$source.Text).AddParameter('UseOllama',$true).AddParameter('IncludeClassificationReview',$true).AddParameter('Endpoint',$endpoint.Text).AddParameter('Model',[string]$model.SelectedItem)
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
            if ($result.Count -eq 1 -and $result[0].PSObject.Properties.Name -contains 'Json') {
                $script:classificationContext=$result[0].Context;$script:classificationReview=$result[0].Review
                $outputBox.Text=$result[0].Json
            } else { $outputBox.Text=($result -join [Environment]::NewLine) }
            Show-RecipePreview $outputBox.Text
            $copy.IsEnabled=$true;$save.IsEnabled=$true;Set-AppStatus 'Recipe ready. Review quantities and instructions, then copy or save your JSON.'
        } catch {
            $form.FindName('ProgressTitle').Text='Could not convert this recipe'
            $form.FindName('ProgressDetail').Text='Use Back to recipe to check the text and Ollama settings, then try again.'
            Set-AppStatus ('Conversion failed: ' + $_.Exception.Message.Trim()) 'error'
        }
        finally {
            $generationProgress.IsIndeterminate=$false;$generationProgress.Visibility='Collapsed'
            $script:worker.Dispose();$script:worker=$null;$script:pending=$null;$convert.IsEnabled=$true
        }
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
$script:factoryClassification=$script:ClassificationJson
$script:logicFile=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'MealieJsonCreate\classification-settings.json'
function Get-LogicRows {
    $config=$script:factoryClassification | ConvertFrom-Json
    foreach ($entry in $config.categories) { [pscustomobject]@{Kind='Category';Original=$entry.name;Name=$entry.name;Logic=$entry.description} }
    foreach ($group in $config.tagGroups) {
        foreach ($name in $group.labels) {
            $definition=@($config.tagDefinitions | Where-Object { $_.name -eq $name })
            $instruction=if ($definition.Count) { $definition[0].description } else { $group.rules }
            [pscustomobject]@{Kind='Tag';Original=$name;Name=$name;Logic=$instruction}
        }
    }
}
function ConvertTo-LogicConfig($Rows) {
    $config=$script:factoryClassification | ConvertFrom-Json
    $defaults=@(Get-LogicRows)
    $custom=@()
    foreach ($kind in @('Category','Tag')) {
        $entries=@($Rows | Where-Object { $_.Kind -eq $kind })
        if (-not $entries.Count) { throw "Keep at least one $kind." }
        $names=@{}
        foreach ($entry in $entries) {
            if (-not $entry.Name.Trim() -or -not $entry.Logic.Trim()) { throw "Enter a name and selection rule for every $kind." }
            if ($names.ContainsKey($entry.Name)) { throw "Duplicate $kind name: $($entry.Name)" }
            $names[$entry.Name]=$true
        }
    }
    $config.categories=@($Rows | Where-Object Kind -eq Category | ForEach-Object { [pscustomobject]@{name=$_.Name;description=$_.Logic} })
    foreach ($group in $config.tagGroups) {
        $group.labels=@(foreach ($row in $Rows) {
            $default=@($defaults | Where-Object { $_.Kind -eq 'Tag' -and $_.Name -ceq $row.Original })
            if ($row.Kind -eq 'Tag' -and $group.labels -contains $row.Original -and $row.Original -ceq $row.Name -and $default.Count -eq 1 -and $row.Logic -ceq $default[0].Logic) { $row.Name }
        })
    }
    foreach ($entry in $Rows) {
        $default=@($defaults | Where-Object { $_.Kind -eq $entry.Kind -and $_.Name -ceq $entry.Original })
        if ($default.Count -and $entry.Name -ceq $entry.Original -and $entry.Logic -ceq $default[0].Logic) { continue }
        $field=if ($entry.Kind -eq 'Category') { 'categories' } else { 'tags' }
        $custom+=($field+'|'+$entry.Name)
        if ($field -eq 'tags') { $config.tagGroups+=@([pscustomobject]@{group='Custom';labels=@($entry.Name);rules=$entry.Logic}) }
    }
    $config | Add-Member -NotePropertyName customSelections -NotePropertyValue $custom
    return ($config | ConvertTo-Json -Depth 16)
}
function Update-DefaultLogicRows($Rows) {
    $factory=$script:factoryClassification | ConvertFrom-Json
    $defaults=@(Get-LogicRows)
    foreach ($row in $Rows) {
        $copy=$row.PSObject.Copy()
        if ($row.Kind -eq 'Tag' -and $row.Name -ceq $row.Original) {
            $group=@($factory.tagGroups | Where-Object { $_.labels -contains $row.Original })
            $definition=@($defaults | Where-Object { $_.Kind -eq 'Tag' -and $_.Name -ceq $row.Original })
            if ($group.Count -eq 1 -and $definition.Count -eq 1 -and $row.Logic -ceq $group[0].rules) { $copy.Logic=$definition[0].Logic }
        }
        $copy
    }
}
$script:logicRows=@(Get-LogicRows)
$script:nextClassification=$script:factoryClassification
if (Test-Path -LiteralPath $script:logicFile) {
    try {
        $loaded=Get-Content $script:logicFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $loaded=@(Update-DefaultLogicRows $loaded)
        $script:nextClassification=ConvertTo-LogicConfig $loaded
        $script:logicRows=$loaded
    } catch { Set-AppStatus ('Could not load classification settings: '+$_.Exception.Message) 'error' }
}
function Select-LogicEntry($Button) {
    $entry=$Button.Tag
    $detail=$form.FindName($entry.Kind+'Detail')
    if ($detail.Tag) { $detail.Tag.ClearValue([Windows.Controls.Control]::BorderBrushProperty) }
    $detail.Tag=$null
    $form.FindName($entry.Kind+'Name').Text=$entry.Name
    $form.FindName($entry.Kind+'Rule').Text=$entry.Logic
    $detail.Tag=$Button
    $Button.BorderBrush='#E58325'
    $detail.Visibility='Visible'
}
function Add-LogicRow($Entry) {
    $chip=New-Object Windows.Controls.Button
    $chip.Tag=$Entry.PSObject.Copy()
    $chip.Content=if ($Entry.Name) { $Entry.Name } else { 'New '+$Entry.Kind.ToLower() }
    $chip.Margin='0,0,8,8'
    $chip.Add_Click({Select-LogicEntry $this})
    [void]$form.FindName($Entry.Kind+'Rows').Children.Add($chip)
    if (-not $Entry.Name) { Select-LogicEntry $chip;$chip.BringIntoView();[void]$form.FindName($Entry.Kind+'Name').Focus() }
}
foreach ($kind in @('Tag','Category')) {
    $form.FindName($kind+'Name').Tag=$kind
    $form.FindName($kind+'Name').Add_TextChanged({
        $chip=$form.FindName($this.Tag+'Detail').Tag
        if ($chip) { $chip.Tag.Name=$this.Text.Trim();$chip.Content=if ($chip.Tag.Name) { $chip.Tag.Name } else { 'Unnamed '+$this.Tag.ToLower() } }
    })
    $form.FindName($kind+'Rule').Tag=$kind
    $form.FindName($kind+'Rule').Add_TextChanged({
        $chip=$form.FindName($this.Tag+'Detail').Tag
        if ($chip) { $chip.Tag.Logic=$this.Text.Trim() }
    })
    $form.FindName('Remove'+$kind).Tag=$kind
    $form.FindName('Remove'+$kind).Add_Click({
        $detail=$form.FindName($this.Tag+'Detail')
        $form.FindName($this.Tag+'Rows').Children.Remove($detail.Tag)
        $detail.Tag=$null;$detail.Visibility='Collapsed'
    })
}
function Close-LogicScreen {
    $form.FindName('LogicScreen').Visibility='Collapsed'
    $inputStage.Parent.Visibility='Visible'
    $form.FindName('LogicButton').IsEnabled=$true
}
$form.FindName('LogicButton').Add_Click({
    $script:aiSnapshot=[pscustomobject]@{Endpoint=$endpoint.Text;Model=[string]$model.SelectedItem}
    $form.FindName('TagRows').Children.Clear();$form.FindName('CategoryRows').Children.Clear()
    foreach ($kind in @('Tag','Category')) { $detail=$form.FindName($kind+'Detail');$detail.Tag=$null;$detail.Visibility='Collapsed' }
    foreach ($entry in $script:logicRows) { Add-LogicRow $entry }
    $inputStage.Parent.Visibility='Collapsed';$form.FindName('LogicScreen').Visibility='Visible';$this.IsEnabled=$false
})
$form.FindName('AddTag').Add_Click({Add-LogicRow ([pscustomobject]@{Kind='Tag';Original='';Name='';Logic=''})})
$form.FindName('AddCategory').Add_Click({Add-LogicRow ([pscustomobject]@{Kind='Category';Original='';Name='';Logic=''})})
$form.FindName('LogicCancel').Add_Click({
    $script:preferredModel=$script:aiSnapshot.Model
    if ($endpoint.Text -cne $script:aiSnapshot.Endpoint) { $endpoint.Text=$script:aiSnapshot.Endpoint }
    if ($model.Items.Contains($script:preferredModel)) { $model.SelectedItem=$script:preferredModel }
    Close-LogicScreen
})
$form.FindName('LogicSave').Add_Click({
    try {
        $rows=@(foreach ($panel in @('TagRows','CategoryRows')) {
            foreach ($row in $form.FindName($panel).Children) {
                $row.Tag
            }
        })
        $json=ConvertTo-LogicConfig $rows
        Save-AiSettings
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($script:logicFile))
        $temp=$script:logicFile+'.'+[guid]::NewGuid()+'.tmp'
        try {
            [IO.File]::WriteAllText($temp,(ConvertTo-Json -InputObject $rows -Depth 5),[Text.UTF8Encoding]::new($false))
            if ([IO.File]::Exists($script:logicFile)) { [IO.File]::Copy($temp,$script:logicFile,$true) } else { [IO.File]::Move($temp,$script:logicFile) }
        } finally { if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) } }
        $script:logicRows=$rows;$script:nextClassification=$json
        Close-LogicScreen;Set-AppStatus 'Settings saved. The default model will be used on future launches.'
    } catch { Set-AppStatus $_.Exception.Message 'error' }
})
. "$PSScriptRoot\Recipe.UpdateUi.ps1"
[void]$form.ShowDialog()
