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
            throw Error(
                "Expected value of Ok, but got value of Err"
            )
        }
        return this.m_Result.get()
    }

    /**
     * @returns {any} The contained error value
     */
    err() {
        if this.isOk() {
            throw Error(
                "Expected value of Err, but got value of Ok"
            )
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