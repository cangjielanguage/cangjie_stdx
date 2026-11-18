# Classes

## class CompressInputStream

```cangjie
public class CompressInputStream <: InputStream {
    public init(inputStream: InputStream, wrap!: WrapType = DeflateFormat, compressLevel!: CompressLevel = DefaultCompression, bufLen!: Int64 = 512)
}
```

Function: Compression input stream.

A [CompressInputStream](zlib_package_classes.md#class-compressinputstream) instance can be bound to any InputStream type input stream through the constructor. By cyclically calling the read(outBuf: Array\<Byte>) function, it compresses data from the input stream and outputs the compressed data to the provided byte array.

Parent Type:

- InputStream

### init(InputStream, WrapType, CompressLevel, Int64)

```cangjie
public init(inputStream: InputStream, wrap!: WrapType = DeflateFormat, compressLevel!: CompressLevel = DefaultCompression, bufLen!: Int64 = 512)
```

Function: Constructs a compression input stream.

Requires binding to an input stream. Allows setting compression data format, compression level, and internal buffer size (how much data is read from the input stream for compression at a time).

Parameters:

- inputStream: InputStream - The input stream to be compressed.
- wrap!: [WrapType](zlib_package_enums.md#enum-wraptype) - Compression data format, default value is [DeflateFormat](zlib_package_enums.md#deflateformat).
- compressLevel!: [CompressLevel](zlib_package_enums.md#enum-compresslevel) - Compression level, default value is [DefaultCompression](zlib_package_enums.md#defaultcompression).
- bufLen!: Int64 - Size of the input stream buffer, valid range is (0, Int64.Max], default is 512 bytes.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if `bufLen` is less than or equal to 0, input stream memory allocation fails, or compression resource initialization fails.

### func close()

```cangjie
public func close(): Unit
```

Function: Closes the compression input stream.

After using a [CompressInputStream](zlib_package_classes.md#class-compressinputstream) instance, this function must be called to release its memory resources to prevent memory leaks. Ensure the [read](./zlib_package_classes.md#func-readarraybyte) function has returned 0 before calling this function, otherwise the bound InputStream may not be fully compressed.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if releasing compression resources fails.

### func read(Array\<Byte>)

```cangjie
public func read(outBuf: Array<Byte>): Int64
```

Function: Reads data from the bound input stream, compresses it, and places the compressed data into the specified byte array.

Parameters:

- outBuf: Array\<Byte> - Buffer to store the compressed data.

Return Value:

- Int64 - If compression succeeds, returns the number of compressed bytes. If all data from the bound input stream has been compressed, or if the compression input stream is closed, returns 0.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if `outBuf` is empty or data compression fails.

Example:

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.fs.*
import std.io.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()
    let byteBuffer = ByteBuffer(arr1)
    let bufferedInputStream = BufferedInputStream(byteBuffer)
    var compressInputStream: CompressInputStream = CompressInputStream(bufferedInputStream)
    var arr: Array<Byte> = Array<Byte>(1024, repeat: 0)
    println(arr1.size)
    var len = compressInputStream.read(arr)
    println(len)
    compressInputStream.close()
}
```

Execution Result:

```text
65
17
```

## class CompressOutputStream

```cangjie
public class CompressOutputStream <: OutputStream {
    public init(outputStream: OutputStream, wrap!: WrapType = DeflateFormat, compressLevel!: CompressLevel = DefaultCompression, bufLen!: Int64 = 512)
}
```

Function: Compression output stream.

A [CompressOutputStream](zlib_package_classes.md#class-compressoutputstream) instance can be bound to any OutputStream type output stream through the constructor. Calling the write(inBuf: Array\<Byte>) function reads and compresses data from the specified byte array, then outputs the compressed data to the bound output stream.

Parent Type:

- OutputStream

### init(OutputStream, WrapType, CompressLevel, Int64)

```cangjie
public init(outputStream: OutputStream, wrap!: WrapType = DeflateFormat, compressLevel!: CompressLevel = DefaultCompression, bufLen!: Int64 = 512)
```

Function: Constructs a compression output stream.

Requires binding to an output stream. Allows setting compression data type, compression level, and internal buffer size (how much compressed data is written to the output stream at a time).

Parameters:

- outputStream: OutputStream - The bound output stream where compressed data will be written.
- wrap!: [WrapType](zlib_package_enums.md#enum-wraptype) - Compression data format, default value is [DeflateFormat](zlib_package_enums.md#deflateformat).
- compressLevel!: [CompressLevel](zlib_package_enums.md#enum-compresslevel) - Compression level, default value is [DefaultCompression](zlib_package_enums.md#defaultcompression).
- bufLen!: Int64 - Size of the output stream buffer, valid range is (0, Int64.Max], default is 512 bytes.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if `bufLen` is less than or equal to 0, output stream memory allocation fails, or compression resource initialization fails.

### func close()

```cangjie
public func close(): Unit
```

Function: Closes the current compression output stream instance.

During closure, it writes remaining compressed data (including data in the buffer and compression tail information) and releases its memory resources. This function must be called after using the compression output stream to prevent memory leaks. Before calling [close](./zlib_package_classes.md#func-close-1), the data written to the bound output stream is not a complete compressed data segment. Only after calling [close](./zlib_package_classes.md#func-close-1) will the remaining compressed data be written to the bound output stream, making it complete.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if the current compression output stream is already closed or releasing compression resources fails.

### func flush()

```cangjie
public func flush(): Unit
```

Function: Flushes the compression output stream.

Flushes the compressed data from the internal buffer to the bound output stream, then flushes the bound output stream.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if the current compression output stream is already closed.

### func write(Array\<Byte>)

```cangjie
public func write(inBuf: Array<Byte>): Unit
```

Function: Compresses data from the specified byte array and writes it to the output stream. Returns when all data has been compressed and written to the output stream.

Parameters:

- inBuf: Array\<Byte> - Byte array to be compressed.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if the current compression output stream is already closed or data compression fails.

Example:

<!-- run -->
```cangjie
import stdx.compress.zlib.*
import std.io.*

main(): Unit {
    var byteBuffer = ByteBuffer()
    var compressOutputStream: CompressOutputStream = CompressOutputStream(byteBuffer, bufLen: 39)

    var arr = "Hello, World!Hello, World!Hello, World!".toArray()

    /* Compresses the byte array and writes it to the compression output stream's buffer */
    compressOutputStream.write(arr)

    /* Flushes the compressed data from the internal buffer to the bound output stream, then flushes the bound output stream */
    compressOutputStream.flush()

    /* Closes the compression output stream */
    compressOutputStream.close()
}
```

## class DecompressInputStream

```cangjie
public class DecompressInputStream <: InputStream {
    public init(inputStream: InputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512)
}
```

Function: Decompression input stream.

A [DecompressInputStream](zlib_package_classes.md#class-decompressinputstream) instance can be bound to any InputStream input stream through the constructor. By cyclically calling the read(outBuf: Array\<Byte>) function, it reads and decompresses data from the input stream, then outputs the decompressed data to the specified byte array.

Parent Type:

- InputStream

### init(InputStream, WrapType, Int64)

```cangjie
public init(inputStream: InputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512)
```

Function: Constructs a decompression input stream.

Requires binding to an input stream. Allows setting the data format to be decompressed and internal buffer size (how much data is read from the input stream for decompression at a time).

Parameters:

- inputStream: InputStream - The input stream to be decompressed.
- wrap!: [WrapType](zlib_package_enums.md#enum-wraptype) - Data format to be decompressed, default value is [DeflateFormat](zlib_package_enums.md#deflateformat).
- bufLen!: Int64 - Size of the input stream buffer, valid range is (0, Int64.Max], default is 512 bytes.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if `bufLen` is less than or equal to 0, input stream memory allocation fails, or decompression resource initialization fails.

### func close()

```cangjie
public func close(): Unit
```

Function: Closes the decompression input stream.

After using a [DecompressInputStream](zlib_package_classes.md#class-decompressinputstream) instance, this function must be called to release its memory resources to prevent memory leaks. Ensure the [read](./zlib_package_classes.md#func-readarraybyte-1) function has returned 0 before calling this function, otherwise the bound InputStream may not be fully decompressed.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if releasing decompression resources fails.

### func read(Array\<Byte>)

```cangjie
public func read(outBuf: Array<Byte>): Int64
```

Function: Reads data from the bound input stream, decompresses it, and places the decompressed data into the specified byte array.

Parameters:

- outBuf: Array\<Byte> - Buffer to store the decompressed data.

Return Value:

- Int64 - If decompression succeeds, returns the number of decompressed bytes. If all data from the bound input stream has been decompressed, or if the decompression input stream is closed, returns 0.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if `outBuf` is empty, data decompression fails, or the compressed data ends before decompression is finished (for example, the compressed data is truncated).

Example:

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.fs.*
import std.io.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()

    /* Uses compression input stream for data compression */
    let byteBuffer = ByteBuffer(arr1)
    var compressInputStream: CompressInputStream = CompressInputStream(byteBuffer)
    var arr2: Array<Byte> = Array<Byte>(1024, repeat: 0)
    /* Original data length */
    println(arr1.size)
    var len1 = compressInputStream.read(arr2)
    /* Compressed data length */
    println(len1)

    /* Uses decompression input stream for data decompression */
    var decompressInputStream: DecompressInputStream = DecompressInputStream(ByteBuffer(arr2[..len1]))
    var arr3: Array<Byte> = Array<Byte>(1024, repeat: 0)
    var len2 = decompressInputStream.read(arr3)
    println(String.fromUtf8(arr3[..len2]))

    /* Closes input streams */
    compressInputStream.close()
    decompressInputStream.close()
}
```

Execution Result:

```text
65
17
Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!
```

## class DecompressOutputStream

```cangjie
public class DecompressOutputStream <: OutputStream {
    public init(outputStream: OutputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512)
}
```

Function: Decompression output stream.

A [DecompressOutputStream](zlib_package_classes.md#class-decompressoutputstream) instance can be bound to a specified OutputStream type output stream through the constructor. By calling the write(inBuf: Array\<Byte>) function, it reads and decompresses data from the specified byte array and outputs the decompressed data to the bound output stream.

Parent Type:

- OutputStream

### init(OutputStream, WrapType, Int64)

```cangjie
public init(outputStream: OutputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512)
```

Function: Constructs a decompression output stream.

Requires binding to an output stream. The compression data type, compression level, and internal buffer size can be set (decompressed data is stored in the internal buffer and written to the output stream when the buffer is full).

Parameters:

- outputStream: OutputStream - The bound output stream to which decompressed data will be written.
- wrap!: [WrapType](zlib_package_enums.md#enum-wraptype) - The format of the data to be decompressed. Default value is [DeflateFormat](zlib_package_enums.md#deflateformat).
- bufLen!: Int64 - The size of the output stream buffer. Valid range is (0, Int64.Max], default is 512 bytes.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if `bufLen` is less than or equal to 0, memory allocation for the output stream fails, or decompression resource initialization fails.

### func close()

```cangjie
public func close(): Unit
```

Function: Closes the current decompression output stream instance.

Upon closing, it writes any remaining decompressed data and releases the occupied memory resources. This function must be called after using the current decompression output stream to prevent memory leaks. If the compressed data processed by the [write](./zlib_package_classes.md#func-writearraybyte-1) function was incomplete, calling [close](./zlib_package_classes.md#func-close-1) will throw an exception due to incomplete decompression data.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if the current decompression output stream has already been closed, the input data for decompression is incomplete (including the case where no data was passed to the [write](./zlib_package_classes.md#func-writearraybyte-1) function), or decompression resource release fails.

### func flush()

```cangjie
public func flush(): Unit
```

Function: Flushes the decompression output stream. Writes the decompressed data in the internal buffer to the bound output stream and then flushes the bound output stream.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if the current decompression output stream has already been closed.

### func write(Array\<Byte>)

```cangjie
public func write(inBuf: Array<Byte>): Unit
```

Function: Decompresses data from the specified byte array and writes it to the output stream. Returns once all data has been decompressed and written to the output stream.

Parameters:

- inBuf: Array\<Byte> - The byte array to be decompressed.

Exceptions:

- [ZlibException](zlib_package_exceptions.md#class-zlibexception) - Thrown if the current decompression output stream has already been closed or decompression fails.

Example:

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import std.fs.*
import std.io.*

main(): Unit {
    let arr1 = "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!".toArray()

    /* Compress data using a compression input stream */
    let byteBuffer = ByteBuffer(arr1)
    var compressInputStream: CompressInputStream = CompressInputStream(byteBuffer)
    var arr2: Array<Byte> = Array<Byte>(1024, repeat: 0)
    /* Original data length */
    println(arr1.size)
    var len1 = compressInputStream.read(arr2)
    /* Compressed data length */
    println(len1)

    /* Decompress data using a decompression output stream and write it to a file. The file content will be the original data */
    var file = File("./file.text", ReadWrite)
    var decompressOutputStream: DecompressOutputStream = DecompressOutputStream(file)
    decompressOutputStream.write(arr2[..len1])
    decompressOutputStream.flush()

    /* Close input and output streams */
    compressInputStream.close()
    decompressOutputStream.close()
    file.close()
}
```

Execution Result:

```text
65
17
```