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

TraySetIcon("../asset/spear-icon.ico")

WIDTH := 800
HEIGHT := 600
PADDING := 20
FONT_SIZE := 15

window := Gui("+ToolWindow -Caption +AlwaysOnTop")
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

    if cache.len() <= settings.maxitemsforautoupdate {
        _find(obj.Value)
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
list.OnEvent("Click", _handle_list_click)

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

settings := _load_settings()

base_dir := ""
_set_base_dir(settings.basedir)

cache := Vec()
cache_ready := false
SetTimer(() => _fill_cache(), -1, 0x7fffffff)

^#l::{
    SendEvent("{Ctrl Up}{Win Up}{l Up}")
    _explorer_integration()
    _show_centered(window, WIDTH, HEIGHT)
    input.Focus()
}
~*Enter:: {
    if !WinActive(window) {
        return
    }
    if !input.Focused {
        return
    }

    _find(input.Value)
}

Esc::_hide_ui()

_hide_ui() {
    global
    window.Hide()

    ; setting? Clear everything upon hiding
    if settings.autoclear {
        while (list.Delete()) {
        }
        input.Value := ""
        perf.Value := ""
    }
}

_show_centered(g, width, height) {
    vp := Viewport()
    pos := Vector2(
        vp.halfX() - width / 2,
        vp.halfY() - height / 2,
    )
    g.Show(Format("x{} y{} w{} h{}", pos.x, pos.y, width, height))
}

_explorer_integration() {
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

    _set_base_dir(A_Clipboard)
    SetTimer(() => _fill_cache(), -1, 0x7fffffff)
    Sleep(50)
    A_Clipboard := bak
}

_load_settings() {
    settings := {}
    try {
        settings_content := FileRead("../config/config.json")
        settings := jsongo.Parse(settings_content)
    }
    catch {
        settings_content := FileRead("../config/spear/config_default.json")
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

_set_base_dir(path) {
    global
    temp := Str.replaceAll(path, "/", "\")
    if !Str.hasSuffix(temp, "\") {
        temp .= "\"
    }

    if !Str.hasSuffix(temp, "*") {
        temp .= "*"
    }

    base_dir := temp
    cache_ready := false

    while (list.Delete()) {
    }
    input.Value := ""
    perf.Value := ""
}

_fill_cache() {
    global

    cache_ready := false
    cache.clear()

    loop files base_dir, "DFR" {

        filename := A_LoopFileName
        path := A_LoopFileFullPath
        if filename == path {
            path := "./"
        }
        ; setting? Either show the last directory of the path
        if !settings.showfulldir {
            path := Str.sub(path, Str.lastIndex(path, "\").unwrap() + 1).unwrap()
        }
        ; setting... Or Show the full thing
        else {
            path := StrReplace(path, "\", "/")
        }

        cache.push(FileHit(filename, path, A_LoopFileAttrib))
    }

    stats.Value := Format("Cached {} Files", cache.len())

    cache_ready := true
}

_find(s) {
    global

    t := Timer()
    t.start()

    while(list.Delete()) {
    }

    if Trim(s) == "" {
        return
    }

    if cache.len() == 0 and cache_ready {
        SetTimer(() => _fill_cache(), -1, 0x7fffffff)
    }

    while(!cache_ready) {
    }

    if cache.len() == 0 {
        perf.Value := ""
        return
    }

    hit_list := cache
        .filter((_, item) => _is_match(item))
        .sort((a, b) => a.score < b.score)
    
    limited := hit_list
        .limit(settings.listviewlimit) ; setting? Limit
        .foreach((_, item) => list.Add(, item.filename, item.path, _get_pretty_mode(item.attr), item.score))

    hits := hit_list.len()
    showing := limited.len()

    filtering := t.ms()

    perf.Value := Format("Hits: {}/{}; Filtering: {}ms",
        hits,
        cache.len(),
        filtering
    )
}

_is_match(item) {
    global

    name := item.filename
    input_str := input.Value

    ; setting? Ignore case
    if settings.matchignorecase {
        name := StrLower(name)
        input_str := StrLower(input_str)
    }

    ; setting? Make $-Suffix search for suffixes instead of fuzzy
    if settings.dollarsuffixisendswith and Str.hasSuffix(input_str, "$") {
        return Str.hasSuffix(name, Str.sub(input_str, , StrLen(input_str)).unwrap())
    }
    ; setting? Make ?-Suffix evaluate containment instead of fuzzy searching
    if settings.qmsuffixiscontains and Str.hasSuffix(input_str, "?") {
        return Str.contains(name, Str.sub(input_str, , StrLen(input_str)).unwrap())
    }

    if StrLen(input_str) > StrLen(name) {
        return false
    }

    if settings.matchpath {
        name := item.path
    }

    i := 1
    name_len := StrLen(name)

    input_idx := 1
    input_len := StrLen(input_str)

    last_hit := false
    power := 2
    seq_len := 0
    score := 1

    while i <= name_len and input_idx <= input_len {
        if Str.charUnsafe(name, i) == Str.charUnsafe(input_str, input_idx) {
            input_idx++

            ; setting? ignore whitespace in matching
            while settings.ignorewhitespace and input_idx <= StrLen(input_str) and Str.charUnsafe(input_str, input_idx) == " " {
                input_idx++
            }

            last_hit := true
            seq_len++
        }
        else {
            seq_len := 0
            last_hit := false
        }

        if last_hit {
            power := Max(seq_len, 2)
            score *= power
        }
        else {
            power := 2
        }

        i++
    }

    item.score := score

    return input_idx - 1 == input_len
}

_handle_list_click(obj, info) {
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
        _hide_ui()
    }
}

_get_pretty_mode(mode) {
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