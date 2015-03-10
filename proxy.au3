#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#NoTrayIcon

GUICreate("Yaxy proxy", 150, 70, -1, -1, BitOr($WS_SYSMENU, $WS_MINIMIZEBOX))
$enablebtn = GUICtrlCreateButton("On", 10, 10, 60)
$disablebtn = GUICtrlCreateButton("Off", 80, 10, 60)

Dim $guishow = False

Opt("TrayOnEventMode",1)
Opt("TrayMenuMode",1)

$exit = TrayCreateItem("Exit")
TrayItemSetOnEvent(-1,"ExitEvent")

TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE,"ToggleGui")

TraySetState()
TraySetClick (8)

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
  setproxy("127.0.0.1", "8558")
  RunWait ("npm.cmd install", "")
  $yaxypid = Run("node node_modules/yaxy/bin/proxy.js","", @SW_HIDE)
  GUICtrlSetState($enablebtn, $GUI_DISABLE)
  GUICtrlSetState($disablebtn, $GUI_ENABLE)
EndFunc

Func disableproxy()
  removeproxy()
  $res = ProcessClose  ($yaxypid)
  GUICtrlSetState($disablebtn, $GUI_DISABLE)
  GUICtrlSetState($enablebtn, $GUI_ENABLE)
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
