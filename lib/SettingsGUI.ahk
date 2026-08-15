/************************************************************************
 * @description Settings
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/19
 * @version 1.1.0
 ***********************************************************************/

ShowSettingsGUI() {
    global Settings, General, VolumeOSDNormal, VolumeOSDSlim, SettingsGui, SettingsTracker

    try {
        if (HasBase(SettingsGui, Gui.Prototype) && WinExist(SettingsGui)) {
            WinActivate(SettingsGui)
            return
        }
    } catch {
    }

    OnGuiDestroy(wParam, lParam, msg, hwnd) {
        if (hwnd == SettingsGui.Hwnd) {
            CleanDestroy()
            ; Run cleanup here right as the window handle is destroyed
        }
    }

    MyGuiTitle := App.Name . " Settings"
    MyGuiOptions := "+LastFound -MinimizeBox"
    SettingsGui := Gui(MyGuiOptions, MyGuiTitle)
    SettingsGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    UseAcrylicGUI := false
    UseAcrylicGUI := true

    if UseAcrylicGUI {
        SettingsGui.Opt("-Caption")
        titlebar := CustomTitleBar.Attach(SettingsGui, {
            Title: MyGuiTitle,
            ShowIcon: true,
            Min: true,
            Max: false,
            Close: true
        })
        SettingsGui.Add("Text", "xm ym", " ")
    }

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", SettingsGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)

    TextNormalColor := "CCCCCC"
    TextHoverColor  := "FFFFFF"
    BGroundNormalColor  := "1b1b1b"
    BGroundHoverColor  := "313131"

    ; 1. Initialize the custom drawing class
    OD_Colors.Init()
    OD_Colors.SetFont("c" TextNormalColor " s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; Define layout constants
    GuiWidth                := 920
    BtnWidth                := 100
    SettingsGui.MarginX     := 50
    SettingsGui.MarginY     := 30
	elMargYBig				:= 25
	elMargYMedium			:= 20
	elMargYSmall			:= 15

    ; HOTKEYS
    SettingsGui.SetFont("s10 w850")
    TitleHotkeys := SettingsGui.Add("Text", "xm y+" elMargYBig " w200", "HotKeys")
    TitleHotkeys.ThemeStyle := "Strong"

    SettingsGui.SetFont("s10 w600")
    SettingsGui.Add("Text", "xm+20 y+" elMargYSmall " w500", "Control foreground app volume")
    SettingsGui.SetFont("s13 w100 norm")
    Hot1Desc := SettingsGui.Add("Text", "xm+25 y+0 0x0200", "ⓘ")
    Hot1Desc.ThemeStyle := "Smooth"
    SettingsGui.SetFont("s9 w100 norm Italic")
    Hot1Desc := SettingsGui.Add("Text", "x+8 yp+4 w300 0x0200", "suggestion: use keyboard")
    Hot1Desc.ThemeStyle := "Smooth"

    if A_IsCompiled {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1 Icon-209", A_ScriptFullPath)
    } else {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1", A_ScriptDir . "\resources\keyboard.ico")
    }

    SettingsGui.SetFont("s11 w400 Norm")
    SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Up")
    SettingsGui.SetFont("s9 w100")
    Hot1Desc := SettingsGui.Add("Text", "y+1 w300", "Increase the active app volume")
    Hot1Desc.ThemeStyle := "Smooth"
    SettingsGui.SetFont("s8 w800")
    
    if UseAcrylicGUI{
        Global optKeyUp := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background" BGroundNormalColor " +Border")
        optKeyUp.BypassTheme := true
    } else {
        Global optKeyUp := SettingsGui.Add("Text", "vStrong_opt1 x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 +Border")
    }

    HotkeyManager.BindControl(optKeyUp, General.KeyUp, VolUp_ActiveWin)

    if A_IsCompiled {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1 Icon-209", A_ScriptFullPath)
    } else {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1", A_ScriptDir . "\resources\keyboard.ico")
    }

    SettingsGui.SetFont("s11 w400")
    SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Down")
    SettingsGui.SetFont("s9 w100")
    Hot2Desc := SettingsGui.Add("Text", "y+1 w300", "Decrease the active app volume")
    Hot2Desc.ThemeStyle := "Smooth"
    SettingsGui.SetFont("s8 w800")

    if UseAcrylicGUI{
        Global optKeyDown := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background" BGroundNormalColor " +Border")
        optKeyDown.BypassTheme := true
    } else {
        Global optKeyDown := SettingsGui.Add("Text", "vStrong_opt2 x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 +Border")
    }

    HotkeyManager.BindControl(optKeyDown, General.KeyDown, VolDown_ActiveWin)

    SettingsGui.SetFont("s10 w600")
    SettingsGui.Add("Text", "xm+20 y+" elMargYBig " w500", "Control hovered app volume")
    SettingsGui.SetFont("s13 w100 norm")
    Hot1Desc := SettingsGui.Add("Text", "xm+25 y+0 0x0200", "ⓘ")
    Hot1Desc.ThemeStyle := "Smooth"
    SettingsGui.SetFont("s9 w100 norm Italic")
    Hot1Desc := SettingsGui.Add("Text", "x+8 yp+4 w300", "suggestion: use keyboard + mouse wheel")
    Hot1Desc.ThemeStyle := "Smooth"

    if A_IsCompiled {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1 Icon-210", A_ScriptFullPath)
    } else {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1", A_ScriptDir . "\resources\mouse.ico")
    }

    SettingsGui.SetFont("s11 w400 Norm")
    SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Up")
    SettingsGui.SetFont("s9 w100")
    Hot3Desc := SettingsGui.Add("Text", "y+1 w380", "Increase the volume of the app under the mouse")
    Hot3Desc.ThemeStyle := "Smooth"
    SettingsGui.SetFont("s8 w800")

    if UseAcrylicGUI{
        Global optMouseUp := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background" BGroundNormalColor " +Border")
        optMouseUp.BypassTheme := true
    } else {
        Global optMouseUp := SettingsGui.Add("Text", "vStrong_opt3 x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 +Border")
    }

    HotkeyManager.BindControl(optMouseUp, General.MouseUp, VolUp_HoverWin)

    if A_IsCompiled {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1 Icon-210", A_ScriptFullPath)
    } else {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1", A_ScriptDir . "\resources\mouse.ico")
    }
    SettingsGui.SetFont("s11 w400")
    SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Down")
    SettingsGui.SetFont("s9 w100")
    Hot4Desc := SettingsGui.Add("Text", "y+1 w380", "Decrease the volume of the app under the mouse")
    Hot4Desc.ThemeStyle := "Smooth"
    SettingsGui.SetFont("s8 w800")

    if UseAcrylicGUI{
        Global optMouseDown := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background" BGroundNormalColor " +Border")
        optMouseDown.BypassTheme := true
    } else {
        Global optMouseDown := SettingsGui.Add("Text", "vStrong_opt4 x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 +Border")
    }

    HotkeyManager.BindControl(optMouseDown, General.MouseDown, VolDown_HoverWin)

    ; OSD
    SettingsGui.SetFont("s10 w850")
    TitleUseOSD := SettingsGui.Add("Text", "xm y+" elMargYBig " w200", "On Screen Display")
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
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1 Icon-211", A_ScriptFullPath)
    } else {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1", A_ScriptDir . "\resources\OSDType.ico")
    }

    SettingsGui.SetFont("s11 w400")
    SettingsGui.Add("Text", "x+20 yp-7 w200", "Type")
    SettingsGui.SetFont("s9 w100")
    UseOSDDesc := SettingsGui.Add("Text", "y+1 w300", "Select the OSD layout")
    UseOSDDesc.ThemeStyle := "Smooth"
    SettingsGui.SetFont("s11 w400")
    Global optUseOSD := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r7 w100 +0x0210 Choose" . StartingIndex, General.OSDList)
    SettingsGui.SetFont("s1 w100")
    UseOSDDesc := SettingsGui.Add("Text", "y+3")
    SettingsGui.SetFont("s9 w100")

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
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1 Icon-212", A_ScriptFullPath)
    } else {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1", A_ScriptDir . "\resources\monitors.ico")
    }

    SettingsGui.SetFont("s11 w400")
    SettingsGui.Add("Text", "x+20 yp-7 w200", "Monitor")
    SettingsGui.SetFont("s9 w100")
    MonitorDesc := SettingsGui.Add("Text", "y+1 w300", "Monitor number to place OSD")
    MonitorDesc.ThemeStyle := "Smooth"
    SettingsGui.SetFont("s11 w400")
    Global optMonitor := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r12 w100 +0x0210 Choose" . StartingIndex, OSDMonitorList)
    SettingsGui.SetFont("s1 w100")
    UseOSDDesc := SettingsGui.Add("Text", "y+3")
    SettingsGui.SetFont("s9 w100")

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
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1 Icon-213", A_ScriptFullPath)
    } else {
        SettingsGui.Add("Picture", "xm+20 y+" elMargYMedium " w24 h-1", A_ScriptDir . "\resources\position.ico")
    }

    SettingsGui.SetFont("s11 w400")
    SettingsGui.Add("Text", "x+20 yp-7 w200", "Position")
    SettingsGui.SetFont("s9 w100")
    PosDesc := SettingsGui.Add("Text", "y+1 w300", "Vertical alignment on Screen")
    PosDesc.ThemeStyle := "Smooth"
    SettingsGui.SetFont("s11 w400")
    Global optPosition := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r12 w100 +0x0210 Choose" . StartingIndex, General.OSDPositionList)
    SettingsGui.SetFont("s1 w100")
    UseOSDDesc := SettingsGui.Add("Text", "y+3")
    SettingsGui.SetFont("s9 w100")

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
    btnX := ((GuiWidth // 2) - BtnWidth - 20)
    
    if UseAcrylicGUI {
        SettingsGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
        btnReset := SettingsGui.Add("Text", "x" btnX " y+" elMargYBig " w" BtnWidth " h30 Center 0x0200 Background" BGroundNormalColor " +Border", "RESET")
        btnReset.BypassTheme := true
    } else {
        SettingsGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
        btnReset := SettingsGui.AddButton("x" btnX " y+" elMargYBig " w" BtnWidth " h30 Default", "&Reset")
    }
    btnReset.OnEvent("Click", ResetAll)

    ; Button OK
    btnX := ((GuiWidth // 2) + 20)

    if UseAcrylicGUI {
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

    if UseAcrylicGUI {
        ApplyThemeToGui(SettingsGui, "Dark")
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

    ; ==============================================================================
    ; GUI TRACKER INITIALIZATION
    ; ==============================================================================
    if UseAcrylicGUI {
        SettingsTracker := GuiTracker()
        SettingsTracker.AddGui := SettingsGui

        ; Map that applies style/colors and sets cursor on hover
        hoverEvents := Map(
            "OnEnter", (ctrl) => (
                ctrl.SetFont("c" TextHoverColor),
                ctrl.Opt("+Background" BGroundHoverColor)
                ; Apply hand cursor to items that aren't the primary OK/Reset buttons 
                ;(ctrl != btnReset && ctrl != btnSave) ? DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr")) : 0
            ),
            "OnLeave", (ctrl) => (
                ctrl.SetFont("c" TextNormalColor),
                ctrl.Opt("+Background" BGroundNormalColor)
            )
        )

        ; Register controls to listen for the hover events
        SettingsTracker.RegisterControl(btnReset, hoverEvents)
        SettingsTracker.RegisterControl(btnSave, hoverEvents)
        SettingsTracker.RegisterControl(optKeyUp, hoverEvents)
        SettingsTracker.RegisterControl(optKeyDown, hoverEvents)
        SettingsTracker.RegisterControl(optMouseUp, hoverEvents)
        SettingsTracker.RegisterControl(optMouseDown, hoverEvents)
    }
    ; ==============================================================================

    SettingsGui.Show("w" GuiWidth)
    btnSave.Focus()
    WinMoveTop(SettingsGui.Hwnd)

    ActionsUseOSD(Ctrl, *) {
        General.UseOSD := optUseOSD.Text
        switch Ctrl.Text {
            case "Normal", "Slim": (
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
        ; GuiTracker automatically unregisters hooks when GUI is destroyed!
        SettingsGui.Destroy()
        RemoveGuiFromArray(SettingsGui)
        SaveINI()
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