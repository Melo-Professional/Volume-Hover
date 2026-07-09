/************************************************************************
 * @description About GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/22
 * @version 1.5.2
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowAboutGUI() {
    MyGuiTitle := "About"
    MyGuiOptions := "+LastFound -SysMenu"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; Define layout constants
    GuiWidth            := 460
    BtnWidth            := 80
    MyGui.MarginX       := 50
    MyGui.MarginY       := 30

    ; 1. Icon
    try {
        MyGui.Add("Picture", "w64 h-1", App.Icon)
    } catch {
        MyGui.SetFont("s22 w500")
        MyGui.Add("Text", "w64 h64", "[ i ]")
    }

    ; 2. Title and Version
    MyGui.SetFont("s" Settings.GuiFontSizeExtraBig " w700")
    if App.Name = App.NameCutted
        MyGui.Add("Text", "x+15 y40 vStrong_Title", App.Name)
    else
        MyGui.Add("Text", "x+15 y28 vStrong_Title", App.NameCutted)

    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w400")
    MyGui.Add("Text", "y+2 vSmooth_Version", "Version " App.Version)

    ; 3. Description
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w400")
    MyGui.Add("Text", "xm y+50 w" . (GuiWidth - (MyGui.MarginX *2)), App.Description)


    if App.Github {
        isHovering := false

        NormalColor := "5865F2"
        HoverColor  := "5896f2"

        MyGui.SetFont("s" Settings.GuiFontSizeBig " c" NormalColor " w800")
        MyLink := MyGui.Add("Text", "-Tabstop xm y+60", "Check Github repository...")
        MyLink.OnEvent("Click", OpenGithub)
        MyLink.BypassTheme := true

        OpenGithub(*) {
            Run(App.Github)
            CleanDestroy()
        }

        OnMessage(0x0200, OnMouseMove)

        OnMouseMove(wParam, lParam, msg, hwnd) {
            try {
                if (!MyLink || !MyLink.Hwnd)
                    return
            } catch {
                return
            }
            
            if (hwnd == MyLink.Hwnd) {
                if (!isHovering) {
                    isHovering := true
                    MyLink.SetFont("c" HoverColor)
                    
                    TRACKMOUSEEVENT := Buffer(A_PtrSize == 8 ? 24 : 16, 0)
                    NumPut("UInt", TRACKMOUSEEVENT.Size, TRACKMOUSEEVENT, 0)
                    NumPut("UInt", 2,                    TRACKMOUSEEVENT, 4)
                    NumPut("Ptr",  MyLink.Hwnd,          TRACKMOUSEEVENT, A_PtrSize == 8 ? 8 : 8)
                    DllCall("TrackMouseEvent", "Ptr", TRACKMOUSEEVENT)
                    
                    OnMessage(0x02A3, OnMouseLeave)
                }
                DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
            }
        }
    }

    ; 4. Credits / Copyright
    MyGui.SetFont("cDefault s" Settings.GuiFontSizeSmall " w400")
    MyGui.Add("Text", "xm y+20 vSmooth_Credits", App.Copyright)

    ; 5. Button
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
    btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right
    MyGui.AddButton("x" (GuiWidth - MyGui.MarginX - BtnWidth) " y+25 w" BtnWidth " h30 Default", "&OK").OnEvent("Click", CleanDestroy)

    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)
    if IsFunctionDefined("ApplyThemeToGui") {
        %"ApplyThemeToGui"%(MyGui)
        %"WatchedGUIs"%.Push(MyGui)
    }

    MyGui.Show()
    
    OnMouseLeave(wParam, lParam, msg, hwnd) {
        try MyLink.SetFont("c" NormalColor)
        isHovering := false
        OnMessage(0x02A3, OnMouseLeave, 0)
    }

    CleanDestroy(*) {
        if App.HasOwnProp("Github"){
            OnMessage(0x0200, OnMouseMove, 0) 
            OnMessage(0x02A3, OnMouseLeave, 0)
        }
        
        if IsFunctionDefined("RemoveGuiFromArray")
            %"RemoveGuiFromArray"%(MyGui)
        MyGui.Destroy()
    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}