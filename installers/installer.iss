; Inno Setup Script for ZOC
; Compatible with Inno Setup 6+

#define MyAppName "ZOC"
#ifndef MyAppVersion
  #define MyAppVersion "1.7.9"
#endif
#define MyAppPublisher "RV Desenvolvimentos"
#define MyAppURL "https://zoctec.com/"
#define MyAppExeName "zoc.exe"

; Adjust this path to your Flutter build output folder
#ifndef SourceDir
  #define SourceDir "C:\app-main\"
#endif

[Setup]
; Unique GUID for ZOC
AppId={{6ABC1D04-2E5D-418D-BDF8-039EEC6E4554}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}

; Modern 64-bit configuration
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

DisableProgramGroupPage=yes
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=C:\zoc\installers
OutputBaseFilename=zoc-installer-{#MyAppVersion}
SetupIconFile=C:\app-main\data\flutter_assets\assets\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Automatically prompt to close running instances during install/update
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startupicon"; Description: "Iniciar com o Windows / Start with Windows"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main executable
Source: "{#SourceDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; All other Flutter binaries, assets, and runtime DLLs
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "{#MyAppExeName}"

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
; Controlled startup shortcut (only created if user checks the task)
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startupicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
