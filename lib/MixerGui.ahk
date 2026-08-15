#Requires AutoHotkey v2.0

; Register GUI Window Messages (Only keeping VScroll and Activate)
MessageManager.Register(0x0006, WM_ACTIVATE)

global DynamicControls := []
global SliderControlMap := Map() ; Maps full session programmatic paths to ModernSlider/Text components
global CurrentGuiHeight := 90

global IsGuiVisible := false
global WheelUsedDuringHover := false
global MainGui := ""
global ChildGui := ""

; GuiTracker Instances
global MainTracker := ""
global ChildTracker := ""

; Track scrolling properties
global MaxGuiHeight := A_ScreenHeight - 80
global VirtualGuiHeight := 0
global CurrentScrollPos := 0
global hovertimeout := 400

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
    global MainGui, ChildGui, MainTracker, ChildTracker
    LoadDeviceConfig()
    
    ; Main container window (Acts as the viewing viewport frame)
    MainGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
    MainGui.SetFont("s9", "Segoe UI")

    ; Child window (Holds all the actual buttons, text, and sliders)
    ChildGui := Gui("-Caption +Parent" MainGui.Hwnd)
    ChildGui.SetFont("cWhite s9", "Segoe UI")
    ChildGui.BackColor := "262626"
    
    ; --- Initialize GuiTrackers ---
    ; Route background scrolls to the window scroller, and manage hover visibility
    MainTracker := GuiTracker()
    MainTracker.AddGui := MainGui
    MainTracker.RegisterGui(Map(
        "OnEnter",     (*) => CancelHide(),
        "OnLeave",     (*) => ScheduleHide(),
        "OnWheelUp",   (*) => ScrollGuiWindow(-24),
        "OnWheelDown", (*) => ScrollGuiWindow(24)
    ))

    ChildTracker := GuiTracker()
    ChildTracker.AddGui := ChildGui
    ChildTracker.RegisterGui(Map(
        "OnEnter",     (*) => CancelHide(),
        "OnLeave",     (*) => ScheduleHide(),
        "OnWheelUp",   (*) => ScrollGuiWindow(-24),
        "OnWheelDown", (*) => ScrollGuiWindow(24)
    ))

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
    global CurrentGuiHeight, MaxGuiHeight, VirtualGuiHeight, CurrentScrollPos, ChildTracker
    
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
    btnSettings := ChildGui.Add("Text", "cWhite x335 y19 w30 h28 Center 0x0200 Background1b1b1b", "⫶☰")
    
    ; Wire settings button via GuiTracker instead of OnEvent
    ChildTracker.RegisterControl(btnSettings, Map(
		"OnEnter", (ctrl) => (ctrl.Opt("+Background313131"), ctrl.Redraw()),
		"OnLeave", (ctrl) => (ctrl.Opt("+Background1b1b1b"), ctrl.Redraw()),
		"OnLClick", (ctrl) => (ctrl.Opt("+Background1b1b1b"), ctrl.Redraw(), SelectPlaybackDevicesGUI())
		))
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
            
            ; Route scroll events directly to the slider to update volume (step of 2)
			ChildTracker.RegisterControl(sldVol.sliderCtrl, Map(
				"OnWheelUp",   UpdateSpecificSliderValue.Bind(session.ProgName, 2),
				"OnWheelDown", UpdateSpecificSliderValue.Bind(session.ProgName, -2)
			))
            
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

; --- Hover Timing Controls ---
CancelHide() {
    SetTimer(HideAudioMixerGui, 0)
}

ScheduleHide() {
    global hovertimeout
    SetTimer(HideAudioMixerGui, hovertimeout)
}

;UpdateSpecificSliderValue(progName, stepDelta) {
UpdateSpecificSliderValue(progName, stepDelta, *) {
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
    global IsGuiVisible, CurrentGuiHeight, MainGui, TrayHandler, WheelUsedDuringHover
    
    if (WheelUsedDuringHover) {
        WheelUsedDuringHover := false
        return
    }

	; --- Abort if GUI is already open and visible ---
    if (IsGuiVisible && MainGui != "" && WinExist(MainGui.Hwnd) && DllCall("IsWindowVisible", "Ptr", MainGui.Hwnd)) {
        return
    }

	;TrayHandler.IsMouseOver := false

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
    
    ; Schedule an initial hide sequence in case the mouse never enters the GUI area
    ScheduleHide()
}

HideAudioMixerGui() {
    global IsGuiVisible, MainGui

	if TrayHandler.IsMouseOver
		return

    IsGuiVisible := false
    CancelHide()
    
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