#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=..\deploy\secure_viewer.exe
#AutoIt3Wrapper_UseX64=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Array.au3>
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <GDIPlus.au3>
#include <GuiScrollBars.au3>
#include <GUIConstantsEx.au3>
#include <GuiScrollBars.au3>
#include <StructureConstants.au3>
#include <WindowsConstants.au3>

Global $gaDropFiles[1], $iDropItem = -1
;Global $WM_DROPFILES = 0x233

Global $gTempFolder = IniRead("config.ini", "Image Viewer", "temp_folder", @ScriptDir & "\temp")
Global $gPrivateKey = IniRead("config.ini", "Image Viewer", "keystore_file", @ScriptDir & "\key\keystore.pkcs8")
Global $gOpensslExe = IniRead("config.ini", "Image Viewer", "openssl_exe", @ScriptDir & "\openssl\openssl.exe")
Global $gMaxImageHeight = IniRead("config.ini", "Image Viewer", "max_height", "768")
Global $gMaxImageWidth = IniRead("config.ini", "Image Viewer", "max_width", "1024")

Global $hGraphics, $hImages;
;Global $isDrawImage = False

$hGUI = GUICreate("DropIt", 200, 200, @DesktopWidth / 2 - 160, @DesktopHeight / 2 - 45, -1, 0x00000018 ); WS_EX_ACCEPTFILES
$FILES_DROPPED = GUICtrlCreateDummy()
;GUICtrlSetResizing($hGUI, $GUI_DOCKALL)
GUISetState()
_GDIPlus_StartUp()
GUIRegisterMsg($WM_DROPFILES, 'WM_DROPFILES_FUNC')
$gPassword = InputBox("Please input keystore password","Please input keystore password","","*")

While True
	$msg = GUIGetMsg(1)
	Select
		Case $msg[0] = $GUI_EVENT_CLOSE
         If $msg[1] = $hGUI Then
            ExitLoop
         Else
            GUISwitch($msg[1])
            GUIDelete()
         EndIf
		Case $msg[0] = $FILES_DROPPED
            $aFiles = $gaDropFiles
            decrypt_file($aFiles)
			;_ArrayDisplay($aFiles)
	EndSelect
WEnd

; Clean up resources
_ArrayDisplay($hGraphics)
For $i = 0 To UBound($hGraphics)-1
	_GDIPlus_GraphicsDispose($hGraphics[$i])
Next
_GDIPlus_ShutDown()


Func decrypt_file($aFiles)
	If UBound($aFiles) < 2 Then
		MsgBox($MB_OK, "Insufficient File", "It must be two files");
		Return
	Else
		$encFileName = $aFiles[0]
		$encKey = $aFiles[1]
		If StringRight($aFiles[0], 8) = ".key.enc" Then
			$encFileName = $aFiles[1]
			$encKey = $aFiles[0]
		EndIf
		Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
		$tempKeyPathSplit = _PathSplit($encKey, $sDrive, $sDir, $sFileName, $sExtension)
		$tempKey = $gTempFolder & "\" & $tempKeyPathSplit[3]
		;StringLeft($tempKeyPathSplit[3], StringLen($tempKeyPathSplit[3])-4)
		$tempFilePathSplit = _PathSplit($encFileName, $sDrive, $sDir, $sFileName, $sExtension)
		$tempFileName = $gTempFolder & "\" & $tempFilePathSplit[3]
		;StringLeft($tempFilePathSplit[3], StringLen($tempFilePathSplit)-4)

		;MsgBox($MB_OK, $encKey, $encFileName )
		;MsgBox($MB_OK, $tempKey , $tempFileName )
		;MsgBox($MB_OK, $gOpensslExe , $gPrivateKey )
		;ShellExecuteWait($gOpensslExe, "rsautl -decrypt -inkey " & $gPrivateKey &" -in " & $encKey & " -out " & $tempKey )
		ShellExecuteWait($gOpensslExe, "rsautl -decrypt -inkey " & $gPrivateKey &" -in " & $encKey & " -out " & $tempKey & " -passin pass:" & $gPassword)

		ShellExecuteWait($gOpensslExe, "enc -d -aes-256-cbc -in " & $encFileName & " -out " & $tempFileName & " -pass file:" & $tempKey)
		$hCHILD = GUICreate($tempFileName, 1024, 768, 0, 0, -1, $WS_SIZEBOX)
        GUISetState()
		$hGraphic = _GDIPlus_GraphicsCreateFromHWND($hCHILD)
		$hImage   = _GDIPlus_ImageLoadFromFile($tempFileName)

		Local $ImageWidth = _GDIPlus_ImageGetWidth($hImage)
        Local $ImageHeight = _GDIPlus_ImageGetHeight($hImage)
		Local $ratio = 1
		Local $ImageNewWidth = $ImageWidth
		Local $ImageNewHeight = $ImageHeight
		If $ImageNewHeight > $gMaxImageHeight  Then
			$ratio =  $gMaxImageHeight / $ImageNewHeight
			$ImageNewWidth = $ratio * $ImageNewWidth
			$ImageNewHeight = $ratio * $ImageNewHeight
		EndIf

		If $ImageNewWidth > $gMaxImageWidth Then
			$ratio = $gMaxImageWidth / $ImageNewWidth
			$ImageNewWidth = $ratio * $ImageNewWidth
			$ImageNewHeight = $ratio * $ImageNewHeight
		EndIf


		$hWnd = _WinAPI_GetDesktopWindow()
		$hDC = _WinAPI_GetDC($hWnd)
		$hBMP = _WinAPI_CreateCompatibleBitmap($hDC, $ImageNewWidth,$ImageNewHeight)
		_WinAPI_ReleaseDC($hWnd, $hDC)
		;Get the handle of blank bitmap you created above as an image
		$hImageResized = _GDIPlus_BitmapCreateFromHBITMAP ($hBMP)
		$hGraphicResized = _GDIPlus_ImageGetGraphicsContext ($hImageResized)
		_GDIPLus_GraphicsDrawImageRect($hGraphicResized, $hImage, 0, 0, $ImageNewWidth,$ImageNewHeight)

		;_GDIPlus_GraphicsDrawImageRect($newGC,$hImage,0,0,$gMaxImageWidth,$gMaxImageHeight)
		GUISwitch($hGUI)
		; Draw PNG image
		_GDIPlus_GraphicsDrawImage($hGraphic, $hImageResized, 0, 0)
		_GDIPlus_ImageDispose($hImage)
		_GDIPlus_ImageDispose($hImageResized)
		_GDIPlus_GraphicsDispose($hGraphic)
		_GDIPlus_GraphicsDispose($hGraphicResized)
		FileDelete($tempKey)
		FileDelete($tempFileName)
	EndIf
EndFunc


Func WM_DROPFILES_FUNC($hWnd, $msgID, $wParam, $lParam)
    Local $nSize, $pFileName
    Local $nAmt = DllCall('shell32.dll', 'int', 'DragQueryFileW', 'hwnd', $wParam, 'int', 0xFFFFFFFF, 'ptr', 0, 'int', 0)
    ReDim $gaDropFiles[$nAmt[0]]
    For $i = 0 To $nAmt[0] - 1
        $nSize = DllCall('shell32.dll', 'int', 'DragQueryFileW', 'hwnd', $wParam, 'int', $i, 'ptr', 0, 'int', 0)
        $nSize = $nSize[0] + 1
        $pFileName = DllStructCreate('wchar[' & $nSize & ']')
        DllCall('shell32.dll', 'int', 'DragQueryFileW', 'hwnd', $wParam, 'int', $i, 'ptr', DllStructGetPtr($pFileName), 'int', $nSize)
        $gaDropFiles[$i] = DllStructGetData($pFileName, 1)
        $pFileName = 0
    Next
    GUICtrlSendToDummy($FILES_DROPPED, $nAmt[0])
EndFunc   ;==>WM_DROPFILES_FUNC



