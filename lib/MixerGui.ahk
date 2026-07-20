#Requires AutoHotkey v2.0

global DynamicControls := []
global SliderControlMap := Map() ; Maps full session programmatic paths to ModernSlider/Text components
global CurrentGuiHeight := 90 

global IsGuiVisible := false
global TrayStartX := 0, TrayStartY := 0
global TrayMouseX := 0, TrayMouseY := 0
global TrayLeaveCount := 0
global MainGui := ""
global ChildGui := ""

; Track scrolling properties
global MaxGuiHeight := A_ScreenHeight - 80
global VirtualGuiHeight := 0
global CurrentScrollPos := 0
global hovertimeout := 1000

global TrayHoverStartTime := 0
global WheelUsedDuringHover := false

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
    global CurrentGuiHeight, TrayMouseX, TrayMouseY, MaxGuiHeight, VirtualGuiHeight, CurrentScrollPos
    
    ; If Gui doesn't exist yet, create it
    if (MainGui == "" || !WinExist(MainGui.Hwnd)) {
        CreateAudioMixerGui()
        return
    }
    
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

    ; Minimal settings layout added directly to the scrolling child canvas
    ChildGui.SetFont("s14", "Segoe UI")
    btnSettings := ChildGui.Add("Text", "cWhite x341 y20 w28 h28", "⫶☰")
    btnSettings.OnEvent("Click", SelectPlaybackDevicesGUI)
    DynamicControls.Push(btnSettings)

    ChildGui.SetFont("s9", "Segoe UI")
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
            ActiveDevices.Push({Name: deviceName, Sessions: sessions})
        }
    }
    
    ; Loop through the prepared visible devices
    for index, device in ActiveDevices {
        lblDevice := ChildGui.Add("Text", "x15 y" yPos " w320 h20 +0x4000", StrUpper(device.Name))
        lblDevice.SetFont("q5 s8 Bold c0x0078D7")
        lblDevice.BypassTheme := true
        DynamicControls.Push(lblDevice)
        
        yPos += 40 ; after playback device
        
        for session in device.Sessions {
            SplitPath(session.ProgName, , , , &cleanProgName)
            lblApp := ChildGui.Add("Text", "x20 y" yPos " w100 h20 cWhite +0x4000 +0x0200", cleanProgName)
            sliderY := yPos - 1

            lblVol := ChildGui.Add("Text", "x338 y" yPos " w25 h20 cWhite Right +0x0200", session.Volume)
            lblVol.SetFont("cWhite w600 s9", "Segoe UI")
            
            ; Instantiate the ModernSlider
            sldVol := ModernSlider(ChildGui, "x125 y" sliderY " w215 h20", session.Volume, 0, 100, OnSliderChange.Bind(session.SimpleVol, lblVol))
            
            ; Save tracking associations to update without structural refreshes later
            SliderControlMap[StrLower(session.ProgName)] := {Slider: sldVol, Label: lblVol, Session: session.SimpleVol}
            
            DynamicControls.Push(lblApp)
            DynamicControls.Push(lblVol)
            
            ; Push the underlying native AHK controls inside the class so the window destructor works
            DynamicControls.Push(sldVol.sliderCtrl)
            DynamicControls.Push(sldVol)
            
            yPos += 45 ; inter programs
        }
        
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
        DllCall("user32\ShowScrollBar", "Ptr", MainGui.Hwnd, "Int", 1, "Int", 0)
    } else {
        newHeight := VirtualGuiHeight
        DllCall("user32\ShowScrollBar", "Ptr", MainGui.Hwnd, "Int", 1, "Int", 0)
    }
    
    CurrentGuiHeight := newHeight
    
    ; Explicitly show child layout frame without taking focus
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

        ; Dynamic resizing/repositioning processed via Win32 to prevent window activation
        DllCall("User32\SetWindowPos", 
            "Ptr", MainGui.Hwnd, 
            "Ptr", 0, 
            "Int", spawnX, 
            "Int", spawnY, 
            "Int", wWidth, "Int", newHeight, 
            "UInt", 0x0010 | 0x0004 ; SWP_NOACTIVATE | SWP_NOZORDER
        )
    } else {
        ; Completely hidden state fallback processed safely without focus signals
        DllCall("User32\ShowWindow", "Ptr", MainGui.Hwnd, "Int", 0) ; SW_HIDE
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

OnTrayMessage(wParam, lParam, msg, hwnd) {
    global mouseOverIconEstimate, TrayMouseX, TrayMouseY, TrayHoverStartTime, WheelUsedDuringHover, IsGuiVisible
    
    ; 0x200 = WM_MOUSEMOVE
    if (lParam == 0x200) {
        if (!mouseOverIconEstimate) {
            mouseOverIconEstimate := true
            WheelUsedDuringHover := false
            TrayHoverStartTime := A_TickCount
            
            CoordMode("Mouse", "Screen")
            MouseGetPos(&TrayMouseX, &TrayMouseY)
            
            ; Start a fast watchdog to actively poll the mouse position
            SetTimer(TrayHoverWatchdog, 50) 
        }
    } 
    ; 0x201 = WM_LBUTTONDOWN, 0x202 = WM_LBUTTONUP
    else if (lParam == 0x201 || lParam == 0x202) {
        if (!IsGuiVisible) {
            WheelUsedDuringHover := true ; Prevent hover timer from double-triggering
            ShowMixerGuiNow()
        }
    }
}

TrayHoverWatchdog() {
    global mouseOverIconEstimate, TrayMouseX, TrayMouseY, TrayHoverStartTime, WheelUsedDuringHover, IsGuiVisible
    
    if (!mouseOverIconEstimate) {
        SetTimer(TrayHoverWatchdog, 0)
        return
    }
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&currentX, &currentY)
    
    ; Define a bounding box (padding) around the tray icon
    padding := 24
    isInside := (Abs(currentX - TrayMouseX) <= padding && Abs(currentY - TrayMouseY) <= padding)
    
    if (!isInside) {
        ; Mouse has successfully left the tray icon bounds
        mouseOverIconEstimate := false
        SetTimer(TrayHoverWatchdog, 0)
        return
    }
    
    ; If hovered for 800ms, wheel wasn't used, and GUI isn't already visible
    if (!IsGuiVisible && !WheelUsedDuringHover && (A_TickCount - TrayHoverStartTime >= 800)) {
        ShowMixerGuiNow()
    }
}

ShowMixerGuiNow() {
    global IsGuiVisible, TrayMouseX, TrayMouseY, TrayLeaveCount, CurrentGuiHeight, MainGui, hovertimeout
    
    if (MainGui == "" || !WinExist(MainGui.Hwnd)) {
        CreateAudioMixerGui()
    } else {
        RefreshSessionsForSelectedDevice()
    }

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
    
    DllCall("User32\SetWindowPos", "Ptr", MainGui.Hwnd, "Ptr", 0, "Int", spawnX, "Int", spawnY, "Int", w, "Int", h, "UInt", 0x0014 | 0x0040)
    
    IsGuiVisible := true
    DllCall("user32\SetWindowPos", "Ptr", MainGui.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0043)
    
    TrayLeaveCount := 0 
    SetTimer(HideGuiWhenMouseLeaves, hovertimeout)
}

HideGuiWhenMouseLeaves() {
    global IsGuiVisible, TrayMouseX, TrayMouseY, TrayLeaveCount, MainGui, ChildGui, hovertimeout, mouseOverIconEstimate

    if (MainGui == "" || !WinExist(MainGui.Hwnd)) {
        mouseOverIconEstimate := false
        return
    }

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    MainGui.GetPos(&gx, &gy, &gw, &gh)
    
    mouseInsideGui := (mx >= gx && mx <= gx + gw && my >= gy && my <= gy + gh)
    padding := 24 
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
    global IsGuiVisible, TrayMouseX, TrayMouseY, MainGui

    IsGuiVisible := false
    TrayMouseX := 0
    TrayMouseY := 0
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
    
    if (VirtualGuiHeight > CurrentGuiHeight) {
        wheelDelta := (wParam << 32 >> 48)
        scrollAmount := (wheelDelta > 0) ? -24 : 24
        ScrollGuiWindow(scrollAmount)
        return 0
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