#Requires AutoHotkey 2.0.2+
#SingleInstance Force

CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

#Include ../lib/v2d.v2.ahk
#Include ../lib/viewport.v2.ahk
#include ../lib/str.v2.ahk
#Include ../lib/vec.v2.ahk
#Include ../lib/result.v2.ahk
#Include ../lib/option.v2.ahk
#Include ../lib/timer.v2.ahk
#Include ../lib/files.v2.ahk
#Include ../lib/jsongo.v2.ahk

#Include ../internal/FileHit.ahk
#Include Spear-FAL.ahk

TraySetIcon("../asset/spear-icon.ico")

WIDTH := 800
HEIGHT := 640
PADDING := 20
FONT_SIZE := 15

; FIXME: You know what to do!
window := Gui("+ToolWindow -Caption -AlwaysOnTop")
window.SetFont(Format("s{}", FONT_SIZE))

INPUT_BOX_POS := PADDING
INPUT_BOX_WIDTH := WIDTH - PADDING * 2 - 200
INPUT_BOX_HEIGHT := 30
input := window.AddEdit(Format("x{} y{} w{} h{}",
    INPUT_BOX_POS,
    INPUT_BOX_POS,
    INPUT_BOX_WIDTH,
    INPUT_BOX_HEIGHT
))
input.OnEvent("Change", auto_update_list)
auto_update_list(obj, info) {
    while !cache_ready {
    }

    if lib.found_files <= settings.native.maxitemsforautoupdate {
        find(obj.Value)
    }
}

STATS_X := PADDING * 2 + INPUT_BOX_WIDTH
STATS_Y := PADDING + 3
STATS_WIDTH := WIDTH - STATS_X - PADDING
STATS_HEIGHT := INPUT_BOX_HEIGHT
stats := window.AddText(Format("x{} y{} w{} h{}",
    STATS_X,
    STATS_Y,
    STATS_WIDTH,
    STATS_HEIGHT
), Format(""))

LIST_X := PADDING
LIST_Y := PADDING * 2 + INPUT_BOX_HEIGHT
LIST_WIDTH := WIDTH - PADDING * 2
LIST_HEIGHT := HEIGHT - PADDING * 2 - INPUT_BOX_HEIGHT - 80
list := window.AddListView(Format("+Grid x{} y{} w{} h{}",
    LIST_X,
    LIST_Y,
    LIST_WIDTH,
    LIST_HEIGHT
), ["Name", "Directory", "Type", "Score"])
list.OnEvent("Click", handle_list_click)

list.ModifyCol(1, LIST_WIDTH / 3)
list.ModifyCol(2, LIST_WIDTH / 2 - 5)
list.ModifyCol(3, LIST_WIDTH / 6)

PERF_X := PADDING
PERF_Y := HEIGHT - PADDING * 2 + 7 - 40
PERF_WIDTH := WIDTH - PADDING * 2
perf := window.AddText(Format("x{} y{} w{}",
    PERF_X,
    PERF_Y,
    PERF_WIDTH
), "")

BUTTON_HEIGHT := 30
BUTTON_WIDTH := 150

FREE_X := PERF_X
FREE_Y := PERF_Y + 30
free_button := window.AddButton(Format("x{} y{} w{} h{}",
    FREE_X,
    FREE_Y,
    BUTTON_WIDTH,
    BUTTON_HEIGHT
), "Free memory")
free_button.OnEvent("click", free_button_callback)
free_button_callback(*) {
    lib.free_mem()
    clear_ui()
}

SELECT_X := FREE_X + BUTTON_WIDTH + PADDING
SELECT_Y := FREE_Y
SELECT_WIDTH := BUTTON_WIDTH
select_dir := window.AddButton(Format("x{} y{} w{} h{}",
    SELECT_X,
    SELECT_Y,
    SELECT_WIDTH,
    BUTTON_HEIGHT
), "Select Dir")
select_dir.OnEvent("click", select_dir_callback)
select_dir_callback(*) {
    set_base_dir(DirSelect())
    SetTimer(() => fill_cache(), -1, 0x7fffffff)
}

NEW_PATH_X := SELECT_X + PADDING + BUTTON_WIDTH
NEW_PATH_Y := FREE_Y
NEW_PATH_WIDTH := 413
new_path_label := window.AddEdit(Format("x{} y{} w{} +Disabled",
    NEW_PATH_X + 7,
    NEW_PATH_Y,
    NEW_PATH_WIDTH
), "")

settings := load_settings()

base_dir := ""
set_base_dir(settings.basedir)

lib := SpearFAL()
lib.setup_settings(settings)

auto_free_timer := Timer()
is_auto_freed := false

SetTimer(() => fill_cache(), -1, 0x7fffffff)

^#l::{
    global

    SendEvent("{Ctrl Up}{Win Up}{l Up}")

    if is_auto_freed {
        is_auto_freed := false
        auto_free_timer.start()
        SetTimer(() => fill_cache(), -1, 0x7fffffff)
    }

    explorer_integration()
    show_centered(window, WIDTH, HEIGHT)
    input.Focus()
}
~*Enter:: {
    if !WinActive(window) {
        return
    }
    if !input.Focused {
        return
    }

    find(input.Value)
}

~Esc::hide_ui()

hide_ui() {
    global
    window.Hide()

    ; setting? Clear everything upon hiding
    if settings.autoclear {
        clear_ui()
    }
}

clear_ui(lib_initialized := true, preserve_stats := false) {
    global
    while list.Delete() {
    }
    input.Value := ""
    perf.Value := ""
    if !preserve_stats and lib_initialized and lib.found_files == 0 {
        stats.Value := "No files indexed"
    }
    else {
        stats.Value := ""
    }
}

show_centered(g, width, height) {
    vp := Viewport()
    pos := Vector2(
        vp.halfX() - width / 2,
        vp.halfY() - height / 2,
    )
    g.Show(Format("x{} y{} w{} h{}", pos.x, pos.y, width, height))
}

check_free_timer() {
    global
    if auto_free_timer.getSecs() >= settings.native.autofreetimeout and !is_auto_freed {
        is_auto_freed := true
        lib.free_mem()
        clear_ui()
        auto_free_timer.start()
    }
}

explorer_integration() {
    ; setting? Explorer integration
    if !settings.integrations.explorer {
        return
    }

    handle := WinActive("ahk_exe explorer.exe ahk_class CabinetWClass")
    if !handle {
        return
    }

    bak := A_Clipboard
    Sleep(50)
    SendEvent("^l^c")
    Sleep(50)

    ; If the user was in This PC > Documents, Downloads, Pictures, etc...
    ; explorer won't give us our desired path meaning this feature won't work...
    if !RegExMatch(A_Clipboard, "i)^\w:[\\/]") {
        return
    }

    set_base_dir(A_Clipboard)
    SetTimer(() => fill_cache(), -1, 0x7fffffff)
    Sleep(50)
    A_Clipboard := bak
}

load_settings() {
    user_path_parts := Vec.FromShared(StrSplit(A_MyDocuments, "\"))
    user_path := user_path_parts
        .limit(user_path_parts.len() - 1)
        .join("\")
        .unwrap()

    settings := {}
    try {
        settings_content := FileRead(Format("{}\.config\spear\config.json", user_path))
        settings := jsongo.Parse(settings_content)
    }
    catch {
        settings_content := FileRead(Format("{}\.config\spear\config_default.json", user_path))
        settings := jsongo.Parse(settings_content)
    }

    ; For the sake of autocomplete!
    return {
        listviewlimit: settings["listviewlimit"], ; How many items the list view can display at a time (reason: performance)
        showfulldir: settings["showfulldir"], ; Show the full directory of the item or just the last part of it
        autoclear: settings["autoclear"], ; Automatically clear the UI upon hiding it
        dollarsuffixisendswith: settings["dollarsuffixisendswith"], ; Suffixing your input with '$' makes the search algorithm look for suffixes instead
        qmsuffixiscontains: settings["qmsuffixiscontains"], ; Suffixing your input with '?' makes the search algorithm look for containment instead
        ignorewhitespace: settings["ignorewhitespace"], ; Ignore the white space in your input. 'Test File.txt' would equal 'TestFile.txt'; Only has an effect when not using a suffixes
        hideafteruiinteraction: settings["hideafteruiinteraction"], ; Hide the UI after interacting with it: Copying the Path / filename or opening the file
        matchignorecase: settings["matchignorecase"], ; Ignore whether the input is uppercase or lowercase
        basedir: Str.replaceOne(settings["basedir"], "{}", A_UserName), ; Starting directory
        matchpath: settings["matchpath"], ; Incoperate the path to the file to actual matching
        maxitemsforautoupdate: settings["maxitemsforautoupdate"], ; Maximum amount of items to automatically filter and update the list while typing making it feel "realtime" (reason: performance)
        integrations: {
            explorer: settings["integrations"]["explorer"], ; Enable the explorer integration
            editcmd: settings["integrations"]["editcmd"], ; The command to be executed when Opening a file from the UI's list via Ctrl+Left Click
        },
        native: {
            maxitemsforautoupdate: settings["native"]["maxitemsforautoupdate"], ; Same as above; This value overrides the one above if you're using Spear-Native
            autofreebuffer: settings["native"]["autofreebuffer"], ; Automatically free the buffer and release the memory
            autofreetimeout: settings["native"]["autofreetimeout"], ; The time (seconds) Spear-Native must be in idle (you don't interact with it at all) to automatically free the buffers
        }
    }
}

set_base_dir(path) {
    global

    if Trim(path) == "" {
        return
    }

    temp := Str.replaceAll(path, "\", "/")

    if Str.endsWith(temp, "*") {
        temp := Str.sub(temp).unwrap()
    }

    if Str.endsWith(temp, "/") {
        temp := Str.sub(temp).unwrap()
    }

    base_dir := temp
    cache_ready := false

    clear_ui(false)
    new_path_label.Value := base_dir

    ; Scroll the end of the edit if the path happens to be longer than the control
    ControlSend("{End}", new_path_label)
}

fill_cache() {
    global

    if settings.native.autofreebuffer {
        auto_free_timer.start()
        SetTimer(check_free_timer, 1)
    }

    cache_ready := false
    lib.free_mem()
    lib.ffi_walk(base_dir)
    cache_ready := true
    stats.Value := Format("{} Files", lib.found_files)
}

find(s) {
    global

    auto_free_timer.start()

    if Trim(s) == "" or lib.found_files == 0 {
        while list.Delete() {
        }
        perf.Value := ""
        return
    }

    lib.set_user_input(s)

    t := Timer()
    t.start()

    while list.Delete() {
    }

    lib.ffi_filter()
    filtering := t.ms()

    limited := lib.filtered_buffer_to_vec()
        .limit(settings.listviewlimit) ; setting? Limit
        .foreach((_, item) => list.Add(, item.filename, item.path, get_pretty_mode(item.attr), item.score))

    hits := lib.matching_files
    showing := limited.len()

    perf.Value := Format("Hits: {}/{}; Filtering: {}ms",
        hits,
        lib.found_files,
        filtering
    )
}

handle_list_click(obj, info) {
    name := list.GetText(info, 1)
    path := list.GetText(info, 2)
    mode := list.GetText(info, 3)

    path_parts := Vec.FromClone(StrSplit(path, "/"))
    if GetKeyState("Control", "P") {
        working_dir := path_parts
            .limit(path_parts.len() - (Str.hasPrefix(mode, "File") ? 1 : 0))
            .join("\")
        
        if working_dir.isNone() {
            return
        }

        Run(Format("explorer {}", working_dir.unwrap()))
    }
    else if GetKeyState("LAlt", "P") {
        Run(Format(settings.integrations.editcmd, path))
    }

    if GetKeyState("LAlt", "P") {
        A_Clipboard := name
    }
    else {
        A_Clipboard := path
    }

    ; setting? Autohide after copy / explorer start
    if settings.hideafteruiinteraction {
        hide_ui()
    }
}

get_pretty_mode(mode) {
    switch mode {
    case 0:
        return "Dir"
    case 1:
        return "File"
    case 2:
        return "Link"
    default:
        return "Unknown"
    }
}