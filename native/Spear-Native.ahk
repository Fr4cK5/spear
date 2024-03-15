#Requires AutoHotkey 2.0.2+
#SingleInstance Force

CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

#Include ../v2d.v2.ahk
#Include ../viewport.v2.ahk
#include ../str.v2.ahk
#Include ../vec.v2.ahk
#Include ../result.v2.ahk
#Include ../option.v2.ahk
#Include ../timer.v2.ahk
#Include ../files.v2.ahk
#Include ../jsongo.v2.ahk

#Include ../FileHit.ahk
#Include Spear-FAL.ahk

TraySetIcon("../asset/spear-icon.ico")

; WE DEBUGGING

; #Include peep.v2.ahk
; #Include ../logger.v2.ahk
; lg := Logger(, true)
; Esc::ExitApp()

; WE AINT DEBUGGING NO MORE

WIDTH := 800
HEIGHT := 600
PADDING := 20
FONT_SIZE := 15

; FIXME: Change to +AlwaysOnTop after debugging
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

    if lib.found_files <= settings.maxitemsforautoupdate {
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
LIST_HEIGHT := HEIGHT - PADDING * 2 - INPUT_BOX_HEIGHT - 40
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
PERF_Y := HEIGHT - PADDING * 2 + 7
PERF_WIDTH := WIDTH - PADDING * 2
perf := window.AddText(Format("x{} y{} w{}",
    PERF_X,
    PERF_Y,
    PERF_WIDTH
), "")

settings := load_settings()

base_dir := ""
set_base_dir(settings.basedir)

lib := SpearFAL()
lib.setup_settings(settings)

SetTimer(() => fill_cache(), -1, 0x7fffffff)

^#l::{
    SendEvent("{Ctrl Up}{Win Up}{l Up}")
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

Esc::hide_ui()

hide_ui() {
    global
    window.Hide()

    ; setting? Clear everything upon hiding
    if settings.autoclear {
        while list.Delete() {
        }
        input.Value := ""
        perf.Value := ""
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
        listviewlimit: settings["listviewlimit"],
        showfulldir: settings["showfulldir"],
        autoclear: settings["autoclear"],
        dollarsuffixisendswith: settings["dollarsuffixisendswith"],
        qmsuffixiscontains: settings["qmsuffixiscontains"],
        ignorewhitespace: settings["ignorewhitespace"],
        hideafteruiinteraction: settings["hideafteruiinteraction"],
        matchignorecase: settings["matchignorecase"],
        basedir: Str.replaceOne(settings["basedir"], "{}", A_UserName),
        matchpath: settings["matchpath"],
        maxitemsforautoupdate: settings["maxitemsforautoupdate"],
        integrations: {
            explorer: settings["integrations"]["explorer"], 
            editcmd: settings["integrations"]["editcmd"],
        },
    }
}

set_base_dir(path) {
    global
    temp := Str.replaceAll(path, "\", "/")

    if Str.endsWith(temp, "*") {
        temp := Str.sub(temp).unwrap()
    }

    if Str.endsWith(temp, "/") {
        temp := Str.sub(temp).unwrap()
    }

    base_dir := temp
    cache_ready := false

    while list.Delete() {
    }
    input.Value := ""
    perf.Value := ""
}

fill_cache() {
    global

    lib.ffi_walk(base_dir)
    stats.Value := Format("Cached {} Files", lib.found_files)
}

find(s) {
    global

    lib.set_user_input(s)

    t := Timer()
    t.start()

    while list.Delete() {
    }

    if Trim(s) == "" {
        return
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
    s := "Unknown"
    if Files.file(mode) {
        s := "File"
    }
    else if Files.directory(mode) {
        s := "Dir"
    }

    if Files.link(mode) {
        s .= "/Link"
    }

    return s
}