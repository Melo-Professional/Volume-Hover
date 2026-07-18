#Requires AutoHotkey v2.0
; ======================================================================================================================
; OD_Colors    Enable user-defined text and background colors for DDL and ListBox controls as well as
;              individual items.
; AHK version: 2.0 (U64)
; Tested on:   Win 10 Pro x64
; Version:     1.0.00/2024-10-06/just me
; License:     The Unlicense (https://unlicense.org/)
; MSDN:        https://learn.microsoft.com/en-us/windows/win32/controls/create-an-owner-drawn-list-box
; ======================================================================================================================
; How to use:  
;     To initialize the class call OD_Colors.Init() once before you create owner drawn controls.
;
;     If you change the Gui font using Gui.SetFont() before you create the controls, call OD_Colors.SetFont() 
;     with corresponding options. The parameter FontOptions muust always contain all changed options.
; 
;     Now you can create the controls by adding 
;        +0x0210 (CBS_OWNERDRAWFIXED = 0x0010, CBS_HASSTRINGS = 0x0200) to the DDL options resp.
;        +0x0050 (LBS_OWNERDRAWFIXED = 0x0010, LBS_HASSTRINGS = 0x0040) to the ListBox options.
;
;     Specify the colors in an object with the following structure
;        Colors := {CB: control background color, 
;                   CT: control text color,
;                   SB: selection background color,
;                   ST: selection text color,
;                   1: {B: item 1 background color, T: item 1 text color},
;                   5: ...
;                  }
;     and store the array in an added control property 'OwnerDraw':
;        GuiCtrl.OwnerDraw := Colors
;     If you omit the B and/or T keys, the control's default colors are used. You can change the color object
;     anytime you want. 
;     All colors must be HTML color names or RGB integer values (e.g. 0xRRGGBB).
; ======================================================================================================================
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from the use of this software.
; ======================================================================================================================

/* 

; 1. Initialize the custom drawing class
OD_Colors.Init()

; --- Configuration Options ---
FontOptions := "Norm s12"
FontName := "Segoe UI"
OD_Colors.SetFont(FontOptions, FontName)

; Set custom row height in pixels
RowHeight := 32

; 2. Create the GUI and tell Windows to treat this window as "Dark Mode"
Win := Gui(, "Custom Styled DDL")
Win.BackColor := "1E1E1E" 
Win.SetFont(FontOptions, FontName)

; Off-screen edit control to prevent initial focus blue highlight
Dummy := Win.AddEdit("w0 h0 x-10 y-10")

; DropDownList Options
; +0x0210 activates Owner-Draw
; We remove -Theme to let Windows render the container using the native dark style
OD_DDL := " +0x0210"
Items := ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5", "Option 6", "Option 7", "Option 8"]

; 'r8' matches the item count perfectly to avoid scrollbar tracking
DDL := Win.AddDDL("xm w200 r20 Choose3" . OD_DDL, Items)

; Define custom colors
DDL.OwnerDraw := {
    CB: 0x202020,  ; Medium Gray background
    CT: 0xFFFFFF,  ; White text
    SB: 0x0055D4,  ; Darker Blue highlight on hover
    ST: 0xFFFFFF   ; White text on hover
}

; 3. Apply the native Windows Dark Mode theme to the dropdown container.
; This instantly converts the white borders and white dropdown backgrounds to a sleek dark color!
DllCall("uxtheme\SetWindowTheme", "Ptr", DDL.Hwnd, "Str", "DarkMode_CFD", "Ptr", 0)

; 4. Set custom spacing/height
SendMessage(0x0153, -1, RowHeight, DDL.Hwnd) ; Main closed box height
SendMessage(0x0153, 0, RowHeight, DDL.Hwnd)  ; Expanded item heights

; Force focus away on selection change to remove sticky blue highlights
DDL.OnEvent("Change", (ctrl, *) => Dummy.Focus())

Win.Show()
 */

Class OD_Colors {
   Static Call(*) => False
   Static Font := 0
   ; ===================================================================================================================
   ; Enable the message handlers and set the default font 
   ; ===================================================================================================================
   Static Init() {
      Static IsInitialized  := False,
             WM_DRAWITEM    := 0x002B,
             Draw := ObjBindMethod(OD_Colors, "DrawItem"),
             WM_MEASUREITEM := 0x002C,
             Measure := ObjBindMethod(OD_Colors, "MeasureItem")
      If !IsInitialized {
         OnMessage(WM_MEASUREITEM, Measure)
         OnMessage(WM_DRAWITEM, Draw)
         OD_Colors.SetFont()
         IsInitialized := True
      }
   }
   ; ===================================================================================================================
   ; Set the font used to calculate the item height in OD_Colors.MeasureItem()
   ; Parameters:
   ;     FontOptions -  font options like Gui.SetFont(Options, ...) or a HFONT handle
   ;     FontName    -  font name like Gui.SetFont(..., Name)
   ;                    If you pass a fnt handle in FontOptions FontName must be omitted.
   ;     If both parameters are omitted, the Gui default font is set.
   ; ===================================================================================================================
   Static SetFont(FontOptions?, FontName?) {
      Local Font := 0
      If !IsSet(FontName) && IsSet(FontOptions) && IsInteger(FontOptions) && 
         (DllCall("GetObjectType", "Ptr", FontOptions, "UInt") = 6) ; OBJ_FONT = 6
         Font :=FontOptions
      Else
         Font := CreateGuiFont(FontOptions?, FontName?)
      OD_Colors.Font := Font
      Return True
      ; ----------------------------------------------------------------------------------------------------------------
      ; CreateGuiFont() -  Create the font which will be used to calculate the item height of the ownwer-drawn control.
      ; ----------------------------------------------------------------------------------------------------------------
      CreateGuiFont(FntOpts := "", FntName := "") {
         Static HDEF := DllCall("GetStockObject", "Int", 17, "UPtr") ; DEFAULT_GUI_FONT
         If (FntOpts = "") && (FntName = "")
            Return HDEF
         Local LOGFONTW := Buffer(92, 0)
         DllCall("GetObject", "Ptr", HDEF, "Int", 92, "Ptr", LOGFONTW)
         Local HDC := DllCall("GetDC", "Ptr", 0, "UInt")
         Local LOGPIXELSY := DllCall("GetDeviceCaps", "Ptr", HDC, "Int", 90, "Int")
         DllCall("ReleaseDC", "Ptr", HDC, "Ptr", 0)
         If (FntOpts != "") {
            Local Weight := 0
            For Opt In StrSplit(RegExReplace(Trim(FntOpts), "\s+", " "), " ") {
               Switch StrUpper(Opt) {
                  Case "BOLD":      Weight := (Weight = 0) ? 700 : Weight
                  Case "ITALIC":    NumPut("Char",  1, LOGFONTW, 20)
                  Case "UNDERLINE": NumPut("Char",  1, LOGFONTW, 21)
                  Case "STRIKE":    NumPut("Char",  1, LOGFONTW, 22)
                  Case "NORM":      Continue
                  Default:
                     O := StrUpper(SubStr(Opt, 1, 1))
                     V := SubStr(Opt, 2)
                     Switch O {
                        Case "C":
                           Continue ; ignore the color option
                        Case "Q":
                           If !IsInteger(V) || (Integer(V) < 0) || (Integer(V) > 5)
                              Throw ValueError("Option Q must be an integer between 0 and 5!", -1, V)
                           NumPut("Char", Integer(V), LOGFONTW, 26)
                        Case "S":
                           If !IsNumber(V) || (Number(V) < 1) || (Integer(V) > 255)
                              Throw ValueError("Option S must be a number between 1 and 255!", -1, V)
                           V := Integer(V + 0.5)
                           NumPut("Int", -Round(V * LOGPIXELSY / 72), LOGFONTW)
                        Case "W":
                           If !IsInteger(V) || (Integer(V) < 1) || (Integer(V) > 1000)
                              Throw ValueError("Option W must be an integer between 1 and 1000!", -1, V)
                           Weight := Integer(V) NumPut("Int", Integer(V), LOGFONTW, 16)
                        Default:
                           Throw ValueError("Invalid font option!", -1, Opt)
                  }
               }
               If (Weight)
                  NumPut("Int", Weight, LOGFONTW, 16)
            }
            NumPut("Char", 1, "Char", 4, "Char", 0, LOGFONTW, 23) ; DEFAULT_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS
            NumPut("Char", 0, LOGFONTW, 27) ; FF_DONTCARE
            If (FntName != "")
               StrPut(FntName, LOGFONTW.Ptr + 28, 32)
            Local HFONT := 0
            If !(HFONT := DllCall("CreateFontIndirectW", "Ptr", LOGFONTW, "UInt"))
               Throw OSError()
            Return HFONT
         }
      }
   }
   ; ===================================================================================================================
   ; WM_DRAWITEM message handler
   ; Sent to the parent window of an owner-drawn ListBox or ComboBox when a visual aspect of the control has changed.
   ; WM_DRAWITEM    -> https://learn.microsoft.com/en-us/windows/win32/controls/wm-drawitem
   ; DRAWITEMSTRUCT -> https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-drawitemstruct
   ; ===================================================================================================================
   Static DrawItem(W, L, M, H) {
      ; L / DRAWITEMSTRUCT offsets
      Static OffItem := 8, OffAction := OffItem + 4, OffState := OffAction + 4, OffHWND := OffState + A_PtrSize,
             OffDC := OffHWND + A_PtrSize, OffRECT := OffDC + A_PtrSize, OffData := OffRECT + 16
      ; Owner Draw Type
      Static ODT := {2: "LISTBOX", 3: "COMBOBOX"}
      ; Owner Draw Action
      Static ODA_DRAWENTIRE := 0x0001, ODA_SELECT := 0x0002, ODA_FOCUS := 0x0004
      ; Owner Draw State
      Static ODS_SELECTED := 0x0001, ODS_FOCUS := 0x0010
      ; Draw text format flags
      Static DT_Flags := 0x0124 ; DT_NOCLIP = 0x0100, DT_SINGLELINE = 0x20, DT_VCENTER = 0x04
      ; Default colors
      Static SelB := DllCall("GetSysColor", "Int", 13, "UInt") ; COLOR_HIGHLIGHT
      Static SelT := DllCall("GetSysColor", "Int", 14, "UInt") ; COLOR_HIGHLIGHTTEXT
      ; ----------------------------------------------------------------------------------------------------------------
      Critical(-1) ; may help in case of drawing issues
      Local HWND := NumGet(L, OffHWND, "UPtr")
      Local Type := NumGet(L, "UInt")
      Local Ctl := 0
      If (Ctl := GuiCtrlFromHwnd(HWND)) && Ctl.HasProp("OwnerDraw") && ODT.HasProp(Type) {
         Local OD := Ctl.OwnerDraw
         Local Item := NumGet(L, OffItem, "Int") + 1
         Local Action := NumGet(L, OffAction, "UInt")
         Local State := NumGet(L, OffState, "UInt")
         Local Selected := State & ODS_SELECTED
         Local HDC := NumGet(L, OffDC, "UPtr")
         Local RECT := L + OffRECT
         If (Action = ODA_FOCUS)
            Return True
         Local CtrlBgC := OD.HasProp("CB") ? BGR(OD.CB) : DllCall("Gdi32.dll\GetBkColor", "Ptr", HDC, "UInt")
         Local CtrlTxc := OD.HasProp("CT") ? BGR(OD.CT) : DllCall("Gdi32.dll\GetTextColor", "Ptr", HDC, "UInt") 
         Local BgC := OD.HasProp(Item) && OD.%Item%.HasProp("B") ? BGR(OD.%Item%.B) : CtrlBgC
         Local TxC := OD.HasProp(Item) && OD.%Item%.HasProp("T") ? BGR(OD.%Item%.T) : CtrlTxC
         If (State & ODS_SELECTED) {
            BgC := OD.HasProp("SB") ? BGR(OD.SB) : SelB
            TxC := OD.HasProp("ST") ? BGR(OD.ST) : SelT
         }
         Local Brush := DllCall("Gdi32.dll\CreateSolidBrush", "UInt", BgC, "UPtr")
         DllCall("User32.dll\FillRect", "Ptr", HDC, "Ptr", RECT, "Ptr", Brush)
         DllCall("Gdi32.dll\DeleteObject", "Ptr", Brush)
         Local Txt := ""
         If !(Item = 0) {
            Local TxtBuf := Buffer(2050, 0) ; up to 1024 characters
            SendMessage(Type = 2 ? 0x0189 : 0x0148, Item - 1, TxtBuf.Ptr, Ctl.Hwnd) ; LB_GETTEXT : CB_GETLBTEXT
            Txt := StrGet(TxtBuf.Ptr)
         }
         Len := StrLen(Txt)
         NumPut("Int", NumGet(RECT, "Int") + 2, RECT)
         DllCall("Gdi32.dll\SetBkMode", "Ptr", HDC, "Int", 1) ; TRANSPARENT
         DllCall("Gdi32.dll\SetTextColor", "Ptr", HDC, "UInt", TxC)
         DllCall("User32.dll\DrawTextW", "Ptr", HDC, "Ptr", StrPtr(Txt), "Int", Len, "Ptr", RECT, "UInt", DT_Flags)
         NumPut("Int", NumGet(RECT, "Int") - 2, RECT)
         ; If (State & ODS_SELECTED)
         ;    DllCall("User32.dll\DrawFocusRect", "Ptr", HDC, "Ptr", RECT)
         DllCall("Gdi32.dll\SetTextColor", "Ptr", HDC, "UInt", CtrlTxC)
         Return True
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; Converts a numeric RGB value or a HTML color name to BGR
      BGR(RGB) {
         Static HTML := {BLACK:  0x000000, SILVER: 0xC0C0C0, GRAY:   0x808080, WHITE:   0xFFFFFF
                       , MAROON: 0x000080, RED:    0x0000FF, PURPLE: 0x800080, FUCHSIA: 0xFF00FF
                       , GREEN:  0x008000, LIME:   0x00FF00, OLIVE:  0x008080, YELLOW:  0x00FFFF
                       , NAVY:   0x800000, BLUE:   0xFF0000, TEAL:   0x808000, AQUA:    0xFFFF00}
         Return HTML.HasProp(RGB) ? HTML.%RGB% : ((RGB & 0xFF0000) >> 16) | (RGB & 0x00FF00) | ((RGB & 0x0000FF) << 16)
      }
   }
   ; ===================================================================================================================
   ; WM_MEASUREITEM message callback
   ; Sent once to the parent window of an OWNERDRAWFIXED ListBox or ComboBox when an the control is being created.
   ; When the owner receives this message, the system has not yet determined the height and width of the font used
   ; in the control. That is why OD_Colors.ItemHeight must be set to an appropriate value before the control will be
   ; created by Gui, Add, ... You either might call 'OD_Colors.SetItemHeight' passing the current font options and
   ; name to calculate the value or set it manually.
   ; WM_MEASUREITEM    -> https://learn.microsoft.com/en-us/windows/win32/controls/wm-measureitem
   ; MEASUREITEMSTRUCT -> https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-measureitemstruct
   ; ===================================================================================================================
   Static MeasureItem(W, L, M, H) {
      ; L -> MEASUREITEMSTRUCT, Owner Draw Type: LISTBOX = 2, COMBOBOX = 3
      Local CtlType := NumGet(L, "UInt"),
            ItemID := NumGet(L, 8, "Int")
      If ((CtlType = 2) || (CtlType = 3)) && (ItemID < 1) {
         If !(DllCall("Gdi32.dll\GetObjectType", "Ptr", OD_Colors.Font, "UInt") = 6 ) ; OBJ_FONT = 6
            Throw Error("OD_Colors.Font isn't a valid GDI font object!", -1, OD_Colors.Font)
         Local HLB := DllCall("User32.dll\CreateWindowEx", "UInt", 0, "Str", "ListBox", "Ptr", 0, "UInt", 0x40000040,
                              "Int", 0, "Int", 0, "Int", 0, "Int", 0, "Ptr", A_ScriptHwnd, "Ptr", 0, "Ptr", 0, "Ptr", 0)
         SendMessage(0x0030, OD_Colors.Font, 1, HLB) ; WM_SETFONT
         Local ItemHeight := SendMessage(0x01A1, 0, 0, HLB) ; LB_GETITEMHEIGHT
         DllCall("DestroyWindow", "Ptr", HLB)
         NumPut("Int", ItemID = -1 ? ItemHeight + 2 : ItemHeight, L + 16) ; itemHeight  <<< changed 2025-11-25
         ; NumPut("Int", ItemHeight, L + 16) ; itemHeight
         Return True
      }
   }
}
