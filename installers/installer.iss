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
OutputBaseFilename=zoc_{#MyAppVersion}
SetupIconFile={#SourceDir}\data\flutter_assets\assets\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Close running instances so files can be replaced, then restart them.
; Tray Zoc ignores WM_CLOSE; PrepareToInstall force-closes if RM cannot.
; Do not also launch from [Run] when that restart already brought Zoc back.
CloseApplications=yes
RestartApplications=yes

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
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall; Check: ShouldLaunchApp

[Code]
function IsZocRunning(): Boolean;
var
  Locator: Variant;
  Service: Variant;
  Processes: Variant;
begin
  Result := False;
  try
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    Service := Locator.ConnectServer('.', 'root\CIMV2');
    Processes := Service.ExecQuery(
      'SELECT ProcessId FROM Win32_Process WHERE Name=''{#MyAppExeName}''');
    Result := Processes.Count > 0;
  except
    Result := False;
  end;
end;

function CloseZoc(): Boolean;
var
  ResultCode: Integer;
  Attempts: Integer;
begin
  Result := True;
  if not IsZocRunning() then
    Exit;

  Exec(ExpandConstant('{sys}\taskkill.exe'),
    '/IM {#MyAppExeName} /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  for Attempts := 1 to 8 do
  begin
    if not IsZocRunning() then
      Exit;
    Sleep(250);
  end;

  Exec(ExpandConstant('{sys}\taskkill.exe'),
    '/F /IM {#MyAppExeName} /T', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  for Attempts := 1 to 12 do
  begin
    if not IsZocRunning() then
      Exit;
    Sleep(250);
  end;

  Result := not IsZocRunning();
end;

function ZocStillRunningMessage(): String;
begin
  Result :=
    'O ZOC está em execução e não foi possível fechá-lo automaticamente.' + #13#10 +
    #13#10 +
    'Feche o programa e clique em Tentar novamente para continuar a instalação.';
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  if IsZocRunning() and not CloseZoc() then
    Result := ZocStillRunningMessage();
end;

function ShouldLaunchApp(): Boolean;
begin
  Result := not IsZocRunning();
end;

