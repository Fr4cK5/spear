class SpearGUI {
    #Requires AutoHotkey 2.0.2+

    static main_gui(WIDTH := 950, HEIGHT := 700, PADDING := 20, FONT_SIZE := 15) {
        window := Gui("+ToolWindow -Caption -AlwaysOnTop")
        window.SetFont("s" . FONT_SIZE)

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
        match_path_checkbox := window.AddCheckbox(Format("x+m yp h{}",
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
        ; TODO Re-enable me when you've got some working prototype 
        ; open_config_menu := window.AddButton(Format("xp y+m w{} h{}",
        ;     BUTTON_WIDTH,
        ;     BUTTON_HEIGHT
        ; ), "Config")

        ; Bottom Section
        ; Bottom Section
        ; Bottom Section

        ; Performance metrics and matching stats
        perf := window.AddText(Format("xm y{} w{}",
            LIST_HEIGHT + EDIT_HEIGHT + PADDING * 2 + 4,
            CONTENT_WIDTH
        ), "")

        ; Current path
        NEW_PATH_WIDTH := LEFT_SIDE_WIDTH - 1 ; I somehow saw the off-by-one-pixel and fixed it!
        new_path_label := window.AddEdit(Format("xm+1 y+{} w{} +Disabled",
            OFFSET_Y,
            NEW_PATH_WIDTH
        ), "")

        credit := window.AddText(Format("x+m yp w{}",
            RIGHT_SIDE_WIDTH
        ), "Made by Yarrak Obama.`nBlazingly Fast!")
        credit.SetFont("s10")
        
        return {
            WIDTH: WIDTH,
            HEIGHT: HEIGHT,
            window: window,
            input: input,
            stats: stats,
            list: list,
            perf: perf,
            free_button: free_button,
            select_dir: select_dir,
            refresh_cache: refresh_cache,
            new_path_label: new_path_label,
            match_path_checkbox: match_path_checkbox,
            open_config_menu: open_config_menu,
        }
    }

    static config_gui(owner_hwnd, config, WIDTH := 950, HEIGHT := 700, PADDING := 20, FONT_SIZE := 15) {
        window := Gui("+Owner" owner_hwnd)
        window.SetFont("s" . FONT_SIZE)

        window.MarginX := PADDING / 2
        window.MarginY := PADDING / 2

        CONTENT_WIDTH := WIDTH - PADDING * 2
        LEFT_SIDE_WIDTH := CONTENT_WIDTH * .8
        RIGHT_SIDE_WIDTH := CONTENT_WIDTH * .2
        EDIT_HEIGHT := 30

        BUTTON_HEIGHT := 35
        BUTTON_WIDTH := RIGHT_SIDE_WIDTH - PADDING

        OFFSET_Y := 5

        ; Autoclear
        config_autoclear_checkbox := SpearGUI.add_checkbox_below(
            window,
            "Automatically clear the ui after interaction",
            config.autoclear,
            CONTENT_WIDTH
        )

        ; Show full dir
        config_showfulldir := SpearGUI.add_checkbox_below(
            window,
            "Show the full filepath in the list",
            config.showfulldir,
            CONTENT_WIDTH
        )

        ; Listview limit
        config_listviewlimit := SpearGUI.add_edit_below(
            window,
            "Maximum amout of items in the list",
            config.listviewlimit,
            CONTENT_WIDTH,
            PADDING
        )

        ; Match Ignorecase
        config_ignorecase := SpearGUI.add_checkbox_below(
            window,
            "Ignore letter casing while matching",
            config.matchignorecase,
            CONTENT_WIDTH
        )

        ; Suffix search
        config_dollarsuffix := SpearGUI.add_checkbox_below(
            window,
            "$ suffix is suffix-search",
            config.dollarsuffixisendswith,
            CONTENT_WIDTH
        )

        ; Containment search
        config_qmsuffix := SpearGUI.add_checkbox_below(
            window,
            "? suffix is containment-search",
            config.qmsuffixiscontains,
            CONTENT_WIDTH
        )

        ; Ignore whitespace
        config_ignore_whitespace := SpearGUI.add_checkbox_below(
            window,
            "Ignore input whitespace (fuzzy-mode)",
            config.ignorewhitespace,
            CONTENT_WIDTH
        )

        ; Hide after interaction
        config_hide_after_interaction := SpearGUI.add_checkbox_below(
            window,
            "Hide the Spear window after interacting with it",
            config.hideafteruiinteraction,
            CONTENT_WIDTH
        )

        ; Hide after interaction
        config_basedir := SpearGUI.add_edit_below(
            window,
            "Base directory",
            config.basedir,
            CONTENT_WIDTH,
            PADDING
        )

        config_matchpath := SpearGUI.add_checkbox_below(
            window,
            "Include the filepath in while matching",
            config.matchpath,
            CONTENT_WIDTH
        )

        return {
            window: window,
            config_autoclear_checkbox: config_autoclear_checkbox,
            config_showfulldir: config_showfulldir,
            config_listviewlimit: config_listviewlimit,
            config_ignorecase: config_ignorecase,
            config_dollarsuffix: config_dollarsuffix,
            config_qmsuffix: config_qmsuffix,
            config_ignore_whitespace: config_ignore_whitespace,
            config_hide_after_interaction: config_hide_after_interaction,
            config_basedir: config_basedir,
            config_matchpath: config_matchpath,
        }
    }

    static add_edit_below(g, name, value, width, padding) {
        g.AddText(Format("xm y+m w{} h30",
            width * .75 - padding * 2
        ), name)

        edt := g.AddEdit(Format("x+m yp w{} h30",
            width * .25 - padding
        ), value)

        return edt
    }

    static add_checkbox_below(g, name, value, width) {
        cb := g.AddCheckbox(Format("xm y+m w{} h30",
            width
        ), name)
        cb.Value := value

        return cb
    }

}