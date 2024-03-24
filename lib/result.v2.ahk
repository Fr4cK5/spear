/************************************************************************
 * @description Result type to represent either Ok or Error
 * @file result.v2.ahk
 * @author Yarrak Obama
 * @version 1.0.0
 * @license MIT
 ***********************************************************************/

class Result {

    m_Result := ""

    /**
     * DO NOT USE THE DEFAULT CONSTRUCTOR!
     * 
     * THIS EXPOSES THE RAW VALUE WHICH BREAKS THE PURPOSE OF THE `Result` TYPE!
     */
    __New(value) {
        this.m_Result := value
    }

    /**
     * Create a new Result container, containing your `Ok` value
     * @param value `Ok` value
     * @returns {result} `Result<Ok>`
     */
    static ofOk(value) {
        return Result(ResultVariantOk(value))
    }

    /**
     * Create a new Result container, containing your `Err` message / value
     * @param msg `Err` value
     * @returns {result} `Result<Err>`
     */
    static ofErr(msg) {
        return Result(ResultVariantErr(msg))
    }

    /**
     * @returns {any} The contained Ok value
     */
    ok() {
        if this.isErr() {
            throw Error("Expected value of Ok, but got value of type Err")
        }
        return this.m_Result.get()
    }

    /**
     * @returns {any} The contained error value
     */
    err() {
        if this.isOk() {
            throw Error("Expected value of Err, but got value of type Ok")
        }
        return this.m_Result.get()

    }

    /**
     * Get the value regardless of it's variant
     * @returns {any} Ok or Error
     */
    get() {
        return this.m_Result.get()
    }

    /**
     * @returns {number} whether the contained value is Ok
     */
    isOk() {
        return this.m_Result is ResultVariantOk
    }

    /**
     * @returns {number} whether the contained value is Error
     */
    isErr() {
        return this.m_Result is ResultVariantErr
    }

    /**
     * Recursively exapand known types such as `Option` and `Result` to display the final value.
     * @returns {String} 
     */
    toString() {
        if this.isOk() {
            value := this.ok()
            return "Result::Ok(" . (Result.isUnionType(value) ? value.toString() : String(value)) . ")"
        }
        else {
            return "Result::Err(" . this.err() . ")"
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
        if this.isOk() {
            value := this.ok()
            add_quotes := value is String
            inner_value := (Option.isUnionType(value) ? value.toStringPretty(base_indentation + indent_jump, indent_jump, indent_str, false) : String(value))
            if add_quotes {
                inner_value := "'" . inner_value . "'"
            }
            return Format(
                "{}Result::Err({}{}{}{}{})",
                first_call ? indent_current : "",
                "`n",
                indent_next,
                inner_value,
                "`n",
                indent_current
            )
        }
        else {
            value := this.err()
            add_quotes := value is String
            inner_value := (Option.isUnionType(value) ? value.toStringPretty(base_indentation + indent_jump, indent_jump, indent_str, false) : String(value))
            if add_quotes {
                inner_value := "'" . inner_value . "'"
            }
            return Format(
                "{}Result::Err({}{}{}{}{})",
                first_call ? indent_current : "",
                "`n",
                indent_next,
                inner_value,
                "`n",
                indent_current
            )
        }
    }

    static isUnionType(value) {
        if value is Option or value is Result {
            return true
        }
        return false
    }
}

/**
 * Result type, representing the error from a function's return
 */
class ResultVariantErr {

    m_Value := ""

    __New(value) {
        this.m_Value := value
    }

    get() {
        return this.m_Value
    }

}

/**
 * Result type, representing successful return from a function
 */
class ResultVariantOk {

    m_Value := ""

    __New(value) {
        this.m_Value := value
    }

    get() {
        return this.m_Value
    }
}