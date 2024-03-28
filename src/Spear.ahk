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

#Include FileHit.ahk
#Include Spear-GUI.ahk
#Include Spear-FAL.ahk

TraySetIcon("../asset/spear-icon.ico")

SetWinDelay(-1)

; GUI
; GUI
; GUI

GUI_MAIN_WIDTH := 950
GUI_MAIN_HEIGHT := 700
PADDING := 20
FONT_SIZE := 15

GUI_CONFIG_WIDTH := GUI_MAIN_WIDTH / 2
GUI_CONFIG_HEIGHT := GUI_MAIN_HEIGHT

main_gui := SpearGUI.main_gui(
    GUI_MAIN_WIDTH,
    GUI_MAIN_HEIGHT,
    PADDING,
    FONT_SIZE
)

main_gui.input.OnEvent("Change", auto_update_list)
auto_update_list(obj, info) {
    while !cache_ready {
    }

    if lib.found_files <= settings.native.maxitemsforautoupdate {
        find(obj.Value)
    }
}

LIST_SELECTION_IDX := -1
main_gui.list.OnEvent("Click", handle_list_click)
main_gui.list.OnEvent("Focus", (*) => set_vim_binds(true))
main_gui.list.OnEvent("LoseFocus", (*) => set_vim_binds(false))
main_gui.list.OnEvent("ItemFocus", set_list_selection)
set_list_selection(_, item) {
    global
    LIST_SELECTION_IDX := item
}

set_vim_binds(b) {
    ; Setting? Vim!!! (bindings)
    if !settings.vim.enabled {
        return
    }

    s := b ? "on" : "off"

    Hotkey(settings.vim.list_up, vim_go_up, s)
    Hotkey(settings.vim.list_down, vim_go_down, s)
    Hotkey(settings.vim.half_viewport_up, vim_half_viewport_up, s)
    Hotkey(settings.vim.half_viewport_down, vim_half_viewport_down, s)
    Hotkey(settings.vim.top, vim_top, s)
    Hotkey(settings.vim.bot, vim_bot, s)
    Hotkey(settings.vim.open_explorer, vim_open_explorer, s)
    Hotkey(settings.vim.edit_file, vim_edit_file, s)
    Hotkey(settings.vim.yank_path, vim_yank_path, s)
    Hotkey(settings.vim.yank_name, vim_yank_name, s)

    ; Focus the first item
    vim_go_down()
}

main_gui.free_button.OnEvent("click", free_button_callback)
free_button_callback(*) {
    lib.free_mem()
    clear_ui()
}

main_gui.select_dir.OnEvent("click", select_dir_callback)
select_dir_callback(*) {
    set_base_dir(DirSelect())
    SetTimer(() => fill_cache(), -1, 0x7fffffff)
}

main_gui.refresh_cache.OnEvent("Click", refresh_cache)
refresh_cache(*) {
    cache_ready := false
    SetTimer(() => fill_cache(), -1, 0x7fffffff)
}

main_gui.match_path_checkbox.OnEvent("Click", toggle_match_path)
toggle_match_path(obj, _) {
    lib.set_match_path(obj.Value)

    while !cache_ready {
    }

    if lib.found_files <= settings.native.maxitemsforautoupdate {
        find(main_gui.input.Value)
    }
}

; TODO Config menu
; NOTE I'll also need to re-enable the config-button in SpearGUI.new_main()
; main_gui.open_config_menu.OnEvent("Click", open_config_menu)
open_config_menu(*) {
    ToolTip("To be implemented")
    SetTimer(() => ToolTip(), -3000)
    if true { ; tHis LINe wILl neVER ExEcuTe
        return
    }

    ; Hey you, if you find this, please read:
    ; I'm not quite sure how to tacle this since there are a lot of settings.
    ; I need some kind of scrollable ui area but that's rather... you know... hard with win32 GUIs
    config_gui := SpearGUI.config_gui(
        main_gui.window.Hwnd,
        settings,
        GUI_CONFIG_WIDTH,
        GUI_CONFIG_HEIGHT,
        PADDING,
        FONT_SIZE
    )

    main_gui.window.GetPos(&x, &y, &w, &h)
    show_centered(config_gui.window, GUI_CONFIG_WIDTH, GUI_CONFIG_HEIGHT)

    while WinActive(config_gui.window) {
        Sleep(100)
    }

    config_gui.window.Destroy()
}

; Init
; Init
; Init

settings := load_settings()

base_dir := ""
set_base_dir(settings.basedir)

lib := SpearFAL()
lib.setup_settings(settings)

auto_free_timer := Timer()
is_auto_freed := false

SetTimer(() => fill_cache(), -1, 0x7fffffff)

; Post Init Gui Update
; Post Init Gui Update
; Post Init Gui Update

main_gui.match_path_checkbox.Value := settings.matchpath

; Hotkeys
; Hotkeys
; Hotkeys

; Ctrl Win L -> Open UI with explorer integration
^#l::{
    global
    SendEvent("{Ctrl Up}{Win Up}{l Up}")
    if is_auto_freed {
        is_auto_freed := false
        auto_free_timer.start()
        SetTimer(() => fill_cache(), -1, 0x7fffffff)
    }

    explorer_integration()
    show_centered(main_gui.window, main_gui.WIDTH, main_gui.HEIGHT)
    main_gui.input.Focus()
}

; Ctrl Win K -> Open UI without checking for explorer
^#k::{
    global
    SendEvent("{Ctrl Up}{Win Up}{k Up}")
    if is_auto_freed {
        is_auto_freed := false
        auto_free_timer.start()
        SetTimer(() => fill_cache(), -1, 0x7fffffff)
    }

    show_centered(main_gui.window, main_gui.WIDTH, main_gui.HEIGHT)
    main_gui.input.Focus()
}

; Manually filter if the amount of found files is too large.
; You can adjust the maximum amount of items for auto-search in your config.json.
~*Enter:: {
    if !WinActive(main_gui.window) {
        return
    }
    if !main_gui.input.Focused {
        return
    }

    find(main_gui.input.Value)
}

~*^f:: {
    if !WinActive(main_gui.window) {
        return
    }

    main_gui.input.Focus()
}

~*^l:: {
    if !WinActive(main_gui.window) {
        return
    }

    main_gui.list.Focus()
}

~*^m:: {
    if !WinActive(main_gui.window) {
        return
    }

    main_gui.match_path_checkbox.Value := !main_gui.match_path_checkbox.Value
    toggle_match_path(main_gui.match_path_checkbox, 0)
}

~Esc::hide_ui()

; Vim GUI Callbacks
; Vim GUI Callbacks
; Vim GUI Callbacks

vim_go_up(*) {
    global
    if !main_gui.list.Focused or LIST_SELECTION_IDX <= 0 {
        return
    }

    ControlSend("{up}", main_gui.list)
}

vim_go_down(*) {
    global
    if !main_gui.list.Focused or LIST_SELECTION_IDX == -1 {
        return
    }

    ControlSend("{down}", main_gui.list)
}

vim_half_viewport_up(*) {
    loop 7 {
        vim_go_up()
    }
}

vim_half_viewport_down(*) {
    loop 7 {
        vim_go_down()
    }
}

vim_top(*) {
    loop LIST_SELECTION_IDX - 1 {
        vim_go_up()
    }
}

vim_bot(*) {
    loop main_gui.list.GetCount() - LIST_SELECTION_IDX {
        vim_go_down()
    }
}

vim_open_explorer(*) {
    global
    if !main_gui.list.Focused {
        return
    }

    path := main_gui.list.GetText(LIST_SELECTION_IDX, 2)
    mode := main_gui.list.GetText(LIST_SELECTION_IDX, 3)
    explorer_at(path, mode)
}

vim_edit_file(*) {
    global
    if !main_gui.list.Focused {
        return
    }

    path := main_gui.list.GetText(LIST_SELECTION_IDX, 2)
    mode := main_gui.list.GetText(LIST_SELECTION_IDX, 3)
    edit_file(path, mode)
}

vim_yank_path(*) {
    global
    if !main_gui.list.Focused {
        return
    }

    A_Clipboard := main_gui.list.GetText(LIST_SELECTION_IDX, 2)
}

vim_yank_name(*) {
    global
    if !main_gui.list.Focused {
        return
    }

    A_Clipboard := main_gui.list.GetText(LIST_SELECTION_IDX, 1)
}

; Functions
; Functions
; Functions

hide_ui() {
    global

    main_gui.window.Hide()

    ; setting? Clear everything upon hiding
    if settings.autoclear {
        clear_ui()
    }
}

clear_ui(lib_initialized := true, preserve_stats := false) {
    global
    while main_gui.list.Delete() {
    }
    main_gui.input.Value := ""
    main_gui.perf.Value := "..."
    if !preserve_stats and lib_initialized and lib.found_files == 0 {
        main_gui.stats.Value := "No files indexed"
    }
    else {
        main_gui.stats.Value := ""
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

    ; Since the windows desktop is just an explorer isntance under the hood,
    ; we need to also make sure that it's an actual window via filtering the ahk_class too
    ; If you're reading this code, AutoHotkey Window Spy is very helpful with these kinds of things
    ; Assuming you've got AHK on your system, it should be installed.
    handle := WinActive("ahk_exe explorer.exe ahk_class CabinetWClass")
    if !handle {
        return
    }

    path := ""
    for window in ComObject("Shell.Application").Windows {
        if window.hwnd == handle {
            path := window.Document.Folder.Self.Path
        }
    }

    ; If the user was in This PC - instead of a path - we just get a CLSID ::{xxxxyyyy-zzzz-...}
    ; here we check if the path is absolute
    if !RegExMatch(path, "i)^\w:[\\/]") {
        if settings.showerr {
            TrayTip("Cannot open path of 'This PC'", "Spear", 0x13)
        }
        return
    }

    set_base_dir(path)
    SetTimer(() => fill_cache(), -1, 0x7fffffff)
}

load_settings() {
    settings := {}
    try {
        settings_content := FileRead("../config/config.json")
        settings := jsongo.Parse(settings_content)
    }
    catch {
        settings_content := FileRead("../config/config_default.json")
        FileCopy("../config/config_default.json", "../config/config.json")
        settings := jsongo.Parse(settings_content)
        SetTimer(() => MsgBox("Unable to parse or locate personal config file.`nFalling back to default config.`nFor more information, see https://github.com/Fr4cK5/spear#readme under the Installation and/or Configuration section."), -1)
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
        showerr: settings["showerr"],
        integrations: {
            explorer: settings["integrations"]["explorer"], ; Enable the explorer integration
            editcmd: settings["integrations"]["editcmd"], ; The command to be executed when Opening a file from the UI's list via Ctrl+Left Click
        },
        native: {
            maxitemsforautoupdate: settings["native"]["maxitemsforautoupdate"], ; Same as above; This value overrides the one above if you're using Spear-Native
            autofreebuffer: settings["native"]["autofreebuffer"], ; Automatically free the buffer and release the memory
            autofreetimeout: settings["native"]["autofreetimeout"], ; The time (seconds) Spear-Native must be in idle (you don't interact with it at all) to automatically free the buffers
        },
        
        vim: { ; When filtering, use Tab to move focus to the listview. Here you'll be able to use vim bindings if you'd like.
            enabled: settings["vim"]["enabled"],
            list_up: settings["vim"]["list_up"],
            list_down: settings["vim"]["list_down"],
            open_explorer: settings["vim"]["open_explorer"],
            edit_file: settings["vim"]["edit_file"],
            half_viewport_up: settings["vim"]["half_viewport_up"],
            half_viewport_down: settings["vim"]["half_viewport_down"],
            bot: settings["vim"]["bot"],
            top: settings["vim"]["top"],
            yank_path: settings["vim"]["yank_path"],
            yank_name: settings["vim"]["yank_name"],
        },
    }
}

set_base_dir(path) {
    global

    if Trim(path) == "" {
        return
    }

    temp := Str.replaceAll(path, "\", "/")

    if Str.endsWith(temp, "*") {
        temp := Str.sub(temp, , StrLen(temp)).unwrap()
    }

    if Str.endsWith(temp, "/") {
        temp := Str.sub(temp, , StrLen(temp)).unwrap()
    }

    ; We only want to return after all the sanitizing has been done since
    ; this ensures that we're actually dealing with the same path.
    ; This way we know for sure that we don't need to re-index the whole directory structure.
    if base_dir == temp {
        return
    }

    base_dir := temp
    cache_ready := false

    clear_ui(false)
    main_gui.new_path_label.Value := base_dir

    ; Scroll the end of the edit if the path happens to be longer than the control
    ControlSend("{End}", main_gui.new_path_label)
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
    main_gui.stats.Value := Format("{} Files", lib.found_files)
}

find(s) {
    global

    auto_free_timer.start()

    if Trim(s) == "" or lib.found_files == 0 {
        while main_gui.list.Delete() {
        }
        main_gui.perf.Value := "..."
        return
    }

    lib.set_user_input(s)

    t := Timer()
    t.start()

    LIST_SELECTION_IDX := -1
    while main_gui.list.Delete() {
    }

    lib.ffi_filter()
    filtering := t.ms()

    limited := lib.filtered_buffer_to_vec()
        .limit(settings.listviewlimit) ; setting? Limit
        .foreach((_, item) => main_gui.list.Add(, item.filename, item.path, get_pretty_mode(item.attr), item.score))

    hits := lib.matching_files
    showing := limited.len()

    main_gui.perf.Value := Format("Hits: {}/{}; Filtering: {}ms",
        hits,
        lib.found_files,
        filtering
    )

    if hits > 0 {
        LIST_SELECTION_IDX := 0
    }
}

explorer_at(path, filemode) {
    path_parts := Vec.FromClone(StrSplit(path, "/"))
    working_dir := path_parts
        .limit(path_parts.len() - (Str.hasPrefix(filemode, "File") ? 1 : 0))
        .join("\")
    
    if working_dir.isNone() {
        return
    }

    Run(Format("explorer {}", working_dir.unwrap()))
}

edit_file(path, filemode) {
    if filemode != "File" and filemode != "Link" {
        return
    }

    Run(Format(settings.integrations.editcmd, path))
}

handle_list_click(obj, info) {
    name := main_gui.list.GetText(info, 1)
    path := main_gui.list.GetText(info, 2)
    mode := main_gui.list.GetText(info, 3)

    ; Unsure if this makes things better or worse, but it works just fine!
    LIST_SELECTION_IDX := info

    if GetKeyState("Control", "P") {
        explorer_at(path, mode)
    }
    else if GetKeyState("LAlt", "P") {
        edit_file(path, mode)
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