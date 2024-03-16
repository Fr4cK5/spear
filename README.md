# Spear
The only Fuzzy-File-Finder you'll need!

# Installation
```powershell
git clone https://github.com/Fr4cK5/spear
mkdir ~/.config -ErrorAction SilentlyContinue
mkdir ~/.config/spear -ErrorAction SilentlyContinue
Copy-Item ./spear/asset/config_default.json ~/.config/spear/config.json
Copy-Item ./spear/asset/config_default.json ~/.config/spear/config_default.json
```

# Features

- Fuzzy Matching
    - Fuzzy matching doesn't look for the exact input, but just for the containment of every character in the right order.
    - Say you're searching for a `.png` image file.
    - An input of `.pg` would match `.png` because the input's characters are in the right order and all contained in the haystack `.png`
    - `tfx` would successfully find `the-file.txt` since all the characters are contained and appear in the right order
    - `xft` would not be found since the there's no `f` after the `x` meaning not all the characters are contained. `t` isn't even addressed within the algorithm

- Suffix Matching
    - To suffix match, just suffix your input with `$`
    - To search for all mp3 files in your file hierarchy, try this input `.mp3$`
    - Since all mp3 audio files end with an `.mp3`, this input will find them all

- Containment Matching
    - To contain-match, just suffix your input with `?`
    - You might have some file who's name you just barely remember, right?
    - Assuming the file is called `some-file.txt` any of the following inputs would find it.
        - `some-file.txt?`
        - `some?`
        - `file?`
        - `me-fi?`
        - `le.t?`

# Usage

- `LCtrl+LWin+L` Open the UI
- Clicking
    - `LButton` Copy filepath to system clipboard
    - `LCtrl+LButton` Open entry in Explorer. This can be toggled in the settings
    - `LAlt+LButton` Execute the command set in the config with `{}` being replaced with the file's path
- `Esc` Hide the UI

# Settings

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

