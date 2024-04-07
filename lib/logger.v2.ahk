/************************************************************************
 * @description A Logger, That's it!
 *              Choose any of: Debug, Log, Warn, Error, Critical!
 * @file logger.v2.ahk
 * @author Yarrak Obama
 * @version 1.0.0
 * @license MIT
 ***********************************************************************/

#Include option.v2.ahk
#Include result.v2.ahk

class Logger {
    #Requires AutoHotkey 2.0+

    m_Gui := 0
    m_TextField := 0
    m_CurrentlyVisible := false
    m_MessageBuffer := 0
    m_StopOnMouseHover := false

    __New(  name := A_ScriptName,
            showDebuggerOnConstruct := false,
            useDarkMode := true,
            stopOutputOnMouseHover := false,
            timeLoggingFormat := "HH:mm:ss",
            width := 512,
            height := 512

    ) {

        color_bg := ""
        color_text := ""
        if useDarkMode {
            color_bg := "1e1e1e"
            color_text := "White"
        }
        else {
            color_bg := "White"
            color_text := "Black"
        }

        this.m_Gui := Gui(, "Logging -> " name)
        this.m_Gui.BackColor := color_bg
        this.m_TextField := this.m_Gui.AddEdit("ReadOnly w" width " h" height " Background" color_bg)
        this.m_TextField.SetFont("S10 c" color_text, "Consolas")
        this.m_MessageBuffer := Array()
        this.m_StopOnMouseHover := stopOutputOnMouseHover

        this.m_CurrentlyVisible := showDebuggerOnConstruct
        if this.m_CurrentlyVisible
            this.show()

        this.m_TimeFormat := timeLoggingFormat
    }

    m_WriteMessage(str) {
        this.m_MessageBuffer.Push(str)

        ; If the gui's invalid, just return.
        if !this.m_Gui {
            return
        }

        ; To prevent scrolling while you might want to read something from the logs.
        if this.m_StopOnMouseHover {
            MouseGetPos(, , , &targetControl)
            if targetControl == "Edit1" {
                return
            }
        }

        for message in this.m_MessageBuffer {
            this.m_TextField.Value .= message
        }
        this.m_MessageBuffer := Array()

        ; Scroll to Bottom of Edit Control
        ; 0x115 = VM_VSCROLL
        ; 0x7 = SB_BOTTOM
        ; 0 = idk ask some win32 dev.
        ; this.m_TextField = Control
        SendMessage(0x115, 0x7, 0, this.m_TextField)
    }

    dbg(items*) {
        this.m_SanitizeUnionTypes(items, true)
        for str in items {
            this.m_WriteMessage("`n" str)
        }
    }
    log(items*) {
        this.m_SanitizeUnionTypes(items)
        for str in items {
            this.m_WriteMessage("`n[LOG: " this.m_GetTime() "] " str)
        }
    }
    warn(items*) {
        this.m_SanitizeUnionTypes(items)
        for str in items {
            this.m_WriteMessage("`n[WARN: " this.m_GetTime() "] " str)
        }
    }
    err(items*) {
        this.m_SanitizeUnionTypes(items)
        for str in items {
            this.m_WriteMessage("`n[ERR: " this.m_GetTime() "] " str)
        }
    }

    dbgf(fmt, args*) {
        this.m_SanitizeUnionTypes(args, true)
        this.dbg(Format(fmt, args*))
    }
    logf(fmt, args*) {
        this.m_SanitizeUnionTypes(args)
        this.log(Format(fmt, args*))
    }
    warnf(fmt, args*) {
        this.m_SanitizeUnionTypes(args)
        this.warn(Format(fmt, args*))
    }
    errf(fmt, args*) {
        this.m_SanitizeUnionTypes(args)
        this.err(Format(fmt, args*))
    }

    walk_obj(obj, depth := 0, hashes := Map()) {
        is_primitive(value) => value is String or value is Number

        indent := ""
        i := 0
        while i < depth * 4 {
            indent .= " "
            i++
        }

        ; If we only get a primitve as the first function call.
        ; We cannot get a primitive from a recursive call since that's handled further down the function.
        if is_primitive(obj) {
            this.dbgf(indent "{} [Primitive]", obj)
            return
        }

        ; Check arrays first since Array.OwnProps() doesnt return anything enumerable
        if obj is Array {
            for i, item in obj {
                if is_primitive(item) {
                    this.dbgf(indent "{} => {} [Primitive]", i, item, i)
                }
                else {
                    this.dbgf(indent "{} => [Object]", i)
                    this.walk_obj(item, depth + 1, hashes)
                }
            }
            return
        }

        ; Iterate over each prop / Key-Value pair
        it := obj is Map ? obj : obj.OwnProps()
        for k, v in it {

            ToolTip()
            ; Cyclic references
            if hashes.Has(v) {
                if is_primitive(k) {
                    this.dbgf(indent "{} => [Cyclic reference]", k)
                }
                continue
            }

            ; We just recurse since we check arrays first anyways.
            if v is Array {
                this.dbgf(indent "{} => [Array]", k)
                hashes[v] := 1
                this.walk_obj(v, depth + 1, hashes)
            }
            ; Objects
            else if !is_primitive(v) or v is Map {
                this.dbgf(indent "{} => [Object]", k)
                hashes[v] := 1
                this.walk_obj(v, depth + 1, hashes)
            }
            ; Primitives (String or Number)
            else {
                this.dbgf(indent "{} => {} [Primitive]", k, v)
            }
        }
    }

    show() {
        this.m_Gui.show()
        this.m_CurrentlyVisible := true
    }
    hide() {
        this.m_Gui.hide()
        this.m_CurrentlyVisible := false
    }
    destroy() {
        this.m_Gui.destroy()
        this.m_Gui := unset ; If the gui is destroyed, we can't output to it anymore so I'll unset it to make sure we don't accidentally try
    }

    setForceOnTop(b){
        if b 
            this.m_Gui.Opt("+AlwaysOnTop")
        else 
            this.m_Gui.Opt("-AlwaysOnTop")
    }

    setTitleRaw(str) {
        this.m_Gui.Title := str
    }

    setTitle(str) {
        this.m_Gui.Title := "Logging -> " str
    }
    
    toggleVisible() {
        if this.m_CurrentlyVisible {
            this.hide()
            this.m_CurrentlyVisible := false
        }
        else {
            this.show()
            this.m_CurrentlyVisible := true
        }
    }

    m_GetTime() {
        return FormatTime(, this.m_TimeFormat)
    }

    m_SanitizeUnionTypes(items, pretty_print := false) {
        i := 1
        while i <= items.Length {
            item := items[i]
            if item is Result or item is Option {
                if pretty_print {
                    items[i] := item.toStringPretty()
                }
                else {
                    items[i] := item.toString()
                }
            }
            i++
        }
    }
}