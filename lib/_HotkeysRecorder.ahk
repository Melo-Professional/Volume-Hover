/************************************************************************
 * @description Lib to record custom hotkeys
 * @author Melo
 * @date 2026/07/20
 * @version 1.3.3 (listening message)
 ***********************************************************************/


/* EXAMPLE

MyGui := Gui()

Hot1 := MyGui.Add("Button", "y+35 w240 h36")
HotkeyManager.BindControl(Hot1, "^!c", RunMyFunc1) ; Bind it!

Global General := {
    KeyUp: "^#F12",
}

Global optKeyUp := SettingsGui.Add("Text", "h32 w240 Center 0x0200 +Border")
HotkeyManager.BindControl(optKeyUp, General.KeyUp, VolUp_ActiveWin)

MyGui.Show()
CleanDestroy(*) {
    MyGui.Destroy()
    try HotkeyRecorder.Cancel()
}


RunMyFunc1(thisHotkey) {
    Run("calc.exe")
}

VolUp_ActiveWin(newHotkey := "", isGuiUpdate := false) {
    if (isGuiUpdate) {
        global General
        General.KeyUp := newHotkey
;        SaveINI()
;        SettingsGUI_EnableDisable()
        return
    }
;    AppVolumeControl.ActiveWindow(5)
}
*/

#Requires AutoHotkey v2.0

class HotkeyManager {
    static BindControl(guiCtrl, defaultHotkey, callbackFunc) {
        guiCtrl.DefineProp("CurrentHotkey", {Value: defaultHotkey})
        guiCtrl.DefineProp("ActionCallback", {Value: callbackFunc})
        
        guiCtrl.Text := "  " . this.FormatLabel(defaultHotkey)
        
        if (defaultHotkey != "") {
            ; Wraps the live hotkey to explicitly trigger with isGuiUpdate = false
            try Hotkey(defaultHotkey, (triggeredKey) => callbackFunc(triggeredKey, false), "On")
        }
        
        guiCtrl.OnEvent("Click", ObjBindMethod(this, "_OnControlClicked"))
    }
    
    static _OnControlClicked(guiCtrl, *) {
        guiCtrl.Text := "`tListening... (ESC to Clear)`t     ⌨"
        HotkeyRecorder.Start(ObjBindMethod(this, "_OnHotkeyCaptured", guiCtrl))
    }
    
    static _OnHotkeyCaptured(guiCtrl, hotkeyStr) {
        oldHotkey := guiCtrl.CurrentHotkey
        callbackFunc := guiCtrl.ActionCallback
        
        if (hotkeyStr == "" || hotkeyStr == "Cancelled") {
            if (oldHotkey != "") {
                try Hotkey(oldHotkey, "Off")
            }
            guiCtrl.CurrentHotkey := ""
            guiCtrl.Text := "  " . this.FormatLabel("")
            
            ; EXPLICITLY TELL the function: This is a GUI Update to CLEAR the hotkey
            callbackFunc.Call("", true)
            return
        }
        
        if (this._RegisterSafely(hotkeyStr, oldHotkey, callbackFunc)) {
            guiCtrl.CurrentHotkey := hotkeyStr
            guiCtrl.Text := "  " . this.FormatLabel(hotkeyStr)
            
            ; EXPLICITLY TELL the function: This is a GUI Update to SAVE the new hotkey
            callbackFunc.Call(hotkeyStr, true)
                
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

            ; Wraps the newly registered hotkey so it also correctly triggers with isGuiUpdate = false
            Hotkey(hotkeyStr, (triggeredKey) => callbackFunc(triggeredKey, false), "On")
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

        if IsSet(MessageManager) {
            MessageManager.Register(0x0201, this._mouseCb)
            MessageManager.Register(0x0204, this._mouseCb)
            MessageManager.Register(0x0207, this._mouseCb)
            MessageManager.Register(0x020A, this._mouseCb)
        } else {
            OnMessage(0x0201, this._mouseCb)
            OnMessage(0x0204, this._mouseCb)
            OnMessage(0x0207, this._mouseCb)
            OnMessage(0x020A, this._mouseCb)
        }
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
            if IsSet(MessageManager) {
                MessageManager.Unregister(0x0201, this._mouseCb)
                MessageManager.Unregister(0x0204, this._mouseCb)
                MessageManager.Unregister(0x0207, this._mouseCb)
                MessageManager.Unregister(0x020A, this._mouseCb)
            } else {
                OnMessage(0x0201, this._mouseCb, 0)
                OnMessage(0x0204, this._mouseCb, 0)
                OnMessage(0x0207, this._mouseCb, 0)
                OnMessage(0x020A, this._mouseCb, 0)
            }
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