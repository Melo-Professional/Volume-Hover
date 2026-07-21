;@region Setup
;@region Description
/************************************************************************
 * @description Controls application audio volumes instantly by hovering over the Windows system tray icon.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/20
 * @releasedate 2026/07/07
 * @version 1.3.203.6
 ***********************************************************************/

AppName := "Volume Hover"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "1.3.203.6"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "Controls application audio volumes instantly by hovering over the Windows system tray icon."
;@Ahk2Exe-AddResource .\images\keyboard.ico, 209
;@Ahk2Exe-AddResource .\images\mouse.ico, 210
;@Ahk2Exe-AddResource .\images\OSDType.ico, 211
;@Ahk2Exe-AddResource .\images\monitors.ico, 212
;@Ahk2Exe-AddResource .\images\position.ico, 213

;@endregion

backupMode := "AppVersionAndMinutes"

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
#Include *i <_Config&Vars>
#Include *i <_MsgBoxCustom>
#Include *i <_SaveSettings>
#Include *i <_MessageManager>
#Include *i <_Theme>
#Include *i <_OSDCustom>
#Include *i <_ModernSlider>
;#Include *i <_Color_Picker_Dialog>
;#Include *i <_ReloadWithArgs>
#Include <_TitleBar>
#Include *i <_FrostedTheme>
#Include *i <_HotkeysRecorder>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>
#Include *i <_ODColors>

#Include <Vars_Custom>
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
;@endregion
;@endregion

#Include <_ReloadWithArgs>
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
^#p::CustomReload()
#HotIf

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

OnExit Cleanup
Cleanup(*) {
    OnMessage(0x020A, OnMouseWheel, 0)
    OnMessage(0x404,  OnTrayMessage, 0)
    OnMessage(0x0006, WM_ACTIVATE, 0)
    OnMessage(0x0115, WM_VSCROLL, 0)
}

;ShowSettingsGUI()


;global IsMouseOverTray := false
global mouseOverIconEstimate := false
global StartIconX := 0
global StartIconY := 0

#HotIf mouseOverIconEstimate

$WheelUp:: {
    global WheelUsedDuringHover := true, IsGuiVisible
    targetApp := GetTrueFirstActiveApp()
    if (targetApp != "") {
        if (IsGuiVisible) {
            ; If GUI is up, route directly to the slider wrapper to update without a complete rebuild
            UpdateSpecificSliderValue(targetApp, 5)
        } else {
            AppVolumeControl.HoverWindow(5, targetApp)
        }
    }
}

$WheelDown:: {
    global WheelUsedDuringHover := true, IsGuiVisible
    targetApp := GetTrueFirstActiveApp()
    if (targetApp != "") {
        if (IsGuiVisible) {
            ; If GUI is up, route directly to the slider wrapper to update without a complete rebuild
            UpdateSpecificSliderValue(targetApp, -5)
        } else {
            AppVolumeControl.HoverWindow(-5, targetApp)
        }
    }
}
#HotIf ; Reset context

; 3. The watchdog timer function
ResetTrayHoverFlag() {
    global IsMouseOverTray := false
    global mouseOverIconEstimate := false
}

GetLastActiveWindow() {
    ; Get a list of all windows, ordered from front to back (Z-order)
    windowIDs := WinGetList()
    
    ; windowIDs[1] is the CURRENT active window.
    ; We loop starting at index 2 to find the first valid previous window.
    loop windowIDs.Length - 1 {
        thisID := windowIDs[A_Index + 1]
        
        ; Skip hidden windows or basic system elements like the desktop/taskbar
        if !WinExist("ahk_id " thisID)
            continue
            
        style := WinGetStyle("ahk_id " thisID)
        exStyle := WinGetExStyle("ahk_id " thisID)
        
        ; Filter out invisible/background windows
        ; 0x10000000 is WS_VISIBLE. 0x00000040 is WS_EX_TOOLWINDOW (skip alt-tab hidden tools)
        if !(style & 0x10000000) || (exStyle & 0x00000040)
            continue
            
        ; Skip the Program Manager (Desktop background) and the Taskbar itself
        title := WinGetTitle("ahk_id " thisID)
        getclass := WinGetClass("ahk_id " thisID)
        if (getclass ~= "i)^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$" || title == ""  || title == "PopupHost"
        || title == App.Name || title == "Volume OSD")
            continue
            
        return thisID ; Found it!
    }
    return 0
}

Getcurrentactivewindow(){
    ; 1. Get the unique ID (HWND) of the active window
    activeID := WinExist("A")
    
    if activeID {
        ; 2. Fetch details using the ID
        activeTitle := WinGetTitle("ahk_id " activeID)
        activeProcess := WinGetProcessName("ahk_id " activeID)
        
        result := ("Active Window ID: " activeID "`n"
             . "Title: " activeTitle "`n"
             . "Process: " activeProcess)
    } else {
        result := ("No active window detected (could be a system menu or transitional state).")
    }
    return result
}

GetTrueFirstActiveApp() {
    global DeviceMap, VisibleDevicesConfig
    deviceNames := PopulatePlaybackDevices()
    
    ; Gather all running audio process paths into a temporary map
    activeAudioApps := Map()
    for deviceName in deviceNames {
        if (!VisibleDevicesConfig.Has(deviceName) || !VisibleDevicesConfig[deviceName])
            continue
        devicePtr := DeviceMap[deviceName]
        sessions := GetAudioSessionsForDevice(devicePtr)
        for session in sessions {
            if (session.ProgName != "") {
                SplitPath(session.ProgName, &exeName)
                activeAudioApps[StrLower(exeName)] := session.ProgName
            }
        }
    }
    
    if (activeAudioApps.Count == 0)
        return ""

    ; Query Windows Z-Order (Frontmost windows to backmost)
    windowList := WinGetList()
    for hwnd in windowList {
        try {
            winExe := WinGetProcessName("ahk_id " hwnd)
            winExeLower := StrLower(winExe)
            
            ; The first window in the Z-order list that matches one of our 
            ; active audio sessions wins!
            if (activeAudioApps.Has(winExeLower)) {
                return activeAudioApps[winExeLower]
            }
        }
    }
    
    ; Fallback: Return any key if window matching fails
    for exe, fullPath in activeAudioApps
        return fullPath

    return ""
}

if isSet(FirstRun) && FirstRun{
    TrayMouseX := 99999
    TrayMouseY := 99999
    ShowSettingsGUI()
    ShowMixerGuiNow()
}

;ShowSettingsGUI()