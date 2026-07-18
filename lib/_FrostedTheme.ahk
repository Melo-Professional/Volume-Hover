/************************************************************************
 * @description Acrylic Theme
 * @author Melo (melo@meloprofessional.com)
 * @credits Owhs at https://www.autohotkey.com/boards/viewtopic.php?style=2&p=617944#p617944
 * @date 2026/07/18
 * @version 1.2.0
 ***********************************************************************/


/* HOW TO USE IT
; Create a standard AHK GUI
MyGui := Gui("+Resize", "My Frosted App")

; Apply the theme with a single class call
FrostedTheme.Apply(MyGui)

; Add some white text
MyGui.SetFont("s20 cWhite bold", "Segoe UI")
MyGui.Add("Text", "BackgroundTrans Center w260 y40", "Class Applied!")

MyGui.SetFont("s12 cWhite", "Segoe UI")
MyGui.Add("Button", "w100 x100 y120", "Click Me")

    ; Button OK
            MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
            ; 6.1 align
        ;        btnX := MyGui.MarginX ; left
                btnX := ((GuiWidth // 2) + 20)
        ;        btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right

            if transparent {
;                MyGui.SetFont("s" Settings.GuiFontSizeBig " C727272 w700", Settings.GuiFontName)
;                btnSave := MyGui.Add("Text", "x" btnX " yp w" BtnWidth " h30 Center 0x0200 Background282828", "OK")
                btnSave.BypassTheme := true
            } else {
                MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
                btnSave := MyGui.AddButton("x" btnX " yp w" BtnWidth " h30 Default", "&OK")
            }

            btnSave.OnEvent("Click", CleanDestroy)


    if transparent {
        ApplyTransparencyToControls(MyGui)
        FrostedTheme.Apply(MyGui)

        isHovering := false
        NormalColor := "727272"
        HoverColor  := "FFFFFF"

        OnMessage(0x0200, OnMouseMove)

        OnMouseMove(wParam, lParam, msg, hwnd) {
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
                    
                    OnMessage(0x02A3, OnMouseLeave)
                }

                if (ctrl == btnReset || ctrl == btnSave) {
                    ctrl.SetFont("c" HoverColor)
                    ctrl.Opt("+Background595858")
                    return
                }

                DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
            }
        }
    } else {
        ApplyThemeToGui(MyGui)
        WatchedGUIs.Push(MyGui)
    }

MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Show("w300 h200")

*/


class FrostedTheme {
    static RegisteredGuis := Map()
    static ChildGuis := Map()

    static Apply(guiObj, childGuiObj := "") {
        if !IsObject(guiObj) || !guiObj.Hwnd
            return

        hwnd := guiObj.Hwnd
        
        if (this.RegisteredGuis.Count = 0) {

            if IsSet(MessageManager) {
                MessageManager.Register(0x0018, this.OnShowWindow.Bind(this))  ; WM_SHOWWINDOW
                MessageManager.Register(0x001A, this.OnThemeChange.Bind(this)) ; WM_SETTINGCHANGE
                MessageManager.Register(0x031A, this.OnThemeChange.Bind(this)) ; WM_THEMECHANGED
            } else {
                OnMessage(0x0018, this.OnShowWindow.Bind(this))  ; WM_SHOWWINDOW
                OnMessage(0x001A, this.OnThemeChange.Bind(this)) ; WM_SETTINGCHANGE
                OnMessage(0x031A, this.OnThemeChange.Bind(this)) ; WM_THEMECHANGED
            }
        }
        this.RegisteredGuis[hwnd] := guiObj

        ; Store associated child GUI if provided
        if (IsObject(childGuiObj) && childGuiObj.Hwnd)
            this.ChildGuis[hwnd] := childGuiObj

        this.ApplyStyles(hwnd, guiObj)
    }

    static ApplyStyles(hwnd, guiObj) {
        ; --- FORCE DWM RESET ---
        ; DWM optimizes out calls if the value hasn't changed. We must set it to DWMSBT_NONE (1)
        ; before setting it back to Acrylic (3) to guarantee DWM throws away the broken opaque 
        ; surface and compiles a fresh acrylic shader when the OS theme changes.
;        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 38, "Int*", 1, "UInt", 4)
        
        ; Dark titlebar (DWMWA_USE_IMMERSIVE_DARK_MODE)
;        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 20, "Int*", 1, "UInt", 4)

         ; Acrylic backdrop (DWMWA_SYSTEMBACKDROP_TYPE = 3)
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 38, "Int*", 3, "UInt", 4)

/*
        ; Extend DWM frame into entire client area so acrylic fills the window
        margins := Buffer(16, 0)
        NumPut("Int", -1, margins, 0)
        NumPut("Int", -1, margins, 4)
        NumPut("Int", -1, margins, 8)
        NumPut("Int", -1, margins, 12)
        DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", hwnd, "Ptr", margins)
 */


    ; ACCENT_STATE
    ; 0 = Disabled
    ; 1 = Gradient
    ; 2 = TransparentGradient
    ; 3 = BlurBehind
    ; 4 = AcrylicBlurBehind
    ; 5 = HostBackdrop (Win10 1809+)

    ACCENT_ENABLE_ACRYLICBLURBEHIND := 1
    ACCENT_ENABLE_ACRYLICBLURBEHIND := 5
    ACCENT_ENABLE_ACRYLICBLURBEHIND := 2
    ACCENT_ENABLE_ACRYLICBLURBEHIND := 3
    ACCENT_ENABLE_ACRYLICBLURBEHIND := 4

;    tint := "0x80444444"
;    tint := "0x80202020"
;    tint := "0x48202020"
;    tint := "0x630f0f0f"
    tint := "0x6c3d3d3d"
    tint := "0x630f0f0f"
    tint := "0x340f0f0f"

    accent := Buffer(16, 0)
    NumPut("Int", ACCENT_ENABLE_ACRYLICBLURBEHIND, accent, 0)
    NumPut("Int", 0, accent, 4)          ; AccentFlags
    NumPut("UInt", tint, accent, 8)      ; GradientColor = AABBGGRR
    NumPut("Int", 0, accent, 12)         ; AnimationId

    data := Buffer(A_PtrSize * 2 + 4, 0)
    NumPut("Int", 19, data, 0)                           ; WCA_ACCENT_POLICY
    NumPut("Ptr", accent.Ptr, data, A_PtrSize)
    NumPut("UInt", accent.Size, data, A_PtrSize * 2)

    DllCall(
        "user32\SetWindowCompositionAttribute",
        "Ptr", guiObj.Hwnd,
        "Ptr", data
    )


        ; Black background: DWM treats pure black as transparent to reveal the acrylic
        guiObj.BackColor := "000000"

        ; Force DWM to recompose
        DllCall("dwmapi\DwmFlush")
        DllCall("user32\RedrawWindow", "Ptr", hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0587)



        ; Apply black background to associated child window
        if (this.ChildGuis.Has(hwnd)) {
            child := this.ChildGuis[hwnd]
            if (child && child.Hwnd) {
                child.BackColor := "000000"
                DllCall("user32\RedrawWindow", "Ptr", child.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0587)
            }
        }
    }

    static OnShowWindow(wp, lp, msg, hwnd) {
        if (wp && this.RegisteredGuis.Has(hwnd)) {  ; wp == 1 when showing
            guiObj := this.RegisteredGuis[hwnd]
            this.ApplyStyles(hwnd, guiObj)
        }
    }

    static ReapplyCallback := ""

    static OnThemeChange(wp, lp, msg, hwnd) {
        if !this.ReapplyCallback
            this.ReapplyCallback := this.ReapplyAll.Bind(this)
        SetTimer(this.ReapplyCallback, -1500)
    }

    static ReapplyAll() {
        for registeredHwnd, guiObj in this.RegisteredGuis {
            if WinExist(registeredHwnd) {
                cb := this.ApplyStyles.Bind(this, registeredHwnd, guiObj)
                this.ForceDWMCompilation(guiObj, cb)
            }
        }
    }
    
    static ForceDWMCompilation(guiObj, applyStylesCallback := "") {
        if (!IsObject(guiObj) || !guiObj.Hwnd || !WinExist(guiObj.Hwnd))
            return
            
        hwnd := guiObj.Hwnd
        prevFocus := WinExist("A")
        
        guiObj.GetPos(&X, &Y)
        wasHidden := (X <= -32000 || Y <= -32000)
        
        if (wasHidden) {
            vx := SysGet(76), vy := SysGet(77), vw := SysGet(78), vh := SysGet(79)
            guiObj.Move(vx + vw - 1, vy + vh - 1)
        }
        
        try WinActivate(hwnd)
        
        if (applyStylesCallback)
            applyStylesCallback()
            
        DllCall("dwmapi\DwmFlush")
        Sleep(50) ; Crucial to wait for DWM to compile the shader
        
        if (wasHidden) {
            guiObj.Move(-32000, -32000)
        }
        
        if (prevFocus)
            try WinActivate(prevFocus)
    }

    static ApplyTransparencyToControls(guiObj) {
        if !Settings.DarkModeCompatible
            return    

        colors := Settings.Theme.Dark
        ;isDark := (CurrentActualTheme == "Dark")
        isDark := true

        ; --- Color Conversion (with fallback) ---
        bgBGR   := this.HexToBGR(colors.Bg)
        ctrlBGR := this.HexToBGR(colors.HasOwnProp("Ctrl") ? colors.Ctrl : colors.Bg)
        textBGR := this.HexToBGR(colors.TextDefault)

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

            if IsSet(MessageManager) {
                MessageManager.Unregister(0x0134, PrevOnCtlBound)
            } else {
                OnMessage(0x0134, PrevOnCtlBound, 0) ; Disables the old custom drawing handle
            }

            PrevOnCtlBound := 0
        }

        if (isDark) {
            OnCtlBound := this.OnCtlColorListbox.Bind(ctrlBGR, textBGR)

            if IsSet(MessageManager) {
                MessageManager.Register(0x0134, OnCtlBound, true)
            } else {
                OnMessage(0x0134, OnCtlBound, -1)
            }

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
                            listHwnd := this.GetComboListHwnd(ctrlObj)
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
                        this.SetListViewHeaderSubclass(ctrlObj.Hwnd, textBGR)

                    case "Button", "Progress":
                        ctrlObj.Opt("+Background" . colors.Bg)
                }

                PostMessage(0x0128, 0x00010001, 0, ctrlObj.Hwnd)
                ctrlObj.Redraw()
            }
        }
    }

    static HexToBGR(hex) {
        if (hex = "")
            return 0
        num := (SubStr(hex, 1, 2) = "0x") ? Integer(hex) : Integer("0x" . StrReplace(hex, "#"))
        return ((num & 0xFF) << 16) | (num & 0xFF00) | ((num >> 16) & 0xFF)
    }

    static GetComboListHwnd(Ctrl) {
        static CBISize := 40 + (A_PtrSize * 3)
        CBI := Buffer(CBISize, 0)
        NumPut("UInt", CBISize, CBI)
        if DllCall("GetComboBoxInfo", "Ptr", Ctrl.Hwnd, "Ptr", CBI)
            return NumGet(CBI, 40 + (A_PtrSize*2), "UInt")
        return 0
    }

    static OnCtlColorListbox(ctrlBGR, textBGR, wParam, lParam, Msg, Hwnd) {
        Critical(-1)
        if !GuiCtrlFromHwnd(Hwnd) {  ; Matches the orphan Dropdown popup menu targets
            DllCall("SetTextColor", "Ptr", wParam, "UInt", textBGR)
            DllCall("SetBkColor",   "Ptr", wParam, "UInt", ctrlBGR)
            DllCall("SetDCBrushColor", "Ptr", wParam, "UInt", ctrlBGR)
            return DllCall("GetStockObject", "Int", 18, "Ptr") ; DC_BRUSH
        }
        return 0
    }

    static SetListViewHeaderSubclass(hwnd, textColor) {
        static Subclassed := Map()
        static pProc := CallbackCreate(this.ListViewHeaderProc, , 6)

        if Subclassed.Has(hwnd) {
            DllCall("RemoveWindowSubclass", "Ptr", hwnd, "Ptr", Subclassed[hwnd], "Ptr", hwnd)
        }

        if DllCall("SetWindowSubclass", "Ptr", hwnd, "Ptr", pProc, "Ptr", hwnd, "Ptr", textColor) {
            Subclassed[hwnd] := pProc
        }
    }

    static ListViewHeaderProc(hWnd, uMsg, wParam, lParam, uIdSubclass, dwRefData) {
        Critical(-1)

        if (uMsg = 0x004E) {  ; WM_NOTIFY
            if (NumGet(lParam, A_PtrSize*2, "Int") = -12) { ; NM_CUSTOMDRAW
                stage := NumGet(lParam, A_PtrSize*3, "UInt")
                hCtrl := NumGet(lParam, "Ptr")

                if (WinGetClass(hCtrl) = "SysHeader32") {
                    if (stage = 0x00000001)      ; CDDS_PREPAINT
                        return 0x20              ; CDRF_NOTIFYITEMDRAW
                    if (stage = 0x00010001) {    ; CDDS_ITEMPREPAINT
                        hdc := NumGet(lParam, A_PtrSize*4, "Ptr")
                        DllCall("SetTextColor", "Ptr", hdc, "UInt", dwRefData)
                        return 0
                    }
                }
            }
        }
        else if (uMsg = 0x0002) { ; WM_DESTROY
            DllCall("RemoveWindowSubclass", "Ptr", hWnd, "Ptr", uIdSubclass, "Ptr", hWnd)
        }

        return DllCall("DefSubclassProc", "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
    }
}