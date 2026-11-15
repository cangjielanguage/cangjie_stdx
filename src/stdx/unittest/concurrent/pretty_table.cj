/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */
package stdx.unittest.concurrent

import std.unittest.common.Color
import std.unittest.common.PrettyPrintable
import std.unittest.common.PrettyPrinter
import std.collection.ArrayList
import std.collection.HashSet
import std.collection.count

// Adapted from std.unittest's PrettyTable: the only change beyond the
// package line is displaySize — upstream computes rune widths through the
// module-protected std.unittest.common.TextWidth extension, which is
// unreachable from module stdx, so the (identical) width logic is inlined
// below (the ranges follow libc's wcwidth, as upstream).

// The std.collection-internal two-argument Int64 max (mirrors its
// implementation exactly); std.core only exposes the variadic-Array form,
// and the internal std.collection symbol is not importable here.
private func maxInt64(a: Int64, b: Int64): Int64 {
    return if (a >= b) {
        a
    } else {
        b
    }
}

private func runeIsFullWidth(r: Rune): Bool {
    let ch = UInt32(r)
    return ch >= 0x1100 &&
        (ch <= 0x115f ||                   // Hangul Jamo init. consonants
         ch == 0x2329 || ch == 0x232a ||
         (ch >= 0x2e80 && ch <= 0xa4cf &&  // CJK ... Yi
          ch != 0x303f) ||
         (ch >= 0xac00 && ch <= 0xd7a3) || // Hangul Syllables
         (ch >= 0xf900 && ch <= 0xfaff) || // CJK Compatibility Ideographs
         (ch >= 0xfe10 && ch <= 0xfe19) || // Vertical forms
         (ch >= 0xfe30 && ch <= 0xfe6f) || // CJK Compatibility Forms
         (ch >= 0xff00 && ch <= 0xff60) || // Fullwidth Forms
         (ch >= 0xffe0 && ch <= 0xffe6) ||
         (ch >= 0x20000 && ch <= 0x2fffd) ||
         (ch >= 0x30000 && ch <= 0x3fffd))
}

private func runeWidth(r: Rune): Int64 {
    if (runeIsFullWidth(r)) { 2 } else { 1 }
}

class PrettyTable <: PrettyPrintable {
    let columnSizes: ArrayList<Int64>
    let rows = ArrayList<ArrayList<(String, Color)>>()
    var column: Int64 = 0
    let leftAlignedColumns = HashSet<Int64>()
    let names: ArrayList<String> = ArrayList()

    PrettyTable(let sep!: String = "|", let separateColumnsNames!: Bool = true, let leftAligneAll!: Bool = false, let minColumnWidth!: Int64 = 6) {
        columnSizes = ArrayList()
        this.nextRow()
        this.nextRow()
    }

    func addColumn(name: String) {
        rows[0].add((" ${name} ", Color.DEFAULT_COLOR))
        rows[1].add(("", Color.DEFAULT_COLOR))
        columnSizes.add(maxInt64(minColumnWidth, name.runes() |> count))
    }

    func nextRow() {
        this.column = 0
        rows.add(ArrayList())
    }

    func addCell(value: String, color!: Color = Color.DEFAULT_COLOR) {

        rows[rows.size - 1].add((" ${value} ", color))
        if (column >= columnSizes.size) { return }

        let size = maxInt64(columnSizes[column], displaySize(value))
        columnSizes[column] = size

        column += 1
    }

    private func displaySize(str: String): Int64 {
        // We assume ambiguous width as half width. Such symbols are quite rare.
        // However TerminalPrinter will be able to handle one of such characters being full width by overwriting trailing space.
        // For example, this can happen for `±` which has ambiguous width and actual width depends on a specific font being used.
        str.runes()
            .map { r: Rune => runeWidth(r) }
            .fold(0) { a, b => a + b }
    }

    public func pprint(pp: PrettyPrinter): PrettyPrinter {
        for (row in 0..rows.size) {
            for (col in 0..columnSizes.size) {
        // cjlint-ignore -start !G.VAR.02 the variables below thread state across loop/algorithm iterations (accumulators or framework context); narrowing their scopes would change semantics
                var (data, color) = rows[row][col] // cjlint-ignore !G.VAR.01 Cangjie tuple destructuring binds one mutability modifier for the whole pattern; `data` is reassigned below, so `var` is forced for the pair
        // cjlint-ignore -end
                let width = columnSizes[col] + 2 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                let alignLeft = leftAligneAll || leftAlignedColumns.contains(col)

                if (row == 1 && separateColumnsNames && alignLeft) {
                    data = ":" + String.fromUtf8(Array(width - 1, repeat: b'-'))
                }
                if (row == 1 && separateColumnsNames && !alignLeft) {
                    data = String.fromUtf8(Array(width - 1, repeat: b'-')) + ":"
                }
                if (row != 1 || separateColumnsNames) {
                    pp.append(sep)
                    printCell(pp, data, width, color, alignLeft)
                }
            }
            if (row != 1 || separateColumnsNames) {
                pp.append(sep)
                pp.newLine()
            }
        }
        pp
    }

    private func printCell(pp: PrettyPrinter, data: String, width: Int64, color: Color, alignLeft: Bool) {
        let nonAsciiShift = data.size - displaySize(data)
        pp.colored(color) {
            pp.fillLimitedSpace(width) {
                if (alignLeft) {
                    pp.appendLeftAligned(data, UInt64(width + nonAsciiShift))
                } else {
                    pp.appendRightAligned(data, UInt64(width + nonAsciiShift))
                }
            }
        }
    }
}