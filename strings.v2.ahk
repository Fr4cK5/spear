/************************************************************************
 * @description String utility class
 * @file strings.v2.ahk
 * @author Yarrak Obama
 * @version 1.1.0
 * @license MIT
 ***********************************************************************/

class Strings {
    #Requires AutoHotkey v2.0.2+

    static char(str, index) {
        return SubStr(str, index, 1)
    }

    static index(str, target) {
        if StrLen(target) != 1
            return -1

        i := 1
        while this.char(str, i) != target
            i++

        return i
    }

    static lastIndex(str, target) {
        if StrLen(target) != 1
            return -1

        i := StrLen(str)
        while this.char(str, i) != target
            i--

        return i
    }

    static expand(str, count) {
        value := ""
        i := 0
        while i < count {
            value .= str
            i++ ; Cost me 1.5h of debugging -_-
        }
        return value
    }

    static endsWith(str, sub) {
        offset := StrLen(str) - StrLen(sub)
        i := 1
        while i < StrLen(str) {
            if this.char(str, offset + i) != this.char(sub, i)
                return false

            i++
        }

        return true
    }

    static endsWithAny(str, sub_list) {
        for sub in sub_list {
            if this.endsWith(str, sub)
                return true
        }

        return false
    }

    static startsWith(str, sub) {
        i := 1
        if StrLen(sub) > StrLen(str)
            return false

        while i <= StrLen(sub) {
            if this.char(str, i) != this.char(sub, i)
                return false

            i++
        }

        return true
    }

    static startsWithAny(str, sub_list) {
        for sub in sub_list {
            if this.startsWith(str, sub)
                return true
        }

        return false
    }

    static contains(str, target, occurences := 1, caseSense := false, startingPos := 1) {
        return InStr(str, target, caseSense, startingPos, occurences)
    }

    static containsAny(str, sub_list*) {
        for sub in sub_list {
            if InStr(str, sub)
                return true
        }

        return false
    }

    static containsAll(str, sub_list*) {
        for sub in sub_list {
            if InStr(str, sub)
                continue
            else
                return false
        }

        return true
    }

    static equalsAny(str, targets*) {
        for t in targets {
            if str == t {
                return true
            }
        }

        return false
    }

    static sub(str, start, end?) {
        end_internal := !IsSet(end) ? StrLen(str) + 1 : end
        return SubStr(str, start, end_internal - start)
    }

    static splitAround(str, target) {
        if !InStr(str, target)
            return -1

        target_index := this.index(str, target)
        one := this.sub(str, 1, target_index)
        two := target
        three := this.sub(str, target_index + 1)
        return [one, two, three]
    }

    static splitAroundAny(str, targets) {
        for t in targets {
            result := this.splitAround(str, t)
            if result != -1 and result.Length == 3
                return result
        }

        return 0
    }

    static first(str) {
        return str[1]
    }

    static last(str) {
        return Strings.Char(str, StrLen(str))
    }

    static join(sep, strs*) {
        value := ""
        for i, str in strs {
            value .= str . sep
        }

        return Strings.sub(value, 1, StrLen(value) - StrLen(sep) + 1)
    }

    static removeAll(str, targets) {
        return Strings.join(StrSplit(str, targets), "")
    }

    static replace(str, sub, new_text) {
        return StrReplace(str, sub, new_text, , , 1)
    }
    static replaceAll(str, sub, new_text) {
        return StrReplace(str, sub, new_text)
    }
}