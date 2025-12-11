#NoEnv
#Persistent
SetBatchLines, -1

; Force AHK to create a window so A_ScriptHwnd becomes valid
Gui, +LastFound
Gui, Show, Hide
hwnd := WinExist()

;======================================================
;  Create overlay GUI
;======================================================
Gui, 2:+AlwaysOnTop +ToolWindow -Caption +E0x20
Gui, 2:Color, 000000
Gui, 2:Font, c00FF00 s12, Consolas
Gui, 2:Add, Text, vOut w300 h60, Initializing...
Gui, 2:Show, x20 y20 NoActivate

;======================================================
;  Register RawInput correctly
;======================================================
RIDEV_INPUTSINK := 0x00000100
RIM_TYPEMOUSE := 0x01

VarSetCapacity(RID, 8*3, 0)
NumPut(RIM_TYPEMOUSE, RID, 0, "UShort") ; UsagePage = 1
NumPut(2,            RID, 2, "UShort") ; Usage = 2 (mouse)
NumPut(RIDEV_INPUTSINK, RID, 4, "UInt")
NumPut(hwnd,           RID, 8, "UInt") ; must be hwnd of our script's window!

if !DllCall("RegisterRawInputDevices", "ptr", &RID, "uint", 1, "uint", 8*3)
{
    MsgBox, Failed to register RawInput.
    ExitApp
}

; Now that hwnd is guaranteed valid, hook the message
OnMessage(0x00FF, "WM_INPUT")  ; WM_INPUT = 0xFF


;======================================================
;  WM_INPUT handler
;======================================================
WM_INPUT(wParam, lParam)
{
    static RID_HEADER_SIZE := 24

    ; Get raw input size
    VarSetCapacity(rawSize, 4, 0)
    DllCall("GetRawInputData", "ptr", lParam, "uint", 0x10000003
        , "ptr", 0, "ptr*", rawSize, "uint", RID_HEADER_SIZE)

    VarSetCapacity(raw, rawSize, 0)

    ; Get actual raw data
    DllCall("GetRawInputData", "ptr", lParam, "uint", 0x10000003
        , "ptr", &raw, "ptr*", rawSize, "uint", RID_HEADER_SIZE)

    offset := 24

    ; Extract values
    lLastX := NumGet(raw, offset + 8,  "Int")
    lLastY := NumGet(raw, offset + 12, "Int")
    usFlags := NumGet(raw, offset + 0, "UShort")

    text := "RawInput Mouse Movement`nΔX: " lLastX "`nΔY: " lLastY "`nFlags: " usFlags

    GuiControl, 2:, Out, %text%
}

Esc::ExitApp
