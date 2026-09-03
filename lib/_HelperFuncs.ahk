/************************************************************************
 * @description QOL helper functions
 * @author Melo (melo@meloprofessional.com) and Pj
 * @date 2026/09/02
 * @version 1.3.8 (CleanTrayTip)
 ***********************************************************************/


/**
 * @description {@link IsFunctionDefined|_HelperFuncs.ahk}
 * Check if a function is available, returning true | false
 * @param {(String)} [FunctionName]
 * The name of the function to test
 * @returns {(Boolean)}
 * - `1` = The function is available.
 * - `0` = The function is not available.
 * @example <caption>Check if ShowHelpGUI() is available and uses it</caption>
 * if IsFunctionDefined("ShowHelpGUI")
 *     MoreMenu.Add("Help", (*) => %"ShowHelpGUI"%())
 */
IsFunctionDefined(FunctionName) {
        try return HasMethod(%FunctionName%)
        return false
    }


/**
 * @description {@link ReloadClean|_HelperFuncs.ahk}
 * Reload current App with clean environment. Option to send arguments.
 * @param {(String)} [args*]
 * First is the name of the function you and to call after reload, ie: "MyFuntcion"
 * then the n parameters to send do the function, ie: "foo", "bar"
 * @example <caption>Reload current App</caption>  
 * ReloadClean()
 * @example <caption>Reload current App sending 2 arguments</caption>  
 * ReloadClean("showGUI", "foo")
 */
ReloadClean(args*) {
    argString := ""
    for arg in args {
        if IsSet(arg) && arg != "" {
            argString .= ' "' arg '"'
        } else {
            argString .= ' "<unset>"'
        }
    }

    if DllCall("userenv\CreateEnvironmentBlock", "Ptr*", &lpEnv:=0, "Ptr",0, "Int",0) {
        si := Buffer(siSize := A_PtrSize == 8 ? 104 : 68, 0), NumPut("UInt", siSize, si)
        pi := Buffer(A_PtrSize == 8 ? 24 : 16, 0)
        cmd := (A_IsCompiled ? '"' A_ScriptFullPath '" /force' : '"' A_AhkPath '" /force "' A_ScriptFullPath '"') argString

        if DllCall("CreateProcessW", "Ptr",0, "Str",cmd, "Ptr",0, "Ptr",0, "Int",0, "UInt",0x400, "Ptr",lpEnv, "Ptr",0, "Ptr",si, "Ptr",pi)
            ExitApp()
        DllCall("userenv\DestroyEnvironmentBlock", "Ptr", lpEnv)
    }
    Reload()
}


/**
 * @description {@link ReloadWithArgs|_HelperFuncs.ahk}
 * Regular Reload current App with arguments. No Clean environment.
 * You need CheckReloadArgs to handle mutiples arguments.
 * @param {(String)} [args*]
 * First is the name of the function you and to call after reload, ie: "MyFuntcion"
 * then the n parameters to send do the function, ie: "foo", "bar"
 * @example <caption>Reload current App sending 3 arguments</caption>  
 * ReloadWithArgs("showGUI", , "foo")
 */
ReloadWithArgs(args*) {
    argString := ""
    for arg in args {
        if IsSet(arg) && arg != "" {
            argString .= ' "' arg '"'
        } else {
            argString .= ' "<unset>"'
        }
    }

    if A_IsCompiled {
        Run('"' A_ScriptFullPath '" /restart' argString)
    } else {
        Run('"' A_AhkPath '" /restart "' A_ScriptFullPath '"' argString)
    }
    ExitApp()
}


/**
 * @description {@link CheckReloadArgs|_HelperFuncs.ahk}
 * Use this function after loading your code to check if there was arguments to dynamically call functions with parameters.
 * If "signal-update-success" was received at arg[1], does nothing.
 * @example <caption>Check if the App received arguments and call function (arg[1]) with parameters (arg[n]).</caption>  
 * CheckReloadArgs()
 */
CheckReloadArgs() {
	if A_Args.Length && !RegExMatch(A_Args[1], "i)^--signal-update-success=") {
		targetFuncName := A_Args[1]
		try {
			fnParams := A_Args.Clone()
			fnParams.RemoveAt(1)
			for index, param in fnParams {
				if (param = "<unset>") {
					fnParams.Delete(index)
				}
			}
			%targetFuncName%(fnParams*)
		} catch Any as e {
			throw e
		}
	}
}


/**
 * @description {@link DPIScale|_HelperFuncs.ahk}
 * Returns DPI Scaled value
 * @param {(Number)} [value]
 * @returns {(Integer)}
 * Returns the rounded value scaled to current DPI
 * @example <caption>Show a GUI properly scaled.</caption>  
 * MyGui := Gui("AlwaysOnTop", A_ScriptName)
 * MyGui.SetFont("s" DPIScale(10))
 * MyGui.Add("Text", "w" DPIScale(2000), "This is a text")
 * MyGui.Show("w" DPIScale(600) " h" DPIScale(200))
 */
DPIScale(value) {
	return Round(value * (A_ScreenDPI / 96))
}


/**
 * @description {@link MsgBoxCustom|_HelperFuncs.ahk}
 * Displays a Custom Message Box. Useful for keeping your custom icon and better control of your GUIs.
 * @param {(String)} [Text]
 * @param {(String)} [Title]
 * @param {"OKCancel"|"RetryCancel"|"ContinueExit"|"YesNo"|"OK"} [Options]
 * @param {(ValueError)} [err ValueError]
 * @returns {(String)}
 * Returns the button pressed by the user.
 * @example <caption>Show a Message Box with "This is a message" with a OK button.</caption>  
 * MsgBoxCustom("This is a message")
 * @example <caption>Show a Message Box asking "Continue?", a title "Question" with buttons Yes and No.</caption>  
 * answer := MsgBoxCustom("Continue?", "Question", "YesNo")
 * @example <caption>Show a Message Box asking to Reload</caption>
 * if (MsgBoxCustom("Reload?", App.Name, "YesNo") = "Yes")
 *    Reload
 * @example <caption>Use in a ternary</caption>
 * MsgBoxCustom("AccessStatus Denied", , "RetryCancel") = "Cancel" ? ExitApp() : Reload()
 * @example <caption>Catch errors</caption>  
 * try {
 * 	foo()
 * } catch as err {
 *     MsgBoxCustom("This in an error:",,,err)
 * }
*/
MsgBoxCustom(Text := "Message", Title := "Warning", Buttons := "OK", errorValue?) {
    MyGuiTitle := Title
    MyGuiOptions := "-MinimizeBox"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)

    ; Layout Configuration
    FontSize        := 10
    btnGap          := 10
    btnW            := 90
    btnH            := 30
    MyGui.MarginX   := 30
    MyGui.MarginY   := 25
    GuiMinWidth     := 300
    GuiMaxWidth     := 660
    
    static Result := ""
    Result := "" ; Reset to prevent click-bleeding

    MyGui.SetFont("s" FontSize, "Segoe UI")

; 1. Display Caller Link (Debug Mode)
    err := Error()
    if (err.HasProp("Stack") && err.Stack != "" && (IsSet(Debug) ? Debug : false)) {
        lines := StrSplit(err.Stack, "`n")
        if (lines.Length >= 2 && RegExMatch(lines[2], "(.*) \((\d+)\)", &Match)) {
            CallerText := Match[1] "`nline: " Match[2]
            caller := MyGui.AddText("Left", CallerText)
            caller.SetFont("underline")
            
            ; KEEP THIS EVENT INSIDE THE SAFE BLOCK
            caller.OnEvent("Click", (*) => (A_Clipboard := FullReportText, ToolTip("Copied Full Report"), SetTimer(() => ToolTip(), -1000)))
        }
    }

    ; 2. Primary Message Text
    ; Specifying a width constraint allows AHK to calculate text wrapping heights perfectly
    txtCtrl := MyGui.AddText("Left w" (GuiMinWidth - 60), Text)

    ; 3. System Error Block (Using an Edit Control to prevent clipping)
; Create a master report variable starting with the main display text
    FullReportText := Text "`n`n"

    ; 3. System Error Block
    if IsSet(errorValue) {
        errorValueText := "--- SYSTEM ERROR DETAILS ---`n"
        try errorValueText .= "Type: " Type(errorValue) "`n"
        try errorValueText .= "Message: " errorValue.Message "`n"
        try errorValueText .= "File: " errorValue.File "`n"
        try errorValueText .= "Line: " errorValue.Line "`n"
        if (errorValue.Extra != "")
            try errorValueText .= "Extra: " errorValue.Extra "`n"
        
        if errorValue.HasProp("Stack") && errorValue.Stack != "" {
            errorValueText .= "`n--- STACK TRACE ---`n" errorValue.Stack "`n"
        }

        ; Append the detailed error text to our master report
        FullReportText .= errorValueText

        LineCount := StrSplit(errorValueText, "`n").Length
        EditHeight := Min(Max(LineCount * 20, 100), 350)

        GotError := MyGui.AddEdit("Left r" LineCount " w" (GuiMaxWidth - 60) " ReadOnly -E0x200 -WantReturn", errorValueText)
        GotError.Move(,, GuiMinWidth - 60, EditHeight)
        
        ; Copies ALL messages combined to the clipboard
        GotError.OnEvent("Focus", (*) => (A_Clipboard := FullReportText, ToolTip("Copied Full Report"), SetTimer(() => ToolTip(), -1000)))
    }

    ; Parse Buttons
ButtonsStrings := (InStr(Buttons, "ReloadExitContinue")) ? ["&Reload", "&Exit", "&Continue"] :
                      (InStr(Buttons, "OKCancel"))           ? ["&OK", "&Cancel"] :
                      (InStr(Buttons, "RetryCancel"))        ? ["&Retry", "&Cancel"] :
                      (InStr(Buttons, "ContinueExit"))       ? ["&Continue", "&Exit"] :
                      (InStr(Buttons, "YesNo"))              ? ["&Yes", "&No"] : ["&OK"]

    BtnObjects := []
    for index, btnName in ButtonsStrings {
        xPos := (index = 1) ? "xm" : "x+" btnGap
        btn := MyGui.AddButton("w" btnW " h" btnH " " xPos, btnName)
        btn.OnEvent("Click", (GuiBtn, *) => (Result := StrReplace(GuiBtn.Text, "&"), CleanDestroy()))
        if (index = 1)
            btn.Opt("+Default")
        BtnObjects.Push(btn)
    }

    if IsFunctionDefined("ApplyThemeToGui") {
        %"ApplyThemeToGui"%(MyGui)
        %"WatchedGUIs"%.Push(MyGui)
    }
    
    ; 4. Dynamic Window Size Calculation
    MyGui.Show("Hide") 
    MyGui.GetClientPos(,, &guiW, &guiH)
    
    ; Adjust final container geometry safely
    finalW := Max(guiW + MyGui.MarginX, GuiMinWidth)
    finalH := guiH + MyGui.MarginY + btnH

    ; Adjust Text fields to the actual clean width
    txtCtrl.Move(,, finalW - (MyGui.MarginX * 2), )
    txtCtrl.Opt("+Redraw")
    if IsSet(GotError)
        GotError.Move(,, finalW - (MyGui.MarginX * 2))

    ; 5. Align and Position Buttons nicely at the footer
    totalBtnW := (BtnObjects.Length * btnW) + ((ButtonsStrings.Length - 1) * btnGap)
    startX := finalW - totalBtnW - MyGui.MarginX ; Default to Right-aligned

    if (BtnObjects.Length = 1)
        startX := (finalW - totalBtnW) / 2      ; Center single buttons

    for index, btnObj in BtnObjects {
        newX := startX + ((index - 1) * (btnW + btnGap))
        newY := finalH - MyGui.MarginY - btnH
        btnObj.Move(newX, newY)
    }

   MyGui.OnEvent("Close", CleanDestroy)
   MyGui.OnEvent("Escape", CleanDestroy)

    ; FORCE FOCUS ON THE FIRST BUTTON (stops the Edit control from auto-selecting)
    if (BtnObjects.Length > 0) {
        BtnObjects[1].Focus()
    }
    
    MyGui.Show("w" finalW " h" finalH " Center")
    
    WinWaitClose(MyGui)
    return Result

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }

   CleanDestroy(*) {
    if IsFunctionDefined("RemoveGuiFromArray")
        %"RemoveGuiFromArray"%(MyGui)

    MyGui.Destroy()
    }
}

/**
 * @description {@link OnError|_HelperFuncs.ahk}
 * Handle errors calling OnErrorCustom and then MsgBoxCustom.
 * This is auto activated.
 */
OnError(OnErrorCustom)


/**
 * @description {@link OnErrorCustom|_HelperFuncs.ahk}
 * Handle errors calling MsgBoxCustom.
 */
OnErrorCustom(Exception, Mode) {
    ErrorType := Type(Exception)
    
    DynamicText := "An unhandled " ErrorType " occurred!`n`n"
    DynamicText .= "What happened: " Exception.Message "`n"
    if (Exception.Extra) {
        DynamicText .= "Specifically: " Exception.Extra "`n"
    }
    DynamicText .= "`nExecution Mode: " (Mode == "Exit" ? "The thread will exit." : "The thread will continue.")
    
    ; PASS THE NEW THREE-BUTTON COMBO HERE
    Result := MsgBoxCustom(DynamicText, ErrorType, "ReloadExitContinue", Exception)
    
    ; HANDLE THE USER'S CHOICES
    if (Result == "Reload") {
        Reload()
    } else if (Result == "Exit") {
        ExitApp()
    }    
    return 1 ; Suppress standard AHK error window
}

/**
 * @description {@link SoudPlayWin|_HelperFuncs.ahk}
 * Play Windows Sound or audio file.
 * @param {(String)} [audiofile]
 * Either a windows sound ie: "Windows Default"
 * either a file path ie: A_ScriptDir "\assets\audios\off_260702.wav"
 * @param {(Integer)} [timer]
 * For how long milliseconds to wait to stop playing (defaults to 5000)
 * @example <caption>Plays default Windows notification</caption>
 * SoundPlayWin("Windows Notify")
 * @example <caption>Plays an audio file.</caption>
 * SoundPlayWin(A_ScriptDir "\assets\audios\on_260702.wav")
 * @example <caption>Plays a long length audio</caption>
 * SoundPlayWin(A_ScriptDir "\assets\audios\longaudio.wav", 0)
 */
SoundPlayWin(audiofile := "Windows Notify", timer := 5000) {
    ; If relative/short name passed, resolve to standard Windows Media path
    if !InStr(audiofile, "\")
        audiofile := A_WinDir "\Media\" audiofile ".wav"

    ; SND_FILENAME (0x20000) | SND_ASYNC (0x1) | SND_NODEFAULT (0x2) = 0x20003
    ; Plays sound in background and avoids error beeps if file is missing
    try DllCall("Winmm.dll\PlaySoundW", "Str", audiofile, "Ptr", 0, "UInt", 0x20003)

    ; Schedule file release if timer is provided
    if (timer > 0)
        SetTimer(ReleaseFile, -timer)

    ReleaseFile() {
        ; Passing 0 as the path cleanly stops playback and releases file handles
        try DllCall("Winmm.dll\PlaySoundW", "Ptr", 0, "Ptr", 0, "UInt", 0x0)
    }
}

/**
 * @description {@link OnFocusGain|_HelperFuncs.ahk}
 * Triggers a callback when a target window transitions from INACTIVE to ACTIVE.
 * @param {String} WinTitle
 * The window title or criteria (e.g., "ahk_class Shell_TrayWnd", "ahk_exe notepad.exe").
 * @param {Func} Callback
 * The function to execute when focus is gained. Receives the gained window's HWND as its first parameter.
 * @returns {Void}
 * @example <caption>Trigger an action when Notepad gains focus</caption>
 * OnFocusGain("ahk_exe notepad.exe", NotepadGainedFocus)
 * 
 * NotepadGainedFocus(hwnd) {
 *     SoundBeep(750, 100)
 * }
 */
Class OnFocusGain {
    static Callbacks := Map()

    static __New() {
        Persistent()
        
        DllCall("user32\SetWinEventHook",
            "UInt", 0x0003, ; EVENT_SYSTEM_FOREGROUND
            "UInt", 0x0003,
            "Ptr", 0,
            "Ptr", CallbackCreate(this.OnFocusChanged.Bind(this), "F"),
            "UInt", 0,
            "UInt", 0,
            "UInt", 0)
    }

    ; Register a WinTitle and its corresponding callback function
    static Call(WinTitle, Callback) {
        this.Callbacks[WinTitle] := Callback
    }

    static OnFocusChanged(*) {
        CurrentActive := WinExist("A")
        if (!CurrentActive)
            return

        ; Check if the CURRENT active window matches any registered target
        for WinTitle, Callback in this.Callbacks {
            if WinExist(WinTitle " ahk_id " CurrentActive) {
                try Callback.Call(CurrentActive)
            }
        }
    }
}

/**
 * @description {@link OnFocusLoss|_HelperFuncs.ahk}
 * Triggers a callback when a target window transitions from ACTIVE to INACTIVE.
 * @param {String} WinTitle
 * The window title or criteria (e.g., "ahk_class Shell_TrayWnd", "ahk_exe notepad.exe").
 * @param {Func} Callback
 * The function to execute when focus is lost. Receives the lost window's HWND as its first parameter.
 * @returns {Void}
 * @example <caption>Trigger an action when the Windows Taskbar loses focus</caption>
 * OnFocusLoss("ahk_class Shell_TrayWnd", TaskbarLostFocus)
 * 
 * TaskbarLostFocus(hwnd) {
 *     ToolTip("Taskbar lost focus! HWND: " hwnd)
 *     SetTimer(() => ToolTip(), -2000)
 * }
 */
Class OnFocusLoss {
    static Callbacks := Map()
    static PrevActive := 0

    static __New() {
        this.PrevActive := WinExist("A")
        Persistent()
        
        DllCall("user32\SetWinEventHook",
            "UInt", 0x0003, ; EVENT_SYSTEM_FOREGROUND
            "UInt", 0x0003,
            "Ptr", 0,
            "Ptr", CallbackCreate(this.OnFocusChanged.Bind(this), "F"),
            "UInt", 0,
            "UInt", 0,
            "UInt", 0)
    }

    ; Register a WinTitle and its corresponding callback function
    static Call(WinTitle, Callback) {
        this.Callbacks[WinTitle] := Callback
    }

    static OnFocusChanged(*) {
        CurrentActive := WinExist("A")
        if (this.PrevActive = CurrentActive)
            return

        ; Check if the PREVIOUS active window matched any registered target
        for WinTitle, Callback in this.Callbacks {
            if (this.PrevActive && WinExist(WinTitle " ahk_id " this.PrevActive)) {
                try Callback.Call(this.PrevActive)
            }
        }

        this.PrevActive := CurrentActive
    }
}

/**
* @description {@link _Debug|_HelperFuncs.ahk}
* Inspects variable state and caller stack details, outputting results via ToolTip, file logging, or debug console.
* *Requires a Debug variable set to true.
* @param {Any} [val="[CHECKPOINT]"]
* The value, variable, array, or map to inspect.
* @param {String} [mode="ToolTip"]
* Output mode: "ToolTip", "Log", "Both", or "OutputDebug".
* @param {Integer} [duration=3000]
* Duration in milliseconds for the ToolTip to display before auto-closing.
* @returns {Any}
* Returns the input val unchanged to allow inline debugging within expressions.
* @example Log an object state and display a temporary ToolTip
* myData := Map("user", "Admin", "active", true)
* _Debug(myData, "Both", 5000)
* @example Both log to file and display a 5-second ToolTip
* _Debug("Critical section completed", "Both", 5000)
* @example Log an object to file
* myMap := Map("status", 200, "user", "Admin")
* _Debug(myMap, "Log")
* ; Inline usage example:
* result := _Debug(CalculateTotal(10, 20))
*/
_Debug(val := "[CHECKPOINT]", mode := "ToolTip", duration := 6000) {
	if !IsSet(Debug) || !Debug
		return

    ; 1. Inspect caller stack frame (-1 gets caller details)
    caller := Error("", -1)
    
    ; Extract caller details safely
    file := caller.File ? RegExReplace(caller.File, "^.*\\") : "Main Script"
    line := caller.Line ? caller.Line : "Unknown"
    fn   := caller.What ? caller.What : "Global Scope"
    
    ; 2. Format payload string (Handles Objects/Arrays/Maps gracefully)
    formattedVal := _Stringify(val)
    timestamp    := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    logLine      := Format("[{1}] [{2}:{3} -> {4}()]: {5}", timestamp, file, line, fn, formattedVal)
    
    ; 3. Output Handlers
    if (mode = "Log" || mode = "Both") {
        try FileAppend(logLine "`n", ".debug_log.txt", "UTF-8")
    }
    
    if (mode = "ToolTip" || mode = "Both") {
        static tipID := 2
        currentID := tipID
        
        ; Display ToolTip at mouse cursor position
        MouseGetPos(&x, &y)
        ToolTip(Format("LINE {1} ({2}):`n{3}", line, fn, formattedVal), x + 15, y + 15, currentID)
        
        ; Clear tooltip automatically after specified duration
        SetTimer () => ToolTip(,,, currentID), -Abs(duration)
        
        ; Rotate IDs between 1 and 20 to allow multiple floating tips simultaneously
        tipID := (tipID >= 20) ? 2 : tipID + 1
    }
    
    if (mode = "OutputDebug") {
        OutputDebug(logLine "`n")
    }
    
    return val

	_Stringify(obj) {
		if !IsObject(obj)
			return String(obj)
		
		str := ""
		if obj is Array {
			for idx, item in obj
				str .= (A_Index > 1 ? ", " : "") . _Stringify(item)
			return "[" str "]"
		} else if obj is Map {
			for k, v in obj
				str .= (A_Index > 1 ? ", " : "") . k ": " . _Stringify(v)
			return "Map(" str ")"
		}
		return Object.Prototype.ToString.Call(obj)
	}
}



/**
 * @description {@link GuiAtTray|_HelperFuncs.ahk}
 * Returns physical coordinates X and Y at 
 * A: app icon at system tray + 8 pixels gap
 * B: the center of system tray + 8 pixels gap
 * Useful for positioning a gui at tray
 * @param GuiObj
 * The GUI to calculate position
 * @param TrayIconHandlerObj
 * Optional a IconTrayHandlerObject to get precise hovering coordinates
 * @param spawnX
 * The X coordinate
 * @param spawnY
 * The Y coordinate
 * @param w
 * The width of the GUI
 * @param h
 * The Heights of the GUI
 * @example <caption> Sends a GUI, a icon tray handler and Gets current tray position and returns x and y to show a GUI. Then show the GUI with physical coordinates.</caption>
 * GuiAtTray(MyGui, TrayHandler, &spawnX, &spawnY, &w, &h)
 * DllCall("User32\SetWindowPos", "Ptr", MyGui.Hwnd, "Ptr", -1, "Int", spawnX, "Int", spawnY, "Int", w, "Int", h, "UInt", 0x0050)
 */
GuiAtTray(GuiObj, TrayIconHandlerObj, &spawnX, &spawnY, &w, &h) {
    if !WinExist(GuiObj.Hwnd)
        return

    scaleFactor := A_ScreenDPI / 96

    ; WinGetPos retrieves exact physical pixel dimensions directly from the window handle
    WinGetPos(, , &w, &h, GuiObj.Hwnd)

    tbHwnd := WinExist("ahk_class Shell_TrayWnd")
    if tbHwnd {
        WinGetPos(&tbX, &tbY, &tbW, &tbH, tbHwnd)
    } else {
        tbX := 0, tbY := A_ScreenHeight - Floor(48 * scaleFactor), tbW := A_ScreenWidth, tbH := Floor(48 * scaleFactor)
    }

    ; Locate Tray Control inside Shell_TrayWnd
    trayNotifyHwnd := 0
    try trayNotifyHwnd := ControlGetHwnd("TrayNotifyWnd1", "ahk_class Shell_TrayWnd")

    if (trayNotifyHwnd) {
        WinGetPos(&tnX, &tnY, &tnW, &tnH, trayNotifyHwnd)
        trayCenterX := tnX + (tnW // 2)
        trayCenterY := tnY + (tnH // 2)
    } else {
        if (tbW > tbH) {
            trayCenterX := tbX + tbW - Floor(80 * scaleFactor)
            trayCenterY := tbY + (tbH // 2)
        } else {
            trayCenterX := tbX + (tbW // 2)
            trayCenterY := tbY + tbH - Floor(80 * scaleFactor)
        }
    }

    monIndex := MonitorGetFromPoint(trayCenterX, trayCenterY)
    MonitorGet(monIndex, &mL, &mT, &mR, &mB)

    MonitorGetFromPoint(X, Y) {
        Loop MonitorGetCount() {
            MonitorGet(A_Index, &Left, &Top, &Right, &Bottom)
            if (X >= Left && X <= Right && Y >= Top && Y <= Bottom)
                return A_Index
        }
        return MonitorGetPrimary()
    }

    distTop    := Abs(trayCenterY - mT)
    distBottom := Abs(trayCenterY - mB)
    distLeft   := Abs(trayCenterX - mL)
    distRight  := Abs(trayCenterX - mR)
    minDist    := Min(distTop, distBottom, distLeft, distRight)

    offsetGap := Floor(8 * scaleFactor)
    useTrayHandler := IsObject(TrayIconHandlerObj) && TrayIconHandlerObj.HasOwnProp("TrayMouseX") && TrayIconHandlerObj.TrayMouseX != 0

    if (minDist == distTop) {
        spawnX := useTrayHandler ? TrayIconHandlerObj.TrayMouseX - (w // 2) : trayCenterX - (w // 2)
        spawnY := useTrayHandler ? Max(TrayIconHandlerObj.TrayMouseY, tbY + tbH) + offsetGap : tbY + tbH + offsetGap
    } else if (minDist == distBottom) {
        spawnX := useTrayHandler ? TrayIconHandlerObj.TrayMouseX - (w // 2) : trayCenterX - (w // 2)
        spawnY := useTrayHandler ? Min(TrayIconHandlerObj.TrayMouseY, tbY) - h - offsetGap : tbY - h - offsetGap
    } else if (minDist == distLeft) {
        spawnX := useTrayHandler ? Max(TrayIconHandlerObj.TrayMouseX, tbX + tbW) + offsetGap : tbX + tbW + offsetGap
        spawnY := useTrayHandler ? TrayIconHandlerObj.TrayMouseY - (h // 2) : trayCenterY - (h // 2)
    } else {
        spawnX := useTrayHandler ? Min(TrayIconHandlerObj.TrayMouseX, tbX) - w - offsetGap : tbX - w - offsetGap
        spawnY := useTrayHandler ? TrayIconHandlerObj.TrayMouseY - (h // 2) : trayCenterY - (h // 2)
    }

    pad := Floor(8 * scaleFactor)
    if (spawnY < mT + pad)
        spawnY := mT + pad
    if (spawnY + h > mB - pad)
        spawnY := mB - pad - h
    if (spawnX < mL + pad)
        spawnX := mL + pad
    if (spawnX + w > mR - pad)
        spawnX := mR - pad - w
}


/**
 * @description {@link GuiAtTray|_HelperFuncs.ahk}
 * Parse an object into strings to easy visualization of data
 * @param obj 
 * The Object to parse
 * @returns {String} 
 * String to print as tooltip or msgbox or whatever
 * @example <caption> Shows a msgbox with the content of an object from method</caption>
 * msgbox(ObjToString(TrayHandler.GetTaskbarPosition()))
 */
ObjToString(obj) {
    str := ""
    for prop, val in obj.OwnProps()
        str .= prop ": " val "`n"
    return RTrim(str, "`n")
}

/**
 * @description {@link EnableAutoScroll|_HelperFuncs.ahk}
 * Dynamically enables mouse wheel vertical scrolling for a GUI without native scrollbars when content exceeds visible bounds.
 * Retains pinned controls (.noScroll := true), prevents High-DPI position drift, and cleanups message hooks on close/destroy.
 * @param {Gui} guiObj 
 * The AutoHotkey GUI object instance to apply auto-scrolling to
 * @param {Integer} [scrollSpeed=50] 
 * Pixel distance moved per mouse wheel notch click
 * @param {Float} [maxScreenRatio=1.0] 
 * Maximum allowable screen height ratio before constraining the GUI size
 * @returns {Void}
 * @example <caption>Enable auto-scrolling on a GUI post-show while keeping title bar pinned</caption>
 * CustomTitleBar.Attach(myGui)
 * myGui.Show("xCenter yCenter h300")
 * EnableAutoScroll(myGui, 40)
 */
EnableAutoVerticalScroll(guiObj, scrollSpeed := 50, maxScreenRatio := 1.0) {
    guiObj.GetPos(, , , &winH)
    guiObj.GetClientPos(, , , &clientH)

    controls := []
    contentHeight := 0
    for ctrl in guiObj {
        ctrl.GetPos(&x, &y, , &h)
        
        if (y + h > contentHeight)
            contentHeight := y + h
            
        if (HasProp(ctrl, "noScroll") && ctrl.noScroll)
            continue
            
        controls.Push({ ctrl: ctrl, origX: x, origY: y })
    }
    contentHeight += 20

    MonitorGetWorkArea(1, , , , &workAreaBottom)
    maxAllowedHeight := Integer(workAreaBottom * maxScreenRatio)

    if (winH > maxAllowedHeight) {
        guiObj.Move(, , , maxAllowedHeight)
        guiObj.GetClientPos(, , , &clientH)
    }

    maxScroll := contentHeight - clientH
    if (maxScroll <= 0)
        return

    currentScroll := 0

    ; Centralized Cleanup Helper
    CleanClose(*) {
        if IsSet(MessageManager) {
            MessageManager.Unregister(0x020A, OnMouseWheel)
            MessageManager.Unregister(0x0082, OnNCDestroy)
        } else {
            OnMessage(0x020A, OnMouseWheel, 0)
            OnMessage(0x0082, OnNCDestroy, 0)
        }
    }

    OnMouseWheel(wParam, lParam, msg, hwnd) {
        try {
            guiHwnd := guiObj.Hwnd
        } catch {
            CleanClose()
            return
        }

        if (hwnd != guiHwnd && !DllCall("IsChild", "Ptr", guiHwnd, "Ptr", hwnd))
            return

        delta := (wParam >> 16) & 0xFFFF
        direction := (delta & 0x8000) ? 1 : -1
        
        newScroll := Min(maxScroll, Max(0, currentScroll + (direction * scrollSpeed)))

        if (newScroll != currentScroll) {
            currentScroll := newScroll
            
            DllCall("SendMessage", "Ptr", guiHwnd, "UInt", 0x000B, "Ptr", 0, "Ptr", 0)
            
            for item in controls {
                item.ctrl.Move(item.origX, item.origY - currentScroll)
            }
            
            DllCall("SendMessage", "Ptr", guiHwnd, "UInt", 0x000B, "Ptr", 1, "Ptr", 0)
            WinRedraw(guiObj)
        }
    }

    OnNCDestroy(wParam, lParam, msg, hwnd) {
        try {
            if (hwnd == guiObj.Hwnd)
                CleanClose()
        } catch {
            CleanClose()
        }
    }

    ; Bind events & message hooks
    guiObj.OnEvent("Close", (*) => CleanClose())

    if IsSet(MessageManager) {
        MessageManager.Register(0x0082, OnNCDestroy)
        MessageManager.Register(0x020A, OnMouseWheel)
    } else {
        OnMessage(0x0082, OnNCDestroy)
        OnMessage(0x020A, OnMouseWheel)
    }
}

/**
 * @description {@link ApplyHDRFontQuality|_HelperFuncs.ahk}
 * Applies Standard/Monochrome quality (Quality 3) for texts instead of ClearType
 * if HDR is enabled
 * @param {GuiObj} [myGui]
 * The GUI to apply q3
* @returns {Void}
 */
ApplyHDRFontQuality(myGui) {
;    if !IsHDREnabled()
;        return
	if !(IsSet(General) && General.HasOwnProp("HDR") && (General.HDR == 1)) {
		return
	}

    for hwnd, ctrl in myGui {
        try {
            ctrl.SetFont("q3")
        }
    }
}
