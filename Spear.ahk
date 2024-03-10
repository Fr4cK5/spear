#Requires AutoHotkey 2.0.2+
#SingleInstance Force

CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

#Include v2d.v2.ahk
#Include viewport.v2.ahk
#include str.v2.ahk
#Include vec.v2.ahk
#Include result.v2.ahk
#Include option.v2.ahk
#Include timer.v2.ahk
#Include peep.v2.ahk
#Include files.v2.ahk

#Include FileHit.ahk

TraySetIcon("./asset/spear-icon.ico")

; WE DEBUGGING

; #Include logger.v2.ahk
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

base_dir := "C:\.dev\*"

cache := Vec()
cache_ready := false
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

    find(input)
}

Esc::hide_ui()

hide_ui() {
    global
    window.Hide()

    ; setting? Clear everything upon hiding
    while(list.Delete()) {
    }
    input.Value := ""
    perf.Value := ""
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
    if !WinActive("ahk_exe explorer.exe") {
        ; setting? Automatically activate explorer to grab path
        return
    }

    bak := A_Clipboard
    Sleep(50)
    SendEvent("^l^c")
    Sleep(50)
    set_base_dir(A_Clipboard)
    Sleep(50)
    A_Clipboard := bak
}

set_base_dir(path) {
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
    SetTimer(() => fill_cache(), -1, 0x7fffffff)
}


fill_cache() {
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
        ; if ... {
        ;     path := Str.sub(path, Str.lastIndex(path, "\").unwrap() + 1).unwrap()
        ; }

        ; setting... Or Show the full thing
        path := StrReplace(path, "\", "/")

        cache.push(FileHit(filename, path, A_LoopFileAttrib))
    }

    stats.Value := Format("Cached {} Files", cache.len())

    cache_ready := true
}

find(obj) {
    global

    t := Timer()
    t.start()

    while(list.Delete()) {
    }

    if Trim(obj.Value) == "" {
        return
    }

    if cache.len() == 0 and cache_ready {
        SetTimer(() => fill_cache(), -1, 0x7fffffff)
    }

    while(!cache_ready) {
    }

    if cache.len() == 0 {
        perf.Value := ""
        return
    }

    searching := t.ms()

    hit_list := cache
        .filter((_, item) => is_match(item))
        .sort((a, b) => a.score < b.score)
    
    limited := hit_list
        .limit(250) ; setting? Limit
        .foreach((_, item) => list.Add(, item.filename, item.path, get_pretty_mode(item.attr), item.score))

    hits := hit_list.len()
    showing := limited.len()

    total := t.ms()
    filtering := total - searching

    perf.Value := Format("Hits: {}/{}; Caching: {}ms; Filtering: {}ms; Total: {}ms",
        hits,
        cache.len(),
        searching,
        filtering,
        total
    )
}

is_match(item) {
    global

    ; setting? Ignore case
    name := StrLower(item.filename)
    input_str := StrLower(input.Value)

    ; setting? Make $-Suffix search for suffixes instead of fuzzy
    if Str.hasSuffix(input_str, "$") {
        return Str.hasSuffix(name, Str.sub(input_str, , StrLen(input_str)).unwrap())
    }
    ; setting? Make ?-Suffix evaluate containment instead of fuzzy searching
    if Str.hasSuffix(input_str, "?") {
        return Str.contains(name, Str.sub(input_str, , StrLen(input_str)).unwrap())
    }

    if StrLen(input_str) > StrLen(name) {
        return false
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
            ; while ignore_whitespace && ... { }
            while input_idx <= StrLen(input_str) and Str.charUnsafe(input_str, input_idx) == " " {
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

handle_list_click(obj, info) {
    name := list.GetText(info, 1)
    path := list.GetText(info, 2)
    mode := list.GetText(info, 3)

    if GetKeyState("Control", "P") {
        path_parts := Vec.FromClone(StrSplit(path, "/"))
        working_dir := path_parts
            .limit(path_parts.len() - (Str.hasPrefix(mode, "File") ? 1 : 0))
            .join("\")
        
        if working_dir.isNone() {
            return
        }

        Run(Format("explorer {}", working_dir.unwrap()))
    }

    if GetKeyState("LAlt", "P") {
        A_Clipboard := name
    }
    else {
        A_Clipboard := path
    }

    ; setting? Autohide after copy / explorer start
    hide_ui()
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