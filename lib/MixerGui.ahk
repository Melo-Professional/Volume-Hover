#Requires AutoHotkey v2.0

; Register GUI Window Messages
MessageManager.Register(0x020A, OnMouseWheel)
MessageManager.Register(0x0006, WM_ACTIVATE)

global DynamicControls := []
global SliderControlMap := Map() ; Maps full session programmatic paths to ModernSlider/Text components
global CurrentGuiHeight := 90

global IsGuiVisible := false
global WheelUsedDuringHover := false
global TrayLeaveCount := 0
global MainGui := ""
global ChildGui := ""

; Track scrolling properties
global MaxGuiHeight := A_ScreenHeight - 80
global VirtualGuiHeight := 0
global CurrentScrollPos := 0
global hovertimeout := 1000

; Initial tracking container (populated via General.PlaybackDevices)
global VisibleDevicesConfig := Map() 

LoadDeviceConfig() {
    global VisibleDevicesConfig
    VisibleDevicesConfig := Map()
    deviceNames := PopulatePlaybackDevices()
    
    if (General.HasOwnProp("PlaybackDevices") && General.PlaybackDevices != "") {
        for name in deviceNames
            VisibleDevicesConfig[name] := false
            
        for name in StrSplit(General.PlaybackDevices, ",") {
            if (name != "")
                VisibleDevicesConfig[name] := true
        }
    } else {
        for name in deviceNames
            VisibleDevicesConfig[name] := true
    }
}

CreateAudioMixerGui() {
    global MainGui, ChildGui
    LoadDeviceConfig()
    
    ; Main container window (Acts as the viewing viewport frame)
    MainGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    MainGui.SetFont("s9", "Segoe UI")

    ; Child window (Holds all the actual buttons, text, and sliders)
    ChildGui := Gui("-Caption +Parent" MainGui.Hwnd)
    ChildGui.SetFont("cWhite s9", "Segoe UI")
    ChildGui.BackColor := "262626"
    
    RefreshSessionsForSelectedDevice()

    ; Apply the theme strictly ONCE during creation
    FrostedTheme.Apply(MainGui)
    
    ; Monitor standard Windows vertical scroll updates
    MessageManager.Register(0x0115, WM_VSCROLL)
    
    Sleep(500)
    
    ; Instantiate off-screen to initialize styles cleanly without taking focus
    MainGui.Show("x-32000 y-32000 w380 h90 NoActivate Hide")
    
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MainGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
}

RefreshSessionsForSelectedDevice() {
    global MainGui, ChildGui, DynamicControls, SliderControlMap, DeviceMap, IsGuiVisible
    global CurrentGuiHeight, MaxGuiHeight, VirtualGuiHeight, CurrentScrollPos
    
    ; If Gui doesn't exist yet, create it
    if (MainGui == "" || !WinExist(MainGui.Hwnd)) {
        CreateAudioMixerGui()
        return
    }
    
    ; Calculate DPI scaling factor for custom controls
    scaleFactor := A_ScreenDPI / 96
    
    ; Reset scroll position to top before rebuilding
    CurrentScrollPos := 0
    if (ChildGui != "")
        ChildGui.Move(0, 0)
    DllCall("user32\SetScrollPos", "Ptr", MainGui.Hwnd, "Int", 1, "Int", 0, "Int", 1)
    
    ; Clear old elements from the ChildGui canvas safely
    for ctrl in DynamicControls {
        try DllCall("user32\DestroyWindow", "Ptr", ctrl.Hwnd)
    }
    DynamicControls := [] 
    SliderControlMap := Map()

    DllCall("user32\RedrawWindow", "Ptr", MainGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 5)

    ; Settings menu icon aligned top-right
    ChildGui.SetFont("s14", "Segoe UI")
    btnSettings := ChildGui.Add("Text", "cWhite x335 y19 w30 h28 Right", "⫶☰")
    btnSettings.OnEvent("Click", SelectPlaybackDevicesGUI)
    DynamicControls.Push(btnSettings)

    ChildGui.SetFont("s9", "Segoe UI")
    deviceNames := PopulatePlaybackDevices()
    yPos := 25
    wWidth := 380

    ActiveDevices := []
    for deviceName in deviceNames {
        if (!VisibleDevicesConfig.Has(deviceName) || !VisibleDevicesConfig[deviceName])
            continue

        devicePtr := DeviceMap[deviceName]
        sessions := GetAudioSessionsForDevice(devicePtr)

        if (sessions.Length > 0) {
            ActiveDevices.Push({Name: deviceName, Sessions: sessions})
        }
    }
    
    ; Loop through visible devices
    for index, device in ActiveDevices {
        lblDevice := ChildGui.Add("Text", "x15 y" yPos " w300 h20 +0x4000", StrUpper(device.Name))
        lblDevice.SetFont("q5 s8 Bold c0x0078D7")
        lblDevice.BypassTheme := true
        DynamicControls.Push(lblDevice)
        
        yPos += 40
        
        for session in device.Sessions {
            SplitPath(session.ProgName, , , , &cleanProgName)
            
            ; App Label (x15, w95)
            lblApp := ChildGui.Add("Text", "x15 y" yPos " w95 h20 cWhite +0x4000 +0x0200", cleanProgName)
            sliderY := yPos - 1

            ; Volume Label (x318, w45 Right-Aligned)
            lblVol := ChildGui.Add("Text", "x318 y" yPos " w45 h20 cWhite Right +0x0200", session.Volume)
            lblVol.SetFont("cWhite w600 s9", "Segoe UI")
            
            ; Dynamically scale slider track width for High DPI / 4K displays
            sliderW := Floor(210 * scaleFactor)
            sldVol := ModernSlider(ChildGui, "x112 y" sliderY " w" sliderW " h20", session.Volume, 0, 100, OnSliderChange.Bind(session.SimpleVol, lblVol))
            
            SliderControlMap[StrLower(session.ProgName)] := {Slider: sldVol, Label: lblVol, Session: session.SimpleVol}
            
            DynamicControls.Push(lblApp)
            DynamicControls.Push(lblVol)
            DynamicControls.Push(sldVol.sliderCtrl)
            DynamicControls.Push(sldVol)
            
            yPos += 45
        }
        
        if (index < ActiveDevices.Length) {
            yPos += 15
        }
    }
    
    if (DynamicControls.Length <= 1) {
        lblEmpty := ChildGui.Add("Text", "x10 y45 w360 Center cGray", "No active audio playing on selected lines.")
        DynamicControls.Push(lblEmpty)
        yPos := 85
    }
    
    VirtualGuiHeight := yPos + 5
    
    if (VirtualGuiHeight > MaxGuiHeight) {
        newHeight := MaxGuiHeight
        
        si := Buffer(28, 0)
        NumPut("UInt", 28, si, 0)
        NumPut("UInt", 0x17, si, 4)
        NumPut("Int", 0, si, 8)
        NumPut("Int", VirtualGuiHeight, si, 12)
        NumPut("UInt", newHeight, si, 16)
        
        DllCall("user32\SetScrollInfo", "Ptr", MainGui.Hwnd, "Int", 1, "Ptr", si.Ptr, "Int", 1)
        DllCall("user32\ShowScrollBar", "Ptr", MainGui.Hwnd, "Int", 1, "Int", 0)
    } else {
        newHeight := VirtualGuiHeight
        DllCall("user32\ShowScrollBar", "Ptr", MainGui.Hwnd, "Int", 1, "Int", 0)
    }
    
    CurrentGuiHeight := newHeight
    
    ChildGui.Show("x0 y0 w" wWidth " h" VirtualGuiHeight " NA")
    
    if (IsGuiVisible) {
        MainGui.GetPos(&gx, &gy, &gw, &gh)
        
        spawnX := gx
        monitorNum := MonitorGetFromPoint(gx + (gw // 2), gy + (gh // 2))
        MonitorGetWorkArea(monitorNum, &wl, &wt, &wr, &wb)
        MonitorGet(monitorNum, &ml, &mt, &mr, &mb)
        
        if ((wt > mt) || (gy + (gh // 2) < (mt + mb) // 2)) {
            spawnY := gy
        } else {
            spawnY := gy + (gh - newHeight)
        }
        
        if (spawnY < wt)
            spawnY := wt
        if (spawnY + newHeight > wb)
            spawnY := wb - newHeight
        if (spawnX < wl)
            spawnX := wl
        if (spawnX + wWidth > wr)
            spawnX := wr - wWidth

        scaledW := Floor(wWidth * scaleFactor)
        scaledH := Floor(newHeight * scaleFactor)

        DllCall("User32\SetWindowPos", 
            "Ptr", MainGui.Hwnd, 
            "Ptr", 0, 
            "Int", spawnX, 
            "Int", spawnY, 
            "Int", scaledW, "Int", scaledH, 
            "UInt", 0x0010 | 0x0004
        )
    } else {
        DllCall("User32\ShowWindow", "Ptr", MainGui.Hwnd, "Int", 0)
    }
}

UpdateSpecificSliderValue(progName, stepDelta) {
    global SliderControlMap
    lookupKey := StrLower(progName)
    if (SliderControlMap.Has(lookupKey)) {
        controlSet := SliderControlMap[lookupKey]
        currentVal := 0
        
        ; Query modern slider's internal tracking
        try {
            currentVal := Number(controlSet.Slider.sliderCtrl.Value)
        } catch {
            try {
                txtVal := controlSet.Label.Text
                currentVal := (txtVal == "") ? 0 : Number(txtVal)
            } catch {
                currentVal := 0
            }
        }
        
        newVal := Max(0, Min(100, currentVal + stepDelta))
        
        ; Update the visual text label
        controlSet.Label.Text := newVal
        
        ; Synchronize custom wrapper instance tracking to visually repaint track/thumb elements
        try {
            controlSet.Slider.Value := newVal
        } catch {
            try {
                controlSet.Slider.sliderCtrl.Value := newVal
            }
        }
        
        ; Commit change directly to CoreAudio endpoint
        SetAppVolume(controlSet.Session, newVal)
    }
}

AdjustMasterVolume(stepDelta) {
    SoundSetVolume(stepDelta > 0 ? "+" . stepDelta : stepDelta)
}

ShowMixerGuiNow() {
    global IsGuiVisible, TrayLeaveCount, CurrentGuiHeight, MainGui, hovertimeout, TrayHandler, WheelUsedDuringHover
    
    if (WheelUsedDuringHover) {
        WheelUsedDuringHover := false
        return
    }

    if (MainGui == "" || !WinExist(MainGui.Hwnd)) {
        CreateAudioMixerGui()
    } else {
        RefreshSessionsForSelectedDevice()
    }

    scaleFactor := A_ScreenDPI / 96
    
    w := Floor(380 * scaleFactor)
    h := Floor(CurrentGuiHeight * scaleFactor)
    
    ; Retrieve taskbar positioning metadata
    tbInfo := TrayHandler.GetTaskbarPosition()
    MonitorGetWorkArea(tbInfo.Monitor, &wl, &wt, &wr, &wb)
    MonitorGet(tbInfo.Monitor, &ml, &mt, &mr, &mb)

    TrayMouseX := TrayHandler.TrayMouseX
    TrayMouseY := TrayHandler.TrayMouseY

    ; Fallback: If no tray mouse event was recorded yet (e.g., FirstRun), target the taskbar tray area
    if (TrayMouseX == 0 && TrayMouseY == 0) {
        switch tbInfo.Pos {
            case "Top":
                TrayMouseX := wr - Floor(100 * scaleFactor)
                TrayMouseY := mt
            case "Left":
                TrayMouseX := ml
                TrayMouseY := wb - Floor(50 * scaleFactor)
            case "Right":
                TrayMouseX := mr
                TrayMouseY := wb - Floor(50 * scaleFactor)
            default: ; Bottom taskbar
                TrayMouseX := wr - Floor(100 * scaleFactor)
                TrayMouseY := mb
        }
    }

    spawnX := TrayMouseX - (w // 2)
    
    ; Calculate vertical placement relative to taskbar position
    switch tbInfo.Pos {
        case "Top":
            spawnY := TrayMouseY + Floor(25 * scaleFactor)
        case "Bottom":
            spawnY := TrayMouseY - h - Floor(15 * scaleFactor)
        default:
            spawnY := (TrayMouseY > (mt + mb) // 2) ? TrayMouseY - h - Floor(15 * scaleFactor) : TrayMouseY + Floor(25 * scaleFactor)
    }
    
    ; Clamp inside working area boundaries
    if (spawnY < wt)
        spawnY := wt
    if (spawnY + h > wb)
        spawnY := wb - h
    if (spawnX < wl)
        spawnX := wl
    if (spawnX + w > wr)
        spawnX := wr - w
    
    DllCall("User32\SetWindowPos", "Ptr", MainGui.Hwnd, "Ptr", 0, "Int", spawnX, "Int", spawnY, "Int", w, "Int", h, "UInt", 0x0014 | 0x0040)
    
    IsGuiVisible := true
    DllCall("user32\SetWindowPos", "Ptr", MainGui.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0043)
    
    TrayLeaveCount := 0 
    SetTimer(HideGuiWhenMouseLeaves, hovertimeout)
}

HideGuiWhenMouseLeaves() {
    global IsGuiVisible, TrayLeaveCount, MainGui, ChildGui, hovertimeout, TrayHandler

    if (MainGui == "" || !WinExist(MainGui.Hwnd)) {
        return
    }

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    
    ; Get actual physical window bounding box via Win32 API
    rect := Buffer(16, 0)
    DllCall("User32\GetWindowRect", "Ptr", MainGui.Hwnd, "Ptr", rect)
    gx := NumGet(rect, 0, "Int")   ; Physical Left
    gy := NumGet(rect, 4, "Int")   ; Physical Top
    gr := NumGet(rect, 8, "Int")   ; Physical Right
    gb := NumGet(rect, 12, "Int")  ; Physical Bottom
    
    ; Check if mouse is within physical window rectangle
    mouseInsideGui := (mx >= gx && mx <= gr && my >= gy && my <= gb)
    
    ; Utilize TrayIconHandler state and bounds tracking
    padding := Floor(24 * (A_ScreenDPI / 96))
    mouseOverIconEstimate := (mx >= TrayHandler.TrayMouseX - padding && mx <= TrayHandler.TrayMouseX + padding && my >= TrayHandler.TrayMouseY - padding && my <= TrayHandler.TrayMouseY + padding)

    if (!mouseInsideGui && !mouseOverIconEstimate) {
        TrayLeaveCount++ 
        if (TrayLeaveCount >= 2)
            HideAudioMixerGui()
    } else {
        TrayLeaveCount := 0 
    }
}

HideAudioMixerGui() {
    global IsGuiVisible, MainGui

    IsGuiVisible := false
    SetTimer(HideGuiWhenMouseLeaves, 0)
    
    if (MainGui != "" && WinExist(MainGui.Hwnd)) {
        ; Send window to coordinates outside visible boundaries without triggering structural focus signals
        DllCall("User32\SetWindowPos", 
            "Ptr", MainGui.Hwnd, 
            "Ptr", 0, 
            "Int", -32000, "Int", -32000, 
            "Int", 0, "Int", 0, 
            "UInt", 0x0010 | 0x0004 | 0x0001 ; SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOSIZE
        )
        
        ; Execute standard background hiding operation completely focus-free
        DllCall("User32\ShowWindow", "Ptr", MainGui.Hwnd, "Int", 0) ; SW_HIDE
    }
}

WM_ACTIVATE(wParam, lParam, msg, hwnd) {
    global MainGui
    if (MainGui == "" || !WinExist(MainGui.Hwnd))
        return
    if (wParam == 0 && hwnd == MainGui.Hwnd) {
        HideAudioMixerGui()
    }
}

OnSliderChange(simpleVol, lblVol, newVol, *) {
    lblVol.Text := newVol
    SetAppVolume(simpleVol, newVol)
}

OnMouseWheel(wParam, lParam, msg, hwnd) {
    global MainGui, CurrentScrollPos, VirtualGuiHeight, CurrentGuiHeight
    if (MainGui == "" || !WinExist(MainGui.Hwnd))
        return
    
    ; 1. Extract screen coordinates from lParam (WM_MOUSEWHEEL passes screen coords)
    xScreen := lParam & 0xFFFF
    if (xScreen > 0x7FFF) 
        xScreen -= 0x10000
        
    yScreen := (lParam >> 16) & 0xFFFF
    if (yScreen > 0x7FFF)
        yScreen -= 0x10000

    ; 2. Convert screen coordinates to client coordinates relative to MainGui
    pt := Buffer(8)
    NumPut("Int", xScreen, pt, 0)
    NumPut("Int", yScreen, pt, 4)
    DllCall("ScreenToClient", "Ptr", MainGui.Hwnd, "Ptr", pt)
    mouseX := NumGet(pt, 0, "Int")
    
    ; 3. If mouse is on the left side (< 125), scroll the main GUI. 
    ; If >= 125, do nothing here and let ModernSlider.HandleWheelMessage take over.
    if (mouseX < 125) {
        if (VirtualGuiHeight > CurrentGuiHeight) {
            wheelDelta := (wParam << 32 >> 48)
            scrollAmount := (wheelDelta > 0) ? -24 : 24
            ScrollGuiWindow(scrollAmount)
            return 0
        }
    }
}

ScrollGuiWindow(amount) {
    global MainGui, ChildGui, CurrentScrollPos, VirtualGuiHeight, CurrentGuiHeight
    if (MainGui == "" || !WinExist(MainGui.Hwnd))
        return
        
    maxScroll := VirtualGuiHeight - CurrentGuiHeight
    newScroll := Max(0, Min(maxScroll, CurrentScrollPos + amount))
    
    if (newScroll != CurrentScrollPos) {
        CurrentScrollPos := newScroll
        
        ChildGui.Move(0, -CurrentScrollPos)
        DllCall("user32\SetScrollPos", "Ptr", MainGui.Hwnd, "Int", 1, "Int", CurrentScrollPos, "Int", 1)
    }
}

WM_VSCROLL(wParam, lParam, msg, hwnd) {
    global MainGui, CurrentScrollPos, VirtualGuiHeight, CurrentGuiHeight
    if (MainGui == "" || !WinExist(MainGui.Hwnd) || hwnd != MainGui.Hwnd)
        return
        
    action := wParam & 0xFFFF
    maxScroll := VirtualGuiHeight - CurrentGuiHeight
    
    if (action == 0) ; SB_LINEUP
        ScrollGuiWindow(-24)
    else if (action == 1) ; SB_LINEDOWN
        ScrollGuiWindow(24)
    else if (action == 2) ; SB_PAGEUP
        ScrollGuiWindow(-72)
    else if (action == 3) ; SB_PAGEDOWN
        ScrollGuiWindow(72)
    else if (action == 4 || action == 5) { ; SB_THUMBPOSITION / SB_THUMBTRACK
        pos := (wParam >> 16) & 0xFFFF
        ScrollGuiWindow(pos - CurrentScrollPos)
    }
    return 0
}

MonitorGetFromPoint(X, Y) {
    monitorCount := MonitorGetCount()
    Loop monitorCount {
        MonitorGet(A_Index, &Left, &Top, &Right, &Bottom)
        if (X >= Left && X <= Right && Y >= Top && Y <= Bottom)
            return A_Index
    }
    return MonitorGetPrimary()
}

ShowTrayMenu() {
	TrayHandler.IsMouseOver := false
	A_TrayMenu.Show()
}

AdjustTargetAppVolume(stepDelta) {
    global IsGuiVisible, WheelUsedDuringHover
    
    ; Mark that wheel was used so the hover timer won't open the GUI
    WheelUsedDuringHover := true
    
    targetApp := GetTrueFirstActiveApp()
    
    if (targetApp != "") {
        if (IsGuiVisible) {
            ; If GUI is up, route directly to the slider wrapper to update without a complete rebuild
            UpdateSpecificSliderValue(targetApp, stepDelta)
        } else {
            AppVolumeControl.HoverWindow(stepDelta, targetApp)
        }
    }
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

ResetHoverFlags() {
    global WheelUsedDuringHover
    WheelUsedDuringHover := false
}