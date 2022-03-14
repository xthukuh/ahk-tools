; Splitter - By Martin Thuku (2021-05-16 15:14:20)
#SingleInstance, Force
#Persistent

script := "Splitter"

;param options
opts := {"-c": 0, "-s": "CSV", "-j": "\n", "-t": 1, "-e": 0}
key =
Loop, % A_Args.Length()
{
	v := A_Args[A_Index]
	if opts.HasKey(v)
	{
		key := v
		continue
	}
	else if key !=
	{
		opts[key] := v
		key =
	}
}

;gui - steal focux
Gui, Add, Edit, x0 y0 w0 h0,

;gui - input
Gui, Add, Text, x12 y10 w400, Split Text
input_str =
if opts["-c"]
	input_str = %Clipboard%
Gui, Add, Edit, x12 y+10 w400 h200 v_input, % input_str

;gui - split
Gui, Add, Text, x12 y+10, Split
Gui, Add, Edit, x+10 w200 h20 v_split, % opts["-s"]

;gui - join
Gui, Add, Text, x+10, Join
Gui, Add, Edit, x+10 w125 h20 v_join, % opts["-j"]

;gui - trim
trimmed := opts["-t"] ? 1 : 0
Gui, Add, Checkbox, x12 y+10 v_trim Checked%trimmed%, Trim

;gui - empty
empty := opts["-e"] ? 1 : 0
Gui, Add, Checkbox, x+20 v_empty Checked%empty%, Empty

;gui - output
Gui, Add, Edit, x12 y+10 w400 h200 v_output ReadOnly,

;gui - buttons
Gui, Add, Button, x+-80 y+10 h30 w80 Default v_do_split g_do_split, Split
Gui, Add, Button, xp-90 h30 w80 v_do_clear g_do_clear, Clear
Gui, Add, Button, xp-90 h30 w80 v_do_out_in g_do_out_in, Out-In
Gui, Add, Button, x12 yp h30 w80 v_do_cancel g_do_cancel, Cancel

;gui - show
Gui, Show,, % script
return

;gui close
_do_cancel:
GuiEscape:
GuiClose:
ExitApp

;split
_do_split:
Gui, Submit, NoHide
_join := _norm(_join)
_split := _norm(_split)
s =
loop, parse, _input, %_split%
{
	v := A_LoopField
	if _trim
		v := Trim(v, " `r`n`t")
	if (v == "" && !_empty)
		continue
	s .= (s != "" ? _join : "") v
}
GuiControl,, _output, % s
return

;clear
_do_clear:
GuiControl,, _input,
GuiControl,, _output,
return

;output to input
_do_out_in:
GuiControlGet, _output,, _output
GuiControl,, _input, % _output
GuiControl,, _output,
return

;normalize delimiter
_norm(v){
	StringReplace, v, v, \r, `r
	StringReplace, v, v, \n, `n
	StringReplace, v, v, \t, `t
	return v
}