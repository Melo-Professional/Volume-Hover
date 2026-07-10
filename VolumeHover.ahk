;@region Setup
;@region Description
/************************************************************************
 * @description Controls application audio volumes instantly by hovering over the Windows system tray icon.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/10
 * @releasedate 2026/07/07
 * @version 1.0.2.6
 ***********************************************************************/

AppName := "Volume Hover"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "1.0.2.6"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "Controls application audio volumes instantly by hovering over the Windows system tray icon."
;@endregion

;@region Directives
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
SetWorkingDir(A_ScriptDir)
A_AllowMainWindow := 0
A_IconHidden := true
A_MenuMaskKey := "vkFF"
; --- Optimization Settings ---
;ProcessSetPriority("High")
ListLines(False)
KeyHistory(0)
;A_MaxHotkeysPerInterval := 5000
;A_HotkeyInterval := 1000
;@endregion

;@region Includes
#Include *i <_CompilerDirectives>
#Include *i <_Config&Vars>
#Include *i <_MsgBoxCustom>
#Include *i <_SaveSettings>
#Include *i <_Theme>
#Include *i <_OSDCustom>
;#Include *i <_Color_Picker_Dialog>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>

#Include <Vars_Custom>
#Include <Menu_Custom>
#Include <_ModernSlider>
#Include <AudioSessions>
#Include <MixerGui>

;@endregion

;@region Startup
; SPLASHSCREEN
if IsSet(SplashScreen){
    SplashScreen("Banner")
}

; TRAY ICON + MENU
StartMenu()
Menu_Custom()

;@endregion
;@endregion

;@region Main
; Initialize system hooks and GUI setup
CreateAudioMixerGui()
OnMessage(0x020A, OnMouseWheel)
OnMessage(0x404,  OnTrayMessage)    
OnMessage(0x0006, WM_ACTIVATE)     

#HotIf !A_IsCompiled
+^p::ReloadClean()
#HotIf
