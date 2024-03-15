#Requires AutoHotkey 2.0+
#SingleInstance Force

#Include Spear-FAL.ahk
#Include logger.v2.ahk
#Include timer.v2.ahk

Esc::ExitApp()

lg := Logger(, true)

t_full := Timer()
t := Timer()

t_full.start()
t.start()

lib := FAL()

setup := t.ms()
t.start()

lib.set_user_input("300k?")

set_user := t.ms()
t.start()

lib.ffi_walk("C:/.dev")

walk := t.ms()
t.start()

lib.ffi_filter()

filter := t.ms()
total := t_full.ms()

found := lib.found_files
matching := lib.matching_files

lg.dbg(Format("Found: {}; Matching: {}", found, matching))
lg.dbg(Format("Setup: {}ms, Set user-input: {}ms", setup, set_user))
lg.dbg(Format("Walk: {}ms, Filter: {}ms", walk, filter))
lg.dbg(Format("Total: {}ms", total))
lg.dbg(Format("Memory Usage: {}MiB", lib.total_memory_usage_mib()))