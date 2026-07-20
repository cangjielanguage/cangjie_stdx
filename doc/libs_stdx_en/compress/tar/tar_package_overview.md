# stdx.compress.tar

## Feature Introduction

compress.tar provides archiving and reading capabilities.

Archiving is a method of organizing multiple files or directories into a single file, typically used to package multiple files or directories into a single file and save it on disk. Archive files usually contain file metadata (such as file names, permissions, timestamps, etc.) as well as file contents. Common archive formats include tar, zip, rar, etc.

This package implements the tar archive format, supporting four formats: V7, USTAR, PAX, and GNU. The tar format is widely used in scenarios for backing up and distributing files.

> **Note:**
>
> For file compression, please use stdx.compress.zlib for compression or use the stdx.compress combination tool TarGzip for archive compression operations.

## Specifications

### Feature Limitations

The current version of this package has the following feature limitations:

- **ACL (Access Control Lists) not supported**: Archiving and extraction operations will not process file ACL information.
- **xattr (Extended Attributes) not supported**: Archiving and extraction operations will not process file extended attributes.
- **Special file types not yet supported**: Block device files, character device files, and FIFO (named pipe) files are not yet supported for archiving and extraction.

### setuid/setgid Permission Bit Handling

During extraction, the setuid/setgid permission bits are restored to the file as-is. However, whether the restoration is successful depends on the following factors:

- The permissions of the user/process performing the extraction
- Operating system security restrictions

On most Unix/Linux systems, regular users cannot set the setgid bit; only the root user or processes with appropriate capabilities can successfully restore these permission bits.

### uid/gid Restoration Behavior

During extraction, the behavior for restoring file uid/gid is as follows:

- The uid/gid recorded in the tar archive will be read and attempted to be restored to the extracted file
- Whether the restoration is successful depends on the permissions of the executing process and operating system restrictions
- Regular users can typically only set the file owner to their own uid/gid, not to other users

### Entry Count Limitation for One-Click Extraction

The one-click extraction method of [Tar](./tar_package_api/tar_package_classes.md#class-tar) does not limit the total number of extracted entries. If the archive contains a large number of entries, it may result in resource exhaustion or prolonged processing time.

To limit the number of extracted entries, it is recommended to use [TarReader](./tar_package_api/tar_package_classes.md#class-tarreadert) and add custom limits during iteration.

## API List

### Classes

|                 Class Name              |                Function                 |
| --------------------------------- | ---------------------------------- |
| [Tar](./tar_package_api/tar_package_readerwriter.md#class-tar) |  tar file operation class.      |
| [TarEntry](./tar_package_api/tar_package_entry.md#class-tarentry) | Represents a tar file entry.      |
| [V7TarEntry](./tar_package_api/tar_package_entry.md#class-v7tarentry) | Represents a V7 tar file entry.      |
| [PosixTarEntry](./tar_package_api/tar_package_entry.md#class-posixtarentry) | Represents a Posix tar file entry.      |
| [UstarTarEntry](./tar_package_api/tar_package_entry.md#class-ustartarentry) | Represents a USTAR tar file entry.      |
| [GnuTarEntry](./tar_package_api/tar_package_entry.md#class-gnutarentry) | Represents a GNU tar file entry.      |
| [PaxTarEntry](./tar_package_api/tar_package_entry.md#class-paxtarentry) | Represents a Pax tar file entry.      |
| [TarReader](./tar_package_api/tar_package_readerwriter.md#class-tarreadert) | Reader for reading tar files.      |
| [TarWriter](./tar_package_api/tar_package_readerwriter.md#class-tarwritert) | Writer for writing tar files.      |

### Enums

|                 Enum Name              |                Function                 |
| --------------------------------- | ---------------------------------- |
| [TarEntryFormat](./tar_package_api/tar_package_enums.md#enum-tarentryformat) | tar entry format.      |
| [TarEntryType](./tar_package_api/tar_package_enums.md#enum-tarentrytype) | tar entry type.      |

### Exception Classes

|                 Exception Class Name              |                Function                 |
| --------------------------------- | ---------------------------------- |
| [TarException](./tar_package_api/tar_package_exceptions.md#class-tarexception) | Exception class for the `tar` package.      |
