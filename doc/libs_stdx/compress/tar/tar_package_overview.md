# stdx.compress.tar

## 功能介绍

compress.tar 提供了归档和读取功能。

归档是一种将多个文件或目录组织成单个文件的方法，通常用于将多个文件或目录压缩成单个文件，并保存在磁盘上。归档文件通常包含文件的元数据（如文件名、权限、时间戳等）以及文件的内容。常见的归档格式有 tar、zip、rar 等。

本包实现了 tar 归档格式，支持 V7、USTAR、PAX 和 GNU 四种格式。tar 格式广泛用于备份和分发文件的场景中。

> **说明：**
>
> 要进行文件压缩请使用 stdx.compress.zlib 进行压缩或使用 stdx.compress 的组合工具 TarGzip 进行归档压缩操作。

## 规格说明

### 功能限制

本包当前版本存在以下功能限制：

- **不支持 ACL（访问控制列表）**：归档和解归档操作不会处理文件的 ACL 信息。
- **不支持 xattr（扩展属性）**：归档和解归档操作不会处理文件的扩展属性。
- **暂不支持特殊文件类型**：块设备文件、字符设备文件和管道文件（FIFO）暂不支持归档和解归档。

### setuid/setgid 权限位处理

解归档时，setuid/setgid 权限位会原样恢复到文件上。但实际是否恢复成功，取决于以下因素：

- 执行解归档操作的用户/进程权限
- 操作系统的安全限制

在大多数 Unix/Linux 系统中，普通用户无法设置 setgid 位，只有 root 用户或具有相应能力的进程才能成功恢复这些权限位。

### uid/gid 恢复行为

解归档时，对于文件 uid/gid 的恢复行为如下：

- tar 归档文件中记录的 uid/gid 会被读取并尝试恢复到解压后的文件上
- 实际恢复是否成功，取决于执行进程的权限和操作系统限制
- 普通用户通常只能将文件的所有者设置为自己的 uid/gid，无法设置为其他用户

### 一键解压的条目数量限制

[Tar](./tar_package_api/tar_package_classes.md#class-tar) 的一键解压方法未对解压的条目总数做限制。如果归档文件包含大量条目，可能导致资源耗尽或处理时间过长。

如需对解压条目数量进行限制，建议使用 [TarReader](./tar_package_api/tar_package_classes.md#class-tarreadert)，在迭代过程中添加自定义的限制。

## API 列表

### 类

|                 类名              |                功能                 |
| --------------------------------- | ---------------------------------- |
| [Tar](./tar_package_api/tar_package_classes.md#class-tar) |  tar 文件操作类。      |
| [TarEntry](./tar_package_api/tar_package_classes.md#class-tarentry) | 表示 tar 文件条目。      |
| [V7TarEntry](./tar_package_api/tar_package_classes.md#class-v7tarentry) | 表示 V7 tar 文件条目。      |
| [PosixTarEntry](./tar_package_api/tar_package_classes.md#class-posixtarentry) | 表示 Posix tar 文件条目。      |
| [UstarTarEntry](./tar_package_api/tar_package_classes.md#class-ustartarentry) | 表示 USTAR tar 文件条目。      |
| [GnuTarEntry](./tar_package_api/tar_package_classes.md#class-gnutarentry) | 表示 GNU tar 文件条目。      |
| [PaxTarEntry](./tar_package_api/tar_package_classes.md#class-paxtarentry) | 表示 Pax tar 文件条目。      |
| [TarReader](./tar_package_api/tar_package_classes.md#class-tarreadert) | 用于读取 tar 文件的读取器。      |
| [TarWriter](./tar_package_api/tar_package_classes.md#class-tarwritert) | 用于写入 tar 文件的写入器。      |

### 枚举

|                 枚举名              |                功能                 |
| --------------------------------- | ---------------------------------- |
| [TarEntryFormat](./tar_package_api/tar_package_enums.md#enum-tarentryformat) | tar 条目格式。      |
| [TarEntryType](./tar_package_api/tar_package_enums.md#enum-tarentrytype) | tar 条目类型。      |

### 异常类

|                 异常类名              |                功能                 |
| --------------------------------- | ---------------------------------- |
| [TarException](./tar_package_api/tar_package_exceptions.md#class-tarexception) | `tar` 包的异常类。      |
