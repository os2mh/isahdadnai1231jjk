DllCall("SetProcessDPIAware")
#NoEnv
#InstallMouseHook
#HotkeyInterval 1000
#MaxHotkeysPerInterval 200
#SingleInstance, Force
#Persistent
#InstallKeybdHook
#UseHook
#KeyHistory, 0
#HotKeyInterval 1
#MaxHotkeysPerInterval 127
CoordMode, Pixel, Screen, RGB
CoordMode, Mouse, Screen
PID := DllCall("GetCurrentProcessId")
Process, Priority, %PID%, High
OnMessage(0x204, "BlockRightClick")
pToken := Gdip_Startup()
global EmCol := 0xE600FF
global smoothing := 0.04
global predictionMultiplier := 2.5
global velocitySmoothing := 0.7
global minVelocityThreshold := 0.1
global adaptivePrediction := true
global maxPredictionStrength := 3.0
global velocityHistory := []
global maxHistorySize := 10
GuiVisible := true
FOVCircleColor := "0xFF00FF00"
AimFOVCircleColor := "0xFFFFFF00"
toggle := false
Paused := False
RecoilACC := 0
RecoilDR := 0.1
RecoilM := 10
RecoilMult := 1
global RecoilEnabled := false
global RecoilStrength := 50
global RecoilDL := 50
global RecoilActive := false
global RecoilY := 0
global MaxRecoil := 20
global RecoilRecoverySpeed := 0.95
global LastRecoilTime := 0
global AimFOV := 300
global ZeroX := A_ScreenWidth / 2
global ZeroY := A_ScreenHeight / 2.18
global TargetOffsetY := 0
global CustomOffsetX := 0
global CustomOffsetY := 0
global XStrengthMultiplier := 1.0
global YStrengthMultiplier := 1.0
global UseCustomOffsetX := false
global UseCustomOffsetY := false
ColVn := 30
global lastMoveX := 0
global lastMoveY := 0
global accelerationX := 0
global accelerationY := 0
global smoothingFactor := 0.35
global accelerationSmoothing := 0.4
global maxAcceleration := 2.0
global centerSpeedMultiplier := 1.00
global MinDistance := 50
global MaxDistance := 500
global SearchArea := 40
global BaseOffsetY := 75
global EnableAnimations := true
global MainGuiHwnd := 0
global AnimationType := "Fade"
global AnimationStep := 10
global GuiTitle := "OS AimAssist"
global WM_SETREDRAW := 0x0B
global lastFOV := 0
global lastAimFOV := 0
global lastZeroX := 0
global lastZeroY := 0
global DefaultToggleAimKey := "Insert"
global DefaultHideGUIKey := "Home"
global DefaultExitGUIKey := "\"
global DefaultAimKey1 := "RButton"
global DefaultAimKey2 := "RButton2"
global DefaultAimKey3 := "XButton3"
IniRead, SavedToggleAimKey, settings.ini, Hotkeys, ToggleAim, %DefaultToggleAimKey%
IniRead, SavedHideGUIKey, settings.ini, Hotkeys, HideGui, %DefaultHideGUIKey%
IniRead, SavedExitGUIKey, settings.ini, Hotkeys, ExitGUIKey, %DefaultExitGUIKey%
IniRead, SavedAimKey1, settings.ini, Hotkeys, AimKey1, %DefaultAimKey1%
IniRead, SavedAimKey2, settings.ini, Hotkeys, AimKey2, %DefaultAimKey2%
IniRead, SavedAimKey3, settings.ini, Hotkeys, AimKey3, %DefaultAimKey3%
global ToggleAimKey := SavedToggleAimKey
global HideGUIKey := SavedHideGUIKey
global ExitGUIKey := SavedExitGUIKey
global AimKey1 := SavedAimKey1
global AimKey2 := SavedAimKey2
global AimKey3 := SavedAimKey3
Gdip_Startup() {
if !DllCall("GetModuleHandle", "str", "gdiplus")
DllCall("LoadLibrary", "str", "gdiplus")
VarSetCapacity(si, 16, 0), si := Chr(1)
DllCall("gdiplus\GdiplusStartup", "uint*", pToken, "uint", &si, "uint", 0)
return pToken
}
Gdip_ExitGUI(pToken) {
DllCall("gdiplus\GdiplusExitGUI", "uint", pToken)
if hModule := DllCall("GetModuleHandle", "str", "gdiplus")
DllCall("FreeLibrary", "uint", hModule)
return 0
}
GetDC(hwnd=0) {
return DllCall("GetDC", "uint", hwnd)
}
ReleaseDC(hdc, hwnd=0) {
return DllCall("ReleaseDC", "uint", hwnd, "uint", hdc)
}
Gdip_GraphicsFromHDC(hDC) {
DllCall("gdiplus\GdipCreateFromHDC", "uint", hDC, "uint*", pGraphics)
return pGraphics
}
Gdip_DeleteGraphics(pGraphics) {
return DllCall("gdiplus\GdipDeleteGraphics", "uint", pGraphics)
}
Gdip_CreatePen(ARGB, w) {
DllCall("gdiplus\GdipCreatePen1", "int", ARGB, "float", w, "int", 2, "uint*", pPen)
return pPen
}
Gdip_DeletePen(pPen) {
return DllCall("gdiplus\GdipDeletePen", "uint", pPen)
}
Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h) {
return DllCall("gdiplus\GdipDrawEllipse", "uint", pGraphics, "uint", pPen
, "float", x, "float", y, "float", w, "float", h)
}
Gdip_SetSmoothingMode(pGraphics, SmoothingMode) {
return DllCall("gdiplus\GdipSetSmoothingMode", "uint", pGraphics, "int", SmoothingMode)
}
PID := DllCall("GetCurrentProcessId")
Process, Priority, %PID%, High
OnMessage(0x204, "BlockRightClick")
pToken := Gdip_Startup()
Width := 400
Height := 560
Gui, +LastFound -Caption +AlwaysOnTop -DPIScale -Border -Caption +ToolWindow
Gui, Color, 1A1A1A
Gui, Margin, 15, 15
WinSetTitle, %GuiTitle%
OriginalX := A_ScreenWidth-Width-20
OriginalY := 520
SafeX := (A_ScreenWidth - Width - 100)
SafeY := (A_ScreenHeight - Height - 100)
OriginalX := SafeX
OriginalY := SafeY
Gui, Font, s14 cFFFFFF Bold, Segoe UI
Gui, Add, Progress, x0 y0 w%Width% h40 Background2D2D2D Disabled
Gui, Add, Text, x0 y8 w%Width% h30 BackgroundTrans Center 0x200 gGuiMove vCaption, OS AimAssist
Gui, Font, s11 cFFFFFF, Segoe UI
Gui, Add, Tab3, % "x15 y50 w" . (Width-30) . " h" . (Height-120) . " vMainTab +Theme +0x8 Multi", Main|FOV|Aim|Advanced|Recoil|Offset|Strength|Target|Hotkeys|Resolution
Gui, Tab, 1
Gui, Font, s9 cFFFFFF, Segoe UI
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h70 c666666", Main Controls
Gui, Font, s9 cFFFFFF, Segoe UI
Gui, Add, CheckBox, % "x30 y140 w" . (Width-60) . " h20 vEnableCheckbox cFFFFFF", Aim Assist                                                                   [INS Key]
Gui, Add, CheckBox, % "x30 y165 w" . (Width-60) . " h20 vEnablePredictionCheckbox cFFFFFF", Aim Prediction
Gui, Add, GroupBox, % "x20 y200 w" . (Width-40) . " h110 c666666", Target Location
Gui, Add, Button, % "x30 y220 w" . ((Width-80)/2) . " h35 gHeadshotsButton", Head
Gui, Add, Button, % "x" . (Width/2 + 10) . " y220 w" . ((Width-80)/2) . " h35 gChestButton", Chest
Gui, Add, Button, % "x30 y260 w" . ((Width-80)/2) . " h35 gLegsButton", Legs
Gui, Add, Button, % "x" . (Width/2 + 10) . " y260 w" . ((Width-80)/2) . " h35 gFeetButton", Feet
Gui, Add, GroupBox, % "x20 y320 w" . (Width-40) . " h65 c666666", Target Color
Gui, Add, Text, % "x30 y340 w60 cFFFFFF", Hex Color:
Gui, Add, Edit, % "x95 y338 w80 vColorInput cBlack", E600FF
Gui, Add, Button, % "x185 y337 w" . (Width-215) . " h25 gUpdateColor", Update
Gui, Font, s14 c666666 Bold
Gui, Add, Text, % "x30 y423 w" . (Width-60) . " Center", Hide GUI: Home
Gui, Tab, 2
Gui, Font, s9 cFFFFFF, Segoe UI
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h140 c666666", FOV Control
Gui, Add, Text, % "x30 y145 w" . (Width-60) . " cFFFFFF", FOV Size:
Gui, Add, Slider, % "x30 y165 w" . (Width-60) . " vFOVSlider gUpdateFOV AltSubmit Range40-1000", 80
Gui, Add, Text, % "x30 y195 w50 cFFFFFF vFOVValue", 80
Gui, Add, CheckBox, % "x30 y220 w" . (Width-60) . " vFOVCircleCheckbox gToggleFOVCircle cFFFFFF", Show FOV Circle
Gui, Add, GroupBox, % "x20 y270 w" . (Width-40) . " h160 c666666", Aim FOV Control
Gui, Add, Text, % "x30 y295 w" . (Width-60) . " cFFFFFF", Aim FOV Size:
Gui, Add, Slider, % "x30 y315 w" . (Width-60) . " vAimFOVSlider gUpdateAimFOV AltSubmit Range40-1000", 175
Gui, Add, Text, % "x30 y340 w50 cFFFFFF vAimFOVValue", 175
Gui, Add, CheckBox, % "x30 y365 w" . (Width-60) . " vAimFOVEnabled cFFFFFF", Enable Aim FOV
Gui, Add, CheckBox, % "x30 y390 w" . (Width-60) . " vAimFOVCircleCheckbox gToggleAimFOVCircle cFFFFFF", Show Aim FOV Circle
Gui, Tab, 3
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h100 c666666", Smoothing Control
Gui, Add, Text, % "x30 y145 w" . (Width-60) . " cFFFFFF", Smoothing:
Gui, Add, Slider, % "x30 y165 w" . (Width-60) . " vSmoothingSlider gUpdateSmoothing AltSubmit Range0-100", 1
Gui, Add, Text, % "x30 y185 w80 cFFFFFF vSmoothingValue", 0.01
Gui, Add, GroupBox, % "x20 y230 w" . (Width-40) . " h100 c666666", Prediction Control
Gui, Add, Text, % "x30 y255 w" . (Width-60) . " cFFFFFF", Prediction Strength:
Gui, Add, Slider, % "x30 y275 w" . (Width-60) . " vPredictionSlider gUpdatePrediction AltSubmit Range0-400", 400
Gui, Add, Text, % "x30 y295 w80 cFFFFFF vPredictionValue", 4.00
Gui, Add, GroupBox, % "x20 y340 w" . (Width-40) . " h100 c666666", Center Speed Control
Gui, Add, Text, % "x30 y365 w" . (Width-60) . " cFFFFFF", Center Speed:
Gui, Add, Slider, % "x30 y385 w" . (Width-60) . " vCenterSpeedSlider gUpdateCenterSpeed AltSubmit Range1-1000", 200
Gui, Add, Text, % "x30 y405 w80 cFFFFFF vCenterSpeedValue", 2.00
Gui, Tab, 4
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h140 c666666", FOV Circle Colors
Gui, Add, Text, % "x30 y145 w120 cFFFFFF", Regular FOV Color:
Gui, Add, Edit, % "x155 y143 w80 vFOVColorInput cBlack", 00FF00
Gui, Add, Button, % "x240 y142 w60 h23 gUpdateFOVColor", Update
Gui, Add, Text, % "x30 y175 w120 cFFFFFF", Aim FOV Color:
Gui, Add, Edit, % "x155 y173 w80 vAimFOVColorInput cBlack", FFFF00
Gui, Add, Button, % "x240 y172 w60 h23 gUpdateAimFOVColor", Update
Gui, Add, GroupBox, % "x20 y270 w" . (Width-40) . " h140 c666666", Config Management
Gui, Add, Button, % "x30 y305 w" . ((Width-60)/2) . " h75 gSaveCurrentConfig", Save Config
Gui, Add, Button, % "x" . (Width/2) . " y305 w" . ((Width-60)/2) . " h75 gLoadSavedConfig", Load Config
Gui, Add, GroupBox, % "x20 y420 w" . (Width-40) . " h50 c666666", Animation Settings
Gui, Add, CheckBox, % "x30 y440 w" . (Width-60) . " vEnableAnimationsCheckbox gToggleAnimations Checked cFFFFFF", Enable Fade Animation
Gui, Tab, 5
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h190 c666666", Recoil Control
Gui, Add, Text, % "x30 y145 w" . (Width-60) . " cFFFFFF", Recoil Strength:
Gui, Add, Slider, % "x30 y165 w" . (Width-60) . " vRecoilStrengthSlider gUpdateRecoil AltSubmit Range0-100", 50
Gui, Add, Text, % "x30 y195 w50 cFFFFFF vRecoilValue", 50
Gui, Add, Text, % "x30 y215 w" . (Width-60) . " cFFFFFF", Recoil Speed:
Gui, Add, Slider, % "x30 y235 w" . (Width-60) . " vRecoilDLSlider gUpdateRecoilDL AltSubmit Range0-100", 50
Gui, Add, Text, % "x30 y265 w50 cFFFFFF vRecoilDLValue", 50
Gui, Add, CheckBox, % "x30 y285 w" . (Width-60) . " vRecoilEnabled gToggleRecoil cFFFFFF", Enable No Recoil
Gui, Tab, 6
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h170 c666666", Custom Offset Controls
Gui, Add, Text, % "x30 y145 w" . (Width-60) . " cFFFFFF", X Offset:
Gui, Add, Slider, % "x30 y165 w" . (Width-120) . " vOffsetSliderX gUpdateOffsetX AltSubmit Range-1000-1000", 0
Gui, Add, Text, % "x" . (Width-80) . " y165 w40 cFFFFFF vOffsetValueX", 0
Gui, Add, CheckBox, % "x30 y195 w" . (Width-60) . " vEnableCustomOffsetX gToggleCustomOffsetX cFFFFFF", Enable Custom X Offset
Gui, Add, Text, % "x30 y220 w" . (Width-60) . " cFFFFFF", Y Offset:
Gui, Add, Slider, % "x30 y240 w" . (Width-120) . " vOffsetSliderY gUpdateOffsetY AltSubmit Range-1000-1000", 0
Gui, Add, Text, % "x" . (Width-80) . " y240 w40 cFFFFFF vOffsetValueY", 0
Gui, Add, CheckBox, % "x30 y270 w" . (Width-60) . " vEnableCustomOffsetY gToggleCustomOffsetY cFFFFFF", Enable Custom Y Offset
Gui, Tab, 7
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h170 c666666", Aim Strength Control
Gui, Add, Text, % "x30 y145 w" . (Width-60) . " cFFFFFF", X Strength Multiplier:
Gui, Add, Slider, % "x30 y165 w" . (Width-60) . " vXStrengthSlider gUpdateXStrength AltSubmit Range0-400", 250
Gui, Add, Text, % "x30 y185 w50 cFFFFFF vXStrengthValue", 2.50
Gui, Add, Text, % "x30 y215 w" . (Width-60) . " cFFFFFF", Y Strength Multiplier:
Gui, Add, Slider, % "x30 y235 w" . (Width-60) . " vYStrengthSlider gUpdateYStrength AltSubmit Range0-400", 200
Gui, Add, Text, % "x30 y255 w50 cFFFFFF vYStrengthValue", 2.00
Gui, Tab, 8
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h320 c666666", Target Offset Controls
Gui, Add, Text, % "x30 y145 w" . (Width-60) . " cFFFFFF", Head Offset (Default: 75):
Gui, Add, Slider, % "x30 y165 w" . (Width-120) . " vHeadOffsetSlider gUpdateHeadOffset AltSubmit Range-1000-1000", 75
Gui, Add, Text, % "x" . (Width-80) . " y165 w40 cFFFFFF vHeadOffsetValue", 75
Gui, Add, CheckBox, % "x30 y190 w" . (Width-60) . " vEnableHeadOffset gToggleHeadOffset cFFFFFF", Enable Custom Head Offset
Gui, Add, Text, % "x30 y215 w" . (Width-60) . " cFFFFFF", Chest Offset (Default: 154):
Gui, Add, Slider, % "x30 y235 w" . (Width-120) . " vChestOffsetSlider gUpdateChestOffset AltSubmit Range-1000-1000", 154
Gui, Add, Text, % "x" . (Width-80) . " y235 w40 cFFFFFF vChestOffsetValue", 154
Gui, Add, CheckBox, % "x30 y260 w" . (Width-60) . " vEnableChestOffset gToggleChestOffset cFFFFFF", Enable Custom Chest Offset
Gui, Add, Text, % "x30 y285 w" . (Width-60) . " cFFFFFF", Legs Offset (Default: 175):
Gui, Add, Slider, % "x30 y305 w" . (Width-120) . " vLegsOffsetSlider gUpdateLegsOffset AltSubmit Range-1000-1000", 175
Gui, Add, Text, % "x" . (Width-80) . " y305 w40 cFFFFFF vLegsOffsetValue", 175
Gui, Add, CheckBox, % "x30 y330 w" . (Width-60) . " vEnableLegsOffset gToggleLegsOffset cFFFFFF", Enable Custom Legs Offset
Gui, Add, Text, % "x30 y355 w" . (Width-60) . " cFFFFFF", Feet Offset (Default: 198):
Gui, Add, Slider, % "x30 y375 w" . (Width-120) . " vFeetOffsetSlider gUpdateFeetOffset AltSubmit Range-1000-1000", 198
Gui, Add, Text, % "x" . (Width-80) . " y375 w40 cFFFFFF vFeetOffsetValue", 198
Gui, Add, CheckBox, % "x30 y400 w" . (Width-60) . " vEnableFeetOffset gToggleFeetOffset cFFFFFF", Enable Custom Feet Offset
Gui, Add, Button, % "x30 y450 w" . (Width-60) . " h30 gSaveTargetOffsets", Save Target Offsets
Gui, Tab, 9
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h320 c666666", Hotkey Settings
Gui, Add, Text, % "x30 y145 w120 cFFFFFF", Toggle Aim Assist:
Gui, Add, Edit, % "x155 y143 w100 vToggleAimKey ReadOnly cFFFFFF", %SavedToggleAimKey%
Gui, Add, Button, % "x265 y142 w60 h23 gCaptureToggleAim", Change
Gui, Add, Text, % "x30 y175 w120 cFFFFFF", Hide GUI:
Gui, Add, Edit, % "x155 y173 w100 vHideGUIKey ReadOnly cFFFFFF", %SavedHideGUIKey%
Gui, Add, Button, % "x265 y172 w60 h23 gCaptureHideGUI", Change
Gui, Add, Text, % "x30 y205 w120 cFFFFFF", Exit GUI:
Gui, Add, Edit, % "x155 y203 w100 vExitGUIKey ReadOnly cFFFFFF", %SavedExitGUIKey%
Gui, Add, Button, % "x265 y202 w60 h23 gCaptureExitGUI", Change
Gui, Add, Text, % "x30 y245 w120 cFFFFFF", Aim Key 1:
Gui, Add, Edit, % "x155 y243 w100 vAimKey1 cBlack", %SavedAimKey1%
Gui, Add, Button, % "x265 y242 w60 h23 gCaptureAimKey1", Change
Gui, Add, Text, % "x30 y275 w120 cFFFFFF", Aim Key 2:
Gui, Add, Edit, % "x155 y273 w100 vAimKey2 cBlack", %SavedAimKey2%
Gui, Add, Button, % "x265 y272 w60 h23 gCaptureAimKey2", Change
Gui, Add, Text, % "x30 y305 w120 cFFFFFF", Aim Key 3:
Gui, Add, Edit, % "x155 y303 w100 vAimKey3 cBlack", %SavedAimKey3%
Gui, Add, Button, % "x265 y302 w60 h23 gCaptureAimKey3", Change
Gui, Add, Button, % "x30 y390 w" . ((Width-60)/2 - 5) . " h30 gSaveHotkeys", Save Hotkeys
Gui, Add, Button, % "x" . (30 + (Width-60)/2 + 5) . " y390 w" . ((Width-60)/2 - 5) . " h30 gResetHotkeys", Reset Hotkeys
Gui, Tab, 10
Gui, Add, GroupBox, % "x20 y120 w" . (Width-40) . " h200 c666666", Resolution Settings
Gui, Add, Text, % "x30 y145 w120 cFFFFFF", Select Resolution:
Gui, Add, DropDownList, % "x30 y165 w" . (Width-60) . " vResolutionSelect", 1024x768|1280x720|1280x800|1280x1024|1360x768|1366x768|1440x900|1600x900|1680x1050|1920x1080|1920x1200|2048x1152|2560x1080|2560x1440|3440x1440|3840x2160
Gui, Add, Button, % "x30 y205 w" . ((Width-80)/2) . " h30 gUpdateResolution", Update Resolution
Gui, Add, Button, % "x" . (Width/2 + 10) . " y205 w" . ((Width-80)/2) . " h30 gSaveResolution", Save Resolution
Gui, Add, Text, % "x30 y255 w" . (Width-60) . " cFFFFFF vCurrentResolution", Current Resolution: 2560x1440
Gui, Tab
Gui, Add, Progress, % "x15 y" . (Height-70) . " w" . (Width-20) . " h40 Background1A1A1A Disabled"
Gui, Font, s11 cD3D3D3
Gui, Add, Text, % "x" . (Width/4) . " y" . (Height-50) . " w" . (Width/2) . " cD3D3D3", Created by osamh
Gui, Font, s9 cFFFFFF Bold
Gui, Add, Button, % "x" . (Width-85) . " y" . (Height-60) . " w70 h40 gClose", Exit
WinSet, Region, 0-0 w%Width% h%Height% r8-8
Gui, Show, Hide
MainGuiHwnd := WinExist("A")
IniRead, savedResolution, settings.ini, Settings, Resolution, 2560x1440
if (savedResolution != "ERROR") {
GuiControl, Choose, ResolutionSelect, %savedResolution%
RegExMatch(savedResolution, "(\d+)x(\d+)", res)
ZeroX := res1 / 2
ZeroY := res2 / 2.18
GuiControl,, CurrentResolution, Current Resolution: %savedResolution%
}
Gui, Show, % "w" . Width . " h" . Height . " x" . SafeX . " y" . SafeY
Hotkey, % "$" . ExitGUIKey, ExitGUI, On
#If
Hotkey, $Insert, Toggle
Hotkey, $Home, GuiToggle
Hotkey, $\, ExitGUI
if !FileExist("settings.ini") {
try {
IniWrite, %DefaultToggleAimKey%, settings.ini, Hotkeys, ToggleAim
IniWrite, %DefaultHideGUIKey%, settings.ini, Hotkeys, HideGui
IniWrite, %DefaultExitGUIKey%, settings.ini, Hotkeys, ExitGUIKey
IniWrite, %DefaultAimKey1%, settings.ini, Hotkeys, AimKey1
IniWrite, %DefaultAimKey2%, settings.ini, Hotkeys, AimKey2
IniWrite, %DefaultAimKey3%, settings.ini, Hotkeys, AimKey3
IniWrite, 0xFF00FF00, settings.ini, Default, FOVCircleColor
IniWrite, 0xFFFFFF00, settings.ini, Default, AimFOVCircleColor
IniWrite, 95, settings.ini, Default, FOVSize
IniWrite, 300, settings.ini, Default, AimFOVSize
IniWrite, 0.05, settings.ini, Default, Smoothing
IniWrite, 0xE600FF, settings.ini, Default, TargetColor
IniWrite, Default Profile, settings.ini, Settings, DefaultConfig
IniWrite, 95, settings.ini, Default Profile, FOVSize
IniWrite, 300, settings.ini, Default Profile, AimFOVSize
IniWrite, 0.05, settings.ini, Default Profile, Smoothing
IniWrite, 0xE600FF, settings.ini, Default Profile, TargetColor
IniWrite, 1.0, settings.ini, Default Profile, XStrengthMultiplier
IniWrite, 1.0, settings.ini, Default Profile, YStrengthMultiplier
IniWrite, 50, settings.ini, Default Profile, RecoilStrength
IniWrite, 50, settings.ini, Default Profile, RecoilDL
IniWrite, 0, settings.ini, Default Profile, CustomOffsetX
IniWrite, 0, settings.ini, Default Profile, CustomOffsetY
IniWrite, 75, settings.ini, Default Profile, HeadOffset
IniWrite, 154, settings.ini, Default Profile, ChestOffset
IniWrite, 125, settings.ini, Default Profile, LegsOffset
IniWrite, 188, settings.ini, Default Profile, FeetOffset
} catch e {
MsgBox, 0x10, Error, Failed to create settings file.`nPlease run as administrator.
ExitApp
}
}
RefreshConfigList() {
global ConfigSelect
configs := ""
Loop, Read, settings.ini
{
if InStr(A_LoopReadLine, "[") && InStr(A_LoopReadLine, "]")
{
section := SubStr(A_LoopReadLine, 2, StrLen(A_LoopReadLine)-2)
if (section != "Settings" && section != "Hotkeys" && section != "Default")
configs .= section . "|"
}
}
GuiControl,, ConfigSelect, |%configs%
}
global CFovX := 95
global CFovY := 95
global ScanL := ZeroX - CFovX
global ScanT := ZeroY - CFovY
global ScanR := ZeroX + CFovX
global ScanB := ZeroY + CFovY
prevX := 0
prevY := 0
lastTime := 0
velocityX := 0
velocityY := 0
accelerationX := 0
accelerationY := 0
prevVelocityX := 0
prevVelocityY := 0
smoothedVelocityX := 0
smoothedVelocityY := 0
Loop {
GuiControlGet, EnableState,, EnableCheckbox
if (EnableState) {
targetFound := False
if (GetKeyState(AimKey1, "P") || GetKeyState(AimKey2, "P") || (AimKey3 != "None" && GetKeyState(AimKey3, "P"))) {
GuiControlGet, AimFOVState,, AimFOVEnabled
searchFOV := AimFOVState ? Max(CFovX, AimFOV) : CFovX
scanStartX := targetFound ? (targetX - SearchArea) : (ZeroX - searchFOV)
scanStartY := targetFound ? (targetY - SearchArea) : (ZeroY - searchFOV)
scanEndX := targetFound ? (targetX + SearchArea) : (ZeroX + searchFOV)
scanEndY := targetFound ? (targetY + SearchArea) : (ZeroY + searchFOV)
ErrorLevel := 0
Try {
PixelSearch, AimPixelX, AimPixelY, scanStartX, scanStartY, scanEndX, scanEndY, EMCol, ColVn, Fast RGB
} Catch e {
ErrorLevel := 1
}
if (!ErrorLevel) {
distanceFromCenter := Sqrt((AimPixelX - ZeroX)**2 + (AimPixelY - ZeroY)**2)
isInMainFOV := (distanceFromCenter <= CFovX)
isInAimFOV := (!AimFOVState || distanceFromCenter <= AimFOV)
if (isInMainFOV || (AimFOVState && isInAimFOV)) {
if (targetX && targetY) {
targetX := targetX * 0.6 + AimPixelX * 0.4
targetY := targetY * 0.6 + AimPixelY * 0.4
} else {
targetX := AimPixelX
targetY := AimPixelY
}
targetFound := True
currentTime := A_TickCount
deltaTime := (currentTime - lastTime) / 1000.0
if (deltaTime > 0.1)
deltaTime := 0.016
moveX := targetX - ZeroX
moveY := targetY - ZeroY
moveX *= centerSpeedMultiplier
moveY *= centerSpeedMultiplier
if (UseCustomOffsetX)
moveX += CustomOffsetX
if (UseCustomOffsetY)
moveY += CustomOffsetY + TargetOffsetY
moveX *= XStrengthMultiplier
moveY *= YStrengthMultiplier
GuiControlGet, PredictionEnabled,, EnablePredictionCheckbox
if (PredictionEnabled && lastTime != 0) {
rawVelocityX := (targetX - prevX) / deltaTime
rawVelocityY := (targetY - prevY) / deltaTime
rawVelocityX := Max(Min(rawVelocityX, 1000), -1000)
rawVelocityY := Max(Min(rawVelocityY, 1000), -1000)
velocityX := (velocityX * velocitySmoothing) + (rawVelocityX * (1 - velocitySmoothing))
velocityY := (velocityY * velocitySmoothing) + (rawVelocityY * (1 - velocitySmoothing))
if (velocityHistory.Length() >= maxHistorySize)
velocityHistory.RemoveAt(1)
velocityHistory.Push({x: velocityX, y: velocityY})
consistency := CalculateVelocityConsistency(velocityHistory)
currentPredictionStrength := predictionMultiplier * consistency
if (adaptivePrediction)
currentPredictionStrength := Min(currentPredictionStrength, maxPredictionStrength)
moveX += velocityX * currentPredictionStrength * deltaTime
moveY += velocityY * currentPredictionStrength * deltaTime
}
moveX *= smoothing
moveY *= smoothing
if (RecoilEnabled && RecoilActive) {
currentTime := A_TickCount
timeSinceLastRecoil := currentTime - LastRecoilTime
if (timeSinceLastRecoil > RecoilDL) {
RecoilY := Min(RecoilY + (RecoilStrength / 100), MaxRecoil)
moveY -= RecoilY
LastRecoilTime := currentTime
} else {
moveY -= RecoilY
}
RecoilY *= RecoilRecoverySpeed
}
prevX := targetX
prevY := targetY
lastTime := currentTime
DllCall("mouse_event", uint, 1, int, Round(moveX), int, Round(moveY), uint, 0, int, 0)
}
}
} else {
lastTime := 0
velocityX := 0
velocityY := 0
velocityHistory := []
targetX := 0
targetY := 0
prevX := 0
prevY := 0
RecoilY := 0
LastRecoilTime := 0
}
}
Sleep, 1
}
UpdateRecoil:
GuiControlGet, newStrength,, RecoilStrengthSlider
RecoilStrength := newStrength
GuiControl,, RecoilValue, %newStrength%
return
UpdateRecoilDL:
GuiControlGet, newDecay,, RecoilDLSlider
RecoilDL := newDecay
RecoilRecoverySpeed := 1 - (newDecay / 200)
GuiControl,, RecoilDLValue, %newDecay%
return
SaveCurrentConfig:
try {
GuiControlGet, enableAim,, EnableCheckbox
GuiControlGet, aimFovEnabled,, AimFOVEnabled
GuiControlGet, fovValue,, FOVSlider
GuiControlGet, aimFovValue,, AimFOVSlider
GuiControlGet, fovCircleEnabled,, FOVCircleCheckbox
GuiControlGet, aimFovCircleEnabled,, AimFOVCircleCheckbox
GuiControlGet, smoothingValue,, SmoothingSlider
GuiControlGet, predictionValue,, PredictionSlider
GuiControlGet, centerSpeedValue,, CenterSpeedSlider
GuiControlGet, enablePrediction,, EnablePredictionCheckbox
GuiControlGet, targetColor,, ColorInput
GuiControlGet, fovColor,, FOVColorInput
GuiControlGet, aimFovColor,, AimFOVColorInput
GuiControlGet, recoilStrength,, RecoilStrengthSlider
GuiControlGet, recoilDL,, RecoilDLSlider
GuiControlGet, recoilEnabled,, RecoilEnabled
GuiControlGet, offsetX,, OffsetSliderX
GuiControlGet, offsetY,, OffsetSliderY
GuiControlGet, customOffsetXEnabled,, EnableCustomOffsetX
GuiControlGet, customOffsetYEnabled,, EnableCustomOffsetY
GuiControlGet, xStrength,, XStrengthSlider
GuiControlGet, yStrength,, YStrengthSlider
GuiControlGet, headOffset,, HeadOffsetSlider
GuiControlGet, chestOffset,, ChestOffsetSlider
GuiControlGet, legsOffset,, LegsOffsetSlider
GuiControlGet, feetOffset,, FeetOffsetSlider
GuiControlGet, enableHeadOffset,, EnableHeadOffset
GuiControlGet, enableChestOffset,, EnableChestOffset
GuiControlGet, enableLegsOffset,, EnableLegsOffset
GuiControlGet, enableFeetOffset,, EnableFeetOffset
GuiControlGet, currentOffsetY,, OffsetSliderY
GuiControlGet, enableAnimations,, EnableAnimationsCheckbox
IniWrite, %currentOffsetY%, settings.ini, SavedConfig, CurrentTargetOffsetY
IniWrite, %TargetOffsetY%, settings.ini, SavedConfig, TargetOffsetY
IniWrite, %enableAim%, settings.ini, SavedConfig, EnableAim
IniWrite, %aimFovEnabled%, settings.ini, SavedConfig, AimFOVEnabled
IniWrite, %fovValue%, settings.ini, SavedConfig, FOVSize
IniWrite, %aimFovValue%, settings.ini, SavedConfig, AimFOVSize
IniWrite, %fovCircleEnabled%, settings.ini, SavedConfig, FOVCircleEnabled
IniWrite, %aimFovCircleEnabled%, settings.ini, SavedConfig, AimFOVCircleEnabled
IniWrite, %smoothingValue%, settings.ini, SavedConfig, Smoothing
IniWrite, %predictionValue%, settings.ini, SavedConfig, Prediction
IniWrite, %centerSpeedValue%, settings.ini, SavedConfig, CenterSpeed
IniWrite, %enablePrediction%, settings.ini, SavedConfig, PredictionEnabled
IniWrite, %targetColor%, settings.ini, SavedConfig, TargetColor
IniWrite, %fovColor%, settings.ini, SavedConfig, FOVColor
IniWrite, %aimFovColor%, settings.ini, SavedConfig, AimFOVColor
IniWrite, %recoilStrength%, settings.ini, SavedConfig, RecoilStrength
IniWrite, %recoilDL%, settings.ini, SavedConfig, RecoilDL
IniWrite, %recoilEnabled%, settings.ini, SavedConfig, RecoilEnabled
IniWrite, %offsetX%, settings.ini, SavedConfig, OffsetX
IniWrite, %offsetY%, settings.ini, SavedConfig, OffsetY
IniWrite, %customOffsetXEnabled%, settings.ini, SavedConfig, CustomOffsetXEnabled
IniWrite, %customOffsetYEnabled%, settings.ini, SavedConfig, CustomOffsetYEnabled
IniWrite, %xStrength%, settings.ini, SavedConfig, XStrength
IniWrite, %yStrength%, settings.ini, SavedConfig, YStrength
IniWrite, %headOffset%, settings.ini, SavedConfig, HeadOffset
IniWrite, %chestOffset%, settings.ini, SavedConfig, ChestOffset
IniWrite, %legsOffset%, settings.ini, SavedConfig, LegsOffset
IniWrite, %feetOffset%, settings.ini, SavedConfig, FeetOffset
IniWrite, %enableHeadOffset%, settings.ini, SavedConfig, EnableHeadOffset
IniWrite, %enableChestOffset%, settings.ini, SavedConfig, EnableChestOffset
IniWrite, %enableLegsOffset%, settings.ini, SavedConfig, EnableLegsOffset
IniWrite, %enableFeetOffset%, settings.ini, SavedConfig, EnableFeetOffset
IniWrite, %enableAnimations%, settings.ini, SavedConfig, EnableAnimations
MsgBox, 0x40, Success, Configuration saved successfully!
} catch e {
MsgBox, 0x10, Error, Failed to save configuration.`nError: %e%
}
return
LoadSavedConfig:
success := true
errorMsg := ""
try {
IniRead, savedTargetOffsetY, settings.ini, SavedConfig, TargetOffsetY, 75
IniRead, currentOffsetY, settings.ini, SavedConfig, CurrentTargetOffsetY, 75
IniRead, enableAim, settings.ini, SavedConfig, EnableAim, 0
IniRead, aimFovEnabled, settings.ini, SavedConfig, AimFOVEnabled, 0
IniRead, fovValue, settings.ini, SavedConfig, FOVSize, 95
IniRead, aimFovValue, settings.ini, SavedConfig, AimFOVSize, 300
IniRead, fovCircleEnabled, settings.ini, SavedConfig, FOVCircleEnabled, 0
IniRead, aimFovCircleEnabled, settings.ini, SavedConfig, AimFOVCircleEnabled, 0
IniRead, smoothingValue, settings.ini, SavedConfig, Smoothing, 4
IniRead, predictionValue, settings.ini, SavedConfig, Prediction, 250
IniRead, centerSpeedValue, settings.ini, SavedConfig, CenterSpeed, 200
IniRead, enablePrediction, settings.ini, SavedConfig, PredictionEnabled, 0
IniRead, targetColor, settings.ini, SavedConfig, TargetColor, E600FF
IniRead, fovColor, settings.ini, SavedConfig, FOVColor, 00FF00
IniRead, aimFovColor, settings.ini, SavedConfig, AimFOVColor, FFFF00
IniRead, recoilStrength, settings.ini, SavedConfig, RecoilStrength, 50
IniRead, recoilDL, settings.ini, SavedConfig, RecoilDL, 50
IniRead, recoilEnabled, settings.ini, SavedConfig, RecoilEnabled, 0
IniRead, offsetX, settings.ini, SavedConfig, OffsetX, 0
IniRead, offsetY, settings.ini, SavedConfig, OffsetY, 0
IniRead, customOffsetXEnabled, settings.ini, SavedConfig, CustomOffsetXEnabled, 0
IniRead, customOffsetYEnabled, settings.ini, SavedConfig, CustomOffsetYEnabled, 0
IniRead, xStrength, settings.ini, SavedConfig, XStrength, 250
IniRead, yStrength, settings.ini, SavedConfig, YStrength, 200
IniRead, headOffset, settings.ini, SavedConfig, HeadOffset, 75
IniRead, chestOffset, settings.ini, SavedConfig, ChestOffset, 154
IniRead, legsOffset, settings.ini, SavedConfig, LegsOffset, 125
IniRead, feetOffset, settings.ini, SavedConfig, FeetOffset, 188
IniRead, enableHeadOffset, settings.ini, SavedConfig, EnableHeadOffset, 0
IniRead, enableChestOffset, settings.ini, SavedConfig, EnableChestOffset, 0
IniRead, enableLegsOffset, settings.ini, SavedConfig, EnableLegsOffset, 0
IniRead, enableFeetOffset, settings.ini, SavedConfig, EnableFeetOffset, 0
IniRead, enableAnimations, settings.ini, SavedConfig, EnableAnimations, 1
GuiControl,, OffsetSliderY, %currentOffsetY%
GuiControl,, OffsetValueY, %currentOffsetY%
GuiControl,, EnableCheckbox, %enableAim%
GuiControl,, AimFOVEnabled, %aimFovEnabled%
GuiControl,, FOVSlider, %fovValue%
GuiControl,, FOVValue, %fovValue%
GuiControl,, AimFOVSlider, %aimFovValue%
GuiControl,, AimFOVValue, %aimFovValue%
GuiControl,, FOVCircleCheckbox, %fovCircleEnabled%
GuiControl,, AimFOVCircleCheckbox, %aimFovCircleEnabled%
GuiControl,, SmoothingSlider, %smoothingValue%
GuiControl,, SmoothingValue, % Round(smoothingValue/100, 2)
GuiControl,, PredictionSlider, %predictionValue%
GuiControl,, PredictionValue, % Round(predictionValue/100, 2)
GuiControl,, CenterSpeedSlider, %centerSpeedValue%
GuiControl,, CenterSpeedValue, % Round(centerSpeedValue/100, 2)
GuiControl,, EnablePredictionCheckbox, %enablePrediction%
GuiControl,, ColorInput, %targetColor%
GuiControl,, FOVColorInput, %fovColor%
GuiControl,, AimFOVColorInput, %aimFovColor%
GuiControl,, RecoilStrengthSlider, %recoilStrength%
GuiControl,, RecoilValue, %recoilStrength%
GuiControl,, RecoilDLSlider, %recoilDL%
GuiControl,, RecoilDLValue, %recoilDL%
GuiControl,, RecoilEnabled, %recoilEnabled%
GuiControl,, OffsetSliderX, %offsetX%
GuiControl,, OffsetValueX, %offsetX%
GuiControl,, OffsetSliderY, %offsetY%
GuiControl,, OffsetValueY, %offsetY%
GuiControl,, EnableCustomOffsetX, %customOffsetXEnabled%
GuiControl,, EnableCustomOffsetY, %customOffsetYEnabled%
GuiControl,, XStrengthSlider, %xStrength%
GuiControl,, XStrengthValue, % Round(xStrength/100, 2)
GuiControl,, YStrengthSlider, %yStrength%
GuiControl,, YStrengthValue, % Round(yStrength/100, 2)
GuiControl,, HeadOffsetSlider, %headOffset%
GuiControl,, HeadOffsetValue, %headOffset%
GuiControl,, ChestOffsetSlider, %chestOffset%
GuiControl,, ChestOffsetValue, %chestOffset%
GuiControl,, LegsOffsetSlider, %legsOffset%
GuiControl,, LegsOffsetValue, %legsOffset%
GuiControl,, FeetOffsetSlider, %feetOffset%
GuiControl,, FeetOffsetValue, %feetOffset%
GuiControl,, EnableHeadOffset, %enableHeadOffset%
GuiControl,, EnableChestOffset, %enableChestOffset%
GuiControl,, EnableLegsOffset, %enableLegsOffset%
GuiControl,, EnableFeetOffset, %enableFeetOffset%
GuiControl,, EnableAnimationsCheckbox, %enableAnimations%
TargetOffsetY := savedTargetOffsetY
toggle := enableAim
EnableState := enableAim
AimFOVState := aimFovEnabled
FOVCircleEnabled := fovCircleEnabled
AimFOVCircleEnabled := aimFovCircleEnabled
Gosub, UpdateFOV
Gosub, UpdateAimFOV
Gosub, UpdateColor
Gosub, UpdateSmoothing
Gosub, UpdatePrediction
Gosub, UpdateCenterSpeed
Gosub, UpdateRecoil
Gosub, UpdateRecoilDL
Gosub, UpdateOffsetX
Gosub, UpdateOffsetY
Gosub, UpdateXStrength
Gosub, UpdateYStrength
if (fovCircleEnabled)
Gosub, ToggleFOVCircle
if (aimFovCircleEnabled)
Gosub, ToggleAimFOVCircle
} catch e {
success := false
errorMsg := e
}
if (success)
MsgBox, 0x40, Success, Configuration loaded successfully!
return
SaveConfig:
GuiControlGet, configName,, ConfigNameInput
if (configName = "") {
MsgBox, 0x10, Error, Please enter a config name!
return
}
try {
IniWrite, %FOVSize%, settings.ini, %configName%, FOVSize
IniWrite, %AimFOVSize%, settings.ini, %configName%, AimFOVSize
IniWrite, %smoothing%, settings.ini, %configName%, Smoothing
IniWrite, %DFColor%, settings.ini, %configName%, TargetColor
IniWrite, %XStrengthMultiplier%, settings.ini, %configName%, XStrengthMultiplier
IniWrite, %YStrengthMultiplier%, settings.ini, %configName%, YStrengthMultiplier
IniWrite, %RecoilStrength%, settings.ini, %configName%, RecoilStrength
IniWrite, %RecoilDL%, settings.ini, %configName%, RecoilDL
IniWrite, %CustomOffsetX%, settings.ini, %configName%, CustomOffsetX
IniWrite, %CustomOffsetY%, settings.ini, %configName%, CustomOffsetY
IniWrite, %HeadOffset%, settings.ini, %configName%, HeadOffset
IniWrite, %ChestOffset%, settings.ini, %configName%, ChestOffset
IniWrite, %LegsOffset%, settings.ini, %configName%, LegsOffset
IniWrite, %FeetOffset%, settings.ini, %configName%, FeetOffset
RefreshConfigList()
GuiControl, Choose, ConfigSelect, %configName%
MsgBox, 0x40, Success, Configuration saved successfully!
} catch e {
MsgBox, 0x10, Error, Failed to save configuration.`nError: %e%
}
return
LoadConfig:
GuiControlGet, selectedConfig,, ConfigSelect
if (selectedConfig = "") {
return
}
try {
IniRead, newFOV, settings.ini, %selectedConfig%, FOVSize, 95
IniRead, newAimFOV, settings.ini, %selectedConfig%, AimFOVSize, 300
IniRead, newSmoothing, settings.ini, %selectedConfig%, Smoothing, 0.05
IniRead, newTargetColor, settings.ini, %selectedConfig%, TargetColor, 0xE600FF
IniRead, newXStrength, settings.ini, %selectedConfig%, XStrengthMultiplier, 1.0
IniRead, newYStrength, settings.ini, %selectedConfig%, YStrengthMultiplier, 1.0
IniRead, newRecoilStrength, settings.ini, %selectedConfig%, RecoilStrength, 50
IniRead, newRecoilDL, settings.ini, %selectedConfig%, RecoilDL, 50
IniRead, newOffsetX, settings.ini, %selectedConfig%, CustomOffsetX, 0
IniRead, newOffsetY, settings.ini, %selectedConfig%, CustomOffsetY, 0
IniRead, newHeadOffset, settings.ini, %selectedConfig%, HeadOffset, 75
IniRead, newChestOffset, settings.ini, %selectedConfig%, ChestOffset, 154
IniRead, newLegsOffset, settings.ini, %selectedConfig%, LegsOffset, 125
IniRead, newFeetOffset, settings.ini, %selectedConfig%, FeetOffset, 188
GuiControl,, FOVSlider, %newFOV%
GuiControl,, AimFOVSlider, %newAimFOV%
GuiControl,, SmoothingSlider, % Round(newSmoothing * 100)
GuiControl,, ColorInput, % SubStr(newTargetColor, 3)
GuiControl,, XStrengthSlider, % Round(newXStrength * 100)
GuiControl,, YStrengthSlider, % Round(newYStrength * 100)
GuiControl,, RecoilStrengthSlider, %newRecoilStrength%
GuiControl,, RecoilDLSlider, %newRecoilDL%
GuiControl,, OffsetSliderX, %newOffsetX%
GuiControl,, OffsetSliderY, %newOffsetY%
GuiControl,, HeadOffsetSlider, %newHeadOffset%
GuiControl,, ChestOffsetSlider, %newChestOffset%
GuiControl,, LegsOffsetSlider, %newLegsOffset%
GuiControl,, FeetOffsetSlider, %newFeetOffset%
FOVSize := newFOV
AimFOVSize := newAimFOV
smoothing := newSmoothing
DFColor := newTargetColor
XStrengthMultiplier := newXStrength
YStrengthMultiplier := newYStrength
RecoilStrength := newRecoilStrength
RecoilDL := newRecoilDL
CustomOffsetX := newOffsetX
CustomOffsetY := newOffsetY
HeadOffset := newHeadOffset
ChestOffset := newChestOffset
LegsOffset := newLegsOffset
FeetOffset := newFeetOffset
Gosub, UpdateAllControls
} catch e {
MsgBox, 0x10, Error, Failed to load configuration.`nError: %e%
}
return
SetDefaultConfig:
GuiControlGet, selectedConfig,, ConfigSelect
if (selectedConfig = "") {
MsgBox, 0x10, Error, Please select a configuration first!
return
}
try {
IniWrite, %selectedConfig%, settings.ini, Settings, DefaultConfig
MsgBox, 0x40, Success, Default configuration set!
} catch e {
MsgBox, 0x10, Error, Failed to set default configuration.`nPlease run as administrator.
}
return
SetTimer, InitializeConfig, -100
InitializeConfig:
RefreshConfigList()
IniRead, defaultConfig, settings.ini, Settings, DefaultConfig, Default Profile
if (defaultConfig != "ERROR") {
GuiControl, Choose, ConfigSelect, %defaultConfig%
Gosub, LoadConfig
}
return
GetSavedHotkey(keyName, defaultValue) {
IniRead, savedKey, settings.ini, Hotkeys, %keyName%, %defaultValue%
return (savedKey = "ERROR") ? defaultValue : savedKey
}
UpdateAllControls:
GuiControl,, FOVValue, %FOVSize%
GuiControl,, FOVSlider, %FOVSize%
GuiControl,, AimFOVValue, %AimFOVSize%
GuiControl,, AimFOVSlider, %AimFOVSize%
GuiControl,, SmoothingValue, %smoothing%
GuiControl,, SmoothingSlider, % Round(smoothing * 100)
GuiControl,, ColorInput, % SubStr(DFColor, 3)
GuiControl,, XStrengthValue, % Round(XStrengthMultiplier, 2)
GuiControl,, XStrengthSlider, % Round(XStrengthMultiplier * 100)
GuiControl,, YStrengthValue, % Round(YStrengthMultiplier, 2)
GuiControl,, YStrengthSlider, % Round(YStrengthMultiplier * 100)
GuiControl,, RecoilValue, %RecoilStrength%
GuiControl,, RecoilStrengthSlider, %RecoilStrength%
GuiControl,, RecoilDLValue, %RecoilDL%
GuiControl,, RecoilDLSlider, %RecoilDL%
GuiControl,, OffsetValueX, %CustomOffsetX%
GuiControl,, OffsetSliderX, %CustomOffsetX%
GuiControl,, OffsetValueY, %CustomOffsetY%
GuiControl,, OffsetSliderY, %CustomOffsetY%
GuiControl,, HeadOffsetValue, %HeadOffset%
GuiControl,, HeadOffsetSlider, %HeadOffset%
GuiControl,, ChestOffsetValue, %ChestOffset%
GuiControl,, ChestOffsetSlider, %ChestOffset%
GuiControl,, LegsOffsetValue, %LegsOffset%
GuiControl,, LegsOffsetSlider, %LegsOffset%
GuiControl,, FeetOffsetValue, %FeetOffset%
GuiControl,, FeetOffsetSlider, %FeetOffset%
if (FOVCircleEnabled)
SetTimer, DrawFOVCircle, -1
if (AimFOVCircleEnabled)
SetTimer, DrawAimFOVCircle, -1
return
ResetHotkeys:
ToggleAimKey := DefaultToggleAimKey
HideGUIKey := DefaultHideGUIKey
ExitGUIKey := DefaultExitGUIKey
AimKey1 := DefaultAimKey1
AimKey2 := DefaultAimKey2
AimKey3 := DefaultAimKey3
GuiControl,, ToggleAimKey, %DefaultToggleAimKey%
GuiControl,, HideGUIKey, %DefaultHideGUIKey%
GuiControl,, ExitGUIKey, %DefaultExitGUIKey%
GuiControl,, AimKey1, %DefaultAimKey1%
GuiControl,, AimKey2, %DefaultAimKey2%
GuiControl,, AimKey3, %DefaultAimKey3%
Hotkey, % "$" . SavedToggleAimKey, Toggle, Off
Hotkey, % "$" . SavedHideGUIKey, GuiToggle, Off
Hotkey, % "$" . SavedExitGUIKey, ExitGUI, Off
Hotkey, % "$" . DefaultToggleAimKey, Toggle, On
Hotkey, % "$" . DefaultHideGUIKey, GuiToggle, On
Hotkey, % "$" . DefaultExitGUIKey, ExitGUI, On
SavedToggleAimKey := DefaultToggleAimKey
SavedHideGUIKey := DefaultHideGUIKey
SavedExitGUIKey := DefaultExitGUIKey
MsgBox, 0x40, Success, Hotkeys reset to default values!
return
CaptureKey(ControlVar) {
static isCapturing := false
static validKeys := {}
if (validKeys.Count() = 0) {
validKeys["LButton"] := 1
validKeys["RButton"] := 1
validKeys["MButton"] := 1
validKeys["XButton1"] := 1
validKeys["XButton2"] := 1
Loop, 26
validKeys[Chr(A_Index + 96)] := 1
Loop, 10
validKeys[A_Index - 1] := 1
Loop, 24
validKeys["F" . A_Index] := 1
validKeys["``"] := 1
validKeys["-"] := 1
validKeys["="] := 1
validKeys["["] := 1
validKeys["]"] := 1
validKeys["\"] := 1
validKeys[";"] := 1
validKeys["'"] := 1
validKeys[","] := 1
validKeys["."] := 1
validKeys["/"] := 1
validKeys["Space"] := 1
validKeys["Tab"] := 1
validKeys["Enter"] := 1
validKeys["Escape"] := 1
validKeys["Esc"] := 1
validKeys["Backspace"] := 1
validKeys["BS"] := 1
validKeys["Delete"] := 1
validKeys["Del"] := 1
validKeys["Insert"] := 1
validKeys["Ins"] := 1
validKeys["Home"] := 1
validKeys["End"] := 1
validKeys["PgUp"] := 1
validKeys["PgDn"] := 1
validKeys["Up"] := 1
validKeys["Down"] := 1
validKeys["Left"] := 1
validKeys["Right"] := 1
validKeys["ScrollLock"] := 1
validKeys["CapsLock"] := 1
validKeys["NumLock"] := 1
Loop, 10
validKeys["Numpad" . (A_Index - 1)] := 1
validKeys["NumpadDot"] := 1
validKeys["NumpadDiv"] := 1
validKeys["NumpadMult"] := 1
validKeys["NumpadAdd"] := 1
validKeys["NumpadSub"] := 1
validKeys["NumpadEnter"] := 1
validKeys["NumpadDel"] := 1
validKeys["NumpadIns"] := 1
validKeys["NumpadClear"] := 1
validKeys["NumpadUp"] := 1
validKeys["NumpadDown"] := 1
validKeys["NumpadLeft"] := 1
validKeys["NumpadRight"] := 1
validKeys["NumpadHome"] := 1
validKeys["NumpadEnd"] := 1
validKeys["NumpadPgUp"] := 1
validKeys["NumpadPgDn"] := 1
validKeys["LAlt"] := 1
validKeys["RAlt"] := 1
validKeys["LCtrl"] := 1
validKeys["RCtrl"] := 1
validKeys["LShift"] := 1
validKeys["RShift"] := 1
validKeys["LWin"] := 1
validKeys["RWin"] := 1
validKeys["Browser_Back"] := 1
validKeys["Browser_Forward"] := 1
validKeys["Browser_Refresh"] := 1
validKeys["Browser_Stop"] := 1
validKeys["Browser_Search"] := 1
validKeys["Browser_Favorites"] := 1
validKeys["Browser_Home"] := 1
validKeys["Volume_Mute"] := 1
validKeys["Volume_Down"] := 1
validKeys["Volume_Up"] := 1
validKeys["Media_Next"] := 1
validKeys["Media_Prev"] := 1
validKeys["Media_Stop"] := 1
validKeys["Media_Play_Pause"] := 1
validKeys["AppsKey"] := 1
validKeys["PrintScreen"] := 1
validKeys["CtrlBreak"] := 1
validKeys["Pause"] := 1
validKeys["Break"] := 1
validKeys["Help"] := 1
validKeys["Sleep"] := 1
validKeys[""] := 1
validKeys["None"] := 1
}
if (isCapturing)
return
isCapturing := true
SoundGet, originalVolume
RegRead, OriginalSoundMode, HKCU, AppEvents\Schemes\Apps\.Default\.Default\.Current
SoundSet, 0
RegWrite, REG_SZ, HKCU, AppEvents\Schemes\Apps\.Default\.Default\.Current,,
BlockInput, On
GuiControl,, %ControlVar%, Press a key...
Loop {
if (GetKeyState("Delete", "P")) {
capturedKey := "None"
Goto, KeyCaptured
}
mouseButtons := ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
for _, button in mouseButtons {
if (GetKeyState(button, "P")) {
capturedKey := button
Goto, KeyCaptured
}
}
for key in validKeys {
if (key != "Delete" && GetKeyState(key, "P")) {
capturedKey := key
Goto, KeyCaptured
}
}
Sleep, 10
}
KeyCaptured:
startTime := A_TickCount
Loop {
if (capturedKey = "None" || !GetKeyState(capturedKey, "P") || A_TickCount - startTime > 1000)
break
Sleep, 10
}
BlockInput, Off
if (capturedKey = "None" || validKeys.HasKey(capturedKey)) {
GuiControl,, %ControlVar%, % (capturedKey = "None" ? "" : capturedKey)
if (ControlVar = "AimKey1")
global AimKey1 := capturedKey
else if (ControlVar = "AimKey2")
global AimKey2 := capturedKey
else if (ControlVar = "AimKey3")
global AimKey3 := capturedKey
else if (ControlVar = "ToggleAimKey")
global DefaultToggleAimKey := capturedKey
else if (ControlVar = "HideGUIKey")
global DefaultHideGUIKey := capturedKey
else if (ControlVar = "ExitGUIKey")
global DefaultExitGUIKey := capturedKey
global aimCheckCondition := BuildAimCheckCondition(AimKey1, AimKey2, AimKey3)
}
Sleep, 50
SoundSet, %originalVolume%
RegWrite, REG_SZ, HKCU, AppEvents\Schemes\Apps\.Default\.Default\.Current,, %OriginalSoundMode%
isCapturing := false
return
}
CaptureToggleAim:
oldKey := SavedToggleAimKey
CaptureKey("ToggleAimKey")
GuiControlGet, newKey,, ToggleAimKey
if (newKey != "None" && newKey != "") {
try {
if (oldKey && oldKey != "None")
Hotkey, % "$" . oldKey, Off
fn := Func("ToggleAim")
Hotkey, % "$" . newKey, % fn, On
SavedToggleAimKey := newKey
ToggleAimKey := newKey
IniWrite, %newKey%, settings.ini, Hotkeys, ToggleAim
} catch e {
MsgBox, % "Failed to set new hotkey: " . e.message
}
}
return
CaptureHideGUI:
oldKey := SavedHideGUIKey
CaptureKey("HideGUIKey")
GuiControlGet, newKey,, HideGUIKey
if (newKey != "None" && newKey != "") {
try {
Hotkey, % "$" . oldKey, Off
Hotkey, % "$" . newKey, GuiToggle, On
SavedHideGUIKey := newKey
HideGUIKey := newKey
IniWrite, %newKey%, settings.ini, Hotkeys, HideGui
} catch {
MsgBox, Failed to set new hotkey.
}
}
return
CaptureExitGUI:
oldKey := SavedExitGUIKey
CaptureKey("ExitGUIKey")
GuiControlGet, newKey,, ExitGUIKey
if (newKey != "None" && newKey != "") {
try {
Hotkey, % "$" . oldKey, Off
Hotkey, % "$" . newKey, ExitGUI, On
SavedExitGUIKey := newKey
ExitGUIKey := newKey
IniWrite, %newKey%, settings.ini, Hotkeys, ExitGUIKey
} catch {
MsgBox, Failed to set new hotkey.
}
}
return
CaptureAimKey1:
CaptureKey("AimKey1")
return
CaptureAimKey2:
CaptureKey("AimKey2")
return
CaptureAimKey3:
CaptureKey("AimKey3")
return
SaveHotkeys:
GuiControlGet, newToggleKey,, ToggleAimKey
GuiControlGet, newHideKey,, HideGUIKey
GuiControlGet, newExitKey,, ExitGUIKey
if (newToggleKey != SavedToggleAimKey) {
Hotkey, % "$" . SavedToggleAimKey, Toggle, Off
Hotkey, % "$" . newToggleKey, Toggle, On
SavedToggleAimKey := newToggleKey
ToggleAimKey := newToggleKey
}
if (newHideKey != SavedHideGUIKey) {
Hotkey, % "$" . SavedHideGUIKey, GuiToggle, Off
Hotkey, % "$" . newHideKey, GuiToggle, On
SavedHideGUIKey := newHideKey
HideGUIKey := newHideKey
}
if (newExitKey != SavedExitGUIKey) {
Hotkey, % "$" . SavedExitGUIKey, ExitGUI, Off
Hotkey, % "$" . newExitKey, ExitGUI, On
SavedExitGUIKey := newExitKey
ExitGUIKey := newExitKey
}
IniWrite, %newToggleKey%, settings.ini, Hotkeys, ToggleAim
IniWrite, %newHideKey%, settings.ini, Hotkeys, HideGui
IniWrite, %newExitKey%, settings.ini, Hotkeys, ExitGUIKey
MsgBox, 0x40, Success, Hotkeys saved successfully!
return
BuildAimCheckCondition(key1, key2, key3) {
condition := ""
if (key1 != "None")
condition .= "GetKeyState(""" . key1 . """, ""P"")"
if (key2 != "None") {
if (condition != "")
condition .= " or "
condition .= "GetKeyState(""" . key2 . """, ""P"")"
}
if (key3 != "None" && key3 != "") {
if (condition != "")
condition .= " or "
condition .= "GetKeyState(""" . key3 . """, ""P"")"
}
return condition
}
ToggleAim() {
global EnableCheckbox, toggle
GuiControlGet, EnableState,, EnableCheckbox
GuiControl,, EnableCheckbox, % !EnableState
toggle := !EnableState
if (toggle)
SoundBeep, 300, 100
}
Toggle:
GuiControlGet, EnableState,, EnableCheckbox
GuiControl,, EnableCheckbox, % !EnableState
toggle := !EnableState
if (toggle)
SoundBeep, 300, 100
return
GuiToggle:
if (GuiVisible) {
WinGetPos, lastX, lastY, , , %GuiTitle%
if (EnableAnimations) {
guiHwnd := WinExist(GuiTitle)
if (guiHwnd)
SmoothFade(guiHwnd, false)
}
Gui, Hide
GuiVisible := false
if (FOVCircleEnabled)
DrawFOVCircle()
if (AimFOVCircleEnabled)
DrawAimFOVCircle()
} else {
showX := lastX ? lastX : SafeX
showY := lastY ? lastY : SafeY
showX := Min(A_ScreenWidth - Width - 20, Max(20, showX))
showY := Min(A_ScreenHeight - Height - 20, Max(20, showY))
Gui, Show, % "w" . Width . " h" . Height . " NA x" . showX . " y" . showY
if (EnableAnimations) {
guiHwnd := WinExist(GuiTitle)
if (guiHwnd)
SmoothFade(guiHwnd, true)
}
GuiVisible := true
if (FOVCircleEnabled)
DrawFOVCircle()
if (AimFOVCircleEnabled)
DrawAimFOVCircle()
}
return
InitializeHotkeyControls() {
global
GuiControl,, ToggleAimKey, %ToggleAimKey%
GuiControl,, HideGUIKey, %HideGUIKey%
GuiControl,, ExitGUIKey, %ExitGUIKey%
GuiControl,, AimKey1, %AimKey1%
GuiControl,, AimKey2, %AimKey2%
GuiControl,, AimKey3, %AimKey3%
}
ToggleAnimations:
GuiControlGet, EnableAnimations,, EnableAnimationsCheckbox
return
UpdateOffsetY:
GuiControlGet, newOffset,, OffsetSliderY
if (UseCustomOffsetY)
CustomOffsetY := newOffset
else
TargetOffsetY := newOffset
GuiControl,, OffsetValueY, %newOffset%
return
UpdateOffsetX:
GuiControlGet, newOffset,, OffsetSliderX
CustomOffsetX := newOffset
GuiControl,, OffsetValueX, %newOffset%
return
UpdateXStrength:
GuiControlGet, newStrength,, XStrengthSlider
XStrengthMultiplier := newStrength / 100
GuiControl,, XStrengthValue, % Round(XStrengthMultiplier, 2)
return
UpdateYStrength:
GuiControlGet, newStrength,, YStrengthSlider
YStrengthMultiplier := newStrength / 100
GuiControl,, YStrengthValue, % Round(YStrengthMultiplier, 2)
return
UpdateFOV:
Critical
GuiControlGet, newFOV,, FOVSlider
CFovX := newFOV
CFovY := newFOV
GuiControl,, FOVValue, %newFOV%
ScanL := ZeroX - CFovX
ScanT := ZeroY - CFovY
ScanR := ZeroX + CFovX
ScanB := ZeroY + CFovY
if (FOVCircleEnabled)
SetTimer, DrawFOVCircle, -1
return
UpdateAimFOV:
Critical
GuiControlGet, newFOV,, AimFOVSlider
AimFOV := newFOV
GuiControl,, AimFOVValue, %newFOV%
if (AimFOVCircleEnabled)
SetTimer, DrawAimFOVCircle, -1
return
UpdateColor:
GuiControlGet, newColor,, ColorInput
if (RegExMatch(newColor, "^[0-9A-Fa-f]{6}$")) {
DFColor := "0x" . newColor
} else {
MsgBox, 0x10, Invalid Color, Please enter a valid 6-digit hex color code (e.g., E600FF)
}
return
ToggleFOVCircle:
GuiControlGet, FOVCircleEnabled,, FOVCircleCheckbox
if (FOVCircleEnabled)
DrawFOVCircle()
else
Gui, FOV:Destroy
return
ToggleAimFOVCircle:
GuiControlGet, AimFOVCircleEnabled,, AimFOVCircleCheckbox
if (AimFOVCircleEnabled)
DrawAimFOVCircle()
else
Gui, AimFOV:Destroy
return
DrawFOVCircle() {
global ZeroX, ZeroY, FOVCircleColor, CFovX
static hwndFOV := 0
if (hwndFOV) {
Gui, FOV:Destroy
hwndFOV := 0
}
Gui, FOV:+LastFound +AlwaysOnTop -Caption +E0x20 +ToolWindow +Owner
Gui, FOV:Color, 000000
WinSet, ExStyle, +0x20
WinSet, TransColor, 000000 255
Width := CFovX * 2
Height := CFovX * 2
Gui, FOV:Show, % "w" Width " h" Height " x" (ZeroX - CFovX) " y" (ZeroY - CFovX) " NA"
hwndFOV := WinExist()
hdc := GetDC(hwndFOV)
Graphics := Gdip_GraphicsFromHDC(hdc)
Gdip_SetSmoothingMode(Graphics, 4)
pPen := Gdip_CreatePen(FOVCircleColor, 2)
Gdip_DrawEllipse(Graphics, pPen, 0, 0, Width-1, Height-1)
Gdip_DeletePen(pPen)
Gdip_DeleteGraphics(Graphics)
ReleaseDC(hdc, hwndFOV)
}
DrawAimFOVCircle() {
global ZeroX, ZeroY, AimFOVCircleColor, AimFOV
static hwndAimFOV := 0
if (hwndAimFOV) {
Gui, AimFOV:Destroy
hwndAimFOV := 0
}
Gui, AimFOV:+LastFound +AlwaysOnTop -Caption +E0x20 +ToolWindow +Owner
Gui, AimFOV:Color, 000000
WinSet, ExStyle, +0x20
WinSet, TransColor, 000000 255
Width := AimFOV * 2
Height := AimFOV * 2
Gui, AimFOV:Show, % "w" Width " h" Height " x" (ZeroX - AimFOV) " y" (ZeroY - AimFOV) " NA"
hwndAimFOV := WinExist()
hdc := GetDC(hwndAimFOV)
Graphics := Gdip_GraphicsFromHDC(hdc)
Gdip_SetSmoothingMode(Graphics, 4)
pPen := Gdip_CreatePen(AimFOVCircleColor, 2)
Gdip_DrawEllipse(Graphics, pPen, 0, 0, Width-1, Height-1)
Gdip_DeletePen(pPen)
Gdip_DeleteGraphics(Graphics)
ReleaseDC(hdc, hwndAimFOV)
}
UpdateFOVColor:
GuiControlGet, newColor,, FOVColorInput
if (RegExMatch(newColor, "^[0-9A-Fa-f]{6}$")) {
FOVCircleColor := "0xFF" . newColor
if (FOVCircleEnabled)
DrawFOVCircle()
} else {
MsgBox, 0x10, Invalid Color, Please enter a valid 6-digit hex color code (e.g., 00FF00)
}
return
UpdateAimFOVColor:
GuiControlGet, newColor,, AimFOVColorInput
if (RegExMatch(newColor, "^[0-9A-Fa-f]{6}$")) {
AimFOVCircleColor := "0xFF" . newColor
if (AimFOVCircleEnabled)
DrawAimFOVCircle()
} else {
MsgBox, 0x10, Invalid Color, Please enter a valid 6-digit hex color code (e.g., FFFF00)
}
return
UpdateHeadOffset:
GuiControlGet, newOffset,, HeadOffsetSlider
HeadOffset := newOffset
GuiControl,, HeadOffsetValue, %newOffset%
return
UpdateChestOffset:
GuiControlGet, newOffset,, ChestOffsetSlider
ChestOffset := newOffset
GuiControl,, ChestOffsetValue, %newOffset%
return
UpdateLegsOffset:
GuiControlGet, newOffset,, LegsOffsetSlider
LegsOffset := newOffset
GuiControl,, LegsOffsetValue, %newOffset%
return
UpdateFeetOffset:
GuiControlGet, newOffset,, FeetOffsetSlider
FeetOffset := newOffset
GuiControl,, FeetOffsetValue, %newOffset%
return
ToggleHeadOffset:
GuiControlGet, EnableCustomHead,, EnableHeadOffset
return
ToggleChestOffset:
GuiControlGet, EnableCustomChest,, EnableChestOffset
return
ToggleLegsOffset:
GuiControlGet, EnableCustomLegs,, EnableLegsOffset
return
ToggleFeetOffset:
GuiControlGet, EnableCustomFeet,, EnableFeetOffset
return
SaveTargetOffsets:
if (EnableCustomHead)
IniWrite, %HeadOffset%, settings.ini, TargetOffsets, HeadOffset
if (EnableCustomChest)
IniWrite, %ChestOffset%, settings.ini, TargetOffsets, ChestOffset
if (EnableCustomLegs)
IniWrite, %LegsOffset%, settings.ini, TargetOffsets, LegsOffset
if (EnableCustomFeet)
IniWrite, %FeetOffset%, settings.ini, TargetOffsets, FeetOffset
MsgBox, 0x40, Success, Target offsets saved successfully!
return
UpdatePrediction:
GuiControlGet, newPrediction,, PredictionSlider
predictionMultiplier := newPrediction / 100
GuiControl,, PredictionValue, % Round(predictionMultiplier, 2)
return
TogglePrediction:
GuiControlGet, currentState,, EnablePredictionCheckbox
GuiControl,, EnablePredictionCheckbox, % !currentState
return
GuiControl, Enable, RecoilStrengthSlider
GuiControl, Enable, RecoilDLSlider
ToggleRecoil:
GuiControlGet, RecoilEnabled,, RecoilEnabled
global RecoilActive := RecoilEnabled
return
ToggleCustomOffsetY:
GuiControlGet, UseCustomOffsetY,, EnableCustomOffsetY
return
ToggleCustomOffsetX:
GuiControlGet, UseCustomOffsetX,, EnableCustomOffsetX
return
BlockRightClick() {
return true
}
UpdateCenterSpeed:
GuiControlGet, newSpeed,, CenterSpeedSlider
centerSpeedMultiplier := newSpeed / 100
GuiControl,, CenterSpeedValue, % Round(centerSpeedMultiplier, 2)
return
UpdateExitGUIKey:
GuiControlGet, newKey,, ExitGUIKey
if (newKey = "") {
MsgBox, 0x10, Error, Please specify a valid hotkey!
return
}
if (ExitGUIKey != "")
Hotkey, % "$" . ExitGUIKey, ExitGUI, Off
ExitGUIKey := newKey
Hotkey, % "$" . ExitGUIKey, ExitGUI, On
IniWrite, %ExitGUIKey%, settings.ini, Hotkeys, ExitGUIKey
MsgBox, 0x40, Success, ExitGUI hotkey updated!
return
GuiMove:
PostMessage, 0xA1, 2
return
GuiContextMenu:
return
HeadshotsButton:
TargetOffsetY := EnableCustomHead ? HeadOffset : 75
GuiControl,, OffsetSliderY, %TargetOffsetY%
GuiControl,, OffsetValueY, %TargetOffsetY%
GuiControl,, ZeroYLabel, %ZeroY%
if (FOVCircleEnabled)
DrawFOVCircle()
IniWrite, %TargetOffsetY%, settings.ini, SavedConfig, CurrentTargetOffsetY
return
ChestButton:
TargetOffsetY := EnableCustomChest ? ChestOffset : 154
GuiControl,, OffsetSliderY, %TargetOffsetY%
GuiControl,, OffsetValueY, %TargetOffsetY%
GuiControl,, ZeroYLabel, %ZeroY%
if (FOVCircleEnabled)
DrawFOVCircle()
IniWrite, %TargetOffsetY%, settings.ini, SavedConfig, CurrentTargetOffsetY
return
LegsButton:
TargetOffsetY := EnableCustomLegs ? LegsOffset : 175
GuiControl,, OffsetSliderY, %TargetOffsetY%
GuiControl,, OffsetValueY, %TargetOffsetY%
GuiControl,, ZeroYLabel, %ZeroY%
if (FOVCircleEnabled)
DrawFOVCircle()
IniWrite, %TargetOffsetY%, settings.ini, SavedConfig, CurrentTargetOffsetY
return
FeetButton:
TargetOffsetY := EnableCustomFeet ? FeetOffset : 198
GuiControl,, OffsetSliderY, %TargetOffsetY%
GuiControl,, OffsetValueY, %TargetOffsetY%
GuiControl,, ZeroYLabel, %ZeroY%
if (FOVCircleEnabled)
DrawFOVCircle()
IniWrite, %TargetOffsetY%, settings.ini, SavedConfig, CurrentTargetOffsetY
return
UpdateAnimationType:
GuiControlGet, AnimationType,, AnimationTypeSelect
return
UpdateSmoothing:
GuiControlGet, newSmoothing,, SmoothingSlider
smoothing := newSmoothing / 100
GuiControl,, SmoothingValue, % Round(smoothing, 2)
return
CalculateVelocityConsistency(history) {
if (history.Length() < 2)
return 0
prevAngle := ATan2(history[1].y, history[1].x)
totalAngleChange := 0
count := 0
Loop, % history.Length() - 1 {
currentAngle := ATan2(history[A_Index + 1].y, history[A_Index + 1].x)
angleChange := Abs(currentAngle - prevAngle)
if (angleChange > 180)
angleChange := 360 - angleChange
totalAngleChange += angleChange
count++
prevAngle := currentAngle
}
averageAngleChange := totalAngleChange / count
consistency := 1 - (averageAngleChange / 180)
return consistency
}
ATan2(y, x) {
return DllCall("msvcrt\atan2", "Double", y, "Double", x, "Double") * 57.29578
}
SmoothFade(hwnd, showing) {
static steps := 30
if showing {
WinSet, Transparent, 0, ahk_id %hwnd%
Loop, %steps% {
opacity := (A_Index / steps) * 255
WinSet, Transparent, %opacity%, ahk_id %hwnd%
Sleep, 5
}
WinSet, Transparent, 255, ahk_id %hwnd%
} else {
WinSet, Transparent, 255, ahk_id %hwnd%
Loop, %steps% {
opacity := ((steps - A_Index) / steps) * 255
WinSet, Transparent, %opacity%, ahk_id %hwnd%
Sleep, 5
}
}
}
Random(min, max) {
Random, output, min, max
return output
}
UpdateResolution:
GuiControlGet, selectedRes,, ResolutionSelect
if (selectedRes = "") {
MsgBox, 0x10, Error, Please select a resolution first!
return
}
RegExMatch(selectedRes, "(\d+)x(\d+)", res)
newWidth := res1
newHeight := res2
ZeroX := newWidth / 2
ZeroY := newHeight / 2.18
if (FOVCircleEnabled)
DrawFOVCircle()
if (AimFOVCircleEnabled)
DrawAimFOVCircle()
GuiControl,, CurrentResolution, Current Resolution: %selectedRes%
MsgBox, 0x40, Success, Resolution updated to %selectedRes%!
return
SaveResolution:
GuiControlGet, selectedRes,, ResolutionSelect
if (selectedRes = "") {
MsgBox, 0x10, Error, Please select a resolution first!
return
}
IniWrite, %selectedRes%, settings.ini, Settings, Resolution
MsgBox, 0x40, Success, Resolution saved! It will be loaded automatically next time.
return
toggle := false
if (targetFound && toggle) {
click down
} else {
click up
}
Paused := False
RemoveToolTip:
ToolTip
return
OnExit:
ExitGUI:
Close:
Gdip_ExitGUI(pToken)
ExitApp
return
GuiClose:
Gui 2: Destroy
Gui 3: Destroy
Gdip_ExitGUI(pToken)
ExitApp
return