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
     * Create an `Option` with a guaranteed valid value
     * @param value value to be wrapped in `Option<Some>`
     * @returns {option} `Option<Some>`
     */
    static of(value) {
        return Option(Some(value))
    }

    /**
     * Create an `Option` of an invalid value to indicate no return value
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

        throw Error(
            "Tried to unwrap content of None value"
        )
    }

    isSome() {
        return this.m_Option is Some
    }

    isNone() {
        return this.m_Option is None
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