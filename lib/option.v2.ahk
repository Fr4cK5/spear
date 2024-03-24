/************************************************************************
 * @description An Option type that represents either some value or nothing at all.
 * @file option.v2.ahk
 * @author Yarrak Obama
 * @version 1.0.0
 * @license MIT
 ***********************************************************************/

Class Option {

    m_Option := ""

    /**
     * DO NOT USE THE DEFAULT CONSTRUCTOR!
     *
     * THIS EXPOSES THE RAW VALUE WHICH BREAKS THE PURPOSE OF THE `Option` TYPE!
     */
    __New(value) {
        this.m_Option := value
    }

    /**
     * Create an `Option` with a guaranteed valid value.
     * @param value value to be wrapped in `Option<Some>`
     * @returns {option} `Option<Some>`
     */
    static of(value) {
        return Option(Some(value))
    }

    /**
     * Create an `Option` of an inexistant value.
     * Often used to indicate no return value.
     * @returns {option} `Option<None>`
     */
    static none() {
        return Option(None())
    }

    unwrap(default?) {
        if this.m_Option is Some {
            return this.m_Option.get()
        }
        
        if IsSet(default) {
            return default
        }

        throw Error("Tried to unwrap content of None value")
    }

    isSome() {
        return this.m_Option is Some
    }

    isNone() {
        return this.m_Option is None
    }

    /**
     * Recursively exapand known types such as `Option` and `Result` to display the final value.
     * @returns {String} 
     */
    toString() {
        if this.isSome() {
            value := this.unwrap()
            return "Option::Some(" . (Option.isUnionType(value) ? value.toString() : String(value)) . ")"
        }
        else {
            return "Option::None"
        }
    }

    /**
     * Recursively exapand known types such as `Option` and `Result` to display the final value with indentation.
     * @param {Integer} base_indentation prefix spacing
     * @param {Integer} indent_jump how much to indent by every level
     * @param {String} indent_str the char to use for indentation
     * @returns {String} 
     */
    toStringPretty(base_indentation := 0, indent_jump := 4, indent_str := " ", first_call := true) {
        if this.isSome() {
            value := this.unwrap()
            add_quotes := value is String
            inner_value := (Option.isUnionType(value) ? value.toStringPretty(base_indentation + indent_jump, indent_jump, indent_str, false) : String(value))
            if add_quotes {
                inner_value := "'" . inner_value . "'"
            }
            indent_current := ""
            i := 0
            while i < base_indentation {
                indent_current .= indent_str
                i++
            }
            
            indent_next := ""
            i := 0
            while i < base_indentation + indent_jump {
                indent_next .= indent_str
                i++
            }
            return Format(
                "{}Option::Some({}{}{}{}{})",
                first_call ? indent_current : "",
                "`n",
                indent_next,
                inner_value,
                "`n",
                indent_current
            )
        }
        else {
            return "Option::None"
        }
    }

    static isUnionType(value) {
        if value is Option or value is Result {
            return true
        }
        return false
    }
}

; These classes are not inteded for use outside of an Optional
Class None {
}
Class Some {

    m_Value := ""

    __New(value) {
        this.m_Value := value
    }

    get() {
        return this.m_Value
    }
}