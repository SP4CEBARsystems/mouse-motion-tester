#NoEnv
#Persistent
#SingleInstance Force
SetBatchLines, -1
SetWinDelay, 0
CoordMode, Mouse, Screen

; =========================
; State
; =========================
global lastX := "", lastY := ""
global lastTime := ""
global lastVelocity := 0
global stoppedSince := 0
global released := false

; =========================
; Tunables (adjust!)
; =========================
MOVE_THRESHOLD      := 0.05   ; px/ms — ignore micro jitter
STOP_THRESHOLD      := 0.01   ; px/ms
DECEL_THRESHOLD     := -0.02  ; px/ms²
RELEASE_HOLD_MS     := 15     ; how long cursor must stay stopped

Gui, +AlwaysOnTop +ToolWindow -Caption +E0x20
Gui, Color, 000000
; Gui, Font, c00FF00 s11, Consolas
; Gui, Add, Text, vOutText w380 h140, Loading...
Gui, Add, Picture, x0 y0 w400 h150 hwndhPic
Gui, Show, x20 y20 NoActivate

; --- Graph settings ---
graphW := 400
graphH := 150
x := 0
plotValue := 0

; --- GDI setup ---
hDC := DllCall("GetDC", "ptr", hPic, "ptr")
hPen := DllCall("CreatePen", "int", 0, "int", 1, "uint", 0x00FF00, "ptr")
DllCall("SelectObject", "ptr", hDC, "ptr", hPen)

; plotSpeed := 30
plotSpeed := 1
SetTimer, Plot, %plotSpeed%
return

; SetTimer, TrackMouse, 1
; Return

GuiClose:
    DllCall("DeleteObject", "ptr", hPen)
    DllCall("ReleaseDC", "ptr", hPic, "ptr", hDC)
    ExitApp

Plot:
    ; global plotValue
    ; Simulated data (replace with real values)
    ; value := 10
    ; value := plotValue
    ; MouseGetPos, mx, my
    ; value := my
    value := TrackMouse()

    ; y := graphH - value
    y := 0.5 * graphH - value

    ; Draw pixel
    DllCall("MoveToEx", "ptr", hDC, "int", x, "int", y, "ptr", 0)
    DllCall("LineTo",   "ptr", hDC, "int", x+1, "int", y)

    x++

    ; Reset when reaching edge
    if (x >= graphW)
    {
        x := 0
        DllCall("PatBlt"
            , "ptr", hDC
            , "int", 0, "int", 0
            , "int", graphW, "int", graphH
            , "uint", 0x00A000C9) ; BLACKNESS
    }
return

TrackMouse() {
    global plotValue
    MouseGetPos, x, y
    now := A_TickCount

    if (lastX = "")
    {
        lastX := x
        lastY := y
        lastTime := now
        Return
    }

    dx := x - lastX
    dy := y - lastY
    dt := now - lastTime
    if (dt <= 0)
        dt := 1

    dist := Sqrt(dx*dx + dy*dy)
    velocity := dist / dt
    acceleration := (velocity - lastVelocity) / dt

    ; =========================
    ; Release detection
    ; =========================
    if (velocity < STOP_THRESHOLD)
    {
        if (!stoppedSince)
            stoppedSince := now

        if ((now - stoppedSince >= RELEASE_HOLD_MS)
            && lastVelocity > MOVE_THRESHOLD
            && acceleration < DECEL_THRESHOLD)
        {
            released := true
        }
    }
    else
    {
        stoppedSince := 0
        released := false
    }

    ; myIsReleased := abs(acceleration) > 0.001
    myIsReleased := acceleration < -1
    ; status := released ? "RELEASED" : "MOVING"
    status := myIsReleased ? "RELEASED" : ""
    plotValue := y
    ; plotValue := acceleration

    ; text := "X: " x "`nY: " y "`nΔX: " dx "`nΔY: " dy "`nVelocity: " Round(velocity, 4) " px/ms Accel:   " Round(acceleration, 4) " px/ms²`nStatus: " status
    text := status "`nA:" Round(acceleration, 4)

    ; GuiControl,, OutText, %text%

    lastX := x
    lastY := y
    lastTime := now
    lastVelocity := velocity
    return velocity
    return acceleration * 100
    ; return y
}
; Return

Esc::
ExitApp
