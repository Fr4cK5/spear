class SpearGUI {
    #Requires AutoHotkey 2.0.2+

    ; Okay listen. When I add more gui elements I will refactor this.
    ; but for now, this does it's job just fine.
    static new(WIDTH := 800, HEIGHT := 700, PADDING := 20, FONT_SIZE := 15, BUTTON_HEIGHT := 35, BUTTON_WIDTH := 150) {
        window := Gui("+ToolWindow -Caption -AlwaysOnTop")
        window.SetFont(Format("s{}", FONT_SIZE))

        window.MarginX := PADDING
        window.MarginY := PADDING

        CONTENT_WIDTH := WIDTH - PADDING * 2

        ; Filter input
        INPUT_BOX_WIDTH := CONTENT_WIDTH - WIDTH / 4
        INPUT_BOX_HEIGHT := 30
        input := window.AddEdit(Format("xm ym w{} h{}",
            INPUT_BOX_WIDTH,
            INPUT_BOX_HEIGHT
        ))

        ; Filecount stats
        STATS_WIDTH := WIDTH * .25 - PADDING * 2
        STATS_HEIGHT := INPUT_BOX_HEIGHT
        stats := window.AddText(Format("x+m ym+3 w{} hp",
            STATS_WIDTH,
            STATS_HEIGHT
        ), "...")

        ; File list-view
        LIST_WIDTH := CONTENT_WIDTH
        LIST_HEIGHT := HEIGHT * .78 - PADDING * 2
        list := window.AddListView(Format("+Grid xm y+m-3 w{} h{}",
            LIST_WIDTH,
            LIST_HEIGHT
        ), ["Name", "Directory", "Type", "Score"])
        list.ModifyCol(1, LIST_WIDTH / 3)
        list.ModifyCol(2, LIST_WIDTH / 2 - 5)
        list.ModifyCol(3, LIST_WIDTH / 6)

        ; Performance metrics and matching stats
        PERF_WIDTH := CONTENT_WIDTH
        perf := window.AddText(Format("xm y+3 w{}",
            PERF_WIDTH
        ), "")

        ; Free FFI buffers
        OFFSET_Y := 5
        free_button := window.AddButton(Format("xm y+{} w{} h{}",
            OFFSET_Y,
            BUTTON_WIDTH,
            BUTTON_HEIGHT
        ), "Clear Cache")

        ; Refresh the cache in the current directory or re-index all hierarchy
        refresh_cache := window.AddButton(Format("x+m yp w{} h{}",
            BUTTON_WIDTH,
            BUTTON_HEIGHT
        ), "Refresh Cache")

        ; Select and index andother directory manually
        select_dir := window.AddButton(Format("x+m yp w{} h{}",
            BUTTON_WIDTH,
            BUTTON_HEIGHT
        ), "Select Dir")

        match_path_box := window.AddCheckbox(Format("x+m yp h{}",
            BUTTON_HEIGHT
        ), "Match Filepath")

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
        }
    }
}