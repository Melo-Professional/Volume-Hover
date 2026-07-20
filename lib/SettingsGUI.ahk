/************************************************************************
 * @description Settings
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/19
 * @version 1.0.1
 ***********************************************************************/

ShowSettingsGUI() {
    global Settings, General, VolumeOSDNormal, VolumeOSDSlim, SettingsGui


try {
        if (HasBase(SettingsGui, Gui.Prototype) && WinExist(SettingsGui)) {
            WinActivate(SettingsGui)
            return
        }
    } catch {
    }


    MyGuiTitle := App.Name . " Settings"
    UseAcrylicGUI := true

    if UseAcrylicGUI {
        MyGuiOptions := "+LastFound -Caption"
    } else {
        MyGuiOptions := "+LastFound -SysMenu"
    }

    SettingsGui := Gui(MyGuiOptions, MyGuiTitle)

    titlebar := CustomTitleBar.Attach(SettingsGui, {
        Title: MyGuiTitle,
        ShowIcon: true,
        Min: true,
        Max: false,
        Close: true
    })

;    titlebar.BypassTheme := false

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", SettingsGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)

    TextNormalColor := "CCCCCC"
    TextHoverColor  := "FFFFFF"
    BGroundNormalColor  := "1b1b1b"
    BGroundHoverColor  := "313131"

    if UseAcrylicGUI {
        SettingsGui.SetFont("c" TextNormalColor " s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    } else {
        SettingsGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    }

    ; 1. Initialize the custom drawing class
    OD_Colors.Init()
    OD_Colors.SetFont("c" TextNormalColor " s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; Define layout constants
    GuiWidth                := 920
    BtnWidth                := 100
    SettingsGui.MarginX     := 50
    SettingsGui.MarginY     := 30
/* 
    ; 1. Icon
    try {
        SettingsGui.Add("Picture", "w32 h-1", App.Icon)
    } catch {
        SettingsGui.SetFont("s15 w500")
        SettingsGui.Add("Text", "w32 h32", "[ i ]")
    }

    ; 2. Title and Version
    SettingsGui.SetFont("s" Settings.GuiFontSizeBig " w200")
    SettingsGui.Add("Text", "x+15 yp vStrong_Title", App.Name)

    SettingsGui.SetFont("s" Settings.GuiFontSizeSmall " w400 ")
    SettingsGui.Add("Text", "y+2 vSmooth_Version", "Version " App.Version)
 */

    ; HOTKEYS
        SettingsGui.SetFont("s10 w850")
        TitleHotkeys := SettingsGui.Add("Text", "xm y+30 w200", "HotKeys")
        TitleHotkeys.ThemeStyle := "Strong"

        SettingsGui.SetFont("s10 w600")
        SettingsGui.Add("Text", "xm+20 y+30 w500", "Control foreground app volume")
        SettingsGui.SetFont("s13 w100 norm")
        Hot1Desc := SettingsGui.Add("Text", "xm+25 y+0 0x0200", "ⓘ")
        Hot1Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s9 w100 norm Italic")
        Hot1Desc := SettingsGui.Add("Text", "x+8 yp+4 w300 0x0200", "suggestion: use keyboard")
        Hot1Desc.ThemeStyle := "Smooth"

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-209", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\keyboard.ico")
        }

        SettingsGui.SetFont("s11 w400 Norm")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Up")
        SettingsGui.SetFont("s9 w100")
        Hot1Desc := SettingsGui.Add("Text", "y+1 w300", "Increase the active app volume")
        Hot1Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w800")
        ;KeyUp := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        Global optKeyUp := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background" BGroundNormalColor " +Border")
        HotkeyManager.BindControl(optKeyUp, General.KeyUp, VolUp_ActiveWin)
        optKeyUp.BypassTheme := true

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-209", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\keyboard.ico")
        }

        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Down")
        SettingsGui.SetFont("s9 w100")
        Hot2Desc := SettingsGui.Add("Text", "y+1 w300", "Decrease the active app volume")
        Hot2Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w800")
        ;KeyDown := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        Global optKeyDown := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background" BGroundNormalColor " +Border")
        HotkeyManager.BindControl(optKeyDown, General.KeyDown, VolDown_ActiveWin)
        optKeyDown.BypassTheme := true

        SettingsGui.SetFont("s10 w600")
        SettingsGui.Add("Text", "xm+20 y+40 w500", "Control hovered app volume")
        SettingsGui.SetFont("s13 w100 norm")
        Hot1Desc := SettingsGui.Add("Text", "xm+25 y+0 0x0200", "ⓘ")
        Hot1Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s9 w100 norm Italic")
        Hot1Desc := SettingsGui.Add("Text", "x+8 yp+4 w300", "suggestion: use keyboard + mouse wheel")
        Hot1Desc.ThemeStyle := "Smooth"

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-210", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\mouse.ico")
        }

        SettingsGui.SetFont("s11 w400 Norm")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Up")
        SettingsGui.SetFont("s9 w100")
        Hot3Desc := SettingsGui.Add("Text", "y+1 w380", "Increase the volume of the app under the mouse")
        Hot3Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w800")
        ;MouseUp := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        Global optMouseUp := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background" BGroundNormalColor " +Border")
        HotkeyManager.BindControl(optMouseUp, General.MouseUp, VolUp_HoverWin)
        optMouseUp.BypassTheme := true

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-210", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\mouse.ico")
        }
        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Down")
        SettingsGui.SetFont("s9 w100")
        Hot4Desc := SettingsGui.Add("Text", "y+1 w380", "Decrease the volume of the app under the mouse")
        Hot4Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w800")
        ;MouseDown := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        Global optMouseDown := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background" BGroundNormalColor " +Border")
        HotkeyManager.BindControl(optMouseDown, General.MouseDown, VolDown_HoverWin)
        optMouseDown.BypassTheme := true

    ; OSD
        SettingsGui.SetFont("s10 w850")
        TitleUseOSD := SettingsGui.Add("Text", "xm y+70 w200", "On Screen Display")
        TitleUseOSD.ThemeStyle := "Strong"

    ; Use OSD
        StartingIndex := 1
        For Index, Value in General.OSDList {
            If (Value = General.UseOSD) {
                StartingIndex := Index
                Break
            }
        }

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-211", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\OSDType.ico")
        }

        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Type")
        SettingsGui.SetFont("s9 w100")
        UseOSDDesc := SettingsGui.Add("Text", "y+1 w200", "Select the OSD layout")
        UseOSDDesc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s11 w400")
;        optUseOSD := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r7 w100 Choose" . StartingIndex, General.OSDList)
        Global optUseOSD := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r7 w100 +0x0210 Choose" . StartingIndex, General.OSDList)
        ;optUseOSD.BypassTheme := true

    ; Monitor list
        OSDMonitorList := ["Auto"]
        Loop MonitorGetCount() {
            OSDMonitorList.Push(A_Index)
        }

        StartingIndex := 1
        For Index, Value in OSDMonitorList {
            If (Value = General.OSDMonitor) {
                StartingIndex := Index
                Break
            }
        }

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-212", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\monitors.ico")
        }

        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Monitor")
        SettingsGui.SetFont("s9 w100")
        MonitorDesc := SettingsGui.Add("Text", "y+1 w200", "Monitor number to place OSD")
        MonitorDesc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s11 w400")
        ;optMonitor := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 80 " yp-17 r12 w80 Choose" . StartingIndex, OSDMonitorList)
        Global optMonitor := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r12 w100 +0x0210 Choose" . StartingIndex, OSDMonitorList)
        ;optMonitor.BypassTheme := true

        if (optUseOSD.Text = "Disable")
            optMonitor.Enabled := false


    ; Position
        StartingIndex := 1
        For Index, Value in General.OSDPositionList {
            If (Value = General.OSDPosition) {
                StartingIndex := Index
                Break
            }
        }

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-213", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\position.ico")
        }

        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Position")
        SettingsGui.SetFont("s9 w100")
        PosDesc := SettingsGui.Add("Text", "y+1 w200", "Vertical alignment on Screen")
        PosDesc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s11 w400")
        ;optPosition := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r7 w100 Choose" . StartingIndex, General.OSDPositionList)
        Global optPosition := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r12 w100 +0x0210 Choose" . StartingIndex, General.OSDPositionList)
        ;optPosition.BypassTheme := true

        for odctrl in [ optUseOSD, optMonitor, optPosition] {
            odctrl.OwnerDraw := {
                CB: 0x1b1b1b,  ; background
                CT: 0xF3F3F3,  ; text
                SB: 0x363636,  ; background highlight on hover
                ST: 0xF3F3F3   ; text on hover
            }
        }

        SettingsGui.SetFont("s" Settings.GuiFontSizeSmall " w400 ")

        if (optUseOSD.Text = "Disable")
            optPosition.Enabled := false

    ; Button Reset
            ; 6.1 align
        ;        btnX := SettingsGui.MarginX ; left
                btnX := ((GuiWidth // 2) - BtnWidth - 20)
        ;        btnX := GuiWidth - SettingsGui.MarginX - BtnWidth ; right
            
            if UseAcrylicGUI {
;                SettingsGui.SetFont("s" Settings.GuiFontSizeBig " C727272 w700", Settings.GuiFontName)
                SettingsGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
                btnReset := SettingsGui.Add("Text", "x" btnX " y+75 w" BtnWidth " h30 Center 0x0200 Background" BGroundNormalColor " +Border", "RESET")
                btnReset.BypassTheme := true
            } else {
                SettingsGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
                btnReset := SettingsGui.AddButton("x" btnX " y+75 w" BtnWidth " h30 Default", "&Reset")
            }

            btnReset.OnEvent("Click", ResetAll)

    ; Button OK
            SettingsGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
            ; 6.1 align
        ;        btnX := SettingsGui.MarginX ; left
                btnX := ((GuiWidth // 2) + 20)
        ;        btnX := GuiWidth - SettingsGui.MarginX - BtnWidth ; right

            if UseAcrylicGUI {
;                SettingsGui.SetFont("s" Settings.GuiFontSizeBig " C727272 w700", Settings.GuiFontName)
                SettingsGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
                btnSave := SettingsGui.Add("Text", "x" btnX " yp w" BtnWidth " h30 Center 0x0200 Background" BGroundNormalColor " +Border", "OK")
                btnSave.BypassTheme := true
            } else {
                SettingsGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
                btnSave := SettingsGui.AddButton("x" btnX " yp w" BtnWidth " h30 Default", "&OK")
            }

            btnSave.OnEvent("Click", CleanDestroy)

    SendMessage(0x0153, -1, 24, optUseOSD)
    SendMessage(0x0153, 0, 30, optUseOSD)

    SendMessage(0x0153, -1, 24, optMonitor)
    SendMessage(0x0153, 0, 30, optMonitor)

    SendMessage(0x0153, -1, 24, optPosition)
    SendMessage(0x0153, 0, 30, optPosition)

;        WatchedGUIs.Push(SettingsGui)

    if UseAcrylicGUI {
        ApplyThemeToGui(SettingsGui, "Dark")
;        ApplyTransparencyToControls(SettingsGui)
        FrostedTheme.Apply(SettingsGui)
    } else {
        ApplyThemeToGui(SettingsGui)
        WatchedGUIs.Push(SettingsGui)
    }
 
    optUseOSD.OnEvent("Change", ActionsUseOSD)
    optMonitor.OnEvent("Change", ActionsMonitor)
    optPosition.OnEvent("Change", ActionsPosition)

    SettingsGui.OnEvent("Close", CleanDestroy)
    SettingsGui.OnEvent("Escape", CleanDestroy)


    SettingsGui.Show("w" GuiWidth)
    btnSave.Focus()
    WinMoveTop(SettingsGui.Hwnd)

    ActionsUseOSD(Ctrl, *) {
        General.UseOSD := optUseOSD.Text
        switch Ctrl.Text {
            case "Normal": (
                    optMonitor.Enabled := true
                    optPosition.Enabled := true
                    ;UpdateOSD("Program", 50)
                    SettingsShowOSD("Program", 50)
                )
            case "Slim": (
                    optMonitor.Enabled := true
                    optPosition.Enabled := true
                    SettingsShowOSD("Program", 50)
                )
            default : (
                optMonitor.Enabled := false
                optPosition.Enabled := false
            )
        }
        SaveINI()
    }

    ActionsMonitor(Ctrl, *) {
        General.OSDMonitor := Ctrl.Text
        VolumeOSDSlim.Monitor := Ctrl.Text
        VolumeOSDNormal.Monitor := Ctrl.Text
        SaveINI()
        SettingsShowOSD("Program", 50)
    }

    ActionsPosition(Ctrl, *) {
        General.OSDPosition := Ctrl.Text
        SaveINI()

        switch General.OSDPosition {
            case "Top": (
                VolumeOSDSlim.Position := "x0.50 y0.09"
                VolumeOSDNormal.Position := "x0.50 y0.09"
            )
            case "Center": (
                VolumeOSDSlim.Position := "x0.50 y0.50"
                VolumeOSDNormal.Position := "x0.50 y0.50"
            )
            default :(
                VolumeOSDSlim.Position := "x0.50 y0.91"
                VolumeOSDNormal.Position := "x0.50 y0.91"
            )
        }
        SettingsShowOSD("Program", 50)
    }




    ResetAll(*) {
        bkp_pbdevices := General.PlaybackDevices
        General := ResetGeneral
        General.PlaybackDevices := bkp_pbdevices
        SaveINI()
        ReloadWithArgs("ShowSettingsGUI")
    }

    CleanDestroy(*) {
        SettingsGui.Destroy()
        RemoveGuiFromArray(SettingsGui)
        SaveINI()
    }


    if UseAcrylicGUI {
        isHovering := false
        MessageManager.Register(0x0200, OnMouseMoveSettingsGUI)

        OnMouseMoveSettingsGUI(wParam, lParam, msg, hwnd) {
            try {
                if (!btnReset || !btnReset.Hwnd || !btnSave || !btnSave.Hwnd
                 || !optKeyUp || !optKeyUp.Hwnd || !optKeyDown || !optKeyDown.Hwnd 
                 || !optMouseUp || !optMouseUp.Hwnd || !optMouseDown || !optMouseDown.Hwnd)
                    return
            } catch {
                return
            }
            
            if (hwnd == btnReset.Hwnd || hwnd == btnSave.Hwnd
             || hwnd == optKeyUp.Hwnd || hwnd == optKeyDown.Hwnd
             || hwnd == optMouseUp.Hwnd || hwnd == optMouseDown.Hwnd) {

                ctrl := GuiCtrlFromHwnd(hwnd)

                if (!isHovering) {
                    isHovering := true
                    
                    TRACKMOUSEEVENT := Buffer(A_PtrSize == 8 ? 24 : 16, 0)
                    NumPut("UInt", TRACKMOUSEEVENT.Size, TRACKMOUSEEVENT, 0)
                    NumPut("UInt", 2,                    TRACKMOUSEEVENT, 4)
                    NumPut("Ptr",  ctrl.Hwnd,          TRACKMOUSEEVENT, A_PtrSize == 8 ? 8 : 8)
                    DllCall("TrackMouseEvent", "Ptr", TRACKMOUSEEVENT)
                    
                    MessageManager.Register(0x02A3, OnMouseLeaveSettingsGUI)
                }

                ctrl.SetFont("c" TextHoverColor)
                ctrl.Opt("+Background" BGroundHoverColor)

                if !(ctrl == btnReset || ctrl == btnSave) {
                    DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
                }
            }
        }
    }

    OnMouseLeaveSettingsGUI(wParam, lParam, msg, hwnd) {
        try {
            if (hwnd == btnReset.Hwnd || hwnd == btnSave.Hwnd
                || hwnd == optKeyUp.Hwnd || hwnd == optKeyDown.Hwnd
                || hwnd == optMouseUp.Hwnd || hwnd == optMouseDown.Hwnd) {

                ctrl := GuiCtrlFromHwnd(hwnd)
                try ctrl.SetFont("c" TextNormalColor)
                try ctrl.Opt("+Background" BGroundNormalColor)
                isHovering := false
                ;OnMessage(0x02A3, OnMouseLeaveSettingsGUI, 0)
            }
        }
    }
}

    SettingsGUI_EnableDisable(*){
        Global General, SettingsGui, optUseOSD, optMonitor, optPosition

        if (General.KeyUp == "" && General.KeyDown == "" && General.MouseUp == "" && General.MouseDown == ""){
            optUseOSD.Text := "Disable"
            General.UseOSD := optUseOSD.Text
            optUseOSD.Enabled := false
            optMonitor.Enabled := false
            optPosition.Enabled := false

        }
    }