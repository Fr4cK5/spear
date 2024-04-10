class SBFConstants {
    static idof_int := 0
    static idof_float := 1
    static idof_bool := 2
    static idof_string := 3
    static idof_array := 4
    static idof_object := 5

    static sizeof_id := 1
    static sizeof_string_encoding := 1
    static sizeof_length := 8
    static sizeof_int_float := 8
    static sizeof_bool := 1
    static sizeof_type_field_count := 2

    static typeof_id := "uchar"
    static typeof_int := "int64"
    static typeof_float := "double"
    static typeof_string_encoding := "uchar"
    static typeof_length := "uint64"
    static typeof_type_field_count := "uint16"
    static typeof_bool := "uchar"

    static string_encoding_utf_16 := 0
    static string_encoding_utf_8 := 1
    static string_encoding_utf_cp0 := 2
    static string_encoding_utf_cp936 := 3

    static EncodingToConstant(enc) {
        switch enc, false {
        case "UTF-16":
            return SBFConstants.string_encoding_utf_16
        case "UTF-8":
            return SBFConstants.string_encoding_utf_8
        case 0:
            return SBFConstants.string_encoding_utf_cp0
        case "CP0":
            return SBFConstants.string_encoding_utf_cp0
        case "CP936":
            return SBFConstants.string_encoding_utf_cp936
        case 936:
            return SBFConstants.string_encoding_utf_cp936
            
        default:
            throw Error("Tried to convert unrecognized string encoding: " enc)
        }

    }

    static EncodingFromConstant(const) {
        switch const {
        case SBFConstants.string_encoding_utf_16:
            return "UTF-16"
        case SBFConstants.string_encoding_utf_8:
            return "UTF-8"
        case SBFConstants.string_encoding_utf_cp0:
            return "CP0"
        case SBFConstants.string_encoding_utf_cp936:
            return "CP936"
        
        default:
            throw Error("Tried to parse unrecognized string encoding constnat: " const)
        }
    }

}

/**
 * The encode functions always encode the type-id, some optional metadata, and the actual data.
 * 
 * The decode functions don't start by parsing the id, but rather by parsing the optional metadata.
 * This means that any decode function needs a pointer to the start of the actual data, not the type-id.
 */
class SBFCoder {

    known_items := 0

    __New() {
        this.known_items := Map()
    }

    decode_id(&ptr) {
        value := NumGet(ptr, 0, SBFConstants.typeof_id)
        ptr += SBFConstants.sizeof_id
        return value
    }

    encode_int(value, &ptr) {
        orig := ptr
        NumPut(SBFConstants.typeof_id, SBFConstants.idof_int, ptr)
        ptr += SBFConstants.sizeof_id
        NumPut(SBFConstants.typeof_int, value, ptr)
        ptr += SBFConstants.sizeof_int_float
        return ptr - orig
    }

    decode_int(&ptr) {
        value := NumGet(ptr, 0, SBFConstants.typeof_int)
        ptr += SBFConstants.sizeof_int_float
        return value
    }

    encode_float(value, &ptr) {
        orig := ptr
        NumPut(SBFConstants.typeof_id, SBFConstants.idof_float, ptr)
        ptr += SBFConstants.sizeof_id
        NumPut(SBFConstants.typeof_float, value, ptr)
        ptr += SBFConstants.sizeof_int_float
        return ptr - orig
    }

    decode_float(&ptr) {
        value := NumGet(ptr, 0, SBFConstants.typeof_float)
        ptr += SBFConstants.sizeof_int_float
        return value
    }

    encode_string(s, &ptr, encoding := "UTF-16") {
        orig := ptr

        ; Id
        NumPut(SBFConstants.typeof_id, SBFConstants.idof_string, ptr)
        ptr += SBFConstants.sizeof_id

        ; String length
        len := StrLen(s)
        NumPut(SBFConstants.typeof_length, len, ptr)
        ptr += SBFConstants.sizeof_length

        ; Encoding
        NumPut(SBFConstants.typeof_string_encoding, SBFConstants.EncodingToConstant(encoding), ptr)
        ptr += SBFConstants.sizeof_string_encoding

        ; Data
        StrPut(s, ptr, len, encoding)
        len *= this.size_of_string_encoding(encoding)
        ptr += len

        return ptr - orig
    }

    decode_string(&ptr) {
        ; String length
        len := NumGet(ptr, 0, SBFConstants.typeof_length)
        ptr += SBFConstants.sizeof_length

        ; Encoding
        encoding := SBFConstants.EncodingFromConstant(NumGet(ptr, 0, SBFConstants.typeof_string_encoding))
        ptr += SBFConstants.sizeof_string_encoding

        ; String
        s := StrGet(ptr, len, encoding)
        ptr += len * this.size_of_string_encoding(encoding)

        return s
    }

    encode_primitive(prim, &ptr) {
        orig := ptr

        switch Type(prim), false {
        case "Integer":
            this.encode_int(prim, &ptr)
        case "Float":
            this.encode_float(prim, &ptr)
        case "String":
            this.encode_string(prim, &ptr)

        default:
            throw Error("Tried to encode non-primtive as primitive: " Type(prim))
        }

        return ptr - orig
    }

    decode_primitive(&ptr) {
        switch this.decode_id(&ptr) {
        case SBFConstants.idof_int:
            return this.decode_int(&ptr)
        case SBFConstants.idof_float:
            return this.decode_float(&ptr)
        case SBFConstants.idof_string:
            return this.decode_string(&ptr)

        default:
            throw Error("Tried to decode non-primitive as primtive")
        }
    }

    encode_array(list, &ptr) {
        if this.known_items.Has(list) and this.known_items[list] >= 1 {
            return 0
        }

        if !(list is Array) {
            throw Error("Tried to encode non-array value as array.")
        }

        orig := ptr

        ; Type
        NumPut(SBFConstants.typeof_id, SBFConstants.idof_array, ptr)
        ptr += SBFConstants.sizeof_id

        ; Length
        NumPut(SBFConstants.typeof_length, list.Length, ptr)
        ptr += SBFConstants.sizeof_length

        ; encode!
        for i, item in list {
            if !this.known_items.Has(item) {
                this.known_items[item] := 0
            }
            else {
                this.known_items[item]++
            }

            this.encode(item, &ptr)
        }

        return ptr - orig
    }

    decode_array(&ptr) {

        ; Length
        len := NumGet(ptr, 0, SBFConstants.typeof_length)
        ptr += SBFConstants.sizeof_length

        ; decode!
        list := []
        i := 0
        while i < len {
            list.Push(this.decode(&ptr))
            i++
        }

        return list
    }

    encode_object(obj, &ptr) {
        if this.known_items.Has(obj) and this.known_items[obj] >= 1 {
            return 0
        }

        if this.is_primitive(obj) or obj is Array {
            throw Error("Tried to encode non-object value as object.")
        }

        orig := ptr

        ; Type
        NumPut(SBFConstants.typeof_id, SBFConstants.idof_object, ptr)
        ptr += SBFConstants.sizeof_id

        ; Size
        NumPut(SBFConstants.typeof_type_field_count, ObjOwnPropCount(obj), ptr)
        ptr += SBFConstants.sizeof_type_field_count

        for k, v in obj.OwnProps() {
            if !this.known_items.Has(v) {
                this.known_items[v] := 0
            }
            else {
                this.known_items[v]++
            }

            this.encode_string(k, &ptr)
            this.encode(v, &ptr) 
        }

        return ptr - orig
    }

    decode_object(&ptr) {

        ; Field-count
        fields := NumGet(ptr, 0, SBFConstants.typeof_type_field_count) & 0xffff
        ptr += SBFConstants.sizeof_type_field_count

        obj := Map()
        i := 0
        while i < fields {
            name_id := this.decode_id(&ptr)
            if name_id != SBFConstants.idof_string {
                throw Error("Object name / key is not of type string")
            }
            name := this.decode_string(&ptr)
            value := this.decode(&ptr)
            obj[name] := value
            i++
        }

        return obj
    }

    encode(some, &ptr) {
        orig := ptr

        if some is Array {
            this.encode_array(some, &ptr)
        }
        else if !this.is_primitive(some) {
            this.encode_object(some, &ptr)
        }
        else {
            this.encode_primitive(some, &ptr)
        }

        return ptr - orig
    }

    decode(&ptr) {
        id := this.decode_id(&ptr)

        if this.is_id_primitive(id) {
            ptr -= 1
            return this.decode_primitive(&ptr)
        }
        else if id == SBFConstants.idof_array {
            return this.decode_array(&ptr)
        }
        else if id == SBFConstants.idof_object {
            return this.decode_object(&ptr)
        }
        else {
            throw Error("Tried to decode unknown id: " id)
        }
    }

    is_id_primitive(id) {
        return id <= 3
    }

    is_primitive(item) {
        return item is String or item is Number
    }

    size_of_string_encoding(enc) {
        return enc == "UTF-16" ? 2 : 1
    }

}
