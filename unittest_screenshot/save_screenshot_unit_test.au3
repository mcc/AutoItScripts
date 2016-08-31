#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ScreenCapture.au3>
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <GuiButton.au3>
#include <GuiRichEdit.au3>
#include <ComboConstants.au3>
#include <GuiComboBox.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <Array.au3>
Opt("TrayAutoPause", 0) ;0=no pause, 1=Pause
Opt("TrayMenuMode",2)
If _Singleton("save_screenshot", 1) = 0 Then
    MsgBox($MB_SYSTEMMODAL, "Warning", "Screenshot Capture is already running")
    Exit
EndIf

HotKeySet("{PRINTSCREEN}", "Screencap2D")
HotKeySet("+{PRINTSCREEN}", "ExitProgram")
HotKeySet("{PAUSE}", "ChangeFolder")

$exit = False
$gFileRead  = ""
$gRootFolder = IniRead("config.ini", "General", "filepath", "U:\Encrypted_Folder")
$gScreenshotRootFolder = $gRootFolder & "\" & @YEAR & @MON & @MDAY
$gScreenshotSubFolder = "Case_01"
$gScreenshotFolder = $gScreenshotRootFolder &"\" &$gScreenshotSubFolder

Func ExitProgram()
	Exit
EndFunc

Func Screencap2D()
	Local $hBmp
	$hBmp = _ScreenCapture_Capture("")
	;$fileName=@MyDocumentsDir & "\" & @ComputerName & "_" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC & ".jpg"
	$fileName=$gScreenshotFolder & "\" & @ComputerName & "_" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC & ".jpg"

	;_ScreenCapture_SaveImage(@MyDocumentsDir & "\" & $fileName, $hBmp)

	_GDIPlus_Startup ()

	$hBitmap = _GDIPlus_BitmapCreateFromHBITMAP($hBmp)
	_GDIPlus_GraphicsSetSmoothingMode($hBitmap, $GDIP_SMOOTHINGMODE_HIGHQUALITY)
	;get context
    $hBuffer = _GDIPlus_ImageGetGraphicsContext($hBitmap)
	;draw somethinginto context
    $hPen = _GDIPlus_PenCreate()
    ;_GDIPlus_GraphicsDrawLine($hBuffer,10 , 10, 500,500, $hPen)
    _GDIPlus_GraphicsFillRect($hBuffer, 400, 100, 1000, 40)
	_GDIPlus_GraphicsFillRect($hBuffer, 150, 50, 800, 40)
    ;_GDIPlus_GraphicsDrawEllipse($hBuffer, 130, 100, 140, 70)
    ; Save bitmap to file
    _GDIPlus_ImageSaveToFile ($hbitmap, $fileName)
    ; Clean up resources
    _GDIPlus_BitmapDispose ($hBitmap)
    ; Shut down GDI+ library
    _GDIPlus_ShutDown ()
	TrayTip ( "Screenshot Saved", $fileName, 10 )
EndFunc


Func ChangeFolder()
	Local $temp = InputBox("Save screenshot to Folder", $gScreenshotRootFolder & "\???", $gScreenshotSubFolder, "", -1, -1, 0, 0)
	If $temp <> "" Then
		$gScreenshotSubFolder = $temp
		$gScreenshotFolder = $gScreenshotRootFolder &"\" &$gScreenshotSubFolder
		DirCreate($gScreenshotFolder)
		TrayTip ( "Folder Changed to " & $gScreenshotFolder, "Folder Changed to " & $gScreenshotFolder, 10 )
	EndIf
EndFunc


While 1
	Sleep(1000)
WEnd