/************************************************************************
 * @description A Logger, That's it!
 *              Choose any of: Debug, Log, Warn, Error, Critical!
 * @file logger.v2.ahk
 * @author Yarrak Obama
 * @version 1.0.0
 * @license MIT
 ***********************************************************************/

class Logger {
    #Requires AutoHotkey 2.0.2+

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

    dbg(strs*) {
        for str in strs {
            this.m_WriteMessage("`n[DBG : " this.m_GetTime() "] " str)
        }
    }
    log(strs*) {
        for str in strs {
            this.m_WriteMessage("`n[LOG : " this.m_GetTime() "] " str)
        }
    }
    warn(strs*) {
        for str in strs {
            this.m_WriteMessage("`n[WARN: " this.m_GetTime() "] " str)
        }
    }
    err(strs*) {
        for str in strs {
            this.m_WriteMessage("`n[ERR : " this.m_GetTime() "] " str)
        }
    }
    crit(strs*) {
        for str in strs {
            this.m_WriteMessage("`n[CRIT: " this.m_GetTime() "] " str)
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
}