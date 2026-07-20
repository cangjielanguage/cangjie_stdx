# 类

## class GnuTarEntry

```cangjie
public class GnuTarEntry <: PosixTarEntry {
    public init(path: String)
    public init(path: Path)
}
```

功能：表示 Gnu tar 文件条目。

父类型：

- [PosixTarEntry](#class-posixtarentry)

### prop accessTime

```cangjie
public prop accessTime: DateTime
```

功能：获取当前条目的访问时间。

类型：DateTime

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 GnuTarEntry
    var entry = GnuTarEntry(testFile)

    println("访问时间: ${entry.accessTime}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

可能的运行结果：

```text
访问时间: 2025-12-19T03:42:59Z
```

### prop changeTime

```cangjie
public prop changeTime: DateTime
```

功能：获取当前条目的修改时间。

类型：DateTime

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 GnuTarEntry
    var entry = GnuTarEntry(testFile)

    println("修改时间: ${entry.changeTime}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

可能的运行结果：

```text
修改时间: 2025-12-19T03:45:31Z
```

### init(Path)

```cangjie
public init(path: Path)
```

功能：从文件、目录、软链接构造一个 Gnu tar 文件条目。

参数：

- path: Path - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 GnuTarEntry
    var gnuEntry = GnuTarEntry(testFile)

    println("GnuTarEntry created successfully")
    println("Entry name: ${gnuEntry.name}")
    println("Entry size: ${gnuEntry.size}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
GnuTarEntry created successfully
Entry name: test.txt
Entry size: 11
```

### init(String)

```cangjie
public init(path: String)
```

功能：从文件、目录、软链接构造一个 Gnu tar 文件条目。

参数：

- path: String - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = "./test.txt"
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 GnuTarEntry
    var gnuEntry = GnuTarEntry(testFile)

    println("GnuTarEntry created successfully from string path")
    println("Entry name: ${gnuEntry.name}")
    println("Entry size: ${gnuEntry.size}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
GnuTarEntry created successfully from string path
Entry name: test.txt
Entry size: 11
```

### func writeTo(OutputStream)

```cangjie
public override func writeTo(target: OutputStream): Unit
```

功能：将当前条目写入到指定的输出流中。

参数：

- target: OutputStream - 指定输出流。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果字段超出格式要求或写入失败，则抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 GnuTarEntry
    var entry = GnuTarEntry(testFile)

    // 创建输出流和 TarWriter
    let outFile = File("./output.tar", Write)
    var writer = TarWriter(outFile)

    // 将条目写入 tar 文件
    writer.write(entry)
    writer.finish()

    // 清理文件
    outFile.close()
    removeIfExists(testFile)
    removeIfExists("./output.tar")
}
```

## class PaxTarEntry

```cangjie
public class PaxTarEntry <: PosixTarEntry {
    public init(path: String)
    public init(path: Path)
}
```

功能：表示 Pax tar 文件条目。

父类型：

- [PosixTarEntry](#class-posixtarentry)

### init(Path)

```cangjie
public init(path: Path)
```

功能：从文件、目录、软链接构造一个 Pax tar 文件条目。

参数：

- path: Path - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 PaxTarEntry
    var entry = PaxTarEntry(testFile)

    println("PaxTarEntry 创建成功")
    println("条目名称: ${entry.name}")
    println("条目大小: ${entry.size}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
PaxTarEntry 创建成功
条目名称: test.txt
条目大小: 11
```

### init(String)

```cangjie
public init(path: String)
```

功能：从文件、目录、软链接构造一个 Pax tar 文件条目。

参数：

- path: String - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = "./test.txt"
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 使用字符串路径创建 PaxTarEntry
    var entry = PaxTarEntry(testFile)

    println("PaxTarEntry 通过字符串路径创建成功")
    println("条目名称: ${entry.name}")
    println("条目大小: ${entry.size}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
PaxTarEntry 通过字符串路径创建成功
条目名称: test.txt
条目大小: 11
```

### func getPaxData(String)

```cangjie
public func getPaxData(key: String): ?String
```

功能：获取当前条目的 Pax 数据。

参数：

- key: String - Pax 数据的键。

返回值：

- ?\<String> - 如果存在对应键的 Pax 数据，则返回其值，否则返回 None。

示例：

<!-- verify -->
```cangjie
import std.process.*
import stdx.compress.tar.*
import std.fs.*

main(): Int64 {
    // 设定路径
    let testFile = "./testFile.txt"
    let testPax = "./test.pax"

    // 创建测试文件
    File.writeTo(testFile, "文件数据...".toArray())

    // 创建 pax 文件，执行命令 "tar --format=pax --pax-option=yourKey=yourValue -cf test.pax testFile.txt"
    executeWithOutput(
        "tar",
        ["--format=pax", "--pax-option=yourKey=yourValue", "-cf", testPax, testFile]
    )

    // 创建输入流
    let inFile = File(testPax, Read)

    // 创建 TarReader
    var reader = TarReader(inFile)

    for (entry in reader) {
        if (let Some(paxEntry) <- (entry as PaxTarEntry)) {
            // 获取 Pax 数据
            let paxData = paxEntry.getPaxData("yourKey")
            println("Pax 数据: ${paxData}")
        }
    }
    // 清理测试文件
    removeIfExists(testFile)
    removeIfExists(testPax)

    return 0
}
```

运行结果：

```text
Pax 数据: Some(yourValue)
```

### func writeTo(OutputStream)

```cangjie
public override func writeTo(target: OutputStream): Unit
```

功能：将当前条目写入到指定的输出流中。

参数：

- target: OutputStream - 指定输出流。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果字段超出格式要求或写入失败，则抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 PaxTarEntry
    var entry = PaxTarEntry(testFile)

    // 创建输出流和 TarWriter
    let outFile = File("./output.tar", Write)
    var writer = TarWriter(outFile)

    // 将条目写入 tar 文件
    writer.write(entry)
    writer.finish()

    // 清理文件
    outFile.close()
    removeIfExists(testFile)
    removeIfExists("./output.tar")
}
```

## class PosixTarEntry

```cangjie
public abstract class PosixTarEntry <: TarEntry {
    protected init(path: String)
    protected init(path: Path)
}
```

功能：表示含有 Ustar Gnu Pax 格式共有字段的 tar 文件条目。

父类型：

- [TarEntry](#class-tarentry)

### prop deviceMajor

```cangjie
public prop deviceMajor: Int32
```

功能：获取当前条目的设备主编号。

类型：Int32

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 PosixTarEntry
    var entry: PosixTarEntry = PaxTarEntry(testFile)

    println("Entry device major: ${entry.deviceMajor}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
Entry device major: 0
```

### prop deviceMinor

```cangjie
public prop deviceMinor: Int32
```

功能：获取当前条目的设备次编号。

类型：Int32

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 PosixTarEntry
    var entry: PosixTarEntry = PaxTarEntry(testFile)

    println("Entry device minor: ${entry.deviceMinor}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
Entry device minor: 0
```

### prop groupName

```cangjie
public prop groupName: String
```

功能：获取当前条目的组名。

类型：String

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 PosixTarEntry
    var entry: PosixTarEntry = PaxTarEntry(testFile)

    println("Entry group name: ${entry.groupName}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

可能的运行结果：

```text
Entry group name: yourName
```

### prop userName

```cangjie
public prop userName: String
```

功能：获取当前条目的用户名。

类型：String

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 PosixTarEntry
    var entry: PosixTarEntry = PaxTarEntry(testFile)

    println("Entry user name: ${entry.userName}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

可能的运行结果：

```text
Entry user name: yourName
```

### init(Path)

```cangjie
protected init(path: Path)
```

功能：从文件、目录、软链接构造一个 tar 文件条目。

参数：

- path: Path - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 PosixTarEntry（PosixTarEntry本身是抽象类，不能直接实例化）
    var entry: PosixTarEntry = PaxTarEntry(testFile)

    // 清理测试文件
    removeIfExists(testFile)
}
```

### init(String)

```cangjie
protected init(path: String)
```

功能：从文件、目录、软链接构造一个 tar 文件条目。

参数：

- path: String - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = "./test.txt"
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 PosixTarEntry（PosixTarEntry本身是抽象类，不能直接实例化）
    var entry: PosixTarEntry = PaxTarEntry(testFile)

    // 清理测试文件
    removeIfExists(testFile)
}
```

## class Tar

```cangjie
public class Tar {}
```

功能：归档和提取目录或流。

### static func archive(Path, (Path) -> Bool, Path, Bool)

```cangjie
public static func archive(fromDir!: Path, filter!: (Path) -> Bool, destFile!: Path, includeBaseDirectory!: Bool): Unit
```

功能：配合过滤函数选择性地将指定目录归档为 .tar 文件。

参数：

- fromDir!: Path - 待归档目录。

- filter!: (Path) -> Bool - 过滤函数，会传入遍历到的目录、文件和软链接路径，返回 true 表示保留，否则丢弃。

- destFile!: Path - 输出的 .tar 文件路径。

- includeBaseDirectory!: Bool - 是否包含根目录。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 归档时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = Path("./test_dir")
    let testFile = Path("./test_dir/test.txt")

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 归档目录
    let archiveFile = Path("./test_archive.tar")
    Tar.archive(fromDir: testDir, filter: {_: Path => true}, destFile: archiveFile, includeBaseDirectory: true)

    println("归档文件: ${archiveFile}")

    // 清理测试文件
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)
    removeIfExists(archiveFile)
}
```

运行结果：

```text
归档文件: ./test_archive.tar
```

### static func archive(Path, Path, Bool)

```cangjie
public static func archive(fromDir!: Path, destFile!: Path, includeBaseDirectory!: Bool): Unit
```

功能：将指定目录归档为 .tar 文件。

参数：

- fromDir!: Path - 待归档的目录路径。

- destFile!: Path - 生成的 .tar 文件路径。

- includeBaseDirectory!: Bool - 是否包含目录本身作为顶级目录。若为 true，归档包内包含该目录；若为 false，仅包含其内容。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 归档时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = Path("./test_dir")
    let testFile = Path("./test_dir/test.txt")

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 归档目录
    let archiveFile = Path("./test_archive.tar")
    Tar.archive(fromDir: testDir, destFile: archiveFile, includeBaseDirectory: true)

    println("目录归档成功")
    println("归档文件: ${archiveFile}")

    // 清理测试文件
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)
    removeIfExists(archiveFile)
}
```

运行结果：

```text
目录归档成功
归档文件: ./test_archive.tar
```

### static func archive(String, (String) -> Bool, String, Bool)

```cangjie
public static func archive(fromDir!: String, filter!: (String) -> Bool, destFile!: String, includeBaseDirectory!: Bool): Unit
```

功能：配合过滤函数选择性地将指定目录归档为 .tar 文件。

参数：

- fromDir!: String - 待归档目录。

- filter!: (String) -> Bool - 过滤函数，会传入遍历到的目录、文件和软链接路径，返回 true 表示保留，否则丢弃。

- destFile!: String - 输出的 .tar 文件路径。

- includeBaseDirectory!: Bool - 是否包含根目录。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 归档时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = "./test_dir"
    let testFile = "./test_dir/test.txt"

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 使用字符串路径和过滤函数归档目录
    let archiveFile = "./test_archive_filtered.tar"
    Tar.archive(fromDir: testDir, filter: {_: String => true}, destFile: archiveFile, includeBaseDirectory: true)

    println("带过滤函数的目录归档成功")
    println("归档文件: ${archiveFile}")

    // 清理测试文件
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)
    removeIfExists(archiveFile)
}
```

运行结果：

```text
带过滤函数的目录归档成功
归档文件: ./test_archive_filtered.tar
```

### static func archive(String, String, Bool)

```cangjie
public static func archive(fromDir!: String, destFile!: String, includeBaseDirectory!: Bool): Unit
```

功能：将指定目录归档为 .tar 文件。

参数：

- fromDir!: String - 待归档的目录路径。

- destFile!: String - 生成的 .tar 文件路径。

- includeBaseDirectory!: Bool - 是否包含目录本身作为顶级目录。若为 true，归档包内包含该目录；若为 false，仅包含其内容。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 归档时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = "./test_dir"
    let testFile = "./test_dir/test.txt"

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 使用字符串路径归档目录
    let archiveFile = "./test_archive_string.tar"
    Tar.archive(fromDir: testDir, destFile: archiveFile, includeBaseDirectory: true)

    println("使用字符串路径的目录归档成功")
    println("归档文件: ${archiveFile}")

    // 清理测试文件
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)
    removeIfExists(archiveFile)
}
```

运行结果：

```text
使用字符串路径的目录归档成功
归档文件: ./test_archive_string.tar
```

### static func archive\<T>(Path, T, Bool) where T <: OutputStream

```cangjie
public static func archive<T>(fromDir!: Path, destStream!: T, includeBaseDirectory!: Bool): Unit where T <: OutputStream
```

功能：将目录归档为 .tar 数据并写入指定输出流。

> **注意：**
>
> 函数不负责 destStream 资源的释放，调用方需自行管理该输出流的生命周期。

参数：

- fromDir!: Path - 待归档的目录路径。

- destStream!: T - 归档后数据的输出流。

- includeBaseDirectory!: Bool - 是否包含根目录。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 归档时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = Path("./test_dir")
    let testFile = Path("./test_dir/test.txt")
    let testFileStream = Path("./test_archive_stream.tar")

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建输出流
    let outputStream = File(testFileStream, Write)

    // 将目录归档到输出流
    Tar.archive(fromDir: testDir, destStream: outputStream, includeBaseDirectory: true)

    println("目录归档到输出流成功")

    // 清理测试文件
    outputStream.close()
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)
    removeIfExists(testFileStream)
}
```

运行结果：

```text
目录归档到输出流成功
```

### static func archive\<T>(String, T, Bool) where T <: OutputStream

```cangjie
public static func archive<T>(fromDir!: String, destStream!: T, includeBaseDirectory!: Bool): Unit where T <: OutputStream
```

功能：将目录归档为 .tar 数据并写入指定输出流。

> **注意：**
>
> 函数不负责 destStream 资源的释放，调用方需自行管理该输出流的生命周期。

参数：

- fromDir!: String - 待归档的目录路径。

- destStream!: T - 归档后数据的输出流。

- includeBaseDirectory!: Bool - 是否包含根目录。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 归档时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = "./test_dir"
    let testFile = Path("./test_dir/test.txt")
    let testFileStream = Path("./test_archive_string_stream.tar")

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建输出流
    let outputStream = File(testFileStream, Write)

    // 使用字符串路径将目录归档到输出流
    Tar.archive(fromDir: testDir, destStream: outputStream, includeBaseDirectory: true)

    println("使用字符串路径归档到输出流成功")

    // 清理测试文件
    outputStream.close()
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)
    removeIfExists(testFileStream)
}
```

运行结果：

```text
使用字符串路径归档到输出流成功
```

### static func extract(Path, Path, Bool)

```cangjie
public static func extract(fromTar!: Path, destDir!: Path, overwrite!: Bool): Unit
```

功能：将 .tar 文件提取至指定目录。

参数：

- fromTar!: Path - 待提取的 .tar 文件路径。

- destDir!: Path - 提取目标目录。

- overwrite!: Bool - 若为 true，允许覆盖已存在文件、目录；否则遇到重名文件、目录将抛出异常。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 提取时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = Path("./test_dir")
    let testFile = Path("./test_dir/test.txt")

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 归档目录
    let archiveFile = Path("./test_archive.tar")
    Tar.archive(fromDir: testDir, destFile: archiveFile, includeBaseDirectory: false)

    println("tar 归档成功")
    println("归档文件: ${archiveFile}")

    // 删除源文件
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)

    // 解压目录
    Tar.extract(fromTar: archiveFile, destDir: testDir, overwrite: true)
    println("tar 解压成功")
    println("解压目录: ${testDir}")

    // 清理测试文件和目录
    removeIfExists(testDir, recursive: true)
    removeIfExists(archiveFile)
}
```

运行结果：

```text
tar 归档成功
归档文件: ./test_archive.tar
tar 解压成功
解压目录: ./test_dir
```

### static func extract(String, String, Bool)

```cangjie
public static func extract(fromTar!: String, destDir!: String, overwrite!: Bool): Unit
```

功能：将 .tar 文件提取至指定目录。

参数：

- fromTar!: String - 待提取的 .tar 文件路径。

- destDir!: String - 提取目标目录。

- overwrite!: Bool - 若为 true，允许覆盖已存在文件、目录；否则遇到重名文件、目录将抛出异常。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 提取时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = "./test_dir"
    let testFile = Path("./test_dir/test.txt")

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 归档目录
    let archiveFile = "./test_archive.tar"
    Tar.archive(fromDir: testDir, destFile: archiveFile, includeBaseDirectory: false)

    println("tar 归档成功")
    println("归档文件: ${archiveFile}")

    // 删除源文件
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)

    // 解压目录
    Tar.extract(fromTar: archiveFile, destDir: testDir, overwrite: true)
    println("tar 解压成功")
    println("解压目录: ${testDir}")

    // 清理测试文件和目录
    removeIfExists(testDir, recursive: true)
    removeIfExists(archiveFile)
}
```

运行结果：

```text
tar 归档成功
归档文件: ./test_archive.tar
tar 解压成功
解压目录: ./test_dir
```

### static func extract\<T>(T, Path, Bool) where T <: InputStream

```cangjie
public static func extract<T>(fromStream!: T, destDir!: Path, overwrite!: Bool): Unit where T <: InputStream
```

功能：将 .tar 数据从输入流中读取并提取至指定目录。

参数：

- fromStream!: T - 待提取的 .tar 数据输入流。

- destDir!: Path - 提取目标目录。

- overwrite!: Bool - 若为 true，允许覆盖已存在文件、目录；否则遇到重名文件、目录将抛出异常。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 提取时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = Path("./test_dir")
    let testFile = Path("./test_dir/test.txt")
    let testFileStream = Path("./test_archive_string_stream.tar")

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建输出流
    let outputStream = File(testFileStream, Write)

    // 将目录归档到输出流
    Tar.archive(fromDir: testDir, destStream: outputStream, includeBaseDirectory: false)

    println("归档到输出流成功")

    // 清理测试文件
    outputStream.close()
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)

    // 创建输入流
    let inputStream = File(testFileStream, Read)
    // 提取目录
    Tar.extract(fromStream: inputStream, destDir: testDir, overwrite: true)

    println("提取目录: ${testDir}")
    println("提取完成")

    // 清理测试文件和目录
    removeIfExists(testDir, recursive: true)
    removeIfExists(testFileStream)
}
```

运行结果：

```text
归档到输出流成功
提取目录: ./test_dir
提取完成
```

### static func extract\<T>(T, String, Bool) where T <: InputStream

```cangjie
public static func extract<T>(fromStream!: T, destDir!: String, overwrite!: Bool): Unit where T <: InputStream
```

功能：将 .tar 数据从输入流中读取并提取至指定目录。

参数：

- fromStream!: T - 待提取的 .tar 数据输入流。

- destDir!: String - 提取目标目录。

- overwrite!: Bool - 若为 true，允许覆盖已存在文件、目录；否则遇到重名文件、目录将抛出异常。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 tar 提取时发生错误，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 设定测试路径
    let testDir = "./test_dir"
    let testFile = Path("./test_dir/test.txt")
    let testFileStream = Path("./test_archive_string_stream.tar")

    // 创建测试目录和文件
    removeIfExists(testDir, recursive: true)
    Directory.create(testDir)
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建输出流
    let outputStream = File(testFileStream, Write)

    // 将目录归档到输出流
    Tar.archive(fromDir: testDir, destStream: outputStream, includeBaseDirectory: false)

    println("归档到输出流成功")

    // 清理测试文件
    outputStream.close()
    removeIfExists(testFile)
    removeIfExists(testDir, recursive: true)

    // 创建输入流
    let inputStream = File(testFileStream, Read)
    // 提取目录
    Tar.extract(fromStream: inputStream, destDir: testDir, overwrite: true)

    println("提取目录: ${testDir}")
    println("提取完成")

    // 清理测试文件和目录
    removeIfExists(testDir, recursive: true)
    removeIfExists(testFileStream)
}
```

运行结果：

```text
归档到输出流成功
提取目录: ./test_dir
提取完成
```

## class TarEntry

```cangjie
public abstract class TarEntry {
    protected init(path: String)
    protected init(path: Path)
}
```

功能：表示一个 tar 文件中的条目，用于和 [TarReader](tar_package_classes.md#class-tarreadert) 和 [TarWriter](tar_package_classes.md#class-tarwritert) 进行交互。可从 [TarReader](tar_package_classes.md#class-tarreadert) 中获取 [TarEntry](tar_package_classes.md#class-tarentry) 实例，表示 tar 归档文件中的一个条目。也可通过 [TarWriter](tar_package_classes.md#class-tarwritert) 将其写入到 tar 归档文件中。

### prop entryType

```cangjie
public prop entryType: TarEntryType
```

功能：获取当前条目的条目类型。

类型：[TarEntryType](tar_package_enums.md#enum-tarentrytype)

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    // 获取 entryType 属性
    let entryType = entry.entryType
    println("条目类型: ${entryType}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
条目类型: TarEntryType.RegularFile
```

### prop linkName

```cangjie
public prop linkName: String
```

功能：获取当前条目的链接名称。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    var symlinkPath = "./test_symlink_target.txt"
    var sourcePath = "./test_symlink_source.txt"
    // 创建前先删除，以防创建失败
    removeIfExists(sourcePath)
    removeIfExists(symlinkPath)

    // 创建一个源文件
    var data: Array<Byte> = [83, 121, 109, 98, 111, 108, 105, 99, 76, 105, 110, 107]
    File.writeTo(sourcePath, data)

    // 创建符号链接
    SymbolicLink.create(symlinkPath, to: sourcePath)

    // 检查符号链接文件是否存在
    if (exists(symlinkPath)) {
        println("符号链接文件存在")
        // 读取符号链接文件内容
        let content = File.readFrom(symlinkPath)
        println("符号链接文件内容: ${content}")
    }

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(symlinkPath)

    // 获取 linkName 属性
    let linkName = entry.linkName
    println("链接名称: ${linkName}")

    // 删除文件
    removeIfExists(sourcePath)
    removeIfExists(symlinkPath)
}
```

运行结果：

```text
符号链接文件存在
符号链接文件内容: [83, 121, 109, 98, 111, 108, 105, 99, 76, 105, 110, 107]
链接名称: test_symlink_source.txt
```

### prop gid

```cangjie
public mut prop gid: Int32
```

功能：获取当前条目的组 ID。

类型：Int32

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    // 获取 gid 属性
    let gid = entry.gid
    println("组ID: ${gid}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

可能的运行结果：

```text
组ID: 1000
```

### prop mode

```cangjie
public mut prop mode: Int32
```

功能：获取当前条目的权限模式。

类型：Int32

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    // 获取 mode 属性
    let mode = entry.mode
    println("权限模式: ${mode}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

可能的运行结果：

```text
权限模式: 420
```

### prop modificationTime

```cangjie
public prop modificationTime: DateTime
```

功能：获取当前条目的最后修改时间。

类型：DateTime

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    // 获取 modificationTime 属性
    let modTime = entry.modificationTime
    println("最后修改时间: ${modTime}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

可能的运行结果：

```text
最后修改时间: 2025-12-23T03:20:02Z
```

### prop checksum

```cangjie
public prop checksum: Int32
```

功能：获取当前条目的校验和。

类型：Int32

> **说明：**
>
> checksum 值根据文件路径、权限、修改时间等元数据动态计算，每次运行结果可能不同。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test_checksum.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 使用 TarWriter 写入 tar 文件
    let tarFile = Path("./test.tar")
    let outStream = File(tarFile, Write)
    var writer = TarWriter(outStream)
    var entry: TarEntry = PaxTarEntry(testFile)
    writer.write(entry)
    writer.finish()
    outStream.close()

    // 从 tar 文件读取 TarEntry 并获取 checksum
    let inStream = File(tarFile, Read)
    var reader = TarReader(inStream)
    for (tarEntry in reader) {
        println("校验和: ${tarEntry.checksum}")
    }
    inStream.close()

    // 清理测试文件
    removeIfExists(testFile)
    removeIfExists(tarFile)
}
```

可能的运行结果：

```text
校验和: 6681
```

### prop name

```cangjie
public mut prop name: String
```

功能：获取当前条目的文件名。

类型：String

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    // 获取 name 属性
    let name = entry.name
    println("文件名: ${name}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

可能的运行结果：

```text
文件名: test.txt
```

### prop size

```cangjie
public prop size: Int64
```

功能：获取当前条目的大小。

类型：Int64

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    // 获取 size 属性
    let size = entry.size
    println("大小: ${size}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
大小: 11
```

### prop stream

```cangjie
public prop stream: ?InputStream
```

功能：获取当前条目的输入流。如果实例由 [TarReader](tar_package_classes.md#class-tarreadert) 创建，则本属性返回流中为条目的数据，若条目没有数据则返回 None。如果实例由构造函数创建，则本属性返回的是创建的文件流，传入 [TarWriter](tar_package_classes.md#class-tarwritert) 时会调用该属性用于写入条目数据。

类型：Option\<InputStream>

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    // 获取 stream 属性
    let stream = entry.stream

    // 清理测试文件
    removeIfExists(testFile)
}
```

### prop uid

```cangjie
public mut prop uid: Int32
```

功能：获取当前条目的用户 ID。

类型：Int32

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    // 获取 uid 属性
    let uid = entry.uid
    println("用户ID: ${uid}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

可能的运行结果：

```text
用户ID: 1000
```

### init(Path)

```cangjie
protected init(path: Path)
```

功能：从文件、目录、软链接构造一个 tar 文件条目。

参数：

- path: Path - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 使用 Path 参数构造一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    println("TarEntry 使用 Path 构造成功")
    println("文件名: ${entry.name}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
TarEntry 使用 Path 构造成功
文件名: test.txt
```

### init(String)

```cangjie
protected init(path: String)
```

功能：从文件、目录、软链接构造一个 tar 文件条目。

参数：

- path: String - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = "./test.txt"
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 使用 String 参数构造一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    println("TarEntry 使用 String 构造成功")
    println("文件名: ${entry.name}")

    // 清理测试文件
    removeIfExists(testFile)
}
```

运行结果：

```text
TarEntry 使用 String 构造成功
文件名: test.txt
```

### func writeTo(OutputStream)

```cangjie
public open func writeTo(target: OutputStream): Unit
```

功能：将当前条目写入到指定的输出流中。

参数：

- target: OutputStream - 指定输出流。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果字段超出格式要求或写入失败，则抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建一个 TarEntry 实例 (使用 PaxTarEntry，因为 TarEntry 是抽象类)
    var entry: TarEntry = PaxTarEntry(testFile)

    // 创建输出流和 TarWriter
    let outputFile = Path("./output.tar")
    let outputStream = File(outputFile, Write)
    var writer = TarWriter(outputStream)

    // 写入条目
    writer.write(entry)
    writer.finish()

    // 清理流和文件
    outputStream.close()

    // 清理测试文件
    removeIfExists(testFile)
    removeIfExists(outputFile)
}
```

## class TarReader\<T>

```cangjie
public class TarReader<T> <: Iterable<TarEntry> where T <: InputStream {
    public init(stream: T)
}
```

功能：从流中按照 tar 格式读取条目。

### init(T)

```cangjie
public init(stream: T)
```

功能：从指定的流中创建一个 tar 文件读取器。

参数：

- stream: T - 指定的输入流。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.process.*

main(): Unit {
    // 设定路径
    let testFile01 = "./testFile01.txt"
    let testFile02 = "./testFile02.txt"
    let testTar = "./test.tar"

    // 创建测试文件
    File.writeTo(testFile01, "文件数据...123".toArray())
    File.writeTo(testFile02, "文件数据...123456".toArray())

    // 创建 tar 文件，执行命令 "tar -cf test.tar testFile.txt"
    executeWithOutput("tar", ["-cf", testTar, testFile01, testFile02])

    // 创建一个 TarReader 实例
    let fileStream = File(testTar, Read)
    var reader = TarReader(fileStream)

    println("TarReader 创建成功")

    // 清理测试文件
    fileStream.close()
    removeIfExists(testFile01)
    removeIfExists(testFile02)
}
```

运行结果：

```text
TarReader 创建成功
```

### func iterator()

```cangjie
public func iterator(): Iterator<TarEntry>
```

功能：返回一个迭代器，迭代 tar 文件中的条目。

返回值：

- Iterator\<TarEntry> - 一个 [TarEntry](tar_package_classes.md#class-tarentry) 的迭代器。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.process.*

main(): Unit {
    // 设定路径
    let testFile01 = "./testFile01.txt"
    let testFile02 = "./testFile02.txt"
    let testTar = "./test.tar"

    // 创建测试文件
    File.writeTo(testFile01, "文件数据...123".toArray())
    File.writeTo(testFile02, "文件数据...123456".toArray())

    // 创建 tar 文件，执行命令 "tar -cf test.tar testFile.txt"
    executeWithOutput("tar", ["-cf", testTar, testFile01, testFile02])

    // 创建一个 TarReader 实例
    let fileStream = File(testTar, Read)
    var reader = TarReader(fileStream)

    // 获取迭代器
    var iterator = reader.iterator()

    for (entry in iterator) {
        println("条目名称: ${entry.name}")
        println("条目大小: ${entry.size}")
    }
    // 清理测试文件
    fileStream.close()
    removeIfExists(testFile01)
    removeIfExists(testFile02)
}
```

运行结果：

```text
条目名称: testFile01.txt
条目大小: 18
条目名称: testFile02.txt
条目大小: 21
```

### extend\<T> TarReader\<T> <: Resource where T <: Resource

```cangjie
extend<T> TarReader<T> <: Resource where T <: Resource
```

功能：为 [TarReader](tar_package_classes.md#class-tarreadert) 实现 Resource 接口，该类型对象可在 `try-with-resource` 语法上下文中实现自动资源释放。

父类型：

- Resource

#### func close()

```cangjie
public func close(): Unit
```

功能：关闭内部流。

> **注意：**
>
> 调用此方法后不可再调用 [TarReader](tar_package_classes.md#class-tarreadert) 的其他接口，否则会造成不可期现象。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.InputStream
import std.process.*

main(): Unit {
    // 设定路径
    let testFile01 = "./testFile01.txt"
    let testFile02 = "./testFile02.txt"
    let testTar = "./test.tar"

    // 创建测试文件
    File.writeTo(testFile01, "文件数据...123".toArray())
    File.writeTo(testFile02, "文件数据...123456".toArray())

    // 创建 tar 文件，执行命令 "tar -cf test.tar testFile.txt"
    executeWithOutput("tar", ["-cf", testTar, testFile01, testFile02])

    // 创建一个 TarReader 实例
    let fileStream = File(testTar, Read)
    var reader = TarReader(fileStream)

    // 关闭 TarReader
    reader.close()

    println("TarReader 关闭成功")

    // 清理测试文件
    removeIfExists(testFile01)
    removeIfExists(testFile02)
}
```

运行结果：

```text
TarReader 关闭成功
```

#### func isClosed()

```cangjie
public func isClosed(): Bool
```

功能：判断内部流是否关闭。

返回值：

- Bool - 如果内部流已经被关闭，返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.InputStream
import std.process.*

main(): Unit {
    // 设定路径
    let testFile01 = "./testFile01.txt"
    let testFile02 = "./testFile02.txt"
    let testTar = "./test.tar"

    // 创建测试文件
    File.writeTo(testFile01, "文件数据...123".toArray())
    File.writeTo(testFile02, "文件数据...123456".toArray())

    // 创建 tar 文件，执行命令 "tar -cf test.tar testFile.txt"
    executeWithOutput("tar", ["-cf", testTar, testFile01, testFile02])

    // 创建一个 TarReader 实例
    let fileStream = File(testTar, Read)
    var reader = TarReader(fileStream)

    // 检查是否已关闭
    let isClosedBefore = reader.isClosed()
    println("关闭前状态: ${isClosedBefore}")

    // 关闭 TarReader
    reader.close()

    // 再次检查是否已关闭
    let isClosedAfter = reader.isClosed()
    println("关闭后状态: ${isClosedAfter}")

    // 清理测试文件
    removeIfExists(testFile01)
    removeIfExists(testFile02)
}
```

运行结果：

```text
关闭前状态: false
关闭后状态: true
```

## class TarWriter\<T>

```cangjie
public class TarWriter<T> where T <: OutputStream {
    public init(stream: T)
    public init(stream: T, format: TarEntryFormat)
}
```

功能：将条目写入到流中，并完成 tar 文件的写入。

### prop format

```cangjie
public prop format: TarEntryFormat
```

功能：获取当前 tar 文件的条目格式。

类型：[TarEntryFormat](tar_package_enums.md#enum-tarentryformat)

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建输出流
    let outputFile = Path("./test.tar")
    let outputStream = File(outputFile, Write)

    // 创建一个 TarWriter 实例
    var writer = TarWriter(outputStream)

    // 获取 format 属性
    let format = writer.format
    println("TarWriter 格式: ${format}")

    // 清理资源
    writer.close()

    // 清理测试文件
    removeIfExists(outputFile)
}
```

运行结果：

```text
TarWriter 格式: TarEntryFormat.Pax
```

### init(T)

```cangjie
public init(stream: T)
```

功能：从指定的流中创建一个 tar 文件写入器，默认为 Pax 格式。

参数：

- stream: T - 指定的输出流。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建输出流
    let outputFile = Path("./test.tar")
    let outputStream = File(outputFile, Write)

    // 创建一个 TarWriter 实例（使用默认格式）
    var writer = TarWriter(outputStream)

    println("TarWriter 创建成功")

    // 清理资源
    writer.close()

    // 清理测试文件
    removeIfExists(outputFile)
}
```

运行结果：

```text
TarWriter 创建成功
```

### init(T, TarEntryFormat)

```cangjie
public init(stream: T, format: TarEntryFormat)
```

功能：从指定的流中创建一个 tar 文件写入器。

参数：

- stream: T - 指定的输出流。

- format: [TarEntryFormat](tar_package_enums.md#enum-tarentryformat) - tar 文件的条目格式。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建输出流
    let outputFile = Path("./test.tar")
    let outputStream = File(outputFile, Write)

    // 创建一个 TarWriter 实例（指定格式）
    var writer = TarWriter(outputStream, TarEntryFormat.Gnu)

    println("TarWriter 指定格式创建成功")
    println("格式: ${writer.format}")

    // 清理资源
    writer.close()

    // 清理测试文件
    removeIfExists(outputFile)
}
```

运行结果：

```text
TarWriter 指定格式创建成功
格式: TarEntryFormat.Gnu
```

### func finish()

```cangjie
public func finish(): Unit
```

功能：写入 tar 结尾标志，即 1024 个空字节，结束 tar 格式的写入。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果写入已结束，或者写入失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 TarWriter
    let outFile = File("./test.tar", ReadWrite)
    var writer = TarWriter(outFile)

    // 写入文件
    writer.write(testFile, entryName: "test_entry.txt")
    println("File size before finish: ${outFile.info.size}")
    writer.finish()
    println("File size after finish: ${outFile.info.size}")

    // 清理测试文件
    writer.close()
    removeIfExists(testFile)
    removeIfExists("./test.tar")
}
```

运行结果：

```text
File size before finish: 1024
File size after finish: 2048
```

### func flush()

```cangjie
public func flush(): Unit
```

功能：刷新内部流。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果写入已结束（调用 [finish()](#func-flush) 之后），则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建输出流
    let outputFile = Path("./test.tar")
    let outputStream = File(outputFile, Write)

    // 创建一个 TarWriter 实例
    var writer = TarWriter(outputStream)

    // 刷新内部流
    writer.flush()

    println("TarWriter flush() 调用成功")

    // 清理资源
    writer.close()

    // 清理测试文件
    removeIfExists(outputFile)
}
```

运行结果：

```text
TarWriter flush() 调用成功
```

### func write(FileInfo, String)

```cangjie
public func write(info: FileInfo, entryName!: String): Unit
```

功能：将指定文件、目录、软链接写入到内部流中。

参数：

- info: FileInfo - 待写入的文件、目录、软链接信息。

- entryName!: String - tar 文件中的条目名。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果写入已结束，或者创建或写入条目失败，则抛出异常。

- FSException - 如果创建文件流失败，则抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())
    let file = File(testFile, Read)

    // 创建 TarWriter
    let outFile = File("./test.tar", ReadWrite)
    var writer = TarWriter(outFile)

    // 通过文件信息info写入文件
    writer.write(file.info, entryName: "test_entry.txt")
    writer.finish()

    // 清理测试文件
    writer.close()
    removeIfExists(testFile)
    removeIfExists("./test.tar")
}
```

### func write(Iterable\<TarEntry>)

```cangjie
public func write(it: Iterable<TarEntry>): Unit
```

功能：将指定 tar 文件条目列表写入到内部流中。

参数：

- it: Iterable\<[TarEntry](tar_package_classes.md#class-tarentry)> - 待写入的 tar 文件条目列表。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果写入已结束，或者写入条目失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.collection.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建输出流
    let outputFile = Path("./test.tar")
    let outputStream = File(outputFile, Write)

    // 创建一个 TarWriter 实例
    var writer = TarWriter(outputStream)

    // 创建 TarEntry 列表
    var entry = PaxTarEntry(testFile)
    var entries = ArrayList<TarEntry>()
    entries.add(entry)

    // 写入 TarEntry 列表
    writer.write(entries)

    println("write(Iterable<TarEntry>) 调用成功，写入了 ${outputFile}")

    // 清理资源
    writer.finish()
    writer.close()

    // 清理测试文件
    removeIfExists(testFile)
    removeIfExists(outputFile)
}
```

运行结果：

```text
write(Iterable<TarEntry>) 调用成功，写入了 ./test.tar
```

### func write(Path, String)

```cangjie
public func write(path: Path, entryName!: String): Unit
```

功能：将指定文件、目录、软链接写入到内部流中。

参数：

- path: Path - 指定文件、目录、软链接路径。

- entryName!: String - tar 文件中的条目名。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果写入已结束，或者创建或写入条目失败，则抛出异常。

- FSException - 如果创建文件流失败，则抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 TarWriter
    let outFile = File("./test.tar", ReadWrite)
    var writer = TarWriter(outFile)

    // 通过路径写入文件
    writer.write(testFile, entryName: "test_entry.txt")
    writer.finish()

    // 清理测试文件
    writer.close()
    removeIfExists(testFile)
    removeIfExists("./test.tar")
}
```

### func write(String, String)

```cangjie
public func write(path!: String, entryName!: String): Unit
```

功能：将指定文件、目录、软链接写入到内部流中。

参数：

- path!: String - 指定文件、目录、软链接的路径。

- entryName!: String - tar 文件中的条目名。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果写入已结束，或者创建或写入条目失败，则抛出异常。

- FSException - 如果创建文件流失败，则抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建测试文件
    let testFile = "./test.txt"
    File.writeTo(Path(testFile), "Hello, Tar!".toArray())

    // 创建 TarWriter 并写入文件
    let outFile = File("./test.tar", Write)
    var writer = TarWriter(outFile)

    // 通过路径字符串写入
    writer.write(path: testFile, entryName: "test_entry.txt")
    writer.finish()

    // 清理测试文件
    writer.close()
    removeIfExists(testFile)
    removeIfExists("./test.tar")
}
```

### func write(TarEntry)

```cangjie
public func write(entry: TarEntry): Unit
```

功能：将指定 tar 文件条目写入到内部流中。

参数：

- entry: [TarEntry](tar_package_classes.md#class-tarentry) - 待写入的 tar 文件条目。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果写入已结束，或者写入条目失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建输出流
    let outputFile = Path("./test.tar")
    let outputStream = File(outputFile, Write)

    // 创建一个 TarWriter 实例
    var writer = TarWriter(outputStream)

    // 创建一个 TarEntry
    var entry = PaxTarEntry(testFile)

    // 写入 TarEntry
    writer.write(entry)

    println("TarWriter write(TarEntry) 调用成功")

    // 清理资源
    writer.finish()
    writer.close()

    // 清理测试文件
    removeIfExists(testFile)
    removeIfExists(outputFile)
}
```

运行结果：

```text
TarWriter write(TarEntry) 调用成功
```

### extend\<T> TarWriter\<T> <: Resource where T <: Resource

```cangjie
extend<T> TarWriter<T> <: Resource where T <: Resource
```

功能：为 [TarWriter](tar_package_classes.md#class-tarwritert) 实现 Resource 接口，该类型对象可在 `try-with-resource` 语法上下文中实现自动资源释放。

父类型：

- Resource

#### func close()

```cangjie
public func close(): Unit
```

功能：写入 tar 结尾标志，并关闭内部流。

> **注意：**
>
> 调用此方法后不可再调用 [TarWriter](tar_package_classes.md#class-tarwritert) 的其他接口，否则会造成不可期现象。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建输出流
    let outputFile = Path("./test.tar")
    let outputStream = File(outputFile, Write)

    // 创建一个 TarWriter 实例
    var writer = TarWriter(outputStream)

    // 关闭 TarWriter
    writer.close()

    println("TarWriter close() 调用成功")

    // 清理测试文件
    removeIfExists(outputFile)
}
```

运行结果：

```text
TarWriter close() 调用成功
```

#### func isClosed()

```cangjie
public func isClosed(): Bool
```

功能：判断内部流是否关闭。

返回值：

- Bool - 如果内部流已经被关闭，返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建输出流
    let outputFile = Path("./test.tar")
    let outputStream = File(outputFile, Write)

    // 创建一个 TarWriter 实例
    var writer = TarWriter(outputStream)

    // 检查是否已关闭
    let isClosedBefore = writer.isClosed()
    println("关闭前状态: ${isClosedBefore}")

    // 关闭 TarWriter
    writer.close()

    // 再次检查是否已关闭
    let isClosedAfter = writer.isClosed()
    println("关闭后状态: ${isClosedAfter}")

    // 清理测试文件
    removeIfExists(outputFile)
}
```

运行结果：

```text
关闭前状态: false
关闭后状态: true
```

## class UstarTarEntry

```cangjie
public class UstarTarEntry <: PosixTarEntry {
    public init(path: String)
    public init(path: Path)
}
```

功能：表示 Ustar tar 文件条目。

父类型：

- [PosixTarEntry](#class-posixtarentry)

### init(Path)

```cangjie
public init(path: Path)
```

功能：从文件、目录、软链接构造一个 Ustar tar 文件条目。

参数：

- path: Path - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 UstarTarEntry
    var ustarEntry = UstarTarEntry(testFile)

    println("UstarTarEntry created successfully")
    println("Entry name: ${ustarEntry.name}")
    println("Entry size: ${ustarEntry.size}")

    // 清理测试文件
    remove(testFile)
}
```

运行结果：

```text
UstarTarEntry created successfully
Entry name: test.txt
Entry size: 11
```

### init(String)

```cangjie
public init(path: String)
```

功能：从文件、目录、软链接构造一个 Ustar tar 文件条目。

参数：

- path: String - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = "./test.txt"
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 UstarTarEntry
    var ustarEntry = UstarTarEntry(testFile)

    println("UstarTarEntry created successfully from string path")
    println("Entry name: ${ustarEntry.name}")
    println("Entry size: ${ustarEntry.size}")

    // 清理测试文件
    remove(testFile)
}
```

运行结果：

```text
UstarTarEntry created successfully from string path
Entry name: test.txt
Entry size: 11
```

### func writeTo(OutputStream)

```cangjie
public override func writeTo(target: OutputStream): Unit
```

功能：将当前条目写入到指定的输出流中。

参数：

- target: OutputStream - 指定输出流。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果字段超出格式要求或写入失败，则抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.tar.*
import std.fs.*
import std.io.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 UstarTarEntry
    var entry = UstarTarEntry(testFile)

    // 创建输出流和 TarWriter
    let outFile = File("./output.tar", Write)
    var writer = TarWriter(outFile)

    // 将条目写入 tar 文件
    writer.write(entry)
    writer.finish()

    // 清理文件
    outFile.close()
    remove(testFile)
    remove("./output.tar")
}
```

## class V7TarEntry

```cangjie
public class V7TarEntry <: TarEntry {
    public init(path: String)
    public init(path: Path)
}
```

功能：表示 V7 tar 文件条目。

父类型：

- [TarEntry](#class-tarentry)

### init(Path)

```cangjie
public init(path: Path)
```

功能：从文件、目录、软链接构造一个 V7 tar 文件条目。

参数：

- path: Path - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = Path("./test.txt")
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 V7TarEntry
    var v7Entry = V7TarEntry(testFile)

    println("V7TarEntry created successfully")
    println("Entry name: ${v7Entry.name}")
    println("Entry size: ${v7Entry.size}")

    // 清理测试文件
    remove(testFile)
}
```

运行结果：

```text
V7TarEntry created successfully
Entry name: test.txt
Entry size: 11
```

### init(String)

```cangjie
public init(path: String)
```

功能：从文件、目录、软链接构造一个 V7 tar 文件条目。

参数：

- path: String - 文件、目录、软链接的路径。

异常：

- [TarException](tar_package_exceptions.md#class-tarexception) - 如果 path 参数指定的目标不存在或不是文件、目录、软链接，则抛出异常。

- FSException - 如果读取目标信息或创建目标文件流失败，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.tar.*
import std.fs.*

main(): Unit {
    // 创建测试文件
    let testFile = "./test.txt"
    File.writeTo(testFile, "Hello, Tar!".toArray())

    // 创建 V7TarEntry
    var v7Entry = V7TarEntry(testFile)

    println("V7TarEntry created successfully from string path")
    println("Entry name: ${v7Entry.name}")
    println("Entry size: ${v7Entry.size}")

    // 清理测试文件
    remove(testFile)
}
```

运行结果：

```text
V7TarEntry created successfully from string path
Entry name: test.txt
Entry size: 11
```
