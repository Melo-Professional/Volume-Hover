/************************************************************************
 * @description OnMessages Manager
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/16
 * @version 1.0.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

class MessageManager {
    static Registry := Map() ; Key: MsgNumber, Value: Array of Callback Functions

    ; Added 'RunBefore' parameter (defaults to false)
    static Register(MsgNumber, Callback, RunBefore := false) {
        if !this.Registry.Has(MsgNumber) {
            this.Registry[MsgNumber] := []
            
            ; When registering the manager itself with AHK, we use -1 
            ; so our manager interceptor runs before other external libraries
            OnMessage(MsgNumber, this.Dispatch.Bind(this), -1)
        }
        
        ; Avoid duplicates
        for registeredCallback in this.Registry[MsgNumber] {
            if registeredCallback == Callback
                return
        }
        
        ; If RunBefore is true, put it at the start of the queue. 
        ; Otherwise, append it to the end.
        if RunBefore
            this.Registry[MsgNumber].InsertAt(1, Callback)
        else
            this.Registry[MsgNumber].Push(Callback)
    }


    ; Unregister a function when a GUI or feature turns off
    static Unregister(MsgNumber, Callback) {
        if !this.Registry.Has(MsgNumber)
            return

        callbacks := this.Registry[MsgNumber]
        for index, registeredCallback in callbacks {
            if registeredCallback == Callback {
                callbacks.RemoveAt(index)
                break
            }
        }

        ; If no one is listening anymore, clean up the global OnMessage
        if callbacks.Length == 0 {
            this.Registry.Delete(MsgNumber)
            
            ; CORRECT V2 METHOD: 
            ; We must pass the exact bound dispatcher function object and '0' to unregister.
            OnMessage(MsgNumber, this.Dispatch.Bind(this), 0) 
        }
    }

    ; The central hub that routes incoming messages to all active subscribers
    static Dispatch(wParam, lParam, msg, hwnd) {
        if !this.Registry.Has(msg)
            return
        
        for callback in this.Registry[msg] {
            try {
                result := callback(wParam, lParam, msg, hwnd)
                
                ; If callback returned an array starting with "STOP", 
                ; we halt the loop and return the second value to the OS.
                if (result is Array && result.Length > 0 && result[1] == "STOP") {
                    return result[2]
                }
            } catch Error as err {
                OutputDebug("Error: " err.Message)
            }
        }
    }
}