/************************************************************************
 * @description A two component Vector.
 * @file v4d.v2.ahk
 * @author Yarrak Obama
 * @version 1.0.0
 * @license MIT
 ***********************************************************************/

class Vector2 {
    #Requires AutoHotkey 2.0.2+

    static PI := 3.141592653589793

    x := 0
    y := 0

    __New(x, y) {
        this.x := x
        this.y := y
    }

    static fromCursorPos() {
        MouseGetPos(&x, &y)
        return Vector2(x, y)
    }

    add(x, y) {
        return Vector2(
            this.x + x,
            this.y + y
        )
    }

    sub(x, y) {
        return Vector2(
            this.x - x,
            this.y - y
        )
    }

    mul(x, y) {
        return Vector2(
            this.x * x,
            this.y * y
        )
    }

    mulScale(n) {
        return Vector2(
            this.x * n,
            this.y * n
        )
    }

    div(x, y) {
        return Vector2(
            this.x / x,
            this.y / y
        )
    }

    divScale(n) {
        return Vector2(
            this.x / n,
            this.y / n
        )
    }

    dist(other) {
        diff_x := Abs(this.x - other.x)
        diff_y := Abs(this.y - other.y)
        return Sqrt(diff_x * diff_x + diff_y * diff_y)
    }

    to(other) {
        ; LO-OL
        ; Local to Other -> Other to local
        ; I want a vec from local to other
        ; So I must use other - local

        diff_x := other.x - this.x
        diff_y := other.y - this.y
        return Vector2(
            diff_x,
            diff_y
        )
    }

    angleTo(other) {
        diff := this.to(other)
        diff_len := diff.len()

        if diff_len == 0 {
            return 0
        }

        angle := ACos(diff.x / diff_len)

        if diff.y > 0 {
            angle := 2 * Vector2.PI - angle
            
        }

        return angle
    }

    len() {
        return Sqrt(this.x * this.x + this.y * this.y)
    }

    norm() {
        l := this.len()
        return Vector2(
            this.x / l,
            this.y / l,
        )
    }
}