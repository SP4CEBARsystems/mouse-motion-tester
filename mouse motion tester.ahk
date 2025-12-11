#NoEnv
#Persistent
SetBatchLines, -1

;================================================================
;  Create a GUI overlay to show precise RawInput mouse deltas
;================================================================
Gui, +AlwaysOnTop +ToolWindow -Caption +E0x20
Gui, Color, 000000
Gui, Font, c00FF00 s12, Consolas
Gui, Add, Text, vOut w300 h100, Initializing...
Gui, Show, x20 y20 NoActivate

;================================================================
;  Register Raw Input (mouse)
;================================================================
RIDEV_INPUTSINK := 0x00000100
RIM_TYPEMOUSE := 0

VarSetCapacity(RAWINPUTDEVICE, 8 * 3, 0)
NumPut(RIM_TYPEMOUSE, RAWINPUTDEVICE, 0, "UShort")   ; usUsagePage=1?
NumPut(2, RAWINPUTDEVICE, 2, "UShort")               ; usUsage=2 (mouse)
NumPut(RIDEV_INPUTSINK, RAWINPUTDEVICE, 4, "UInt")   ; Flags
NumPut(A_ScriptHwnd, RAWINPUTDEVICE, 8, "UInt")      ; Target hwnd

DllCall("RegisterRawInputDevices", "Ptr", &RAWINPUTDEVICE, "UInt", 1, "UInt", 8*3)

;================================================================
;  Message handler for Raw Input
;================================================================
OnMessage(0x00FF, "WM_INPUT")  ; WM_INPUT = 0x00FF
return


WM_INPUT(wParam, lParam)
{
    MsgBox, "Raw input detected"
    
    static RID_HEADER_SIZE := 24

    ; Query raw input size
    VarSetCapacity(rawSize, 4, 0)
    DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003  ; RID_INPUT
        , "Ptr", 0, "Ptr*", rawSize, "UInt", RID_HEADER_SIZE)

    VarSetCapacity(raw, rawSize, 0)

    ; Get actual raw mouse data
    DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000003
        , "Ptr", &raw, "Ptr*", rawSize, "UInt", RID_HEADER_SIZE)

    ; RAWINPUT structure:
    ; header at 0–23
    ; mouse data begins at offset 24

    offset := 24

    usFlags := NumGet(raw, offset+0, "UShort")
    usButtonFlags := NumGet(raw, offset+4, "UShort")
    lLastX := NumGet(raw, offset+8, "Int")
    lLastY := NumGet(raw, offset+12, "Int")

    ; Show the data
    
    text := "RawInput Mouse Movement`nΔX: " lLastX "`nΔY: " lLastY "`nFlags: " usFlags

    GuiControl,, Out, %text%
}

Esc::ExitApp
