/************************************************************************
 * @description About GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/18
 * @version 1.7.0 (MessageManager + Acrylic )
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowAboutGUI() {
    MyGuiTitle := "About"
    UseAcrylicGUI := true

    if UseAcrylicGUI {
        MyGuiOptions := "+LastFound -Caption"
    } else {
        MyGuiOptions := "+LastFound -SysMenu"
    }

    MyGui := Gui(MyGuiOptions, MyGuiTitle)

    titlebar := CustomTitleBar.Attach(MyGui, {
        Title: App.Name,
        ShowIcon: false,
        Min: false,
        Max: false,
        Close: true
    })

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)

    TextNormalColor := "CCCCCC"
    TextHoverColor  := "FFFFFF"
    BGroundNormalColor  := "1b1b1b"
    BGroundHoverColor  := "313131"

    if UseAcrylicGUI {
        MyGui.SetFont("c" TextNormalColor " s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    } else {
        MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    }

    ; Define layout constants
    GuiWidth            := 460
    BtnWidth            := 100
    MyGui.MarginX       := 50
    MyGui.MarginY       := 30

    ; 1. Icon
    try {
        MyGui.Add("Picture", "xm y+20 w64 h-1", App.Icon)
    } catch {
        MyGui.SetFont("s22 w500")
        MyGui.Add("Text", "xm y+20 w64 h64", "[ i ]")
    }

    ; 2. Title and Version
    MyGui.SetFont("s" Settings.GuiFontSizeExtraBig " w700")
    if App.Name = App.NameCutted
        MyGui.Add("Text", "vTitle x+15 yp+10 vStrong_Title", App.Name)
    else
        MyGui.Add("Text", "vTitle x+15 yp vStrong_Title", App.NameCutted)

    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w400")
    MyGui.Add("Text", "y+2 vSmooth_Version", "Version " App.Version)

    ; 3. Description
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w400")
    MyGui.Add("Text", "xm y+50 w" . (GuiWidth - (MyGui.MarginX *2)), App.Description)


    if App.Github {
        isHovering := false

        GitNormalColor := "5865F2"
        GitHoverColor  := "5896f2"

        MyGui.SetFont("s" Settings.GuiFontSizeBig " c" GitNormalColor " w800")
        MyLink := MyGui.Add("Text", "-Tabstop xm y+60", "Check Github repository...")
        MyLink.OnEvent("Click", OpenGithub)
        MyLink.BypassTheme := true

        OpenGithub(*) {
            Run(App.Github)
            CleanDestroy()
        }
    }

    ; 4. Credits / Copyright
    MyGui.SetFont("cDefault s" Settings.GuiFontSizeSmall " w400")
    MyGui.Add("Text", "xm y+20 vSmooth_Credits", App.Copyright)

    ; Button OK
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
;    btnX := (GuiWidth - BtnWidth) // 2 ; center
    btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right

    if UseAcrylicGUI {
;        HoverSettingsGui.SetFont("s" Settings.GuiFontSizeBig " C727272 w700", Settings.GuiFontName)
        MyGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
        btnSave := MyGui.Add("Text", "x" btnX " y+25 w" BtnWidth " h30 Center 0x0200 Background282828 +Border", "OK")
        btnSave.BypassTheme := true
    } else {
        MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
        btnSave := MyGui.AddButton("x" btnX " y+25 w" BtnWidth " h30 Default", "&Save")
    }

    btnSave.OnEvent("Click", CleanDestroy)

    if UseAcrylicGUI {
        ApplyThemeToGui(MyGui, "Dark")
        FrostedTheme.Apply(MyGui)
    } else {
        ApplyThemeToGui(MyGui)
        WatchedGUIs.Push(MyGui)
    }


    MyGui.Show()

    if (App.Github || UseAcrylicGUI) {

        if IsSet(MessageManager) {
            MessageManager.Register(0x0200, OnMouseMoveAbout)
        } else {
            OnMessage(0x0200, OnMouseMoveAbout)
        }
    }

    OnMouseMoveAbout(wParam, lParam, msg, hwnd) {
        try {
            if (!btnSave || !btnSave.Hwnd || !MyLink || !MyLink.Hwnd)
                return
        } catch {
            return
        }
        
        if (hwnd == btnSave.Hwnd || hwnd == MyLink.Hwnd) {

            ctrl := GuiCtrlFromHwnd(hwnd)

            if (!isHovering) {
                    isHovering := true
                    
                    TRACKMOUSEEVENT := Buffer(A_PtrSize == 8 ? 24 : 16, 0)
                    NumPut("UInt", TRACKMOUSEEVENT.Size, TRACKMOUSEEVENT, 0)
                    NumPut("UInt", 2,                    TRACKMOUSEEVENT, 4)
                    NumPut("Ptr",  ctrl.Hwnd,          TRACKMOUSEEVENT, A_PtrSize == 8 ? 8 : 8)
                    DllCall("TrackMouseEvent", "Ptr", TRACKMOUSEEVENT)
                    
                    if IsSet(MessageManager) {
                        MessageManager.Register(0x02A3, OnMouseLeaveAbout)
                    } else {
                        OnMessage(0x02A3, OnMouseMoveAbout)
                    }
            }


            if (ctrl == MyLink) {
                DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
                ctrl.SetFont("c" GitHoverColor)
            } else {
                ctrl.SetFont("c" TextHoverColor)
                ctrl.Opt("+Background" BGroundHoverColor)
            }
        }
    }    

    OnMouseLeaveAbout(wParam, lParam, msg, hwnd) {
        try {
            if (hwnd == btnSave.Hwnd || hwnd == MyLink.Hwnd) {
                ctrl := GuiCtrlFromHwnd(hwnd)

                if (ctrl == MyLink) {
                    ctrl.SetFont("c" GitNormalColor)
                } else {
                    ctrl.SetFont("c" TextNormalColor)
                    ctrl.Opt("+Background" BGroundNormalColor)

                }
                isHovering := false
            }
        }
    }

    CleanDestroy(*) {
        if App.HasOwnProp("Github"){

            if IsSet(MessageManager) {
                MessageManager.Unregister(0x0200, OnMouseMoveAbout)
                MessageManager.Unregister(0x02A3, OnMouseLeaveAbout)
            } else {
                OnMessage(0x0200, OnMouseMoveAbout, 0)
                OnMessage(0x02A3, OnMouseLeaveAbout, 0)
            }
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