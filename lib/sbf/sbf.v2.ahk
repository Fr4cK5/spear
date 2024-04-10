/************************************************************************
 * @description A Simple Binary Format implementation for AHK
 * @file sbf.v2.ahk
 * @author Yarrak Obama
 * @version 1.0
 ***********************************************************************/

#Include sbf-shared.v2.ahk

class SBFEncoder {
    #Requires AutoHotkey 2.0+

    buf := 0
    write_head := 0
    utils := 0

    __New(size := 1024 * 64) {
        this.buf := Buffer(size)
        this.write_head := this.buf.ptr
        this.utils := SBFCoder()
    }

    to_file(filename) {
        f := FileOpen(filename, "w")
        f.RawWrite(this.buf, this.bytes_written())
        f.Close()
    }

    write(obj) {
        head_ptr := this.write_head
        this.utils.encode(obj, &head_ptr)
        this.write_head := head_ptr
    }

    bytes_written() {
        return this.write_head - this.buf.ptr
    }
}

class SBFDecoder {
    static FileToBuffer(filename, buffer_size := 1024 * 64) {
        buf := FileRead(filename, "raw")
        buf.Size := buffer_size
        return buf
    }

    static BufferToObj(buf) {
        ptr := buf.ptr
        return obj := SBFCoder().decode(&ptr)
    }

    static FileToObject(filename, buffer_size := 1024 * 64) {
        buf := FileRead(filename, "raw")
        ptr := buf.ptr
        obj := SBFCoder().decode(&ptr)
        return obj
    }
}