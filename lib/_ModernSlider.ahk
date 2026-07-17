/************************************************************************
 * @description Modern Slider for AutoHotKey v2
 * @author Melo
 * @date 2026/07/16
 * @version 3.0.3 (MessageManager)
 ***********************************************************************/

/* 
; EXAMPLE
myGui := Gui("+AlwaysOnTop", "Modern Themed Sliders")
myGui.SetFont("s10", "Segoe UI")

; --- Custom Color Palettes ---
; Format: [TrackActiveColor, TrackBgColor, ThumbColor]
lightPalette := ["0078D7", "58E0E0E0", "0078D7"] ; Windows Blue theme
lightPalette := ["0078D7", "2fff0000", "0078D7"] ; Windows Blue theme
darkPalette  := ["6BA4FF", "58333333", "6BA4FF"] ; High-contrast Soft Blue

; --- Slider 1: Light Mode Forced ---
myGui.Add("Text", "x20 y15 w200 h20", "Forced Light Mode")
s1 := ModernSlider(myGui, "x20 y35 w300 h40", 30, 0, 100, (v,*)=>t1.Value:=v "%", "Light", lightPalette, darkPalette)
t1 := myGui.Add("Text", "x330 y43 w50", "30%")

; --- Slider 2: Dark Mode Forced ---
myGui.Add("Text", "x20 y80 w200 h20", "Forced Dark Mode")
s2 := ModernSlider(myGui, "x20 y100 w300 h40", 70, 0, 100, (v,*)=>t2.Value:=v "%", "Dark")
t2 := myGui.Add("Text", "x330 y108 w50", "70%")

; --- Slider 3: Auto Mode (Follows Windows OS Theme) ---
myGui.Add("Text", "x20 y145 w200 h20", "Auto Theme (Follows Windows)")
;s3 := ModernSlider(myGui, "x20 y165 w300 h40", 50, 0, 200, (v,*)=>t3.Value:=v "%")
t3 := myGui.Add("Text", "x330 y173 w50", "50%")
s3 := ModernSlider(myGui, "x20 y165 w300 h40", 50, 0, 200, OnSliderChange.Bind(t3))

OnSliderChange(lbl, newVal, *) {
    lbl.Text := newVal
}
F2::myGui.Show("w400 h230")
 */


#Requires AutoHotkey v2.0
#DllLoad "gdiplus"

class ModernSlider {
    static Instances := [] 
    static RegisteredThemeMonitor := false
    static RegisteredMouseMonitor := false
    
    static GdipToken := ModernSlider.InitGdip()

    static InitGdip() {
        si := Buffer(24, 0)
        NumPut("UInt", 1, si, 0)
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken:=0, "Ptr", si, "Ptr", 0)
        OnExit(ObjBindMethod(ModernSlider, "ShutdownGdip"))
        return pToken
    }

    static ShutdownGdip(*) {
        if (ModernSlider.GdipToken) {
            DllCall("gdiplus\GdiplusShutdown", "Ptr", ModernSlider.GdipToken)
            ModernSlider.GdipToken := 0
        }
    }

    hwnd := 0
    min := 0
    max := 100
    callback := ""
    themeMode := "Auto" 
    
    lightColors := ["0067C0", "17b0b0b0", "005A9E"] ; [TrackActive, TrackBg, Thumb]
    darkColors  := ["4CC2FF", "58141414", "88cff3"] ; [TrackActive, TrackBg, Thumb]
    
    ctrlX := 0, ctrlY := 0, ctrlW := 0, ctrlH := 0
    trackH := 5
    thumbSize := 15
    paddingX := 12 
    
    guiObj := ""
    sliderCtrl := ""
    _value := 0
    isHovered := false
    isDragging := false
    isTrackingMouse := false
    rectBuffer := ""

    __New(guiObj, options := "", startValue := 0, min := 0, 
        max := 100, callback := "", themeMode := "Auto", lightColors := "", darkColors := "") {
        this.guiObj := guiObj
        this.min := min
        this.max := max
        this.themeMode := themeMode
        this.callback := callback
        
        if (lightColors is Array)
            this.lightColors := lightColors
  
        if (darkColors is Array)
            this.darkColors := darkColors

        this._value := startValue < min ? min : (startValue > max ? max : startValue)

        x := 10, y := 10, w := 200, h := 40 
        RegExMatch(options, "i)\bx(\d+)", &m) ? x := Integer(m[1]) : ""
        RegExMatch(options, "i)\by(\d+)", &m) ? y := Integer(m[1]) : ""
        RegExMatch(options, "i)\bw(\d+)", &m) ? w := Integer(m[1]) : ""
        RegExMatch(options, "i)\bh(\d+)", &m) ? h := Integer(m[1]) : ""
        
        this.ctrlX := x, this.ctrlY := y, this.ctrlW := w, this.ctrlH := h

        pad := 3
        this.rectBuffer := Buffer(16)
        NumPut("Int", x - pad, this.rectBuffer, 0)
        NumPut("Int", y - pad, this.rectBuffer, 4)
        NumPut("Int", x + w + pad, this.rectBuffer, 8)
        NumPut("Int", y + h + pad, this.rectBuffer, 12)

        ; Create standard transparent Picture control (100% compatible with transparent designs)
        this.sliderCtrl := guiObj.Add("Pic", "x" x " y" y " w" w " h" h " -Border -E0x200 +BackgroundTrans +0xE")
        this.hwnd := this.sliderCtrl.hwnd 
        
        ; Explicitly strip native borders to guarantee layout integration
        try {
            style := DllCall("user32\GetWindowLong", "Ptr", this.hwnd, "Int", -16, "UInt")
            DllCall("user32\SetWindowLong", "Ptr", this.hwnd, "Int", -16, "UInt", style & ~0x00800000) ; -WS_BORDER
            exStyle := DllCall("user32\GetWindowLong", "Ptr", this.hwnd, "Int", -20, "UInt")
            DllCall("user32\SetWindowLong", "Ptr", this.hwnd, "Int", -20, "UInt", exStyle & ~0x00000200) ; -WS_EX_CLIENTEDGE
            DllCall("uxtheme\SetWindowTheme", "Ptr", this.hwnd, "Str", "", "Str", "")
        }
        
        ModernSlider.Instances.Push(this)
        
        this.sliderCtrl.OnEvent("Click", (ctrl, *) => this.OnDrag())

        if IsSet(MessageManager) {
            MessageManager.Register(0x0201, this.HandleLButtonDown.Bind(this)) 
            MessageManager.Register(0x020A, this.HandleWheelMessage.Bind(this)) 
            MessageManager.Register(0x0100, this.HandleKeyDown.Bind(this))      
        } else {
            OnMessage(0x0201, this.HandleLButtonDown.Bind(this)) 
            OnMessage(0x020A, this.HandleWheelMessage.Bind(this)) 
            OnMessage(0x0100, this.HandleKeyDown.Bind(this))      
        }

        if (!ModernSlider.RegisteredThemeMonitor) {
            if IsSet(MessageManager) {
                MessageManager.Register(0x001A, ModernSlider.OnSettingChange.Bind(ModernSlider))   
            } else {
                OnMessage(0x001A, ModernSlider.OnSettingChange.Bind(ModernSlider))   
            }

            ModernSlider.RegisteredThemeMonitor := true
        }

        if (!ModernSlider.RegisteredMouseMonitor) {
            if IsSet(MessageManager) {
                MessageManager.Register(0x0200, ModernSlider.HandleMouseMove.Bind(ModernSlider)) 
                MessageManager.Register(0x02A3, ModernSlider.HandleMouseLeave.Bind(ModernSlider))
            } else {
                OnMessage(0x0200, ModernSlider.HandleMouseMove.Bind(ModernSlider)) 
                OnMessage(0x02A3, ModernSlider.HandleMouseLeave.Bind(ModernSlider))
            }
            ModernSlider.RegisteredMouseMonitor := true
        }
        
        this.UpdatePosition(false)
    }

    static CleanDeadInstances() {
        active := []
        for instance in ModernSlider.Instances {
            if (instance.hwnd && DllCall("user32\IsWindow", "Ptr", instance.hwnd, "Int"))
                active.Push(instance)
        }
        ModernSlider.Instances := active
    }

    GetActiveColors() {
        if (this.themeMode == "Light")
            return this.lightColors
        if (this.themeMode == "Dark")
            return this.darkColors
            
        try {
            lightTheme := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
            return lightTheme ? this.lightColors : this.darkColors
        } catch {
            return this.lightColors 
        }
    }

    SetControlBitmap(hBitmap) {
        if (!this.hwnd || !DllCall("user32\IsWindow", "Ptr", this.hwnd, "Int"))
            return

        hOld := SendMessage(0x172, 0, hBitmap, this.hwnd) ; STM_SETIMAGE
        if (hOld) {
            DllCall("gdi32\DeleteObject", "Ptr", hOld)
        }

        ; Force the parent window to paint this area synchronously to avoid any flickering
        DllCall("user32\InvalidateRect", "Ptr", this.guiObj.Hwnd, "Ptr", this.rectBuffer, "Int", 1)
        DllCall("user32\UpdateWindow", "Ptr", this.guiObj.Hwnd)
    }

    RenderSliderBitmap() {
        w := this.ctrlW, h := this.ctrlH
        pct := (this._value - this.min) / (this.max - this.min)
        colors := this.GetActiveColors()
        
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pBitmap:=0)
        
        DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", &pGraphics:=0)
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
        
        ; Clear canvas with absolute alpha transparency (0)
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "Int", 0)
        
        trackW := w - (this.paddingX * 2)
        trackY := h / 2
        xStart := this.paddingX
        xEnd := this.paddingX + trackW
        
        ; --- 1. Draw Track Background ---
        trackBgCol := (StrLen(colors[2]) == 8) ? Integer("0x" colors[2]) : (0xFF000000 | Integer("0x" colors[2]))
        DllCall("gdiplus\GdipCreatePen1", "UInt", trackBgCol, "Float", this.trackH, "Int", 2, "Ptr*", &pPenBg:=0)
        DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPenBg, "Int", 2) ; LineCapRound := 2
        DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenBg, "Int", 2)
        DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenBg, "Float", xStart, "Float", trackY, "Float", xEnd, "Float", trackY)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPenBg)
        
        ; --- 2. Draw Active Foreground Track ---
        activeW := Round(pct * trackW)
        if (activeW > 0) {
            trackActiveCol := (StrLen(colors[1]) == 8) ? Integer("0x" colors[1]) : (0xFF000000 | Integer("0x" colors[1]))
            DllCall("gdiplus\GdipCreatePen1", "UInt", trackActiveCol, "Float", this.trackH, "Int", 2, "Ptr*", &pPenActive:=0)
            DllCall("gdiplus\GdipSetPenStartCap", "Ptr", pPenActive, "Int", 2)
            DllCall("gdiplus\GdipSetPenEndCap", "Ptr", pPenActive, "Int", 2)
            DllCall("gdiplus\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPenActive, "Float", xStart, "Float", trackY, "Float", xStart + activeW, "Float", trackY)
            DllCall("gdiplus\GdipDeletePen", "Ptr", pPenActive)
        }
        
        ; --- 3. Draw Thumb ---
        thumbSize := (this.isHovered || this.isDragging) ? (this.thumbSize * 1.2) : this.thumbSize
        thumbColorHex := (this.isHovered || this.isDragging) ? colors[1] : colors[3]
        thumbColor := (StrLen(thumbColorHex) == 8) ? Integer("0x" thumbColorHex) : (0xFF000000 | Integer("0x" thumbColorHex))
        
        thumbCenterX := this.paddingX + (pct * trackW)
        thumbCenterY := h / 2
        thumbLeft := thumbCenterX - (thumbSize / 2)
        thumbTop := thumbCenterY - (thumbSize / 2)
        
        DllCall("gdiplus\GdipCreateSolidFill", "Int", thumbColor, "Ptr*", &pBrushThumb:=0)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrushThumb, "Float", thumbLeft, "Float", thumbTop, "Float", thumbSize, "Float", thumbSize)
        
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", &hBitmap:=0, "Int", 0)
        
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushThumb)
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        
        return hBitmap
    }

    ApplyTheme() {
        this.UpdatePosition(false)
    }

    static OnSettingChange(wParam, lParam, msg, hwnd) {
        ModernSlider.CleanDeadInstances()
        if (lParam != 0 && StrGet(lParam) == "ImmersiveColorSet") {
            for instance in ModernSlider.Instances {
                if (instance.themeMode == "Auto")
                    instance.ApplyTheme()
            }
        }
    }

    static HandleMouseMove(wParam, lParam, msg, hwnd) {
        ModernSlider.CleanDeadInstances()
        try {
            for instance in ModernSlider.Instances {
                if (!instance.hwnd || !DllCall("user32\IsWindow", "Ptr", instance.hwnd, "Int"))
                    continue
                
                if (!instance.isTrackingMouse) {
                    tme := Buffer(8 + A_PtrSize * 2, 0)
                    NumPut("UInt", tme.Size, tme, 0)
                    NumPut("UInt", 2, tme, 4) ; TME_LEAVE
                    NumPut("Ptr", instance.hwnd, tme, 8)
                    DllCall("user32\TrackMouseEvent", "Ptr", tme)
                    instance.isTrackingMouse := true
                }

                instance.GetLocalMousePos(&mx, &my)
                
                pct := (instance._value - instance.min) / (instance.max - instance.min)
                trackW := instance.ctrlW - (instance.paddingX * 2)
                thumbCenterX := instance.paddingX + (pct * trackW)
                thumbCenterY := instance.ctrlH / 2
                
                dx := mx - thumbCenterX
                dy := my - thumbCenterY
                distance := Sqrt(dx*dx + dy*dy)
                
                isOverThumb := (distance <= 14)
                
                if (isOverThumb != instance.isHovered && !instance.isDragging) {
                    instance.isHovered := isOverThumb
                    instance.UpdatePosition(false)
                }
            }
        }
    }

    static HandleMouseLeave(wParam, lParam, msg, hwnd) {
        ModernSlider.CleanDeadInstances()
        try {
            for instance in ModernSlider.Instances {
                if (instance.hwnd == hwnd) {
                    instance.isTrackingMouse := false
                    if (instance.isHovered && !instance.isDragging) {
                        instance.isHovered := false
                        instance.UpdatePosition(false)
                    }
                }
            }
        }
    }

    UpdatePosition(triggerCallback := true) {
        if (!this.hwnd || !DllCall("user32\IsWindow", "Ptr", this.hwnd, "Int"))
            return

        hBmp := this.RenderSliderBitmap()
        this.SetControlBitmap(hBmp)
        
        if (triggerCallback && this.callback) {
            try {
                this.callback.Call(this._value, this)
            } catch {
                try {
                    this.callback.Call(this._value)
                } catch {
                    this.callback.Call()
                }
            }
        }
    }
    
    IsHwndTarget(hwnd) {
        if (!this.hwnd || !DllCall("user32\IsWindow", "Ptr", this.hwnd, "Int"))
            return false

        topHwnd := DllCall("GetAncestor", "Ptr", this.guiObj.Hwnd, "UInt", 2, "Ptr")
        return (hwnd == this.hwnd || hwnd == topHwnd || DllCall("IsChild", "Ptr", topHwnd, "Ptr", hwnd))
    }

    GetLocalMousePos(&mx, &my) {
        pt := Buffer(8)
        DllCall("GetCursorPos", "Ptr", pt)
        DllCall("ScreenToClient", "Ptr", this.guiObj.Hwnd, "Ptr", pt)
        mx := NumGet(pt, 0, "Int") - this.ctrlX
        my := NumGet(pt, 4, "Int") - this.ctrlY
    }

    IsMouseOverSlider(mx, my, padding := 10) {
        return (mx >= -padding
             && mx <= this.ctrlW + padding 
             && my >= -padding 
             && my <= this.ctrlH + padding)
    }

    OnDrag() {
        this.isDragging := true
        
        while GetKeyState("LButton", "P") {
            if (!this.hwnd || !DllCall("user32\IsWindow", "Ptr", this.hwnd, "Int"))
                break

            this.GetLocalMousePos(&mx, &my)
            
            trackW := this.ctrlW - (this.paddingX * 2)
            pct := (mx - this.paddingX) / trackW
            pct := pct < 0 ? 0 : (pct > 1 ? 1 : pct)
            
            newValue := Round(this.min + (pct * (this.max - this.min)))
            if (newValue != this._value) {
                this._value := newValue
                this.UpdatePosition(true)
            }
            Sleep(10) 
        }
        
        this.isDragging := false
        
        this.GetLocalMousePos(&mx, &my)
        pct := (this._value - this.min) / (this.max - this.min)
        trackW := this.ctrlW - (this.paddingX * 2)
        thumbCenterX := this.paddingX + (pct * trackW)
        thumbCenterY := this.ctrlH / 2
        this.isHovered := (Sqrt((mx - thumbCenterX)**2 + (my - thumbCenterY)**2) <= 14)
        
        this.UpdatePosition(false)
    }

    HandleLButtonDown(wParam, lParam, msg, hwnd) {
        ModernSlider.CleanDeadInstances()
        if (this.IsHwndTarget(hwnd)) {
            this.GetLocalMousePos(&mx, &my)
            if (this.IsMouseOverSlider(mx, my, 2)) {
                trackW := this.ctrlW - (this.paddingX * 2)
                pct := (mx - this.paddingX) / trackW
                pct := pct < 0 ? 0 : (pct > 1 ? 1 : pct)
                this.SetValue(Round(this.min + (pct * (this.max - this.min))), true)
                this.OnDrag()
                return 0 
            }
        }
    }

    HandleKeyDown(wParam, lParam, msg, hwnd) {
        ModernSlider.CleanDeadInstances()
        if (this.IsHwndTarget(hwnd)) {
            this.GetLocalMousePos(&mx, &my)
            if (this.IsMouseOverSlider(mx, my)) {
                switch wParam {
                    case 37, 40: 
                        this.SetValue(this._value - 1, true)
                        return 0
                    case 39, 38: 
                        this.SetValue(this._value + 1, true)
                        return 0
                    case 33:    
                        this.SetValue(this._value + ((this.max - this.min) // 10), true)
                        return 0
                    case 34:    
                        this.SetValue(this._value - ((this.max - this.min) // 10), true)
                        return 0
                }
            }
        }
    }

    HandleWheelMessage(wParam, lParam, msg, hwnd) {
        ModernSlider.CleanDeadInstances()
        if (this.IsHwndTarget(hwnd)) {
            this.GetLocalMousePos(&mx, &my)
            if (this.IsMouseOverSlider(mx, my, 5)) { 
                ; Extract standard signed 16-bit scroll wheel delta
                delta := (wParam >> 16) & 0xFFFF
                if (delta > 0x7FFF)
                    delta -= 0x10000
                
                ; Dynamically step size depending on total range depth
                stepSize := (this.max - this.min) > 20 ? 2 : 1
                
                ; Scale actual steps relative to a standard wheel tick (120 units)
                actualSteps := Round((delta / 120) * stepSize)
                
                ; Safety fallback for ultra-precise micro-ticks (assures physical movement)
                if (actualSteps == 0 && delta != 0) {
                    actualSteps := delta > 0 ? 1 : -1
                }
                
                if (actualSteps != 0) {
                    this.SetValue(this._value + actualSteps, true)
                }
                return 0 
            }
        }
    }

    SetValue(value, triggerCallback := false) {
        val := value < this.min ? this.min : (value > this.max ? this.max : value)
        if (val != this._value) {
            this._value := val
            this.UpdatePosition(triggerCallback)
        }
    }

    Value {
        get => this._value
        set => this.SetValue(value, false) ; Programmatic modifications NEVER trigger the callback loop
    }
}