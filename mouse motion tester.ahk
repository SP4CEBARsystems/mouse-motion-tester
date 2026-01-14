#NoEnv
#Persistent
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
Gui, Font, c00FF00 s11, Consolas
Gui, Add, Text, vOutText w380 h140, Loading...
Gui, Show, x20 y20 NoActivate

SetTimer, TrackMouse, 1
Return

TrackMouse:
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

    ; text := "X: " x "`nY: " y "`nΔX: " dx "`nΔY: " dy "`nVelocity: " Round(velocity, 4) " px/ms Accel:   " Round(acceleration, 4) " px/ms²`nStatus: " status
    text := status "`nA:" Round(acceleration, 4)
    ; text :=
    ; (
    ; X: %x%
    ; Y: %y%
    ; ΔX: %dx%
    ; ΔY: %dy%

    ; Velocity: % Round(velocity, 4) % px/ms
    ; Accel:    % Round(acceleration, 4) % px/ms²
    ; Status:   %status%
    ; )

    GuiControl,, OutText, %text%

    lastX := x
    lastY := y
    lastTime := now
    lastVelocity := velocity
Return

Esc::
ExitApp
