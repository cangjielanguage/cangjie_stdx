# Tar 格式数据的归档与提取

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main() {
    let originalFile = Path("./tgz_src.txt")
    let tarFile = Path("./archive.tar")
    let extractedFile = Path("./tgz_dst.txt")
    let fileSize = 1024 * 1024

    // 创建测试文件
    createFile(originalFile, fileSize)

    // 归档文件到 tar 包
    let tarSize = archiveFile(originalFile, tarFile)
    println("归档成功，tar 文件大小: ${tarSize} 字节")

    // 从 tar 包提取文件
    let extractedSize = extractFile(tarFile, extractedFile)
    println("提取成功，解压文件大小: ${extractedSize} 字节")

    // 验证文件内容一致性
    if (compareFile(originalFile, extractedFile)) {
        println("验证成功：文件内容一致")
    } else {
        println("验证失败：文件内容不一致")
    }

    // 清理测试文件
    remove(originalFile)
    remove(tarFile)
    remove(extractedFile)
    return 0
}

// 归档单个文件到 tar 包
func archiveFile(srcFile: Path, tarFile: Path): Int64 {
    try (outFile: File = File(tarFile, Write)) {
        var writer = TarWriter(outFile)
        // 写入文件条目，使用文件名作为条目名
        writer.write(srcFile, entryName: srcFile.fileName)
        writer.finish()
        return outFile.length
    }
    return 0
}

// 从 tar 包提取文件
func extractFile(tarFile: Path, destFile: Path): Int64 {
    var writtenBytes: Int64 = 0
    try (inFile: File = File(tarFile, Read), outFile: File = File(destFile, Write)) {
        var reader = TarReader(inFile)
        for (entry in reader) {
            // 只处理普通文件
            if (entry.entryType == TarEntryType.RegularFile) {
                if (let Some(stream) <- entry.stream) {
                    writtenBytes = copy(stream, to: outFile)
                    break
                }
            }
        }
    }
    return writtenBytes
}

// 创建指定大小的测试文件
func createFile(file: Path, size: Int64) {
    File.writeTo(file, Array<Byte>(size, {i => UInt8(i % 256)}))
}

// 比较两个文件内容是否相同
func compareFile(file1: Path, file2: Path): Bool {
    return File.readFrom(file1) == File.readFrom(file2)
}
```

运行结果：

```text
归档成功，tar 文件大小: 1050112 字节
提取成功，解压文件大小: 1048576 字节
验证成功：文件内容一致
```
