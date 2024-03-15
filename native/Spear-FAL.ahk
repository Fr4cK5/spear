#Include ../FileHit.ahk
#Include ../vec.v2.ahk
#Include ../option.v2.ahk
#Include ../result.v2.ahk
#Include ../logger.v2.ahk

fal_lg := Logger("FAL-Logger", false)

/**
 * The FAL or 'FFI Abstraction Layer' or 'Foreign-Function-Interface Abstraction Layer'
 * 
 * It builds an abstraction in between the 'spearlib's native interface' and AutoHotkey.
 * 
 * ```rust
 * pub struct Data {            // Size: 24 bytes
 *     pub path: *const String, // Offset: 0
 *     pub len: usize,          // Offset: 8
 *     pub score: usize,        // Offset: 16
 * }
 * ```
 */
class SpearFAL {
    #Requires AutoHotkey 2.0+

    static KiB := 1024
    static MiB := 1024 * 2014
    static SIZEOF_DATA := 24

    lib := 0

    data_buf := 0
    str_buf := 0
    filtered_data_buf := 0
    filtered_str_buf := 0

    found_files := 0
    matching_files := 0

    /**
     * Constructor
     * @note Yes, you can freely change these values if you'd like. The AHK program using it will consume this much memory at most.
     * @param {Integer} data_buf_size Size of the metadata buffer in megabytes. One entry is 24 bytes in size. Default = 30
     * @param {Integer} str_buf_size Size of the string buffer in megabytes. This holds all the data of walked directories. Default = 500
     * @param {Integer} filtered_data_buf_size Size of the filtered metadata buffer in megabates. One entry is 24 bytes in size. Default = 15
     * @param {Integer} filtered_str_buf_size Size of the filtered string buffer in megabytes. This holds a copy of all the matching directories in the right order. Default = 150
     */
    __New(data_buf_size := 30, str_buf_size := 500, filtered_data_buf_size := 15, filtered_str_buf_size := 150) {
        if !FileExist("./spearlib.dll") {
            throw Error("Unable to dll 'spearlib.dll'. If you want to use the native algorithms, make sure 'spearlib.dll' is the same directory as all the other files.")
        }

        this.lib := DllCall("LoadLibrary", "str", "./spearlib.dll")
        if this.lib == 0 {
            throw Error("Found 'spearlib.dll', but unable to load it.")
        }

        ; I'm NOT zeroing out the memory to prevent AHK from actually using all of the committed memory.
        ; It also saves some setup time not having to write 0x00 bytes everywhere in the buffer.
        ; If you look into Task Manager, on the second page under RAM, you should see committed memory.
        ; The committed amount will jump a serious amount while the actual allocation is done later thereby preserving actual usable and fast memory.
        ; If you're unsure about what all this means, you can read through this article to get more information.
        ; https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/introduction-to-the-page-file
        ; Especially this section: System committed memory:
        ; https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/introduction-to-the-page-file#system-committed-memory

        this.data_buf := Buffer(data_buf_size * SpearFAL.Mib)
        this.filtered_data_buf := Buffer(filtered_data_buf_size * SpearFAL.Mib)

        this.str_buf := Buffer(str_buf_size * SpearFAL.Mib)
        this.filtered_str_buf := Buffer(filtered_str_buf_size * SpearFAL.MiB)

        this.found_files := 0
        this.matching_files := 0
    }

    __Delete() {
        DllCall("FreeLibrary", "ptr", this.lib)
    }

    setup_settings(settings) {
        this.set_ignore_case(settings.matchignorecase)
        this.set_suffix_filter(settings.dollarsuffixisendswith)
        this.set_contains_filter(settings.qmsuffixiscontains)
        this.set_match_path(settings.matchpath)
        this.set_ignore_whitespace(settings.ignorewhitespace)
    }

    check_valid() {
        if this.lib == 0 {
            throw Error("Handle to native library is null")
        }
    }

    buffer_has_items() {
        return this.found_files != 0
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
            base := i * SpearFAL.SIZEOF_DATA
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
            base := i * SpearFAL.SIZEOF_DATA
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

    reserved_memory() {
        return (
            this.data_buf.Size + this.str_buf.Size +
            this.filtered_str_buf.Size + this.filtered_str_buf.Size
        )
    }

    free_mem() {
        this.data_buf := Buffer(this.data_buf.Size)
        this.filtered_data_buf := Buffer(this.filtered_data_buf.Size)

        this.str_buf := Buffer(this.str_buf.Size)
        this.filtered_str_buf := Buffer(this.filtered_str_buf.Size)

        this.found_files := 0
        this.matching_files := 0
    }
}