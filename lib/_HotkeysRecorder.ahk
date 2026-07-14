/************************************************************************
 * @description Lib to record custom hotkeys
 * @author Melo
 * @date 2026/07/12
 * @version 1.1.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

/* EXAMPLE

MyGui := Gui()

Hot1 := MyGui.Add("Button", "y+35 w220 h36")
HotkeyManager.BindControl(Hot1, "^!c", RunMyFunc1) ; Bind it!

Hot2 := MyGui.Add("Text", "y+35 w220 h36")
HotkeyManager.BindControl(Hot2, "^+WheelDown", RunMyFunc2) ; Bind it!

MyGui.Show()

RunMyFunc1(thisHotkey) {
    Run("calc.exe")
}

RunMyFunc2(thisHotkey) {
    ToolTip("System Active! (Triggered via " . thisHotkey . ")")
    SetTimer((*) => ToolTip(), -1500)
}

*/
class HotkeyManager {
    /**
     * Binds a GUI Text control to act as an automatic Hotkey Input box.
     * @param {Gui.Control} guiCtrl - The Text control object to modify.
     * @param {String} defaultHotkey - The starting hotkey (e.g. "^!2" or "").
     * @param {Func} callbackFunc - The function to trigger when the hotkey is pressed.
     */
    static BindControl(guiCtrl, defaultHotkey, callbackFunc) {
        ; guiCtrl.Opt("+Border BackgroundFFFFFF 0x200")
        
        guiCtrl.DefineProp("CurrentHotkey", {Value: defaultHotkey})
        guiCtrl.DefineProp("ActionCallback", {Value: callbackFunc})
        
        guiCtrl.Text := "  " . this.FormatLabel(defaultHotkey)
        
        if (defaultHotkey != "") {
            try Hotkey(defaultHotkey, callbackFunc, "On")
        }
        
        guiCtrl.OnEvent("Click", ObjBindMethod(this, "_OnControlClicked"))
    }
    
    static _OnControlClicked(guiCtrl, *) {
        guiCtrl.Text := "Listening... (ESC to cancel)"
        HotkeyRecorder.Start(ObjBindMethod(this, "_OnHotkeyCaptured", guiCtrl))
    }
    
    static _OnHotkeyCaptured(guiCtrl, hotkeyStr) {
        oldHotkey := guiCtrl.CurrentHotkey
        callbackFunc := guiCtrl.ActionCallback
        
        ; FIX: Treat both explicit Escape ("") and aborted recordings ("Cancelled") as a CLEAR operation.
        if (hotkeyStr == "" || hotkeyStr == "Cancelled") {
            if (oldHotkey != "") {
                try Hotkey(oldHotkey, "Off")
            }
            guiCtrl.CurrentHotkey := ""
            guiCtrl.Text := "  " . this.FormatLabel("")
            
            ; This calls your Action_KeyUp("") function to wipe it out from the INI file
            callbackFunc("")
            return
        }
        
        if (this._RegisterSafely(hotkeyStr, oldHotkey, callbackFunc)) {
            guiCtrl.CurrentHotkey := hotkeyStr
            guiCtrl.Text := "  " . this.FormatLabel(hotkeyStr)
            
            ; Call the callback function with the newly recorded string to save it to the INI
            callbackFunc(hotkeyStr)
                
        } else {
            MsgBox("Failed to bind hotkey: " . this.FormatLabel(hotkeyStr), "Registration Error", "Icon!")
            guiCtrl.Text := "  " . this.FormatLabel(oldHotkey)
        }
    }
    
    static FormatLabel(hotkeyStr) {
        if (hotkeyStr == "" || hotkeyStr == "Cancelled") {
            return "None"
        }
            
        parts := []
        
        for _, char in StrSplit(hotkeyStr) {
            if (char == "^")
                parts.Push("CONTROL")
            if (char == "+")
                parts.Push("SHIFT")
            if (char == "!")
                parts.Push("ALT")
            if (char == "#")
                parts.Push("WIN")
        }
        
        baseKey := RegExReplace(hotkeyStr, "[\^!\+#]")
        if (baseKey != "") {
            parts.Push(String(StrUpper(baseKey)))
        }
        
        formattedString := ""
        for index, value in parts {
            formattedString .= (index == 1 ? "" : " + ") . value
        }
        return formattedString
    }
    
    static _RegisterSafely(hotkeyStr, oldHotkey, callbackFunc) {
        if (oldHotkey != "") {
            try Hotkey(oldHotkey, "Off")
        }
            
        try {
            for _, char in StrSplit(hotkeyStr) {
                if (char == "^")
                    KeyWait("Ctrl")
                if (char == "!")
                    KeyWait("Alt")
                if (char == "+")
                    KeyWait("Shift")
                if (char == "#") {
                    KeyWait("LWin")
                    KeyWait("RWin")
                }
            }
            
            baseKey := RegExReplace(hotkeyStr, "[\^!\+#]")
            if !InStr(baseKey, "Wheel") {
                KeyWait(baseKey)
            }

            Hotkey(hotkeyStr, callbackFunc, "On")
            return true
        } catch {
            return false
        }
    }
}

; --- Core Low-Level Input Interception Engine ---
class HotkeyRecorder {
    static IsRecording := false
    static CurrentCallback := ""
    static InputLogger := ""
    static _mouseCb := ""
    
    static Start(callback) {
        if (this.IsRecording) {
            this.Cancel()
        }
            
        this.IsRecording := true
        this.CurrentCallback := callback
        
        this.InputLogger := InputHook("L0 I1")
        this.InputLogger.KeyOpt("{All}", "+N +S")
        this.InputLogger.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-S")
        this.InputLogger.OnKeyDown := ObjBindMethod(this, "_OnKeyDown")
        this.InputLogger.Start()
        
        this._mouseCb := ObjBindMethod(this, "_OnMouseEvents")
        OnMessage(0x0201, this._mouseCb)
        OnMessage(0x0204, this._mouseCb)
        OnMessage(0x0207, this._mouseCb)
        OnMessage(0x020A, this._mouseCb)
    }
    
    static Cancel() {
        if (!this.IsRecording) {
            return
        }
        cb := this.CurrentCallback
        this._Cleanup()
        if (cb) {
            cb("Cancelled")
        }
    }
    
    static _Cleanup() {
        this.IsRecording := false
        if (GetKeyState("LWin") || GetKeyState("RWin")) {
            Send("{Blind}{Ctrl}")
        }
        if (this.InputLogger) {
            this.InputLogger.Stop()
        }
        if (this._mouseCb) {
            OnMessage(0x0201, this._mouseCb, 0)
            OnMessage(0x0204, this._mouseCb, 0)
            OnMessage(0x0207, this._mouseCb, 0)
            OnMessage(0x020A, this._mouseCb, 0)
            this._mouseCb := ""
        }
    }
    
    static _OnKeyDown(ih, vk, sc) {
        if (vk == 0x1B) { 
            cb := this.CurrentCallback
            this._Cleanup()
            if (cb) {
                cb("") 
            }
            return
        }
        
        keyName := GetKeyName(Format("vk{:X}sc{:X}", vk, sc))
        if (InStr(keyName, "Control") || InStr(keyName, "Alt") || InStr(keyName, "Shift") || InStr(keyName, "Win")) {
            return
        }
        
        cb := this.CurrentCallback
        this._Cleanup()
        
        modifiers := ""
        if (GetKeyState("Ctrl", "P")) {
            modifiers .= "^"
        }
        if (GetKeyState("Alt", "P")) {
            modifiers .= "!"
        }
        if (GetKeyState("Shift", "P")) {
            modifiers .= "+"
        }
        if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P")) {
            modifiers .= "#"
        }
            
        if (cb) {
            cb(modifiers . keyName)
        }
    }
    
    static _OnMouseEvents(wParam, lParam, msg, hwnd) {
        mouseKey := ""
        if (msg == 0x0201) {
            mouseKey := "LButton"
        } else if (msg == 0x0204) {
            mouseKey := "RButton"
        } else if (msg == 0x0207) {
            mouseKey := "MButton"
        } else if (msg == 0x020A) {
            wrappedDelta := (wParam >> 16) & 0xFFFF
            mouseKey := (wrappedDelta & 0x8000) ? "WheelDown" : "WheelUp"
        }
        
        modifiers := ""
        if (wParam & 0x0008) {
            modifiers .= "^"
        }
        if (wParam & 0x0004) {
            modifiers .= "+"
        }
        if (GetKeyState("Alt", "P")) {
            modifiers .= "!"
        }
        if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P")) {
            modifiers .= "#"
        }
        
        if (mouseKey == "LButton" && modifiers == "") {
            return true
        }
            
        cb := this.CurrentCallback
        this._Cleanup()
        if (cb) {
            cb(modifiers . mouseKey)
        }
        return true 
    }
}