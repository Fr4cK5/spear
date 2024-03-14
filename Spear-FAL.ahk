#Include FileHit.ahk
#Include vec.v2.ahk
#Include option.v2.ahk
#Include result.v2.ahk
#Include logger.v2.ahk

fal_lg := Logger("FAL-Logger", false)

/*
Rust struct typedef
pub struct Data {               ; Size: 24 bytes
    pub path: *const String,    ; Offset: 0
    pub len: usize,             ; Offset: 8
    pub score: usize,           ; Offset: 16
}
*/
class FAL {
    #Requires AutoHotkey 2.0+

    static MEGABYTE := 1000000

    lib := 0
    data_buf := 0
    str_buf := 0
    filtered_data_buf := 0
    filtered_str_buf := 0

    found_files := 0
    matching_files := 0

    __New() {
        if !FileExist("./spearlib.dll") {
            throw Error("Unable to dll 'spearlib.dll'. If you want to use the native algorithms, make sure 'spearlib.dll' is the same directory as all the other files.")
        }

        this.lib := DllCall("LoadLibrary", "str", "./spearlib.dll")
        if this.lib == 0 {
            throw Error("Found 'spearlib.dll', but unable to load it.")
        }

        ; Data buffers; These hold the "Data" struct definied above.
        ; 30 Megabytes should be able to fit ~1.2 mil files
        this.data_buf := Buffer(30 * FAL.MEGABYTE, 0)
        this.filtered_data_buf := Buffer(30 * FAL.MEGABYTE, 0)

        ; These hold the actual strings, they need WAY more memory.
        ; A 3-char string is equal to one whole "Data" entry.
        this.str_buf := Buffer(500 * FAL.MEGABYTE, 0)
        this.filtered_str_buf := Buffer(500 * FAL.MEGABYTE, 0)

        this.found_files := 0
        this.matching_files := 0
    }

    __Delete() {
        DllCall("FreeLibrary", "ptr", this.lib)
    }

    check_valid() {
        if this.lib == 0 {
            throw Error("Handle to native library is null")
        }
    }

    as_buf_ansi(s) {
        b := Buffer(StrLen(s))
        written := StrPut(s, b.Ptr, StrLen(s), "cp0")
        return b
    }

    ffi_walk(working_dir) {
        this.check_valid()

        this.found_files := DllCall("spearlib\walk_ffi",
            "ptr", this.data_buf.Ptr,
            "int64", this.data_buf.Size,

            "ptr", this.str_buf.Ptr,
            "int64", this.str_buf.Size,

            "ptr", this.as_buf_ansi(working_dir).Ptr,
            "int64", StrLen(working_dir),

            "cdecl int64"
        )
    }

    ffi_filter() {
        this.matching_files := DllCall("spearlib\filter_ffi",

            "ptr", this.data_buf.Ptr,
            "int64", this.found_files,

            "ptr", this.filtered_data_buf.Ptr,
            "ptr", this.filtered_str_buf.Ptr,

            "cdecl int64"
        )
    }

    filtered_buffer_to_vec() {
        v := Vec(this.matching_files)
        if this.matching_files == 0 {
            return v
        }

        i := 0
        while i < this.matching_files {
            base := i * 24
            str_ptr := NumGet(this.filtered_data_buf, base, "ptr")
            str_len := NumGet(this.filtered_data_buf, base + 8, "int64")
            score := NumGet(this.filtered_data_buf, base + 16, "int64")
            str := StrGet(str_ptr, str_len, "cp0")
            name := StrSplit(str, "/")[-1]
            hit := FileHit(name, str, "N")
            hit.score := score
            v.push(hit)
            i++
        }

        return v
    }

    raw_buffer_to_vec() {
        v := Vec(this.found_files)
        if this.found_files == 0 {
            return v
        }

        i := 0
        while i < this.found_files {
            base := i * 24
            str_ptr := NumGet(this.data_buf, base, "ptr")
            str_len := NumGet(this.data_buf, base + 8, "int64")
            str := StrGet(str_ptr, str_len, "cp0")
            name := StrSplit(str, "/")[-1]
            v.push(FileHit(name, str, "N"))
            i++
        }

        return v
    }

    set_user_input(s) {
        DllCall("spearlib\set_user_input",
            "ptr", this.as_buf_ansi(s).Ptr,
            "int64", StrLen(s),

            "cdecl"
        )
    }
    set_ignore_case(b) {
        DllCall("spearlib\set_ignore_case", "int64", b)
    }
    set_suffix_filter(b) {
        DllCall("spearlib\set_suffix_filter", "int64", b)
    }
    set_contains_filter(b) {
        DllCall("spearlib\set_contains_filter", "int64", b)
    }
    set_match_path(b) {
        DllCall("spearlib\set_match_path", "int64", b)
    }
    set_ignore_whitespace(b) {
        DllCall("spearlib\set_ignore_whitespace", "int64", b)
    }

}