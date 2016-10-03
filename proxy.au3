#include <Constants.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#NoTrayIcon

$yaxyPort = IniRead ( "yaxy-launcher.ini", "yaxy", "port", "8558" )
$yaxyConfig = IniRead ( "yaxy-launcher.ini", "yaxy", "config", "" )
$yaxyProxy = IniRead ( "yaxy-launcher.ini", "yaxy", "proxy", "" )

$yaxyEnabled = False
$globalEnabled = False

GUICreate("Yaxy proxy", 154, 70, -1, -1, BitOr($WS_SYSMENU, $WS_MINIMIZEBOX))

$yaxyBtn = GUICtrlCreateCheckbox("Yaxy", 10, 10, 60, 25, $BS_PUSHLIKE)
$proxyBtn = GUICtrlCreateCheckbox("Global", 80, 10, 60, 25, $BS_PUSHLIKE)

Dim $guishow = False

Opt("TrayOnEventMode",1)
Opt("TrayMenuMode",1)

$exit = TrayCreateItem("Exit")
TrayItemSetOnEvent($exit,"close")

TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE,"ToggleGui")

TraySetState()
TraySetClick(8)

$turnOnMenuItem = TrayCreateItem("On", -1, -1, 1)
TrayItemSetOnEvent($turnOnMenuItem,"enableproxy")
$turnOffMenuItem = TrayCreateItem("Off", -1, -1, 1)
TrayItemSetOnEvent($turnOffMenuItem,"disableproxy")

Func ToggleGui() 
  If $guishow = True Then
    GUISetState(@SW_HIDE)
  Else
    GUISetState(@SW_SHOW)
  EndIf
  $guishow = not $guishow
EndFunc

Dim $yaxypid

Func setproxy($host, $port) 
  $key = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
  $reg = RegWrite($key, "ProxyEnable", "REG_DWORD", "1")
  $reg1 = RegWrite($key, "ProxyServer", "REG_SZ", $host & ":" & $port)
  DllCall('WININET.DLL', 'long', 'InternetSetOption', 'int', 0, 'long', 39, 'str', 0, 'long', 0)
EndFunc

Func removeproxy()
  $key = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
  $reg = RegWrite($key, "ProxyEnable", "REG_DWORD", "0")
  DllCall('WININET.DLL', 'long', 'InternetSetOption', 'int', 0, 'long', 39, 'str', 0, 'long', 0)
EndFunc

Func setGlobalProxy()
  setproxy("127.0.0.1", $yaxyPort)
EndFunc

Func enableproxy()

  If $globalEnabled Then
    setGlobalProxy()
  EndIf

  RunWait ("npm.cmd install", "")

  $args = ""
  
  $args = $args & " --port " & $yaxyPort

  If $yaxyConfig <> "" Then
    $args = $args & " --config " & $yaxyConfig
  EndIf

  If $yaxyProxy <> "" Then
    $args = $args & " --proxy " & $yaxyProxy
  EndIf

  $yaxypid = Run("node node_modules/yaxy/bin/proxy.js" & $args,"", @SW_HIDE)
  If $yaxypid == 0 Then
    MsgBox ( 4096, "Error", "Yaxy not started")
    return
  EndIf

  GUICtrlSetState($yaxyBtn, $GUI_CHECKED)

  TrayItemSetState($turnOnMenuItem,$TRAY_CHECKED)
  TrayItemSetState($turnOffMenuItem,$TRAY_UNCHECKED)

  $yaxyEnabled = True
EndFunc

Func disableproxy()
  If $globalEnabled Then
    removeproxy()
  EndIf

  $res = ProcessClose  ($yaxypid)

  $yaxyEnabled = False

  GUICtrlSetState($yaxyBtn, $GUI_UNCHECKED)

  TrayItemSetState($turnOffMenuItem,$TRAY_CHECKED)
  TrayItemSetState($turnOnMenuItem,$TRAY_UNCHECKED)
EndFunc

Func enableGlobalProxy()
  $globalEnabled = True;
  If $yaxyEnabled Then
    setGlobalProxy()
  EndIf
EndFunc

Func disableGlobalProxy()
  $globalEnabled = False;
  If $yaxyEnabled Then
    removeproxy()
  EndIf
EndFunc

Func close()
  disableproxy()
  Exit
EndFunc

enableproxy()

While 1
  $msg = GUIGetMsg()

  Switch $msg
    Case $yaxyBtn
      Switch GUICtrlRead($yaxyBtn)
        Case $GUI_CHECKED
          enableproxy()
        Case $GUI_UNCHECKED
          disableproxy()
      EndSwitch

    Case $proxyBtn
      Switch GUICtrlRead($proxyBtn)
        Case $GUI_CHECKED
          enableGlobalProxy()
        Case $GUI_UNCHECKED
          disableGlobalProxy()
      EndSwitch

    Case $GUI_EVENT_CLOSE
      disableproxy()
      ExitLoop

    Case $GUI_EVENT_MINIMIZE
      GUISetState(@SW_HIDE)
      $guishow = false
  EndSwitch

WEnd 
