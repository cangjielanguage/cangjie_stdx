# Deflate 格式数据的压缩和解压

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.fs.*

main() {
    // 创建测试文件（1MB，内容为循环的 0-255）
    let originalData = Array<Byte>(1024 * 1024, {i => UInt8(i % 256)})
    let originalFile = "./deflate_original.txt"
    File.writeTo(originalFile, originalData)

    // 压缩文件
    let compressedFile = "./deflate_compressed.zlib"
    let compressedSize = compressFile(originalFile, compressedFile)
    println("压缩成功，写入字节数: ${compressedSize}")

    // 解压文件
    let decompressedFile = "./deflate_decompressed.txt"
    let decompressedSize = decompressFile(compressedFile, decompressedFile)
    println("解压成功，写入字节数: ${decompressedSize}")

    // 验证解压后的文件内容
    if (compareFile(originalFile, decompressedFile)) {
        println("验证成功：解压后文件与原文件一致")
    } else {
        println("验证失败：文件内容不一致")
    }

    // 清理测试文件
    remove(originalFile)
    remove(compressedFile)
    remove(decompressedFile)
    return 0
}

// 使用 Deflate 格式压缩文件
func compressFile(srcFile: String, destFile: String): Int64 {
    var writtenBytes: Int64 = 0
    try (input: File = File(srcFile, Read), output: File = File(destFile, Write)) {
        // 创建压缩输出流，指定 Deflate 格式
        var compressStream = CompressOutputStream(output, wrap: DeflateFormat)

        // 分块读取并压缩
        var buffer = Array<UInt8>(1024, repeat: 0)
        while (true) {
            let bytesRead = input.read(buffer)
            if (bytesRead <= 0) {
                break
            }
            compressStream.write(buffer.slice(0, bytesRead).toArray())
            writtenBytes += bytesRead
        }
        compressStream.flush()
        compressStream.close()
    }
    return writtenBytes
}

// 解压 Deflate 格式的文件
func decompressFile(srcFile: String, destFile: String): Int64 {
    var writtenBytes: Int64 = 0
    try (input: File = File(srcFile, Read), output: File = File(destFile, Write)) {
        // 创建解压输入流，指定 Deflate 格式
        var decompressStream = DecompressInputStream(input, wrap: DeflateFormat)

        // 分块读取并解压
        var buffer = Array<UInt8>(1024, repeat: 0)
        while (true) {
            let bytesRead = decompressStream.read(buffer)
            if (bytesRead <= 0) {
                break
            }
            output.write(buffer.slice(0, bytesRead).toArray())
            writtenBytes += bytesRead
        }
        decompressStream.close()
    }
    return writtenBytes
}

// 比较两个文件内容是否相同
func compareFile(file1: String, file2: String): Bool {
    return File.readFrom(file1) == File.readFrom(file2)
}
```

运行结果：

```text
压缩成功，写入字节数: 1048576
解压成功，写入字节数: 1048576
验证成功：解压后文件与原文件一致
```
