/************************************************************************
 * @description Robust, Modular Menu (No-Crash Dependency Checking)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/04
 * @version 1.4.1
 ***********************************************************************/

Menu_Custom() {

    TrayMenu := A_TrayMenu
    MoreMenu := TrayMenu.HasProp("MoreMenu") ? TrayMenu.MoreMenu : ""

    try MoreMenu.Delete("Light")
    try MoreMenu.Delete("Dark")
    try MoreMenu.Delete("Auto")
;    try MoreMenu.Delete("1&")
;    try MoreMenu.Delete("2&")
;    try MoreMenu.Delete("3&")
    try MoreMenu.Delete("Pause")
    try MoreMenu.Delete("Suspend")

    TrayMenu.Insert("Restart", "")

    if A_IsCompiled {
        try TrayMenu.Delete("Restart")
        try MoreMenu.Delete("Explore")
    }

;    TrayMenu.Insert("Pause`tScrollLock", "")
    ;TrayMenu.Insert("Exit", "Pause`tScrollLock", (*) => ToggleSuspend())
    TrayMenu.Insert("Exit", "Pause", (*) => ToggleSuspend())

    global OptionsMenu := Menu()
    A_TrayMenu.OptionsMenu := OptionsMenu
    OptionsMenu.Add("Settings...", (*) => ShowKineticGUI())

    global ProfileMenu := Menu()

;    profilesOrder := ["Slow", "Precise", "Default", "Fast", "Dry", "Wet", "Custom"]

    for profileName in ProfileNames {
        ProfileMenu.Add(profileName, OnTrayProfileSelect)
    }

    try ProfileMenu.Check(GlobalActiveProfile)

    TrayMenu.Insert("More","Options", OptionsMenu)
    OptionsMenu.Add("Profiles", ProfileMenu)


; --- FIX: ONMESSAGE LEFT-CLICK ONLY ---
    OnMessage(0x404, TrayIconClick)  ; WM_TRAYICON = 0x404

    TrayIconClick(wParam, lParam, msg, hwnd) {
        ; 0x201 = WM_LBUTTONDOWN (Single left click)
        ; 0x203 = WM_LBUTTONDBLCLK (Double left click)
        if (lParam = 0x201 || lParam = 0x203) {
            if (Settings.TrayIconClick == false) {
                ShowKineticGUI()
            } else {
                ToggleSuspend()
            }
            return 1  ; <-- CRITICAL: Tells Windows "I handled this", blocking the menu!
        }
    }



    OnTrayProfileSelect(ItemName, ItemPos, MyMenu) {
        ApplyProfile(ItemName)
        SaveSettings()
    }
}