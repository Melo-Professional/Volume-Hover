#Requires AutoHotkey v2.0

global CLSID_MMDeviceEnumerator   := "{BCDE0395-E52F-467C-8E3D-C4579291692E}"
global IID_IMMDeviceEnumerator    := "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
global IID_IAudioSessionManager2  := "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}"
global IID_IAudioSessionControl2  := "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}"
global IID_ISimpleAudioVolume     := "{87CE5498-68D6-44E5-9215-6DA47EF883D8}"
global VolumeLogarithmic          := 1
global DeviceMap := Map()

PopulatePlaybackDevices() {
    global DeviceMap
    DeviceMap.Clear()
    deviceNames := []
    
    deviceEnum := ComObject(CLSID_MMDeviceEnumerator, IID_IMMDeviceEnumerator)
    ComCall(3, deviceEnum, "Int", 0, "UInt", 1, "Ptr*", &deviceCollection := 0)
    ComCall(3, deviceCollection, "UInt*", &deviceCount := 0)
    
    loop deviceCount {
        ComCall(4, deviceCollection, "UInt", A_Index - 1, "Ptr*", &device := 0)
        friendlyName := GetDeviceNameString(device)
        if (friendlyName == "") {
            friendlyName := "Unknown Device Line [" A_Index "]"
        }
        while DeviceMap.Has(friendlyName)
            friendlyName .= " "
            
        DeviceMap[friendlyName] := device
        deviceNames.Push(friendlyName)
    }
    return deviceNames
}

GetDeviceNameString(devicePtr) {
    ComCall(4, devicePtr, "UInt", 0, "Ptr*", &propertyStore := 0)
    propKey := Buffer(20, 0)
    DllCall("ole32\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "Ptr", propKey)
    NumPut("UInt", 14, propKey, 16) 
    
    varResult := Buffer(24, 0)
    ComCall(5, propertyStore, "Ptr", propKey, "Ptr", varResult)
    
    friendlyName := ""
    vt := NumGet(varResult, 0, "UShort")
    if (vt == 31) { 
        pStr := NumGet(varResult, 8, "Ptr")
        if (pStr != 0) {
            friendlyName := StrGet(pStr, "UTF-16")
            DllCall("ole32\CoTaskMemFree", "Ptr", pStr)
        }
    }
    ObjRelease(propertyStore)
    return friendlyName
}

GetDefaultDeviceFriendlyName() {
    try {
        deviceEnum := ComObject(CLSID_MMDeviceEnumerator, IID_IMMDeviceEnumerator)
        ComCall(4, deviceEnum, "Int", 0, "Int", 0, "Ptr*", &defaultDevice := 0)
        if (defaultDevice != 0) {
            name := GetDeviceNameString(defaultDevice)
            ObjRelease(defaultDevice)
            return name
        }
    }
    return ""
}

GetAudioSessionsForDevice(devicePtr) {
    sessions := []
    seenApps := Map()
    
    DllCall("ole32\CLSIDFromString", "Str", IID_IAudioSessionManager2, "Ptr", iidBuf := Buffer(16))
    hr := ComCall(3, devicePtr, "Ptr", iidBuf, "UInt", 23, "Ptr", 0, "Ptr*", &sessionManager := 0)
    if (hr != 0 || !sessionManager)
        return sessions
        
    ComCall(5, sessionManager, "Ptr*", &sessionEnum := 0)
    if (!sessionEnum)
        return sessions
        
    ComCall(3, sessionEnum, "Int*", &sessionCount := 0)
    
    loop sessionCount {
        ComCall(4, sessionEnum, "Int", A_Index - 1, "Ptr*", &sessionCtrl := 0)
        if !(sessionCtrl2 := ComObjQuery(sessionCtrl, IID_IAudioSessionControl2))
            continue
            
        ComCall(14, sessionCtrl2, "UInt*", &pid := 0)
        if (pid == 0 || !ProcessExist(pid))
            continue
            
        progName := ProcessGetName(pid)
        if seenApps.Has(progName)
            continue
        seenApps[progName] := true
        
        if !(simpleVol := ComObjQuery(sessionCtrl2, IID_ISimpleAudioVolume))
            continue
            
        ComCall(4, simpleVol, "Float*", &volScalar := 0)
        
        ; CONVERSION: Convert raw hardware scalar back to a perceived logarithmic slider UI value
        ;sliderUIVal := Round(Sqrt(volScalar) * 100)
        sliderUIVal := Round((volScalar ** VolumeLogarithmic) * 100)
        
        sessions.Push({
            PID: pid,
            ProgName: progName,
            Volume: sliderUIVal,
            SimpleVol: simpleVol
        })
    }
    return sessions
}

SetAppVolume(simpleVol, sliderPercent) {
    sliderPercent := Max(0, Min(100, sliderPercent))
    
    ; LOGARITHMIC FIX: Convert the UI Slider (0-100) to a perceived exponential curve
    ;scalarVol := (sliderPercent / 100.0) ** 2
    scalarVol := (sliderPercent / 100.0) ** (1 / VolumeLogarithmic)
    
    ComCall(3, simpleVol, "Float", scalarVol, "Ptr", 0)
}