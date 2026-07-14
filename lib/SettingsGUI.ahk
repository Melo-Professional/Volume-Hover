/************************************************************************
 * @description Settings
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/10
 * @version 1.0.0
 ***********************************************************************/

ShowSettingsGUI() {
    global Settings, General, VolumeOSDNormal, VolumeOSDSlim

    MyGuiTitle := App.Name . " Settings"
    ;MyGuiOptions := "+LastFound -MinimizeBox"
    ;MyGuiOptions := "+Owner +LastFound -MinimizeBox"
    MyGuiOptions := "+LastFound"
    Global SettingsGui := Gui(MyGuiOptions, MyGuiTitle)
    SettingsGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; Define layout constants
    GuiWidth                := 920
    BtnWidth                := 100
    SettingsGui.MarginX     := 50
    SettingsGui.MarginY     := 30

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


;keyboard and mouse TraySetIcon("C:\WINDOWS\System32\ddores.dll", 28)
;mouse TraySetIcon("C:\WINDOWS\System32\ddores.dll", 32)
; keyboard TraySetIcon("C:\WINDOWS\System32\imageres.dll", 174)

; up TraySetIcon("C:\WINDOWS\System32\shell32.dll", 247)
; down TraySetIcon("C:\WINDOWS\System32\shell32.dll", 248)
; multi monitors TraySetIcon("C:\WINDOWS\System32\shell32.dll", 19)

; black plus sign TraySetIcon("C:\WINDOWS\System32\mmcndmgr.dll", 7)
; black minus sign TraySetIcon("C:\WINDOWS\System32\mmcndmgr.dll", 40)
; black arrow up TraySetIcon("C:\WINDOWS\System32\mmcndmgr.dll", 58)
; black arrow down TraySetIcon("C:\WINDOWS\System32\mmcndmgr.dll", 49)

; blue arrow up TraySetIcon("C:\WINDOWS\System32\netshell.dll", 151)
; blue arrow down TraySetIcon("C:\WINDOWS\System32\netshell.dll", 152)
; single window TraySetIcon("C:\WINDOWS\System32\imageres.dll", 262)

; pair of windows TraySetIcon("C:\WINDOWS\System32\imageres.dll", 263)
; pair of windows TraySetIcon("C:\WINDOWS\System32\imageres.dll", 202)

/* 
SettingsGui.Add("Picture", "xm+10 y+30 w24 h-1 Icon28", A_WinDir "\System32\ddores.dll")
SettingsGui.Add("Picture", "x+30 yp w24 h-1 Icon32", A_WinDir "\System32\ddores.dll")
SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon174", A_WinDir "\System32\imageres.dll")

SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon247", A_WinDir "\System32\shell32.dll")
SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon248", A_WinDir "\System32\shell32.dll")
SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon19", A_WinDir "\System32\shell32.dll")

SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon7", A_WinDir "\System32\mmcndmgr.dll")
SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon40", A_WinDir "\System32\mmcndmgr.dll")
SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon58", A_WinDir "\System32\mmcndmgr.dll")
SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon49", A_WinDir "\System32\mmcndmgr.dll")

SettingsGui.Add("Picture", "xm+10 y+30 w24 h-1 Icon151", A_WinDir "\System32\netshell.dll")
SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon152", A_WinDir "\System32\netshell.dll")

SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon262", A_WinDir "\System32\imageres.dll")
SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon263", A_WinDir "\System32\imageres.dll")
SettingsGui.Add("Picture", "x+40 yp w24 h-1 Icon202", A_WinDir "\System32\imageres.dll")
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
            ;SettingsGui.Add("Picture", "xm+20 y+15 w24 h-1 Icon174", A_WinDir "\System32\imageres.dll")
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\keyboard.ico")
        }

        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Up")
        SettingsGui.SetFont("s9 w100")
        Hot1Desc := SettingsGui.Add("Text", "y+1 w300", "Increase volume of the active program")
        Hot1Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w400")
        KeyUp := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        HotkeyManager.BindControl(KeyUp, General.KeyUp, Action_KeyUp)


        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-209", A_ScriptFullPath)
        } else {
            ;SettingsGui.Add("Picture", "xm+20 y+15 w24 h-1 Icon174", A_WinDir "\System32\imageres.dll")
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\keyboard.ico")
        }
        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Down")
        SettingsGui.SetFont("s9 w100")
        Hot2Desc := SettingsGui.Add("Text", "y+1 w300", "Decrease volume of the active program")
        Hot2Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w400")
        KeyDown := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        HotkeyManager.BindControl(KeyDown, General.KeyDown, Action_KeyDown)

        SettingsGui.SetFont("s10 w600")
        SettingsGui.Add("Text", "xm+20 y+25 w500", "Change volume of any program under mouse pointer")

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-210", A_ScriptFullPath)
        } else {
;            SettingsGui.Add("Picture", "xm+20 y+15 w24 h-1 Icon32", A_WinDir "\System32\ddores.dll")
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\mouse.ico")
        }

        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Up")
        SettingsGui.SetFont("s9 w100")
        Hot3Desc := SettingsGui.Add("Text", "y+1 w300", "Increase volume (suggestion: use mouse wheel)")
        Hot3Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w400")
        MouseUp := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        HotkeyManager.BindControl(MouseUp, General.MouseUp, Action_MouseUp)

        if A_IsCompiled {
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon-210", A_ScriptFullPath)
        } else {
;            SettingsGui.Add("Picture", "xm+20 y+15 w24 h-1 Icon32", A_WinDir "\System32\ddores.dll")
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\mouse.ico")
        }
        SettingsGui.SetFont("s11 w400")
        SettingsGui.Add("Text", "x+20 yp-7 w200", "Volume Down")
        SettingsGui.SetFont("s9 w100")
        Hot4Desc := SettingsGui.Add("Text", "y+1 w300", "Decrease volume (suggestion: use mouse wheel)")
        Hot4Desc.ThemeStyle := "Smooth"
        SettingsGui.SetFont("s8 w400")
        MouseDown := SettingsGui.Add("Button", "x" GuiWidth - SettingsGui.MarginX - 20 - 240 " yp-18 h32 w240")
        HotkeyManager.BindControl(MouseDown, General.MouseDown, Action_MouseDown)

    ; OSD
        ;SettingsGui.Add("GroupBox", "xm y+35 w" GuiWidth - (SettingsGui.MarginX * 2) " h280","OSD" )
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
                ;SettingsGui.Add("Picture", "xm+20 y+15 w24 h-1 Icon187", A_WinDir "\System32\imageres.dll")
                SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\OSDType.ico")
            }

            SettingsGui.SetFont("s11 w400")
            SettingsGui.Add("Text", "x+20 yp-7 w200", "Type")
            SettingsGui.SetFont("s9 w100")
            UseOSDDesc := SettingsGui.Add("Text", "y+1 w200", "Select the OSD layout")
            UseOSDDesc.ThemeStyle := "Smooth"
            SettingsGui.SetFont("s11 w400")
            optUseOSD := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r7 w100 Choose" . StartingIndex, General.OSDList)

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
                ;SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon19", A_WinDir "\System32\shell32.dll")
                SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\monitors.ico")
            }

            SettingsGui.SetFont("s11 w400")
            SettingsGui.Add("Text", "x+20 yp-7 w200", "Monitor")
            SettingsGui.SetFont("s9 w100")
            MonitorDesc := SettingsGui.Add("Text", "y+1 w200", "Monitor number to place OSD")
            MonitorDesc.ThemeStyle := "Smooth"
            SettingsGui.SetFont("s11 w400")
            optMonitor := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 80 " yp-17 r12 w80 Choose" . StartingIndex, OSDMonitorList)

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
            ;SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1 Icon176", A_WinDir "\System32\imageres.dll")
            SettingsGui.Add("Picture", "xm+20 y+30 w24 h-1", A_ScriptDir . "\images\position.ico")
            }
            SettingsGui.SetFont("s11 w400")
            SettingsGui.Add("Text", "x+20 yp-7 w200", "Position")
            SettingsGui.SetFont("s9 w100")
            PosDesc := SettingsGui.Add("Text", "y+1 w200", "Vertical alignment on Screen")
            PosDesc.ThemeStyle := "Smooth"
            SettingsGui.SetFont("s11 w400")
            optPosition := SettingsGui.AddDDL("x" GuiWidth - SettingsGui.MarginX - 20 - 100 " yp-17 r7 w100 Choose" . StartingIndex, General.OSDPositionList)
            SettingsGui.SetFont("s" Settings.GuiFontSizeSmall " w400 ")

            if (optUseOSD.Text = "Disable")
                optPosition.Enabled := false

    ; Button Reset
            SettingsGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
            ; 6.1 align
        ;        btnX := SettingsGui.MarginX ; left
                btnX := ((GuiWidth // 2) - BtnWidth - 20)
        ;        btnX := GuiWidth - SettingsGui.MarginX - BtnWidth ; right
            btnReset := SettingsGui.AddButton("x" btnX " y+75 w" BtnWidth " h30 Default", "&Reset")
            btnReset.OnEvent("Click", ResetAll)

    ; Button OK
            SettingsGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
            ; 6.1 align
        ;        btnX := SettingsGui.MarginX ; left
                btnX := ((GuiWidth // 2) + 20)
        ;        btnX := GuiWidth - SettingsGui.MarginX - BtnWidth ; right
            btnSave := SettingsGui.AddButton("x" btnX " yp w" BtnWidth " h30 Default", "&OK")
            btnSave.OnEvent("Click", CleanDestroy)

;SettingsGui.Add("Text", "y+40")


    optUseOSD.OnEvent("Change", ActionsUseOSD)
    optMonitor.OnEvent("Change", ActionsMonitor)
    optPosition.OnEvent("Change", ActionsPosition)

    SettingsGui.OnEvent("Close", CleanDestroy)
    SettingsGui.OnEvent("Escape", CleanDestroy)

    ApplyThemeToGui(SettingsGui)
    WatchedGUIs.Push(SettingsGui)

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
;                    UpdateVolumeOSDNormal("Program", 50)
                    optMonitor.Enabled := true
                    optPosition.Enabled := true
                    ;UpdateOSD("Program", 50)
                    SettingsShowOSD("Program", 50)
                )
            case "Slim": (
;                    UpdateVolumeOSDSlim("Program", 50)
                    optMonitor.Enabled := true
                    optPosition.Enabled := true
                    ;UpdateOSD("Program", 50)
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
        ;UpdateOSD("Program", 50)
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
        ;UpdateOSD("Program", 50)
        SettingsShowOSD("Program", 50)
    }

    Action_KeyUp(newHotkey := "NOT_SET") {
        global General
        
        General.KeyUp := newHotkey
        EnableDisable()
        SaveINI()
        AppVolumeControl.AdjustVolumeByActiveWindow(5)
    }

    Action_KeyDown(newHotkey := "NOT_SET") {
        global General

        General.KeyDown := newHotkey
        EnableDisable()
        SaveINI()
        AppVolumeControl.AdjustVolumeByActiveWindow(-5)
    }

    Action_MouseUp(newHotkey := "") {
        global General

        General.MouseUp := newHotkey
        EnableDisable()
        SaveINI()
        AppVolumeControl.AdjustVolumeByMouse(5)
    }

    Action_MouseDown(newHotkey := "") {
        global General
        
        General.MouseDown := newHotkey
        EnableDisable()
        SaveINI()
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
        ;ReloadClean()
        ReloadWithArgs("ShowSettingsGUI")
    }

    CleanDestroy(*) {
        SettingsGui.Destroy()
        RemoveGuiFromArray(SettingsGui)
        SaveINI()
    }
}