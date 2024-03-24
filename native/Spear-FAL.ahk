#Include ../internal/FileHit.ahk
#Include ../lib/vec.v2.ahk
#Include ../lib/option.v2.ahk
#Include ../lib/result.v2.ahk

/**
 * The FAL or 'FFI Abstraction Layer' or 'Foreign-Function-Interface Abstraction Layer'
 * 
 * It builds an abstraction in between spearlib's native interface and AutoHotkey.
 * 
 */
class SpearFAL {
    #Requires AutoHotkey 2.0.2+

    static KiB := 1024
    static MiB := 1024 * 1014
    static SIZEOF_DATA := 32

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
     * @note For reference, I indexed my whole user folder 'C:/Users/%username%/' which containes about 780'000 files. This filled up about 112 Megabytes (Value from Task Manager)
     * @param {Integer} data_buf_size Size of the metadata buffer in megabytes. One entry is 32 bytes in size. Default = 50
     * @param {Integer} str_buf_size Size of the string buffer in megabytes. This holds all the data of walked directories. Default = 500
     * @param {Integer} filtered_data_buf_size Size of the filtered metadata buffer in megabates. One entry is 32 bytes in size. Default = 15
     * @param {Integer} filtered_str_buf_size Size of the filtered string buffer in megabytes. This holds a copy of all the matching directories in the right order. Default = 150
     */
    __New(data_buf_size := 50, str_buf_size := 500, filtered_data_buf_size := 15, filtered_str_buf_size := 150) {
        if !FileExist("./spearlib.dll") {
            throw Error("Unable to load dll 'spearlib.dll'. If you want to use the native algorithms, make sure 'spearlib.dll' is the same directory as 'Spear-Native.ahk' and 'Spear-FAL.ahk'.")
        }

        this.lib := DllCall("LoadLibrary", "str", "./spearlib.dll")
        if this.lib == 0 {
            throw Error("Found 'spearlib.dll', but unable to load it.")
        }

        ; I'm not zeroing out the memory to prevent AHK from actually using all of the committed memory.
        ; It also saves some setup time by not having to write 0x00 bytes everywhere in the buffer.
        ; If you look into Task Manager, on the second page under RAM, you should see committed memory.
        ; The committed memory will jump a serious amount while the actual allocation is done later (as shown by the graph not jumping) thereby preserving actual usable and fast memory.
        ; If you're unsure about what all this means, you can read through this article to get more information.
        ; https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/introduction-to-the-page-file
        ; Especially this section: System committed memory:
        ; https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/introduction-to-the-page-file#system-committed-memory

        this.data_buf := Buffer(data_buf_size * SpearFAL.MiB)
        this.filtered_data_buf := Buffer(filtered_data_buf_size * SpearFAL.MiB)

        this.str_buf := Buffer(str_buf_size * SpearFAL.MiB)
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

    ; #[no_mangle]
    ; pub extern "C" fn walk_ff(*mut Data, usize, *mut u16, usize, *mut u16) -> usize
    ffi_walk(working_dir) {
        this.check_valid()

        this.found_files := DllCall("spearlib\walk_ffi",
            "ptr", this.data_buf.Ptr,
            "uint64", this.data_buf.Size,

            "ptr", this.str_buf.Ptr,
            "uint64", this.str_buf.Size,

            "wstr", working_dir,

            "cdecl uint64"
        )
    }

    ffi_filter() {
        this.matching_files := DllCall("spearlib\filter_ffi",

            "ptr", this.data_buf.Ptr,
            "uint64", this.found_files,

            "ptr", this.filtered_data_buf.Ptr,
            "ptr", this.filtered_str_buf.Ptr,

            "cdecl uint64"
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
            str_ptr := NumGet(this.filtered_data_buf, base + Data.path, "ptr")
            str_len := NumGet(this.filtered_data_buf, base + Data.len, "uint64")
            score := NumGet(this.filtered_data_buf, base + Data.score, "uint64")
            file_mode := NumGet(this.filtered_data_buf, base + Data.file_mode, "uint64")
            path := StrGet(str_ptr, str_len, "UTF-16")
            name := StrSplit(path, "/")[-1]

            hit := FileHit(name, path, file_mode)
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
            str_ptr := NumGet(this.data_buf, base + Data.path, "ptr")
            str_len := NumGet(this.data_buf, base + Data.len, "uint64")
            file_mode := NumGet(this.filtered_data_buf, base + Data.file_mode, "uint64")
            path := StrGet(str_ptr, str_len, "UTF-16")
            name := StrSplit(path, "/")[-1]

            v.push(FileHit(name, path, file_mode))
            i++
        }

        return v
    }

    ; #[no_mangle]
    ; pub extern "C" fn set_user_input(s: *mut u16)
    set_user_input(s) {
        DllCall("spearlib\set_user_input",
            "wstr", s,

            "cdecl"
        )
    }
    ; #[no_mangle]
    ; pub extern "C" fn set_ignore_case(isize)
    set_ignore_case(b) {
        DllCall("spearlib\set_ignore_case", "int64", b)
    }

    ; #[no_mangle]
    ; pub extern "C" fn set_suffix_filter(isize)
    set_suffix_filter(b) {
        DllCall("spearlib\set_suffix_filter", "int64", b)
    }

    ; #[no_mangle]
    ; pub extern "C" fn set_contains_filter(isize)
    set_contains_filter(b) {
        DllCall("spearlib\set_contains_filter", "int64", b)
    }

    ; #[no_mangle]
    ; pub extern "C" fn set_match_path(isize)
    set_match_path(b) {
        DllCall("spearlib\set_match_path", "int64", b)
    }

    ; #[no_mangle]
    ; pub extern "C" fn set_ignore_whitespace(isize)
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

/**
 * ```rust
 * #[Repr(C)]
 * pub struct Data {            // Size: 32 bytes
 *     pub path: *mut u32,      // Offset: 0
 *     pub len: usize,          // Offset: 8
 *     pub score: usize,        // Offset: 16
 *     pub file_mode: usize,    // Offset: 24, turns out: AHK doesn't like unaligned reads into char
 * }
 * ```
 */
class Data {
    static path := 0
    static len := 8
    static score := 16
    static file_mode := 24
}

/**
 * Don't need it in AHK, still good to have for debugging.
 * ```rust
 * pub enum FileMode {
 *     File,
 *     Dir,
 *     Link,
 *     Any,
 * }
 * 
 * impl FileMode {
 *     fn as_bytes(&self) -> u8 {
 *         return match self {
 *             Self::Dir => 0,
 *             Self::File => 1,
 *             Self::Link => 2,
 *             Self::Any => 4,
 *         }
 *     }
 * }
 * ```
 */