/************************************************************************
 * @description Your average PC's viewport
 * @file viewport.v2.ahk
 * @author Yarrak Obama
 * @version 0.1.0
 * @license MIT
 * 
 * @depends v2d.v2.ahk
 ***********************************************************************/

#Include v2d.v2.ahk

class Viewport {

    ; Deal with it!
    m_TaskBarHeight := A_ScreenHeight / 1080 * 40

    minX() => 0
    minY() => 0

    maxX() => A_ScreenWidth - 1
    maxY() => A_ScreenHeight - this.m_TaskBarHeight - 1

    width() => A_ScreenWidth
    height() => A_ScreenHeight - this.m_TaskBarHeight

    halfX() => A_ScreenWidth / 2
    halfY() => A_ScreenHeight / 2 - this.m_TaskBarHeight / 2

    center() {
        return Vector2(
            this.halfX(),
            this.halfY()
        )
    }
}