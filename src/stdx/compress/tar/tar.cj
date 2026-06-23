/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.compress.tar

import std.fs.{Path, File, FileInfo, Directory, SymbolicLink, HardLink, OpenMode, remove, exists, canonicalize}
import std.io.{InputStream, OutputStream, copy}

public class Tar {
    private init() {} // static class

    public static func archive(fromDir!: String, destFile!: String, includeBaseDirectory!: Bool): Unit {
        try (file = File(destFile, OpenMode.Write)) {
            Tar.archive(fromDir: Path(fromDir), destStream: file, includeBaseDirectory: includeBaseDirectory)
        }
    }

    public static func archive(fromDir!: Path, destFile!: Path, includeBaseDirectory!: Bool): Unit {
        try (file = File(destFile, OpenMode.Write)) {
            Tar.archive(fromDir: fromDir, destStream: file, includeBaseDirectory: includeBaseDirectory)
        }
    }

    public static func archive<T>(fromDir!: String, destStream!: T, includeBaseDirectory!: Bool): Unit where T <: OutputStream {
        Tar.archive(fromDir: Path(fromDir), destStream: destStream, includeBaseDirectory: includeBaseDirectory)
    }

    public static func archive<T>(fromDir!: Path, destStream!: T, includeBaseDirectory!: Bool): Unit where T <: OutputStream {
        Tar.archive(fromDir: fromDir, filter: {_ => true}, destStream: destStream,
            includeBaseDirectory: includeBaseDirectory)
    }

    public static func archive(fromDir!: String, filter!: (String) -> Bool, destFile!: String,
        includeBaseDirectory!: Bool): Unit {
        try (file = File(destFile, OpenMode.Write)) {
            Tar.archive(fromDir: Path(fromDir), filter: {p: Path => filter(p.toString())}, destStream: file,
                includeBaseDirectory: includeBaseDirectory)
        }
    }

    public static func archive(fromDir!: Path, filter!: (Path) -> Bool, destFile!: Path, includeBaseDirectory!: Bool): Unit {
        try (file = File(destFile, OpenMode.Write)) {
            Tar.archive(fromDir: fromDir, filter: filter, destStream: file, includeBaseDirectory: includeBaseDirectory)
        }
    }

    protected static func archive<T>(fromDir!: Path, filter!: (Path) -> Bool, destStream!: T,
        includeBaseDirectory!: Bool): Unit where T <: OutputStream {
        if (!exists(fromDir)) {
            throw TarException("From directory not exists: ${fromDir}.")
        }
        if (!FileInfo(fromDir).isDirectory()) {
            throw TarException("From directory is not a directory: ${fromDir}.")
        }
        let fromDirCanonicalized = canonicalize(fromDir)
        if (isRootPath(fromDirCanonicalized.toString())) {
            throw TarException("Can not archive root directory: ${fromDir}.")
        }
        let fromDirNormalized = fromDirCanonicalized.normalizePath()
        let fromDirNormalizedPath = Path(fromDirNormalized)
        let tarWriter = TarWriter(destStream)
        let prefixLength: Int64
        if (includeBaseDirectory) {
            tarWriter.write(path: fromDirNormalized, entryName: fromDirNormalizedPath.fileName)
            prefixLength = fromDirNormalizedPath.parent.toString().size + 1
        } else {
            prefixLength = fromDirNormalized.size + 1
        }
        Directory.walkRecursively(Path(fromDirNormalized)) {
            fileInfo, targetType =>
                if (!filter(fileInfo.path)) {
                    return
                }
                var entryName = fileInfo.path.toString()[prefixLength..]
                if (targetType == TargetType.Directory) {
                    entryName += "/"
                }
                tarWriter.write(fileInfo, entryName: entryName)
        }
        tarWriter.finish()
    }

    public static func extract(fromTar!: String, destDir!: String, overwrite!: Bool): Unit {
        try (file = File(fromTar, OpenMode.Read)) {
            Tar.extract(fromStream: file, destDir: Path(destDir), overwrite: overwrite)
        }
    }

    public static func extract(fromTar!: Path, destDir!: Path, overwrite!: Bool): Unit {
        try (file = File(fromTar, OpenMode.Read)) {
            Tar.extract(fromStream: file, destDir: destDir, overwrite: overwrite)
        }
    }

    public static func extract<T>(fromStream!: T, destDir!: String, overwrite!: Bool): Unit where T <: InputStream {
        Tar.extract(fromStream: fromStream, destDir: Path(destDir), overwrite: overwrite)
    }

    public static func extract<T>(fromStream!: T, destDir!: Path, overwrite!: Bool): Unit where T <: InputStream {
        if (!exists(destDir)) {
            Directory.create(destDir, recursive: true)
        }
        let destAbsoluteDir = canonicalize(destDir)

        let tarReader = TarReader(fromStream)
        for (entry in tarReader) {
            let entryPath = destAbsoluteDir.join(entry.name)

            if (!isPathWithinDirectory(entryPath.normalize(), destAbsoluteDir)) {
                throw TarException("Zip Slip detected: ${entry.name}.")
            }

            if (exists(entryPath)) {
                if (!overwrite) {
                    throw TarException("File ${entryPath} already exists and overwrite is false.")
                }
                if (!FileInfo(entryPath).isDirectory()) {
                    remove(entryPath)
                }
            }

            // check slip for both file and directory
            match (entry.entryType) {
                case TarEntryType.RegularFile | TarEntryType.V7RegularFile | TarEntryType.ContiguousFile
                    | TarEntryType.Directory =>
                    let parentDir = entryPath.parent
                    // For the first time, before creating the parent directory, prevent existing symlinks.
                    // For example, if an existing ancestor of parentDir is a symbolic link pointing outside the
                    // directory, even if parentDir lexically appears to be within the extraction root,
                    // after actual resolution, it will have escaped outside.
                    ensureRegularFileParentWithinDirectory(parentDir, destAbsoluteDir, entry.name)
                    if (!parentDir.isEmpty() && !exists(parentDir)) {
                        Directory.create(parentDir, recursive: true)
                    }
                    // The second time after executing Directory.create(parentDir, recursive: true), the result of
                    // preventing creation is inconsistent with expectations. Although under normal circumstances,
                    // the newly created directory is still within the root, after creation, performing a canonicalize
                    // check on the complete parentDir can ensure that the final actual parent directory has not been
                    // redirected before proceeding with file writing.
                    ensureRegularFileParentWithinDirectory(parentDir, destAbsoluteDir, entry.name)
                case _ => ()
            }

            match (entry.entryType) {
                case TarEntryType.Directory =>
                    if (!exists(entryPath)) {
                        Directory.create(entryPath, recursive: true)
                    }
                case TarEntryType.RegularFile | TarEntryType.V7RegularFile | TarEntryType.ContiguousFile =>
                    if (let Some(stream) <- entry.stream) {
                        try (outputFile = File(entryPath.toString(), OpenMode.Write)) {
                            copy(stream, to: outputFile)
                        }
                    }
                case TarEntryType.Symlink =>
                    checkSymbolicLinkTarget(entry.linkName, entryPath, destAbsoluteDir)
                    SymbolicLink.create(entryPath, to: Path(entry.linkName))
                case TarEntryType.HardLink =>
                    checkHardLinkTarget(entry.linkName, destAbsoluteDir)
                    HardLink.create(entryPath, to: Path(entry.linkName))
                case _ => continue
            }
            if (entry.entryType != TarEntryType.Symlink) {
                Native.setFileAttributes(entryPath, entry)
            }
        }
    }

    private static func checkSymbolicLinkTarget(linkName: String, linkPath: Path, destDir: Path) {
        var linkTarget = Path(linkName)
        if (linkTarget.isRelative()) {
            let linkParent = linkPath.parent
            if (!linkParent.isEmpty()) {
                linkTarget = linkParent.join(linkTarget).normalize()
            }
        }
        if (!isPathWithinDirectory(linkTarget, destDir)) {
            throw TarException("Symlink points outside target dir.")
        }
    }

    private static func checkHardLinkTarget(linkName: String, destDir: Path) {
        var linkTarget = Path(linkName)
        if (linkTarget.isRelative()) {
            linkTarget = destDir.join(linkTarget).normalize()
        } else {
            throw TarException("Hardlink points to absolute path outside target dir.")
        }
        if (!isPathWithinDirectory(linkTarget, destDir)) {
            throw TarException("Hardlink points outside target dir.")
        }
    }

    /**
     * Check whether a path is within the directory.
     */
    private static func isPathWithinDirectory(path: Path, dir: Path): Bool {
        let normalizedPath = path.normalize().toString()
        let normalizedDir = dir.normalize().toString()

        if (normalizedPath == normalizedDir) {
            return true
        }

        if (normalizedDir.endsWith(Path.Separator)) {
            return normalizedPath.startsWith(normalizedDir)
        }

        return normalizedPath.startsWith("${normalizedDir}${Path.Separator}")
    }

    /**
     * Ensure the parentDir is within the target directory
     */
    private static func ensureRegularFileParentWithinDirectory(parentDir: Path, destDir: Path, entryName: String): Unit {
        if (parentDir.isEmpty()) {
            return
        }

        var nearestExistingAncestor = parentDir
        while (!nearestExistingAncestor.isEmpty() && !exists(nearestExistingAncestor)) {
            nearestExistingAncestor = nearestExistingAncestor.parent
        }

        if (nearestExistingAncestor.isEmpty()) {
            throw TarException("Cannot resolve parent path for tar entry: ${entryName}.")
        }

        let resolvedAncestor = canonicalize(nearestExistingAncestor)
        if (!isPathWithinDirectory(resolvedAncestor, destDir)) {
            throw TarException("Resolved parent path escapes target dir for tar entry: ${entryName}.")
        }

        if (exists(parentDir)) {
            let resolvedParentDir = canonicalize(parentDir)
            if (!isPathWithinDirectory(resolvedParentDir, destDir)) {
                throw TarException("Resolved parent path escapes target dir for tar entry: ${entryName}.")
            }
        }
    }
}
