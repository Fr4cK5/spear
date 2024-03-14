#Requires AutoHotkey 2.0+
#SingleInstance Force

#Include Spear-FAL.ahk
#Include logger.v2.ahk

Esc::ExitApp()

lg := Logger(, true)

lib := FAL()

lib.set_user_input("300k?")

lib.ffi_walk("C:/.dev")
lib.ffi_filter()
lib.filtered_buffer_to_vec().len()