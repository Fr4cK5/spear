class SpearGUI {
    #Requires AutoHotkey 2.0.2+

    ; Okay listen. When I add more gui elements I will refactor this.
    ; but for now, this does it's job just fine.
    static new(WIDTH := 800, HEIGHT := 700, PADDING := 20, FONT_SIZE := 15) {
        window := Gui("+ToolWindow -Caption -AlwaysOnTop")
        window.SetFont(Format("s{}", FONT_SIZE))

        window.MarginX := PADDING
        window.MarginY := PADDING

        CONTENT_WIDTH := WIDTH - PADDING * 2
        LEFT_SIDE_WIDTH := CONTENT_WIDTH * .8
        RIGHT_SIDE_WIDTH := CONTENT_WIDTH * .2
        EDIT_HEIGHT := 30

        BUTTON_HEIGHT := 35
        BUTTON_WIDTH := RIGHT_SIDE_WIDTH - PADDING

        OFFSET_Y := 5

        ; Filter input
        input := window.AddEdit(Format("xm ym w{} h{}",
            LEFT_SIDE_WIDTH,
            EDIT_HEIGHT
        ))

        ; Filecount stats
        stats := window.AddText(Format("x+m ym+3 w{} hp",
            RIGHT_SIDE_WIDTH,
            EDIT_HEIGHT
        ), "...")

        ; File list-view
        LIST_WIDTH := LEFT_SIDE_WIDTH
        LIST_HEIGHT := HEIGHT * .83 - PADDING * 2
        list := window.AddListView(Format("+Grid xm y+m-3 w{} h{}",
            LIST_WIDTH,
            LIST_HEIGHT
        ), ["Name", "Directory", "Type", "Score"])
        list.ModifyCol(1, LIST_WIDTH / 3)
        list.ModifyCol(2, LIST_WIDTH / 2 - 5)
        list.ModifyCol(3, LIST_WIDTH / 6)

        ; Side Buttons
        ; Side Buttons
        ; Side Buttons

        ; Match path checkbox
        match_path_box := window.AddCheckbox(Format("x+m yp h{}",
            BUTTON_HEIGHT
        ), "Match Filepath")

        ; Free FFI buffers
        free_button := window.AddButton(Format("xp y+m w{} h{}",
            BUTTON_WIDTH,
            BUTTON_HEIGHT
        ), "Clear Cache")

        ; Refresh the cache in the current directory or re-index all hierarchy
        refresh_cache := window.AddButton(Format("xp y+m w{} h{}",
            BUTTON_WIDTH,
            BUTTON_HEIGHT
        ), "Refresh Cache")

        ; Select and index andother directory manually
        select_dir := window.AddButton(Format("xp y+m w{} h{}",
            BUTTON_WIDTH,
            BUTTON_HEIGHT
        ), "Select Dir")

        ; Config Menu
        open_config_menu := window.AddButton(Format("xp y+m w{} h{}",
            BUTTON_WIDTH,
            BUTTON_HEIGHT
        ), "Config")

        ; Bottom Section
        ; Bottom Section
        ; Bottom Section

        ; Performance metrics and matching stats
        perf := window.AddText(Format("xm y{} w{}",
            LIST_HEIGHT + EDIT_HEIGHT + PADDING * 2 + 4,
            CONTENT_WIDTH
        ), "")

        ; Current path
        NEW_PATH_WIDTH := CONTENT_WIDTH - 1 ; I somehow saw the off-by-one-pixel and fixed it!
        new_path_label := window.AddEdit(Format("xm+1 y+{} w{} +Disabled",
            OFFSET_Y,
            NEW_PATH_WIDTH
        ), "")
        
        return {
            WIDTH: WIDTH,
            HEIGHT: HEIGHT,
            PADDING: PADDING,
            BUTTON_WIDTH: BUTTON_WIDTH,
            BUTTON_HEIGHT: BUTTON_HEIGHT,
            window: window,
            input: input,
            stats: stats,
            list: list,
            perf: perf,
            free_button: free_button,
            select_dir: select_dir,
            refresh_cache: refresh_cache,
            new_path_label: new_path_label,
            match_path_box: match_path_box,
            open_config_menu: open_config_menu,
        }
    }
}