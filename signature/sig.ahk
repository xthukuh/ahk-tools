#SingleInstance, Force
#Persistent

script := "Signature"
title := A_Args.Length() && (title := Trim(A_Args[1], " `r`n`t")) != "" ? title : ""
mode := A_Args.Length() >= 2 ? Abs(Floor(A_Args[2] * 1)) : 0

;template file
file := A_Args.Length() >= 3 && (file := Trim(A_Args[3], " `r`n`t")) != "" ? file : "template.txt"
SplitPath, file,, dir, ext, name
file := (dir ? dir : A_ScriptDir) "/" name "." (ext ? ext : "txt")

;check template
IfNotExist, % file
{
	MsgBox, 262192, %script%, Could not find signature template file.`n%file%
	ExitApp
}

;read template
FileRead, sig, % file
if !(sig := Trim(sig, " `r`n`t"))
{
	MsgBox, 262192, %script%, Signature template is empty.
	ExitApp	
}

;template replace
FormatTime, now, %A_Now%, yyyy-MM-dd HH:mm:ss
StringReplace, sig, sig, {title}, %title%, All
StringReplace, sig, sig, {timestamp}, %now%, All
sig := Trim(sig, " `r`n`t")

;modes
if (mode == 0)
{
	s := "/*"
	loop, parse, sig, `n
		s .= "`n`t" Trim(A_LoopField, " `r`t")
	s .= "`n*/"
	sig := s
}
else if (mode == 1){
	s := ""
	loop, parse, sig, `n
		s .= (s != "" ? "`n" : "") "; " Trim(A_LoopField, " `r`t")
	sig := s
}

;copy sig
Clipboard := sig
MsgBox, 262208, %script% - Copied!, %sig%, 2
ExitApp