SelectPlaybackDevicesGUI(*) {
    global VisibleDevicesConfig

    transparent := true

    HoverSettingsGui := Gui("+Owner" MainGui.Hwnd " +LastFound -Caption", "Show Playback Devices")

    CustomTitleBar.Attach(HoverSettingsGui, {
        Title: "Show Playback Devices",
        ShowIcon: true,
        Min: true,
        Max: false, ; Turn off maximize if you don't need it
        Close: true
    })

        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", HoverSettingsGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)


    if transparent {
        HoverSettingsGui.SetFont("cWhite s13", Settings.GuiFontName)
    } else {
        HoverSettingsGui.SetFont("s13", Settings.GuiFontName)
    }

    ; Define layout constants
    GuiWidth                     := 560
    BtnWidth                     := 100
    HoverSettingsGui.MarginX     := 50
    HoverSettingsGui.MarginY     := 30

    HoverSettingsGui.SetFont("s10 w850")
    HoverSettingsGui.Add("Text", "vTitle xm y+30 w350", "Select playback devices to show:")
    
    deviceNames := PopulatePlaybackDevices()
    checkboxes := Map()
    yOffset := 100

    HoverSettingsGui.SetFont("s11 w400")
    for name in deviceNames {
        isChecked := (VisibleDevicesConfig.Has(name) && VisibleDevicesConfig[name]) ? "Checked" : ""
        namelabel := (StrLen(name) > 52) ? SubStr(name, 1, 49) "..." : name
        
        ; Separated checkbox (no caption)
        chk := HoverSettingsGui.Add("Checkbox", "xm+20 y" yOffset " w20 h20 " isChecked)
        checkboxes[name] := chk
        
        ; Separated description text
        txtCtrl := HoverSettingsGui.Add("Text", "x+10 yp w430 h20 +BackgroundTrans", namelabel)
        
        ; Clicking the text toggles the checkbox
        txtCtrl.OnEvent("Click", ((associatedCheckbox, *) => associatedCheckbox.Value := !associatedCheckbox.Value).Bind(chk))
        
        yOffset += 40
    }
 
    ; Button OK
    HoverSettingsGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
    btnX := (GuiWidth - BtnWidth) // 2 ; center

    if transparent {
;        HoverSettingsGui.SetFont("s" Settings.GuiFontSizeBig " C727272 w700", Settings.GuiFontName)
        HoverSettingsGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
        btnSave := HoverSettingsGui.Add("Text", "x" btnX " y" (yOffset + 20) " w" BtnWidth " h30 Center 0x0200 Background282828 +Border", "SAVE")
        btnSave.BypassTheme := true
    } else {
        HoverSettingsGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
        btnSave := HoverSettingsGui.AddButton("x" btnX " y" (yOffset + 20) " w" BtnWidth " h30 Default", "&Save")
    }

    btnSave.OnEvent("Click", SavePreferences)

    if transparent {
        FrostedTheme.ApplyTransparencyToControls(HoverSettingsGui)
        FrostedTheme.Apply(HoverSettingsGui)

        isHovering := false
        ;NormalColor := "727272"
        NormalColor := "FFFFFF"
        HoverColor  := "FFFFFF"

        ;OnMessage(0x0200, OnMouseMoveHoverSettings)
        MessageManager.Register(0x0200, OnMouseMoveHoverSettings)

        OnMouseMoveHoverSettings(wParam, lParam, msg, hwnd) {
;            if hwnd != HoverSettingsGui.Hwnd
;                return
            try {
                if (!btnSave || !btnSave.Hwnd)
                    return
            } catch {
                return
            }
            
            if (hwnd == btnSave.Hwnd) {
                ctrl := GuiCtrlFromHwnd(hwnd)

                if (!isHovering) {
                    isHovering := true
                    
                    TRACKMOUSEEVENT := Buffer(A_PtrSize == 8 ? 24 : 16, 0)
                    NumPut("UInt", TRACKMOUSEEVENT.Size, TRACKMOUSEEVENT, 0)
                    NumPut("UInt", 2,                    TRACKMOUSEEVENT, 4)
                    NumPut("Ptr",  ctrl.Hwnd,          TRACKMOUSEEVENT, A_PtrSize == 8 ? 8 : 8)
                    DllCall("TrackMouseEvent", "Ptr", TRACKMOUSEEVENT)
                    
                    ;OnMessage(0x02A3, OnMouseLeaveHoverSettings)
                    MessageManager.Register(0x02A3, OnMouseLeaveHoverSettings)
                }

                if (ctrl == btnSave) {
                    ctrl.SetFont("c" HoverColor)
                    ctrl.Opt("+Background595858")
                    return
                }

                DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
            }
        }
    } else {
        ApplyThemeToGui(HoverSettingsGui)
        WatchedGUIs.Push(HoverSettingsGui)
    }

    HoverSettingsGui.OnEvent("Close", HoverSettingsGuiUnregister)
    HoverSettingsGui.OnEvent("Escape", HoverSettingsGuiUnregister)

    HoverSettingsGuiUnregister(*) {
        MessageManager.Unregister(0x0200, OnMouseMoveHoverSettings)
        MessageManager.Unregister(0x02A3, OnMouseLeaveHoverSettings)
    }

    HoverSettingsGui.Show("w" GuiWidth " h" (yOffset + 75))
    btnSave.Focus()
    
    SavePreferences(*) {
        ;OnMessage(0x0200, OnMouseMoveHoverSettings, 0)
        MessageManager.Unregister(0x0200, OnMouseMoveHoverSettings)
        MessageManager.Unregister(0x02A3, OnMouseLeaveHoverSettings)
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
            
        HoverSettingsGui.Destroy()
        RefreshSessionsForSelectedDevice()
    }

    OnMouseLeaveHoverSettings(wParam, lParam, msg, hwnd) {
;        if hwnd != HoverSettingsGui.Hwnd
;            return
        try {
            if (hwnd == btnSave.Hwnd) {
                ctrl := GuiCtrlFromHwnd(hwnd)
                try ctrl.SetFont("c" NormalColor)
                try ctrl.Opt("+Background282828")
                isHovering := false
            }
        }
    }
}
