; Version and numeric metadata are supplied by Build.ps1 from AppVersion.
#ifndef AppVersion
  #error Build using Build.ps1 -Installer
#endif
[Setup]
AppId={{BF73E013-5A24-471A-8D26-AC369F2760ED}
AppName=Mealie JSON Create
AppVersion={#AppVersion}
VersionInfoVersion={#WindowsVersion}
DefaultDirName={autopf}\Mealie JSON Create
DisableDirPage=yes
DefaultGroupName=Mealie JSON Create
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputDir=dist
OutputBaseFilename=MealieJsonCreate-{#AppVersion}-Setup
SetupIconFile=Assets\MealieJsonCreate.ico
UninstallDisplayIcon={app}\MealieJsonCreate-{#AppVersion}.exe
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
WizardStyle=modern
[Tasks]
Name: desktopicon; Description: "Create a desktop shortcut"; Flags: unchecked
[Files]
Source: "dist\MealieJsonCreate-{#AppVersion}.exe"; DestDir: "{app}"; Flags: ignoreversion
[InstallDelete]
; Only our versioned application binaries; never user data.
Type: files; Name: "{app}\MealieJsonCreate-*.exe"
[Icons]
Name: "{commonprograms}\Mealie JSON Create"; Filename: "{app}\MealieJsonCreate-{#AppVersion}.exe"
Name: "{commondesktop}\Mealie JSON Create"; Filename: "{app}\MealieJsonCreate-{#AppVersion}.exe"; Tasks: desktopicon
[Run]
Filename: "{app}\MealieJsonCreate-{#AppVersion}.exe"; Description: "Launch Mealie JSON Create"; Flags: nowait postinstall skipifsilent runasoriginaluser
