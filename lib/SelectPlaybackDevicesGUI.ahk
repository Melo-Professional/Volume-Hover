/************************************************************************
 * @description Select Playback Devices
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/20
 * @version 2.0.2 (Clean Close fix)
 ***********************************************************************/

SelectPlaybackDevicesGUI(*) {
    global VisibleDevicesConfig, DevicesGui

    try {
        if (HasBase(DevicesGui, Gui.Prototype) && WinExist(DevicesGui)) {
            WinActivate(DevicesGui)
            return
        }
    } catch {
    }

    MyGuiTitle := App.Name . " Playback Devices"
    MyGuiOptions := "+Owner" MainGui.Hwnd " +LastFound"
    DevicesGui := Gui( MyGuiOptions, MyGuiTitle)
    DevicesGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    UseAcrylicGUI := true

    if UseAcrylicGUI {
        DevicesGui.Opt("-Caption")
        titlebar := CustomTitleBar.Attach(DevicesGui, {
            Title: MyGuiTitle,
            ShowIcon: true,
            Min: false,
            Max: false,
            Close: true
        })
        DevicesGui.Add("Text", "xm ym", " ")
    }

;    titlebar.BypassTheme := false

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", DevicesGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)

    TextNormalColor := "CCCCCC"
    TextHoverColor  := "FFFFFF"
    BGroundNormalColor  := "1b1b1b"
    BGroundHoverColor  := "313131"

    ; Define layout constants
    GuiWidth               := 560
    BtnWidth               := 100
    DevicesGui.MarginX     := 50
    DevicesGui.MarginY     := 30

    DevicesGui.SetFont("s10 w850")
    DevicesGui.Add("Text", "vTitle xm y+30 w350", "Select playback devices to show:")
    
    deviceNames := PopulatePlaybackDevices()
    checkboxes := Map()
    yOffset := 100

    DevicesGui.SetFont("s11 w400")
    for name in deviceNames {
        isChecked := (VisibleDevicesConfig.Has(name) && VisibleDevicesConfig[name]) ? "Checked" : ""
        namelabel := (StrLen(name) > 52) ? SubStr(name, 1, 49) "..." : name
        
        ; Separated checkbox (no caption)
        chk := DevicesGui.Add("Checkbox", "xm+20 y" yOffset " w20 h20 " isChecked)
        checkboxes[name] := chk
        
        ; Separated description text
        txtCtrl := DevicesGui.Add("Text", "x+10 yp w430 h20 +BackgroundTrans", namelabel)

        txtCtrl.OnEvent("Click", ((associatedCheckbox, *) => associatedCheckbox.Value := !associatedCheckbox.Value).Bind(chk))
        
        yOffset += 40
    }
 
    ; Button OK
    DevicesGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
    btnX := (GuiWidth - BtnWidth) // 2 ; center

    if UseAcrylicGUI {
;        HoverSettingsGui.SetFont("s" Settings.GuiFontSizeBig " C727272 w700", Settings.GuiFontName)
        DevicesGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
        btnSave := DevicesGui.Add("Text", "x" btnX " y" (yOffset + 20) " w" BtnWidth " h30 Center 0x0200 Background282828 +Border", "SAVE")
        btnSave.BypassTheme := true
    } else {
        DevicesGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
        btnSave := DevicesGui.AddButton("x" btnX " y" (yOffset + 20) " w" BtnWidth " h30 Default", "&Save")
    }

    btnSave.OnEvent("Click", SavePreferences)

    DevicesGui.OnEvent("Close", SavePreferences)
    DevicesGui.OnEvent("Escape", SavePreferences)

    if UseAcrylicGUI {
        ApplyThemeToGui(DevicesGui, "Dark")
        FrostedTheme.Apply(DevicesGui)
    } else {
        ApplyThemeToGui(DevicesGui)
        WatchedGUIs.Push(DevicesGui)
    }


    DevicesGui.Show("w" GuiWidth " h" (yOffset + 75))
    btnSave.Focus()

    if UseAcrylicGUI {
        isHovering := false
        MessageManager.Register(0x0200, OnMouseMoveHoverSettings)

        OnMouseMoveHoverSettings(wParam, lParam, msg, hwnd) {
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

                    MessageManager.Register(0x02A3, OnMouseLeaveHoverSettings)
                }

                ctrl.SetFont("c" TextHoverColor)
                ctrl.Opt("+Background" BGroundHoverColor)

                if (ctrl == btnSave) {
                    DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
                }
            }
        }
    }

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
            
        DevicesGui.Destroy()
        RefreshSessionsForSelectedDevice()
    }

    OnMouseLeaveHoverSettings(wParam, lParam, msg, hwnd) {
        try {
            if (hwnd == btnSave.Hwnd) {
                ctrl := GuiCtrlFromHwnd(hwnd)
                try ctrl.SetFont("c" TextNormalColor)
                try ctrl.Opt("+Background" BGroundNormalColor)
                isHovering := false
            }
        }
    }
}
