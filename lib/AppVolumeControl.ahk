/************************************************************************
 * @description App Volume Control Library
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/19
 * @version 1.1.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

class AppVolumeControl {
    
    ; Initialize the hotkeys from main script
    static Init(config := {}) {
        ; Default step size
        this.step := config.HasOwnProp("Step") ? config.Step : 5

        ; 1. Mouse Wheel Hotkeys
        if (config.HasOwnProp("MouseUp") && config.MouseUp != "")
            Hotkey("$" . config.MouseUp, (*) => this.HoverWindow(this.step))
            
        if (config.HasOwnProp("MouseDown") && config.MouseDown != "")
            Hotkey("$" . config.MouseDown, (*) => this.HoverWindow(-this.step))

        ; 2. Keyboard Hotkeys
        if (config.HasOwnProp("KeyUp") && config.KeyUp != "")
            Hotkey("$" . config.KeyUp, (*) => this.ActiveWindow(this.step))
            
        if (config.HasOwnProp("KeyDown") && config.KeyDown != "")
            Hotkey("$" . config.KeyDown, (*) => this.ActiveWindow(-this.step))
    }

    static HoverWindow(step, targetExe?) {
        if IsSet(targetExe){
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

    static ActiveWindow(step) {
        activeHwnd := WinExist("A")
        
        if (activeHwnd) {
            targetExe := WinGetProcessName(activeHwnd)
            this.ChangeAppVolumeByExe(targetExe, step)
        }
    }

    static ChangeAppVolumeByExe(targetExe, step) {
        global DeviceMap
        
        if (DeviceMap.Count == 0)
            PopulatePlaybackDevices()
            
        sessionFound := false
        
        for deviceName, devicePtr in DeviceMap {
            sessions := GetAudioSessionsForDevice(devicePtr)
            
            for session in sessions {
                if (session.ProgName = targetExe) {
                    newVol := session.Volume + step
                    newVol := Max(0, Min(100, newVol))
                    SetAppVolume(session.SimpleVol, newVol)
                    UpdateOSD(session.ProgName, newVol)
                    sessionFound := true
                }
            }
        }
        
        if (!sessionFound) {
            PopulatePlaybackDevices()
        }
    }
}