/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

import std.fs.*

/**
 * A single point in a source file (line and column, 1-based when valid).
 *
 * Used as start or end position inside DebugLocation.
 */
public struct Position <: ToString {
    private let _line: Int64

    private let _column: Int64

    /**
     * 1-based line number in the source file.
     * @type { Int64 }
     */
    public prop line: Int64 {
        get() {
            return _line
        }
    }

    /**
     * 1-based column number in the source file.
     * @type { Int64 }
     */
    public prop column: Int64 {
        get() {
            return _column
        }
    }

    /**
     * Whether this position holds a real source location (line and column both greater than 0).
     */
    public func isValid(): Bool {
        return line > 0 && column > 0
    }

    /**
     * Compact string form "-line-column" for debugging.
     */
    public func toString(): String {
        let result = StringBuilder()
        result.append("-")
        result.append(line.toString())
        result.append("-")
        result.append(column.toString())
        return result.toString()
    }

    internal init() {
        this._line = 0
        this._column = 0
    }

    internal init(line: Int64, column: Int64) {
        this._line = line
        this._column = column
    }
}

/**
 * Span in a source file (start/end positions and path) for CHIR debug info.
 */
public class DebugLocation <: ToString {
    internal var _fileId: UInt64 = 0
    internal var _scopeInfo: ArrayList<Int64> = ArrayList<Int64>()
    private let _end: Position
    private let _filePath: Path
    private let _start: Position

    /**
     * End position of the span.
     * @type { Position }
     */
    public prop end: Position {
        get() {
            return _end
        }
    }

    /**
     * Absolute or workspace path of the source file.
     * @type { Path }
     */
    public prop filePath: Path {
        get() {
            return _filePath
        }
    }

    /**
     * Start position of the span (inclusive).
     * @type { Position }
     */
    public prop start: Position {
        get() {
            return _start
        }
    }

    internal init() {
        this._start = Position()
        this._end = Position()
        this._filePath = Path(String.empty)
    }

    internal init(start: Position, end: Position, filePath: Path) {
        this._start = start
        this._end = end
        this._filePath = filePath;
    }

    internal static func invalid(): DebugLocation {
        return DebugLocation()
    }

    /**
     * Whether start, end, and file path are all set meaningfully.
     */
    public func isValid(): Bool {
        return start.isValid() && end.isValid() && !filePath.isEmpty()
    }

    /**
     * Human-readable location: file name, line/column range, optional scope chain.
     */
    public func toString(): String {
        if (!isValid()) {
            return String.empty
        }
        let result = StringBuilder()
        result.append(filePath.fileName)
        result.append(start.toString())
        if (!_scopeInfo.isEmpty()) {
            var scopeStr = ArrayList<String>()
            for (info in _scopeInfo) {
                scopeStr.add(info.toString())
            }
            result.append(", scope: ")
            result.append(String.join(scopeStr.toArray(), delimiter: "-"))
        }
        return result.toString()
    }
}
