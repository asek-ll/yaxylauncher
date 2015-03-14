#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#NoTrayIcon

$yaxyPort = IniRead ( "yaxy-launcher.ini", "yaxy", "port", "8559" )
$yaxyConfig = IniRead ( "yaxy-launcher.ini", "yaxy", "config", "" )
$yaxyProxy = IniRead ( "yaxy-launcher.ini", "yaxy", "proxy", "" )

GUICreate("Yaxy proxy", 150, 70, -1, -1, BitOr($WS_SYSMENU, $WS_MINIMIZEBOX))
$enablebtn = GUICtrlCreateButton("On", 10, 10, 60)
$disablebtn = GUICtrlCreateButton("Off", 80, 10, 60)

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

Func enableproxy()
  setproxy("127.0.0.1", $yaxyPort)
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

  GUICtrlSetState($enablebtn, $GUI_DISABLE)
  GUICtrlSetState($disablebtn, $GUI_ENABLE)

  TrayItemSetState($turnOnMenuItem,$TRAY_CHECKED)
  TrayItemSetState($turnOffMenuItem,$TRAY_UNCHECKED)
EndFunc

Func disableproxy()
  removeproxy()
  $res = ProcessClose  ($yaxypid)
  GUICtrlSetState($disablebtn, $GUI_DISABLE)
  GUICtrlSetState($enablebtn, $GUI_ENABLE)

  TrayItemSetState($turnOffMenuItem,$TRAY_CHECKED)
  TrayItemSetState($turnOnMenuItem,$TRAY_UNCHECKED)
EndFunc

Func close()
  disableproxy()
  Exit
EndFunc

enableproxy()

While 1
  $msg = GUIGetMsg()

  Select
    Case $msg = $enablebtn
      enableproxy()

    Case $msg = $disablebtn
      disableproxy()

    Case $msg = $GUI_EVENT_CLOSE
      disableproxy()
      ExitLoop
    Case $msg = $GUI_EVENT_MINIMIZE
      GUISetState(@SW_HIDE)
      $guishow = false
  EndSelect

WEnd 
