/************************************************************************
 * @description Help GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/29
 * @version 1.4.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowHelpGUI() {
    MyGuiTitle := "Help"
    MyGuiOptions := "+LastFound -SysMenu"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    if IsFunctionDefined("CustomTitleBar") {
        MyGui.Opt("-Caption")
        titlebar := %"CustomTitleBar"%.Attach(MyGui, {
            Title: MyGuiTitle,
            ShowIcon: false,
            Min: true,
            Max: false,
            Close: true
        })
        offset := 60
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
    }

    ; Define layout constants
    GuiWidth            := 480
    BtnWidth            := 100
    MyGui.MarginX       := 50
    MyGui.MarginY       := 30

    ; 1. Icon
    try {
        MyGui.Add("Picture", "xm y" offset " w32 h32", App.Icon)
    } catch {
        MyGui.SetFont("s15 w500")
        MyGui.Add("Text", "y" offset " w32 h32", "[ i ]")
    }

    ; 2. Title and Version
    MyGui.SetFont("s" Settings.GuiFontSizeBig " w700")
    MyGui.Add("Text", "x+15 yp vStrong_Title", App.Name)

    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w400 ")
    MyGui.Add("Text", "y+2 vSmooth_Version", "Version " App.Version)


    ; 3. Content
    MyGui.SetFont("s" Settings.GuiFontSizeBig " w300")
    MyGui.Add("Text", "xm y+50 w" . (GuiWidth - (MyGui.MarginX * 2)), "- Select your preferred scrolling preset directly from the Tray Menu > Profiles.")
    MyGui.Add("Text", "xm y+25 w" . (GuiWidth - (MyGui.MarginX * 2)), "- Open the main interface to fine-tune speed, acceleration and breaking.")
    MyGui.Add("Text", "xm y+25 w" . (GuiWidth - (MyGui.MarginX * 2)), "- Exclude specific applications or programs that do not comfortably support smooth scrolling.")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w100")
    MyGui.Add("Text", "vSmooth_PS xm y+50 w" . (GuiWidth - (MyGui.MarginX * 2)), "*Use hotkey to pause/ activate " . App.Name . ".")
;    MyGui.Add("Text", "xm y+30 w" . (GuiWidth - (MyGui.MarginX * 2)))

    ; 4. Button
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
    ; 5.1 align
;        btnX := MyGui.MarginX ; left
;        btnX := (GuiWidth - BtnWidth) // 2 ; center
        btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right
;    MyGui.AddButton("x" btnX " y+25 w" BtnWidth " h30 Default", "&OK").OnEvent("Click", (*) => myGui.Destroy())
    MyGui.AddButton("x" btnX " y+25 w" BtnWidth " h30 Default", "&OK").OnEvent("Click", CleanDestroy)


    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)

    if IsFunctionDefined("ApplyThemeToGui") {
        %"ApplyThemeToGui"%(MyGui)
        %"WatchedGUIs"%.Push(MyGui)
    }

    MyGui.Show("w" GuiWidth)

    CleanDestroy(*) {
        if IsFunctionDefined("RemoveGuiFromArray")
            %"RemoveGuiFromArray"%(MyGui)
        if (IsSet(CurrentActualTheme) && CurrentActualTheme == "Dark") {
            %"RemoveGuiFromArray"%(MyGui)
        }
        MyGui.Destroy()
    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}

ShouldNormalizeScroll1() {
    global LiveExclusionMap, KineticGui, AddAppsGui
    CoordMode "Mouse", "Screen"
    try {
        MouseGetPos ,, &topHwnd
        if (!topHwnd)
            return true
            
        if (KineticGui != 0 && topHwnd == KineticGui.Hwnd)
            return false
        if (AddAppsGui != 0 && topHwnd == AddAppsGui.Hwnd)
            return false
            
        rootHwnd := DllCall("GetAncestor", "Ptr", topHwnd, "UInt", 2, "Ptr")
        targetHwnd := rootHwnd ? rootHwnd : topHwnd

        topClass := WinGetClass(targetHwnd)
        procName := WinGetProcessName(targetHwnd)
        
        if (topClass == "Shell_SecondaryTrayWnd" || topClass == "Shell_TrayWnd" || topClass == "NewStartServer")
            return false
            
        if LiveExclusionMap.Has(StrLower(procName)) || LiveExclusionMap.Has(StrLower(topClass)) {
            Physics.Velocity := 0.0
            Physics.MomentumReservoir := 0.0
            return false
        }
        
        if (topClass == "ApplicationFrameWindow" || topClass == "Windows.UI.Core.CoreWindow" || InStr(topClass, "Windows.UI.XAML")) {
            return false
        }
    } catch {
        return true 
    }
    return true
}