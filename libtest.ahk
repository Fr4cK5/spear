#Requires AutoHotkey 2.0.2+
#SingleInstance Force

#Include logger.v2.ahk
#Include timer.v2.ahk
#Include vec.v2.ahk

lg := Logger(, true)

lg.dbg("Ptr size: " A_PtrSize)

handle := DllCall("LoadLibrary", "str", "../spearlib.dll", "ptr")

data_buf := Buffer(10000000)
str_buf := Buffer(500000000)

t := Timer()
t.start()
file_count := DllCall("spearlib\explore_ffi",
    "ptr", data_buf,
    "int64", data_buf.Size,

    "ptr", str_buf.Ptr,
    "int64", str_buf.Size,

    "cdecl int64")

lg.dbg(t.ms())

DllCall("FreeLibrary", "ptr", handle)

; lg.dbg("strs: " str_buf.Ptr " " str_buf.Size)
; lg.dbg("data: " data_buf.Ptr " " data_buf.Size)

t.start()
filevec := Vec(file_count)
i := 0
while i < file_count {

    base := i * 16
    ptr := NumGet(data_buf.Ptr + base, "ptr")
    len := NumGet(data_buf.Ptr + base + 8, "int64")
    s := StrGet(ptr, len, "cp0")
    filevec.push(s)

    ; lg.dbg("Pointer: " Format("{:016X}", ptr) " Length: " len " Strlen: " StrLen(s), s)

    i++
}

lg.dbg(t.ms())

s := "balls in your jaws"

Esc::ExitApp()