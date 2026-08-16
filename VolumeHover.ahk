;@region Setup
;@region Description
/************************************************************************
 * @description Controls application audio volumes instantly by hovering over the Windows system tray icon.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/15
 * @releasedate 2026/07/07
 * @version 1.6.5.110
 ***********************************************************************/

AppName := "Volume Hover"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "1.6.5.110"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "Controls application audio volumes instantly by hovering over the Windows system tray icon."
;@Ahk2Exe-AddResource .\resources\keyboard.ico, 209
;@Ahk2Exe-AddResource .\resources\mouse.ico, 210
;@Ahk2Exe-AddResource .\resources\OSDType.ico, 211
;@Ahk2Exe-AddResource .\resources\monitors.ico, 212
;@Ahk2Exe-AddResource .\resources\position.ico, 213

;@endregion

;_bkpMode := "AppVersionAndMinutes"

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
#Include *i <_Backup>
#Include *i <_HelperFuncs>
#Include *i <_Config&Vars>
#Include *i <_SaveSettings>
#Include *i <_MessageManager>
#Include *i <_TrayIconHandler>
#Include *i <_Theme>
#Include *i <_FrostedTheme>
#Include *i <_GuiTracker>
#Include *i <_TitleBar>
#Include *i <_OSDCustom>
#Include *i <_AutoUpdater>
#Include *i <_ModernSlider>
;#Include *i <_Color_Picker_Dialog>
#Include *i <_HotkeysRecorder>
#Include <Vars_Custom>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>
#Include *i <_ODColors>

#Include <Menu_Custom>
#Include <SettingsGUI>
#Include <AudioSessions>
#Include <OSDVolume>
#Include <AppVolumeControl>
#Include <SelectPlaybackDevicesGUI>
#Include <MixerGui>


;@endregion

;@region Startup
; SPLASHSCREEN
if (A_Args.Length == 0) && IsSet(SplashScreen){
    SplashScreen()
}

; TRAY ICON + MENU
StartMenu()
Menu_Custom()
if IsSet(StartAutoUpdater) {
	%"StartAutoUpdater"%()
}
;@endregion
;@endregion

#HotIf !A_IsCompiled
^#p::ReloadClean()
#HotIf

;@region Main
; Initialize system hooks and GUI setup
CreateAudioMixerGui()

; HOTKEYS
AppVolumeControl.Init({
    Step: 5,
    MouseUp: General.MouseUp,
    MouseDown: General.MouseDown,
    KeyUp: General.KeyUp,
    KeyDown: General.KeyDown
})

VolUp_ActiveWin(newHotkey := "", isGuiUpdate := false) {
    if (isGuiUpdate) {
        global General
        General.KeyUp := newHotkey
        SaveINI()
        SettingsGUI_EnableDisable()
        return
    }
    AppVolumeControl.ActiveWindow(5)
}

VolDown_ActiveWin(newHotkey := "", isGuiUpdate := false) {
    if (isGuiUpdate) {
        global General
        General.KeyDown := newHotkey
        SaveINI()
        SettingsGUI_EnableDisable()
        return
    }
    AppVolumeControl.ActiveWindow(-5)
}

VolUp_HoverWin(newHotkey := "", isGuiUpdate := false) {
    if (isGuiUpdate) {
        global General
        General.MouseUp := newHotkey
        SaveINI()
        SettingsGUI_EnableDisable()
        return
    }
    AppVolumeControl.HoverWindow(5)
}

VolDown_HoverWin(newHotkey := "", isGuiUpdate := false) {
    if (isGuiUpdate) {
        global General
        General.MouseDown := newHotkey
        SaveINI()
        SettingsGUI_EnableDisable()
        return
    }        
    AppVolumeControl.HoverWindow(-5)
}

; Instantiate the TrayIconHandler
global TrayHandler := TrayIconHandler()
TrayHandler.HoverDelay := 400
TrayHandler.OnRightClick		:= (*) => ShowTrayMenu()
TrayHandler.OnHover			    := (*) => ShowMixerGuiNow()
TrayHandler.OnLeftClick			:= (*) => ShowMixerGuiNow()
TrayHandler.OnLeave				:= (*) => ResetHoverFlags()
TrayHandler.OnWheelUp			:= (*) => AdjustTargetAppVolume(5)
TrayHandler.OnWheelDown			:= (*) => AdjustTargetAppVolume(-5)


OnExit Cleanup
Cleanup(*) {
;    OnMessage(0x020A, OnMouseWheel, 0)
;    OnMessage(0x404,  OnTrayMessage, 0)
;    OnMessage(0x0006, WM_ACTIVATE, 0)
;    OnMessage(0x0115, WM_VSCROLL, 0)
}


; FIRST RUN
if IsSet(FirstRun) && FirstRun {
    if (A_Args.Length == 0 || !RegExMatch(A_Args[1], "i)^--signal-update-success=")) {
		ShowSettingsGUI()
		ShowMixerGuiNow()
		hovertimeout := 400
	}
}

; CHECK RELOAD WITH ARGS
CheckReloadArgs()

;ShowSettingsGUI()
;ShowAboutGUI()

