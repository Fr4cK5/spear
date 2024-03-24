/************************************************************************
 * @description Wrapper class of `Array` that adds support for iterator patterns.
 * @file vec.v2.ahk
 * @author Yarrak Obama
 * @version 1.1.1
 * @license MIT
 * 
 * @dependency option.v2.ahk
 * @dependency result.v2.ahk
 ***********************************************************************/

#Include option.v2.ahk
#Include result.v2.ahk

/**
 * A list of available functionality within vec.v2.ahk.
 * There's more documentation about any of the listed functions at their respective definitions.
 * 
 * @note Available static functions
 * @example
 * static Range(low, high)
 * static FromClone(array)
 * static FromShared(array)
 * static FromLength(base, len)
 * static FromRange(low, high)
 * static FromString(str)
 *
 * @note Available methods
 * @example
 * toString()
 * push(items*)
 * pop()
 * contains(item)
 * drop(index, len := 1) ; Same as removeAt
 * removeAt(index, len := 1) ; Same as drop
 * insert(index, items*)
 * len()
 * clear()
 * get(index)
 * set(index, item)
 * arr()
 * reserveAdditional(count)
 * reserve(count)
 * indexOf(target)
 * lastIndexOf(target)
 * indeciesOf(target)
 * indexOfCompare(comparator)
 * lastIndexOfCompare(comparator)
 * indeciesOfCompare(comparator)
 * find(comparator)
 * findLast(comparator)
 * foreach(operation)
 * filter(predicate)
 * retain(predicate)
 * map(operation)
 * remap(operation)
 * splitMapPreserveOrder(predicate, operationTrue, operationFalse)
 * splitMapPreserveOrderInPlace(predicate, operationTrue, operationFalse)
 * chain(other)
 * chainInPlace(other)
 * fold(default, operation)
 * join(delim)
 * take(base, len)
 * takeRange(low, high)
 * rev()
 * revInPlace()
 * limit(n)
 * limitInPlace(n)
 * windows(size, operation)
 * chunks(size)
 * rchunks(size)
 * any(predicate)
 * all(predicate)
 * shuffle()
 * sortInPlace(predicate)
 * sort(predicate)
 */
class Vec {
    #Requires AutoHotkey 2.0+

    IDX_OOB(idx, len := this.len()) => "Index " idx " out of bounds for length " len "."
    INVALID_VALUE(val, what := "this operation") => "Value " val " cannot be used for " what "."

    m_Data := Array()

    __New(initial_capacity := 20) {
        this.reserve(initial_capacity)
    }

    /**
     * Used to generate a range of numbers.
     * 
     * @example
     * for i in Vec.Range(0, 20) { ; 0 to 19
     *     ToolTip(i) ; 0, 1, 2, ... 18, 19
     *     Sleep(250)
     * }
     * 
     * @param low starting value, inclusive
     * @param high ending vlaue, exclusive
     * @returns {array} an array filled with numbers from low..high
     * @see FromRange To get a `Vec` object, use `FromRange` instead.
     */
    static Range(low, high) {
        range := high - low
        arr := Array()
        arr.Capacity := range
        i := 0
        while i < range {
            arr.Push(low + i)
            i++
        }
        return arr
    }

    /**
     * Construct a `Vec` from an existing `Array` object.
     *
     * @note The passed in array will be cloned. Changing it afterwards will NOT affect the `Vec` you're constructing.
     * 
     * @param array the array to clone to the `Vec`
     * @returns {vec} your array, but wrapped in a new and shiny sheet of abstraction! :D
     */
    static FromClone(array) {
        new := Vec(0)
        new.m_Data := array.Clone()
        return new
    }

    /**
     * Construct a `Vec` from an existing `Array` object.
     *
     * @note The passed in array will not be cloned. Changing it afterwards WILL affect the `Vec` you're constructing.
     * 
     * @param array the array to clone to the `Vec`
     * @returns {vec} your array, but wrapped in a new and shiny sheet of abstraction! :D
     */
    static FromShared(array) {
        new := Vec(0)
        new.m_Data := array
        return new
    }

    /**
     * Generate a new `Vec` filled with numbers.
     * 
     * @param base the starting value, inclusive
     * @param len the `Vec`'s length final length
     * @returns {vec} `Vec` object, filled with numbers starting from `base` and going for `len`
     */
    static FromLength(base, len) {
        arr := Array()
        arr.Capacity := len
        i := 0
        while i < len {
            arr.Push(base + i)
            i++
        }
        return Vec.FromShared(arr)
    }

    /**
     * Generate a new `Vec` filled with numbers
     * 
     * @param low from where to start going up to but not including `high`
     * @param high the value to go up to but not including
     * @returns {vec} a new `Vec` filled with numbers: `low..high`
     */
    static FromRange(low, high) {
        range := high - low
        arr := Array()
        arr.Capacity := range
        i := 0
        while i < range {
            arr.Push(low + i)
            i++
        }
        return Vec.FromShared(arr)
    }

    /**
     * Construct a `Vec` from a `String` object
     * 
     * @param str a string
     * @returns {vec} `Vec` containing the individual chars of `str`
     */
    static FromString(str) {
        arr := Array()
        i := 1
        while i <= StrLen(str) {
            arr.Push(SubStr(str, i, 1))
            i++
        }
        return Vec.FromShared(arr)
    }

    /**
     * Turn the `Vec`'s data into a `String`.
     * 
     * @returns {string} the string!
     * @note Will fail if any item of the `Vec` cannot be turned into a `String`
     */
    toString() {
        return this.fold("", (str, char) => str . char)
    }

    push(items*)              => this.m_Data.Push(items*)
    pop()                     => this.m_Data.Pop()
    contains(item)            => this.m_Data.Has(item)
    drop(index, len := 1)     => this.m_Data.RemoveAt(index, len)
    removeAt(index, len := 1) => this.m_Data.RemoveAt(index, len)
    insert(index, items*)     => this.m_Data.InsertAt(index, items*)
    len()                     => this.m_Data.Length
    clear()                   => this.m_Data := Array()

    /**
     * Retrieve an item from the collection
     * 
     * @param index the index to query
     * @returns {result} `Ok<any>` if the index is within bounds, `Err<string>` otherwise
     */
    get(index) {
        if index < 1 or index > this.len() {
            return Result.ofErr(this.IDX_OOB(index))
        }
        return Result.ofOk(this.m_Data.Get(index))
    }

    /**
     * Set the value of `index` to `item`
     * 
     * @param index the `index` to set `item` at
     * @param item the `item` to set at `index`
     * @returns {result} `Ok<true>` if `item` could be set at `index`, `Err<string>` otherwise
     */
    set(index, item) {
        if index < 1 or index > this.len() {
            return Result.ofErr(this.IDX_OOB(index))
        }
        this.m_Data[index] := item
        return Result.ofOk(true)
    }

    /**
     * Get a `copy` of the internal `Array`.
     * 
     * @returns {array} `copy` of the internal `Array`
     */
    arr() => this.m_Data.Clone()

    /**
     * Reserve additional space for more efficient usage of the `Vec` when you approximately know the size
     * 
     * @param count how much the `Vec` should grow
     * @returns {result} `Ok<true>` if count is valid, `Err<string>` otherwise
     */
    reserveAdditional(count) {
        if count < 1 {
            return Result.ofErr(this.INVALID_VALUE(count, "resizing"))
        }

        this.m_Data.Capacity += count
        return Result.ofOk(true)
    }

    /**
     * Reserve space for more efficient usage of the `Vec` when you approximately know the size
     * 
     * @param count how big the `Vec` should be
     * @returns {result} `Ok<true>` if count is valid, `Err<string>` otherwise
     */
    reserve(count) {
        if count <= this.m_Data.Length {
            return Result.ofErr(this.INVALID_VALUE(count, "resizing"))
        }

        this.m_Data.Capacity := count
        return Result.ofOk(true)
    }

    /**
     * Get the index of an item by searching for it
     * 
     * @param target item to find the index of
     * @returns {option} `Some<number>` if found, `None` otherwise
     */
    indexOf(target) {
        for i, item in this.m_Data {
            if target == item {
                return Option.of(i)
            }
        }

        return Option.none()
    }

    /**
     * Get the last index of an item by searching for it from the back
     * 
     * @param target item to find the index of
     * @returns {option} `Some<number>` if found, `None` otherwise
     */
    lastIndexOf(target) {
        i := this.len()
        while i >= 1 {
            if target == this.get(i).ok() {
                return Option.of(i)
            }

            i--
        }

        return Option.none()
    }

    /**
     * Get the indecies of all the items of this `Vec` which return `true` when compared with `target`
     * 
     * @param target target item
     * @returns {option} `Some<Vec<number>>` if any target was found, `None` otherwise
     */
    indeciesOf(target) {
        arr := Array()
        for i, item in this.m_Data {
            if item == target {
                arr.Push(i)
            }
        }

        return arr.Length == 0 ? Option.none() : Option.of(Vec.FromShared(arr))
    }

    /**
     * Get the index of an item in a collection by comparing every element against `comparator`.
     * This is useful for comparing more complex objects where you'd say they're equal despite them not having equal values for all their fields.
     * 
     * @param comparator `func(index, item) -> bool`
     * @returns {option} `Some<number>` if the target item was found, `None` otherwise
     */
    indexOfCompare(comparator) {
        for i, item in this.m_Data {
            if comparator(i, item) {
                return Option.of(i)
            }
        }

        return Option.none()
    }

    /**
     * Get the last index of an item in a collection by comparing every element against `comparator`.
     * This is useful for comparing more complex objects where you'd say they're equal despite them not having equal values for all their fields.
     * 
     * @param comparator `func(index, item) -> bool`
     * @returns {option} `Some<number>` if the target item was found, `None` otherwise
     */
    lastIndexOfCompare(comparator) {
        i := this.len()
        while i >= 1 {
            if comparator(i, this.get(i).ok()) {
                return Option.of(i)
            }

            i--
        }

        return Option.none()
    }

    /**
     * Get the indecies of all the items of this `Vec` which return `true` when compared against `comparator`
     * 
     * @param comparator `func(index, item) -> bool`
     * @returns {option} `Some<Vec<number>>` if any target was found, `None` otherwise
     */
    indeciesOfCompare(comparator) {
        arr := Array()
        for i, item in this.m_Data {
            if comparator(i, item) {
                arr.Push(i)
            }
        }

        return arr.Length == 0 ? Option.none() : Option.of(Vec.FromShared(arr))
    }

    /**
     * Find the first matching item in a collection by comparing every element against `comparator`.
     * This is useful for comparing more complex objects where you'd consider them equal despite them not having equal values for all their internal fields.
     * 
     * @param comparator `func(index, item) -> bool`
     * @returns {option} `Some<any>` if the target item was found, `None` otherwise
     * @see findLast(comparator)
     */
    find(comparator) {
        for i, item in this.m_Data {
            if comparator(i, item)
                return Option.of(item)
        }

        return Option.none()
    }

    /**
     * Find the last matching item in a collection by comparing every element against `comparator`.
     * This is useful for comparing more complex objects where you'd consider them equal despite them not having equal values for all their internal fields.
     * 
     * @param comparator `func(index, item) -> bool`
     * @returns {option} `Some<any>` if the target item was found, `None` otherwise
     * @see find(comparator)
     */
    findLast(comparator) {
        i := this.len()
        while i >= 1 {
            item := this.get(i).ok()
            if comparator(i, item)
                return Option.of(item)

            i--
        }

        return Option.none()
    }

    /**
     * Use `operation` on every item in the collection while not mutating it.
     * 
     * @param operation `func(index, item) -> void`
     * @returns {vec} the same `Vec` as invoked on, simply used for better chaining / debugging and being able to continue the chain.
     */
    foreach(operation) {
        for i, item in this.m_Data {
            operation(i, item)
        }

        return this
    }

    /**
     * Filter out items that return `false` for `predicate`
     * 
     * @param predicate `func(index, item) -> bool`
     * @returns {vec} new, filtered `Vec`
     * @see retain(predicate)
     * @see splitMap(predicate, operationTrue, operationFalse)
     */
    filter(predicate) {
        arr := Array()

        for i, item in this.m_Data {
            if predicate(i, item)
                arr.Push(item)
        }

        return Vec.FromShared(arr)
    }

    /**
     * Filter out items that return `false` for `predicate`
     *
     * @note This function changes the `Vec` in-place, meaning it modifies the original value.
     *
     * @param predicate `func(index, item) -> bool`
     * @returns {vec} `this`, but filtered by `predicate`
     * @see filter(predicate)
     * @see splitMap(predicate, operationTrue, operationFalse)
     */
    retain(predicate) {
        this.m_Data := this.filter(predicate).m_Data
        return this
    }

    /**
     * Map every item of a collection to some other value by applying `operation` on it
     * 
     * @param operation `func(index, item) -> any|item`
     * @returns {vec} new, remapped `Vec`
     * @see remap(operation)
     * @see splitMap(predicate, operationTrue, operationFalse)
     */
    map(operation) {
        arr := Array()
        arr.Capacity := this.len()

        for i, item in this.m_Data {
            arr.Push(operation(i, item))
        }

        return Vec.FromShared(arr)
    }

    /**
     * Map every item of a collection to some other value by applying `operation` on it
     * 
     * @note This function changes the `Vec` in-place, meaning it modifies the original value.
     * 
     * @param operation `func(index, item) -> any|item`
     * @returns {vec} `this`, but mutated by `operation`
     * @see map(operation)
     * @see splitMap(predicate, operationTrue, operationFalse)
     */
    remap(operation) {
        this.m_Data := this.map(operation).m_Data
        return this
    }

    /**
     * Apply `operationTrue` or `operationFalse` to every item the returns the respective value
     * when tested against `predicate`
     * 
     * @param predicate `func(index, item) -> bool`
     * @param operationTrue `func(index, item) -> any|item`
     * @param operationFalse `func(index, item) -> any|item`
     * @returns {Vec} new, remapped `Vec`
     * 
     * @example
     * s := Vec.FromRange(0, 20)
     *     .splitMapPreserveOrder(
     *         (_, item) => Mod(item, 2) == 0,
     *         (_, item) => item * item,
     *         (_, item) => 0
     *     )
     *     .join(", ")
     *
     * if s.isNone() {
     *     ToolTip("Unable to join the values together.")
     * }
     * else {
     *     ToolTip(s.unwrap())
     * }
     */
    splitMapPreserveOrder(predicate, operationTrue, operationFalse) {
        return this.map((i, item) => applyOperations(i, item))
        applyOperations(idx, item) {
            if predicate(idx, item) {
                return operationTrue(idx, item)
            }
            return operationFalse(idx, item)
        }
    }

    /**
     * Apply `operationTrue` or `operationFalse` to every item the returns the respective value
     * when tested against `predicate`
     * 
     * @note This function changes the `Vec` in-place, meaning it modifies the original value.
     * 
     * @param predicate `func(index, item) -> bool`
     * @param operationTrue `func(index, item) -> any|item`
     * @param operationFalse `func(index, item) -> any|item`
     * @returns {Vec} new, remapped `Vec`
     * 
     * @example
     * s := Vec.FromRange(0, 20)
     *     .splitMapPreserveOrderInPlace(
     *         (_, item) => Mod(item, 2) == 0,
     *         (_, item) => item * item,
     *         (_, item) => 0
     *     )
     *     .join(", ")
     *
     * if s.isNone() {
     *     ToolTip("Unable to join the values together.")
     * }
     * else {
     *     ToolTip(s.unwrap())
     * }
     */
    splitMapPreserveOrderInPlace(predicate, operationTrue, operationFalse) {
        this.m_Data := this.splitMapPreserverOrderInPlace(predicate, operationTrue, operationFalse).m_Data
        return this
    }

    /**
     * Chains `Vec`s together.
     * @param other a `Vec` to chain into `this`
     * @returns {vec} a new `Vec` made of `this` + `other`
     * @see chainInPlace(other)
     */
    chain(other) {
        new := this.Clone()
        new.m_Data.Push(other.m_Data*)
        return new
    }

    /**
     * Chains another `Vec` into `this`
     * 
     * @note This function changes the `Vec` in-place, meaning it modifies the original value.
     * 
     * @param other a `Vec` to chain into `this`
     * @returns {vec} `this` + `other`
     * @see chain(other)
     */
    chainInPlace(other) {
        this.m_Data.Push(other.m_Data*)
        return this
    }

    /**
     * Folds a collection of items into a single one
     * 
     * @param default the default / starting value
     * @param operation `func(accumulator, item) -> any`
     * @returns {any} the folded value
     */
    fold(default, operation) {
        acc := default

        for item in this.m_Data {
            acc := operation(acc, item)
        }

        return acc
    }


    /**
     * Join all elements together to a string
     * 
     * @param delim the delimiter between each element in the resulting string
     * @returns {Option<string>} the joined value, or None if the `Vec` is empty.
     */
    join(delim) {
        len := this.len()
        if len == 0 {
            return Option.none()
        }

        acc := ""

        for i, item in this.m_Data {
            acc .= item
            if i != len {
                acc .= delim
            }
        }

        return Option.of(acc)
    }

    /**
     * Take a sub-array of `this` by starting at `base` and continuing on for `len` items.
     * 
     * @param base from where to start
     * @param len how far to go
     * @returns {vec} sub-array of `this`
     * @see takeRange(low, high)
     */
    take(base, len) {
        if base < 1 {
            return Result.ofErr("Take: Base index of " base " is out of bounds.")
        }
        else if base + len - 1 > this.len() {
            return Result.ofErr("Take: Max index of " (base + len - 1) " is out of bounds.")
        }

        arr := Array()
        arr.Capacity := len
        i := 0

        while i < len {
            arr.Push(this.get(base + i).ok())
            i++
        }

        return Vec.FromShared(arr)
    }

    /**
     * Take a sub-array of `this` by defining a range from `low` up until but not including `high`
     * 
     * @param low from where the sub-array starts
     * @param high where the sub-array will end
     * @returns {vec} sub-array of `this`
     * @see take(base, len)
     */
    takeRange(low, high) {
        if low < 1  {
            return Result.ofErr("TakeRange: Min index of " low " is out of bounds.")
        }
        else if high > this.len() {
            return Result.ofErr("TakeRange: Max index of " high " is out of bounds.")
        }

        range := high - low
        arr := Array()
        arr.Capacity := range

        i := 0
        while i < range {
            arr.Push(this.get(low + i).ok())
            i++
        }

        return Vec.FromShared(arr)
    }


    /**
     * Get a new reversed `Vec` without mutating `this`
     * 
     * @returns {vec} new `Vec` for chaining function calls
     * @see revInPlace()
     */
    rev() {
        len := this.len()
        arr := Array()
        arr.Capacity := len
        i := len
        while i > 0 {
            arr.Push(this.get(i).ok())
            i--
        }

        return Vec.FromShared(arr)
    }

    /**
     * Reverses the vector in place and returns it
     * 
     * @note This function changes the `Vec` in-place, meaning it modifies the original value.
     * 
     * @returns {vec} `this` for chaining functions calls
     * @see rev()
     */
    revInPlace() {
        this.m_Data := this.rev().m_Data
        return this
    }

    /**
     * Limit your `Vec` to `n` elements, starting from the first one
     * 
     * @param n how long the return `Vec` will be
     * @returns {vec} limited `Vec`
     */
    limit(n) {
        if n > this.len() {
            return Vec.FromClone(this.m_Data)
        }
        return this.take(1, n)
    }

    /**
     * Limit your `Vec` to `n` elements, starting from the first one
     * 
     * @note This function changes the `Vec` in-place, meaning it modifies the original value.
     * 
     * @param n how long the return `Vec` will be
     * @returns {vec} limited `Vec`
     */
    limitInPlace(n) {
        if n > this.len() {
            return this
        }
        this.m_Data := this.take(1, n).m_Data
        return this
    }

    /**
     * Create overlapping windows or sub-arrays of size `size` over the `Vec`
     * 
     * @param size window size
     * @param operation `func(instance of Vec) => none`
     * @returns {result|vec} 
     */
    windows(size, operation) {
        if size < 1 or size > this.len() {
            return Result.ofErr("Windows: Invalid size: " size ".")
        }

        len := this.len()
        i := 0
        while i <= len - size {
            operation(this.take(i + 1, size))
            i++
        }

        return this
    }

    /**
     * Makes item-chunks out of `this`, starting from the front or "left side"
     * 
     * @note If `size` is bigger than `this.len()`, an Error will be returned.
     * 
     * @param size the chunk's size
     * @returns {result|vec} `Vec<Vec<Any>>`
     */
    chunks(size) {
        if size > this.len() or size < 1 {
            return Result.ofErr("Chunks: Invalid size: " size ".")
        }
        v := this.rev()
        i := 1
        chunk_index := 1
        list := Array()
        while v.len() != 0 {
            if list.Length != chunk_index {
                list.Push(Vec(size))
                list[chunk_index].push(v.pop())
            }
            else {
                list[chunk_index].push(v.pop())
            }

            if Mod(i, size) == 0 {
                chunk_index++
            }
            
            i++
        }

        return Vec.FromShared(list)
    }

    /**
     * Makes item-chunks out of `this`, starting from the back or "right side". Hence rchunks -> right-chunks
     * 
     * @note If `size` is bigger than `this.len()`, an Error will be returned.
     * 
     * @param size the chunk's size
     * @returns {vec} `Vec<Vec<Any>>`
     */
    rchunks(size) {
        if size > this.len() or size < 1 {
            return Result.ofErr("RChunks: Invalid size: " size ".")
        }
        i := 1
        chunk_index := 1
        list := Array()
        while this.len() != 0 {
            if list.Length != chunk_index {
                list.Push(Vec(size))
                list[chunk_index].push(this.pop())
            }
            else {
                list[chunk_index].push(this.pop())
            }

            if Mod(i, size) == 0 {
                chunk_index++
            }
            
            i++
        }

        return Vec.FromShared(list)
    }

    /**
     * Returns whether any of the items of this collection return true for `predicate`
     * 
     * @param predicate `func(index, item) -> Bool`
     * @returns {number} `true` if any of the items of `this` return true for `predicate`, `false` otherwise
     * @see all(predicate)
     */
    any(predicate) {
        for i, item in this.m_Data {
            if predicate(i, item)
                return true
        }

        return false
    }

    /**
     * Returns whether all of the items of this collection return true for `predicate`
     * 
     * @param predicate `func(index, item) -> Bool`
     * @returns {number} `true` if all of the items of `this` return true for `predicate`, `false` otherwise
     * @see any(predicate)
     */
    all(predicate) {
        for i, item in this.m_Data {
            if !predicate(i, item)
                return false
        }

        return true
    }

    /**
     * Shuffle (randomize the position of) the contained data.
     * 
     * @note This function changes the `Vec` in-place, meaning it modifies the original value.
     * 
     * @returns {vec} shuffled `Vec`
     */
    shuffle() {
        i := 1
        len := this.m_Data.Length
        while i <= len {                 ; ... Look below!
            current := this.m_Data[i]
            rand := Ceil(Random() * len) ; Ceil 🗿 -> 1-based indexing 🔥
            this.m_Data[i] := this.m_Data[rand]
            this.m_Data[rand] := current
            i++
        }

        return this
    }

    /**
     * Sort `this`'s items according to a given function / condition `predicate`.
     * 
     * @note This function changes the `Vec` in-place, meaning it modifies the original value.
     * 
     * @param predicate func(item1, item2) => bool
     * @returns {vec} sorted `Vec`
     */
    sortInPlace(predicate) {
        i := 1
        end := this.m_Data.Length

        while i <= end {
            current := this.m_Data[i]
            j := i - 1
            while j >= 1 and predicate(this.m_Data[j], current) {
                this.m_Data[j + 1] := this.m_Data[j]
                j--
            }
            this.m_Data[j + 1] := current
            i++
        }

        return this
    }

    /**
     * Sort `this`'s items according to a given function / condition `predicate`.
     * 
     * @param predicate func(item1, item2) => bool
     * @returns {vec} sorted `Vec`
     */
    sort(predicate) {
        i := 1
        arr := this.m_Data.Clone()

        end := arr.Length

        while i <= end {
            current := arr[i]
            j := i - 1
            while j >= 1 and predicate(arr[j], current) {
                arr[j + 1] := arr[j]
                j--
            }
            arr[j + 1] := current
            i++
        }

        return Vec.FromShared(arr)
    }
}