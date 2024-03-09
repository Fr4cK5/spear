#Requires AutoHotkey 2.0.2+
#SingleInstance Force

CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

#Include v2d.v2.ahk
#Include viewport.v2.ahk
#Include strings.v2.ahk
#Include vec.v2.ahk
#Include result.v2.ahk
#Include option.v2.ahk
#Include timer.v2.ahk
#Include peep.v2.ahk

#Include FileHit.ahk

WIDTH := 800
HEIGHT := 600
PADDING := 20
FONT_SIZE := 15

window := Gui("+ToolWindow -Caption +AlwaysOnTop")
window.SetFont(Format("s{}", FONT_SIZE))

INPUT_BOX_POS := PADDING
INPUT_BOX_WIDTH := WIDTH - PADDING * 2 - 100
INPUT_BOX_HEIGHT := 30
input := window.AddEdit(Format("x{} y{} w{} h{}",
    INPUT_BOX_POS,
    INPUT_BOX_POS,
    INPUT_BOX_WIDTH,
    INPUT_BOX_HEIGHT
))

STATS_X := PADDING * 2 + INPUT_BOX_WIDTH
STATS_Y := PADDING
STATS_WIDTH := WIDTH - STATS_X - PADDING
STATS_HEIGHT := INPUT_BOX_HEIGHT
stats := window.AddText(Format("x{} y{} w{} h{}",
    STATS_X,
    STATS_Y,
    STATS_WIDTH,
    STATS_HEIGHT
), Format("0/{}", 250)) ; opt? Max items at once

LIST_X := PADDING
LIST_Y := PADDING * 2 + INPUT_BOX_HEIGHT
LIST_WIDTH := WIDTH - PADDING * 2
LIST_HEIGHT := HEIGHT - PADDING * 2 - INPUT_BOX_HEIGHT - 40
list := window.AddListView(Format("+Grid x{} y{} w{} h{}",
    LIST_X,
    LIST_Y,
    LIST_WIDTH,
    LIST_HEIGHT
), ["Name", "Directory"])
list.OnEvent("Click", handle_list_click)

list.ModifyCol(1, LIST_WIDTH / 2 - PADDING / 2)
list.ModifyCol(2, LIST_WIDTH / 2)

PERF_X := PADDING
PERF_Y := HEIGHT - PADDING * 2
PERF_WIDTH := WIDTH - PADDING * 2
perf := window.AddText(Format("x{} y{} w{}",
    PERF_X,
    PERF_Y,
    PERF_WIDTH
), "Performance")

Esc::ExitApp()
^#l::{
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

; Esc::hide_ui()

hide_ui() {
    global
    window.Hide()
    while(list.Delete()) {
    }
    input.Value := ""
    perf.Value := "Performance"
}

show_centered(g, width, height) {
    vp := Viewport()
    pos := Vector2(
        vp.halfX() - width / 2,
        vp.halfY() - height / 2,
    )
    g.Show(Format("x{} y{} w{} h{}", pos.x, pos.y, width, height))
}

find(obj) {

    t := Timer()
    t.start()

    while(list.Delete()) {
    }

    if Trim(obj.Value) == "" {
        return
    }

    files := Vec()

    ; opt? Search type
    loop files "C:\.dev\*", "DFR" {

        filename := A_LoopFileName
        path := A_LoopFilePath
        if filename == path {
            path := "./"
        }

        ; opt? Either show the last directory of the path
        ; else {
        ;     path := Strings.sub(path, Strings.lastIndex(path, "\") + 1)
        ; }

        ; opt... Or Show the full thing
        ; if !Strings.startsWith(path, "./") and Strings.char(path, 2) != ":" {
        ;     path := "./" . path
        ; }
        path := StrReplace(path, "\", "/")

        files.push(FileHit(filename, path, obj.Value))
    }

    if files.len() == 0 {
        perf.Value := "Performance"
        return
    }

    searching := t.ms()

    files
        .retain((_, item) => is_match(item))
        .sortInPlace((a, b) => a.score < b.score)
    
    limited := files
        .limitInPlace(250) ; opt? Limit
        .foreach((_, item) => list.Add(, item.filename, item.path))

    hits := files.len()
    showing := limited.len()

    total := t.ms()
    filtering := total - searching

    perf.Value := Format("Hits: {}; Search: {}ms; Filter: {}ms; Total: {}ms",
        hits,
        searching,
        filtering,
        total
    )

    stats.Value := Format("{}/{}", showing, 250)
}

is_match(item) {
    ; opt? Ignore case
    name := StrLower(item.filename)
    input := StrLower(item.input)

    ; FIXME: Idk man, endsWith is bugged *shrug*
    ; if Strings.char(input, StrLen(input)) == "$" {
    ;     return Strings.endsWith(name, SubStr(input, 0, StrLen(input) - 1))
    ; }

    if StrLen(input) > StrLen(name) {
        return false
    }

    i := 1
    name_len := StrLen(name)

    input_idx := 1
    input_len := StrLen(input)

    last_hit := false
    power := 2
    seq_len := 0
    score := 1

    while i <= name_len and input_idx <= input_len {
        if Strings.char(name, i) == Strings.char(input, input_idx) {
            input_idx++

            ; opt? ignore whitespace in matching
            ; while ignore_whitespace and Strings.char...
            ; This don't quite work... somehow?
            while Strings.char(input, input_idx) == " " {
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
            power += power * seq_len
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

    if GetKeyState("Control", "P") {
        path_parts := Vec.FromClone(StrSplit(path, "/"))
        working_dir := path_parts
            .limit(path_parts.len() - 1)
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

    ; opt? Autohide after copy / explorer start
    hide_ui()
}