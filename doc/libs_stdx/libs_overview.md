# 仓颉编程语言扩展库概述

仓颉编程语言扩展库（stdx）包含多个功能包，为开发者提供领域专用的扩展能力。

与标准库提供的通用 API 不同，扩展库专注于特定领域的功能实现。例如，compress 包提供压缩与解压缩能力，crypto 包提供加解密相关能力，net 包专注于网络协议解析和通信能力。

> **说明：**
>
> 目前，官方提供的扩展库不随仓颉编译器、工具链一起发布，需要用户单独下载。

## 平台支持说明

扩展库提供的 API 支持在如下操作系统上运行：

> **注意：**
>
> 部分 API 不支持在特定的操作系统运行，详情请参见对应 API 描述。

| 操作系统       | CPU 架构  | 环境及其版本要求 |
| ------------- | --------- | --------------- |
| Linux         | x86_64    | glibc 2.22；Linux Kernel 4.12 或更高版本；系统安装 libstdc++ 6.0.24 或更高版本 |
| Linux         | aarch64   | glibc 2.27；Linux Kernel 4.15 或更高版本；系统安装 libstdc++ 6.0.24 或更高版本 |
| Windows       | x86_64    | Windows 10 或更高版本 |
| macOS         | aarch64   | macOS 12.0 或更高版本 |
| OpenHarmony   | aarch64   | OpenHarmony 5.1 或更高版本 |
| OpenHarmony   | arm32     | OpenHarmony 5.1 或更高版本 |
| HarmonyOS     | aarch64   | HarmonyOS 5.1 或更高版本 |
| iOS           | aarch64   | iOS 11 或更高版本（ast 库需要 iOS 12 或更高版本） |
| Android       | aarch64   | Android API 26 或更高版本 |

## 使用指导

### 包依赖

| 导入库名                                  | 依赖包                                                                                                                                                                                                                         |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| import stdx.actors.*                      | stdx.actors                                                                                                                                                                                                                    |
| import stdx.actors.macros.*               | stdx.actors.macros                                                                                                                                                                                                             |
| import stdx.aspect_cj.*                    | stdx.aspect_cj                                                                                                                                                                                                                  |
| import stdx.chir.*                         | stdx.chir                                                                                                                                                                                                                       |
| import stdx.compress.zlib.*               | stdx.compress.zlib                                                                                                                                                                                                             |
| import stdx.compress.tar.*               | stdx.compress.tar                                                                                                                                                                                                             |
| import stdx.crypto.common.*               | stdx.crypto.common、stdx.encoding.base64                                                                                                                                                                                       |
| import stdx.crypto.crypto.*               | stdx.crypto.crypto、stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64                                                                                                                                               |
| import stdx.crypto.digest.*               | stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64                                                                                                                                                                   |
| import stdx.crypto.keys.*                 | stdx.crypto.keys、stdx.crypto.x509、stdx.encoding.hex、stdx.crypto.crypto、stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64                                                                                        |
| import stdx.crypto.kit.*                  | stdx.crypto.keys、stdx.crypto.x509、stdx.encoding.hex、stdx.crypto.crypto、stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64                                                                                        |
| import stdx.crypto.x509.*                 | stdx.crypto.x509、stdx.encoding.hex、stdx.crypto.crypto、stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64                                                                                                          |
| import stdx.effect.*                      | stdx.effect                                                                                                                                                                                                                    |
| import stdx.encoding.hex.*                | stdx.encoding.hex                                                                                                                                                                                                              |
| import stdx.encoding.base64.*             | stdx.encoding.base64                                                                                                                                                                                                           |
| import stdx.encoding.json.*               | stdx.encoding.json、stdx.serialization.serialization                                                                                                                                                                           |
| import stdx.encoding.json.stream.*        | stdx.encoding.json.stream                                                                                                                                                                                                      |
| import stdx.encoding.url.*                | stdx.encoding.url                                                                                                                                                                                                              |
| import stdx.log.*                         | stdx.log                                                                                                                                                                                                                       |
| import stdx.logger.*                      | stdx.logger                                                                                                                                                                                                                    |
| import stdx.serialization.serialization.* | stdx.serialization.serialization                                                                                                                                                                                               |
| import stdx.syntax.*                      | stdx.syntax                                                                                                                                                                                               |
| import stdx.fuzz.*                   | stdx.fuzz                                                                                                                                                                                                                 |
| import stdx.net.http .*                   | stdx.net.http、stdx.net.tls.common、stdx.logger、stdx.log、stdx.encoding.url、stdx.encoding.json.stream、stdx.crypto.x509、stdx.encoding.hex、stdx.crypto.crypto、stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64 |
| import stdx.net.tls.*                     | stdx.net.tls、stdx.net.tls.common、stdx.crypto.x509、stdx.encoding.hex、stdx.crypto.crypto、stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64                                                                       |
| import stdx.net.tls.common.*              | stdx.net.tls.common、stdx.crypto.x509、stdx.encoding.hex、stdx.crypto.crypto、stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64                                                                                     |
| import stdx.plugin.manager.*              | stdx.plugin.manager                                                                                                                                                                                                             |
| import stdx.unittest.data.*               | stdx.encoding.json、stdx.serialization.serialization                                                                                                                                                                           |

使用 cjc 编译时，需要按照上表列出的依赖顺序进行链接。如果使用 cjpm 管理项目，则无需关注依赖顺序。

使用静态库时，不同平台需要添加额外的系统库依赖：

| 导入库 | Windows | Linux | macOS | Android | iOS |
| ------ | ------- | ----- | ----- | ------- | --- |
| crypto、net | `-lcrypt32` | `-ldl` | - | - | - |
| syntax | `-lc++ -lunwind` | `-lstdc++ -lgcc_s` | `-lc++` | `-lc++ -lunwind` | `-lc++` |

### cjc 使用命令示例

cjc 的介绍和编译请查看 cangjie 用户手册。

<!-- code_no_check -->
```cangjie
import stdx.actors.*
import stdx.actors.macros.*
import stdx.aspect_cj.*
import stdx.compress.zlib.*
import stdx.compress.tar.*
import stdx.crypto.crypto.*
import stdx.crypto.digest.*
import stdx.crypto.keys.*
import stdx.crypto.x509.*
import stdx.effect.*
import stdx.encoding.hex.*
import stdx.encoding.base64.*
import stdx.encoding.json.*
import stdx.encoding.url.*
import stdx.encoding.json.stream.*
import stdx.net.tls.*
import stdx.net.http.*
import stdx.log.*
import stdx.logger.*
import stdx.syntax.*
import stdx.serialization.serialization.*

main() {
    0
}
```

Linux 和 macOS 的编译命令：

```shell
cjc main.cj -L $CANGJIE_STDX_PATH -lstdx.actors -lstdx.aspect_cj -lstdx.effect -lstdx.encoding.json -lstdx.serialization.serialization -lstdx.net.http -lstdx.net.tls -lstdx.net.tls.common -lstdx.logger -lstdx.log -lstdx.encoding.url -lstdx.encoding.json.stream -lstdx.crypto.kit -lstdx.crypto.keys -lstdx.crypto.x509 -lstdx.encoding.hex -lstdx.crypto.crypto -lstdx.crypto.digest -lstdx.crypto.common -lstdx.encoding.base64 -lstdx.compress.zlib -lstdx.compress.tar -lstdx.syntax -lstdx.syntaxFFI -ldl --import-path $CANGJIE_STDX_PATH -o main.out
```

Windows 编译命令：

```bat
cjc main.cj -L %CANGJIE_STDX_PATH% -lstdx.actors -lstdx.aspect_cj -lstdx.effect -lstdx.encoding.json -lstdx.serialization.serialization -lstdx.net.http -lstdx.net.tls -lstdx.net.tls.common -lstdx.logger -lstdx.log -lstdx.encoding.url -lstdx.encoding.json.stream -lstdx.crypto.kit -lstdx.crypto.keys -lstdx.crypto.x509 -lstdx.encoding.hex -lstdx.crypto.crypto -lstdx.crypto.digest -lstdx.crypto.common -lstdx.encoding.base64 -lstdx.compress.zlib -lstdx.compress.tar -lstdx.syntax -lstdx.syntaxFFI -lcrypt32 --import-path %CANGJIE_STDX_PATH% -o main.out
```

其中 `CANGJIE_STDX_PATH` 为扩展库的安装路径。不同系统设置示例：

Linux/macOS（bash）：

```shell
export CANGJIE_STDX_PATH=/target/linux_x86_64_cjnative/dynamic/stdx
```

Windows：

```bat
set CANGJIE_STDX_PATH=C:\target\windows_x86_64_cjnative\dynamic\stdx
```

使用动态库时，运行程序前需要设置扩展库路径。不同系统设置示例：

Linux：

```shell
export LD_LIBRARY_PATH=/target/linux_x86_64_cjnative/dynamic/stdx:$LD_LIBRARY_PATH
```

macOS：

```shell
export DYLD_LIBRARY_PATH=/target/darwin_aarch64_cjnative/dynamic/stdx:$DYLD_LIBRARY_PATH
```

Windows：

```bat
set PATH=C:\target\windows_x86_64_cjnative\dynamic\stdx;%PATH%
```

### cjpm 使用示例

cjpm 的介绍和使用请查看 cjpm 手册。

在 `cjpm.toml` 中添加以下配置：

```text
[target.x86_64-unknown-linux-gnu]
  [target.x86_64-unknown-linux-gnu.bin-dependencies]
    path-option = ["${CANGJIE_STDX_PATH}"]
```

其中 `x86_64-unknown-linux-gnu` 为系统架构信息，可通过 `cjc -v` 命令获取，需要根据实际环境进行替换。`CANGJIE_STDX_PATH` 为扩展库的安装路径。

> **注意：**
>
> 在交叉编译的场景下，如果有自行开发宏包的需求，且需要依赖 stdx 实现宏包中的业务逻辑，那么除了目标运行平台以外，还需要配置本地开发平台的 stdx 路径。

## 包列表

stdx 包含多个功能包，提供丰富的扩展能力：

| 包名                                                                             | 功能                                                                                                                                                              |
|--------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [actors](./actors/actors_package_overview.md)                                  | actors 包提供 actor 编程模型的基础能力。                                                                                                                                     |
| [actors.macros](./actors/macros/macros_package_overview.md)                    | actors.macros 包提供将 class 转换为 active object 的能力。                                                                                                                  |
| [aspect_cj](./aspect_cj/aspect_cj_package_overview.md)                            | aspect_cj 包提供仓颉语言中面向切面编程（Aspect Oriented Programming, AOP）的能力。                                                                                            |
| [chir](./chir/chir_package_overview.md)                                        | chir 包提供类型系统与 CHIR 声明表示，用于构建和遍历 CHIR 中间表示。                                                                                                           |
| [compress.zlib](./compress/zlib/zlib_package_overview.md)                      | compress.zlib 包提供压缩与解压缩能力。                                                                                                                                             |
| [compress.tar](./compress/tar/tar_package_overview.md)                      | compress.tar 包提供 tar 归档和读取功能。                                                                                                                                             |
| [crypto.common](./crypto/common/crypto_common_package_overview.md)             | crypto.common 包提供加解密相关的通用接口。                                                                                                                                      |
| [crypto.crypto](./crypto/crypto/crypto_package_overview.md)                    | crypto.crypto 包提供安全加密能力。                                                                                                                                               |
| [crypto.digest](./crypto/digest/crypto_digest_package_overview.md)             | crypto.digest 包提供常用的消息摘要算法。                                                                                                                                            |
| [crypto.keys](./crypto/keys/keys_package_overview.md)                          | crypto.keys 包提供非对称加密和签名算法。                                                                                                                                             |
| [crypto.kit](./crypto/kit/crypto_kit_package_overview.md)                      | crypto.kit 包提供 [CryptoKit](./crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-cryptokit) 的默认实现，包括随机数生成器及 DER、PEM 解码能力。 |
| [crypto.x509](./crypto/x509/x509_package_overview.md)                          | crypto.x509 包提供数字证书处理功能。                                                                                                                                               |
| [effect](./effect/effect_package_overview.md)                                  | `stdx.effect` 包提供仓颉语言中 Effect Handler 的用户级 API。这是一项实验性功能，需要配合支持该机制的仓颉编译器使用。                                                                      |
| [encoding.base64](./encoding/base64/base64_package_overview.md)                | encoding.base64 包提供 Base64 编码及解码能力。                                                                                                                                      |
| [encoding.hex](./encoding/hex/hex_package_overview.md)                         | encoding.hex 包提供 Hex 编码及解码能力。                                                                                                                                          |
| [encoding.json](./encoding/json/json_package_overview.md)                      | encoding.json 包用于处理 JSON 数据，实现 String、JsonValue、DataModel 之间的相互转换。                                                                                                   |
| [encoding.json.stream](./encoding/json_stream/json_stream_package_overview.md) | encoding.json.stream 包用于仓颉对象与 JSON 数据流之间的互相转换。                                                                                                                         |
| [encoding.url](./encoding/url/url_package_overview.md)                         | encoding.url 包提供 URL 相关能力，包括解析 URL 组件、URL 编解码、URL 或路径合并等。                                                                                                    |
| [fuzz](./fuzz/fuzz_package_overview.md)                                        | fuzz 包为开发者提供基于覆盖率反馈的仓颉 fuzz 引擎及对应的接口，开发者可以编写代码对 API 进行测试。                                                                                                       |
| [log](./log/log_package_overview.md)                                           | log 包提供日志记录相关能力。                                                                                                                                              |
| [logger](./logger/logger_package_overview.md)                                  | logger 包提供文本格式和 JSON 格式的日志打印功能。                                                                                                                                 |
| [net.http](./net/http/http_package_overview.md)                                | net.http 包提供 HTTP/1.1、HTTP/2、WebSocket 协议的服务器端和客户端实现。                                                                                                       |
| [net.tls](./net/tls/tls_package_overview.md)                                   | net.tls 包用于安全加密的网络通信，提供创建 TLS 服务器、基于协议进行 TLS 握手、收发加密数据、恢复 TLS 会话等能力。                                                                                              |
| [net.tls.common](./net/tls/common/tls_common_package_overview.md)              | net.tls.common 包提供 TLS 相关的抽象接口，用于适配多种 TLS 实现。                                                                                                                      |
| [plugin](./plugin/plugin_package_overview.md)                                  | plugin 包提供 CHIR 插件的注册、管理与执行机制。                                                                                                                           |
| [serialization](./serialization/serialization_package_overview.md)             | serialization 包提供序列化与反序列化能力。                                                                                                                                   |
| [syntax](./syntax/syntax_package_overview.md)                                  | syntax 包包含仓颉源码的语法解析器和语法树节点，提供语法解析函数。                                                                                                                       |
| [unittest.data](./unittest/data/data_package_overview.md)                      | unittest.data 包提供单元测试扩展能力。                                                                                                                                         |
| [string_intern](./string_intern/string_intern_package_overview.md)             | string_intern 包提供字符串内联缓存能力。                                                                                                                                    |
