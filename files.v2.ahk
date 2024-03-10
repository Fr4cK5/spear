
class Files {
    #Requires AutoHotkey 2.0.2+

    static readonly(mode) {
        return InStr(mode, "R")
    }

    static file(mode) {
        return InStr(mode, "A")
    }

    static system(mode) {
        return InStr(mode, "S")
    }

    static hidden(mode) {
        return InStr(mode, "H")
    }

    static normal(mode) {
        return InStr(mode, "N")
    }

    static directory(mode) {
        return InStr(mode, "D")
    }

    static offline(mode) {
        return InStr(mode, "O")
    }
    
    static compressed(mode) {
        return InStr(mode, "C")
    }

    static temp(mode) {
        return InStr(mode, "T")
    }

    static link(mode) {
        return InStr(mode, "L")
    }

}