#SingleInstance, force
#Persistent
#NoEnv
#Include, %A_LineFile%/../IniStore.ahk

;tray
Menu, Tray, DeleteAll
Menu, Tray, NoDefault
Menu, Tray, NoStandard
Menu, Tray, Add, Show, _show
Menu, Tray, Add, Cache Reset, _cache_reset
Menu, Tray, Add, Cache Delete, _cache_delete
Menu, Tray, Add,
Menu, Tray, Add, Pause, _pause
Menu, Tray, Add, Reload, _reload
Menu, Tray, Add, Quit, _quit
Menu, Tray, Default, Show
Menu, Tray, Click, 1
Menu, Tray, Tip, % script_title

;on close
OnExit("ExitHandler")

;main
;_main:
script_title := "Create Copy"
script_store := new IniStore()
script_paused := 0
starting_folder := A_WorkingDir != A_ScriptDir ? "*" A_WorkingDir : ""
hashes_file := ".hashes"
copy_from := script_store.get("copy_from")
copy_to := script_store.get("copy_to")
tmp := ""
if copy_from
	tmp .= copy_from
if (copy_to && copy_to != tmp)
	tmp .= (tmp != "" ? "|" : "") copy_to
copy_paths := script_store.get("copy_paths", tmp)
copy_exclude := script_store.get("copy_exclude", ".vscode,.git,node_modules,vendor,build")
copy_action_copy := script_store.get("copy_action_copy", 1)
copy_action_hash := script_store.get("copy_action_hash", 0)
copy_exclude_ask := script_store.get("copy_exclude_ask", 0)
copy_overwrite_ask := script_store.get("copy_overwrite_ask", 1)
copy_write_new := script_store.get("copy_write_new", 0)
copy_folders := script_store.get("copy_folders", 0)
copy_changes := script_store.get("copy_changes", 0)
copy_count := 0
copy_done := 0
copy_busy := 0
toggle_ctrls := "_from,_to,_from_select,_to_select,_exclude,_action_hash,_action_copy,_exclude_ask,_overwrite_ask,_write_new,_folders,_changes,_submit"
exclude_info := "Comma separated path match regex (^_MATCH_REGEX_$). (Directory Separator=/)"
exclude_info .= "`nMatching paths will be excluded during copy/hash."

;create gui
_main:
Gui, Destroy
Gui, +LastFound
gui_hwnd := WinExist()
Gui, Add, Edit, x0 y0 w0 h0,

Gui, Add, Text, xm ym w60 -Wrap, Source
Gui, Add, DropDownList, x+5 yp w350 h100 v_from, % copy_paths
Gui, Add, Button, x+5 yp-1 w70 h22 v_from_select g_select_dir, Select

Gui, Add, Text, xm y+5 w60 -Wrap, Destination
Gui, Add, DropDownList, x+5 yp w350 h100 v_to, % copy_paths
Gui, Add, Button, x+5 yp-1 w70 h22 v_to_select g_select_dir, Select

Gui, Add, Text, xm y+5 w60 -Wrap, Exclusions
Gui, Font, S10 CDefault, Consolas
Gui, Add, Edit, x+5 yp w425 h80 v_exclude, % copy_exclude
Gui, Font
Gui, Font, S8
Gui, Add, Text, xp y+2 wp cGray, % exclude_info
Gui, Font,

Gui, Add, Radio, x+-110 y+10 w110 v_action_hash Checked%copy_action_hash% Group Section, Hash Source Files
Gui, Add, Radio, xp-85 ys w75 -Wrap v_action_copy Checked%copy_action_copy%, Create Copy

Gui, Add, Button, x+-80 y+10 w200 h35 v_start g_start_toggle, Start
Gui, Add, Button, xp y+5 w200 h30 v_submit g_submit, Submit

Gui, Add, Checkbox, xm ys v_exclude_ask Checked%copy_exclude_ask%, Ask exclude skip confirmation.
Gui, Add, Checkbox, xm y+5 v_overwrite_ask Checked%copy_overwrite_ask%, Ask overwrite confirmation.
Gui, Add, Checkbox, xm y+5 v_write_new Checked%copy_write_new%, Copy write new.
Gui, Add, Checkbox, xm y+5 v_folders Checked%copy_folders%, Copy folders.
Gui, Add, Checkbox, xm y+5 v_changes Checked%copy_changes%, Copy changes.
Gui, Add, StatusBar,,

if copy_from
	GuiControl, Choose, _from, % copy_from
if copy_to
	GuiControl, Choose, _to, % copy_to
Gui, Show,, % script_title

_sb(A_WorkingDir, "Ready!")
return

;show
_show:
WinHide, ahk_id %gui_hwnd%
WinShow, ahk_id %gui_hwnd%
WinActivate, ahk_id %gui_hwnd%
return

;gui close
_quit:
GuiEscape:
GuiClose:
ExitApp

;cache reset
_cache_reset:
is_busy := copy_busy == 1
if is_busy && !_confirm("Confirm cache reset?")
	return
path := script_store.getPath()
if !_file_delete(path)
	return
GuiControl,, _exclude, % ".vscode,.git,node_modules,vendor,build"
GuiControl,, _action_copy, 1
GuiControl,, _action_hash, 0
GuiControl,, _exclude_ask, 0
GuiControl,, _overwrite_ask, 1
GuiControl,, _write_new, 0
GuiControl,, _folders, 0
GuiControl,, _changes, 0
copy_paths := ""
copy_to := ""
copy_from := ""
gosub, _submit
if is_busy
	Reload
else gosub, _main
return

;cache delete
_cache_delete:
if !_confirm("Confirm cache delete?")
	return
path := script_store.getPath()
if !_file_delete(path)
	return
ExitApp

;reload
_reload:
Reload
return

;pause
_pause:
menu_name := script_paused ? "Resume" : "Pause"
menu_rename := !script_paused ? "Resume" : "Pause"
Menu, Tray, Rename, %menu_name%, %menu_rename%
script_paused := !script_paused
Pause, % script_paused ? "On" : "Off"
return

;select folder
_select_dir:
Gui, +OwnDialogs
to := A_GuiControl == "_to_select"
GuiControlGet, tmp,, % (to ? "_to" : "_from")
if (tmp := _trim(tmp))
	starting_folder := "*" tmp
opts := to ? 1 : 0
prompt := "Select " (to ? "destination" : "source") " folder." 
FileSelectFolder, path, % starting_folder, % opts, % prompt
	if (ErrorLevel || !(path := _trim(path)))
		return
paths := _copy_paths(path)
if (paths != copy_paths)
{
	copy_paths := paths
	script_store.set("copy_paths", copy_paths)
	GuiControlGet, tmp,, % (to ? "_from" : "_to")
	GuiControl,, _to, % "|" copy_paths
	GuiControl,, _from, % "|" copy_paths
	if (tmp := _trim(tmp))
		GuiControl, Choose, % (to ? "_from" : "_to"), % tmp
}
script_store.set("copy_" (to ? "to" : "from"), path)
GuiControl, Choose, % (to ? "_to" : "_from"), % path
return

;default state
_default_state:
_ctrls_enable(1)
_start_ctrl("Start", 1)
return

;submit
_submit:
_ctrls_enable(0)
_start_ctrl("", 0)
Gui, Submit, NoHide

;check from
if !((_from := _trim(_from)) && _is_dir(_from))
{
	_warn("Copy ""From"" is undefined!")
	gosub, _default_state
	return
}

;check to
if !(_to := _trim(_to))
{
	_warn("Copy ""To"" is undefined!")
	gosub, _default_state
	return
}

;update copy from
if (_from != copy_from)
	copy_from := script_store.set("copy_from", _from)

;update copy to
if (_to != copy_to)
	copy_to := script_store.set("copy_to", _to)

;update copy paths
copy_paths := copy_paths "|" copy_from "|" copy_to
if ((tmp := _copy_paths()) != copy_paths)
	copy_paths := script_store.set("copy_paths", tmp)

;update action copy
if (_action_copy != copy_action_copy)
	copy_action_copy := script_store.set("copy_action_copy", _action_copy)

;update action hash
if (_action_hash != copy_action_hash)
	copy_action_hash := script_store.set("copy_action_hash", _action_hash)

;update exclude
if ((_exclude := _copy_exclude(_exclude)) != copy_exclude)
	copy_exclude := script_store.set("copy_exclude", _exclude)

;update exclude ask
if (_exclude_ask != copy_exclude_ask)
	copy_exclude_ask := script_store.set("copy_exclude_ask", _exclude_ask)

;update exclude ask
if (_overwrite_ask != copy_overwrite_ask)
	copy_overwrite_ask := script_store.set("copy_overwrite_ask", _overwrite_ask)

;update write new
if (_write_new != copy_write_new)
	copy_write_new := script_store.set("copy_write_new", _write_new)

;update copy folders
if (_folders != copy_folders)
	copy_folders := script_store.set("copy_folders", _folders)

;update copy changes
if (_changes != copy_changes)
	copy_changes := script_store.set("copy_changes", _changes)

;submit done
gosub, _default_state
return

;start toggle
_start_toggle:
if copy_busy
{
	copy_busy := 0
	_start_ctrl("Stopping...", 0)
	return
}
SetTimer, _start, 30
return

;start
_start:
SetTimer, _start, Off
gosub, _submit

;set busy
copy_done := 0
copy_size := 0
copy_count := 0
copy_busy := 1
_ctrls_enable(0)
_start_ctrl("Stop")

;action copy
if _action_copy
{
	;load hashes
	_sb(_from, "Loading hashes", 1)
	hashes_map := _hashes_map(_from)
	
	;copy files
	_copy_folder(_from, _to, hashes_map)

	;copy time
	if !_write_new
		_copy_time(_from, _to)
	
	;update hashes
	_hashes_map_save(hashes_map, 1)

	;copy done
	copy_done := copy_busy
	copy_status := !copy_done ? "cancelled" : (copy_done == -1 ? "failed" : "complete")
	_sb("Copied: " copy_count " (items) | Size: " _size(copy_size), "Status: " copy_status)
}

;action hash
if _action_hash
{
	;hash folder 
	_hash_folder(_from, "", hashes_map)
	
	;save hashes
	_hashes_map_save(hashes_map)

	;hash done
	copy_done := copy_busy
	copy_status := !copy_done ? "cancelled" : (copy_done == -1 ? "failed" : "complete")
	_sb("Hashed: " copy_count " (files)", "Status: " copy_status)
}

;goto stop
SetTimer, _stop, 30
return

;stop
_stop:
SetTimer, _stop, Off
copy_busy := 0
_ctrls_enable()
_start_ctrl("Start", 1)
return

;start control
_start_ctrl(text := "", enable := ""){
	ctrl := "_start"
	if (text != "")
		GuiControl,, % ctrl, % text
	if (enable != "")
		_enable(ctrl, !!enable)
}

;controls enable
_ctrls_enable(enable := 1){
	global toggle_ctrls
	loop, parse, toggle_ctrls, `,
		_enable(A_LoopField, enable)
}

;hashes map
_hashes_map(dir){
	global hashes_file

	;check dir
	if !_is_dir(dir)
		return _warn("Hashes map folder not found.`n" dir)

	;check hashes file
	path := dir "\" hashes_file
	if _is_file(path)
	{
		;set map
		map := {}
		map[":path"] := path

		;read loop
		loop {
			
			;read file line
			FileReadLine, line, % path, % A_index
			if ErrorLevel
				break
			
			;parse line - set file, hash
			hash_val := ""
			hash_path := ""
			loop, parse, line, `|
			{
				if !(val := _trim(A_LoopField))
					continue
				if (A_index == 1)
					hash_val := val
				if (A_index == 2)
					hash_path := val
			}

			;map file hash
			if (hash_val && hash_path)
				map[hash_path] := hash_val
		}
	}

	;result
	return map
}

;hashes map save
_hashes_map_save(map, _update := 0){
	global hashes_file, _overwrite_ask

	;check map
	if !IsObject(map)
		return
	
	;check path
	path_key := ":path"
	path := _trim(map[path_key])
	backup_path := path ".bak"
	map.Delete(path_key)
	SplitPath, path, fname, dir
	if (!(dir && fname == hashes_file)){
		_warn("Invalid hashes file path!`n" path)
		return
	}

	;hashes buffer
	buffer := ""
	for key, hash in map
		buffer .= (buffer != "" ? "`n" : "") hash "|" key
	
	;overwrite confirm
	if (!_update && _is_file(path) && _overwrite_ask && !_confirm("Overwrite existing file?`n" path))
		return
	
	;backup path
	if (_update && _is_file(path))
	{
		;delete existing backup
		if !_file_delete(backup_path)
			return
		
		;copy backup
		if !_create_copy(path, backup_path)
			return
	}

	;delete existing
	if !_file_delete(path)
		return

	;ignore empty
	if (buffer == "")
		return

	;append buffer
	FileAppend, % buffer, % path
	if ErrorLevel
	{
		_warn("Failed to append hashes buffer.")
		return
	}
}

;hash folder
_hash_folder(dir, _root := "", ByRef _map := ""){
	global
	local path, path_type, path_short, hash, tmp

	;check dir
	if !_is_dir(dir)
	{
		_warn("Hash folder not found.`n" dir)
		copy_done := -1
		copy_busy := 0
		return
	}
	
	;set root
	if !(_root := _trim(_root))
		_root := dir
	if !_is_dir(_root)
	{
		_warn("Hash root folder not found.`n" _root)
		copy_done := -1
		copy_busy := 0
		return
	}
	
	;set map
	if !IsObject(_map)
	{
		_map := {}
		_map[":path"] := _root "\" hashes_file
	}

	;loop files
	Loop, Files, % dir "\*.*" , FD
	{
		;check aborted
		if (copy_busy != 1)
			return

		;set path
		path := A_LoopFileFullPath
		path_type := _path_type(path)
		StringReplace, path_short, path, % _root,, All
		path_short := _trim(path_short, "\")
		
		;ignore hashes file
		if (path_type == "file" && IsObject(_map) && (_map[":path"] == path || _map[":path"] ".bak" == path))
			continue

		;skip exclusion
		if (tmp := _exclude_path(path_short))
		{
			if _exclude_ask
			{
				_sb("Skip exclusion: " tmp, path_short)
				if _confirm("Skip hash " path_type " exclusion (" tmp ")?`n" path_short)
					continue
			}
			else continue
		}

		;file hash
		if (path_type == "file")
		{
			_sb("File hash:", path_short, 1)
			_sb("Hash: " path_short, "Calculating hash", 1)
			hash := HashFile(path, 4)
			_map[path_short] := hash
			copy_count += 1
			_sb("Hashed: " copy_count " (files)")
		}

		;dir recurse
		if (path_type == "dir")
			_hash_folder(path, _root, _map)
	}
}

;copy folder
_copy_folder(_source, _dest, ByRef _map := "", _source_root := "", _dest_root := ""){
	global
	local source, source_type, source_path, dest, dest_type, create_copy, tmp, changed

	;check source
	if !_is_dir(_source)
	{
		_warn("Copy folder source not found.`n" _source)
		copy_done := -1
		copy_busy := 0
		return
	}
	
	;set root
	if !(_source_root := _trim(_source_root))
		_source_root := _source
	if !_is_dir(_source_root)
	{
		_warn("Copy folder source root not found.`n" _source_root)
		copy_done := -1
		copy_busy := 0
		return
	}
	if (_source_root == _source)
		_dest_root := _dest
	
	;loop files
	Loop, Files, % _source "\*.*" , FD
	{
		;check aborted
		if (copy_busy != 1)
			return
		
		;set vars
		create_copy := 1
		
		;source
		source := A_LoopFileFullPath
		source_size := A_LoopFileSize
		source_type := _path_type(source)
		StringReplace, source_path, source, % _source_root,, All
		source_path := _trim(source_path, "\")

		;ignore hashes file
		if (source_type == "file" && IsObject(_map) && (_map[":path"] == source || _map[":path"] ".bak" == source))
			continue
		
		;destination
		dest := _dest_root "\" source_path
		dest_type := _path_type(dest)

		;skip exclusion
		if (tmp := _exclude_path(source_path))
		{
			if _exclude_ask
			{
				_sb("Exclude: " tmp, source_path)
				if _confirm("Confirm skip excluded " source_type " (" tmp ")?`n" source_path)
					continue
			}
			else continue
		}

		;file copy
		if (source_type == "file")
		{
			;hash
			if IsObject(_map)
			{
				;check hash
				_sb("Copy check hash:", source_path, 1)
				source_hash := HashFile(source, 4)
				
				;check change
				changed := 1
				tmp_hash := _map[source_path]
				if _map.HasKey(source_path)
				{
					if (_map[source_path] == source_hash)
						changed := 0
				}
				else map_count += 1
				if changed
					_map[source_path] := source_hash
				
				;skip copy changes only
				if (_changes && !changed)
					continue
			}

			;duplicate
			if (source_type == dest_type)
			{
				;skip overwrite
				if _overwrite_ask && !_confirm("Overwrite existing file?`n" source_path)
					continue
				
				;delete existing
				if !_file_delete(dest, 1)
				{
					copy_done := -1
					copy_busy := 0
					return
				}
			}
		}

		;dir copy
		if (source_type == "dir")
		{
			;skip folders
			if !_folders
				create_copy := 0
		}

		;create copy
		if create_copy
		{
			_sb("Copy " source_type ": " source_path)
			if _create_copy(source, dest, _write_new, bytes)
			{
				copy_count += 1
				if bytes is number
					copy_size += bytes
				_sb("Copied: " copy_count " (items) " _size(copy_size))
			}
			else {
				copy_done := -1
				copy_busy := 0
				return
			}
		}

		;copy dir - recurse
		if (source_type == "dir")
		{
			_copy_folder(source, dest, _map, _source_root, _dest_root)
			if !_write_new
				_copy_time(source, dest)
		}
	}
}

;create copy
_create_copy(source, dest, write_new := 0, ByRef bytes := 0){
	bytes := 0

	;check source
	source_type := _path_type(source)
	if !source_type
	{
		_notify("Source does not exist!`n" source, "warning")
		return
	}

	;check destination
	dest := _trim(dest)
	SplitPath, dest, fname, dir
	if (!(dir && fname)){
		_notify("Invalid copy destination!`n" dest, "warning")
		return
	}

	;copy file
	if (source_type == "file")
	{
		;create dir
		IfNotExist, % dir
		{
			FileCreateDir, % dir
			if ErrorLevel
			{
				_notify("Failed to create dir: " dir, "warning")
				return
			}
		}

		;write new
		if write_new
		{
			;file open
			source_fo := FileOpen(source, "r")
			dest_fo := FileOpen(dest, "w")
			
			;file read/write
			failure := 0
			loop
			{
				;source read
				if (r_len := Strlen(data := source_fo.Read(1024)))
				{
					;dest write - add bytes written
					w_len := dest_fo.Write(data)
					bytes += w_len

					;compare bytes length
					if (w_len != r_len)
					{
						_notify("Compare copied bytes length failed! (" r_len "<>" w_len ")", "warning")
						failure := 1
						break
					}
				}
				else break
			}

			;file close
			source_fo.Close()
			dest_fo.Close()

			;write failure
			if failure
				return
			
			;copy failure
			if !FileExist(dest)
			{
				_notify("Failed to create new file copy: " dest, "warning")
				return
			}
		}
		else {

			;file copy
			FileCopy, % source, % dest

			;copy failure
			if !FileExist(dest)
			{
				_notify("Failed to copy file: " dest, "warning")
				return
			}

			;set bytes
			FileGetSize, tmp, % dest
			bytes := tmp
		}
	}

	;copy folder
	else if (source_type == "dir")
	{
		;create dir
		IfNotExist, % dest
		{
			FileCreateDir, % dest
			if ErrorLevel
			{
				_notify("Failed to create dir: " dest, "warning")
				return
			}
		}

		;copy failure
		if !FileExist(dest)
		{
			_notify("Failed to copy dir: " dest, "warning")
			return
		}
	}

	;result
	return dest
}

;copy time
_copy_time(source, dest){
	if !(FileExist(source) && FileExist(dest))
		return
	FileGetTime, _m, % source, M
	FileGetTime, _c, % source, C
	FileGetTime, _a, % source, A
	FileSetTime, % _m, % dest, M, 2
	FileSetTime, % _c, % dest, C, 2
	FileSetTime, % _a, % dest, A, 2
}

;copy paths
_copy_paths(path := ""){
	global copy_paths
	path := _trim(path)
	tmp := ""
	found := 0
	loop, parse, copy_paths, `|
	{
		val = %A_LoopField%
		if !val
			continue
		tmp .= (tmp != "" ? "|" : "") val
		if (path && val == path)
			found := 1
	}
	if (path && !found)
		tmp .= (tmp != "" ? "|" : "") path
	return tmp
}

;copy exclude
_copy_exclude(val){
	val := _trim(val)
	StringReplace, val, val, `r,, All
	StringReplace, val, val, `n, `,, All
	items := {}
	loop, parse, val, `,
	{
		if !(item := _trim(A_LoopField))
			continue
		items[item] := item
	}
	val := ""
	For key, item in items
		val .= (val != "" ? "," : "") item
	return val
}

;exclude path
_exclude_path(path){
	global _exclude
	if (path := _trim(path))
	{
		StringReplace, path, path, `\, `/, All
		loop, parse, _exclude, `,
		{
			if !(item := _trim(A_LoopField))
				continue
			reg := "^" _reg_esc(item) "$"
			if RegExMatch(path, reg)
				return item
		}
	}
}

;escape regex
_reg_esc(val){
	return RegExReplace(val, "[\.\*\+\?\^\$\{\}\(\)\|\[\]\\]", "\$0")
	;return "\E\Q" RegExReplace(val, "\\E", "\E\\E\Q") "\E"
}

;is dir
_is_dir(path){
	return (tmp := FileExist(path)) && InStr(tmp, "D")
}

;is file
_is_file(path){
	return (tmp := FileExist(path)) && !InStr(tmp, "D")
}

;path type
_path_type(path){
	return (tmp := FileExist(path)) ? (InStr(tmp, "D") ? "dir" : "file") : ""
}

;file delete
_file_delete(path, notify := 0){
	if _is_file(path)
	{
		FileDelete, % path
		if ErrorLevel
		{
			err := "File delete failed!`n" path 
			if notify
				_notify(err, "warning")
			else _warn(err)
			return
		}
	}
	return true
}

;size
_size(val){
	sz := "B"
	kb := 1024
	mb := 1024 ** 2
	gb := 1024 ** 3
	if (val >= kb && val < mb)
	{
		sz := "KB"
		val := RTrim(RTrim(Format("{:.3f}", val/kb), "0"), ".")
	}
	if (val >= mb && val < gb)
	{
		sz := "MB"
		val := RTrim(RTrim(Format("{:.3f}", val/mb), "0"), ".")
	}
	if (val >= gb)
	{
		sz := "GB"
		val := RTrim(RTrim(Format("{:.3f}", val/gb), "0"), ".")
	}
	return val " (" Format("{:L}", sz) ")"
}

;notify
_notify(msg, type := "info", seconds := ""){
	global script_title
	title := _trim(script_title " " Format("{:T}", type))
	opts := 16
	if (type == "info")
		opts += 1
	if (type == "warning")
		opts += 2
	if (type == "error")
		opts += 3
	TrayTip, % title, % msg, % seconds, % opts
}

;confirm
_confirm(msg){
	global script_title
	Gui, +OwnDialogs
	MsgBox, 36, % script_title, % msg
	IfMsgBox, Yes
		return true
}

;warn
_warn(msg){
	global script_title
	Gui, +OwnDialogs
	MsgBox, 48, % script_title, % msg
}

;toggle enable
_enable(ctrl, enabled := true){
	toggle := enabled ? "Enable" : "Disable"
	GuiControl, % toggle, % ctrl
}

;statusbar set text
_sb(left_text, right_text := "", ellipsis := 0, max_right := 60){
	left_text := _trim(left_text)
	right_text := _trim(right_text)
	if (StrLen(right_text) > max_right)
		right_text := SubStr(right_text, 1, max_right)
	if (right_text && ellipsis)
		right_text .= "..."
	text := left_text "`t`t" right_text
	SB_SetText(text, 1)
}

;trim
_trim(val, omit := ""){
	tmp := " `r`n`t"
	if !InStr(tmp, omit)
		tmp := omit tmp
	return Trim(val, tmp)
}

;exit handler
ExitHandler(ExitReason, ExitCode){
	global script_title
	global started
	if !started
		return
	if ExitReason not in Logoff,Shutdown
	{
		MsgBox, 52, %script_title%, Cancel current job?
		IfMsgBox, No
			return 1
	}
}

/*
HASH types:
1 - MD2
2 - MD5
3 - SHA
4 - SHA256 - not supported on XP,2000
5 - SHA384 - not supported on XP,2000
6 - SHA512 - not supported on XP,2000
*/
HashFile(filePath,hashType=2)
{
    PROV_RSA_AES := 24
    CRYPT_VERIFYCONTEXT := 0xF0000000
    BUFF_SIZE := 1024 * 1024 ; 1 MB
    HP_HASHVAL := 0x0002
    HP_HASHSIZE := 0x0004
     
    HASH_ALG := hashType = 1 ? (CALG_MD2 := 32769) : HASH_ALG
    HASH_ALG := hashType = 2 ? (CALG_MD5 := 32771) : HASH_ALG
    HASH_ALG := hashType = 3 ? (CALG_SHA := 32772) : HASH_ALG
    HASH_ALG := hashType = 4 ? (CALG_SHA_256 := 32780) : HASH_ALG   ;Vista+ only
    HASH_ALG := hashType = 5 ? (CALG_SHA_384 := 32781) : HASH_ALG   ;Vista+ only
    HASH_ALG := hashType = 6 ? (CALG_SHA_512 := 32782) : HASH_ALG   ;Vista+ only
     
    f := FileOpen(filePath,"r","CP0")
    if !IsObject(f)
        return 0
    if !hModule := DllCall( "GetModuleHandleW", "str", "Advapi32.dll", "Ptr" )
        hModule := DllCall( "LoadLibraryW", "str", "Advapi32.dll", "Ptr" )
    if !dllCall("Advapi32\CryptAcquireContextW"
                ,"Ptr*",hCryptProv
                ,"Uint",0
                ,"Uint",0
                ,"Uint",PROV_RSA_AES
                ,"UInt",CRYPT_VERIFYCONTEXT )
        Goto,FreeHandles
     
    if !dllCall("Advapi32\CryptCreateHash"
                ,"Ptr",hCryptProv
                ,"Uint",HASH_ALG
                ,"Uint",0
                ,"Uint",0
                ,"Ptr*",hHash )
        Goto,FreeHandles
     
    VarSetCapacity(read_buf,BUFF_SIZE,0)
     
    hCryptHashData := DllCall("GetProcAddress", "Ptr", hModule, "AStr", "CryptHashData", "Ptr")
    While (cbCount := f.RawRead(read_buf, BUFF_SIZE))
    {
        if (cbCount = 0)
            break
         
        if !dllCall(hCryptHashData
                    ,"Ptr",hHash
                    ,"Ptr",&read_buf
                    ,"Uint",cbCount
                    ,"Uint",0 )
            Goto,FreeHandles
    }
     
    if !dllCall("Advapi32\CryptGetHashParam"
                ,"Ptr",hHash
                ,"Uint",HP_HASHSIZE
                ,"Uint*",HashLen
                ,"Uint*",HashLenSize := 4
                ,"UInt",0 ) 
        Goto,FreeHandles
         
    VarSetCapacity(pbHash,HashLen,0)
    if !dllCall("Advapi32\CryptGetHashParam"
                ,"Ptr",hHash
                ,"Uint",HP_HASHVAL
                ,"Ptr",&pbHash
                ,"Uint*",HashLen
                ,"UInt",0)
        Goto,FreeHandles    
     
    SetFormat,integer,Hex
    loop,%HashLen%
    {
        num := numget(pbHash,A_index-1,"UChar")
        hashval .= substr((num >> 4),0) . substr((num & 0xf),0)
    }
    SetFormat,integer,D
	FreeHandles:
    f.Close()
    DllCall("FreeLibrary", "Ptr", hModule)
    dllCall("Advapi32\CryptDestroyHash","Ptr",hHash)
    dllCall("Advapi32\CryptReleaseContext","Ptr",hCryptProv,"UInt",0)
    return hashval
}