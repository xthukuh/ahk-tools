#SingleInstance, force
#Persistent
#NoEnv
SendMode, Input
SetBatchLines, -1
SetWorkingDir, % A_ScriptDir

;script
script_title := "Export AHK"
xconfig.config_ini := A_ScriptDir "\export.ini"

;gui layout values
gui_x := 12
gui_y := 12
gap_x := 10
gap_y := 10
label_width := 120
input_width := 250
input_height := 20
input_btn_width := 50
input_btn_height := 20
btn_width := 150
btn_height := 30

/*
input_height2 := 80
input_height3 := 70
input_height_text := 100
checkbox_x := gui_x + label_width + gap_x

ctrl_width := label_width + gap_x + input_width + gap_x + input_btn_width
btn_x := gui_x + ctrl_width - btn_width + 13
btn_y := 425
debug_limit_gap := 10
debug_limit_width := 221
input_height_console := 330
tab_x := 12
tab_y := 8
tab_width := ctrl_width + 30
tab_height := 410
username_x := tab_x
username_y := btn_y
*/

;gui - script
Gui, Add, Text, x%gui_x% y%gui_y% w%label_width%, Export Script
Gui, Add, Edit, x+%gap_x% w%input_width% h%input_height% ReadOnly v_export_script, % config.data("export_script")
Gui, Add, Button, x+%gap_x% w%input_btn_width% h%input_btn_height% g_btn_export_script, Select

;gui - script
Gui, Add, Text, x%gui_x% y+%gap_y% w%label_width%, Destination
Gui, Add, Edit, x+%gap_x% w%input_width% h%input_height% ReadOnly v_export_dest, % config.data("export_dest")
Gui, Add, Button, x+%gap_x% w%input_btn_width% h%input_btn_height% g_btn_export_dest, Select

;gui - export
Gui, Add, Button, x%gui_x% y+%gap_y% w%btn_width% h%btn_height%  g_btn_export, Export

;gui - show
Gui, Show,, % script_title
return

;gui - close
GuiClose:
GuiEscape:
ExitApp

_btn_export_script:
if (path := xfile_select("Select export script.",, "AHK Script (*.ahk)", A_ScriptDir "/../"))
{
	GuiControl,, _export_script, % path
	config.save("export_script", path)
}
return

_btn_export_dest:
if (path := xdir_select("Select export destination.",, "*" A_ScriptDir "/../"))
{
	GuiControl,, _export_dest, % path
	config.save("export_dest", path)
}
return

_btn_export:
Gui, Submit, NoHide
s := "_export_script: " _export_script "`n"
s .= "_export_dest: " _export_dest "`n"
xalert(s)
return