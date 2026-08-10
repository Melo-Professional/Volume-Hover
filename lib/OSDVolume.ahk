If IsNumber(General.OSDMonitor){
    if (General.OSDMonitor > MonitorGetCount()){
        General.OSDMonitor := 1
        SaveINI()
    }
}

; SLIM SIZE
VolumeOSDSlim 						:= OSDCustom()
VolumeOSDSlim.Monitor 				:= General.OSDMonitor
VolumeOSDSlim.MinWidth 				:= 220
VolumeOSDSlim.Speed 				:= 2.3
VolumeOSDSlim.MarginX 				:= 16
VolumeOSDSlim.MarginY 				:= 14
VolumeOSDSlim.TextDefaultLight  	:= "222222"
VolumeOSDSlim.ProgressFgLight 		:= "0067C0"
VolumeOSDSlim.ProgressBgLight 		:= "E5E5E5"
VolumeOSDSlim.TextDefaultDark  		:= "CCCCCC"
VolumeOSDSlim.ProgressFgDark  		:= "4CC2FF"
VolumeOSDSlim.ProgressBgDark  		:= "333333"
VolumeOSDSlim.ProgressBarHeight		:= 5
VolumeOSDSlim.Opacity 				:= 255
VolumeOSDSlim.TimeOut 				:= 1775
VolumeOSDSlim.FontWeight 			:= 300
VolumeOSDSlim.FontSize 				:= 7

ProgramSlim 			:= 	VolumeOSDSlim.SetCellText(1, 1, " ", "Left")
BarSlim 				:= VolumeOSDSlim.SetCellProgress(2, 1, 100, "Center",,1)
ValueSlim 				:= VolumeOSDSlim.SetCellText(3, 1, "100", "Right", { FontSize: 10, FontWeight: 700 })


; NORMAL SIZE
VolumeOSDNormal 					:= OSDCustom()
VolumeOSDNormal.Monitor 			:= General.OSDMonitor
VolumeOSDNormal.MinWidth 			:= 220
VolumeOSDNormal.Speed 				:= 2.3
VolumeOSDNormal.MarginX 			:= 16
VolumeOSDNormal.MarginY 			:= 14
VolumeOSDNormal.TextDefaultLight  	:= "222222"
VolumeOSDNormal.ProgressFgLight 	:= "0067C0"
VolumeOSDNormal.ProgressBgLight 	:= "E5E5E5"
VolumeOSDNormal.TextDefaultDark  	:= "CCCCCC"
VolumeOSDNormal.ProgressFgDark  	:= "4CC2FF"
VolumeOSDNormal.ProgressBgDark  	:= "333333"
VolumeOSDNormal.ProgressBarHeight 	:= 7
VolumeOSDNormal.Opacity 			:= 255
VolumeOSDNormal.TimeOut 			:= 1775
VolumeOSDNormal.FontWeight 			:= 700
VolumeOSDNormal.FontSize 			:= 9

ProgramNormal 			:= VolumeOSDNormal.SetCellText(1, 1, " ", "Left")
ValueNormal 			:= VolumeOSDNormal.SetCellText(2, 1, " ", "Right", { FontSize: 12, FontWeight: 1000 })
BarNormal 				:= VolumeOSDNormal.SetCellProgress(1, 2, 100,,,2)


UpdateOSD(program, currentVol) {

    if (General.UseOSD = "Normal") {

        program := RegExReplace(program, "\.[^.\\/:]+$")
        VolumeOSDNormal.UpdateProgressObject(BarNormal, currentVol)
        VolumeOSDNormal.UpdateTextObject(ProgramNormal, program)
        VolumeOSDNormal.UpdateTextObject(ValueNormal, currentVol, 2000)

        if !(VolumeOSDNormal.IsVisible) {
            VolumeOSDNormal.Show()
        }

    } else if (General.UseOSD = "Slim") {

        program := SubStr(RegExReplace(program, "\.[^.\\/:]+$"), 1, 11)
        VolumeOSDSlim.UpdateProgressObject(BarSlim, currentVol)
        VolumeOSDSlim.UpdateTextObject(ProgramSlim, program)
        VolumeOSDSlim.UpdateTextObject(ValueSlim, currentVol, 2000)

        if !(VolumeOSDSlim.IsVisible) {
            VolumeOSDSlim.Show()
        }
    }
}

SettingsShowOSD(program, currentVol) {

    if (General.UseOSD = "Normal") {

        program := RegExReplace(program, "\.[^.\\/:]+$")
        VolumeOSDNormal.UpdateProgressObject(BarNormal, currentVol)
        VolumeOSDNormal.UpdateTextObject(ProgramNormal, program)
        VolumeOSDNormal.UpdateTextObject(ValueNormal, currentVol, 2000)
        VolumeOSDNormal.Show(,, 5000)

    } else if (General.UseOSD = "Slim") {

        program := SubStr(RegExReplace(program, "\.[^.\\/:]+$"), 1, 11)
        VolumeOSDSlim.UpdateProgressObject(BarSlim, currentVol)
        VolumeOSDSlim.UpdateTextObject(ProgramSlim, program)
        VolumeOSDSlim.UpdateTextObject(ValueSlim, currentVol, 2000)
        VolumeOSDSlim.Show(,, 5000)
    }
}

switch General.OSDPosition {
    case "Top": (
        VolumeOSDSlim.Position := "x0.50 y0.09"
        VolumeOSDNormal.Position := "x0.50 y0.09"
    )
    case "Center": (
        VolumeOSDSlim.Position := "x0.50 y0.50"
        VolumeOSDNormal.Position := "x0.50 y0.50"
    )
    default :(
        VolumeOSDSlim.Position := "x0.50 y0.91"
        VolumeOSDNormal.Position := "x0.50 y0.91"
    )
}