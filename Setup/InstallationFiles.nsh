# Dependencies
!include "Util\GetSectionNames.nsh"
!include "Util\StrContains.nsh"
!include MUI2.nsh
!include LogicLib.nsh
!include FileFunc.nsh
!include ErrorHandling.nsh
!insertmacro Locate

!macro RequiredFiles SourcePath OutPath
    SectionGroup "-Required"
        Section "-Koshade"
            SectionIn 1 RO

            SetOutPath $INSTDIR
            CreateDirectory ${PRESETFOLDER}
            File "Graphics\AppIcon.ico"
            WriteUninstaller "${UninstallerExe}"

            CreateDirectory "$SMPROGRAMS\${NAME}"
            CreateShortCut "$SMPROGRAMS\${NAME}\Uninstall ${NAME}.lnk" "$INSTDIR\${UninstallerExe}" "" "${APPICON}"

            CreateDirectory "$PICTURES\${NAME}"
        SectionEnd
        Section "-Reshade" ReshadeSection
            SectionIn 1 RO

            CreateDirectory ${TEMPFOLDER}

            ; Отключено: скачивание шейдеров онлайн
            ; SetOutPath $TEMP
            ; ${Explode} $2 "," $Repositories
            ; ${For} $3 1 $2
            ;     pop $0
            ;     ${Explode} $0 "@" $0
            ;     Call InstallShadersAsync
            ; ${Next}

            StrCmp $LauncherTransferID "" +4
            NScurl::wait /ID $LauncherTransferID /END
            !insertmacro ToLog $LOGFILE "NScurl" "Transfer with ID $LauncherTransferID has completed. Executing RobloxPlayerLauncher.exe."
            ExecWait "$PLUGINSDIR\RobloxPlayerLauncher.exe"

            StrCpy $ShaderDir "$RobloxPath\reshade-shaders"
            CreateDirectory $ShaderDir

            FindFirst $0 $1 "${PRESETTEMPFOLDER}\*.ini"
            !define PRESETID ${__LINE__}
            loop_${PRESETID}:
                StrCmp $1 "" done_${PRESETID}
                Delete "${PRESETFOLDER}\$1"
                Rename "${PRESETTEMPFOLDER}\$1" "${PRESETFOLDER}\$1"
                !insertmacro ToLog $LOGFILE "Output" "Moving $1 to ${PRESETFOLDER}."
                FindNext $0 $1
                GoTo loop_${PRESETID}
            done_${PRESETID}:
            !undef PRESETID
            FindClose $0
            RMDir /r ${PRESETTEMPFOLDER}
            RMDir /r "$RobloxPath\koshade"

            CreateDirectory "$RobloxPath\koshade"
            SetOutPath "$RobloxPath\koshade"
            File /r "..\Files\Roshade\*"

            delete "$RobloxPath\opengl32.dll"
            delete "$RobloxPath\d3d9.dll"
            delete "$RobloxPath\dxgi.dll"

            SetOutPath $RobloxPath
            File "${SourcePath}\reshade.dll"
            !insertmacro ToLog $LOGFILE "Output" "Rendering API: ${RENDERAPI}."
            Rename "$RobloxPath\reshade.dll" "$RobloxPath\${RENDERAPI}"

            ${If} ${FileExists} "$RobloxPath\Reshade.ini"
                !insertmacro ToLog $LOGFILE "Output" "Existing Reshade settings have been found."
                ReadINIStr $0 "$RobloxPath\Reshade.ini" "INPUT" "KeyEffects"
                ReadINIStr $1 "$RobloxPath\Reshade.ini" "INPUT" "KeyOverlay"
                ${IfNot} $0 == $KeyEffects
                ${OrIfNot} $1 == $KeyOverlay
                push $1
                push $0
                Call SettingsExistingError
                ${Else}
                !insertmacro ToLog $LOGFILE "Output" "Existing settings match the chosen settings."
                ${EndIf}
            ${Else}
                !insertmacro IniPrint "${RESHADEINI}" "INPUT" "KeyEffects" $KeyEffects
                !insertmacro IniPrint "${RESHADEINI}" "INPUT" "KeyOverlay" $KeyOverlay
            ${EndIf}
            
            !insertmacro IniPrint "${RESHADEINI}" "SCREENSHOT" "SavePath" "$PICTURES\${NAME}"
            !insertmacro ToLog $LOGFILE "Output" "Screenshot path set to $PICTURES\${NAME}."

            Delete "$RobloxPath\Reshade.ini"

            !insertmacro MoveFile "$PLUGINSDIR\Reshade.ini" "$RobloxPath\Reshade.ini"

            AccessControl::GrantOnFile "$RobloxPath\Reshade.ini" "Everyone" "FullAccess"
            AccessControl::GrantOnFile "$RobloxPath\Reshade.ini" "SYSTEM" "FullAccess"
            AccessControl::GrantOnFile "$RobloxPath\Reshade.ini" "Users" "FullAccess"

            ReadRegStr $1 HKCU "${ROBLOXREGLOC}" "curPlayerVer"
            WriteRegStr HKCU "${SELFREGLOC}" "RobloxVersion" "$1"
            WriteRegStr HKCU "${SELFREGLOC}" "Version" "${VERSION}"
            WriteRegStr HKCU "${SELFREGLOC}" "RobloxPath" "$RobloxPath"
            WriteRegStr HKCU "${SELFREGLOC}" "DisplayName" "${NAME} - ${MANUFACTURER}"
            WriteRegStr HKCU "${SELFREGLOC}" "UninstallString" "$INSTDIR\${UninstallerExe}"
            WriteRegStr HKCU "${SELFREGLOC}" "DisplayIcon" "${APPICON}"
            WriteRegStr HKCU "${SELFREGLOC}" "Publisher" "${MANUFACTURER}"
            WriteRegStr HKCU "${SELFREGLOC}" "HelpLink" "${HELPLINK}"
            WriteRegStr HKCU "${SELFREGLOC}" "URLInfoAbout" "${ABOUTLINK}"
            WriteRegStr HKCU "${SELFREGLOC}" "URLUpdateInfo" "${UPDATELINK}"
            WriteRegStr HKCU "${SELFREGLOC}" "DisplayVersion" "${VERSION}"
            WriteRegDWORD HKCU "${SELFREGLOC}" "NoModify" 1
            WriteRegDWORD HKCU "${SELFREGLOC}" "NoRepair" 1

            ; Копируем готовые шейдеры вместо скачивания
            SetOutPath "$RobloxPath\reshade-shaders"
            File /r "..\Files\reshade-shaders\*"
            !insertmacro ToLog $LOGFILE "Output" "Shaders copied from local files."

            SetOutPath "$RobloxPath\reshade-shaders\Textures"
            File /r "..\Files\Textures\*"
            
            ; Устанавливаем также в папку 2020L если она найдена
            StrCmp $RobloxPath2020L "" skip_install_2020L
            !insertmacro ToLog $LOGFILE "Output" "Installing to 2020L: $RobloxPath2020L"
            
            delete "$RobloxPath2020L\opengl32.dll"
            delete "$RobloxPath2020L\d3d9.dll"
            delete "$RobloxPath2020L\dxgi.dll"
            
            SetOutPath $RobloxPath2020L
            File "${RESHADESOURCE}\reshade.dll"
            Rename "$RobloxPath2020L\reshade.dll" "$RobloxPath2020L\${RENDERAPI}"
            
            CopyFiles "$RobloxPath\Reshade.ini" "$RobloxPath2020L\Reshade.ini"
            CopyFiles /SILENT "$RobloxPath\reshade-shaders\*.*" "$RobloxPath2020L\reshade-shaders\"
            CreateDirectory "$RobloxPath2020L\koshade"
            CopyFiles /SILENT "$RobloxPath\koshade\*.*" "$RobloxPath2020L\koshade\"
            
            skip_install_2020L:
        SectionEnd
    SectionGroupEnd
!macroend

!macro MoveShaderFiles SourceName Destination Search
    !insertmacro ToLog $LOGFILE "Output" "Moving contents of ${TEMPFOLDER}\${SourceName} to ${Destination}"
    !insertmacro MoveFolder "${TEMPFOLDER}\${SourceName}\Shaders\${Search}" "${Destination}\Shaders" "*.fx"
    !insertmacro MoveFolder "${TEMPFOLDER}\${SourceName}\Shaders\${Search}" "${Destination}\Shaders" "*.fxh"
    !insertmacro MoveFolder "${TEMPFOLDER}\${SourceName}\Textures\${Search}" "${Destination}\Textures" "*"
!macroend

!macro InstallToTemp SourcePath ZipName
    SetOutPath $TEMP
!macroend

!macro Unzip ZipName
    !define ID ${__LINE__}
    start_${ID}:
    nsisunz::UnzipToStack "${TEMPFOLDER}\${ZipName}" ${TEMPFOLDER}
    Pop $R0
    StrCpy $R2 "$R0: ${ZipName}"
    !insertmacro ToLog $LOGFILE "nsisunz" "Unzipping ${ZipName} with response: $R0."
    StrCmp $R0 "success" +3
    MessageBox MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION $R2 IDIGNORE end_${ID} IDRETRY start_${ID}
        Abort

    Pop $R1
    ${Explode} $R1 "\" $R1
    pop $R1
    ${Explode} $R2 "." ${ZipName}
    pop $R2
    ReadINIStr $R3 ${SHADERSINI} $R2 "search"
    !insertmacro MoveShaderFiles $R1 $ShaderDir $R3
    end_${ID}:
    Delete "${TEMPFOLDER}\${ZipName}"
    !undef ID
!macroend

Function InstallShadersAsync
    pop $R7
    pop $R1
    ReadINIStr $R0 ${SHADERSINI} $R7 "alwaysinstall"
    StrCmp $R0 "" 0 install
    ReadINIStr $R0 ${SHADERSINI} $R7 "techniques"
    StrCpy $Techniques ""
    StrCpy $R6 ""
    FindFirst $R8 $R9 "${PRESETTEMPFOLDER}\*.ini"
    !define PRESETID ${__LINE__}
    loop_${PRESETID}:
        StrCmp $R9 "" done_${PRESETID}
        ${ConfigRead} "${PRESETTEMPFOLDER}\$R9" "Techniques=" $Techniques
        ${Explode} $R2 "," $Techniques
        ${For} $R3 1 $R2
            pop $R4
            ${Explode} $R5 "@" $R4
            IntCmp $R5 2 0 +7
            pop $R4
            pop $R4
            StrCpy $R5 ""
            ${StrContains} $R5 $R4 $R0
            StrCmp $R5 "" +4
            StrCmp $R6 "" 0 +3
            StrCpy $R6 $R5
            !insertmacro ToLog $LOGFILE "Output" "$R6 ($R7) found in $R9."
        ${Next}
        FindNext $R8 $R9
        GoTo loop_${PRESETID}
    done_${PRESETID}:
    !undef PRESETID
    FindClose $R8
    StrCmp $R6 "" skip
    install:
    ReadINIStr $R0 ${SHADERSINI} $R7 "branch"
    StrCmp $R0 "" 0 +2
    StrCpy $R0 "master"
    NScurl::http GET "https://github.com/$R1/archive/refs/heads/$R0.zip" "${TEMPFOLDER}/$R7.zip" /BACKGROUND /TAG "Shader" /END
    pop $R2
    !insertmacro ToLog $LOGFILE "NScurl" "Adding installation of $R1 to a background thread. ($R2)"
    DetailPrint "$R1 GET"
    skip:
FunctionEnd