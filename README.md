# Spear
The only Fuzzy-Finder you'll need!

# Installation
```bash
git clone https://github.com/Fr4cK5/spear
```
1. Do either of
    - Start Spear `./native/Spear-Native.ahk`. Since there's no personal config file, it will automatically copy the default one.
    - Make a copy of the file `./config/config_default.json` and name it `config.json`.
1. Now you can safely edit your config while also having a fallback option.

# Important

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
    - An input of `HlWr!` would match `Hello, World!` because the input's characters are in the right order and all contained in the so-called haystack `Hello, World!`
    - `tfx` would successfully find `the-file.txt` since all the characters are contained and appear in the right order
    - `xft` would not find `the-file.txt` since there's no `f` after the `x` meaning not all the characters are contained in the right order
    - If you're using path-matching instead of just filename-matching, you can type out parts of the path and the filename to get ***potentially*** better results.
        - For example, your input is `picfam01png`
        - This would likely find
            1. Pictures
            1. Family Photos
            1. Photo-01.png
        - If you're using the `ignorewhitespace` config you can also use an input like this `pic fam 01 png`

- Suffix Matching
    - To suffix match, just suffix your input with `$`.
    - To search for all mp3 files in your file hierarchy, try this input `.mp3$`
    - Since all mp3 audio files end with an `.mp3` this input will find them all
    - Why is `$` the suffix of choice? Probably all [regex](https://en.wikipedia.org/wiki/Regular_expression) engines out there use it as their end-of-string character. this just makes it a little more familiar :)

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

- Toggle path matching: You can choose to
    - Only use each item's name: "config.json"
    - Use it's full path: "C:/Users/You/Pictures/Family-Photo.jpeg"

# Usage

- `LCtrl+LWin+L` Open the UI with explorer integration if enabled
- `LCtrl+LWin+K` Open the UI without explorer integration
- Clicking
    - `LButton` Copy filepath to system clipboard
    - `LCtrl+LButton` Open entry in Explorer. This can be toggled in the settings
    - `LAlt+LButton` Execute the command set in the config with `{}` being replaced with the file's path
- Vim-Mode
    - If you've enabled Vim-Mode, you can focus the list by pressing tab (assuming the input is currently focused.)
    - All your configured keybinds will now be applied.
- `Esc` Hide the UI

# Configuration

**All of this would not have been possible without GroggyOtter's JSON parsing library: `jsongo.ahk`.**

**Note: Some values contain a `{}`. This is a placeholder for a dynamically generated value. Do not remove it. Any text outside of it however can be changed.**

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
    - `editcmd` The command to be executed when opening a file from the UI's list via `LAlt+LButton` or `f` in Vim-Mode
- `native` How many items the list view can display at a time
    - `maxitemsforautoupdate` Same as above. This value overrides the one above if you're using `Spear-Native`
    - `autofreebuffer` Automatically free the buffer and release the memory
    - `autofreetimeout` The time (seconds) `Spear-Native` must be in idle (on user-interaction) to automatically free the buffers
- `vim`
    - `enabled` Enable vim keybinds when the list view is in focus. This will disable the "find item via pressing the first letter of its name" feature.
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

To change any of the config's values, just change them! The config files are located under `./config/`.

- Spear will try to decode two different files based on if they exist or not
    1. `config.json` Your config
    1. `config_default.json` Fallback default config
        - If the fallback config is loaded, you'll get a message telling you

If both the files don't exist, the process will exit with an error.

(Note: **There is no config-validation other than your config file must be syntactically correct json. If you mess with some values and it doesn't work that's on you**).

# Acknowledgements

- Spear's config system would not have been possible without [GroggyOtter's](https://github.com/GroggyOtter) amazing JSON library: [jsongo.ahk](https://github.com/GroggyOtter/jsongo_AHKv2)
- I also used another one of GroggyOtter's libraries during development: [Peep.ahk](https://github.com/GroggyOtter/PeepAHK)

Thank you for your dedication to the AHK-Community.

# Possible future additions

- An in-app config menu! (Needs some more GUI-redesigning)

# Thank you

Thank you for checking out my project, hope you like it!
