#SingleInstance, force
#Persistent

^!T::
WinGet, hwnd, ID, A
WinSet, AlwaysOnTop, Toggle, ahk_id %hwnd%
return