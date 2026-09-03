/************************************************************************
 * @description App Volume Control Library
 * @author Melo
 * @date 2026/08/25
 * @version 2.2.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

class AppVolumeControl {
    
    ; Initialize the hotkeys from main script
    static Init(config := {}) {
        ; Default step size
        this.step := config.HasOwnProp("Step") ? config.Step : 5

        ; 1. Mouse Wheel Hotkeys (Hovered Window)
        if (config.HasOwnProp("MouseUp") && config.MouseUp != "")
            Hotkey("$" . config.MouseUp, (*) => this.HoverWindow(this.step))
            
        if (config.HasOwnProp("MouseDown") && config.MouseDown != "")
            Hotkey("$" . config.MouseDown, (*) => this.HoverWindow(-this.step))

        ; 2. Keyboard Hotkeys (Active Window)
        if (config.HasOwnProp("KeyUp") && config.KeyUp != "")
            Hotkey("$" . config.KeyUp, (*) => this.ActiveWindow(this.step))
            
        if (config.HasOwnProp("KeyDown") && config.KeyDown != "")
            Hotkey("$" . config.KeyDown, (*) => this.ActiveWindow(-this.step))

        ; 3. Mouse Wheel Taskbar
        if (config.HasOwnProp("TaskbarUp") && config.TaskbarUp != "") {
			;HotIf (*) => this.MouseIsOverTaskbar()
			HotIf this.MouseIsOverTaskbar
            Hotkey("$~" . config.TaskbarUp, (*) => this.OverTaskBar(this.step))
			HotIf()
		}
            
        if (config.HasOwnProp("TaskbarDown") && config.TaskbarDown != "") {
			;HotIf (*) => this.MouseIsOverTaskbar()
			HotIf this.MouseIsOverTaskbar
            Hotkey("$~" . config.TaskbarDown, (*) => this.OverTaskBar(-this.step))
			HotIf()
		}
    }

    ; Callback for scrolling over taskbar icons
    static OverTaskBar(step) {
;        if (!this.MouseIsOverTaskbar()) {
			;_Debug(,"Both")
            ; Pass through normal wheel scroll if triggered off the taskbar
;            key := RegExReplace(A_ThisHotkey, "[\$\~]")
;            Send("{" . key . "}")
;            return
;        }

        try {
            el := UIA.ElementFromPoint()
            targetExe := this.GetProcessFromAppID(el.AutomationId, el.Name)

			_Debug(targetExe,"Both")
            
            if (targetExe != "")
                this.ChangeAppVolumeByExe(targetExe, step, true)
        }
    }

    ; Callback for scrolling over standard application windows
    static HoverWindow(step, targetExe?) {
        if IsSet(targetExe) {
            this.ChangeAppVolumeByExe(targetExe, step)
            return
        }

        CoordMode("Mouse", "Screen")
        MouseGetPos(,, &hoveredHwnd)
        
        if (hoveredHwnd) {
            targetExe := WinGetProcessName(hoveredHwnd)
            this.ChangeAppVolumeByExe(targetExe, step)
        }
    }

    ; Callback for active window keyboard hotkeys
    static ActiveWindow(step) {
        activeHwnd := WinExist("A")
        
        if (activeHwnd) {
            targetExe := WinGetProcessName(activeHwnd)
            this.ChangeAppVolumeByExe(targetExe, step)
        }
    }

    ; Core volume adjustment using global DeviceMap and WASAPI sessions
    static ChangeAppVolumeByExe(targetExe, step, isTaskbar := false) {
        global DeviceMap
        
        if (!IsSet(DeviceMap) || DeviceMap.Count == 0)
            PopulatePlaybackDevices()
            
        sessionFound := false
        
        for deviceName, devicePtr in DeviceMap {
            sessions := GetAudioSessionsForDevice(devicePtr)
            
            for session in sessions {
                if (InStr(session.ProgName, targetExe, false) || InStr(targetExe, session.ProgName, false)) {
                    newVol := session.Volume + step
                    newVol := Max(0, Min(100, newVol))
                    SetAppVolume(session.SimpleVol, newVol)
                    
                    if (isTaskbar && General.OSDPosition == "Bottom")
                        UpdateOSD(session.ProgName, newVol, "x0.50 y0.71")
                    else
                        UpdateOSD(session.ProgName, newVol)
                        
                    sessionFound := true
                }
            }
        }
        
        if (!sessionFound) {
            PopulatePlaybackDevices()
        }
    }

/* 
    static MouseIsOverTaskbar() {
		MouseGetPos(,, &hWnd)
		if !hWnd
			return false
		winClass := WinGetClass(hWnd)
		return winClass == "Shell_TrayWnd" || winClass == "Shell_SecondaryTrayWnd"
	}
 */

	static MouseIsOverTaskbar(*) {
        MouseGetPos(,, &hWnd, &ctrl)
        if !hWnd
            return false

        try {
            winClass := WinGetClass(hWnd)

            ; Ensure the cursor is over the main or secondary taskbar window
            if !(winClass == "Shell_TrayWnd" || winClass == "Shell_SecondaryTrayWnd")
                return false

            ; Exclude system tray, clock, notification area, and overflow controls
            if RegExMatch(ctrl, "i)(TrayNotifyWnd|SysPager|Clock|ControlNotificationArea|Notification|Overflow)")
                return false

            return true
        } catch {
            return false
        }
    }

    static GetProcessFromAppID(AID, elName) {
        if RegExMatch(AID, "i)([\w\.-]+\.exe)", &m)
            return m[1]
        
        for hwnd in WinGetList() {
            try {
                pName := WinGetProcessName(hwnd)
                pBase := SubStr(pName, 1, InStr(pName, ".") - 1)
                if (pBase != "" && (InStr(AID, pBase, false) || InStr(elName, pBase, false)))
                    return pName
            }
        }
        return ""
    }
}