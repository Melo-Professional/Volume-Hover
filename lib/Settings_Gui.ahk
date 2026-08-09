/************************************************************************
 * @description Kinetic Settings GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/20
 * @version 1.2.0
 ***********************************************************************/

ShowKineticGUI() {
    global KineticGui, ProfileDDL, SpeedSlider, FrictionSlider, BoostSlider, optUseHotKey
    global SpeedText, FrictionText, BoostText, ExclusionBox, WorkingExclusions
    global LiveExclusionMap
    
    WorkingExclusions := ""
        for exeName, _ in LiveExclusionMap {
            WorkingExclusions .= (WorkingExclusions == "" ? "" : ",") exeName
        }

/* 
    try {
        for exeName, _ in LiveExclusionMap {
            WorkingExclusions .= (WorkingExclusions == "" ? "" : ",") exeName
        }
    } catch {
        MsgBox("error")
    }
 */

    if (KineticGui != 0) {
        KineticGui.Show()
        UpdateKineticGUIElements()
        return
    }
    
    KineticGui := Gui("AlwaysOnTop", App.Name " Settings")
    KineticGui.SetFont("s10 Norm", "Segoe UI")


    KineticGui.OnEvent("Close", CancelAndRestoreValues)
    KineticGui.OnEvent("Escape", CancelAndRestoreValues)
    
    ; ---------------- LEFT COLUMN: PHYSICAL ENGINE TUNING ----------------
    KineticGui.AddGroupBox("x20 y15 w430 h80", "Preset Profile Template")
    KineticGui.SetFont("s11 w400")
;    ProfileDDL := KineticGui.AddDropDownList("x40 y42 w390 Choose1", ["Slow", "Precise", "Default", "Fast", "Dry", "Wet", "Custom"])
    ProfileDDL := KineticGui.AddDropDownList("x40 y42 w390 Choose1", ProfileNames)
    ProfileDDL.OnEvent("Change", OnProfileChange)

    KineticGui.SetFont("s10 Norm", "Segoe UI")
    SendMessage(0x0153, -1, 24, ProfileDDL)
    SendMessage(0x0153, 0, 30, ProfileDDL)

    KineticGui.AddGroupBox("x20 y115 w430 h400", "Live Kinetic Engine Settings")
    
    KineticGui.SetFont("bold")
    SpeedText := KineticGui.AddText("x40 y145 w390", "Speed: 1.000")
    KineticGui.SetFont("Norm")
    KineticGui.SetFont("s9", "Segoe UI")
    KineticGui.AddText("VSmooth_speed x40 y170 w380", "Controls distance traveled on single, isolated wheel clicks. Lower values allow exact micro-adjustments.")
    SpeedSlider := ModernSlider(KineticGui, "x35 y205 w400", 100, 10, 5000, OnSliderAdjustment)

    KineticGui.SetFont("s10 cDefault", "Segoe UI")
    
    KineticGui.SetFont("bold")
    BoostText := KineticGui.AddText("x40 y270 w390", "Acceleration: 1.040")
    KineticGui.SetFont("Norm")
    KineticGui.SetFont("s9", "Segoe UI")
    KineticGui.AddText("VSmooth_accel x40 y295 w380", "Sets the acceleration rate when spinning the wheel rapidly. Stays inactive during slow turns, but builds high velocity on large pages.")
    KineticGui.SetFont("bold")
    BoostSlider := ModernSlider(KineticGui, "x35 y330 w400", 104, 10, 25000, OnSliderAdjustment)
    KineticGui.SetFont("s10 cDefault", "Segoe UI")
    
    KineticGui.SetFont("bold")
    FrictionText := KineticGui.AddText("x40 y395 w390", "Breaking: 0.100")
    KineticGui.SetFont("norm")
    KineticGui.SetFont("s9", "Segoe UI")
    KineticGui.AddText("VSmooth_break x40 y420 w380", "Determines how quickly scrolling slides to a stop. Higher values stop instantly; lower values provide a smooth glide.")
    FrictionSlider := ModernSlider(KineticGui, "x35 y455 w400", 10, 1, 500, OnSliderAdjustment)
    KineticGui.SetFont("s10 Norm cDefault", "Segoe UI")

;    KineticGui.AddText("x30 y530 h25 0x0200", "Pause/ Activate")
    KineticGui.AddGroupBox("x20 y530 w430 h110", "Pause / Activate")

;    KineticGui.SetFont("s9 cDefault w300", "Segoe UI")
KineticGui.SetFont("s9 Norm cDefault ", "Segoe UI")
    optLeftClick := KineticGui.Add("Checkbox", "x40 y565 w220", "  With left click at tray icon")
    optLeftClick.Value := Settings.TrayIconClick
optLeftClick.OnEvent("Click", ActionsLeftClickIcon)


    KineticGui.AddText("x40 y600 h25 0x0200", "With Hotkey:    ")

    KineticGui.SetFont("s8 w700", "Segoe UI")
    HotKeyCtrl := KineticGui.Add("Button", "x+5 yp h25 w240")
    HotkeyManager.BindControl(HotKeyCtrl, Settings.HotKey, ToggleSuspend)



    ActionsLeftClickIcon(*) {
        Settings.TrayIconClick := optLeftClick.Value
        SaveINI()
        ReloadWithArgs("ShowKineticGUI")
    }

KineticGui.SetFont("s10 cDefault Norm", "Segoe UI")

    ; ---------------- RIGHT COLUMN: EXCLUSION INTERFACE ----------------
    KineticGui.AddGroupBox("x475 y15 w320 h575", "Exceptions")

KineticGui.SetFont("s9 cDefault Norm", "Segoe UI")
    KineticGui.AddText("x495 y45 w280", "Do not apply scroll effect to the programs below:")
    ExclusionBox := KineticGui.AddListBox("x495 y88 w280 h445")
    
    BtnAddCatalog := KineticGui.AddButton("x495 y535 w135 h30", "&Add...")
    BtnAddCatalog.OnEvent("Click", OpenAppCatalogModal)
    
    BtnRem := KineticGui.AddButton("x640 y535 w135 h30", "&Remove")
    BtnRem.OnEvent("Click", RemoveTargetFromExclusions)
    
    ; ---------------- BOTTOM ALIGNED ACTIONS ----------------
    BtnSave := KineticGui.AddButton("x645 y610 w150 h30 +Default", "&Save")
    BtnSave.OnEvent("Click", CommitChangesToIni)
    
;    BtnCancel := KineticGui.AddButton("x475 y610 w150 h30", "&Close")
;    BtnCancel.OnEvent("Click", CancelAndRestoreValues)
    
    UpdateKineticGUIElements()

    ApplyThemeToGui(KineticGui)
    WatchedGUIs.Push(KineticGui)

    ;KineticGui.Show("w815 h595")
    KineticGui.Show("w815 h660")



    OnProfileChange(CtrlObj, *) {
        ApplyProfile(CtrlObj.Text)
        UpdateKineticGUIElements()
    }

    OnSliderAdjustment(*) {
        global ProfileDDL, GlobalActiveProfile
        if (ProfileDDL.Text != "Custom") {
            ProfileDDL.Choose("Custom")
            GlobalActiveProfile := "Custom"
        }
        
        vSpeed := Round((SpeedSlider.Value / 1000), 3)
        vBoost := Round((BoostSlider.Value / 1000), 3)
        vFric  := Round((FrictionSlider.Value / 1000), 3)
        
        Profiles["Custom"].BaseSpeed := vSpeed
        Profiles["Custom"].SpeedBoost := vBoost
        Profiles["Custom"].BrakingFriction := vFric
        
        Physics.BaseSpeed := vSpeed
        Physics.SpeedBoost := vBoost
        Physics.BrakingFriction := vFric

        SpeedText.Text := "Speed: " String(Format("{:.3f}", vSpeed))
        BoostText.Text := "Acceleration: " String(Format("{:.3f}", vBoost))
        FrictionText.Text := "Braking: " String(Format("{:.3f}", vFric))
    }

    RemoveTargetFromExclusions(*) {
        global WorkingExclusions
        selectedIdx := ExclusionBox.Value
        if (selectedIdx == 0)
            return
            
        items := StrSplit(WorkingExclusions, ",")
        items.RemoveAt(selectedIdx)
        
        rebuiltStr := ""
        for item in items {
            cleanItem := Trim(item)
            if (cleanItem != "")
                rebuiltStr .= (rebuiltStr == "" ? "" : ",") cleanItem
        }
        WorkingExclusions := rebuiltStr
        
        UpdateKineticGUIElements()
    }

    CommitChangesToIni(*) {
        global KineticGui, WorkingExclusions, LiveExclusionMap, optUseHotKey, Settings
        
        LiveExclusionMap.Clear()
        loop parse, WorkingExclusions, "," {
            clean := StrLower(Trim(A_LoopField))
            if (clean != "")
                LiveExclusionMap[clean] := true
        }

        SaveSettings()
        
        Physics.Velocity := 0.0
        Physics.MomentumReservoir := 0.0
        
        CleanDestroy()
    }

    CancelAndRestoreValues(*) {
        global KineticGui
        
    ; 1. Remove checkmark from the previously active profile
        if IsSet(ProfileMenu) {
            try ProfileMenu.Uncheck(GlobalActiveProfile)
        }
        LoadSettings()
        
        Physics.Velocity := 0.0
        Physics.MomentumReservoir := 0.0
        
    ; 2. Add checkmark to the newly active profile
        if IsSet(ProfileMenu) {
            try ProfileMenu.Check(GlobalActiveProfile)
        }

        if (KineticGui != 0) {
            ;KineticGui.Hide()
    ;    KineticGui.Destroy()
    ;    KineticGui := 0

        CleanDestroy()

        }
    }

    ; ==============================================================================
    ; --- LIVE WINDOW ENUMERATION MODAL ---
    ; ==============================================================================
    OpenAppCatalogModal(*) {
        global KineticGui, AddAppsGui, CatalogListBox
        
        AddAppsGui := Gui("+Owner" KineticGui.Hwnd, "Add Programs to Exceptions List")
        AddAppsGui.SetFont("s10", "Segoe UI")
        
        AddAppsGui.OnEvent("Close", (*) => (AddAppsGui.Destroy(), AddAppsGui := 0))
        AddAppsGui.OnEvent("Escape", (*) => (AddAppsGui.Destroy(), AddAppsGui := 0))
        
        AddAppsGui.AddText("x20 y15 w410", "Hold Ctrl or Shift to select multiple currently running applications:")
        
        CatalogListBox := AddAppsGui.AddListView("x20 y40 w410 h320", ["Process Name", "Window Title"])
        CatalogListBox.ModifyCol(1, 140) 
        CatalogListBox.ModifyCol(2, 260) 
        
        idList := WinGetList()
        addedProcesses := Map()
        
        for hwnd in idList {
            try {
                title := WinGetTitle(hwnd)
                style := WinGetStyle(hwnd)
                pName := WinGetProcessName(hwnd)
                
                ;if (title != "" && (style & 0x10000000) && pName != "explorer.exe" && !InStr(pName, "AutoHotkey")) {
                if (title != "" && (style & 0x10000000) && !InStr(pName, "AutoHotkey")) {
                    if !addedProcesses.Has(StrLower(pName)) {
                        addedProcesses[StrLower(pName)] := true
                        CatalogListBox.Add(, pName, title)
                    }
                }
            }
        }
        
        if (CatalogListBox.GetCount() == 0)
            CatalogListBox.Add(, "No active windows", "")
            
        BtnBrowse := AddAppsGui.AddButton("x20 y375 w120 h30", "Select From File...")
;        BtnBrowse.OnEvent("Click", BrowseForExecutableFile)
        BtnBrowse.OnEvent("Click", (*) => (AddAppsGui.Destroy(), BrowseForExecutableFile()))
        
        BtnAddSelected := AddAppsGui.AddButton("x155 y375 w140 h30 +Default", "Add Selected")
        BtnAddSelected.OnEvent("Click", ProcessCatalogSelections)
        
        BtnClose := AddAppsGui.AddButton("x310 y375 w120 h30", "Close")
        BtnClose.OnEvent("Click", (*) => (AddAppsGui.Destroy(), AddAppsGui := 0))

        ApplyThemeToGui(AddAppsGui)
        WatchedGUIs.Push(AddAppsGui)

        AddAppsGui.Show("w450 h422")
        ;AddAppsGui.Show("w450 h630")
    }

    ProcessCatalogSelections(*) {
        global CatalogListBox, WorkingExclusions, AddAppsGui
        
        RowNumber := 0
        Loop {
            RowNumber := CatalogListBox.GetNext(RowNumber)
            if (!RowNumber)
                break
                
            pName := StrLower(Trim(CatalogListBox.GetText(RowNumber, 1)))
            
            if (pName == "no active windows")
                continue
                
            isDuplicate := false
            loop parse, WorkingExclusions, "," {
                if (StrLower(Trim(A_LoopField)) == pName) {
                    isDuplicate := true
                    break
                }
            }
            
            if (!isDuplicate) {
                WorkingExclusions .= (WorkingExclusions == "" ? "" : ",") pName
            }
        }
        
        UpdateKineticGUIElements()
        AddAppsGui.Destroy()
        AddAppsGui := 0
    }

    BrowseForExecutableFile(*) {
        global WorkingExclusions, AddAppsGui
        
        SelectedFile := FileSelect(3, , "Select Target Executable to Bypass", "Applications (*.exe; *.dll)")
        if (SelectedFile == "")
            return
            
        SplitPath(SelectedFile, &pName)
        pName := StrLower(Trim(pName))
        
        isDuplicate := false
        loop parse, WorkingExclusions, "," {
            if (StrLower(Trim(A_LoopField)) == pName) {
                isDuplicate := true
                break
            }
        }
        
        if (!isDuplicate) {
            WorkingExclusions .= (WorkingExclusions == "" ? "" : ",") pName
            UpdateKineticGUIElements()
        }
        
        AddAppsGui.Destroy()
        AddAppsGui := 0
    }


    CleanDestroy(*) {
        KineticGui.Destroy()
        KineticGui := 0
        try HotkeyRecorder.Cancel()
    }
}

UpdateKineticGUIElements() {
    global ProfileDDL, SpeedSlider, FrictionSlider, BoostSlider, ExclusionBox, WorkingExclusions, GlobalActiveProfile, optUseHotKey
    global SpeedText, FrictionText, BoostText
    
    ProfileDDL.Text := GlobalActiveProfile
    
    SpeedSlider.Value := Integer(Physics.BaseSpeed * 1000)
    SpeedText.Text := "Speed: " String(Format("{:.3f}", Physics.BaseSpeed))
    
    BoostSlider.Value := Integer(Physics.SpeedBoost * 1000)
    BoostText.Text := "Acceleration: " String(Format("{:.3f}", Physics.SpeedBoost))
    
    FrictionSlider.Value := Integer(Physics.BrakingFriction * 1000)
    FrictionText.Text := "Braking: " String(Format("{:.3f}", Physics.BrakingFriction))

    ExclusionBox.Delete()
    loop parse, WorkingExclusions, "," {
        cleanItem := Trim(A_LoopField)
        if (cleanItem != "") && (cleanItem != 0)
            ExclusionBox.Add([cleanItem])
    }
}

