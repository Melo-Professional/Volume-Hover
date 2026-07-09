/************************************************************************
 * @description OSDCustom (Dynamic Styling & Multi-Column Grid Engine)
 * @version 6.13.1 (UpdateImageObject method )
 ***********************************************************************/

#Requires AutoHotkey v2.0

class OSDCustom {
    static pToken := 0

    static __New() {
        si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
        NumPut("UInt", 1, si, 0)
        pToken := 0
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0)
        OSDCustom.pToken := pToken
    }

    static DWMMinVer := "10.0.22000"
    static UseOSD := true
    static Monitor := "Auto"
    static MinWidth := 50
    static MaxWidth := 1600
    static FontSize := 11
    static TimeOut := 1800
    static Speed := 4
    static Position := "x0.50 y0.50"
    static SlideDistance := 30
    static FontName := "Segoe UI"
    static FontWeight := 400
    static MarginX := 24
    static MarginY := 16
    static Opacity := 245
    static RoundedCorners := 15
    static ProgressMaxValue := 100
    static ProgressBarHeight := 6

    ; Backward-compat: used only when no SetCellProgress cell is defined
    static ProgressBarRow := 4
    static RowGap := 8
    static Theme := "Auto"

    static TextDefaultLight := "5a5555"
    static BgColorLight := "F5F9FB"
    static BorderColorLight := "ffffff"
    static ProgressFgLight := "0067C0"
;    static ProgressBgLight := "EDF1F2"
    static ProgressBgLight := "E5E5E5"
    static ProgressOver100Light := "FF5555"

    static TextDefaultDark := "d8d8d8"
    static BgColorDark := "272525"
    static BorderColorDark := "272525"
    static ProgressFgDark := "4CC2FF"
    static ProgressBgDark := "333333"
    static ProgressOver100Dark := "FF5555"

    static DWMCompatible {
        get => (VerCompare(A_OSVersion, OSDCustom.DWMMinVer) >= 0)
    }

    __Get(name, args) {
        if OSDCustom.HasProp(name)
            return OSDCustom.%name%
    }

    __New(title := "Custom OSD", options := "-Caption +AlwaysOnTop +ToolWindow +E0x20 -DPIScale") {
        this.Title := title
        this.Options := options " +Owner"
        this.MyGui := ""
        this.ProgressCtrl := ""
        this.ProgressValue := ""
        
        this.ProgressMin := 0
        this.ProgressMax := OSDCustom.ProgressMaxValue

        this.Cells := []
        this.CellCtrls := Map()

        this.State := "Hidden"
        this.PosX := 0
        this.CurrentY := 0
        this.StartY := 0
        this.FinalY := 0
        this.CurrentAlpha := 0
        this.AlphaStep := 0
        this.InternalState := "Ready"

        this.SlideInCb := ObjBindMethod(this, "AnimateSlideIn")
        this.SlideOutCb := ObjBindMethod(this, "AnimateSlideOut")
        this.DestroyCb := ObjBindMethod(this, "Destroy")

        OnMessage(0x001A, ObjBindMethod(this, "OnSettingChange"))
    }

    ; --- Cell definition methods ---

    SetCellText(col, row, text, alignment := "Left", styleObj := "", colSpan := 1, rowSpan := 1) {
        textObj := { Type: "Text", Col: col, Row: row, Text: text, Align: alignment, Style: styleObj, ColSpan: colSpan, RowSpan: rowSpan }
        this.Cells.Push(textObj)
        return textObj
    }
/* 
    SetCellImage(col, row, imagePath, alignment := "Center", targetHeight := 54, colSpan := 1, rowSpan := 1) {
        if (!FileExist(imagePath))
            throw Error("Image file not found: " imagePath)
        this.Cells.Push({ Type: "Image", Col: col, Row: row, Path: imagePath, TargetH: targetHeight, Align: alignment, Style: "", ColSpan: colSpan, RowSpan: rowSpan })
    }
 */

    SetCellImage(col, row, imagePath, alignment := "Center", targetHeight := 54, colSpan := 1, rowSpan := 1) {
        if (!FileExist(imagePath))
            throw Error("Image file not found: " imagePath)

        imageObj := { Type: "Image", Col: col, Row: row, Path: imagePath, TargetH: targetHeight, Align: alignment, Style: "", ColSpan: colSpan, RowSpan: rowSpan }
        this.Cells.Push(imageObj)
        return imageObj
    }

    ; range can be: "-50-100", [-50, 100], {Min:-50, Max:100}, or just 500 (meaning 0 to 500)
/*     SetCellProgress(col := 1, row := this.ProgressBarRow, value := 0, alignment := "Center", range := "", colSpan := 999, rowSpan := 1) {
        rng := OSDCustom.ParseRange(range, this.ProgressMaxValue)
        this.Cells.Push({ Type: "Progress", Col: col, Row: row, Value: value, ColSpan: colSpan, RowSpan: rowSpan, Style: "", Align: alignment, Min: rng.Min, Max: rng.Max })
    }
 */

    SetCellProgress(col := 1, row := this.ProgressBarRow, value := 0, alignment := "Center", range := "", colSpan := 999, rowSpan := 1) {
        rng := OSDCustom.ParseRange(range, this.ProgressMaxValue)
        progressObj := { Type: "Progress", Col: col, Row: row, Value: value, ColSpan: colSpan, RowSpan: rowSpan, Style: "", Align: alignment, Min: rng.Min, Max: rng.Max }
        this.Cells.Push(progressObj)
        return progressObj
    }

    ClearCells() {
        this.Cells := []
        this.ProgressValue := ""
    }

    ; --- Theme helpers ---

    IsLightMode() {
        if (StrLower(this.Theme) != "auto")
            return (StrLower(this.Theme) == "light")
        try {
            return RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
        } catch {
            return true
        }
    }

    GetCurrentThemeColor(propName) {
        suffix := this.IsLightMode() ? "Light" : "Dark"
        fullPropName := propName suffix
        
        ; 1. Check if this specific instance has a custom override
        if (this.HasProp(fullPropName))
            return this.%fullPropName%
            
        ; 2. Otherwise, fall back to the global class default
        return OSDCustom.%fullPropName%
    }

    ApplyThemeColors() {
        if (this.InternalState != "Ready" || !this.MyGui)
            return

        try {
            resolvedBg := this.GetCurrentThemeColor("BgColor")
            this.MyGui.BackColor := resolvedBg
            isLight := this.IsLightMode()

            for idx, ctrl in this.CellCtrls {
                if (idx < 1 || idx > this.Cells.Length)
                    continue
                info := this.Cells[idx]
                
                ; Handle text cell styling
                if (info.Type == "Text") {
                    textColor := this.GetCurrentThemeColor("TextDefault")
                    if (IsObject(info.Style)) {
                        if (isLight && info.Style.HasProp("ColorLight"))
                            textColor := info.Style.ColorLight
                        else if (!isLight && info.Style.HasProp("ColorDark"))
                            textColor := info.Style.ColorDark
                    }
                    try ctrl.SetFont("c" textColor)
                }
                
                ; Handle progress bar cell styling dynamically for ALL bars
                else if (info.Type == "Progress") {
                    resolvedFg := this.GetCurrentThemeColor("ProgressFg")
                    pMax := info.HasProp("Max") ? info.Max : this.ProgressMaxValue
                    
                    if (IsNumber(info.Value) && info.Value > pMax)
                        resolvedFg := this.GetCurrentThemeColor("ProgressOver100")
                        
                    resolvedPbBg := this.GetCurrentThemeColor("ProgressBg")
                    if (resolvedPbBg = "transparent")
                        resolvedPbBg := resolvedBg

                    try ctrl.Opt("c" resolvedFg " Background" resolvedPbBg)
                }
            }
        }
    }

    OnSettingChange(wParam, lParam, msg, hwnd) {
        if (StrLower(this.Theme) == "auto" && this.InternalState == "Ready")
            try this.ApplyThemeColors()
    }

    ; --- Main Show method ---

    Show(Position := "", TimeOut := "", Progress := "") {
        Critical("On")
        this.InternalState := "Assembling"

        SetTimer(this.DestroyCb, 0)
        SetTimer(this.SlideInCb, 0)
        SetTimer(this.SlideOutCb, 0)

        if (Position == "")
            Position := this.Position
        if (TimeOut == "")
            TimeOut := this.TimeOut
        if (Progress !== "")
            this.ProgressValue := Progress

        if (this.Cells.Length == 0) {
            this.SetCellText(1, 1, A_LineFile, "Center")
        }

        if (this.MyGui) {
            try this.MyGui.Destroy()
        }
        this.CellCtrls.Clear()
        this.ProgressCtrl := ""
        this.MyGui := Gui(this.Options, this.Title)
        this.MyGui.OnEvent("Close", (*) => this.Destroy())

        this.MyGui.MarginX := this.MarginX
        this.MyGui.MarginY := this.MarginY

        hasProgressCell := false
        for cell in this.Cells {
            if (cell.Type == "Progress") {
                hasProgressCell := true
                if (this.ProgressValue !== "")
                    cell.Value := this.ProgressValue
                break
            }
        }

        autoInsertedProgress := false
        if (!hasProgressCell && this.ProgressValue !== "") {
            initVal := IsNumber(this.ProgressValue) ? Integer(this.ProgressValue) : 0
            this.Cells.Push({ Type: "Progress", Col: 1, Row: this.ProgressBarRow, Value: initVal, ColSpan: 999, RowSpan: 1, Style: "", Align: "Center", Min: 0, Max: this.ProgressMaxValue })
            autoInsertedProgress := true
        }

        maxRow := 0
        maxCol := 1
        for cell in this.Cells {
            if (cell.Row > maxRow)
                maxRow := cell.Row
            if (cell.Type != "Progress" && cell.Col > maxCol)
                maxCol := cell.Col
        }
        if (maxRow < 1)
            maxRow := 1

        reqColW := Map()
        loop maxCol
            reqColW[A_Index] := 0

        for cell in this.Cells {
            if (cell.Type == "Progress" || cell.ColSpan > 1)
                continue

            w := 0
            if (cell.Type == "Image") {
                dims := this.GetImageDims(cell.Path, cell.TargetH)
                w := dims.W + 16 
            } else {
                fName := (IsObject(cell.Style) && cell.Style.HasProp("FontName")) ? cell.Style.FontName : this.FontName
                fSize := (IsObject(cell.Style) && cell.Style.HasProp("FontSize")) ? cell.Style.FontSize : this.FontSize
                FWeight := (IsObject(cell.Style) && cell.Style.HasProp("FontWeight")) ? cell.Style.FontWeight : this.FontWeight
                bounds := this.CalculateTextSize(cell.Text, fName, fSize, FWeight, this.MaxWidth)
                w := bounds.W + 8 
            }
            if (w > reqColW[cell.Col])
                reqColW[cell.Col] := w
        }

        totalReqW := 0
        loop maxCol
            totalReqW += reqColW[A_Index]

        if (totalReqW == 0) {
            loop maxCol {
                reqColW[A_Index] := 10
                totalReqW += 10
            }
        }

        for cell in this.Cells {
            if (cell.Type != "Progress" && cell.ColSpan > 1) {
                w := 0
                if (cell.Type == "Image") {
                    w := this.GetImageDims(cell.Path, cell.TargetH).W + 16
                } else {
                    fName := (IsObject(cell.Style) && cell.Style.HasProp("FontName")) ? cell.Style.FontName : this.FontName
                    fSize := (IsObject(cell.Style) && cell.Style.HasProp("FontSize")) ? cell.Style.FontSize : this.FontSize
                    FWeight := (IsObject(cell.Style) && cell.Style.HasProp("FontWeight")) ? cell.Style.FontWeight : this.FontWeight
                    w := this.CalculateTextSize(cell.Text, fName, fSize, FWeight, this.MaxWidth).W + 8
                }
                if (w > totalReqW) {
                    extraNeeded := w - totalReqW
                    addPerCol := Ceil(extraNeeded / maxCol)
                    loop maxCol
                        reqColW[A_Index] += addPerCol
                    totalReqW += addPerCol * maxCol
                }
            }
        }

        finalGuiWidth := totalReqW + (this.MarginX * 2)
        if (this.HasProp("MinWidth") && finalGuiWidth < this.MinWidth)
            finalGuiWidth := this.MinWidth
        if (finalGuiWidth > this.MaxWidth)
            finalGuiWidth := this.MaxWidth

        contentWidth := finalGuiWidth - (this.MarginX * 2)

        colWidths := Map()
        distributedW := 0
        loop maxCol {
            if (A_Index == maxCol) {
                colWidths[A_Index] := contentWidth - distributedW
            } else {
                cw := Integer(contentWidth * (reqColW[A_Index] / totalReqW))
                colWidths[A_Index] := cw
                distributedW += cw
            }
        }

        rowHeights := Map()
        loop maxRow
            rowHeights[A_Index] := 0

        progressBarH := this.ProgressBarHeight

        for cell in this.Cells {
            colKey := colWidths.Has(cell.Col) ? cell.Col : 1
            cellW := (cell.ColSpan >= maxCol) ? contentWidth : colWidths[colKey]

            if (cell.Type == "Image") {
                dims := this.GetImageDims(cell.Path, cell.TargetH)
                cell.ComputedW := dims.W
                cell.ComputedH := dims.H
                if (cell.RowSpan == 1 && rowHeights.Has(cell.Row) && dims.H > rowHeights[cell.Row])
                    rowHeights[cell.Row] := dims.H

            } else if (cell.Type == "Progress") {
                cell.ComputedW := cellW
                cell.ComputedH := progressBarH
                if (rowHeights.Has(cell.Row) && progressBarH > rowHeights[cell.Row])
                    rowHeights[cell.Row] := progressBarH

            } else { 
                fName := (IsObject(cell.Style) && cell.Style.HasProp("FontName")) ? cell.Style.FontName : this.FontName
                fSize := (IsObject(cell.Style) && cell.Style.HasProp("FontSize")) ? cell.Style.FontSize : this.FontSize
                FWeight := (IsObject(cell.Style) && cell.Style.HasProp("FontWeight")) ? cell.Style.FontWeight : this.FontWeight
                bounds := this.CalculateTextSize(cell.Text, fName, fSize, FWeight, cellW)
                cell.ComputedW := bounds.W
                cell.ComputedH := bounds.H
                if (rowHeights.Has(cell.Row) && bounds.H > rowHeights[cell.Row])
                    rowHeights[cell.Row] := bounds.H
            }
        }

        for cell in this.Cells {
            if (cell.Type == "Image" && cell.RowSpan > 1) {
                totalRowsH := 0
                loop cell.RowSpan {
                    r := cell.Row + A_Index - 1
                    if (rowHeights.Has(r))
                        totalRowsH += rowHeights[r]
                }
                if (totalRowsH < cell.ComputedH) {
                    addPerRow := Ceil((cell.ComputedH - totalRowsH) / cell.RowSpan)
                    loop cell.RowSpan {
                        r := cell.Row + A_Index - 1
                        if (rowHeights.Has(r))
                            rowHeights[r] += addPerRow
                    }
                }
            }
        }

        rowY := Map()
        currentY := this.MarginY
        loop maxRow {
            r := A_Index
            rowY[r] := currentY
            if (rowHeights.Has(r))
                currentY += rowHeights[r] + this.RowGap
        }

        for idx, cell in this.Cells {
            colKey := colWidths.Has(cell.Col) ? cell.Col : 1

            if (cell.ColSpan >= maxCol) {
                cellX := this.MarginX
                cellW := contentWidth
            } else {
                currentOffsetX := 0
                loop cell.Col - 1 {
                    if (colWidths.Has(A_Index))
                        currentOffsetX += colWidths[A_Index]
                }
                cellX := this.MarginX + currentOffsetX
                cellW := colWidths[colKey]
            }

            if (!rowY.Has(cell.Row))
                continue
            cellY := rowY[cell.Row]

            if (cell.RowSpan > 1) {
                cellH := 0
                loop cell.RowSpan {
                    r := cell.Row + A_Index - 1
                    if (rowHeights.Has(r))
                        cellH += rowHeights[r] + (A_Index < cell.RowSpan ? this.RowGap : 0)
                }
            } else {
                cellH := rowHeights.Has(cell.Row) ? rowHeights[cell.Row] : 20
            }
            if (cellH < 1)
                cellH := 20

            alignOpt := cell.Align == "Right" ? "Right" : (cell.Align == "Center" ? "Center" : "Left")

            if (cell.Type == "Image") {
                imgX := cellX
                if (alignOpt == "Center") {
                    imgX := cellX + (cellW - cell.ComputedW) / 2
                } else if (alignOpt == "Right") {
                    imgX := cellX + cellW - cell.ComputedW
                }
                imgY := cellY + (cellH - cell.ComputedH) / 2
                if (cell.ComputedW > 0 && cell.ComputedH > 0) {
                    try ctrl := this.MyGui.AddPic("x" imgX " y" imgY " w" cell.ComputedW " h" cell.ComputedH " +BackgroundTrans", cell.Path)
                    this.CellCtrls[idx] := ctrl
                }

            } else if (cell.Type == "Progress") {
                pMin := cell.HasProp("Min") ? cell.Min : 0
                pMax := cell.HasProp("Max") ? cell.Max : this.ProgressMaxValue
                this.ProgressMin := pMin
                this.ProgressMax := pMax

                initVal := IsNumber(cell.Value) ? Integer(cell.Value) : pMin
                initVal := Max(pMin, Min(pMax, initVal))

                ; --- CUSTOM HEIGHT CORRECTION ---
                ; Pull custom height from class settings, otherwise default to 6 pixels
                barH := (this.HasProp("ProgressBarHeight") && this.ProgressBarHeight > 0) ? this.ProgressBarHeight : 6
                
                ; Calculate centered vertical offset relative to the row's total text height
                barY := cellY + (cellH - barH) / 2
                ; --------------------------------

                ctrl := this.MyGui.AddProgress(
                    "x" cellX " y" barY " w" cellW " h" barH
                    " Smooth Range" pMin "-" pMax,
                    initVal)

                this.ProgressCtrl := ctrl
                this.CellCtrls[idx] := ctrl

            } else {  
                fName := (IsObject(cell.Style) && cell.Style.HasProp("FontName")) ? cell.Style.FontName : this.FontName
                fSize := (IsObject(cell.Style) && cell.Style.HasProp("FontSize")) ? cell.Style.FontSize : this.FontSize
                FWeight := (IsObject(cell.Style) && cell.Style.HasProp("FontWeight")) ? cell.Style.FontWeight : this.FontWeight
                this.MyGui.SetFont("s" fSize " w" FWeight, fName)
                
                ; --- CUSTOM TEXT VERTICAL CENTERING ---
                ; Calculate centered vertical offset relative to the row's total height
                textY := cellY + (cellH - cell.ComputedH) / 2
                ; --------------------------------------

                ctrl := this.MyGui.AddText("x" cellX " y" textY " w" cellW " h" cell.ComputedH " +BackgroundTrans " alignOpt, cell.Text)
                this.CellCtrls[idx] := ctrl
            }
        }

        if (autoInsertedProgress)
            this.Cells.Pop()

        finalGuiHeight := currentY - this.RowGap + this.MarginY

        this.InternalState := "Ready"
        this.ApplyThemeColors()

        try this.MyGui.Show("w" finalGuiWidth " h" finalGuiHeight " Hide")

        guiWidth := finalGuiWidth
        guiHeight := finalGuiHeight
        try this.MyGui.GetPos(, , &guiWidth, &guiHeight)

        if OSDCustom.DWMCompatible {
            try {
                ncPolicy := Buffer(4, 0), NumPut("Int", 2, ncPolicy, 0)
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.MyGui.Hwnd, "UInt", 2, "Ptr", ncPolicy, "UInt", 4)
                cornerPreference := Buffer(4, 0), NumPut("Int", 2, cornerPreference, 0)
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.MyGui.Hwnd, "UInt", 33, "Ptr", cornerPreference, "UInt", 4)
                margins := Buffer(16, 0)
                NumPut("Int", 1, margins, 0), NumPut("Int", 1, margins, 4)
                NumPut("Int", 1, margins, 8), NumPut("Int", 1, margins, 12)
                DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", this.MyGui.Hwnd, "Ptr", margins)
            } catch {
            }
        } else if (this.RoundedCorners > 0) {
            try {
                hRgn := DllCall("Gdi32.dll\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", guiWidth, "Int", guiHeight, "Int", this.RoundedCorners, "Int", this.RoundedCorners, "Ptr")
                if (hRgn)
                    DllCall("User32.dll\SetWindowRgn", "Ptr", this.MyGui.Hwnd, "Ptr", hRgn, "Int", true)
            } catch {
            }
        }

        monLeft := 0, monTop := 0, monRight := 0, monBottom := 0
        targetMonIndex := 1
        if (StrLower(this.Monitor) == "auto") {
            activeWin := WinExist("A")
            if (activeWin)
                try targetMonIndex := this.GetMonitorFromWindow(activeWin)
        } else if (IsInteger(this.Monitor) && this.Monitor > 0 && this.Monitor <= MonitorGetCount()) {
            targetMonIndex := this.Monitor
        }

        try {
            MonitorGetWorkArea(targetMonIndex, &monLeft, &monTop, &monRight, &monBottom)
        } catch {
            MonitorGetWorkArea(1, &monLeft, &monTop, &monRight, &monBottom)
        }

        monWidth := monRight - monLeft
        monHeight := monBottom - monTop
        targetX := monLeft + (monWidth * 0.5)
        targetY := monTop + (monHeight * 0.5)
        if RegExMatch(Position, "i)x([\d\.]+)", &matchX) {
            targetX := monLeft + (monWidth * Float(matchX[1]))
        }
        if RegExMatch(Position, "i)y([\d\.]+)", &matchY) {
            targetY := monTop + (monHeight * Float(matchY[1]))
        }

        this.PosX := Max(monLeft, Min(targetX - Integer(guiWidth / 2), monRight - guiWidth))
        this.FinalY := Max(monTop, Min(targetY - Integer(guiHeight / 2), monBottom - guiHeight))
        this.IsBottomHalf := (this.FinalY >= (monTop + (monHeight / 2) - guiHeight / 2))
        this.StartY := this.IsBottomHalf ? (this.FinalY + this.SlideDistance) : (this.FinalY - this.SlideDistance)
        this.AlphaStep := this.Opacity / (this.SlideDistance / this.Speed)

        hwnd := this.MyGui.Hwnd
        if (this.State == "Hidden" || this.State == "SlidingOut") {
            this.CurrentY := this.StartY
            this.CurrentAlpha := 0
            try WinSetTransparent(0, hwnd)
            try DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", -1, "Int", this.PosX, "Int", this.CurrentY, "Int", 0, "Int", 0, "UInt", 0x0051)
            this.State := "SlidingIn"
            this.TargetDuration := TimeOut
            SetTimer(this.SlideInCb, 5)
        } else {
            this.CurrentY := this.FinalY
            this.CurrentAlpha := this.Opacity
            try WinSetTransparent(Integer(this.Opacity), hwnd)
            try DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", -1, "Int", this.PosX, "Int", this.CurrentY, "Int", 0, "Int", 0, "UInt", 0x0051)
            this.State := "Visible"
            if (TimeOut > 0)
                SetTimer(this.DestroyCb, -TimeOut)
        }
        Critical("Off")
    }

    ; --- Update methods ---

    UpdateProgress(newValue, TimeOut := "") {
        if (this.InternalState != "Ready")
            return

        this.ProgressValue := newValue
        if (TimeOut == "")
            TimeOut := this.TimeOut

        try {
            if (this.MyGui && this.ProgressCtrl && (this.State == "Visible" || this.State == "SlidingIn")) {
                SetTimer(this.DestroyCb, 0)
                this.ProgressCtrl.Value := newValue

                if (IsNumber(newValue)) {
                    resolvedFg := this.GetCurrentThemeColor("ProgressFg")
                    pMax := this.HasProp("ProgressMax") ? this.ProgressMax : this.ProgressMaxValue
                    
                    if (newValue > pMax)
                        resolvedFg := this.GetCurrentThemeColor("ProgressOver100")

                    if (!this.HasProp("LastProgressFg") || this.LastProgressFg != resolvedFg) {
                        this.LastProgressFg := resolvedFg
                        try this.ProgressCtrl.Opt("c" resolvedFg)
                    }
                }

                if (TimeOut > 0)
                    SetTimer(this.DestroyCb, -TimeOut)
            }
        } catch {
        }
    }

    UpdateProgressObject(progressObj, newValue, TimeOut := "") {
        if (this.InternalState != "Ready")
            return

        progressObj.Value := newValue

        if (TimeOut == "")
            TimeOut := this.TimeOut

        for idx, cell in this.Cells {
            if (cell == progressObj) {
                try {
                    if (this.MyGui && this.CellCtrls.Has(idx) && (this.State == "Visible" || this.State == "SlidingIn")) {
                        SetTimer(this.DestroyCb, 0)
                        
                        this.CellCtrls[idx].Value := newValue

                        if (IsNumber(newValue)) {
                            resolvedFg := this.GetCurrentThemeColor("ProgressFg")
                            pMax := progressObj.Max
                            
                            if (newValue > pMax)
                                resolvedFg := this.GetCurrentThemeColor("ProgressOver100")

                            if (!this.HasProp("LastProgressFg") || this.LastProgressFg != resolvedFg) {
                                this.LastProgressFg := resolvedFg
                                try this.CellCtrls[idx].Opt("c" resolvedFg)
                            }
                        }

                        if (TimeOut > 0)
                            SetTimer(this.DestroyCb, -TimeOut)
                    }
                } catch {
                }
                break
            }
        }
    }

    UpdateImageObject(imageObj, newImagePath, TimeOut := "") {
        if (this.InternalState != "Ready")
            return
        if (!FileExist(newImagePath))
            throw Error("Image file not found: " newImagePath)
            
        imageObj.Path := newImagePath
        if (TimeOut == "")
            TimeOut := this.TimeOut

        for idx, cell in this.Cells {
            if (cell == imageObj) {
                try {
                    if (this.MyGui && this.CellCtrls.Has(idx) && (this.State == "Visible" || this.State == "SlidingIn")) {
                        SetTimer(this.DestroyCb, 0)
                        
                        this.CellCtrls[idx].Value := newImagePath
                        
                        if (TimeOut > 0)
                            SetTimer(this.DestroyCb, -TimeOut)
                    }
                } catch {
                }
                break
            }
        }
    }

    UpdateTextObject(cellObj, newText, TimeOut := "") {
        if (this.InternalState != "Ready")
            return

        ; Update the internal object's text property automatically
        cellObj.Text := newText

        if (TimeOut == "")
            TimeOut := this.TimeOut

        for idx, cell in this.Cells {
            if (cell == cellObj) {
                try {
                    if (this.MyGui && this.CellCtrls.Has(idx) && (this.State == "Visible" || this.State == "SlidingIn")) {
                        SetTimer(this.DestroyCb, 0)
                        
                        ; Push the text directly into the Win32 control
                        this.CellCtrls[idx].Value := newText
                        
                        if (TimeOut !== "")
                            SetTimer(this.DestroyCb, -TimeOut)
                    }
                } catch {
                }
                break
            }
        }
    }

    UpdateText(col, row, newText, TimeOut := "") {
        if (this.InternalState != "Ready")
            return

        for idx, cell in this.Cells {
            if (cell.Row == row && cell.Col == col) {
                cell.Text := newText
                try {
                    if (this.MyGui && this.CellCtrls.Has(idx) && (this.State == "Visible" || this.State == "SlidingIn")) {
                        SetTimer(this.DestroyCb, 0)
                        this.CellCtrls[idx].Value := newText
                        if (TimeOut !== "")
                            SetTimer(this.DestroyCb, -TimeOut)
                    }
                } catch {
                }
                break
            }
        }
    }

    ; --- Helpers & Parsers ---

    static ParseRange(input, fallbackMax := 100) {
        minV := 0, maxV := fallbackMax
        if IsObject(input) {
            if (input.HasProp("Min") && input.HasProp("Max"))
                minV := Integer(input.Min), maxV := Integer(input.Max)
            else if (input.Has(1) && input.Has(2))
                minV := Integer(input[1]), maxV := Integer(input[2])
        } else if (input !== "") {
            if RegExMatch(String(input), "^\s*(-?\d+)\s*-\s*(-?\d+)\s*$", &m) {
                minV := Integer(m[1]), maxV := Integer(m[2])
            } else if IsNumber(input) {
                maxV := Integer(input)
            }
        }
        return { Min: Min(minV, maxV), Max: Max(minV, maxV) }
    }

    GetMonitorFromWindow(hwnd) {
        if (!hwnd)
            return 1
        try {
            hMonitor := DllCall("User32.dll\MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr")
            if (!hMonitor)
                return 1
            loop MonitorGetCount() {
                if (this.GetMonitorHandle(A_Index) == hMonitor)
                    return A_Index
            }
        } catch {
            return 1
        }
        return 1
    }

    GetMonitorHandle(monitorIndex) {
        try {
            MonitorGet(monitorIndex, &mLeft, &mTop, &mRight, &mBottom)
            rc := Buffer(16, 0)
            NumPut("Int", mLeft, rc, 0), NumPut("Int", mTop, rc, 4)
            NumPut("Int", mRight, rc, 8), NumPut("Int", mBottom, rc, 12)
            return DllCall("User32.dll\MonitorFromRect", "Ptr", rc, "UInt", 1, "Ptr")
        } catch {
            return 0
        }
    }

    CalculateTextSize(text, fontName, fontSize, fontWeight, maxW) {
        try {
            hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
            if (!hdc)
                return { W: maxW, H: 20 }

            logPixelsY := DllCall("GetDeviceCaps", "Ptr", hdc, "Int", 90)
            if (!logPixelsY)
                logPixelsY := 96

            hFont := DllCall("CreateFont",
                "Int", -DllCall("MulDiv", "Int", fontSize, "Int", logPixelsY, "Int", 72),
                "Int", 0, "Int", 0, "Int", 0, "Int", fontWeight,
                "UInt", 0, "UInt", 0, "UInt", 0,
                "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0,
                "Str", fontName, "Ptr")

            if (!hFont) {
                DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
                return { W: maxW, H: 20 }
            }

            obm := DllCall("SelectObject", "Ptr", hdc, "Ptr", hFont, "Ptr")
            RECT := Buffer(16, 0), NumPut("Int", maxW, RECT, 8)
            DllCall("User32.dll\DrawText", "Ptr", hdc, "Str", text, "Int", -1, "Ptr", RECT, "UInt", 0x450)
            DllCall("SelectObject", "Ptr", hdc, "Ptr", obm)
            DllCall("DeleteObject", "Ptr", hFont)
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
            return { W: NumGet(RECT, 8, "Int") - NumGet(RECT, 0, "Int"),
                H: NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int") }
        } catch {
            return { W: maxW, H: 20 }
        }
    }

    GetImageDims(imagePath, targetH) {
        try {
            if (!OSDCustom.pToken)
                return { W: targetH, H: targetH }

            pImage := 0
            DllCall("gdiplus\GdipLoadImageFromFile", "Str", imagePath, "Ptr*", &pImage)
            if (!pImage)
                return { W: targetH, H: targetH }

            imgW := 0, imgH := 0
            DllCall("gdiplus\GdipGetImageWidth", "Ptr", pImage, "UInt*", &imgW)
            DllCall("gdiplus\GdipGetImageHeight", "Ptr", pImage, "UInt*", &imgH)
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pImage)

            if (imgW > 0 && imgH > 0)
                return { W: Round(targetH * (imgW / imgH)), H: targetH }
        } catch {
            return { W: targetH, H: targetH }
        }
        return { W: targetH, H: targetH }
    }

    AnimateSlideIn() {
        Critical("On")
        if (this.InternalState != "Ready")
            return
        try {
            if (!this.MyGui) {
                SetTimer(this.SlideInCb, 0)
                return
            }
            hwnd := this.MyGui.Hwnd
            if (!hwnd) {
                SetTimer(this.SlideInCb, 0)
                return
            }

            reachedTarget := false
            if (this.IsBottomHalf) {
                this.CurrentY -= this.Speed
                if (this.CurrentY <= this.FinalY) {
                    this.CurrentY := this.FinalY
                    reachedTarget := true
                }
            } else {
                this.CurrentY += this.Speed
                if (this.CurrentY >= this.FinalY) {
                    this.CurrentY := this.FinalY
                    reachedTarget := true
                }
            }

            this.CurrentAlpha := Min(this.Opacity, this.CurrentAlpha + this.AlphaStep)
            WinSetTransparent(Integer(this.CurrentAlpha), hwnd)
            DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", -1, "Int", this.PosX, "Int", this.CurrentY, "Int", 0, "Int", 0, "UInt", 0x0051)

            if (reachedTarget) {
                SetTimer(this.SlideInCb, 0)
                this.State := "Visible"
                WinSetTransparent(this.Opacity == 255 ? "" : this.Opacity, hwnd)
                if (this.TargetDuration > 0)
                    SetTimer(this.DestroyCb, -this.TargetDuration)
            }
        } catch {
            SetTimer(this.SlideInCb, 0)
        }
    }

    AnimateSlideOut() {
        Critical("On")
        if (this.InternalState != "Ready")
            return
        try {
            if (!this.MyGui) {
                SetTimer(this.SlideOutCb, 0)
                return
            }
            hwnd := this.MyGui.Hwnd
            if (!hwnd) {
                SetTimer(this.SlideOutCb, 0)
                return
            }

            reachedTarget := false
            if (this.IsBottomHalf) {
                this.CurrentY += this.Speed
                if (this.CurrentY >= this.StartY) {
                    this.CurrentY := this.StartY
                    reachedTarget := true
                }
            } else {
                this.CurrentY -= this.Speed
                if (this.CurrentY <= this.StartY) {
                    this.CurrentY := this.StartY
                    reachedTarget := true
                }
            }

            this.CurrentAlpha := Max(0, this.CurrentAlpha - this.AlphaStep)
            WinSetTransparent(Integer(this.CurrentAlpha), hwnd)
            DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", -1, "Int", this.PosX, "Int", this.CurrentY, "Int", 0, "Int", 0, "UInt", 0x0051)

            if (reachedTarget) {
                SetTimer(this.SlideOutCb, 0)
                this.MyGui.Hide()
                this.State := "Hidden"
            }
        } catch {
            SetTimer(this.SlideOutCb, 0)
        }
    }

    IsVisible {
        get => (this.State == "Visible" || this.State == "SlidingIn")
    }

    Destroy() {
        Critical("On")
        this.InternalState := "Destroying"

        SetTimer(this.DestroyCb, 0)
        SetTimer(this.SlideInCb, 0)
        SetTimer(this.SlideOutCb, 0)

        if (this.State == "Visible" || this.State == "SlidingIn") {
            this.State := "SlidingOut"
            this.InternalState := "Ready"
            SetTimer(this.SlideOutCb, 5)
        } else if (this.State == "Hidden" && this.MyGui) {
            try this.MyGui.Hide()
            this.InternalState := "Ready"
        } else {
            this.InternalState := "Ready"
        }
        Critical("Off")
    }
}

/*
* EXAMPLES



ThemeIcon := A_ScriptDir "\windowstheme7.ico"
ShieldIcon := A_ScriptDir "\shield.png"

MyOSD1 := OSDCustom("My First OSD in Light Mode")
MyOSD1.Theme := "Light"
MyOSD2 := OSDCustom("Another OSD with default settings")
MyOSD3 := OSDCustom()


#F4:: {
    MyOSD1.ClearCells()
    MyOSD2.ClearCells()
    MyOSD3.ClearCells()

    MyOSD1.SetCellImage(1, 1, ThemeIcon, "Left", 80,1,3)
    MyOSD1.SetCellText(2, 1, "`nThis is Title 1", "Left",{ FontSize: 13, FontWeight: 1000 })
    MyOSD1.SetCellText(2, 2, "This is a description`nArtist:`tBethoven`nTrack:`tMoonlight Sonata", "Left",,,)
    MyOSD1.SetCellText(2, 3, " ", "Left",{ FontSize: 1},,)



    MyOSD2.SetCellImage(1, 1, ThemeIcon, "Left", 80,1,4)
    MyOSD2.SetCellText(2, 1, "  ", "Left",{ FontSize: 1})
    MyOSD2.SetCellText(2, 2, "This is Title 2", "Left",{ FontSize: 13, FontWeight: 700 })
    MyOSD2.SetCellText(2, 3, "This is a description`nArtist:`tBethoven`nTrack:`tMoonlight Sonata", "Left", { FontSize: 11},,)
    MyOSD2.SetCellText(2, 4, " ", "Left",{ FontSize: 1},,)
 

    MyOSD3.SetCellImage(1, 1, ThemeIcon, "Left", 80,1,4)
    MyOSD3.SetCellText(2, 2, "This is Title 3", "Left",{ FontSize: 16, FontWeight: 500 })
    MyOSD3.SetCellText(2, 3, "This is a description`nArtist:`tBethoven`nTrack:`tMoonlight Sonata", "Left", { FontSize: 11},,)
    MyOSD3.SetCellText(2, 4, " ", "Left",{ FontSize: 1},,)



    MyOSD1.Show("x0.75 y0.35",5000)
    MyOSD2.Show("x0.75 y0.5",5000)
    MyOSD3.Show("x0.75 y0.65",5000)
}

; ------------------------------------------------------------------------------
; HOTKEY: Win + F5 -> Example 1: Basic Modern Handshake Notification
; ------------------------------------------------------------------------------
#f5:: {
    secondstocount := 3000
    starttime := A_TickCount
    
    MyOSD2.ClearCells()
    MyOSD2.SetCellText(1, 1, "SYSTEM SERVICE INITIALIZED", "Center", { FontSize: 13, FontName: "Segoe UI", FontWeight: 700, ColorLight: "aa00c0", ColorDark: "ea4cff" })
    MyOSD2.SetCellText(1, 2, "Verifying local security handshake...", "Center", { FontSize: 10 })

    MyProgress1 := MyOSD2.SetCellProgress(1, 3, 0,, secondstocount)
    TimeElapsed := MyOSD2.SetCellText(1, 4, "Time elapsed: 0s",, { FontSize: 7 })
    MyProgress2 := MyOSD2.SetCellProgress(1, 6, 2500,, secondstocount)
    
    MyOSD2.Show(, 0)
    
    While (A_TickCount < starttime + secondstocount) {
        CurrentProgress := (A_TickCount - starttime)
        
        ; Both follow the uniform structure: (object, newValue, timeOut)
        MyOSD2.UpdateProgressObject(MyProgress1, CurrentProgress, 0)
        MyOSD2.UpdateProgressObject(MyProgress2, 500, 0)
        MyOSD2.UpdateTextObject(TimeElapsed, "Time elapsed: " . (CurrentProgress // 1000) . " seconds", 0)
        
        Sleep(100)
    }
    
    MyOSD2.UpdateText(1, 2, "Verification done.")
    MyOSD2.UpdateTextObject(TimeElapsed, "Time elapsed: " . (secondstocount // 1000) . " seconds", 2000)
    MyOSD2.UpdateProgressObject(MyProgress1, secondstocount)
    MyOSD2.UpdateProgressObject(MyProgress2, secondstocount, 2000)
}

; ------------------------------------------------------------------------------
; HOTKEY: Win + F6 -> Example 2: Fixed 3-Column Asset Download (No wrapping!)
; ------------------------------------------------------------------------------
#f6:: {
    MyOSD2.ClearCells() ; brand new, not keeping previous cells

    ; Column 1: Primary Action Status Labels
    MyOSD2.SetCellText(1, 1, "DOWNLOADING ASSETS", "Left", { FontSize: 13, FontName: "Segoe UI Semibold" }, 3)

    ; Column 2: File Cache Details (Placed adjacent to column 1 to prevent text wrap)
    MyOSD2.SetCellText(1, 2, "File:", "Left", { FontSize: 10, ColorLight: "0067C0", ColorDark: "4CC2FF" })
    MyOSD2.SetCellText(2, 2, "shaders_compiled.cache", "Left", { FontSize: 10, ColorLight: "0067C0", ColorDark: "4CC2FF" })

    ; Column 3: Graphic icon spanning rows 1-2
    if FileExist(ShieldIcon) {
        MyOSD2.SetCellImage(3, 1, ShieldIcon, "Right", 56, 1, 2)
    }

    ; Row 3: Pre-defined status cells so UpdateCellText works during the loop
    MyOSD2.SetCellText(1, 3, "Speed: -- MB/s", "Left", { FontSize: 10 })
    MyOSD2.SetCellText(2, 3, "Progress: 0%", "Right", { FontSize: 10 }, 3)

    ; Progress bar at row 4, spanning all 3 columns
    MyOSD2.SetCellProgress(1, 4, 0, 3)

    MyOSD2.Show("x0.50 y0.80", 0)

    Loop 10 {
        CurrentProgress := A_Index * 10
        CurrentSpeed := Round(50 + Random(-5.0, 5.0), 1)

        MyOSD2.UpdateText(1, 3, "Speed: " CurrentSpeed " MB/s", 0)
        MyOSD2.UpdateText(2, 3, "Progress: " CurrentProgress "%", 0)
        MyOSD2.UpdateProgress(CurrentProgress, 0)
        Sleep(400)
    }

    MyOSD2.UpdateText(1, 3, "Assets synced successfully.", 2000)
    MyOSD2.UpdateText(2, 3, "", 2000)
    MyOSD2.UpdateProgress(100, 3000)
}

; ------------------------------------------------------------------------------
; HOTKEY: Win + F7 -> Example 3: Wide Split Layout Layout
; ------------------------------------------------------------------------------
#f7:: {
    MyOSD1.ClearCells()

    if FileExist(ShieldIcon) {
        MyOSD1.SetCellImage(1, 1, ShieldIcon, "Left", 54, 1, 3)
    }

    MyOSD1.SetCellText(2, 1, "SECURE DOWNLOAD ACTIVE", "Left", { FontSize: 11, FontName: "Segoe UI Semibold" })
    MyOSD1.SetCellText(2, 2, "File: shaders_compiled.cache", "Left", { FontSize: 10 })
    MyOSD1.SetCellText(2, 3, "Speed: 14.2 MB/s", "Left", { FontSize: 10 })

    ; Progress bar at row 4, between text and footer (spans both columns)
    MyOSD1.SetCellProgress(1, 4, 79, 2)

    MyOSD1.SetCellText(1, 5, "Press [Esc] to cancel background sync operations", "Center", { FontSize: 10 }, 2)
    MyOSD1.Show("x0.50 y0.30", 1500)
}

; ------------------------------------------------------------------------------
; HOTKEY: Win + F8 -> Example 4: Graphical HUD
; ------------------------------------------------------------------------------
#f8:: {
    MyOSD1.ClearCells()

    if FileExist(ThemeIcon) {
        MyOSD1.SetCellImage(1, 1, ThemeIcon, "Left", 24, 1, 1)
    }

;    MyOSD1.SetCellText(2, 1, "                                      ", "Left", { FontSize: 9 })
    MyOSD1.SetCellText(2, 1, "WINDOWS SECURITY COMPLIANCE", "Center", { FontSize: 11, FontWeight: 1000 })
    MyOSD1.SetCellText(3, 1, "Verified SEC-ID", "Right", { FontSize: 7 })
    MyOSD1.SetCellText(1, 2, "Environment state matches all DWM kernel policies.", "Left", { FontSize: 10 }, 4)
    MyOSD1.Show("x0.85 y1", 3000)
}

; ------------------------------------------------------------------------------
; HOTKEY: Volume Up / Down -> Example 5: Windows OSD for Audio Volume
; ------------------------------------------------------------------------------
VolumeOSD := OSDCustom("Volume OSD")
VolumeOSD.MinWidth := 195
VolumeOSD.Speed := 2.3
VolumeOSD.MarginX := 16
VolumeOSD.MarginY := 14
VolumeOSD.TextDefaultLight  := "000000"
VolumeOSD.ProgressFgLight := "0067C0"
VolumeOSD.ProgressBgLight := "89898A"
VolumeOSD.TextDefaultDark  := "FFFFFF"
VolumeOSD.ProgressFgDark  := "4CC2FF"
VolumeOSD.ProgressBgDark  := "9F9F9F"
VolumeOSD.ProgressBarHeight := 5
VolumeOSD.Opacity := 255
VolumeOSD.Position := "x0.50 y0.91"
VolumeOSD.TimeOut := 1775

; Start the controls
VolIconObj :=       VolumeOSD.SetCellText(1, 1, " ", "Left", { FontSize: 14, FontWeight: 500 })
DummyCell:=         VolumeOSD.SetCellText(2, 1, "                                                                                ", "Center", { FontSize: 1})
VolTextObj :=       VolumeOSD.SetCellText(3, 1, " ", "Right", { FontSize: 10, FontWeight: 500 })
VolProgressObj :=   VolumeOSD.SetCellProgress(2, 1, 100,,,1)

e66 := "🔊"
e33 := "🔉"
e0 := "🔈"
em := "🔇"

; 2. Bind the volume hotkeys
~Volume_Up::UpdateVolumeOSD()
~Volume_Down::UpdateVolumeOSD()
~Volume_Mute::UpdateVolumeOSD()

UpdateVolumeOSD() {
    sleep(10)
    currentVol := Round(SoundGetVolume())
    
    switch {
        case (currentVol >= 66):
            VolumeOSD.UpdateTextObject(VolIconObj, e66)
        case (currentVol >= 33):
            VolumeOSD.UpdateTextObject(VolIconObj, e33)
        case (currentVol > 0):
            VolumeOSD.UpdateTextObject(VolIconObj, e0)
        default:
            VolumeOSD.UpdateTextObject(VolIconObj, em)
    }
    
    VolumeOSD.UpdateProgressObject(VolProgressObj, currentVol)
    VolumeOSD.UpdateTextObject(VolTextObj, currentVol, 2000)

    if !(VolumeOSD.IsVisible) {
        VolumeOSD.Show()
    }
}

; ------------------------------------------------------------------------------
; HOTKEY: #F3 -> Example 6: Update image
; ------------------------------------------------------------------------------
; Initialize OSD Layout structure once at script startup
Global StatusOSD := OSDCustom("Status Panel")
StatusOSD.Theme := "Dark"

; Pre-build a layout grid:
; Column 1, Row 1, Spanning 1 Column and 2 Rows
Global MyImageObj := StatusOSD.SetCellImage(1, 1, ThemeIcon, "Center", 64, 1, 2)

; Column 2, Rows 1 and 2 for labels
Global TitleObj   := StatusOSD.SetCellText(2, 1, "SYSTEM STATUS", "Left", { FontSize: 12, FontWeight: 700 })
Global StateObj   := StatusOSD.SetCellText(2, 2, "SECURITY: LOCKED", "Left", { FontSize: 10 })

#F3:: {
    ; First-time open
    if (!StatusOSD.IsVisible) {
        StatusOSD.Show("x0.50 y0.85", 2000)
        return
    }
    
    ; Toggle states completely flicker-free on subsequent presses
    if (MyImageObj.Path == ThemeIcon) {
        StatusOSD.UpdateImageObject(MyImageObj, ShieldIcon, 2000)
        StatusOSD.UpdateTextObject(StateObj, "SECURITY: UNLOCKED", 2000)
    } else {
        StatusOSD.UpdateImageObject(MyImageObj, ThemeIcon, 2000)
        StatusOSD.UpdateTextObject(StateObj, "SECURITY: LOCKED", 2000)
    }
}

*/