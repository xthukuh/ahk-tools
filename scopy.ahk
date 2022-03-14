#SingleInstance, force
#Persistent

;vars
xalert_title := script := "SCopy"
sub := A_Args.Length() ? xtrim(A_Args[1]) : ""

;call sub
if !(sub && IsLabel(sub))
{
	xalert_danger("Invalid/unsupported subroutine """ sub """!")
	ExitApp
}
Gosub, % sub
ExitApp

;copy default signature
sig:
cmd := A_AhkPath
cmd .= """" A_ScriptDir "\signature\sig.ahk"""
RunWait, %cmd%
return

;head (start code)
head:
str =
(
#SingleInstance, force
#Persistent
#NoEnv

SendMode, Input
SetBatchLines, -1
SetWorkingDir, `% A_ScriptDir
)
Clipboard := str
xalert_info(str, script " - Head Copied!")
return

;requires
#Include, <xalert>
#Include, <xtrim>

