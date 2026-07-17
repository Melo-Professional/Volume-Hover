;@region Setup
;@region Description
/************************************************************************
 * @description Controls application audio volumes instantly by hovering over the Windows system tray icon.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/16
 * @releasedate 2026/07/07
 * @version 1.2.5.0
 ***********************************************************************/

AppName := "Volume Hover"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "1.2.5.0"
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
#Include *i <_MessageManager>
#Include *i <_Theme>
#Include *i <_OSDCustom>
#Include *i <_ModernSlider>
;#Include *i <_Color_Picker_Dialog>
;#Include *i <_ReloadWithArgs>
#Include *i <_FrostedTheme>
#Include *i <_HotkeysRecorder>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>
#Include *i <OD_Colors>


#Include <Vars_Custom>
#Include <Menu_Custom>
#Include <_ReloadWithArgs>
#Include <SettingsGUI>
#Include <AudioSessions>
#Include <OSDVolume>
#Include <AppVolumeControl>
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

;@endregion
;@endregion

;@region Main
; Initialize system hooks and GUI setup
CreateAudioMixerGui()
;OnMessage(0x020A, OnMouseWheel)
;OnMessage(0x404,  OnTrayMessage)
;OnMessage(0x0006, WM_ACTIVATE)
MessageManager.Register(0x020A, OnMouseWheel)
MessageManager.Register(0x404, OnTrayMessage)
MessageManager.Register(0x0006, WM_ACTIVATE)

#HotIf !A_IsCompiled
;+^p::ReloadClean()
+^p::CustomReload()
#HotIf

AppVolumeControl.Init({
    Step: 5,
    MouseUp: General.MouseUp,
    MouseDown: General.MouseDown,
    KeyUp: General.KeyUp,
    KeyDown: General.KeyDown
})

OnExit Cleanup
Cleanup(*) {
    OnMessage(0x020A, OnMouseWheel, 0)
    OnMessage(0x404,  OnTrayMessage, 0)
    OnMessage(0x0006, WM_ACTIVATE, 0)
    OnMessage(0x0115, WM_VSCROLL, 0)
}



/*
; Define the message we want to monitor
global WM_LBUTTONDOWN := 0x0201

; --- GUI 1: A simple window that reacts to clicks when active ---
gui1 := Gui(, "GUI One")
gui1.AddText(, "Click inside me!")
gui1.Show("x100 y100 w200 h100")

; We define our callback
Gui1_OnLeftClick(wParam, lParam, msg, hwnd) {
    if hwnd == gui1.Hwnd {
        ToolTip "You clicked GUI 1!"
        SetTimer () => ToolTip(), -1000
    }
}
; Register it!
MessageManager.Register(WM_LBUTTONDOWN, Gui1_OnLeftClick)


; --- GUI 2: Another window that also reacts to clicks ---
gui2 := Gui(, "GUI Two")
gui2.AddText(, "Click inside me too!")
gui2.Show("x400 y100 w200 h100")

Gui2_OnLeftClick(wParam, lParam, msg, hwnd) {
    if hwnd == gui2.Hwnd {
        ToolTip "You clicked GUI 2! (Double Action)"
        SetTimer () => ToolTip(), -1000
    }
}
; Register it!
MessageManager.Register(WM_LBUTTONDOWN, Gui2_OnLeftClick)


; --- GUI 3: A toggle window to show how to dynamically turn features On/Off ---
gui3 := Gui(, "Toggle Tool")
btn := gui3.AddButton("w150", "Unregister GUI 2 Clicks")
btn.OnEvent("Click", ToggleGui2)
gui3.Show("x250 y300")

ToggleGui2(btnObj, *) {
    static active := true
    if active {
        MessageManager.Unregister(WM_LBUTTONDOWN, Gui2_OnLeftClick)
        btnObj.Text := "Register GUI 2 Clicks"
        active := false
    } else {
        MessageManager.Register(WM_LBUTTONDOWN, Gui2_OnLeftClick)
        btnObj.Text := "Unregister GUI 2 Clicks"
        active := true
    }
}
*/

