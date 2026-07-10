#Requires AutoHotkey v2.0

global DynamicControls := []
global CurrentGuiHeight := 90 

global IsGuiVisible := false
global TrayStartX := 0, TrayStartY := 0
global TrayMouseX := 0, TrayMouseY := 0
global TrayLeaveCount := 0
global MainGui
global ChildGui := ""

; Track scrolling properties
global MaxGuiHeight := A_ScreenHeight
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
    MainGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner +0x00200000")
    MainGui.SetFont("s9", "Segoe UI")
    
    ; Child window (Holds all the actual buttons, text, and sliders)
    ChildGui := Gui("-Caption +Parent" MainGui.Hwnd)
    ChildGui.SetFont("s9", "Segoe UI")
    
    ; Monitor standard Windows vertical scroll updates
    OnMessage(0x0115, WM_VSCROLL) ; WM_VSCROLL
    RefreshSessionsForSelectedDevice()
}

RefreshSessionsForSelectedDevice() {
    global MainGui, ChildGui, DynamicControls, DeviceMap, IsGuiVisible
    global CurrentGuiHeight, TrayMouseX, TrayMouseY, MaxGuiHeight, VirtualGuiHeight, CurrentScrollPos
    
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

    DllCall("user32\RedrawWindow", "Ptr", MainGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 5)

    ; Minimal settings layout added directly to the scrolling child canvas
    btnSettings := ChildGui.Add("Button", "x341 y18 w28 h28", "⚙")
    btnSettings.OnEvent("Click", OpenSettingsWindow)
    DynamicControls.Push(btnSettings)

    deviceNames := PopulatePlaybackDevices()
    yPos := 25 ; starting position
    wWidth := 380

    ActiveDevices := []
    for deviceName in deviceNames {
        if (!VisibleDevicesConfig.Has(deviceName) || !VisibleDevicesConfig[deviceName])
            continue

        devicePtr := DeviceMap[deviceName]
        sessions := GetAudioSessionsForDevice(devicePtr)

        if (sessions.Length > 0) {
            ; Store both the name and its active sessions for the layout step
            ActiveDevices.Push({Name: deviceName, Sessions: sessions})
        }
    }
    
    ; 2. Loop through the prepared visible devices
    for index, device in ActiveDevices {
        lblDevice := ChildGui.Add("Text", "x15 y" yPos " w320 h20 +0x4000", StrUpper(device.Name))
        lblDevice.SetFont("q5 s8 Bold c0x0078D7")
        lblDevice.BypassTheme := true
        DynamicControls.Push(lblDevice)
        
        yPos += 40 ; after playback device
        
        for session in device.Sessions {
            SplitPath(session.ProgName, , , , &cleanProgName)
            lblApp := ChildGui.Add("Text", "x20 y" yPos " w100 h20 +0x4000", cleanProgName)
            sliderY := yPos - 7

            lblVol := ChildGui.Add("Text", "x338 y" yPos " w25 h20 Right", session.Volume)
            
            ; Instantiate the ModernSlider. Omitted theme params = Auto mode!
            sldVol := ModernSlider(ChildGui, "x125 y" sliderY " w215 h25", session.Volume, 0, 100, OnSliderChange.Bind(session.SimpleVol, lblVol))
            
            DynamicControls.Push(lblApp)
            DynamicControls.Push(lblVol)
            
            ; Push the underlying native AHK controls inside the class so the window destructor works
            DynamicControls.Push(sldVol.track)
            DynamicControls.Push(sldVol.thumb)
            
            yPos += 45 ; inter programs
        }
        
        ; 3. CHECK: Only add space/divider if this is NOT the last visible device in our list
        if (index < ActiveDevices.Length) {
            yPos += 15 ; after programs
        }
    }
    
    if (DynamicControls.Length <= 1) {
        lblEmpty := ChildGui.Add("Text", "x10 y45 w360 Center cGray", "No active audio playing on selected lines.")
        DynamicControls.Push(lblEmpty)
        yPos := 85
    }
    
    VirtualGuiHeight := yPos + 5
    
    ; Determine window frame size constraints vs scrolling availability
    if (VirtualGuiHeight > MaxGuiHeight) {
        newHeight := MaxGuiHeight
        
        si := Buffer(28, 0)
        NumPut("UInt", 28, si, 0)    ; cbSize
        NumPut("UInt", 0x17, si, 4)  ; fMask (SIF_RANGE | SIF_PAGE | SIF_POS)
        NumPut("Int", 0, si, 8)      ; nMin
        NumPut("Int", VirtualGuiHeight, si, 12) ; nMax
        NumPut("UInt", newHeight, si, 16)       ; nPage
        
        DllCall("user32\SetScrollInfo", "Ptr", MainGui.Hwnd, "Int", 1, "Ptr", si.Ptr, "Int", 1)
    } else {
        newHeight := VirtualGuiHeight
        DllCall("user32\ShowScrollBar", "Ptr", MainGui.Hwnd, "Int", 1, "Int", 0)
    }
    
    CurrentGuiHeight := newHeight

    if IsSet(ApplyThemeToGui) {
        ApplyThemeToGui(MainGui)
        ApplyThemeToGui(ChildGui)
        WatchedGUIs.Push(MainGui)
        WatchedGUIs.Push(ChildGui)
    }
    
    ; Resize the child canvas container to fit the total entries smoothly
    ChildGui.Move(0, 0, wWidth, VirtualGuiHeight)
    ChildGui.Show("NA")
    
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

        MainGui.Show("x" spawnX " y" spawnY " w" wWidth " h" newHeight " NoActivate")
    } else {
        MainGui.Move(,, wWidth, newHeight)
    }
}

OpenSettingsWindow(*) {
    global VisibleDevicesConfig
    settingsGui := Gui("+Owner" MainGui.Hwnd " +ToolWindow", "Volume Hover Configuration")
    settingsGui.SetFont("s10", "Segoe UI")
    settingsGui.Add("Text", "x15 y10 w350", "Select playback devices to show:")
    
    deviceNames := PopulatePlaybackDevices()
    checkboxes := Map()
    yOffset := 50

    settingsGui.SetFont("s9", "Segoe UI")
    for name in deviceNames {
        isChecked := (VisibleDevicesConfig.Has(name) && VisibleDevicesConfig[name]) ? "Checked" : ""
        chk := settingsGui.Add("Checkbox", "x20 y" yOffset " w340 " isChecked, "  " . name)
        checkboxes[name] := chk
        yOffset += 35
    }

    btnSave := settingsGui.Add("Button", "x140 y" (yOffset + 10) " w100 h25 Default", "&Save")
    btnSave.OnEvent("Click", SavePreferences)

    if IsSet(ApplyThemeToGui) {
        ApplyThemeToGui(settingsGui)
        WatchedGUIs.Push(settingsGui)
    }

    settingsGui.Show("w380 h" (yOffset + 50))
    
    SavePreferences(*) {
        visibleList := []
        for name, chkControl in checkboxes {
            VisibleDevicesConfig[name] := chkControl.Value
            if (chkControl.Value)
                visibleList.Push(name)
        }
        
        savedString := ""
        for idx, name in visibleList {
            savedString .= (idx == 1 ? "" : ",") . name
        }
        
        General.PlaybackDevices := savedString
        if IsSet(SaveINI)
            SaveINI()
            
        settingsGui.Destroy()
        RefreshSessionsForSelectedDevice()
    }
}

OnTrayMessage(wParam, lParam, msg, hwnd) {
    if (lParam == 0x200 || lParam == 0x201) { 
        if (IsGuiVisible)
            return
        A_IconTip := "" 
        CoordMode("Mouse", "Screen")
        MouseGetPos(&sX, &sY)
        
        global TrayStartX := sX, TrayStartY := sY

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
    
    sX := TrayStartX, sY := TrayStartY
    TrayStartX := 0, TrayStartY := 0

    if (Abs(currentX - sX) > 5 || Abs(currentY - sY) > 5 || !targetHwnd)
         return

    TrayMouseX := currentX, TrayMouseY := currentY
    
    RefreshSessionsForSelectedDevice()
    
    monitorNum := MonitorGetFromPoint(TrayMouseX, TrayMouseY)
    MonitorGetWorkArea(monitorNum, &wl, &wt, &wr, &wb)
    MonitorGet(monitorNum, &ml, &mt, &mr, &mb)
    
    w := 380 
    h := CurrentGuiHeight
    spawnX := TrayMouseX - (w // 2)
    
    if (wt > mt) {
        spawnY := TrayMouseY + 25
    } else if (wb < mb) {
        spawnY := TrayMouseY - h - 15
    } else {
        spawnY := (TrayMouseY > (mt + mb) // 2) ? TrayMouseY - h - 15 : TrayMouseY + 25
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
    SetTimer(HideGuiWhenMouseLeaves, hovertimeout)
}

HideGuiWhenMouseLeaves() {
    global IsGuiVisible, TrayMouseX, TrayMouseY, TrayLeaveCount
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    MainGui.GetPos(&gx, &gy, &gw, &gh)
    
    mouseInsideGui := (mx >= gx && mx <= gx + gw && my >= gy && my <= gy + gh)
    padding := 20 
    mouseOverIconEstimate := (mx >= TrayMouseX - padding && mx <= TrayMouseX + padding && my >= TrayMouseY - padding && my <= TrayMouseY + padding)
    
    if (!mouseInsideGui && !mouseOverIconEstimate) {
        TrayLeaveCount++ 
        if (TrayLeaveCount >= 2)
            HideAudioMixerGui()
    } else {
        TrayLeaveCount := 0 
    }
}

HideAudioMixerGui() {
    global IsGuiVisible, TrayMouseX, TrayMouseY
    IsGuiVisible := false, TrayMouseX := 0, TrayMouseY := 0
    SetTimer(HideGuiWhenMouseLeaves, 0)
    MainGui.Hide()
}

WM_ACTIVATE(wParam, lParam, msg, hwnd) {
    global MainGui
    if (!IsSet(MainGui))
        return
    if (wParam == 0 && hwnd == MainGui.Hwnd) {
        HideAudioMixerGui()
    }
}

; Adapted to accept the new dynamic value from the class directly
OnSliderChange(simpleVol, lblVol, newVol, *) {
    lblVol.Text := newVol
    SetAppVolume(simpleVol, newVol)
}

; Simplified: Only handles canvas window scrolling now. The Slider handles its own volume scrolls!
OnMouseWheel(wParam, lParam, msg, hwnd) {
    global MainGui, CurrentScrollPos, VirtualGuiHeight, CurrentGuiHeight
    
    if (VirtualGuiHeight > CurrentGuiHeight) {
        wheelDelta := (wParam << 32 >> 48)
        scrollAmount := (wheelDelta > 0) ? -24 : 24
        ScrollGuiWindow(scrollAmount)
        return 0
    }
}

ScrollGuiWindow(amount) {
    global MainGui, ChildGui, CurrentScrollPos, VirtualGuiHeight, CurrentGuiHeight
    maxScroll := VirtualGuiHeight - CurrentGuiHeight
    newScroll := Max(0, Min(maxScroll, CurrentScrollPos + amount))
    
    if (newScroll != CurrentScrollPos) {
        CurrentScrollPos := newScroll
        
        ; Physically slide the ChildGui panel up/down relative to parent viewport frame
        ChildGui.Move(0, -CurrentScrollPos)
        DllCall("user32\SetScrollPos", "Ptr", MainGui.Hwnd, "Int", 1, "Int", CurrentScrollPos, "Int", 1)
    }
}

WM_VSCROLL(wParam, lParam, msg, hwnd) {
    global MainGui, CurrentScrollPos, VirtualGuiHeight, CurrentGuiHeight
    if (hwnd != MainGui.Hwnd)
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