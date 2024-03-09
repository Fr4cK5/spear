/************************************************************************
 * @description String utility class
 * @file str.v2.ahk
 * @author Yarrak Obama
 * @version 1.1.0
 * @license MIT
 ***********************************************************************/

#Include result.v2.ahk
#Include option.v2.ahk

class Str {
    #Requires AutoHotkey v2.0.2+

    /**
     * Check if `idx` is within the bounds of `s`
     * @param s the string
     * @param idx the index
     * @returns {Bool} `true` if ok, `false` otherwise
     */
    static check_bounds(s, idx) {
        len := StrLen(s)
        return idx >= 1 and idx <= len
    }

    /**
     * Check if `long` is longer or equal to `short`
     * @param long long string
     * @param short short string
     * @returns {Bool} `true` if `long` is longer than or equal to `short`, `false` otherwise
     */
    static check_len_inc(long, short) {
        return StrLen(long) >= StrLen(short)
    }

    /**
     * Get the char at a specific index in `s`
     * @param s the string
     * @param index the index
     * @returns {Option<String>}
     */
    static char(s, idx) {
        if !this.check_bounds(s, idx) {
            return Option.none()
        }

        return Option.of(SubStr(s, idx, 1))
    }

    /**
     * Get the char at a specific index in `s`. Only use this in istuations where you know you won't be going out of bounds.
     * eg. parsing a string in a loop
     * @param s the string
     * @param index the index
     * @returns {Option<String>}
     */
    static charUnsafe(s, idx) {
        return SubStr(s, idx, 1)
    }

    /**
     * Check whether the strings are equal. In comparison to `StrCompare`, this actually works!
     * @param s1 the first string
     * @param s2 the second string
     * @returns {Bool} 
     */
    static equal(s1, s2) {
        if StrLen(s1) != StrLen(s2) {
            return false
        }

        i := 1
        len := StrLen(s1)
        while i <= len {
            one := this.char(s1, i).unwrap()
            two := this.char(s2, i).unwrap()
            if one !== two {
                return false
            }
            i++
        }

        return true
    }

    /**
     * Get the first index of `c` in `s`, starting from the left
     * @param s the string
     * @param c the char
     * @returns {Option<Number>} 
     */
    static indexChar(s, c) {
        i := 1
        len := StrLen(s)
        while i <= len {
            current := this.char(s, i).unwrap()
            if current == c {
                return Option.of(i)
            }
            i++
        }

        return Option.none()
    }

    /**
     * Get the last index of `c` in `s`, starting from the left
     * @param s the string
     * @param c the char
     * @returns {Option<Number>} 
     */
    static lastIndexChar(s, c) {
        i := StrLen(s)
        while i >= 1 {
            current := this.char(s, i).unwrap()
            if current == c {
                return Option.of(i)
            }
            i--
        }
        return Option.none()
    }

    /**
     * Get the first index of `c` in `s`, starting from the right
     * @param s the string
     * @param c the char
     * @returns {Option<Number>} 
     */
    static indexRight(s, c) {
        i := StrLen(s)
        while i >= 1 {
            current := this.char(s, i).unwrap()
            if current == c {
                return Option.of(StrLen(s) - i + 1)
            }
            i--
        }
        return Option.none()
    }

    /**
     * Repeat the string `s`, `n` times
     * @param s the string
     * @param n number of times to repeat
     * @returns {Option<String>}
     */
    static repeat(s, n) {
        if n <= 0 {
            return Option.none()
        }
        if n == 1 {
            return Option.of(s)
        }

        base := s

        i := 0
        while i < n - 1 {
            base .= s
            i++
        }

        return Option.of(base)
    }

    /**
     * Get a subsequence from `s` that ranges from `start` up to but not including `end`
     * @param s the string
     * @param start start index, inclusive
     * @param end end index, exclusive (like it should be)
     * @returns {Option<String>}
     */
    static sub(s, start := 1, end := StrLen(s) + 1) {
        if start > end {
            return Option.none()
        }
        if !this.check_bounds(s, start) or !this.check_bounds(s, end - 1) {
            return Option.none()
        }

        return Option.of(SubStr(s, start, end - start))
    }


    /**
     * Limit the string's length from the left
     * @param s the string
     * @param len the length
     * @returns {Option<String>}
     */
    static left(s, len) {
        return this.sub(s, 1, len + 1)
    }

    /**
     * Limit the string's length from the right
     * @param s the string
     * @param len the length
     * @returns {Option<String>}
     */
    static right(s, len) {
        return this.sub(s, StrLen(s) - len + 1)
    }

    /**
     * Check if `s` starts with sub-sequence `seq`
     * @param s the string
     * @param seq the sequence
     * @returns {Bool}
     */
    static startsWith(s, seq) {
        if !this.check_len_inc(s, seq) {
            return false
        }

        len := StrLen(seq)
        i := 1
        while i <= len {
            s_char := this.char(s, i).unwrap()
            seq_char := this.char(seq, i).unwrap()

            ; The !== Operator was specifically added to be able to do case-sensitive comps
            ; The normal != is always case-insensitive *facepalm*
            ; -5 minutes :(
            if s_char !== seq_char {
                return false
            }
            i++
        }

        return true
    }

    /**
     * Check if `s` ends with sub-sequence `seq`
     * @param s the string
     * @param seq the sequence
     * @returns {Bool}
     */
    static endsWith(s, seq) {
        if !this.check_len_inc(s, seq) {
            return false
        }

        i := StrLen(seq)
        while i >= 1 {
            s_char := this.char(s, StrLen(s) - i + 1).unwrap()
            seq_char := this.char(seq, StrLen(seq) - i + 1).unwrap()
            if s_char !== seq_char {
                return false
            }
            i--
        }

        return true
    }

    /**
     * Synonymous with `startsWith`; Check if `s` starts with sub-sequence `seq`
     * @param s the string
     * @param seq the sequence
     * @returns {Bool}
     */
    static hasPrefix(s, seq) {
        return this.startsWith(s, seq)
    }

    /**
     * Synonymous with `endsWith`; Check if `s` ends with sub-sequence `seq`
     * @param s the string
     * @param seq the sequence
     * @returns {Bool}
     */
    static hasSuffix(s, seq) {
        return this.endsWith(s, seq)
    }

    /**
     * Check if `s` contains `seq`
     * @param s the string
     * @param seq the sequence
     * @returns {Bool}
     */
    static contains(s, seq) {
        return InStr(s, seq, true)
    }

    /**
     * Check if `s` contains `seq` without looking at the string's cases.
     * @param s the string
     * @param seq the sequence
     * @returns {Bool}
     */
    static containsIgnoreCase(s, seq) {
        return InStr(s, seq)
    }

    /**
     * Check if `s` contains any element of `sub_list`
     * @param s the string
     * @param sub_list list of strings
     * @returns {Bool}
     */
    static containsAny(s, sub_list*) {
        for sub in sub_list {
            if InStr(s, sub, true)
                return true
        }

        return false
    }

    /**
     * Check if `s` contains all elements of `sub_list`
     * @param s the string
     * @param sub_list list of strings
     * @returns {Bool}
     */
    static containsAll(s, sub_list*) {
        for sub in sub_list {
            if InStr(s, sub, true) {
                continue
            }
            else {
                return false
            }
        }

        return true
    }

    /**
     * Check if `s` equals any element of `targets`
     * @param s the string
     * @param targets list of strings
     * @returns {Bool}
     */
    static equalsAny(s, targets*) {
        for t in targets {
            if this.equal(s, t) {
                return true
            }
        }

        return false
    }

    /**
     * Get the first char of string `s`
     * @param s the string
     * @returns {Option<String>} 
     */
    static first(s) {
        len := StrLen(s)
        if len <= 0 {
            return Option.none()
        }
        return Option.of(this.char(s, 1).unwrap())
    }
    
    /**
     * Get the last char of string `s`
     * @param s the string
     * @returns {Option<String>} 
     */
    static last(s) {
        len := StrLen(s)
        if len <= 0 {
            return Option.none()
        }
        return Option.of(this.char(s, StrLen(s)).unwrap())
    }
    
    /**
     * Join all the strings `strs` together with a separator `sep`
     * @param sep the separator
     * @param strs strings
     * @returns {String} 
     */
    static join(sep, strs*) {
        base := ""
        for idx, s in strs {
            base .= s
            if idx != strs.Length {
                base .= sep
            }
        }

        return base
    }

    /**
     * Replace `s`'s first occurrence of `old` with `new`
     * @param str the string
     * @param old the sequence to be replaced
     * @param new the new sequence to be written
     * @returns {String} 
     */
    static replaceOne(str, old, new) {
        return StrReplace(str, old, new, , , 1)
    }

    /**
     * Replace `s`'s first `n` occurrences of `old` with `new`
     * @param str the string
     * @param old the sequence to be replaced
     * @param new the new sequence to be written
     * @param n the amount of replacements
     * @returns {String} 
     */
    static replaceN(str, old, new, n) {
        return StrReplace(str, old, new, , , n)
    }

    /**
     * Replace all occurrence of `old` with `new` in `s`
     * @param str the string
     * @param old the sequence to be replaced
     * @param new the new sequence to be written
     * @returns {String} 
     */
    static replaceAll(str, old, new) {
        return StrReplace(str, old, new)
    }
}