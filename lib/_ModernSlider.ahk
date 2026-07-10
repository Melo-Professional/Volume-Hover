/************************************************************************
 * @description Modern Slider for AutoHotKey v2
 * @author Melo
 * @date 2026/07/10
 * @version 1.0.0
 ***********************************************************************/


/* 
; EXAMPLE
myGui := Gui("+AlwaysOnTop", "Modern Themed Sliders")
myGui.SetFont("s10", "Segoe UI")

; --- Custom Color Palettes ---
; Format: [TrackColor, BackgroundColor, ThumbColor]
lightPalette := ["0078D7", "E0E0E0", "0078D7"] ; Windows Blue theme
darkPalette  := ["6BA4FF", "333333", "6BA4FF"] ; High-contrast Soft Blue

; --- Slider 1: Light Mode Forced ---
myGui.Add("Text", "x20 y15 w200 h20", "Forced Light Mode")
s1 := ModernSlider(myGui, "x20 y35 w300 h40", 30, 0, 100, (v,*)=>t1.Value:=v "%", "Light", lightPalette, darkPalette)
t1 := myGui.Add("Text", "x330 y43 w50", "30%")

; --- Slider 2: Dark Mode Forced ---
myGui.Add("Text", "x20 y80 w200 h20", "Forced Dark Mode")
;s2 := ModernSlider(myGui, "x20 y100 w300 h40", 70, 0, 100, (v,*)=>t2.Value:=v "%", "Dark", lightPalette, darkPalette)
s2 := ModernSlider(myGui, "x20 y100 w300 h40", 70, 0, 100, (v,*)=>t2.Value:=v "%", "Dark")
t2 := myGui.Add("Text", "x330 y108 w50", "70%")

; --- Slider 3: Auto Mode (Follows Windows OS Theme) ---
myGui.Add("Text", "x20 y145 w200 h20", "Auto Theme (Follows Windows)")
;s3 := ModernSlider(myGui, "x20 y165 w300 h40", 50, 0, 100, (v,*)=>t3.Value:=v "%", "Auto", lightPalette, darkPalette)
;s3 := ModernSlider(myGui, "x20 y165 w300 h40", 50, 0, 100, (v,*)=>t3.Value:=v "%", "Auto")
s3 := ModernSlider(myGui, "x20 y165 w300 h40", 50, 0, 200, (v,*)=>t3.Value:=v "%")
t3 := myGui.Add("Text", "x330 y173 w50", "50%")

myGui.Show("w400 h230")
 */

#Requires AutoHotkey v2.0

class ModernSlider {
    static Instances := [] 
    static RegisteredThemeMonitor := false

    hwnd := 0
    min := 0
    max := 100
    callback := ""
    themeMode := "Auto" 
    
    lightColors := ["0067C0", "E5E5E5", "0078D7"]
    darkColors  := ["4CC2FF", "333333", "0078D7"]
    
    ctrlX := 0, ctrlY := 0, ctrlW := 0, ctrlH := 0
    trackX := 0, trackY := 0, trackW := 0, trackH := 6
    thumbW := 20, thumbH := 20
    
    guiObj := ""
    track := ""
    thumb := ""
    _value := 0

    __New(guiObj, options := "", startValue := 0, min := 0, max := 100, callback := "", themeMode := "Auto", lightColors := "", darkColors := "") {
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

        x := 10, y := 10, w := 200, h := 0 
        RegExMatch(options, "i)\bx(\d+)", &m) ? x := Integer(m[1]) : ""
        RegExMatch(options, "i)\by(\d+)", &m) ? y := Integer(m[1]) : ""
        RegExMatch(options, "i)\bw(\d+)", &m) ? w := Integer(m[1]) : ""
        RegExMatch(options, "i)\bh(\d+)", &m) ? h := Integer(m[1]) : ""
        
        this.ctrlX := x, this.ctrlY := y, this.ctrlW := w, this.ctrlH := h
        this.trackX := x + (this.thumbW / 2)
        this.trackY := y + (h / 2)
        this.trackW := w - this.thumbW

        colors := this.GetActiveColors()

        this.track := guiObj.Add("Progress", "x" this.trackX " y" this.trackY " w" this.trackW " h" this.trackH " -Smooth c" colors[1] " Background" colors[2], this._value)
        this.track.BypassTheme := true
        
        thumbY := y + (h / 2) - (this.thumbH / 2)
        this.thumb := guiObj.Add("Text", "x" x " y" (thumbY + 3) " w" this.thumbW " h" this.thumbH " Center BackgroundTrans c" colors[3], "⚫")
        this.thumb.SetFont("s13", "Arial")
        this.thumb.BypassTheme := true
        
        this.hwnd := this.thumb.hwnd 
        
        ModernSlider.Instances.Push(this)
        
        this.thumb.OnEvent("Click", (ctrl, *) => this.OnDrag())
        OnMessage(0x0201, this.HandleLButtonDown.Bind(this)) 
        OnMessage(0x020A, this.HandleWheelMessage.Bind(this)) 
        OnMessage(0x0100, this.HandleKeyDown.Bind(this))      
        
        if (!ModernSlider.RegisteredThemeMonitor) {
            OnMessage(0x001A, ModernSlider.OnSettingChange.Bind(ModernSlider))   
            ModernSlider.RegisteredThemeMonitor := true
        }
        
        this.UpdatePosition(false)
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

    ApplyTheme() {
        colors := this.GetActiveColors()
        this.track.Opt("c" colors[1] " Background" colors[2])
        this.thumb.Opt("c" colors[3])
        this.UpdatePosition(false)
    }

    static OnSettingChange(wParam, lParam, msg, hwnd) {
        if (lParam != 0 && StrGet(lParam) == "ImmersiveColorSet") {
            for instance in ModernSlider.Instances {
                if (instance.themeMode == "Auto")
                    instance.ApplyTheme()
            }
        }
    }

    UpdatePosition(triggerCallback := true) {
        ; SAFE CHECK: Using direct Win32 API to check if control still physically exists
        if (!this.thumb || !DllCall("user32\IsWindow", "Ptr", this.thumb.hwnd, "Int"))
            return

        pct := (this._value - this.min) / (this.max - this.min)
        this.track.Value := pct * 100
        
        thumbNewX := this.trackX + (pct * this.trackW) - (this.thumbW / 2)
        this.thumb.Move(thumbNewX)
        this.thumb.Redraw()
        
        if (triggerCallback && this.callback) {
            try {
                ; Attempt to pass the new value to the callback
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
    
    ; Checks if a specific HWND belongs to this active GUI's window tree
    IsHwndTarget(hwnd) {
        ; SAFE CHECK: Using direct Win32 API to see if control is alive
        if (!this.thumb || !DllCall("user32\IsWindow", "Ptr", this.thumb.hwnd, "Int"))
            return false

        topHwnd := DllCall("GetAncestor", "Ptr", this.guiObj.Hwnd, "UInt", 2, "Ptr")
        return (hwnd == topHwnd || DllCall("IsChild", "Ptr", topHwnd, "Ptr", hwnd))
    }

    ; Converts raw screen coordinates to this specific GUI's client space 
    GetLocalMousePos(&mx, &my) {
        pt := Buffer(8)
        DllCall("GetCursorPos", "Ptr", pt)
        DllCall("ScreenToClient", "Ptr", this.guiObj.Hwnd, "Ptr", pt)
        mx := NumGet(pt, 0, "Int")
        my := NumGet(pt, 4, "Int")
    }

    IsMouseOverSlider(mx, my, padding := 15) {
        return (mx >= this.ctrlX - padding 
             && mx <= this.ctrlX + this.ctrlW + padding 
             && my >= this.ctrlY - padding 
             && my <= this.ctrlY + this.ctrlH + padding)
    }

    OnDrag() {
        while GetKeyState("LButton", "P") {
            ; Guard checking during a live drag session via Win32 API
            if (!this.thumb || !DllCall("user32\IsWindow", "Ptr", this.thumb.hwnd, "Int"))
                break

            this.GetLocalMousePos(&mx, &my)
            
            pct := (mx - this.trackX) / this.trackW
            pct := pct < 0 ? 0 : (pct > 1 ? 1 : pct)
            
            newValue := Round(this.min + (pct * (this.max - this.min)))
            if (newValue != this._value) {
                this._value := newValue
                this.UpdatePosition(true)
            }
            Sleep(10) 
        }
    }

    HandleLButtonDown(wParam, lParam, msg, hwnd) {
        if (this.IsHwndTarget(hwnd)) {
            this.GetLocalMousePos(&mx, &my)
            if (this.IsMouseOverSlider(mx, my, 5)) {
                pct := (mx - this.trackX) / this.trackW
                pct := pct < 0 ? 0 : (pct > 1 ? 1 : pct)
                this.Value := Round(this.min + (pct * (this.max - this.min)))
                this.OnDrag()
                return 0 
            }
        }
    }

    HandleKeyDown(wParam, lParam, msg, hwnd) {
        if (this.IsHwndTarget(hwnd)) {
            this.GetLocalMousePos(&mx, &my)
            if (this.IsMouseOverSlider(mx, my)) {
                switch wParam {
                    case 37, 40: 
                        this.Value := this._value - 1
                        return 0
                    case 39, 38: 
                        this.Value := this._value + 1
                        return 0
                    case 33:    
                        this.Value := this._value + ((this.max - this.min) // 10)
                        return 0
                    case 34:    
                        this.Value := this._value - ((this.max - this.min) // 10)
                        return 0
                }
            }
        }
    }

    HandleWheelMessage(wParam, lParam, msg, hwnd) {
        if (this.IsHwndTarget(hwnd)) {
            this.GetLocalMousePos(&mx, &my)
            if (this.IsMouseOverSlider(mx, my, 15)) { 
                rotation := (wParam >> 16) & 0xFFFF
                if (rotation > 0x7FFF)
                    rotation -= 0x10000
                step := (this.max - this.min) > 20 ? 2 : 1
                direction := rotation > 0 ? step : -step
                this.Value := this._value + direction
                return 0 
            }
        }
    }

    Value {
        get => this._value
        set {
            val := value < this.min ? this.min : (value > this.max ? this.max : value)
            if (val != this._value) {
                this._value := val
                this.UpdatePosition(true)
            }
        }
    }
}