/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/06
 * @version 1.2.0
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES
; ==============================================================================
; --- PROFILES ---
; ==============================================================================

Settings.ActiveProfile := "Default"
Settings.TrayIconClick := false
Settings.UseHotKey := true
Settings.HotKey := "ScrollLock"
Settings.Exclusions := "mspaint.exe,powertoys.exe,steamwebhelper.exe,voicemeeter8x64.exe,whatsapp.root.exe"
Settings.Custom_BaseSpeed :=        1.03
Settings.Custom_BrakingFriction :=  0.10
Settings.Custom_SpeedBoost :=       1.16

global GlobalActiveProfile := "Default"
global LiveExclusionMap := Map() ; The internal engine ONLY reads application blocks from this map

global Profiles := Map(
    "Slow",			{BaseSpeed: 0.840, BrakingFriction: 0.140, SpeedBoost: 0.600},
    "Precise",		{BaseSpeed: 0.216, BrakingFriction: 0.150, SpeedBoost: 6.595},
    "Delicate",		{BaseSpeed: 0.287, BrakingFriction: 0.092, SpeedBoost: 2.868},
    "Default",		{BaseSpeed: 1.080, BrakingFriction: 0.100, SpeedBoost: 1.140},
    "Fast",			{BaseSpeed: 1.600, BrakingFriction: 0.100, SpeedBoost: 1.950},
    "Dry",			{BaseSpeed: 1.400, BrakingFriction: 0.200, SpeedBoost: 1.800},
    "Wet",			{BaseSpeed: 1.400, BrakingFriction: 0.060, SpeedBoost: 1.800},
    "Custom",		{BaseSpeed: 1.030, BrakingFriction: 0.100, SpeedBoost: 1.160}
)

ProfileNames := ["Slow", "Precise", "Delicate", "Default", "Fast", "Dry", "Wet", "Custom"]
;@endregion

;ResetSettings       := Settings.Clone()
;ResetSettings       := Settings.Clone()
;ResetGeneral        := General.Clone()
;ResetOSDSettings    := OSDSettings.Clone()

App.Github := "https://github.com/Melo-Professional/Scroll-Flow"
if (App.HasOwnProp("Github")  && App.Github != "" && App.Github != "https://github.com/Melo-Professional/") {
	App.UpdateAuto := true
	App.UpdateFrequencyDays := 3
	App.UpdateLastCheck := ""
	SaveToINI.Push("App.UpdateAuto", "App.UpdateFrequencyDays", "App.UpdateLastCheck")
	RegisterArrayItems(SaveToINI)
	LoadINI()
}

;App.NameCutted := "Template`nBigName"
;Settings.SplashScreen := "Icon"
;Debug := true
;@endregion


;@region INI
SaveToINI.Push("Settings.ActiveProfile",
    "Settings.TrayIconClick",
    "Settings.UseHotKey",
    "Settings.HotKey",
    "Settings.Exclusions",
    "Settings.Custom_BaseSpeed",
    "Settings.Custom_BrakingFriction",
    "Settings.Custom_SpeedBoost")     ; add more to INI file
RegisterArrayItems(SaveToINI)
LoadINI()

if !(Settings.TrayIconClick == 0 || Settings.TrayIconClick == 1) ; back compatibility
{
    Settings.TrayIconClick := 0
    SaveINI()
}



GlobalActiveProfile := Settings.ActiveProfile
;KineticGui := 0

class Physics {
    static BaseSpeed := 1.00
    static BrakingFriction := 0.10
    static SpeedBoost := 1.04
    
    static Velocity := 0.0
    static MomentumReservoir := 0.0
}

; ==============================================================================
; --- INTERCEPTION ENGINE RUNTIME STATE BUFFER ---
; ==============================================================================
global TargetTopHWnd := 0
global TargetCtrlHWnd := 0
global PackedLParam := 0
global ScrollMethod := "Win32HighPrecision"
global AccV := 0.0

global KineticGui := 0
global AddAppsGui := 0
global CatalogListBox := 0 
global WorkingExclusions := "" 

;@endregion