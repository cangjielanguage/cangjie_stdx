# 类

## class CompressInputStream

```cangjie
public class CompressInputStream <: InputStream {
    public init(inputStream: InputStream, wrap!: WrapType = DeflateFormat, compressLevel!: CompressLevel = DefaultCompression, bufLen!: Int64 = 512)
}
```

功能：压缩输入流。

可将 [CompressInputStream](zlib_package_classes.md#class-compressinputstream) 实例通过构造函数绑定到任意 InputStream 类型输入流，通过循环调用 read(outBuf: Array\<Byte>) 函数，将该输入流中的数据压缩，并将压缩后的数据输出到传入的字节数组。

父类型：

- InputStream

### init(InputStream, WrapType, CompressLevel, Int64)

```cangjie
public init(inputStream: InputStream, wrap!: WrapType = DeflateFormat, compressLevel!: CompressLevel = DefaultCompression, bufLen!: Int64 = 512)
```

功能：构造一个压缩输入流。

需绑定一个输入流，可设置压缩数据格式、压缩等级、内部缓冲区大小（每次从输入流中读取多少数据进行压缩）。

参数：

- inputStream: InputStream - 待压缩的输入流。
- wrap!: [WrapType](zlib_package_enums.md#enum-wraptype) - 压缩数据格式，默认值为 [DeflateFormat](zlib_package_enums.md#deflateformat)。
- compressLevel!: [CompressLevel](zlib_package_enums.md#enum-compresslevel) - 压缩等级，默认值为 [DefaultCompression](zlib_package_enums.md#defaultcompression)。
- bufLen!: Int64 - 输入流缓冲区的大小，取值范围为 (0, Int64.Max]，默认 512 字节。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 当 `bufLen` 小于等于 0，输入流分配内存失败，或压缩资源初始化失败，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()
    let byteBuffer = ByteBuffer(arr1)
    let bufferedInputStream = BufferedInputStream(byteBuffer)
    var compressInputStream: CompressInputStream = CompressInputStream(bufferedInputStream)
    compressInputStream.close()
}
```

### func close()

```cangjie
public func close(): Unit
```

功能：关闭压缩输入流。

当前 [CompressInputStream](zlib_package_classes.md#class-compressinputstream) 实例使用完毕后必须调用此函数来释放其所占内存资源，以免造成内存泄漏。调用该函数前需确保 [read](./zlib_package_classes.md#func-readarraybyte) 函数已返回 0，否则可能导致绑定的 InputStream 并未被全部压缩。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果释放压缩资源失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()
    let byteBuffer = ByteBuffer(arr1)
    let bufferedInputStream = BufferedInputStream(byteBuffer)
    var compressInputStream: CompressInputStream = CompressInputStream(bufferedInputStream)
    // 使用压缩输入流进行一些操作
    var arr: Array<Byte> = Array<Byte>(1024, repeat: 0)
    var len = compressInputStream.read(arr)
    println("Read ${len} bytes.")
    // 关闭压缩输入流
    compressInputStream.close()
}
```

运行结果：

```text
Read 18 bytes.
```

### func read(Array\<Byte>)

```cangjie
public func read(outBuf: Array<Byte>): Int64
```

功能：从绑定的输入流中读取数据并压缩，压缩后数据放入指定的字节数组中。

参数：

- outBuf: Array\<Byte> - 用来存放压缩后数据的缓冲区。

返回值：

- Int64 - 如果压缩成功，返回压缩后字节数，如果绑定的输入流中数据已经全部压缩完成，或者该压缩输入流被关闭，返回 0。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 当 `outBuf` 为空，或压缩数据失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()
    let byteBuffer = ByteBuffer(arr1)
    let bufferedInputStream = BufferedInputStream(byteBuffer)
    var compressInputStream: CompressInputStream = CompressInputStream(bufferedInputStream)
    var arr: Array<Byte> = Array<Byte>(1024, repeat: 0)
    println("原始数据长度: ${arr1.size}")
    var len = compressInputStream.read(arr)
    println("压缩后的数据长度: ${len}")
    compressInputStream.close()
}
```

运行结果：

```text
原始数据长度: 65
压缩后的数据长度: 18
```

## class CompressOutputStream

```cangjie
public class CompressOutputStream <: OutputStream {
    public init(outputStream: OutputStream, wrap!: WrapType = DeflateFormat, compressLevel!: CompressLevel = DefaultCompression, bufLen!: Int64 = 512)
}
```

功能：压缩输出流。

可将 [CompressOutputStream](zlib_package_classes.md#class-compressoutputstream) 实例通过构造函数绑定到任意 OutputStream 类型输出流，调用 write(inBuf: Array\<Byte>) 函数读取、压缩指定字节数组中的数据，并将压缩后的数据输出到绑定的输出流。

父类型：

- OutputStream

### init(OutputStream, WrapType, CompressLevel, Int64)

```cangjie
public init(outputStream: OutputStream, wrap!: WrapType = DeflateFormat, compressLevel!: CompressLevel = DefaultCompression, bufLen!: Int64 = 512)
```

功能：构造一个压缩输出流，需绑定一个输出流，可设置压缩数据类型、压缩等级、内部缓冲区大小（每得到多少压缩后数据往输出流写出）。

参数：

- outputStream: OutputStream - 绑定的输出流，压缩后数据将写入该输出流。
- wrap!: [WrapType](zlib_package_enums.md#enum-wraptype) - 压缩数据格式，默认值为 [DeflateFormat](zlib_package_enums.md#deflateformat)。
- compressLevel!: [CompressLevel](zlib_package_enums.md#enum-compresslevel) - 压缩等级，默认值为 [DefaultCompression](zlib_package_enums.md#defaultcompression)。
- bufLen!: Int64 - 输出流缓冲区的大小，取值范围为 (0, Int64.Max]，默认 512 字节。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果 `bufLen` 小于等于 0，输出流分配内存失败，或压缩资源初始化失败，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    var byteBuffer = ByteBuffer()
    var compressOutputStream: CompressOutputStream = CompressOutputStream(byteBuffer, wrap: GzipFormat,
        compressLevel: BestCompression, bufLen: 1024)
    compressOutputStream.close()
}
```

### func close()

```cangjie
public func close(): Unit
```

功能：关闭当前压缩输出流实例。

关闭时，将写入剩余压缩数据（包括缓冲区中数据，以及压缩尾部信息），并释放其所占内存资源。当前压缩输出流使用完毕后必须调用此函数来释放其所占内存资源，以免造成内存泄漏。在调用 [close](./zlib_package_classes.md#func-close-1) 函数前，绑定的输出流里已写入的数据并不是一段完整的压缩数据，调用 [close](./zlib_package_classes.md#func-close-1) 函数后，才会把剩余压缩数据写入绑定的输出流，使其完整。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果当前压缩输出流已经被关闭，或释放压缩资源失败，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    var byteBuffer = ByteBuffer()
    var compressOutputStream: CompressOutputStream = CompressOutputStream(byteBuffer, bufLen: 39)

    var arr = "Hello, World!Hello, World!Hello, World!".toArray()

    /* 将字节数组压缩后写入压缩输出流的缓冲区 */
    compressOutputStream.write(arr)

    /* 将内部缓冲区里已压缩的数据刷出并写入绑定的输出流，然后刷新绑定的输出流 */
    compressOutputStream.flush()

    /* 关闭压缩输出流 */
    compressOutputStream.close()
}
```

### func flush()

```cangjie
public func flush(): Unit
```

功能：刷新压缩输出流。将内部缓冲区里已压缩的数据刷出并写入绑定的输出流，然后刷新绑定的输出流。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果当前压缩输出流已经被关闭，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    var byteBuffer = ByteBuffer()
    var compressOutputStream: CompressOutputStream = CompressOutputStream(byteBuffer, bufLen: 39)

    var arr = "Hello, World!Hello, World!Hello, World!".toArray()

    /* 将字节数组压缩后写入压缩输出流的缓冲区 */
    compressOutputStream.write(arr)

    /* 将内部缓冲区里已压缩的数据刷出并写入绑定的输出流，然后刷新绑定的输出流 */
    compressOutputStream.flush()

    /* 关闭压缩输出流 */
    compressOutputStream.close()
}
```

### func write(Array\<Byte>)

```cangjie
public func write(inBuf: Array<Byte>): Unit
```

功能：将指定字节数组中的数据进行压缩，并写入输出流，当数据全部压缩完成并写入输出流，函数返回。

参数：

- inBuf: Array\<Byte> - 待压缩的字节数组。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果当前压缩输出流已经被关闭，或压缩数据失败，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    var byteBuffer = ByteBuffer()
    var compressOutputStream: CompressOutputStream = CompressOutputStream(byteBuffer, bufLen: 39)

    var arr = "Hello, World!Hello, World!Hello, World!".toArray()

    /* 将字节数组压缩后写入压缩输出流的缓冲区 */
    compressOutputStream.write(arr)

    /* 将内部缓冲区里已压缩的数据刷出并写入绑定的输出流，然后刷新绑定的输出流 */
    compressOutputStream.flush()

    /* 关闭压缩输出流 */
    compressOutputStream.close()
}
```

## class DecompressInputStream

```cangjie
public class DecompressInputStream <: InputStream {
    public init(inputStream: InputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512)
}
```

功能：解压输入流。

可将 [DecompressInputStream](zlib_package_classes.md#class-decompressinputstream) 实例通过构造函数绑定到任意 InputStream 输入流，通过循环调用 read(outBuf: Array\<Byte>) 函数读取、解压输入流中的数据，并将解压后数据输出到指定字节数组。

父类型：

- InputStream

### init(InputStream, WrapType, Int64)

```cangjie
public init(inputStream: InputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512)
```

功能：构造一个解压输入流。

需绑定一个输入流，可设置待解压数据格式、内部缓冲区大小（每次从输入流中读取多少数据进行解压）。

参数：

- inputStream: InputStream - 待压缩的输入流。
- wrap!: [WrapType](zlib_package_enums.md#enum-wraptype) - 待解压数据格式，默认值为 [DeflateFormat](zlib_package_enums.md#deflateformat)。
- bufLen!: Int64 - 输入流缓冲区的大小，取值范围为 (0, Int64.Max]，默认 512 字节。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果 `bufLen` 小于等于 0，输入流分配内存失败，或待解压资源初始化失败，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()

    /* 使用压缩输入流进行数据压缩 */
    let byteBuffer = ByteBuffer(arr1)
    var compressInputStream: CompressInputStream = CompressInputStream(byteBuffer)
    var arr2: Array<Byte> = Array<Byte>(1024, repeat: 0)
    var len1 = compressInputStream.read(arr2)

    /* 使用解压缩输入流进行数据解压 */
    var decompressInputStream: DecompressInputStream = DecompressInputStream(ByteBuffer(arr2[..len1]), wrap: GzipFormat,
        bufLen: 1024)

    /* 关闭输入流 */
    compressInputStream.close()
    decompressInputStream.close()
}
```

### func close()

```cangjie
public func close(): Unit
```

功能：关闭解压输入流。

当前 [DecompressInputStream](zlib_package_classes.md#class-decompressinputstream) 实例使用完毕后必须调用此函数来释放其所占内存资源，以免造成内存泄漏。调用该函数前需确保 [read](./zlib_package_classes.md#func-readarraybyte-1) 函数已返回 0，否则可能导致绑定的 InputStream 并未被全部解压。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果释放解压资源失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()

    /* 使用压缩输入流进行数据压缩 */
    let byteBuffer = ByteBuffer(arr1)
    var compressInputStream: CompressInputStream = CompressInputStream(byteBuffer)
    var arr2: Array<Byte> = Array<Byte>(1024, repeat: 0)
    var len1 = compressInputStream.read(arr2)

    /* 使用解压缩输入流进行数据解压 */
    var decompressInputStream: DecompressInputStream = DecompressInputStream(ByteBuffer(arr2[..len1]))
    var arr3: Array<Byte> = Array<Byte>(1024, repeat: 0)
    var len2 = decompressInputStream.read(arr3)
    println(String.fromUtf8(arr3[..len2]))

    /* 关闭输入流 */
    compressInputStream.close()
    decompressInputStream.close()
    println("DecompressInputStream closed successfully.")
}
```

运行结果：

```text
Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!
DecompressInputStream closed successfully.
```

### func read(Array\<Byte>)

```cangjie
public func read(outBuf: Array<Byte>): Int64
```

功能：从绑定的输入流中读取数据并解压，解压后数据放入指定的字节数组中。

参数：

- outBuf: Array\<Byte> - 用来存放解压后数据的缓冲区。

返回值：

- Int64 - 如果解压成功，返回解压后字节数，如果绑定的输入流中数据已经全部解压完成，或者该解压输入流被关闭，返回 0。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 当 `outBuf` 为空，解压数据失败，或压缩数据在解压完成前结束（例如压缩数据被截断），抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()

    /* 使用压缩输入流进行数据压缩 */
    let byteBuffer = ByteBuffer(arr1)
    var compressInputStream: CompressInputStream = CompressInputStream(byteBuffer)
    var arr2: Array<Byte> = Array<Byte>(1024, repeat: 0)
    /* 原始数据长度 */
    println("原始数据长度: ${arr1.size}")
    var len1 = compressInputStream.read(arr2)
    /* 压缩后的数据长度 */
    println("压缩后的数据长度: ${len1}")

    /* 使用解压缩输入流进行数据解压 */
    var decompressInputStream: DecompressInputStream = DecompressInputStream(ByteBuffer(arr2[..len1]))
    var arr3: Array<Byte> = Array<Byte>(1024, repeat: 0)
    var len2 = decompressInputStream.read(arr3)
    println("解压后的数据长度: ${len2}")
    println("解压后数据: ${String.fromUtf8(arr3[..len2])}")

    /* 关闭输入流 */
    compressInputStream.close()
    decompressInputStream.close()
}
```

运行结果：

```text
原始数据长度: 65
压缩后的数据长度: 18
解压后的数据长度: 65
解压后数据: Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!
```

## class DecompressOutputStream

```cangjie
public class DecompressOutputStream <: OutputStream {
    public init(outputStream: OutputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512)
}
```

功能：解压输出流。

可将 [DecompressOutputStream](zlib_package_classes.md#class-decompressoutputstream) 实例通过构造函数绑定到指定的 OutputStream 类型输出流，通过调用 write(inBuf: Array\<Byte>) 函数读取、解压指定字节数组中的数据，并将解压后数据输出到绑定的输出流中。

父类型：

- OutputStream

### init(OutputStream, WrapType, Int64)

```cangjie
public init(outputStream: OutputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512)
```

功能：构造一个解压输出流。

需绑定一个输出流，可设置压缩数据类型、压缩等级、内部缓冲区大小（解压后数据会存入内部缓冲区，缓冲区存满后再写到输出流）。

参数：

- outputStream: OutputStream - 绑定的输出流，解压后数据将写入该输出流。
- wrap!: [WrapType](zlib_package_enums.md#enum-wraptype) - 待解压数据格式，默认值为 [DeflateFormat](zlib_package_enums.md#deflateformat)。
- bufLen!: Int64 - 输出流缓冲区的大小，取值范围为 (0, Int64.Max]，默认 512 字节。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果 `bufLen` 小于等于 0，输出流分配内存失败，或解压资源初始化失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.fs.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()

    // 创建一个临时文件用于压缩
    File.writeTo("./temp_input.txt", arr1)

    // 压缩文件
    compressFile("./temp_input.txt", "./temp_compressed.gz")

    // 读取压缩后的数据
    let compressedData = File.readFrom("./temp_compressed.gz")

    /* 使用解压缩输出流进行数据解压后，将数据写入文件，文件的内容为原始数据 */
    var file = File("./file.text", ReadWrite)
    var decompressOutputStream: DecompressOutputStream = DecompressOutputStream(file, wrap: GzipFormat, bufLen: 1024)

    decompressOutputStream.write(compressedData)
    decompressOutputStream.flush()

    /* 关闭输出流和文件 */
    decompressOutputStream.close()

    println("解压后文件数据字节数和压缩前数据字节数是否相等: ${file.length == arr1.size}")
    file.close()

    // 清理临时文件
    removeIfExists("./temp_input.txt")
    removeIfExists("./temp_compressed.gz")
    removeIfExists("./file.text")
}

func compressFile(srcFileName: String, destFileName: String): Int64 {
    var count: Int64 = 0
    var srcFile: File = File(srcFileName, Read)
    var destFile: File = File(destFileName, Write)

    var tempBuf: Array<UInt8> = Array<UInt8>(1024, repeat: 0)
    var compressOutputStream: CompressOutputStream = CompressOutputStream(destFile, wrap: GzipFormat, bufLen: 10000)
    while (true) {
        var readNum = srcFile.read(tempBuf)
        if (readNum > 0) {
            compressOutputStream.write(tempBuf.slice(0, readNum).toArray())
            count += readNum
        } else {
            break
        }
    }
    compressOutputStream.flush()
    compressOutputStream.close()

    srcFile.close()
    destFile.close()
    return count
}
```

运行结果：

```text
解压后文件数据字节数和压缩前数据字节数是否相等: true
```

### func close()

```cangjie
public func close(): Unit
```

功能：关闭当前解压输出流实例。

关闭时，将写入剩余解压后数据，并释放其所占内存资源。当前压缩输出流使用完毕后必须调用此函数来释放其所占内存资源，以免造成内存泄漏。如果之前 [write](./zlib_package_classes.md#func-writearraybyte-1) 函数已处理的压缩数据不完整，调用 [close](./zlib_package_classes.md#func-close-1) 函数时会因为解压数据不全而抛出异常。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果当前压缩输出流已经被关闭，通过 [write](./zlib_package_classes.md#func-writearraybyte-1) 函数传入的待解压数据不完整（含未调用 [write](./zlib_package_classes.md#func-writearraybyte-1) 传入任何数据的情形），或释放压缩资源失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.fs.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()

    // 创建一个临时文件用于压缩
    File.writeTo("./temp_input.txt", arr1)

    // 压缩文件
    compressFile("./temp_input.txt", "./temp_compressed.gz")

    // 读取压缩后的数据
    let compressedData = File.readFrom("./temp_compressed.gz")

    /* 使用解压缩输出流进行数据解压后，将数据写入文件，文件的内容为原始数据 */
    var file = File("./file.text", ReadWrite)
    var decompressOutputStream: DecompressOutputStream = DecompressOutputStream(file, wrap: GzipFormat, bufLen: 1024)

    decompressOutputStream.write(compressedData)
    decompressOutputStream.flush()

    /* 关闭输出流和文件 */
    decompressOutputStream.close()

    println("解压后文件数据字节数和压缩前数据字节数是否相等: ${file.length == arr1.size}")
    file.close()

    // 清理临时文件
    removeIfExists("./temp_input.txt")
    removeIfExists("./temp_compressed.gz")
    removeIfExists("./file.text")
}

func compressFile(srcFileName: String, destFileName: String): Int64 {
    var count: Int64 = 0
    var srcFile: File = File(srcFileName, Read)
    var destFile: File = File(destFileName, Write)

    var tempBuf: Array<UInt8> = Array<UInt8>(1024, repeat: 0)
    var compressOutputStream: CompressOutputStream = CompressOutputStream(destFile, wrap: GzipFormat, bufLen: 10000)
    while (true) {
        var readNum = srcFile.read(tempBuf)
        if (readNum > 0) {
            compressOutputStream.write(tempBuf.slice(0, readNum).toArray())
            count += readNum
        } else {
            break
        }
    }
    compressOutputStream.flush()
    compressOutputStream.close()

    srcFile.close()
    destFile.close()
    return count
}
```

运行结果：

```text
解压后文件数据字节数和压缩前数据字节数是否相等: true
```

### func flush()

```cangjie
public func flush(): Unit
```

功能：刷新解压输出流。将内部缓冲区里已解压的数据写入绑定的输出流，然后刷新绑定的输出流。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果当前解压输出流已经被关闭，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.fs.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()

    // 创建一个临时文件用于压缩
    File.writeTo("./temp_input.txt", arr1)

    // 压缩文件
    compressFile("./temp_input.txt", "./temp_compressed.gz")

    // 读取压缩后的数据
    let compressedData = File.readFrom("./temp_compressed.gz")

    /* 使用解压缩输出流进行数据解压后，将数据写入文件，文件的内容为原始数据 */
    var file = File("./file.text", ReadWrite)
    var decompressOutputStream: DecompressOutputStream = DecompressOutputStream(file, wrap: GzipFormat, bufLen: 1024)

    decompressOutputStream.write(compressedData)
    decompressOutputStream.flush()

    /* 关闭输出流和文件 */
    decompressOutputStream.close()

    println("解压后文件数据字节数和压缩前数据字节数是否相等: ${file.length == arr1.size}")
    file.close()

    // 清理临时文件
    removeIfExists("./temp_input.txt")
    removeIfExists("./temp_compressed.gz")
    removeIfExists("./file.text")
}

func compressFile(srcFileName: String, destFileName: String): Int64 {
    var count: Int64 = 0
    var srcFile: File = File(srcFileName, Read)
    var destFile: File = File(destFileName, Write)

    var tempBuf: Array<UInt8> = Array<UInt8>(1024, repeat: 0)
    var compressOutputStream: CompressOutputStream = CompressOutputStream(destFile, wrap: GzipFormat, bufLen: 10000)
    while (true) {
        var readNum = srcFile.read(tempBuf)
        if (readNum > 0) {
            compressOutputStream.write(tempBuf.slice(0, readNum).toArray())
            count += readNum
        } else {
            break
        }
    }
    compressOutputStream.flush()
    compressOutputStream.close()

    srcFile.close()
    destFile.close()
    return count
}
```

运行结果：

```text
解压后文件数据字节数和压缩前数据字节数是否相等: true
```

### func write(Array\<Byte>)

```cangjie
public func write(inBuf: Array<Byte>): Unit
```

功能：将指定字节数组中的数据进行解压，并写入输出流，当数据全部解压完成并写入输出流，函数返回。

参数：

- inBuf: Array\<Byte> - 待解压的字节数组。

异常：

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - 如果当前解压输出流已经被关闭，或解压数据失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.io.*
import std.fs.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()

    /* 使用压缩输入流进行数据压缩 */
    let byteBuffer = ByteBuffer(arr1)
    var compressInputStream: CompressInputStream = CompressInputStream(byteBuffer)
    var arr2: Array<Byte> = Array<Byte>(1024, repeat: 0)
    /* 原始数据长度 */
    println("原始数据长度: ${arr1.size}")
    var len1 = compressInputStream.read(arr2)
    /* 压缩后的数据长度 */
    println("压缩后的数据长度: ${len1}")

    /* 使用解压缩输出流进行数据解压后，将数据写入文件，文件的内容为原始数据 */
    var file = File("./file.text", ReadWrite)
    var decompressOutputStream: DecompressOutputStream = DecompressOutputStream(file)
    decompressOutputStream.write(arr2[..len1])
    decompressOutputStream.flush()

    /* 关闭输入流和输出流 */
    compressInputStream.close()
    decompressOutputStream.close()
    println("解压后文件数据字节数和压缩前数据字节数是否相等: ${file.length == arr1.size}")
    file.close()
    removeIfExists("./file.text")
}
```

运行结果：

```text
原始数据长度: 65
压缩后的数据长度: 18
解压后文件数据字节数和压缩前数据字节数是否相等: true
```
