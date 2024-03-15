/************************************************************************
 * @description A Timer for all my fellow clockwatchers out there!
 * @file timer.v2.ahk
 * @author Yarrak Obama
 * @version 1.0.0
 * @license MIT
 ***********************************************************************/

class Timer {
    #Requires AutoHotkey 2.0.2+

    m_time := 0

    /**
     * Start or restart the timer
     */
    start() {
        this.m_time := A_TickCount
    }

    /**
     * Get the elapsed milliseconds since `start()` was called.
     * @returns {number} elapsed time in milliseconds
     */
    getMillis() {
        return A_TickCount - this.m_time
    }

    /**
     * Alias for `getMillis()`;
     * 
     * Get the elapsed milliseconds since `start()` was called.
     * @returns {number} elapsed time in milliseconds
     */
    ms() => this.getMillis()

    /**
     * Get the elapsed seconds since `start()` was called.
     * @returns {number} elapsed time in seconds
     */
    getSecs() => this.getMillis() / 1000

    /**
     * Get the elapsed minutes since `start()` was called.
     * @returns {number} elapsed time in minutes
     */
    getMins() => this.getMillis() / 1000 / 60

    /**
     * Get the elapsed hours since `start()` was called.
     * @returns {number} elapsed time in hours
     */
    getHours() => this.getMillis() / 1000 / (60 * 60)

    /**
     * Get the elapsed days since `start()` was called.
     * @returns {number} elapsed time in days
     */
    getDays() => this.getMillis() / 1000 / (60 * 60) / 24

    /**
     * Get the elapsed weeks since `start()` was called.
     * @returns {number} elapsed time in weeks
     */
    getWeeks() => this.getMillis() / 1000 / (60 * 60) / 24 / 7

    /**
     * Get the more detail about the so-far elapsed time.
     * @param n the place to round the time unit to
     * @return {string} formatted time.
     */
    detail(n := 2) {

        ms := this.ms()

        ; Me: Let's just pretend you didn't see that, okay?
        ; You: no..
        ; Me: pulls out Barrett .50 cal
        ; You: Sure! ¯\_(ツ)_/¯
        ; Me: Good! :D
        if (time := this.getWeeks()) >= 1 {
            time_rounded := Round(time, n)
            return {
                unit: "week",
                rounded: time_rounded,
                measured: time,
                str: time_rounded . "w",
                millis: ms
            }
        }

        if (time := this.getDays()) >= 1 {
            time_rounded := Round(time, n)
            return {
                unit: "day",
                rounded: time_rounded,
                measured: time,
                str: time_rounded . "d",
                millis: ms
            }
        }

        if (time := this.getHours()) >= 1 {
            time_rounded := Round(time, n)
            return {
                unit: "hour",
                rounded: time_rounded,
                measured: time,
                str: time_rounded . "h",
                millis: ms
            }
        }

        if (time := this.getMins()) >= 1 {
            time_rounded := Round(time, n)
            return {
                unit: "minute",
                rounded: time_rounded,
                measured: time,
                str: time_rounded . "m",
                millis: ms
            }
        }

        if (time := this.getSecs()) >= 1 {
            time_rounded := Round(time, n)
            return {
                unit: "second",
                rounded: time_rounded,
                measured: time,
                str: time_rounded . "s",
                millis: ms
            }
        }

        time := this.ms()
        time_rounded := Round(time, n)
        return {
            unit: "millisecond",
            rounded: time_rounded,
            measured: time,
            str: time_rounded . "ms",
            millis: ms
        }
    }

    /**
     * Allows you to measure the performance of a function `operation`
     * @param operation the function to be measure
     * @param args the args to be passed to the function (can be omitted)
     * @returns {array} [your function's return value, measured time in milliseconds]
     */
    static Measure(operation, args*) {
        t := Timer()
        t.start()
        value := operation(args*)
        return {
            ret: value,
            time: t.getMillis()
        }
    }
}