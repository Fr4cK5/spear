#Requires AutoHotkey 2.0.2+
#SingleInstance Force

#Include logger.v2.ahk
#Include timer.v2.ahk
#Include vec.v2.ahk

lg := Logger(, true)

handle := DllCall("LoadLibrary", "str", "./spearlib.dll", "ptr")

data_buf := Buffer(100000000)
str_buf := Buffer(500000000)

t := Timer()
t.start()
file_count := DllCall("spearlib\explore_ffi",
    "ptr", data_buf,
    "int64", data_buf.Size,

    "ptr", str_buf.Ptr,
    "int64", str_buf.Size,

    "cdecl int64"
)

lg.dbg(t.ms())

KeyWait("Shift", "D")

matches := DllCall("spearlib\filter_ffi",

    "ptr", data_buf,
    "int64", file_count,

    "cdecl int64"
)



Esc::ExitApp()
DllCall("FreeLibrary", "ptr", handle)