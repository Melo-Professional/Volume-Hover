/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/06
 * @version 1.2.0
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES
App.Github := "https://github.com/Melo-Professional/Volume-Hover"
if (App.HasOwnProp("Github")  && App.Github != "" && App.Github != "https://github.com/Melo-Professional/") {
	App.UpdateAuto := true
	App.UpdateFrequencyDays := 3
	App.UpdateLastCheck := ""
	SaveToINI.Push("App.UpdateAuto", "App.UpdateFrequencyDays", "App.UpdateLastCheck")
}

/*
Global General := {
    BTDetect:                   true,
    WheelSpeed:                 10,
    gainStepsMin:               2,
    gainStepsMax:               20
}
*/

;ResetSettings       := Settings.Clone()
;ResetGeneral        := General.Clone()
;ResetOSDSettings    := OSDSettings.Clone()

;App.NameCutted := "Template`nBigName"
;Settings.SplashScreen := "Icon"
;Debug := true
;@endregion

;Settings.GuiFontName:= "Microsoft Sans Serif"

Global General := {
    PlaybackDevices: "",
    OSDList: ["Disable", "Normal", "Slim"],
    UseOSD: "Slim",
    OSDMonitor: 1,
    OSDPositionList: ["Top", "Center", "Bottom"],
    OSDPosition: "Bottom",
    KeyUp: "^#F12",
    KeyDown: "^#F11",
    MouseUp: "^#WheelUp",
    MouseDown: "^#WheelDown",
}
ResetGeneral        := General.Clone()

;@region INI
SaveToINI.Push(
    "General.PlaybackDevices", "General.UseOSD", "General.OSDMonitor", "General.OSDPosition",
    "General.KeyUp", "General.KeyDown", "General.MouseUp", "General.MouseDown"
    )     ; add more to INI file
RegisterArrayItems(SaveToINI)
LoadINI()
;@endregion

UseRegularReload := false