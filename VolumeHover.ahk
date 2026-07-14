;@region Setup
;@region Description
/************************************************************************
 * @description Controls application audio volumes instantly by hovering over the Windows system tray icon.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/12
 * @releasedate 2026/07/07
 * @version 1.1.07.1
 ***********************************************************************/

AppName := "Volume Hover"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "1.1.07.1"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "Controls application audio volumes instantly by hovering over the Windows system tray icon."
;@Ahk2Exe-AddResource .\images\keyboard.ico, 209
;@Ahk2Exe-AddResource .\images\mouse.ico, 210
;@Ahk2Exe-AddResource .\images\OSDType.ico, 211
;@Ahk2Exe-AddResource .\images\monitors.ico, 212
;@Ahk2Exe-AddResource .\images\position.ico, 213

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
A_MaxHotkeysPerInterval := 5000
A_HotkeyInterval := 1000
;@endregion

;@region Includes
#Include *i <_CompilerDirectives>
#Include *i <_Config&Vars>
#Include *i <_MsgBoxCustom>
#Include *i <_SaveSettings>
#Include *i <_Theme>
#Include *i <_OSDCustom>
;#Include *i <_Color_Picker_Dialog>
;#Include *i <_ReloadWithArgs>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>

#Include <Vars_Custom>
#Include <Menu_Custom>
#Include <_HotkeysRecorder>
#Include <SettingsGUI>
#Include <_ModernSlider>
#Include <AudioSessions>
#Include <OSDVolume>
#Include <AppVolumeControl>
#Include <MixerGui>
#Include <_ReloadWithArgs>

;@endregion

;@region Startup
; SPLASHSCREEN
if (A_Args.Length == 0) && IsSet(SplashScreen){
    SplashScreen()
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

AppVolumeControl.Init({
    Step: 5,
    MouseUp: General.MouseUp,
    MouseDown: General.MouseDown,
    KeyUp: General.KeyUp,
    KeyDown: General.KeyDown
})

;ShowSettingsGUI()