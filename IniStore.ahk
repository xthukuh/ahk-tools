;ini store
class IniStore
{
	;statics
	static DIR := A_Temp
	static SECTION := "main"

	;new instance
	__New(ini := "", section := "")
	{
		this._ini := this.getPath(ini)
		this._section := this.getSection(section)
	}

	;get name
	getName(name := "")
	{
		;param value
		if (name := Trim(name, " `r`n`t"))
		{
			name := Trim(RegExReplace(Trim(Format("{:L}", RegExReplace(name, "([A-Z])", "-$1")), " `r`n`t"), "i)[^a-z0-9]", "-"), "-")
			if RegExMatch(name, "[^-]")
				return name
		}

		;default value
		SplitPath, A_ScriptFullPath,,,, name
		name := Trim(RegExReplace(Trim(Format("{:L}", RegExReplace(name, "([A-Z])", "-$1")), " `r`n`t"), "i)[^a-z0-9]", "-"), "-")
		if RegExMatch(name, "[^-]")
			return name "-ahk"
		return "store-ahk"
	}

	;get path
	getPath(ini := "")
	{
		;param value
		if (ini := Trim(ini, " `r`n`t"))
		{
			SplitPath, ini, fname, dir, ext, name
			if (fdir && name)
				return fdir "\" name ".ini"
		}

		;instance value
		if (ini := Trim(this._ini, " `r`n`t"))
		{
			SplitPath, ini, fname, dir, ext, name
			if (fdir && name)
				return fdir "\" name ".ini"
		}

		;default value
		name := this.getName()
		dir := this.base.DIR
		if !InStr(FileExist(dir), "D")
			dir := A_Temp
		return dir "\" name ".ini"
	}

	;get section
	getSection(section := "")
	{
		;param value
		if ((val := Trim(section, " `r`n`t")) && RegExMatch(val, "i)^[-_a-z0-9]+$"))
			return val
		
		;instance value
		if ((val := Trim(this._section, " `r`n`t")) && RegExMatch(val, "i)^[-_a-z0-9]+$"))
			return val

		;default value
		if ((val := Trim(this.base.SECTION, " `r`n`t")) && RegExMatch(val, "i)^[-_a-z0-9]+$"))
			return val
		return "main"
	}

	;key
	key(key, throwable := true)
	{
		if ((val := Trim(key, " `r`n`t")) && RegExMatch(val, "i)^[-_a-z0-9]+$"))
			return val
		if throwable
			throw Exception("Invalid key!", "IniStore -> key: " key, "IniStore key value is invalid.")
	}

	;value
	value(val, parse := false)
	{
		if (val := Trim(val, " `r`n`t"))
		{
			if parse
			{
				StringReplace, val, val, ``r, `r, All
				StringReplace, val, val, ``n, `n, All
				StringReplace, val, val, ``t, `t, All
			}
			else {
				StringReplace, val, val, `r, ``r, All
				StringReplace, val, val, `n, ``n, All
				StringReplace, val, val, `t, ``t, All
			}
		}
		return val
	}

	;read
	get(key, default := "", section := "", ini := "", ByRef failure := 0)
	{
		failure := 0
		key := this.key(key)
		ini := this.getPath(ini)
		section := this.getSection(section)
		IniRead, val, % ini, % section, % key
		if (ErrorLevel || Format("{:L}", val) == "error")
		{
			failure := 1
			val := default != "" ? this.set(key, default) : default
		}
		return this.value(val, 1)
	}

	;write
	set(key, value, section := "", ini := "", ByRef failure := 0, throwable := true)
	{
		failure := 0
		key := this.key(key)
		val := this.value(value)
		ini := this.getPath(ini)
		section := this.getSection(section)
		IniWrite, % val, % ini, % section, % key
		if ErrorLevel
		{
			failure := 1
			if throwable
				throw Exception("IniWrite failure!", "IniStore -> set: key=" key ", val=" val ", ini=" ini ", section=" section, "IniStore set key value failed.")
		}
		else return value
	}
}