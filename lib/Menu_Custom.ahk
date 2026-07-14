/************************************************************************
 * @description Robust, Modular Menu (No-Crash Dependency Checking)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.3.1
 ***********************************************************************/

#Requires AutoHotkey v2.0

Menu_Custom() {

    TrayMenu := A_TrayMenu
    MoreMenu := TrayMenu.HasProp("MoreMenu") ? TrayMenu.MoreMenu : ""

    ; Reload fix
;    TrayMenu.Delete("Restart")
;    TrayMenu.Insert("Exit", "Restart", (*) => Reload())
    TrayMenu.ClickCount     := 2

    try MoreMenu.Delete("Suspend")
    try MoreMenu.Delete("Pause")

    TrayMenu.Insert("More", "Settings...", (*) => ShowSettingsGUI())
    TrayMenu.Insert("More", "Playback Devices...", (*) => _HoverSettingsGUI())





    ; Custom items
/*
    ; INSERT AT POSITION
    TrayMenu.Insert("3&", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
    TrayMenu.Insert("4&", "Volume Mixer", (*) => Run("sndvol.exe"))
    TrayMenu.Insert("5&")
 */

    ; INSERT OVER 'More'
;    TrayMenu.Insert("More", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
;    TrayMenu.Insert("More", "Volume Mixer", (*) => Run("sndvol.exe"))
;    TrayMenu.Insert("More")

    ; Clean up Suspend and Pause
;    if (MoreMenu != "") {
;    try MoreMenu.Delete("4&")
;    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}

;A_TrayMenu.Delete()

