/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/01
 * @version 1.1.0
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES
App.Github := "https://github.com/Melo-Professional/Volume-Hover"
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

Global General := {
    PlaybackDevices: "",
}

;@region INI
SaveToINI.Push("General.PlaybackDevices")     ; add more to INI file
RegisterArrayItems(SaveToINI)
LoadINI()
;@endregion