; ============================================================
; HyperXTalk Windows Installer
; Inno Setup 6.x  (https://jrsoftware.org/isinfo.php)
;
; Build steps:
;   1. Run build-release-x64.bat to produce the Release binaries.
;   2. Open this file in the Inno Setup Compiler (or run:
;        iscc.exe installer\HyperXTalk-setup.iss)
;   3. The installer is written to installer\output\.
; ============================================================

#define MyAppName      "HyperXTalk"
#define MyAppVersion   "0.9.9"
#define MyAppPublisher "HyperXTalk"
#define MyAppURL       "https://github.com/HyperXTalk/HyperXTalk"
#define MyAppExeName   "HyperXTalk.exe"
#define MyAppID        "7F3A2C1D-B4E5-4F89-A012-C3D456789ABC"

; Source tree — relative to this .iss file.
; The Release build script places all outputs here.
#define SourceDir "..\build-win-x86_64\livecode\Release"

; ============================================================
[Setup]
; -------- Identity --------
AppId={{{#MyAppID}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; -------- Install location --------
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; -------- Output --------
OutputDir=output
OutputBaseFilename=HyperXTalk-{#MyAppVersion}-win64-setup
SetupIconFile=..\engine\rsrc\installer.ico

; -------- Compression --------
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; -------- Platform --------
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; -------- UI --------
WizardStyle=modern
WizardSmallImageFile=application.png

; -------- Uninstall --------
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName} {#MyAppVersion}

; -------- Misc --------
MinVersion=10.0
; Require Windows 10 or later (Per-Monitor DPI awareness requires Win10)

; ============================================================
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

; ============================================================
[Tasks]
Name: "desktopicon"; \
    Description: "{cm:CreateDesktopIcon}"; \
    GroupDescription: "{cm:AdditionalIcons}"

Name: "fileassoc"; \
    Description: "Associate .hyperxtalk and .hyperxtalkscript files with {#MyAppName}"; \
    GroupDescription: "File associations"

; ============================================================
[Files]
; ---- Main executables ----
Source: "{#SourceDir}\HyperXTalk.exe";           DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\standalone-community.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\lc-compile.exe";           DestDir: "{app}"; Flags: ignoreversion

; ---- Runtime DLLs ----
; ICU text-processing libraries
Source: "{#SourceDir}\icudt58.dll";  DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\icuin58.dll";  DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\icutu58.dll";  DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\icuuc58.dll";  DestDir: "{app}"; Flags: ignoreversion

; OpenSSL
Source: "{#SourceDir}\libcrypto-3-x64.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\libssl-3-x64.dll";    DestDir: "{app}"; Flags: ignoreversion

; WebView2 (browser widget)
Source: "{#SourceDir}\WebView2Loader.dll"; DestDir: "{app}"; Flags: ignoreversion

; Database drivers
Source: "{#SourceDir}\dbmysql.dll";      DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\dbodbc.dll";       DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\dbsqlite.dll";     DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\dbpostgresql.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\libmysql.dll";     DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

; LiveCode externals — placed in both {app} (Windows DLL search path)
; and {app}\Externals (where revInternal__SetupExternals scans in
; installed mode to register them with the LiveCode engine, making
; their LCB modules — e.g. com.livecode.extensions.libbrowser —
; available for LCB widget loading).
Source: "{#SourceDir}\revbrowser.dll";   DestDir: "{app}";           Flags: ignoreversion
Source: "{#SourceDir}\revdb.dll";        DestDir: "{app}";           Flags: ignoreversion
Source: "{#SourceDir}\revsecurity.dll";  DestDir: "{app}";           Flags: ignoreversion
Source: "{#SourceDir}\revxml.dll";       DestDir: "{app}";           Flags: ignoreversion
Source: "{#SourceDir}\revbrowser.dll";   DestDir: "{app}\Externals"; Flags: ignoreversion
Source: "{#SourceDir}\revdb.dll";        DestDir: "{app}\Externals"; Flags: ignoreversion
Source: "{#SourceDir}\revsecurity.dll";  DestDir: "{app}\Externals"; Flags: ignoreversion
Source: "{#SourceDir}\revxml.dll";       DestDir: "{app}\Externals"; Flags: ignoreversion

; Server externals (needed by the IDE's server-side script testing)
Source: "{#SourceDir}\server-revdb.dll";  DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\server-revxml.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\server-revzip.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

; Utility DLLs
Source: "{#SourceDir}\tz.dll";   DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#SourceDir}\inih.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

; ---- LCB modules (for extension compilation) ----
Source: "{#SourceDir}\modules\lci\*"; \
    DestDir: "{app}\modules\lci"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ---- Packaged extensions ----
Source: "{#SourceDir}\packaged_extensions\*"; \
    DestDir: "{app}\packaged_extensions"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ---- IDE Toolset (home stack, libraries, palettes, resources) ----
; This is the entire development environment UI layer. Without it
; the engine's startUp handler cannot initialize the IDE.
Source: "..\ide\Toolset\*"; \
    DestDir: "{app}\Toolset"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ---- IDE Resources (examples, sample projects, Start Center) ----
Source: "..\ide\Resources\*"; \
    DestDir: "{app}\Resources"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ---- IDE Plugins (built-in palette plugins) ----
Source: "..\ide\Plugins\*"; \
    DestDir: "{app}\Plugins"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ---- IDE Documentation (dictionary, guides, HTML viewer) ----
Source: "..\ide\Documentation\*"; \
    DestDir: "{app}\Documentation"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ---- IDE support libraries (deploy, revliburl, etc.) ----
Source: "..\ide-support\*"; \
    DestDir: "{app}\ide-support"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ---- Windows standalone runtime templates ----
; These are the manifest XML files used by the standalone builder
; to embed DPI awareness and UAC settings into compiled standalones.
Source: "..\ide\Runtime\Windows\*"; \
    DestDir: "{app}\Runtime\Windows"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ============================================================
[Dirs]
; Create writable user-data directories outside Program Files.
; HyperXTalk stores user stacks and preferences here.
Name: "{userdocs}\{#MyAppName}"
Name: "{userdocs}\{#MyAppName}\Stacks"

; ============================================================
[Icons]
Name: "{group}\{#MyAppName}";                    Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";              Filename: "{app}\{#MyAppExeName}"; \
    Tasks: desktopicon

; ============================================================
[Registry]
; ---- File association: .hyperxtalk ----
Root: HKA; Subkey: "Software\Classes\.hyperxtalk"; \
    ValueType: string; ValueName: ""; ValueData: "HyperXTalk.Stack"; \
    Flags: uninsdeletevalue; Tasks: fileassoc
Root: HKA; Subkey: "Software\Classes\HyperXTalk.Stack"; \
    ValueType: string; ValueName: ""; ValueData: "HyperXTalk Stack"; \
    Flags: uninsdeletekey; Tasks: fileassoc
Root: HKA; Subkey: "Software\Classes\HyperXTalk.Stack\DefaultIcon"; \
    ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"; \
    Tasks: fileassoc
Root: HKA; Subkey: "Software\Classes\HyperXTalk.Stack\shell\open\command"; \
    ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; \
    Tasks: fileassoc

; ---- File association: .hyperxtalkscript ----
Root: HKA; Subkey: "Software\Classes\.hyperxtalkscript"; \
    ValueType: string; ValueName: ""; ValueData: "HyperXTalk.Script"; \
    Flags: uninsdeletevalue; Tasks: fileassoc
Root: HKA; Subkey: "Software\Classes\HyperXTalk.Script"; \
    ValueType: string; ValueName: ""; ValueData: "HyperXTalk Script"; \
    Flags: uninsdeletekey; Tasks: fileassoc
Root: HKA; Subkey: "Software\Classes\HyperXTalk.Script\DefaultIcon"; \
    ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"; \
    Tasks: fileassoc
Root: HKA; Subkey: "Software\Classes\HyperXTalk.Script\shell\open\command"; \
    ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; \
    Tasks: fileassoc

; ============================================================
[Run]
Filename: "{app}\{#MyAppExeName}"; \
    Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; \
    Flags: nowait postinstall skipifsilent
