/************************************************************************
 * @description Settings
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/10
 * @version 1.0.0
 ***********************************************************************/

ShowSettingsGUI() {
    global Settings, General, VolumeOSDNormal, VolumeOSDSlim

    transparent := false
    transparent := true
    MyGuiTitle := App.Name . " Settings"
    MyGuiOptions := "+LastFound -Caption"
    Global SettingsGui := Gui(MyGuiOptions, MyGuiTitle)

    CustomTitleBar.Attach(SettingsGui, {
        Title: MyGuiTitle,
        ShowIcon: true,
        Min: true,
        Max: false, ; Turn off maximize if you don't need it
        Close: true
    })

        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", SettingsGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)


    if transparent {
        SettingsGui.SetFont("cWhite s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    } else {
        SettingsGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    }

    ; 1. Initialize the custom drawing class
    OD_Colors.Init()
    OD_Colors.SetFont("cWhite s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

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
        SettingsGui.Add("Text", "xm+20 y+10 w500", "Change volume of foreground program with keyboard")
        
        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-209", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\keyboard.ico")
        }

        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Up")
        SettingsGui.SetFont("s9 w100")
        Hot1Desc := SettingsGui.Add("Text", "y+1 w300", "Increase volume of the active program")
        Hot1Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w400")
        ;KeyUp := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        KeyUp := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background282828 +Border")
        HotkeyManager.BindControl(KeyUp, General.KeyUp, Action_KeyUp)
        KeyUp.BypassTheme := true

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-209", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\keyboard.ico")
        }

        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Down")
        SettingsGui.SetFont("s9 w100")
        Hot2Desc := SettingsGui.Add("Text", "y+1 w300", "Decrease volume of the active program")
        Hot2Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w400")
        ;KeyDown := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        KeyDown := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background282828 +Border")
        HotkeyManager.BindControl(KeyDown, General.KeyDown, Action_KeyDown)
        KeyDown.BypassTheme := true

        SettingsGui.SetFont("s10 w600")
        SettingsGui.Add("Text", "xm+20 y+25 w500", "Change volume of any program under mouse pointer")

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-210", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\mouse.ico")
        }

        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Up")
        SettingsGui.SetFont("s9 w100")
        Hot3Desc := SettingsGui.Add("Text", "y+1 w300", "Increase volume (suggestion: use mouse wheel)")
        Hot3Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w400")
        ;MouseUp := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        MouseUp := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background282828 +Border")
        HotkeyManager.BindControl(MouseUp, General.MouseUp, Action_MouseUp)
        MouseUp.BypassTheme := true

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-210", A_ScriptFullPath)
        } else {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\mouse.ico")
        }
        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Down")
        SettingsGui.SetFont("s9 w100")
        Hot4Desc := SettingsGui.Add("Text", "y+1 w300", "Decrease volume (suggestion: use mouse wheel)")
        Hot4Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w400")
        ;MouseDown := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        MouseDown := SettingsGui.Add("Text", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240 Center 0x0200 Background282828 +Border")
        HotkeyManager.BindControl(MouseDown, General.MouseDown, Action_MouseDown)
        MouseDown.BypassTheme := true

    ; OSD
        SettingsGui.SetFont("s10 w850")
        TitleUseOSD := SettingsGui.Add("Text", "xm y+30 w200", "On Screen Display")
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
        optUseOSD := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r7 w100 +0x0210 Choose" . StartingIndex, General.OSDList)
        optUseOSD.BypassTheme := true

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
        optMonitor := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r12 w100 +0x0210 Choose" . StartingIndex, OSDMonitorList)
        optMonitor.BypassTheme := true

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
        optPosition := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r12 w100 +0x0210 Choose" . StartingIndex, General.OSDPositionList)
        optPosition.BypassTheme := true

        for odctrl in [ optUseOSD, optMonitor, optPosition] {
            odctrl.OwnerDraw := {
                CB: 0x202020,  ; background
                CT: 0xFFFFFF,  ; text
                SB: 0x2c2d2e,  ; background highlight on hover
                ST: 0xFFFFFF   ; text on hover
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
            
            if transparent {
;                SettingsGui.SetFont("s" Settings.GuiFontSizeBig " C727272 w700", Settings.GuiFontName)
                SettingsGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
                btnReset := SettingsGui.Add("Text", "x" btnX " y+75 w" BtnWidth " h30 Center 0x0200 Background282828 +Border", "RESET")
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

            if transparent {
;                SettingsGui.SetFont("s" Settings.GuiFontSizeBig " C727272 w700", Settings.GuiFontName)
                SettingsGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
                btnSave := SettingsGui.Add("Text", "x" btnX " yp w" BtnWidth " h30 Center 0x0200 Background282828 +Border", "OK")
                btnSave.BypassTheme := true
            } else {
                SettingsGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
                btnSave := SettingsGui.AddButton("x" btnX " yp w" BtnWidth " h30 Default", "&OK")
            }

            btnSave.OnEvent("Click", CleanDestroy)


    if transparent {
        ApplyTransparencyToControls(SettingsGui)
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

    SendMessage(0x0153, -1, 24, optUseOSD)
    SendMessage(0x0153, 0, 30, optUseOSD)

    SendMessage(0x0153, -1, 24, optMonitor)
    SendMessage(0x0153, 0, 30, optMonitor)

    SendMessage(0x0153, -1, 24, optPosition)
    SendMessage(0x0153, 0, 30, optPosition)

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

    Action_KeyUp(newHotkey := "", isGuiUpdate := false) {
        global General

        if (isGuiUpdate) {
            General.KeyUp := newHotkey
            SaveINI()
            EnableDisable()
            return
        }
        AppVolumeControl.AdjustVolumeByActiveWindow(5)
    }

    Action_KeyDown(newHotkey := "", isGuiUpdate := false) {
        global General

        if (isGuiUpdate) {
            General.KeyDown := newHotkey
            SaveINI()
            EnableDisable()
            return
        }
        AppVolumeControl.AdjustVolumeByActiveWindow(-5)
    }

    Action_MouseUp(newHotkey := "", isGuiUpdate := false) {
        global General

        if (isGuiUpdate) {
            General.MouseUp := newHotkey
            SaveINI()
            EnableDisable()
            return
        }
        AppVolumeControl.AdjustVolumeByMouse(5)
    }

    Action_MouseDown(newHotkey := "", isGuiUpdate := false) {
        global General

        if (isGuiUpdate) {
            General.MouseDown := newHotkey
            SaveINI()
            EnableDisable()
            return
        }        
        AppVolumeControl.AdjustVolumeByMouse(-5)
    }

    EnableDisable(*){
        Global General

        if (General.KeyUp == "" && General.KeyDown == "" && General.MouseUp == "" && General.MouseDown == ""){
            optUseOSD.Text := "Disable"
            General.UseOSD := optUseOSD.Text
            optUseOSD.Enabled := false
            optMonitor.Enabled := false
            optPosition.Enabled := false

        }
    }

    ResetAll(*) {
        Global General := {
            UseOSD: "Slim",
            OSDMonitor: 1,
            OSDPosition: "Bottom",
            KeyUp: "^+F8",
            KeyDown: "^+F7",
            MouseUp: "^+WheelUp",
            MouseDown: "^+WheelDown",
        }
        SaveINI()
        ReloadWithArgs("ShowSettingsGUI")
    }

    CleanDestroy(*) {
        SettingsGui.Destroy()
        RemoveGuiFromArray(SettingsGui)
        SaveINI()
    }

    ApplyTransparencyToControls(guiObj) {
        if !Settings.DarkModeCompatible
            return    

        colors := Settings.Theme.Dark
        ;isDark := (CurrentActualTheme == "Dark")
        isDark := true

        ; --- Color Conversion (with fallback) ---
        bgBGR   := HexToBGR(colors.Bg)
        ctrlBGR := HexToBGR(colors.HasOwnProp("Ctrl") ? colors.Ctrl : colors.Bg)
        textBGR := HexToBGR(colors.TextDefault)

        ; --- Dark Mode System Setup ---
        uxtheme := DllCall("GetModuleHandle", "Str", "uxtheme.dll", "Ptr")
        SetPreferredAppMode := DllCall("GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr")
        AllowDarkModeForWindow := DllCall("GetProcAddress", "Ptr", uxtheme, "Ptr", 133, "Ptr")
        

        if (SetPreferredAppMode) {
            DllCall(SetPreferredAppMode, "Int", isDark ? 2 : 0)
        }
    ;    DllCall(AllowDarkModeForWindow, "Ptr", guiObj.Hwnd, "UInt", isDark)
        

        ; --- Title Bar ---
    ;    DWMWA := (VerCompare(A_OSVersion, "10.0.18985") >= 0) ? 20 : 19
    ;    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", guiObj.Hwnd, "int", DWMWA, "int*", isDark, "int", 4)

        guiObj.BackColor := colors.Bg

        ; --- WM_CTLCOLORLISTBOX Handler (FIXED: Toggles cleanly between modes) ---
        static PrevOnCtlBound := 0
        if (PrevOnCtlBound) {
            OnMessage(0x0134, PrevOnCtlBound, 0) ; Disables the old custom drawing handle
            ;MessageManager.Unregister(0x0134, PrevOnCtlBound)
            PrevOnCtlBound := 0
        }

        if (isDark) {
            OnCtlBound := OnCtlColorListbox.Bind(ctrlBGR, textBGR)
            OnMessage(0x0134, OnCtlBound, -1)
            ;MessageManager.Register(0x0134, OnCtlBound, true)
            PrevOnCtlBound := OnCtlBound
        }

        ; --- Apply Theme to Controls ---
        for _, ctrlObj in guiObj {
            try {

                ; --- BYPASS CHECK ---
                ; If the control has a name containing "Color" or "Btn", skip automatic recoloring
                if (ctrlObj.HasOwnProp("BypassTheme") && ctrlObj.BypassTheme)
                    continue

                themeStr := isDark ? "DarkMode_DarkTheme" : "Explorer"

                DllCall(AllowDarkModeForWindow, "Ptr", ctrlObj.Hwnd, "UInt", isDark)
                DllCall("uxtheme.dll\SetWindowTheme", "ptr", ctrlObj.Hwnd, "str", themeStr, "ptr", 0)

                switch ctrlObj.Type {
                    case "Text", "Checkbox", "GroupBox":

                        ctrlObj.Opt("+BackgroundTrans")
                        
                        ; Direct implementation support for dynamic custom object property tags
                        tStyle := ctrlObj.HasOwnProp("ThemeStyle") ? ctrlObj.ThemeStyle : ""
                        
                        if (tStyle == "Strong" || InStr(ctrlObj.Name, "Title") || InStr(ctrlObj.Name, "Strong"))
                            ctrlObj.Opt("c" . colors.TextStrong)
                        else if (tStyle == "Weak" || tStyle == "Smooth" || InStr(ctrlObj.Name, "Footer") || InStr(ctrlObj.Name, "Smooth"))
                            ctrlObj.Opt("c" . colors.TextSmooth)
                        else
                            ctrlObj.Opt("c" . colors.TextDefault)


                        ;if (ctrlObj.Type = "Text")
                        ;   ctrlObj.Opt("+Background" . colors.Bg)

                    case "Edit", "ListBox", "ComboBox", "DDL":
                        ctrlBg := colors.HasOwnProp("Ctrl") ? colors.Ctrl : colors.Bg
                        ctrlObj.Opt("+Background" . ctrlBg . " c" . colors.TextDefault)

                        if (ctrlObj.Type = "ComboBox" || ctrlObj.Type = "DDL") {
                            listHwnd := GetComboListHwnd(ctrlObj)
                            if (listHwnd) {
                                DllCall(AllowDarkModeForWindow, "Ptr", listHwnd, "UInt", isDark)
                                DllCall("uxtheme.dll\SetWindowTheme", "ptr", listHwnd, "str", themeStr, "ptr", 0)
                            }
                        }

                    case "ListView":
                        ctrlBg := colors.HasOwnProp("Ctrl") ? colors.Ctrl : colors.Bg
                        ctrlObj.Opt("+Background" . ctrlBg . " c" . colors.TextDefault)
                        ctrlObj.Opt("-E0x200")

                        hdrHwnd := SendMessage(0x101F, 0, 0, ctrlObj)
                        if (hdrHwnd) {
                            DllCall(AllowDarkModeForWindow, "Ptr", hdrHwnd, "UInt", isDark)
                            DllCall("uxtheme.dll\SetWindowTheme", "ptr", hdrHwnd, "str", themeStr, "ptr", 0)
                        }
                        SetListViewHeaderSubclass(ctrlObj.Hwnd, textBGR)

                    case "Button", "Progress":
                        ctrlObj.Opt("+Background" . colors.Bg)
                }

                PostMessage(0x0128, 0x00010001, 0, ctrlObj.Hwnd)
                ctrlObj.Redraw()
            }
        }
    }

    if transparent {
        isHovering := false
        ;NormalColor := "727272"
        NormalColor := "FFFFFF"
        HoverColor  := "FFFFFF"

        MessageManager.Register(0x0200, OnMouseMoveSettingsGUI)

        OnMouseMoveSettingsGUI(wParam, lParam, msg, hwnd) {
            try {
                if (!btnReset || !btnReset.Hwnd || !btnSave || !btnSave.Hwnd
                 || !KeyUp || !KeyUp.Hwnd || !KeyDown || !KeyDown.Hwnd 
                 || !MouseUp || !MouseUp.Hwnd || !MouseDown || !MouseDown.Hwnd)
                    return
            } catch {
                return
            }
            
            if (hwnd == btnReset.Hwnd || hwnd == btnSave.Hwnd
             || hwnd == KeyUp.Hwnd || hwnd == KeyDown.Hwnd
             || hwnd == MouseUp.Hwnd || hwnd == MouseDown.Hwnd) {

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

;                if (ctrl == btnReset || ctrl == btnSave) {
                    ctrl.SetFont("c" HoverColor)
                    ctrl.Opt("+Background595858")
;                    return
;                }


                if !(ctrl == btnReset || ctrl == btnSave) {
                    DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
                }

            }
        }
    }

    OnMouseLeaveSettingsGUI(wParam, lParam, msg, hwnd) {
        try {
            if (hwnd == btnReset.Hwnd || hwnd == btnSave.Hwnd
                || hwnd == KeyUp.Hwnd || hwnd == KeyDown.Hwnd
                || hwnd == MouseUp.Hwnd || hwnd == MouseDown.Hwnd) {

                ctrl := GuiCtrlFromHwnd(hwnd)
                try ctrl.SetFont("c" NormalColor)
                try ctrl.Opt("+Background282828")
                isHovering := false
                ;OnMessage(0x02A3, OnMouseLeaveSettingsGUI, 0)
            }
        }
    }
}