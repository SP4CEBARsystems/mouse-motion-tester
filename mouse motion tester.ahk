#NoEnv
#Persistent
SetBatchLines, -1

;======================================================
;  Create a real AHK window so A_ScriptHwnd becomes valid
;======================================================
Gui, +LastFound
Gui, Show, Hide
hwnd := WinExist()


;======================================================
;  GUI overlay for showing movement
;======================================================
Gui, 2:+AlwaysOnTop +ToolWindow -Caption +E0x20
Gui, 2:Color, 000000
Gui, 2:Font, c00FF00 s12, Consolas
Gui, 2:Add, Text, vOut w300 h100, Initializing...
Gui, 2:Show, x20 y20 NoActivate


;======================================================
;  Register RawInput using correct 12-byte struct
;======================================================
RIDEV_INPUTSINK := 0x00000100
UsagePage_Mouse := 1
Usage_Mouse := 2

VarSetCapacity(RID, 12, 0)
NumPut(UsagePage_Mouse, RID, 0, "UShort")
NumPut(Usage_Mouse,      RID, 2, "UShort")
NumPut(RIDEV_INPUTSINK,  RID, 4, "UInt")
NumPut(hwnd,              RID, 8, "UInt")   ; Valid window handle

if !DllCall("RegisterRawInputDevices", "ptr", &RID, "uint", 1, "uint", 12)
{
    MsgBox, Failed to register RawInput.
    ExitApp
}

OnMessage(0x00FF, "WM_INPUT")  ; WM_INPUT


;======================================================
;  WM_INPUT handler
;======================================================
WM_INPUT(wParam, lParam)
{
    static RID_HEADER_SIZE := 24

    ; Get required size
    VarSetCapacity(size, 4)
    DllCall("GetRawInputData"
        , "Ptr", lParam
        , "UInt", 0x10000003  ; RID_INPUT
        , "Ptr", 0
        , "Ptr*", size
        , "UInt", RID_HEADER_SIZE)

    VarSetCapacity(raw, size)
    DllCall("GetRawInputData"
        , "Ptr", lParam
        , "UInt", 0x10000003
        , "Ptr", &raw
        , "Ptr*", size
        , "UInt", RID_HEADER_SIZE)

    offset := 24  ; skip RAWINPUTHEADER

    dx := NumGet(raw, offset + 8, "Int")
    dy := NumGet(raw, offset + 12, "Int")
    flags := NumGet(raw, offset, "UShort")

    text := "RawInput Mouse Movement`nΔX: " lLastX "`nΔY: " lLastY "`nFlags: " usFlags

    GuiControl, 2:, Out, %text%
}

Esc::ExitApp
