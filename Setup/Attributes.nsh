# Important
InstallDir "$LOCALAPPDATA\Koshade"


# Attributes
!define VERSION "1.4.1"
!define MANUFACTURER "Koshade Team"
!define NAME "Koshade"
!define ROBLOXREGLOC "SOFTWARE\ROBLOX Corporation\Environments\roblox-player"
!define SELFREGLOC "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}"
!define UninstallerExe "Uninstall Roshade.exe"
!define HELPLINK "https://github.com"
!define ABOUTLINK "https://github.com"
!define UPDATELINK "https://github.com"
!define RENDERAPI "d3d11.dll"

# Directories
!define PRESETFOLDER "$INSTDIR\presets"
!define RESHADESOURCE "..\Files\Reshade"
!define PRESETSOURCE "..\Files\Preset"
!define PRESETTEMPFOLDER "$TEMP\Presets"
!define TEMPFOLDER "$TEMP\Zeal"
!define LOGDIRECTORY "$TEMP\koshade"

# Files
!define SPLASHICON "$PLUGINSDIR\Koshade.gif"
!define SHADERSINI "$PLUGINSDIR\Shaders.ini"
!define RESHADEINI "$PLUGINSDIR\Reshade.ini"
!define APPICON "$INSTDIR\AppIcon.ico"

Var Techniques
Var Repositories
Var ShaderDir
Var RobloxPath
Var RobloxPath2020L
Var PresetPriority # Determine which preset should be loaded. Lower = higher priority.

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${NAME}"
VIAddVersionKey "CompanyName" "${MANUFACTURER}"
VIAddVersionKey "LegalCopyright" "Copyright (C) 2026 Koshade Team"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "FileVersion" "${VERSION}"

Name "${NAME}"
Caption "$(^Name) Installation"
Outfile "..\KoshadeSetup.exe"
BrandingText "${MANUFACTURER}"
CRCCHECK force