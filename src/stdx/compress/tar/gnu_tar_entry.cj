/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.compress.tar

import std.fs.{Path, FileInfo}
import std.io.{InputStream, OutputStream}
import std.core.Option
import std.time.DateTime

private class GnuExtensionTarEntry {
    private static const LONG_LINK_NAME = "././@LongLink"
    private static const LONG_NAME_NAME = "././@LongName"

    private let isLinkName: Bool
    private let data: Array<UInt8>
    private let header = TarHeaderBuffer()

    private func initializeHeader() {
        if (isLinkName) {
            LONG_LINK_NAME
        } else {
            LONG_NAME_NAME
        }.encodeTo(header[FieldLocation.NAME])
        "0000000".encodeTo(header[FieldLocation.MODE])
        "0000000".encodeTo(header[FieldLocation.UID])
        "0000000".encodeTo(header[FieldLocation.GID])
        (data.size + 1).encodeOcatalTo(header[FieldLocation.SIZE])
        "00000000000".encodeTo(header[FieldLocation.M_TIME])
        header[FieldLocation.TYPE_FLAG][0] = if (isLinkName) {
            TarEntryType.GnuLongLink
        } else {
            TarEntryType.GnuLongName
        }.flag
        GNU_MAGIC.encodeTo(header[FieldLocation.MAGIC])
        GNU_VERSION.encodeTo(header[FieldLocation.VERSION])
    }

    init(data: String, isLinkName: Bool) {
        this.data = unsafe { data.rawData() }
        this.isLinkName = isLinkName
        initializeHeader()
    }

    func writeTo(target: OutputStream): Unit {
        header.writeTo(target)
        target.write(data)
        target.write(b'\0')
        writeZeros(target, calculateDataBlockPadding(data.size + 1))
    }
}

public class GnuTarEntry <: PosixTarEntry {
    public prop accessTime: DateTime {
        get() { return _header.aTime }
    }

    public prop changeTime: DateTime {
        get() { return _header.cTime }
    }

    init(header: TarHeader) {
        super(header)
    }

    init(header: TarHeader, stream: ?InputStream) {
        super(header, stream)
    }

    public init(path: String) {
        this(Path(path))
    }

    public init(path: Path) {
        super(path)

        _header.format = TarEntryFormat.Gnu

        let fileInfo = FileInfo(path)
        _header.aTime = fileInfo.lastAccessTime
        _header.cTime = fileInfo.creationTime
    }

    func writeGnuFields(buffer: TarHeaderBuffer) {
        _header.aTime.encodeTo(buffer[FieldLocation.A_TIME])
        _header.cTime.encodeTo(buffer[FieldLocation.C_TIME])
    }

    private static func writeGnuExtensionEntry(target: OutputStream, name: String, isLinkName: Bool) {
        GnuExtensionTarEntry(name, isLinkName).writeTo(target)
    }

    public override func writeTo(target: OutputStream): Unit {
        let buffer = TarHeaderBuffer()
        if (name.size > FieldLocation.NAME.length) {
            writeGnuExtensionEntry(target, name, false)
        } else {
            writeNameDirectly(buffer)
        }
        if (linkName.size > FieldLocation.LINK_NAME.length) {
            writeGnuExtensionEntry(target, linkName, true)
        } else {
            writeLinkNameDirectly(buffer)
        }
        writeCommonFieldsWithoutNameChecksumLinkName(buffer)
        writePosixFields(buffer, GNU_MAGIC, GNU_VERSION)
        writeGnuFields(buffer)

        buffer.writeTo(target)

        writeDataTo(target)
    }
}
