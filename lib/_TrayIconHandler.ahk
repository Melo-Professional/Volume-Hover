/************************************************************************
 * @description Handles tray icon events
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/15
 * @version 1.2.1 (hover triggers while moving)
 ***********************************************************************/

#Requires AutoHotkey v2.0

/*
; *************************************************************
### Summary of Usable Features in `TrayIconHandler`

| **Mouse Coordinates** | 
trayObj.TrayMouseX
trayObj.TrayMouseY
Screen X/Y coordinates recorded when hovering over the tray icon.


| **Taskbar Orientation** |
trayObj.GetTaskbarPosition()
Returns an object containing `{ Pos, Monitor, X, Y, BoundingX, BoundingY }`. `Pos` can be `"Top"`, `"Bottom"`, `"Left"`, or `"Right"`.


| **Hover State** |
trayObj.IsHovering
Boolean `true` or `false` indicating whether the cursor is currently over the icon.


| **Scroll Detection** |
OnWheelUp
OnWheelDown
Fires specifically when scrolling while hovering over the icon.


| **Click Disambiguation** |
OnLeftClick
OnDoubleClick
OnRightClick
OnRightDoubleClick
Separates single clicks from double clicks cleanly using system double-click speed timing.

*/


class TrayIconHandler {
    ; --- User-Defined Callbacks ---
    OnLeftClick := ""
    OnDoubleClick := ""
    OnRightClick := ""
    OnRightDoubleClick := ""
    OnHover := ""
    OnLeave := ""
    OnWheelUp := ""
    OnWheelDown := ""

    ; --- Internal State Tracking ---
    HoverDelay := 600
    LeaveDelay := 200  ; Time tolerance (ms) after leaving before triggering OnLeave
	HoverTimerActive := false
    PaddingBase := 2 ; Base padding before DPI scaling
    IsHovering := false
	IsMouseOver := false
    TrayMouseX := 0
    TrayMouseY := 0
    
    ; Pending Leave Delay Timer Tracking
    PendingLeaveTimer := 0
    
    ; Click Debouncing & Double-Click Guard Tracking
    DoubleClickTime := 150
    PendingLeftTimer := 0
    PendingRightTimer := 0
    IgnoreNextLeftUp := false
    IgnoreNextRightUp := false
    
    __New(hoverDelayMs := "", leaveDelayMs := "", doubleClickTimeMs := "") {
        if (hoverDelayMs !== "")
            this.HoverDelay := hoverDelayMs
            
        if (leaveDelayMs !== "")
            this.LeaveDelay := leaveDelayMs

        if (doubleClickTimeMs !== "") {
            this.DoubleClickTime := doubleClickTimeMs
        } else if (this.DoubleClickTime == 0) {
            ; Query system double click speed threshold ONLY if not manually specified
            sysDblTime := DllCall("User32\GetDoubleClickTime", "UInt")
            if (sysDblTime > 0)
                this.DoubleClickTime := sysDblTime
        }

        this.HoverWatchdogObj := this.HoverWatchdog.Bind(this)
        this.LeaveWatchdogObj := this.LeaveWatchdog.Bind(this)

        ; 1. Register Messages via MessageManager if available, fallback to standard OnMessage
        if IsSet(MessageManager) {
            MessageManager.Register(0x404, this.HandleTrayMessage.Bind(this))
        } else {
            OnMessage(0x404, this.HandleTrayMessage.Bind(this))
        }
        
        ; 2. Register Mouse Wheel hotkeys via conditional HotIf context
        this.SetupWheelHotkeys()
    }

; --- Mouse Wheel Registration ---
    SetupWheelHotkeys() {
        HotIf((*) => this.IsMouseOver)
        Hotkey("WheelUp", (*) => this.CallCallback(this.OnWheelUp, this), "On")
        Hotkey("WheelDown", (*) => this.CallCallback(this.OnWheelDown, this), "On")
        HotIf()
    }

    ; --- Safe Method Invoker ---
    CallCallback(callback, params*) {
        if (HasMethod(callback)) {
            try {
                callback(params*)
            } catch Error as err {
                if (InStr(err.Message, "Too many parameters"))
                    callback()
                else
                    throw err
            }
        }
    }

    ; --- Core Tray Message Handler ---
    HandleTrayMessage(wParam, lParam, msg, hwnd) {
        stopMsg := IsSet(MessageManager) ? ["STOP", 0] : 0

        switch lParam {
            case 0x200: ; WM_MOUSEMOVE
                CoordMode("Mouse", "Screen")
                MouseGetPos(&x, &y)

                ; Update coordinates continuously while over icon
                this.TrayMouseX := x
                this.TrayMouseY := y

                ; Instantly mark that mouse is inside icon area for wheel hotkeys
                this.IsMouseOver := true

                ; Start LeaveWatchdog immediately so leaving during HoverDelay is properly detected
                SetTimer(this.LeaveWatchdogObj, 100)

                ; If mouse came back while pending a leave, cancel the leave timer
                if (this.PendingLeaveTimer) {
                    SetTimer(this.PendingLeaveTimer, 0)
                    this.PendingLeaveTimer := 0
                }

                if (!this.IsHovering && !this.HoverTimerActive) {
					this.HoverTimerActive := true
					SetTimer(this.HoverWatchdogObj, -this.HoverDelay)
				}

            ; --- LEFT CLICK / DOUBLE CLICK ---
            case 0x202: ; WM_LBUTTONUP
                this.HandleClick("Left", false)
                return stopMsg
                    
            case 0x203: ; WM_LBUTTONDBLCLK
                this.HandleClick("Left", true)
                return stopMsg

            ; --- RIGHT CLICK / DOUBLE CLICK ---
            case 0x205: ; WM_RBUTTONUP
                this.HandleClick("Right", false)
                return stopMsg

            case 0x206: ; WM_RBUTTONDBLCLK
                this.HandleClick("Right", true)
                return stopMsg
        }
    }

    ; --- Click & Double-Click Debouncer ---
    HandleClick(btn, isExplicitDbl) {
        if (btn == "Left") {
            ; 1. Explicit Double-Click Message (0x203)
            if (isExplicitDbl) {
                if (this.PendingLeftTimer != 0) {
                    SetTimer(this.PendingLeftTimer, 0)
                    this.PendingLeftTimer := 0
                }
                this.IgnoreNextLeftUp := true  ; Block the upcoming 2nd WM_LBUTTONUP message
                this.CallCallback(this.OnDoubleClick, this)
                return
            }

            ; 2. Ignore the 2nd button release that Windows sends during a double-click sequence
            if (this.IgnoreNextLeftUp) {
                this.IgnoreNextLeftUp := false
                return
            }

            ; 3. First button release (WM_LBUTTONUP)
            if (HasMethod(this.OnDoubleClick)) {
                ; Double-click callback exists: delay single-click execution to see if double-click follows
                this.PendingLeftTimer := () => (
                    this.PendingLeftTimer := 0,
                    this.CallCallback(this.OnLeftClick, this)
                )
                SetTimer(this.PendingLeftTimer, -this.DoubleClickTime)
            } else {
                ; No double-click callback registered: fire single click IMMEDIATELY
                this.CallCallback(this.OnLeftClick, this)
            }
        } 
        else if (btn == "Right") {
            if (isExplicitDbl) {
                if (this.PendingRightTimer != 0) {
                    SetTimer(this.PendingRightTimer, 0)
                    this.PendingRightTimer := 0
                }
                this.IgnoreNextRightUp := true
                this.CallCallback(this.OnRightDoubleClick, this)
                return
            }

            if (this.IgnoreNextRightUp) {
                this.IgnoreNextRightUp := false
                return
            }

            if (HasMethod(this.OnRightDoubleClick)) {
                this.PendingRightTimer := () => (
                    this.PendingRightTimer := 0,
                    this.CallCallback(this.OnRightClick, this)
                )
                SetTimer(this.PendingRightTimer, -this.DoubleClickTime)
            } else {
                this.CallCallback(this.OnRightClick, this)
            }
        }
    }

    ; --- Hover & Bounding Box Logic ---
    HoverWatchdog() {
		this.HoverTimerActive := false
        CoordMode("Mouse", "Screen")
        MouseGetPos(&currentX, &currentY)
        
        if (this.IsOutsideTrayBounds(currentX, currentY))
            return 
            
        this.IsHovering := true
        if (this.OnHover)
            this.CallCallback(this.OnHover, this)
    }

    LeaveWatchdog() {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&currentX, &currentY)
        
        if (this.IsOutsideTrayBounds(currentX, currentY)) {
            ; Check if we are already waiting for a pending leave timer
            if (this.PendingLeaveTimer)
                return

            ; Set up tolerance timer
            this.PendingLeaveTimer := () => this.ConfirmLeave()
            SetTimer(this.PendingLeaveTimer, -this.LeaveDelay)
        } else {
            ; If mouse returned inside bounds during watchdog, cancel pending leave
            if (this.PendingLeaveTimer) {
                SetTimer(this.PendingLeaveTimer, 0)
                this.PendingLeaveTimer := 0
            }
        }
    }

	ConfirmLeave() {
		CoordMode("Mouse", "Screen")
		MouseGetPos(&currentX, &currentY)

		if (this.IsOutsideTrayBounds(currentX, currentY)) {
			this.IsHovering := false
			this.IsMouseOver := false
			this.HoverTimerActive := false ; <-- Add this
			
			; Cancel any pending hover timer if mouse left early
			SetTimer(this.HoverWatchdogObj, 0)
			
			SetTimer(this.LeaveWatchdogObj, 0)
			this.PendingLeaveTimer := 0
			
			if (this.OnLeave)
				this.CallCallback(this.OnLeave, this)
		} else {
			this.PendingLeaveTimer := 0
		}
	}

    ; --- DPI & Multi-Monitor Helpers ---
    IsOutsideTrayBounds(x, y) {
        scaleFactor := A_ScreenDPI / 96
        padding := Floor(this.PaddingBase * scaleFactor)
        
        return (Abs(x - this.TrayMouseX) > padding || Abs(y - this.TrayMouseY) > padding)
    }

    GetTaskbarPosition() {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&x, &y)
        
        monitorNum := this.MonitorGetFromPoint(x, y)
        MonitorGetWorkArea(monitorNum, &wl, &wt, &wr, &wb)
        MonitorGet(monitorNum, &ml, &mt, &mr, &mb)
        
        if (wt > mt)
            return { Pos: "Top", Monitor: monitorNum, X: x, Y: y, BoundingY: wt }
        if (wb < mb)
            return { Pos: "Bottom", Monitor: monitorNum, X: x, Y: y, BoundingY: wb }
        if (wl > ml)
            return { Pos: "Left", Monitor: monitorNum, X: x, Y: y, BoundingX: wl }
        if (wr < mr)
            return { Pos: "Right", Monitor: monitorNum, X: x, Y: y, BoundingX: wr }
            
        return { Pos: "Bottom", Monitor: monitorNum, X: x, Y: y, BoundingY: mb }
    }

    MonitorGetFromPoint(X, Y) {
        monitorCount := MonitorGetCount()
        Loop monitorCount {
            MonitorGet(A_Index, &Left, &Top, &Right, &Bottom)
            if (X >= Left && X <= Right && Y >= Top && Y <= Bottom)
                return A_Index
        }
        return MonitorGetPrimary()
    }
}




/* HOW TO USE

; *************************************************************
### Summary of Usable Features in `TrayIconHandler`

| **Mouse Coordinates** | 
trayObj.TrayMouseX
trayObj.TrayMouseY
Screen X/Y coordinates recorded when hovering over the tray icon.


| **Taskbar Orientation** |
trayObj.GetTaskbarPosition()
Returns an object containing `{ Pos, Monitor, X, Y, BoundingX, BoundingY }`. `Pos` can be `"Top"`, `"Bottom"`, `"Left"`, or `"Right"`.


| **Hover State** |
trayObj.IsHovering
Boolean `true` or `false` indicating whether the cursor is currently over the icon.


| **Scroll Detection** |
OnWheelUp
OnWheelDown
Fires specifically when scrolling while hovering over the icon.


| **Click Disambiguation** |
OnLeftClick
OnDoubleClick
OnRightClick
OnRightDoubleClick
Separates single clicks from double clicks cleanly using system double-click speed timing.


; *************************************************************





; Disable standard AHK tray context menu so right/double clicks belong exclusively to your library
A_TrayMenu.ClickCount := 1
A_TrayMenu.Delete()
TrayMenu                := A_TrayMenu
TrayMenu.Add("Exit", (*) => ExitApp())
TrayMenu.Add("Restart", (*) => Reload())
TrayMenu.Add("Explore", (*) => Run('explorer.exe /select,"' . A_ScriptFullPath . '"'))

#Include <_TrayIconHandler>
#Include <_MessageManager>

 */



/* 
;1. Show Custom Context Menu at the Correct Taskbar Position
#Requires AutoHotkey v2.0
#Include Lib\_TrayIconHandler.ahk

MyTray := TrayIconHandler()

MyTray.OnRightClick := ShowMenuAtTray

ShowMenuAtTray(trayObj) {
    ; Get taskbar position info
    tbInfo := trayObj.GetTaskbarPosition()
    
    ; Create a quick sample menu
    AnotherTrayMenu := Menu()
    AnotherTrayMenu.Add("Taskbar Position: " tbInfo.Pos, (*) => "")
    AnotherTrayMenu.Add("Monitor Number: " tbInfo.Monitor, (*) => "")
    AnotherTrayMenu.Add()
    AnotherTrayMenu.Add("Exit App", (*) => ExitApp())
    
    ; Display menu at mouse location
    AnotherTrayMenu.Show()
}
*/

/*
; 2. Display Hover Info Card with DPI-Scaled Coordinates
#Requires AutoHotkey v2.0
#Include Lib\_TrayIconHandler.ahk

MyTray := TrayIconHandler() ; Fast hover (300ms), fast leave (200ms)

MyTray.OnHover := (trayObj) => ToolTip(
    "Mouse X: " trayObj.TrayMouseX "`n" .
    "Mouse Y: " trayObj.TrayMouseY "`n" .
    "DPI Scale: " (A_ScreenDPI / 96) "x"
)

MyTray.OnLeave := (*) => ToolTip() ; Hide ToolTip on exit
*/

/*
;3. Volume / Brightness Control via Mouse Wheel

#Requires AutoHotkey v2.0
#Include Lib\_TrayIconHandler.ahk

MyTray := TrayIconHandler()

MyTray.OnWheelUp := (*) => AdjustVolume("+2")
MyTray.OnWheelDown := (*) => AdjustVolume("-2")

AdjustVolume(change) {
    SoundSetVolume(change)
    currentVol := Round(SoundGetVolume())
    ToolTip("Volume: " currentVol "%")
    SetTimer(() => ToolTip(), -1000) ; Auto-hide tooltip after 1 sec
}
*/


/* 
; 4. Separate Actions for Single Click vs. Double Click
#Requires AutoHotkey v2.0
#Include Lib\_TrayIconHandler.ahk

MyTray := TrayIconHandler()

; Single click toggles mute
MyTray.OnLeftClick := (*) => SoundSetMute(-1)

; Double click opens/restores main app window
MyTray.OnDoubleClick := (*) => ToggleMainWindow()

ToggleMainWindow() {
    static MainGui := 0
    if (!MainGui) {
        MainGui := Gui("+AlwaysOnTop", "My App Window")
        MainGui.Add("Text",, "Hello from the Tray Handler!")
    }
    
    if DllCall("IsWindowVisible", "Ptr", MainGui.Hwnd)
        MainGui.Hide()
    else
        MainGui.Show("w300 h200")
}
 */




/*
; 5. Show a GUI near the mouse click
#Requires AutoHotkey v2.0
#Include Lib\_TrayIconHandler.ahk

A_TrayMenu.ClickCount := 1
MyTray := TrayIconHandler()

MyTray.OnLeftClick := (*) => ToggleTrayGui()

; --- GUI Definition ---
TrayGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
TrayGui.BackColor := "1E1E1E"
TrayGui.SetFont("s10 cWhite", "Segoe UI")
TrayGui.Add("Text", "w200 Center", "Tray Popup GUI")
TrayGui.Add("Button", "w200 h30 y+10", "Close").OnEvent("Click", (*) => TrayGui.Hide())

ToggleTrayGui() {
    static isVisible := false

    if (isVisible) {
        TrayGui.Hide()
        isVisible := false
        return
    }

    guiWidth := 220
    guiHeight := 120
    offsetGap := 12 ; Distance (pixels) away from the click position

    tbInfo := MyTray.GetTaskbarPosition()

    ; Get usable screen work area (prevents GUI from overlapping taskbar or going off-screen)
    MonitorGetWorkArea(tbInfo.Monitor, &workLeft, &workTop, &workRight, &workBottom)

    ; Calculate position based on taskbar location relative to click position
    switch tbInfo.Pos {
        case "Bottom":
            ; Center horizontally on mouse click
            spawnX := Clamp(tbInfo.X - (guiWidth / 2), workLeft + 8, workRight - guiWidth - 8)
            ; Spawn above mouse click location
            spawnY := tbInfo.Y - guiHeight - offsetGap

        case "Top":
            spawnX := Clamp(tbInfo.X - (guiWidth / 2), workLeft + 8, workRight - guiWidth - 8)
            ; Spawn below mouse click location
            spawnY := tbInfo.Y + offsetGap

        case "Right":
            ; Spawn to the left of mouse click location
            spawnX := tbInfo.X - guiWidth - offsetGap
            spawnY := Clamp(tbInfo.Y - (guiHeight / 2), workTop + 8, workBottom - guiHeight - 8)

        case "Left":
            ; Spawn to the right of mouse click location
            spawnX := tbInfo.X + offsetGap
            spawnY := Clamp(tbInfo.Y - (guiHeight / 2), workTop + 8, workBottom - guiHeight - 8)
    }

    ; Final safeguard: ensure spawnY doesn't breach top/bottom screen boundaries
    spawnY := Clamp(spawnY, workTop + 8, workBottom - guiHeight - 8)

    TrayGui.Show("x" . Round(spawnX) . " y" . Round(spawnY) . " w" . guiWidth . " h" . guiHeight)
    isVisible := true
}

Clamp(val, minVal, maxVal) {
    return Max(minVal, Min(val, maxVal))
}
*/


/* 
; 6. General use
MyTray := TrayIconHandler()

; Map your events
MyTray.OnHover       := () => aaaaaaa()
MyTray.OnLeave       := () => bbb()

MyTray.OnLeftClick   := () => leftclickactions()

;MyTray.OnLeftClick   := () => TrayMenu.Show()

MyTray.OnDoubleClick := () => Tooltip("Double click",1400,900)
MyTray.OnRightClick  := () => Tooltip("Right click",1400,900)
MyTray.OnWheelUp     := () => zzzzz(1)
MyTray.OnWheelDown   := () => zzzzz(-1)


leftclickactions() {
	SoundBeep()
	Tooltip("Left click",1400,900)
}
aaaaaaa() {
    ; You can easily ask the class where the taskbar is to position your GUI correctly!
    tbInfo := MyTray.GetTaskbarPosition()
    
    if (tbInfo.Pos == "Bottom") {
        ; Spawn GUI above taskbar
        ;spawnY := tbInfo.BoundingY - MyGuiHeight
        spawnY := tbInfo.BoundingY
    } else if (tbInfo.Pos == "Top") {
        ; Spawn GUI below taskbar
        spawnY := tbInfo.BoundingY
    }
    Tooltip("OnHover()`n " spawnY "`n " tbInfo.Pos,1400,900)
    ; ... show your GUI ...
}

bbb() {
	Tooltip("OnLeave",1400,900)
}

zzzzz(value?) {
	static accu := 0
	accu += value
	Tooltip("OnWheel " accu,1400,900)
}


 */