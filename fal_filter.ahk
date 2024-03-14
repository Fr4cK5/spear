#Requires AutoHotkey 2.0.2+
#SingleInstance Force

#Include logger.v2.ahk
#Include timer.v2.ahk
#Include vec.v2.ahk

lg := Logger(, true)

MEGABYTE := 1000000

handle := DllCall("LoadLibrary", "str", "./spearlib.dll", "ptr")

data_buf := Buffer(100 * MEGABYTE)
str_buf := Buffer(500 * MEGABYTE)

t := Timer()
t.start()

wd := "C:/.dev/spear"
wd_buffer := as_buf_ansi(wd)

file_count := DllCall("spearlib\walk_ffi",
    "ptr", data_buf.Ptr,
    "int64", data_buf.Size,

    "ptr", str_buf.Ptr,
    "int64", str_buf.Size,

    "ptr", wd_buffer,
    "int64", StrLen(wd),

    "cdecl int64"
)

lg.dbg(t.ms())

KeyWait("Shift", "D")

filter_data := Buffer(100 * MEGABYTE)
filter_strs := Buffer(500 * MEGABYTE)

user_input := ".rs"

DllCall("spearlib\set_user_input",
    "ptr", as_buf_ansi(user_input).Ptr,
    "int64", StrLen(user_input)
)

matches := DllCall("spearlib\filter_ffi",

    "ptr", data_buf.Ptr,
    "int64", file_count,

    "ptr", filter_data.Ptr,
    "ptr", filter_strs.Ptr,

    "cdecl int64"
)

lg.dbg("Matches: " matches)

i := 0
filez := Vec(matches)
while i < matches {
    base := i * 24
    str_ptr := NumGet(filter_data, base, "ptr")
    str_len := NumGet(filter_data, base + 8, "int64")
    score := NumGet(filter_data, base + 16, "int64")
    str := StrGet(str_ptr, str_len, "cp0")
    lg.dbg(str, score)
    i++
}

Esc::ExitApp()
DllCall("FreeLibrary", "ptr", handle)

as_buf_ansi(s) {
    b := Buffer(StrLen(s))
    written := StrPut(s, b.Ptr, StrLen(s), "cp0")
    lg.dbg("Written " written " bytes")
    return b
}

/*
Rust struct typedef
pub struct Data {               ; Size: 24 bytes
    pub path: *const String,    ; Offset: 0
    pub len: usize,             ; Offset: 8
    pub score: usize,           ; Offset: 16
}
*/