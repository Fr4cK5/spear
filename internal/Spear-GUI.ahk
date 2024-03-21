#Requires AutoHotkey 2.0.2+

class SpearGUI {

    ; Okay listen. When I add more gui elements I will refactor this.
    ; but for now, this does it's job just fine.
    static mk_gui(WIDTH := 800, HEIGHT := 640, PADDING := 20, FONT_SIZE := 15, BUTTON_HEIGHT := 34, BUTTON_WIDTH := 150) {
        window := Gui("+ToolWindow -Caption -AlwaysOnTop")
        window.SetFont(Format("s{}", FONT_SIZE))

        ; Filter input
        INPUT_BOX_POS := PADDING
        INPUT_BOX_WIDTH := WIDTH - PADDING * 2 - 200
        INPUT_BOX_HEIGHT := 30
        input := window.AddEdit(Format("x{} y{} w{} h{}",
            INPUT_BOX_POS,
            INPUT_BOX_POS,
            INPUT_BOX_WIDTH,
            INPUT_BOX_HEIGHT
        ))

        ; Filecount stats
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

        ; File list-view
        LIST_SELECTION_IDX := -1
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
        list.ModifyCol(1, LIST_WIDTH / 3)
        list.ModifyCol(2, LIST_WIDTH / 2 - 5)
        list.ModifyCol(3, LIST_WIDTH / 6)

        ; Performance metrics and matching stats
        PERF_X := PADDING
        PERF_Y := HEIGHT - PADDING * 2 + 7 - 40
        PERF_WIDTH := WIDTH - PADDING * 2
        perf := window.AddText(Format("x{} y{} w{}",
            PERF_X,
            PERF_Y,
            PERF_WIDTH
        ), "")

        ; Free FFI buffers
        FREE_X := PERF_X
        FREE_Y := PERF_Y + 30
        free_button := window.AddButton(Format("x{} y{} w{} h{}",
            FREE_X,
            FREE_Y,
            BUTTON_WIDTH,
            BUTTON_HEIGHT
        ), "Free memory")

        ; Select and index andother directory manually
        SELECT_X := FREE_X + BUTTON_WIDTH + PADDING
        SELECT_Y := FREE_Y
        SELECT_WIDTH := BUTTON_WIDTH
        select_dir := window.AddButton(Format("x{} y{} w{} h{}",
            SELECT_X,
            SELECT_Y,
            SELECT_WIDTH,
            BUTTON_HEIGHT
        ), "Select Dir")

        NEW_PATH_X := SELECT_X + PADDING + BUTTON_WIDTH
        NEW_PATH_Y := FREE_Y
        NEW_PATH_WIDTH := 413
        new_path_label := window.AddEdit(Format("x{} y{} w{} +Disabled",
            NEW_PATH_X + 7,
            NEW_PATH_Y,
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
            new_path_label: new_path_label,
        }
    }
}