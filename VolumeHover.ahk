;@region Setup
;@region Description
/************************************************************************
 * @description Controls application audio volumes instantly by hovering over the Windows system tray icon.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/09
 * @releasedate 2026/07/07
 * @version 1.0.0.0
 ***********************************************************************/

AppName := "Volume Hover"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "1.0.0.0"
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

#Include *i <Vars_Custom>
#Include *i <Menu_Custom>
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

;@endregion
;throw Error('Message', A_ThisFunc, )
;a := "test"
;OutputDebug(a) ; debug tab

^p::ReloadClean()

; ==============================================================================
; COM GUIDs & VTable Offsets for WASAPI
; ==============================================================================
global CLSID_MMDeviceEnumerator   := "{BCDE0395-E52F-467C-8E3D-C4579291692E}"
global IID_IMMDeviceEnumerator    := "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
global IID_IAudioSessionManager2  := "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}"
global IID_IAudioSessionControl2  := "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}"
global IID_ISimpleAudioVolume     := "{87CE5498-68D6-44E5-9215-6DA47EF883D8}"

; Global tracking variables
global ControlToSessionMap := Map()
global DynamicControls := []
global DeviceMap := Map() 
global CurrentGuiHeight := 90 

; Tray Icon Hover State Tracking Variables
global IsGuiVisible := false
global TrayStartX := 0
global TrayStartY := 0
global TrayMouseX := 0
global TrayMouseY := 0
global TrayLeaveCount := 0

; Initialize the mixer layout silently, then register system hook messages
CreateAudioMixerGui()
OnMessage(0x020A, OnMouseWheel)
OnMessage(0x404,  OnTrayMessage)    ; Monitors mouse actions over the tray icon
OnMessage(0x0006, WM_ACTIVATE)     ; Monitors window focus deactivation

; ==============================================================================
; GUI Layout & Logic
; ==============================================================================
CreateAudioMixerGui() {
    ; Removed default Windows title bar (-Caption)
    global MainGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    MainGui.SetFont("s9", "Segoe UI")
    
    deviceNames := PopulatePlaybackDevices()
    if (deviceNames.Length == 0) {
        MainGui.Add("Text", "x20 y25 w320 Center cRed", "No playback devices detected.")
        return
    }
    
    chooseIdx := 1 ; Default fallback
    
    if (HasMethod(General, "PlaybackDevice") && General.PlaybackDevice != "" && DeviceMap.Has(General.PlaybackDevice)) {
        for idx, name in deviceNames {
            if (name == General.PlaybackDevice) {
                chooseIdx := idx
                break
            }
        }
    } else {
        defaultName := GetDefaultDeviceFriendlyName()
        if (defaultName != "" && DeviceMap.Has(defaultName)) {
            for idx, name in deviceNames {
                if (name == defaultName) {
                    chooseIdx := idx
                    break
                }
            }
        }
    }
    
    ; Setup the DDL container (Positioned dynamically via Refresh function later)
    ; Placed with x20 margin, width 320 (Total width layout constraint)
    global DeviceDDL := MainGui.Add("DDL", "x20 w320 Choose" chooseIdx, deviceNames)
    DeviceDDL.OnEvent("Change", OnDeviceChange)
    
    try General.PlaybackDevice := DeviceDDL.Text
    
    ApplyThemeToGui(MainGui)
    WatchedGUIs.Push(MainGui)
    ; Pre-calculate and construct controls silently in the background
    RefreshSessionsForSelectedDevice()

}

OnDeviceChange(ctrl, *) {
    try {
        General.PlaybackDevice := ctrl.Text
        SaveINI()
    }
    RefreshSessionsForSelectedDevice()
}

RefreshSessionsForSelectedDevice() {
    global MainGui, ControlToSessionMap, DynamicControls, DeviceDDL, DeviceMap, IsGuiVisible, CurrentGuiHeight
    
    ; Clear out old dynamic Win32 child elements safely
    for ctrl in DynamicControls {
        DllCall("user32\DestroyWindow", "Ptr", ctrl.Hwnd)
    }
    DynamicControls := [] 
    ControlToSessionMap.Clear()
    
    ; Force window redraw/wipe
    DllCall("user32\RedrawWindow", "Ptr", MainGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 5)
    
    selectedName := DeviceDDL.Text
    if (!selectedName || !DeviceMap.Has(selectedName))
        return
        
    devicePtr := DeviceMap[selectedName]
    sessions := GetAudioSessionsForDevice(devicePtr)
    
    ; Top margin set to 25
    yPos := 30
    
    if (sessions.Length == 0) {
        lbl := MainGui.Add("Text", "x20 y" yPos " w320 Center cGray", "No active audio sessions on this device.")
        DynamicControls.Push(lbl)
        yPos += 30
    } else {
        for session in sessions {
            ; Correct SplitPath parameters to extract name without extension
            SplitPath(session.ProgName, , , , &cleanProgName)
            
            ; Left margin starts at x20
            lblApp := MainGui.Add("Text", "x20 y" yPos " w100 h20 +0x4000", cleanProgName)
            sliderY := yPos - 3

            ; FIX: Expanded slider width from 210 to 215 so it gets closer to the numbers
            sldVol := MainGui.Add("Slider", "x125 y" sliderY " w215 h25 +NoTicks Range0-100", session.Volume)
            
            ; FIX: Shifted numbers to x345 and switched to Left-alignment so they don't hug the right margin
            lblVol := MainGui.Add("Text", "x345 y" yPos " w25 h20 Left", session.Volume)
            
            DynamicControls.Push(lblApp)
            DynamicControls.Push(sldVol)
            DynamicControls.Push(lblVol)
            
            sessionData := {SimpleVol: session.SimpleVol, Slider: sldVol, Label: lblVol}
            ControlToSessionMap[lblApp.Hwnd] := sessionData
            ControlToSessionMap[sldVol.Hwnd] := sessionData
            ControlToSessionMap[lblVol.Hwnd] := sessionData
            
            sldVol.OnEvent("Change", OnSliderChange.Bind(session.SimpleVol, lblVol))
            
            yPos += 45
        }
    }
    
    ; Extra spacer space before the DDL
    yPos += 0
    
    ; Drop-down List positioned down with matching left margin and full width alignment
    DeviceDDL.Move(20, yPos, 340, 24)
    yPos += 24
    
    ; Retained deep padding below the DDL boundary element
    newHeight := yPos + 25
    CurrentGuiHeight := newHeight
    
    ; Total window container width remains 380 for clean padding
    newWidth := 380

        ApplyThemeToGui(MainGui)
    
    if (IsGuiVisible) {
        MainGui.GetPos(&gx, &gy, &gw, &gh)
        
        ; Grab current monitor metrics to properly adjust position transitions
        monitorNum := MonitorGetFromPoint(gx + (gw // 2), gy + (gh // 2))
        MonitorGetWorkArea(monitorNum, &wl, &wt, &wr, &wb)
        MonitorGet(monitorNum, &ml, &mt, &mr, &mb)
        
        ; Properly wrapped condition to prevent early evaluation closure
        if ((wt > mt) || (gy + (gh // 2) < (mt + mb) // 2)) {
            ; Top-anchored Taskbar: Expand downwards
            newY := gy
        } else {
            ; Bottom-anchored Taskbar: Expand upwards
            newY := gy + (gh - newHeight)
        }
        
        ; Enforce strict screen boundaries
        if (newY < wt)
            newY := wt
        if (newY + newHeight > wb)
            newY := wb - newHeight
        if (gx < wl)
            gx := wl
        if (gx + newWidth > wr)
            gx := wr - newWidth
            
        MainGui.Show("x" gx " y" newY " w" newWidth " h" newHeight)
    } else {
        MainGui.Move(,, newWidth, newHeight)
    }
}

; ==============================================================================
; Tray Icon Hover Activation System
; ==============================================================================
OnTrayMessage(wParam, lParam, msg, hwnd) {
    if (lParam == 0x200) { 
        if (IsGuiVisible)
            return

        A_IconTip := "" 

        CoordMode("Mouse", "Screen")
        MouseGetPos(&sX, &sY)
        global TrayStartX := sX
        global TrayStartY := sY

        SetTimer(CheckIfStillHovered, 0)

        hoverTime := 400 
        if !DllCall("SystemParametersInfo", "UInt", 0x0066, "UInt", 0, "Int*", &hoverTime, "UInt", 0)
            hoverTime := 400

        targetDelay := Max(100, hoverTime - 220)
        SetTimer(CheckIfStillHovered, -targetDelay)
    }
}

CheckIfStillHovered() {
    global IsGuiVisible, TrayStartX, TrayStartY, TrayMouseX, TrayMouseY, TrayLeaveCount, CurrentGuiHeight
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&currentX, &currentY, &targetHwnd)
    
    sX := TrayStartX
    sY := TrayStartY
    TrayStartX := 0
    TrayStartY := 0

    if (Abs(currentX - sX) > 5 || Abs(currentY - sY) > 5)
         return

    if (!targetHwnd)
        return

    TrayMouseX := currentX
    TrayMouseY := currentY
    
    RefreshSessionsForSelectedDevice()
    
    ; Determine correct screen parameters for safe clipping
    monitorNum := MonitorGetFromPoint(TrayMouseX, TrayMouseY)
    MonitorGetWorkArea(monitorNum, &wl, &wt, &wr, &wb)
    MonitorGet(monitorNum, &ml, &mt, &mr, &mb)
    
    w := 380 ; Matching total container width bounds
    h := CurrentGuiHeight
    spawnX := TrayMouseX - (w // 2)
    
    ; Contextually spawn above or below based on Taskbar positions
    if (wt > mt) {
        spawnY := TrayMouseY + 25
    } else if (wb < mb) {
        spawnY := TrayMouseY - h - 15
    } else {
        if (TrayMouseY > (mt + mb) // 2)
            spawnY := TrayMouseY - h - 15
        else
            spawnY := TrayMouseY + 25
    }
    
    if (spawnY < wt)
        spawnY := wt
    if (spawnY + h > wb)
        spawnY := wb - h
    if (spawnX < wl)
        spawnX := wl
    if (spawnX + w > wr)
        spawnX := wr - w
    
    MainGui.Show("X" spawnX " Y" spawnY " w" w " h" h " NoActivate")
    IsGuiVisible := true 
    
    DllCall("user32\SetWindowPos", "Ptr", MainGui.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0043)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MainGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
    
    TrayLeaveCount := 0 
    ; IMPROVEMENT: Changed timeout check execution delay from 400ms to 2400ms
    SetTimer(HideGuiWhenMouseLeaves, 2400)
}

HideGuiWhenMouseLeaves() {
    global IsGuiVisible, TrayMouseX, TrayMouseY, TrayLeaveCount, CurrentGuiHeight
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    MainGui.GetPos(&gx, &gy, &gw, &gh)
    
    mouseInsideGui := (mx >= gx && mx <= gx + gw && my >= gy && my <= gy + gh)
    padding := 20 
    mouseOverIconEstimate := (mx >= TrayMouseX - padding && mx <= TrayMouseX + padding && my >= TrayMouseY - padding && my <= TrayMouseY + padding)
    
    if (!mouseInsideGui && !mouseOverIconEstimate) {
        TrayLeaveCount++ 
        if (TrayLeaveCount >= 2) { 
            HideAudioMixerGui()
        }
    } else {
        TrayLeaveCount := 0 
    }
}

HideAudioMixerGui() {
    global IsGuiVisible, TrayMouseX, TrayMouseY
    IsGuiVisible := false
    TrayMouseX := 0
    TrayMouseY := 0
    SetTimer(HideGuiWhenMouseLeaves, 0)
    MainGui.Hide()
}

WM_ACTIVATE(wParam, lParam, msg, hwnd) {
    global MainGui

    if (!IsSet(Settings) || !IsSet(MainGui))
            return

    if (wParam == 0 && hwnd == MainGui.Hwnd) {
        HideAudioMixerGui()
    }
}

; ==============================================================================
; Audio Endpoint & Session Retrieval Logic
; ==============================================================================
PopulatePlaybackDevices() {
    global DeviceMap
    DeviceMap.Clear()
    deviceNames := []
    
    deviceEnum := ComObject(CLSID_MMDeviceEnumerator, IID_IMMDeviceEnumerator)
    ComCall(3, deviceEnum, "Int", 0, "UInt", 1, "Ptr*", &deviceCollection := 0)
    ComCall(3, deviceCollection, "UInt*", &deviceCount := 0)
    
    loop deviceCount {
        ComCall(4, deviceCollection, "UInt", A_Index - 1, "Ptr*", &device := 0)
        friendlyName := GetDeviceNameString(device)
        if (friendlyName == "") {
            friendlyName := "Unknown Device Line [" A_Index "]"
        }
        
        while DeviceMap.Has(friendlyName)
            friendlyName .= " "
            
        DeviceMap[friendlyName] := device
        deviceNames.Push(friendlyName)
    }
    return deviceNames
}

GetDeviceNameString(devicePtr) {
    ComCall(4, devicePtr, "UInt", 0, "Ptr*", &propertyStore := 0)
    propKey := Buffer(20, 0)
    DllCall("ole32\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "Ptr", propKey)
    NumPut("UInt", 14, propKey, 16) 
    
    varResult := Buffer(24, 0)
    ComCall(5, propertyStore, "Ptr", propKey, "Ptr", varResult)
    
    friendlyName := ""
    vt := NumGet(varResult, 0, "UShort")
    
    if (vt == 31) { 
        pStr := NumGet(varResult, 8, "Ptr")
        if (pStr != 0) {
            friendlyName := StrGet(pStr, "UTF-16")
            DllCall("ole32\CoTaskMemFree", "Ptr", pStr)
        }
    }
    ObjRelease(propertyStore)
    return friendlyName
}

GetDefaultDeviceFriendlyName() {
    try {
        deviceEnum := ComObject(CLSID_MMDeviceEnumerator, IID_IMMDeviceEnumerator)
        ComCall(4, deviceEnum, "Int", 0, "Int", 0, "Ptr*", &defaultDevice := 0)
        if (defaultDevice != 0) {
            name := GetDeviceNameString(defaultDevice)
            ObjRelease(defaultDevice)
            return name
        }
    }
    return ""
}

GetAudioSessionsForDevice(devicePtr) {
    sessions := []
    seenApps := Map()
    
    DllCall("ole32\CLSIDFromString", "Str", IID_IAudioSessionManager2, "Ptr", iidBuf := Buffer(16))
    hr := ComCall(3, devicePtr, "Ptr", iidBuf, "UInt", 23, "Ptr", 0, "Ptr*", &sessionManager := 0)
    if (hr != 0 || !sessionManager)
        return sessions
        
    ComCall(5, sessionManager, "Ptr*", &sessionEnum := 0)
    if (!sessionEnum)
        return sessions
        
    ComCall(3, sessionEnum, "Int*", &sessionCount := 0)
    
    loop sessionCount {
        ComCall(4, sessionEnum, "Int", A_Index - 1, "Ptr*", &sessionCtrl := 0)
        
        if !(sessionCtrl2 := ComObjQuery(sessionCtrl, IID_IAudioSessionControl2))
            continue
            
        ComCall(14, sessionCtrl2, "UInt*", &pid := 0)
        if (pid == 0 || !ProcessExist(pid))
            continue
            
        progName := ProcessGetName(pid)
        if seenApps.Has(progName)
            continue
        seenApps[progName] := true
        
        if !(simpleVol := ComObjQuery(sessionCtrl2, IID_ISimpleAudioVolume))
            continue
            
        ComCall(4, simpleVol, "Float*", &volScalar := 0)
        currentVol := Round(volScalar * 100)
        
        sessions.Push({
            PID: pid,
            ProgName: progName,
            Volume: currentVol,
            SimpleVol: simpleVol
        })
    }
    return sessions
}

SetAppVolume(simpleVol, newVolPercent) {
    newVolPercent := Max(0, Min(100, newVolPercent))
    scalarVol := newVolPercent / 100.0
    ComCall(3, simpleVol, "Float", scalarVol, "Ptr", 0)
}

; ==============================================================================
; Control & Mouse Wheel Handlers
; ==============================================================================
OnSliderChange(simpleVol, lblVol, sldCtrl, *) {
    newVol := sldCtrl.Value
    lblVol.Text := newVol
    SetAppVolume(simpleVol, newVol)
}

OnMouseWheel(wParam, lParam, msg, hwnd) {
    wheelDelta := (wParam << 32 >> 48)
    step := (wheelDelta > 0) ? 5 : -5
    
    MouseGetPos(,, &winHwnd, &ctrlHwnd, 2)
    
    if (ControlToSessionMap.Has(ctrlHwnd)) {
        data := ControlToSessionMap[ctrlHwnd]
        
        currentVal := data.Slider.Value
        newVal := Max(0, Min(100, currentVal + step))
        
        data.Slider.Value := newVal
        data.Label.Text := newVal
        
        SetAppVolume(data.SimpleVol, newVal)
        return 0 
    }
}

; ==============================================================================
; HELPER FUNCTIONS
; ==============================================================================
MonitorGetFromPoint(X, Y) {
    monitorCount := MonitorGetCount()
    Loop monitorCount {
        MonitorGet(A_Index, &Left, &Top, &Right, &Bottom)
        if (X >= Left && X <= Right && Y >= Top && Y <= Bottom)
            return A_Index
    }
    return MonitorGetPrimary()
}