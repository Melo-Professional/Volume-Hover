/************************************************************************
 * @description Reload passing a dynamic call with a parameter
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/13
 * @version 1.0.0
 ***********************************************************************/


ReloadWithArgs(callerName := "", paramValue := "") {
    argString := ""
    if (callerName != "") {
        argString .= ' "' callerName '"'
        if (paramValue != "") {
            argString .= ' "' paramValue '"'
        }
    }

    OnMessage(0x020A, OnMouseWheel, 0)
    OnMessage(0x404,  OnTrayMessage, 0)
    OnMessage(0x0006, WM_ACTIVATE, 0)
    OnMessage(0x0115, WM_VSCROLL, 0)

    if A_IsCompiled {
        Run('"' A_ScriptFullPath '" /restart' argString)
    } else {
        Run('"' A_AhkPath '" /restart "' A_ScriptFullPath '"' argString)
    }
    ExitApp()
}

; CHECK RELOAD ARGUMENTS
if (A_Args.Length > 0) {
    targetFuncName := A_Args[1]
    if !A_IsCompiled && Debug
        ToolTip("reload with args " A_Args[1])
    try {
        if (A_Args.Length >= 2) {
            %targetFuncName%(A_Args[2])
        } else {
            %targetFuncName%()
        }
    } catch Any as e {
        ;MsgBoxCustom("Failed to execute dynamic call: " e.Message, App.Name)
        MsgBoxCustom(,,,e)
    }
}