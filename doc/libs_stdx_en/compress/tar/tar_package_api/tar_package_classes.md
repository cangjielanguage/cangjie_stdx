# Classes

## class GnuTarEntry

```cangjie
public class GnuTarEntry <: PosixTarEntry {
    public init(path: String)
    public init(path: Path)
}
```

Function: Represents a Gnu tar file entry.

Parent type:

- [PosixTarEntry](#class-posixtarentry)

### prop accessTime

```cangjie
public prop accessTime: DateTime
```

Function: Gets the access time of the current entry.

Type: DateTime

### prop changeTime

```cangjie
public prop changeTime: DateTime
```

Function: Gets the change time of the current entry.

Type: DateTime

### init(Path)

```cangjie
public init(path: Path)
```

Function: Construct a Gnu tar file entry from a file, directory, or symbolic link.

Parameters:

- path: Path - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### init(String)

```cangjie
public init(path: String)
```

Function: Construct a Gnu tar file entry from a file, directory, or symbolic link.

Parameters:

- path: String - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### func writeTo(OutputStream)

```cangjie
public override func writeTo(target: OutputStream): Unit
```

Function: Write the current entry to the specified output stream.

Parameters:

- target: OutputStream - The specified output stream.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if a field exceeds format requirements or writing fails.

## class PaxTarEntry

```cangjie
public class PaxTarEntry <: PosixTarEntry {
    public init(path: String)
    public init(path: Path)
}
```

Function: Represents a Pax tar file entry.

Parent type:

- [PosixTarEntry](#class-posixtarentry)

### init(Path)

```cangjie
public init(path: Path)
```

Function: Construct a Pax tar file entry from a file, directory, or symbolic link.

Parameters:

- path: Path - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### init(String)

```cangjie
public init(path: String)
```

Function: Construct a Pax tar file entry from a file, directory, or symbolic link.

Parameters:

- path: String - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### func getPaxData(String)

```cangjie
public func getPaxData(key: String): ?String
```

Function: Gets the Pax data of the current entry.

Parameters:

- key: String - The key of the Pax data.

Return value:

- Option\<String> - If Pax data exists for the corresponding key, returns its value; otherwise, returns None.

### func writeTo(OutputStream)

```cangjie
public override func writeTo(target: OutputStream): Unit
```

Function: Write the current entry to the specified output stream.

Parameters:

- target: OutputStream - The specified output stream.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if a field exceeds format requirements or writing fails.

## class PosixTarEntry

```cangjie
public abstract class PosixTarEntry <: TarEntry {
    protected init(path: String)
    protected init(path: Path)
}
```

Function: Represents a tar file entry containing common fields shared by Ustar, Gnu, and Pax formats.

Parent type:

- [TarEntry](#class-tarentry)

### prop deviceMajor

```cangjie
public prop deviceMajor: Int32
```

Function: Gets the device major number of the current entry.

Type: Int32

### prop deviceMinor

```cangjie
public prop deviceMinor: Int32
```

Function: Gets the device minor number of the current entry.

Type: Int32

### prop groupName

```cangjie
public prop groupName: String
```

Function: Gets the group name of the current entry.

Type: String

### prop userName

```cangjie
public prop userName: String
```

Function: Gets the user name of the current entry.

Type: String

### init(Path)

```cangjie
public init(path: Path)
```

Function: Construct a tar file entry from a file, directory, or symbolic link.

Parameters:

- path: Path - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### init(String)

```cangjie
public init(path: String)
```

Function: Construct a tar file entry from a file, directory, or symbolic link.

Parameters:

- path: String - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

## class Tar

```cangjie
public class Tar {}
```

Function: Archive and extract directories or streams.

### static func archive(Path, (Path) -> Bool, Path, Bool)

```cangjie
public static func archive(fromDir!: Path, filter!: (Path) -> Bool, destFile!: Path, includeBaseDirectory!: Bool): Unit
```

Function: Selectively archive the specified directory as a .tar file with a filter function.

Parameters:

- fromDir!: Path - The directory to be archived.

- filter!: (Path) -> Bool - A filter function that receives paths of directories, files, and symbolic links encountered during traversal. Returns true to keep the item, otherwise discards it.

- destFile!: Path - The path of the output .tar file.

- includeBaseDirectory!: Bool - Whether to include the base directory.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar archiving.

### static func archive(Path, Path, Bool)

```cangjie
public static func archive(fromDir!: Path, destFile!: Path, includeBaseDirectory!: Bool): Unit
```

Function: Archive the specified directory as a .tar file.

Parameters:

- fromDir!: Path - The path of the directory to be archived.

- destFile!: Path - The path of the generated .tar file.

- includeBaseDirectory!: Bool - Whether to include the directory itself as the top-level directory. If true, the archive contains the directory; if false, only its contents are included.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar archiving.

### static func archive(String, (String) -> Bool, String, Bool)

```cangjie
public static func archive(fromDir!: String, filter!: (String) -> Bool, destFile!: String, includeBaseDirectory!: Bool): Unit
```

Function: Selectively archive the specified directory as a .tar file with a filter function.

Parameters:

- fromDir!: String - The directory to be archived.

- filter!: (String) -> Bool - A filter function that receives paths of directories, files, and symbolic links encountered during traversal. Returns true to keep the item, otherwise discards it.

- destFile!: String - The path of the output .tar file.

- includeBaseDirectory!: Bool - Whether to include the base directory.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar archiving.

### static func archive(String, String, Bool)

```cangjie
public static func archive(fromDir!: String, destFile!: String, includeBaseDirectory!: Bool): Unit
```

Function: Archive the specified directory as a .tar file.

Parameters:

- fromDir!: String - The path of the directory to be archived.

- destFile!: String - The path of the generated .tar file.

- includeBaseDirectory!: Bool - Whether to include the directory itself as the top-level directory. If true, the archive contains the directory; if false, only its contents are included.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar archiving.

### static func archive\<T>(Path, T, Bool) where T <: OutputStream

```cangjie
public static func archive<T>(fromDir!: Path, destStream!: T, includeBaseDirectory!: Bool): Unit where T <: OutputStream
```

Function: Archive a directory as .tar data and write it to the specified output stream.

> **Note:**
>
> The function does not handle the release of destStream resources; the caller must manage the lifecycle of this output stream.

Parameters:

- fromDir!: Path - The path of the directory to be archived.

- destStream!: T - The output stream for archived data.

- includeBaseDirectory!: Bool - Whether to include the base directory.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar archiving.

### static func archive\<T>(String, T, Bool) where T <: OutputStream

```cangjie
public static func archive<T>(fromDir!: String, destStream!: T, includeBaseDirectory!: Bool): Unit where T <: OutputStream
```

Function: Archive a directory as .tar data and write it to the specified output stream.

> **Note:**
>
> The function does not handle the release of destStream resources; the caller must manage the lifecycle of this output stream.

Parameters:

- fromDir!: String - The path of the directory to be archived.

- destStream!: T - The output stream for archived data.

- includeBaseDirectory!: Bool - Whether to include the base directory.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar archiving.

### static func extract(Path, Path, Bool)

```cangjie
public static func extract(fromTar!: Path, destDir!: Path, overwrite!: Bool): Unit
```

Function: Extract a .tar file to the specified directory.

Parameters:

- fromTar!: Path - The path of the .tar file to be extracted.

- destDir!: Path - The target directory for extraction.

- overwrite!: Bool - If true, allows overwriting existing files and directories; otherwise, an exception is thrown when encountering files or directories with duplicate names.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar extraction.

### static func extract(String, String, Bool)

```cangjie
public static func extract(fromTar!: String, destDir!: String, overwrite!: Bool): Unit
```

Function: Extract a .tar file to the specified directory.

Parameters:

- fromTar!: String - The path of the .tar file to be extracted.

- destDir!: String - The target directory for extraction.

- overwrite!: Bool - If true, allows overwriting existing files and directories; otherwise, an exception is thrown when encountering files or directories with duplicate names.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar extraction.

### static func extract\<T>(T, Path, Bool) where T <: InputStream

```cangjie
public static func extract<T>(fromStream!: T, destDir!: Path, overwrite!: Bool): Unit where T <: InputStream
```

Function: Read .tar data from an input stream and extract it to the specified directory.

Parameters:

- fromStream!: T - The input stream of .tar data to be extracted.

- destDir!: Path - The target directory for extraction.

- overwrite!: Bool - If true, allows overwriting existing files and directories; otherwise, an exception is thrown when encountering files or directories with duplicate names.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar extraction.

### static func extract\<T>(T, String, Bool) where T <: InputStream

```cangjie
public static func extract<T>(fromStream!: T, destDir!: String, overwrite!: Bool): Unit where T <: InputStream
```

Function: Read .tar data from an input stream and extract it to the specified directory.

Parameters:

- fromStream!: T - The input stream of .tar data to be extracted.

- destDir!: String - The target directory for extraction.

- overwrite!: Bool - If true, allows overwriting existing files and directories; otherwise, an exception is thrown when encountering files or directories with duplicate names.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if an error occurs during tar extraction.

## class TarEntry

```cangjie
public abstract class TarEntry {
    protected init(path: String)
    protected init(path: Path)
}
```

Function: Represents an entry in a tar file, used to interact with [TarReader](tar_package_classes.md#class-tarreadert) and [TarWriter](tar_package_classes.md#class-tarwritert). A [TarEntry](tar_package_classes.md#class-tarentry) instance can be obtained from [TarReader](tar_package_classes.md#class-tarreadert), representing an entry in the tar archive file. It can also be written to a tar archive file via [TarWriter](tar_package_classes.md#class-tarwritert).

### prop entryType

```cangjie
public prop entryType: TarEntryType
```

Function: Gets the entry type of the current entry.

Type: [TarEntryType](tar_package_enums.md#enum-tarentrytype)

### prop linkName

```cangjie
public prop linkName: String
```

Function: Gets the link name of the current entry.

Type: String

### prop gid

```cangjie
public mut prop gid: Int32
```

Function: Gets the group ID of the current entry.

Type: Int32

### prop mode

```cangjie
public mut prop mode: Int32
```

Function: Gets the permission mode of the current entry.

Type: Int32

### prop modificationTime

```cangjie
public prop modificationTime: DateTime
```

Function: Gets the last modification time of the current entry.

Type: DateTime

### prop checksum

```cangjie
public prop checksum: Int32
```

Function: Gets the checksum of the current entry.

Type: Int32

### prop name

```cangjie
public mut prop name: String
```

Function: Gets the file name of the current entry.

Type: String

### prop size

```cangjie
public prop size: Int64
```

Function: Gets the size of the current entry.

Type: Int64

### prop stream

```cangjie
public prop stream: ?InputStream
```

Function: Gets the input stream of the current entry. If the instance is created by [TarReader](tar_package_classes.md#class-tarreadert), this property returns the data stream for the entry, or None if the entry has no data. If the instance is created by the constructor, this property returns the created file stream, which will be called when passed to [TarWriter](tar_package_classes.md#class-tarwritert) to write entry data.

Type: Option\<InputStream>

### prop uid

```cangjie
public mut prop uid: Int32
```

Function: Gets the user ID of the current entry.

Type: Int32

### init(Path)

```cangjie
protected init(path: Path)
```

Function: Construct a tar file entry from a file, directory, or symbolic link.

Parameters:

- path: Path - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### init(String)

```cangjie
protected init(path: String)
```

Function: Construct a tar file entry from a file, directory, or symbolic link.

Parameters:

- path: String - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### func writeTo(OutputStream)

```cangjie
public open func writeTo(target: OutputStream): Unit
```

Function: Write the current entry to the specified output stream.

Parameters:

- target: OutputStream - The specified output stream.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if a field exceeds format requirements or writing fails.

## class TarReader

```cangjie
public class TarReader<T> <: Iterable<TarEntry> where T <: InputStream {
    public init(stream: T)
}
```

Function: Read entries from a stream in tar format.

### init(T)

```cangjie
public init(stream: T)
```

Function: Create a tar file reader from the specified stream.

Parameters:

- stream: T - The specified input stream.

### func iterator()

```cangjie
public func iterator(): Iterator<TarEntry>
```

Function: Returns an iterator that iterates over entries in the tar file.

Return value:

- Iterator\<TarEntry> - An iterator of [TarEntry](tar_package_classes.md#class-tarentry).

### extend\<T> TarReader\<T> <: Resource where T <: Resource

```cangjie
extend<T> TarReader<T> <: Resource where T <: Resource
```

Function: Implements the Resource interface for [TarReader](tar_package_classes.md#class-tarreadert), allowing objects of this type to achieve automatic resource release in the `try-with-resource` syntax context.

Parent type:

- Resource

#### func close()

```cangjie
public func close(): Unit
```

Function: Close the internal stream.

> **Note:**
>
> After calling this method, do not call other interfaces of [TarReader](tar_package_classes.md#class-tarreadert), otherwise it may cause unexpected behavior.

#### func isClosed()

```cangjie
public func isClosed(): Bool
```

Function: Determine whether the internal stream is closed.

Return value:

- Bool - Returns true if the internal stream has been closed, otherwise returns false.

## class TarWriter

```cangjie
public class TarWriter<T> where T <: OutputStream {
    public init(stream: T)
    public init(stream: T, format: TarEntryFormat)
}
```

Function: Write entries to a stream and complete the writing of the tar file.

### prop format

```cangjie
public prop format: TarEntryFormat
```

Function: Gets the entry format of the current tar file.

Type: [TarEntryFormat](tar_package_enums.md#enum-tarentryformat)

### init(T)

```cangjie
public init(stream: T)
```

Function: Create a tar file writer from the specified stream, defaulting to Pax format.

Parameters:

- stream: T - The specified output stream.

### init(T, TarEntryFormat)

```cangjie
public init(stream: T, format: TarEntryFormat)
```

Function: Create a tar file writer from the specified stream.

Parameters:

- stream: T - The specified output stream.

- format: [TarEntryFormat](tar_package_enums.md#enum-tarentryformat) - The entry format of the tar file.

### func finish()

```cangjie
public func finish(): Unit
```

Function: Write the tar end marker, which is 1024 null bytes, and finish writing in tar format.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if writing has ended, or if writing fails.

### func flush()

```cangjie
public func flush(): Unit
```

Function: Flush the internal stream.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if writing has ended.

### func write(FileInfo, String)

```cangjie
public func write(info: FileInfo, entryName!: String): Unit
```

Function: Write the specified file, directory, or symbolic link to the internal stream.

Parameters:

- info: FileInfo - The information of the file, directory, or symbolic link to be written.

- entryName!: String - The entry name in the tar file.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if writing has ended, or if creating or writing the entry fails.

- FSException - Thrown if creating file stream fails.

### func write(Iterable\<TarEntry>)

```cangjie
public func write(it: Iterable<TarEntry>): Unit
```

Function: Write the specified list of tar file entries to the internal stream.

Parameters:

- it: Iterable\<[TarEntry](tar_package_classes.md#class-tarentry)> - The list of tar file entries to be written.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if writing has ended, or if writing entries fails.

### func write(Path, String)

```cangjie
public func write(path: Path, entryName!: String): Unit
```

Function: Write the specified file, directory, or symbolic link to the internal stream.

Parameters:

- path: Path - The path of the specified file, directory, or symbolic link.

- entryName!: String - The entry name in the tar file.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if writing has ended, or if creating or writing the entry fails.

- FSException - Thrown if creating file stream fails.

### func write(String, String)

```cangjie
public func write(path!: String, entryName!: String): Unit
```

Function: Write the specified file, directory, or symbolic link to the internal stream.

Parameters:

- path!: String - The path of the specified file, directory, or symbolic link.

- entryName!: String - The entry name in the tar file.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if writing has ended, or if creating or writing the entry fails.

- FSException - Thrown if creating file stream fails.

### func write(TarEntry)

```cangjie
public func write(entry: TarEntry): Unit
```

Function: Write the specified tar file entry to the internal stream.

Parameters:

- entry: [TarEntry](tar_package_classes.md#class-tarentry) - The tar file entry to be written.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if writing has ended, or if writing the entry fails.

### extend\<T> TarWriter\<T> <: Resource where T <: Resource

```cangjie
extend<T> TarWriter<T> <: Resource where T <: Resource
```

Function: Implements the Resource interface for [TarWriter](tar_package_classes.md#class-tarwritert), allowing objects of this type to achieve automatic resource release in the `try-with-resource` syntax context.

Parent type:

- Resource

#### func close()

```cangjie
public func close(): Unit
```

Function: Write the tar end marker and close the internal stream.

> **Note:**
>
> After calling this method, do not call other interfaces of [TarWriter](tar_package_classes.md#class-tarwritert), otherwise it may cause unexpected behavior.

#### func isClosed()

```cangjie
public func isClosed(): Bool
```

Function: Determine whether the internal stream is closed.

Return value:

- Bool - Returns true if the internal stream has been closed, otherwise returns false.

## class UstarTarEntry

```cangjie
public class UstarTarEntry <: PosixTarEntry {
    public init(path: String)
    public init(path: Path)
}
```

Function: Represents a Ustar tar file entry.

Parent type:

- [PosixTarEntry](#class-posixtarentry)

### init(Path)

```cangjie
public init(path: Path)
```

Function: Construct a Ustar tar file entry from a file, directory, or symbolic link.

Parameters:

- path: Path - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### init(String)

```cangjie
public init(path: String)
```

Function: Construct a Ustar tar file entry from a file, directory, or symbolic link.

Parameters:

- path: String - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the path parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### func writeTo(OutputStream)

```cangjie
public override func writeTo(target: OutputStream): Unit
```

Function: Write the current entry to the specified output stream.

Parameters:

- target: OutputStream - The specified output stream.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if a field exceeds format requirements or writing fails.

## class V7TarEntry

```cangjie
public class V7TarEntry <: TarEntry {
    public init(filePath: String)
    public init(filePath: Path)
}
```

Function: Represents a V7 tar file entry.

Parent type:

- [TarEntry](#class-tarentry)

### init(Path)

```cangjie
public init(filePath: Path)
```

Function: Construct a V7 tar file entry from a file, directory, or symbolic link.

Parameters:

- filePath: Path - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the filePath parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.

### init(String)

```cangjie
public init(filePath: String)
```

Function: Construct a V7 tar file entry from a file, directory, or symbolic link.

Parameters:

- filePath: String - The path of the file, directory, or symbolic link.

Exceptions:

- [TarException](tar_package_exceptions.md#class-tarexception) - Thrown if the target specified by the filePath parameter does not exist or is not a file, directory, or symbolic link.

- FSException - Thrown if reading target information or creating target file stream fails.
