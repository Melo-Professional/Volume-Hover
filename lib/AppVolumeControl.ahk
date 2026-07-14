#Requires AutoHotkey v2.0

; ==============================================================================
; App Volume Control Library
; Hotkeys to change specific application volume on the fly.
; Requires: AudioSessions.ahk to be included in the main script.
; ==============================================================================

class AppVolumeControl {
    
    ; Initialize the hotkeys from your main script
    static Init(config := {}) {
        ; Default step size
        this.step := config.HasOwnProp("Step") ? config.Step : 5

        ; 1. Mouse Wheel Hotkeys
        if (config.HasOwnProp("MouseUp") && config.MouseUp != "")
            Hotkey(config.MouseUp, (*) => this.AdjustVolumeByMouse(this.step))
            
        if (config.HasOwnProp("MouseDown") && config.MouseDown != "")
            Hotkey(config.MouseDown, (*) => this.AdjustVolumeByMouse(-this.step))

        ; 2. Keyboard Hotkeys
        if (config.HasOwnProp("KeyUp") && config.KeyUp != "")
            Hotkey(config.KeyUp, (*) => this.AdjustVolumeByActiveWindow(this.step))
            
        if (config.HasOwnProp("KeyDown") && config.KeyDown != "")
            Hotkey(config.KeyDown, (*) => this.AdjustVolumeByActiveWindow(-this.step))
    }

    static AdjustVolumeByMouse(step) {
        CoordMode("Mouse", "Screen")
        MouseGetPos(,, &hoveredHwnd)
        
        if (hoveredHwnd) {
            targetExe := WinGetProcessName(hoveredHwnd)
            this.ChangeAppVolumeByExe(targetExe, step)
        }
    }

    static AdjustVolumeByActiveWindow(step) {
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

/* 
                    if (General.UseOSD = "Normal") {
                        UpdateVolumeOSDNormal(session.ProgName, newVol)
                    } else if (General.UseOSD = "Slim") {
                        UpdateVolumeOSDSlim(session.ProgName, newVol)
                    }
 */
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