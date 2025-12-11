#NoEnv
#Persistent
SetBatchLines, -1
SetWinDelay, 0
CoordMode, Mouse, Screen

global lastX := 0, lastY := 0

Gui, +AlwaysOnTop +ToolWindow -Caption +E0x20
Gui, Color, 000000
Gui, Font, c00FF00 s12, Consolas
Gui, Add, Text, vOutText w300 h100, Loading...
Gui, Show, x20 y20 NoActivate

SetTimer, TrackMouse, 1
Return

TrackMouse:
    MouseGetPos, x, y

    if (lastX = "")
    {
        lastX := x
        lastY := y
    }

    dx := x - lastX
    dy := y - lastY

    ; Show precise floating values
    text := "X: " x "`nY: " y "`nΔX: " dx "`nΔY: " dy

    GuiControl,, OutText, %text%

    lastX := x
    lastY := y
Return

Esc::
ExitApp
