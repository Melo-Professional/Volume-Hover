/************************************************************************
 * @description Custom Title Bar (Isolated Window Messages & Native Move Loop)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/09/01
 * @version 1.6.2 (Parent Gui support)
 ***********************************************************************/

class CustomTitleBar {
    static TitleBars := Map()
    static RegisteredMouseMonitor := false

    /**
     * Attaches a custom emulated title bar layout to an existing GUI.
     */
    static Attach(guiObj, options := "") {
        cfg := { Title: "", ShowIcon: true, Min: true, Max: true, Close: true, Height: 32 }
        if IsObject(options) {
            for k, v in options.OwnProps()
                cfg.%k% := v
        }

        tb := {
            Gui: guiObj,
            Hwnd: guiObj.Hwnd,
            Height: cfg.Height,
            Buttons: Map(),
            Cfg: cfg
        }
        
        this.TitleBars[guiObj.Hwnd] := tb

        guiObj.MarginX := 10
        guiObj.MarginY := 10

        ; 1. Draw Icon if enabled
        currentX := 16
        if (cfg.ShowIcon) {
            iconOpts := "X" currentX " Y" (cfg.Height-16)/2 " W16 H16"
            try {
                iconTarget := HasProp(App, "Icon") ? App.Icon : "shell32.dll"
                iconFlags := (A_IsCompiled && iconTarget == A_ScriptFullPath) ? "Icon1 W16 H16" : "W16 H16"
                
                localType := 0
                hIcon := LoadPicture(iconTarget, iconFlags, &localType)
                
                if (hIcon) {
                    tb.IconCtrl := guiObj.Add("Pic", iconOpts, "HICON:*" hIcon)
                    tb.IconCtrl.noScroll := true  ; <--- FIXED FROM SCROLLING
                } else
                    cfg.ShowIcon := false
            } catch {
                cfg.ShowIcon := false 
            }
            if (cfg.ShowIcon)
                currentX += 32
        }

        ; 2. Draw Optional Title Text
        if (cfg.Title != "") {
            guiObj.SetFont("S10 cWhite", "Segoe UI")
            w := guiObj.HasProp("Width") ? guiObj.Width : 400
            btnAreaWidth := (cfg.Close?46:0) + (cfg.Max?46:0) + (cfg.Min?46:0)
            textWidth := w - currentX - btnAreaWidth - 10
            
            tb.TextCtrl := guiObj.Add("Text", "X" currentX " Y0 W" textWidth " H" cfg.Height " +0x200", cfg.Title)
            tb.TextCtrl.noScroll := true  ; <--- FIXED FROM SCROLLING
        }

        ; 3. Isolated Drag Support
        if (this.TitleBars.Count = 1) {
            if IsSet(MessageManager) {
                MessageManager.Register(0x0201, this.WM_LBUTTONDOWN.Bind(this))
            } else {
                OnMessage(0x0201, this.WM_LBUTTONDOWN.Bind(this))
            }
        }

        ; 4. Isolated Button Hover Monitor
        if (!this.RegisteredMouseMonitor) {
            if IsSet(MessageManager) {
                MessageManager.Register(0x0200, this.HandleMouseMove.Bind(this))
                MessageManager.Register(0x02A3, this.HandleMouseLeave.Bind(this))
            } else {
                OnMessage(0x0200, this.HandleMouseMove.Bind(this))
                OnMessage(0x02A3, this.HandleMouseLeave.Bind(this))
                this.RegisteredMouseMonitor := true
            }
        }

        guiObj.OnEvent("Size", this.OnGuiSize.Bind(this))
        guiObj.OnEvent("Close", (go) => this.CleanClose(go))
        guiObj.OnEvent("Escape", (go) => this.CleanClose(go))

        this.RenderButtons(tb)
        SetTimer(this.Prune.Bind(this), 1000)
        return tb
    }

    static Prune() {
        for parentHwnd, tb in this.TitleBars {
            if (!DllCall("user32\IsWindow", "Ptr", parentHwnd))
                this.TitleBars.Delete(parentHwnd)
        }

        if (this.TitleBars.Count == 0 && this.RegisteredMouseMonitor) {
            if IsSet(MessageManager) {
                MessageManager.Unregister(0x0201, this.WM_LBUTTONDOWN.Bind(this))
                MessageManager.Unregister(0x0200, this.HandleMouseMove.Bind(this))
                MessageManager.Unregister(0x02A3, this.HandleMouseLeave.Bind(this))
            } else {
                OnMessage(0x0201, this.WM_LBUTTONDOWN.Bind(this), 0)
                OnMessage(0x0200, this.HandleMouseMove.Bind(this), 0)
                OnMessage(0x02A3, this.HandleMouseLeave.Bind(this), 0)
            }
            this.RegisteredMouseMonitor := false
            SetTimer(this.Prune.Bind(this), 0)
        }
    }

    static CleanClose(go) {
        if this.TitleBars.Has(go.Hwnd)
            this.TitleBars.Delete(go.Hwnd)
        
        if (this.TitleBars.Count == 0) {
            if IsSet(MessageManager) {
                MessageManager.Unregister(0x0201, this.WM_LBUTTONDOWN.Bind(this))
                MessageManager.Unregister(0x0200, this.HandleMouseMove.Bind(this))
                MessageManager.Unregister(0x02A3, this.HandleMouseLeave.Bind(this))
            } else {
                OnMessage(0x0201, this.WM_LBUTTONDOWN.Bind(this), 0)
                OnMessage(0x0200, this.HandleMouseMove.Bind(this), 0)
                OnMessage(0x02A3, this.HandleMouseLeave.Bind(this), 0)
            }
            this.RegisteredMouseMonitor := false
        }
    }

    static RenderButtons(tb) {
        cfg := tb.Cfg
        guiObj := tb.Gui
        bckcolor := guiObj.BackColor
        tb.BaseBackColor := bckcolor ; Store original background
        tb.HoveredButton := ""       ; Track hover state manually
        
        iconFont := (VerCompare(A_OSVersion, "10.0.22000") >= 0) ? "Segoe Fluent Icons" : "Segoe MDL2 Assets"
        guiObj.SetFont("S8 cWhite", iconFont)
        
        btnWidth := 46
        btnHeight := tb.Height
        w := guiObj.HasProp("Width") ? guiObj.Width : 200
        
        btnStyles := " +Center +0x200 Background" bckcolor

        if (cfg.Close) {
            btnX := "X" . (w - btnWidth)
            tb.Buttons["Close"] := guiObj.Add("Text", btnX . " Y0 W" btnWidth " H" btnHeight btnStyles, Chr(0xE8BB))
            tb.Buttons["Close"].noScroll := true
        }
        if (cfg.Max) {
            offset := cfg.Close ? 2 : 1
            btnX := "X" . (w - (btnWidth * offset))
            tb.Buttons["Max"] := guiObj.Add("Text", btnX . " Y0 W" btnWidth " H" btnHeight btnStyles, Chr(0xE922))
            tb.Buttons["Max"].noScroll := true
        }
        if (cfg.Min) {
            offset := (cfg.Close ? 1 : 0) + (cfg.Max ? 1 : 0) + 1
            btnX := "X" . (w - (btnWidth * offset))
            tb.Buttons["Min"] := guiObj.Add("Text", btnX . " Y0 W" btnWidth " H" btnHeight btnStyles, Chr(0xE921))
            tb.Buttons["Min"].noScroll := true
        }

        guiObj.SetFont("S10 cWhite", "Segoe UI")
    }

    static OnGuiSize(guiObj, minMax, width, height) {
        if !this.TitleBars.Has(guiObj.Hwnd)
            return
        tb := this.TitleBars[guiObj.Hwnd]

        btnWidth := 46
        offset := 1
        
        if tb.Buttons.Has("Close") {
            tb.Buttons["Close"].Move(width - (btnWidth * offset))
            offset++
        }
        if tb.Buttons.Has("Max") {
            tb.Buttons["Max"].Move(width - (btnWidth * offset))
            tb.Buttons["Max"].Text := minMax == 1 ? Chr(0xE923) : Chr(0xE922)
            offset++
        }
        if tb.Buttons.Has("Min") {
            tb.Buttons["Min"].Move(width - (btnWidth * offset))
        }
    }

    static WM_LBUTTONDOWN(wp, lp, msg, hwnd) {
        tb := ""
        for registeredHwnd, item in this.TitleBars {
            parentHwnd := DllCall("user32\GetAncestor", "Ptr", registeredHwnd, "UInt", 1, "Ptr")
            if (hwnd == registeredHwnd || DllCall("user32\IsChild", "Ptr", registeredHwnd, "Ptr", hwnd) || hwnd == parentHwnd) {
                tb := item
                break
            }
        }
        if !tb
            return

        CoordMode "Mouse", "Screen"
        MouseGetPos &startX, &startY
        WinGetPos &tbX, &tbY,,, tb.Hwnd
        mouseY := startY - tbY

        if (mouseY >= 0 && mouseY <= tb.Height) {
            targetHwnd := DllCall("user32\GetAncestor", "Ptr", tb.Hwnd, "UInt", 2, "Ptr")
            if (!targetHwnd)
                targetHwnd := tb.Hwnd

            ; Coordinate Hit-Test for Buttons (catches clicks even if visually transparent)
            for name, ctrl in tb.Buttons {
                if !DllCall("user32\IsWindow", "Ptr", ctrl.Hwnd)
                    continue
                WinGetPos &cX, &cY, &cW, &cH, ctrl.Hwnd
                if (startX >= cX && startX <= cX + cW && startY >= cY && startY <= cY + cH) {
                    if (name == "Close")
                        PostMessage(0x0010, 0, 0, targetHwnd)
                    else if (name == "Max")
                        WinGetMinMax(targetHwnd) ? WinRestore(targetHwnd) : WinMaximize(targetHwnd)
                    else if (name == "Min")
                        WinMinimize(targetHwnd)
                    return 0
                }
            }

            isMaximized := WinGetMinMax(targetHwnd) == 1
            
            if (isMaximized) {
                WinGetPos &maxWinX, &maxWinY, &maxWinW, &maxWinH, "ahk_id " targetHwnd
                clickRatioX := (startX - maxWinX) / maxWinW

                while GetKeyState("LButton", "P") {
                    MouseGetPos &curX, &curY
                    if (Abs(curX - startX) > 5 || Abs(curY - startY) > 5) {
                        WinRestore(targetHwnd)
                        break
                    }
                    Sleep(-1)
                }

                if !GetKeyState("LButton", "P")
                    return
                
                WinGetPos &winX, &winY, &winW, &winH, "ahk_id " targetHwnd
                offsetX := winW * clickRatioX
                offsetY := startY - winY
            } 
            else {
                WinGetPos &winX, &winY, &winW, &winH, "ahk_id " targetHwnd
                offsetX := startX - winX
                offsetY := startY - winY
            }

            DllCall("user32\SetCapture", "Ptr", hwnd)

            while GetKeyState("LButton", "P") {
                MouseGetPos &curX, &curY
                newX := curX - offsetX
                newY := curY - offsetY
                
                DllCall("user32\MoveWindow", "Ptr", targetHwnd, "Int", newX, "Int", newY, "Int", winW, "Int", winH, "Int", 1)
                Sleep(-1) 
            }

            DllCall("user32\ReleaseCapture")
            return 0
        }
    }

    static HandleMouseMove(wParam, lParam, msg, hwnd) {
        ; Start the coordinate-based hover tracker if it isn't running
        if !this.HasProp("TrackingHover") || !this.TrackingHover {
            SetTimer(ObjBindMethod(this, "TrackHoverState"), 50)
            this.TrackingHover := true
        }
        return 0
    }

    static TrackHoverState() {
        CoordMode "Mouse", "Screen"
        MouseGetPos &mX, &mY

        hoveredAny := false

        for registeredHwnd, tb in this.TitleBars {
            if (!DllCall("user32\IsWindow", "Ptr", registeredHwnd))
                continue
            
            for name, ctrl in tb.Buttons {
                if !DllCall("user32\IsWindow", "Ptr", ctrl.Hwnd)
                    continue

                WinGetPos &cX, &cY, &cW, &cH, ctrl.Hwnd
                isInside := (mX >= cX && mX <= cX + cW && mY >= cY && mY <= cY + cH)

                if (isInside) {
                    hoveredAny := true
                    if (!tb.HasProp("HoveredButton") || tb.HoveredButton != name) {
                        ; Clear the previous button if sliding horizontally between them
                        if (tb.HasProp("HoveredButton") && tb.HoveredButton != "") {
                            prevCtrl := tb.Buttons[tb.HoveredButton]
                            prevCtrl.Opt("+Background" tb.BaseBackColor)
                            prevCtrl.Redraw()
                        }

                        tb.HoveredButton := name
                        if (name == "Close")
                            ctrl.Opt("+BackgroundE81123")
                        else
                            ;ctrl.Opt("+Background333333")
                            ;ctrl.Opt("+Background8b8b8b")
                            ctrl.Opt("+Background292929")
                        ctrl.Redraw()
                    }
                }
            }

            ; If mouse leaves all buttons for this GUI, restore transparent color
            if (!hoveredAny && tb.HasProp("HoveredButton") && tb.HoveredButton != "") {
                if tb.Buttons.Has(tb.HoveredButton) {
                    ctrl := tb.Buttons[tb.HoveredButton]
                    ctrl.Opt("+Background" tb.BaseBackColor)
                    ctrl.Redraw()
                }
                tb.HoveredButton := ""
            }
        }

        ; Stop the timer when the mouse is outside all buttons to save CPU
        if (!hoveredAny) {
            SetTimer(ObjBindMethod(this, "TrackHoverState"), 0)
            this.TrackingHover := false
        }
    }

    static HandleMouseLeave(wParam, lParam, msg, hwnd) {
        ; Intentionally left blank.
        ; The TrackHoverState timer now handles exits perfectly regardless of TransColor.
        return 0
    }
}