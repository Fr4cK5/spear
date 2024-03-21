# Spear
The only Fuzzy-Finder you'll need!

# Installation
```bash
git clone https://github.com/Fr4cK5/spear
```

# Note

- Spear-Native `./native/Spear-Native.ahk` is the version you should be using
- The normal version `./normal/Spear.ahk` is deprecated. If you use it, expect
    - No further updates
    - Less features
    - Bugs
    - Slow performance

# Features

- Fuzzy Matching
    - Fuzzy matching doesn't look for the exact input, but just for the containment of every character in the right order
    - Say you're searching for a `.png` image file
    - An input of `.pg` would match `.png` because the input's characters are in the right order and all contained in the haystack `.png`
    - `tfx` would successfully find `the-file.txt` since all the characters are contained and appear in the right order
    - `xft` would not be found since the there's no `f` after the `x` meaning not all the characters are contained in the right order

- Suffix Matching
    - To suffix match, just suffix your input with `$`.
    - To search for all mp3 files in your file hierarchy, try this input `.mp3$`
    - Since all mp3 audio files end with an `.mp3` this input will find them all
    - Why is `$` the suffix of choice? Probably all `regex` engines out there use it as their end-of-string character. Makes it a little more familiar

- Containment Matching
    - To containment-match, just suffix your input with `?`
    - You might have some file who's name you just barely remember, right?
    - Assuming the file is called `some-file.txt` any of the following inputs would find it
        - `some-file.txt?`
        - `some?`
        - `file?`
        - `me-fi?`
        - `le.t?`
    - Why is `?` the suffix of choice? It works

- Filemode filtering
    - You can filter for different types of filesystem entries using prefixes
        - Filter to only include files `:f`
        - Filter to only include links `:l`
        - Filter to only include directories `:d`
    - This can be combined in multiple different ways
        - Need to find a directory that fuzzily matches `myfile`? `:dmyfile`'s got you covered!
        - Maybe you've got a file by the name `directory` together with a bunch of other directories. `:fdirectory?` will find it for you
    - Why did I choose `:` as the prefix?
        - Makes for pretty good indicator that its a prefix
        - The `:` characters is not permitted in filenames under windows

# Usage

- `LCtrl+LWin+L` Open the UI with explorer integration if enabled
- `LCtrl+LWin+K` Open the UI without explorer integration
- Clicking
    - `LButton` Copy filepath to system clipboard
    - `LCtrl+LButton` Open entry in Explorer. This can be toggled in the settings
    - `LAlt+LButton` Execute the command set in the config with `{}` being replaced with the file's path
- `Esc` Hide the UI

# Settings

**All of this would not have been possible without GroggyOtters JSON library: `jsongo.ahk`**

- `listviewlimit` How many items the list view can display at a time
- `showfulldir` Show the full directory of the item or just the last part of it
- `autoclear` Automatically clear the UI upon hiding it
- `dollarsuffixisendswith` Suffixing your input with `$` makes the search algorithm look for suffixes instead
- `qmsoffixiscontains` Suffixing your input with `?` makes the search algorithm look for containment instead
- `ignorewhitespace` Ignore the white space in your input. `Test File.txt` will be equal to `TestFile.txt` if set to true
- `hideafteruiinteraction` Hide the UI after interacting with it
- `matchignorecase` Ignore whether any input's characters are uppercase or lowercase when filtering
- `basedir` Starting directory
- `matchpath` Incorperate the path to the file in the filtering process
- `maxitemsforautoupdate` Maximum amount of items to automatically filter and update the list while typing making it feel "realtime"
- `integrations`
    - `explorer` Enable the explorer integration
    - `editcmd` The command to be executed when opening a file from the UI's list via `LCtrl+LButton`
- `native` How many items the list view can display at a time
    - `maxitemsforautoupdate` Same as above. This value overrides the one above if you're using `Spear-Native`
    - `autofreebuffer` Automatically free the buffer and release the memory
    - `autofreetimeout` The time (seconds) `Spear-Native` must be in idle (on user-interaction) to automatically free the buffers
- `vim`
    - `enabled` Enable vim keybinds when the list view is in focus
    - `list_up` Keybind to go up
    - `list_down` Keybind to go down
    - `half_viewport_up` Keybind to go up half a viewport
    - `half_viewport_down` Keybind to go down half a viewport
    - `bot` Keybind to go to the bottom of the list view (This emulates a bunch of keypresses which makes it rather slow)
    - `top` Keybind to go to the top of the list view (This too)
    - `open_explorer` Keybind to open explorer at the selected item
    - `edit_file` Keybind to execute the `integrations/editcmd` command on the selected item
    - `yank_path` Keybind to copy ("yank" in vim terminology) the item's path
    - `yank_name` Keybind to copy the item's name

# Acknowledgements

- Spear's config system would not have been possible without [GroggyOtter's](https://github.com/GroggyOtter) amazing JSON library: [jsongo.ahk](https://github.com/GroggyOtter/jsongo_AHKv2)

- I also used another one of GroggyOtter's libraries during development: [Peep.ahk](https://github.com/GroggyOtter/PeepAHK)

Thank you for your dedication to the AHK-Community.

# Thank you

Thank you for checking out my project, hope you liked it!
