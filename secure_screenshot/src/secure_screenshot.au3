#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=..\deploy\secure_screenshot.exe
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

$gIniFile = "config.ini"
If $CmdLine[0] > 1 Then
	If $CmdLine[1] = "/C" Then
		$gIniFile = $CmdLine[2]
	EndIf
EndIf

HotKeySet("{PRINTSCREEN}", "Screencap2D")
HotKeySet("+{PRINTSCREEN}", "ExitProgram")
HotKeySet("^`", "OpenTemplate")

$exit = False
$gFileRead  = ""

$gTempFolder = IniRead($gIniFile, "Screencapture", "temp_folder", @ScriptDir & "\temp")
$gPublicKey = IniRead($gIniFile, "Screencapture", "publickey_file", @ScriptDir & "\key\public.pem")
$gOpensslExe = IniRead($gIniFile, "Screencapture", "openssl_exe", @ScriptDir & "\openssl\openssl.exe")
$gOutputFolder = IniRead($gIniFile, "Screencapture", "output_folder", @ScriptDir & "\output")
$gTemplateFolder = IniRead($gIniFile, "Template", "template_folder", @ScriptDir & "\template")

If Not FileExists($gTempFolder) Then
	MsgBox($MB_SYSTEMMODAL, "", "The temp file doesn't exist." & @CRLF & $gTempFolder)
	Exit
EndIf

If Not FileExists($gPublicKey) Then
	MsgBox($MB_SYSTEMMODAL, "", "The public key file doesn't exist." & @CRLF & $gPublicKey)
	Exit
EndIf

If Not FileExists($gOpensslExe) Then
	MsgBox($MB_SYSTEMMODAL, "", "The openssl.exe doesn't exist." & @CRLF & $gOpensslExe)
	Exit
EndIf

If Not FileExists($gOutputFolder) Then
	MsgBox($MB_SYSTEMMODAL, "", "The output file doesn't exist." & @CRLF & $gOutputFolder)
	Exit
EndIf

If Not FileExists($gTemplateFolder) Then
	MsgBox($MB_SYSTEMMODAL, "", "The template file doesn't exist." & @CRLF & $gTemplateFolder)
	Exit
EndIf


Func ExitProgram()
	Exit
EndFunc

Func Screencap2D()
	Local $hBmp
	$hBmp = _ScreenCapture_Capture("")
	;$fileName=@MyDocumentsDir & "\" & @ComputerName & "_" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC & ".jpg"
	$stamp=@ComputerName & "_" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC
	$tempFileName=$gTempFolder & "\" & $stamp & ".jpg"

	;_ScreenCapture_SaveImage(@MyDocumentsDir & "\" & $fileName, $hBmp)

	_GDIPlus_Startup ()

	$hBitmap = _GDIPlus_BitmapCreateFromHBITMAP($hBmp)
	_GDIPlus_GraphicsSetSmoothingMode($hBitmap, $GDIP_SMOOTHINGMODE_HIGHQUALITY)
	;get context
    $hBuffer = _GDIPlus_ImageGetGraphicsContext($hBitmap)
	;draw somethinginto context
    $hPen = _GDIPlus_PenCreate()
    ;_GDIPlus_GraphicsDrawLine($hBuffer,10 , 10, 500,500, $hPen)
    ;_GDIPlus_GraphicsFillRect($hBuffer, 400, 100, 1000, 40)
	;_GDIPlus_GraphicsFillRect($hBuffer, 150, 50, 800, 40)
	_GDIPlus_GraphicsFillRect($hBuffer, 0, 50, 1000, 65)
    ;_GDIPlus_GraphicsDrawEllipse($hBuffer, 130, 100, 140, 70)
    ; Save bitmap to file
    _GDIPlus_ImageSaveToFile ($hbitmap, $tempFileName)
	$tempKey = $gTempFolder & "\"&$stamp&".key"
	$tempEncKey = $gTempFolder & "\"&$stamp&".key" & ".enc"
	$tempEncFileName = $gTempFolder  & "\" &  $stamp & ".jpg.enc"

	$encKey = $gOutputFolder & "\"&$stamp&".key" & ".enc"
	$encFileName = $gOutputFolder & "\" &  $stamp & ".jpg.enc"

	ShellExecuteWait($gOpensslExe, "rand -base64 32 -out """ & $tempKey & """")
	ShellExecuteWait($gOpensslExe, "rsautl -encrypt -inkey """ & $gPublicKey &""" -pubin -in """ & $tempKey & """ -out """ & $tempEncKey & """")
	ShellExecuteWait($gOpensslExe, "enc -aes-256-cbc -salt -in """ & $tempFileName & """ -out """ & $tempEncFileName & """ -pass file:""" & $tempKey & """")
	FileMove($tempEncKey,$encKey)
	FileMove($tempEncFileName,$encFileName)
	FileDelete($tempKey)
	FileDelete($tempEncKey)
	FileDelete($tempFileName)
	FileDelete($tempEncFileName)

	MsgBox($MB_OK, "Screenshot Saved", $encFileName)
	;Local $response = MsgBox($MB_YESNO, "Screenshot Saved", "Need to send Lotus Note?" &@CRLF& $fileName)
    ; Clean up resources
    _GDIPlus_BitmapDispose ($hBitmap)
    ; Shut down GDI+ library
    _GDIPlus_ShutDown ()
	;If $response = $IDYES Then
	;	OpenNotes($fileName)
	;EndIf
EndFunc

Func OpenNotes($iFile)
	ShellExecute("mailto:test@test.com?subject=testing&body= Please see attachment","","","",0)
	Local $iPID = ShellExecute("notes", "mailto:csa18_ehr@dh.gov.hk?subject=CIMS_SCREENSHOT&body=some text&attach="&$iFile)
	;Since doctor not always login the lotus, the above solution it not so applicable to the user, just open lotus note for them
	;Local $iPID = ShellExecute("notes")
EndFunc

Func UpdateTemplate($FilePath, $hEdit)
	Local $hFileOpen = FileOpen($FilePath, $FO_READ)

	If $hFileOpen = -1 Then
        MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.")
        Return False
    EndIf

	$gFileRead = FileRead($hFileOpen)
	;MsgBox($MB_SYSTEMMODAL, "", "The combobox is currently displaying: " & $FilePath & $sFileRead, 0)
	FileClose($hFileOpen)
	GUICtrlSetData($hEdit, $gFileRead)
EndFunc

Func OpenTemplate()
    Local $hGui, $hRichEdit, $iMsg
	Local $sFolder = $gTemplateFolder
	Local $FileList = _FileListToArray($sFolder, "*.txt")

    $hGui = GUICreate("Util", 600, 600, -1, -1, BitOr($WS_BORDER, $WS_POPUP), $WS_EX_TOOLWINDOW)
	$hEdit = GuiCtrlCreateEdit("",10,50,550,550,BitOR($ES_MULTILINE,$WS_VSCROLL))
	$mylist = GUICtrlCreateCombo("", 10, 10, 400, 10, BitOR($CBS_DROPDOWNLIST, $CBS_SORT))
	$idCopy = GUICtrlCreateButton("Copy and Close", 420, 10, 170, 25, $BS_DEFPUSHBUTTON )
	For $i = 1 To $FileList[0]
		GUICtrlSetData($mylist, $FileList[$i])
	Next
	If $FileList[0] > 0 Then
		_GUICtrlComboBox_SetCurSel($mylist,0)
		$sComboRead = GUICtrlRead($mylist)
		UpdateTemplate($sFolder & "\" & $sComboRead, $hEdit)
	EndIf

    GUISetState(@SW_SHOW, $hGUI)
	_WinAPI_SetFocus(ControlGetHandle("Util", "", $mylist))
	Local $oldComboRead = ""
    While True
        $iMsg = GUIGetMsg()
        Select
            Case $iMsg = $GUI_EVENT_CLOSE
                 GUIDelete()   ; is OK too
				 ExitLoop
            Case $iMsg = $mylist
                $sComboRead = GUICtrlRead($mylist)
				If $sComboRead <> $oldComboRead Then
					$oldComboRead = $sComboRead
					UpdateTemplate($sFolder & "\" & $sComboRead, $hEdit)
				EndIf
			Case $iMsg = $idCopy
                ; Run Notepad with the window maximized.
                ClipPut($gFileRead)
				GUIDelete()   ; is OK too
				ExitLoop
        EndSelect
    WEnd
EndFunc


While 1
	Sleep(1000)
WEnd