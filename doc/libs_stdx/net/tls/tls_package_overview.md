# stdx.net.tls

## 功能介绍

tls 包用于进行安全加密的网络通信，提供创建 TLS 服务器、基于协议进行 TLS 握手、收发加密数据、恢复 TLS 会话等能力。

本包支持 TLS 1.2 及 TLS 1.3 传输层安全协议通信。

使用本包需要外部依赖 `OpenSSL 3` 的 `ssl` 和 `crypto` 动态库文件，故使用前需安装相关工具：

- 对于 `Linux` 操作系统，可参考以下方式：
    - 如果系统的包管理工具支持安装 `OpenSSL 3` 开发工具包，可通过这个方式安装，并确保系统安装目录下含有 `libssl.so`、`libssl.so.3`、`libcrypto.so` 和 `libcrypto.so.3` 这些动态库文件，例如 `Ubuntu 22.04` 系统上可使用 `sudo apt install libssl-dev` 命令安装 `libssl-dev` 工具包；
    - 如果无法通过上面的方式安装，可自行下载 `OpenSSL 3.x.x` 源码编译安装软件包，并确保安装目录下含有 `libssl.so`、`libssl.so.3`、`libcrypto.so` 和 `libcrypto.so.3` 这些动态库文件，然后可选择下面任意一种方式来保证系统链接器可以找到这些文件：
        - 在系统未安装 OpenSSL 的场景，安装时选择直接安装到系统路径下；
        - 安装在自定义目录的场景，将这些文件所在目录设置到环境变量 `LD_LIBRARY_PATH` 以及 `LIBRARY_PATH` 中。
- 对于 `Windows` 操作系统，可按照以下步骤：
    - 自行下载 `OpenSSL 3.x.x` 源码编译安装 x64 架构软件包或者自行下载安装第三方预编译的供开发人员使用的 `OpenSSL 3.x.x` 软件包；
    - 确保安装目录下含有 `libssl.dll.a`（或 `libssl.lib`）、`libssl-3-x64.dll`、`libcrypto.dll.a`（或 `libcrypto.lib`）、`libcrypto-3-x64.dll` 这些库文件；
    - 将 `libssl.dll.a`（或 `libssl.lib`）、`libcrypto.dll.a`（或 `libcrypto.lib`）所在的目录路径设置到环境变量 `LIBRARY_PATH` 中，将 `libssl-3-x64.dll`、`libcrypto-3-x64.dll` 所在的目录路径设置到环境变量 `PATH` 中。
- 对于 `macOS` 操作系统，可参考以下方式：
    - 使用 `brew install openssl@3` 安装，并确保系统安装目录下含有 `libcrypto.dylib` 和 `libcrypto.3.dylib` 这两个动态库文件；
    - 如果无法通过上面的方式安装，可自行下载 `OpenSSL 3.x.x` 源码编译安装软件包，并确保安装目录下含有 `libcrypto.dylib` 和 `libcrypto.3.dylib` 这两个动态库文件，然后可选择下面任意一种方式来保证系统链接器可以找到这些文件：
        - 在系统未安装 OpenSSL 的场景，安装时选择直接安装到系统路径下；
        - 安装在自定义目录的场景，将这些文件所在目录设置到环境变量 `DYLD_LIBRARY_PATH` 以及 `LIBRARY_PATH` 中。
    > **注意：**
 	>
 	> `macOS` 系统自带的 `OpenSSL` 库不完整，不符合 `stdx` 的需求，使用系统自带的库会导致未知错误。用户必须按照以上步骤正确安装完整的 `OpenSSL` 库并配置环境变量。
- 对于 `Android` 操作系统，可参考以下方式：
    - 由于 `Android` 系统默认自带的 `OpenSSL` 是裁剪版本，部分接口可能找不到符号而抛出异常，因此需要用户自行编译安装完整的 `OpenSSL 3.x.x` 版本；
    - 可自行下载 `OpenSSL 3.x.x` 源码，使用 Android NDK 交叉编译生成对应架构（当前只支持 `arm64-v8a`）的动态库文件，确保编译产物中含有 `libssl.so`、`libssl.so.3`、`libcrypto.so` 和 `libcrypto.so.3` 这些动态库文件；
    - 将这些文件所在目录设置到环境变量 `LD_LIBRARY_PATH` 中。
- 对于 `HarmonyOS` 操作系统，可参考以下方式：
    - 由于 `HarmonyOS 6.0` 及以上版本系统限制，`stdx` 无法直接调用系统内置的 `OpenSSL`，需要用户自行编译 `HarmonyOS` 的 `OpenSSL` 动态库并打包到应用中；
    - 编译 `HarmonyOS` 的 `OpenSSL` 可参考 [OHOS 仓颉 SDK 构建指导书](https://gitcode.com/Cangjie/cangjie_build/blob/main/docs/linux_ohos_toolchain.md)；
    - 将编译好的动态库文件 `libcrypto_openssl.z.so` 和 `libssl_openssl.z.so` 拷贝到应用模块的 `libs/arm64-v8a`（真机）或 `libs/x86_64`（模拟器）目录下，`DevEco Studio` 会将其打包到应用包的对应目录中，确保应用运行时能够正确加载这些库文件。
    - 另外，使用 `DevEco Studio-Cangjie Plugin`（`26.0.0 Beta1` 及以上版本）时，在动态链接 `stdx` 库的场景下，还需要把 `stdx` 模块中的 `libcangjie-dynamicLoader-opensslFFI.so` 打包到应用包中，该动态库用于链接 `OpenSSL`。
    - 用户可将本地仓颉 stdx 库中的 `libcangjie-dynamicLoader-opensslFFI.so` 拷贝到应用模块的 `libs/arm64-v8a`（真机）或 `libs/x86_64`（模拟器）目录下， `DevEco Studio` 会将其打包到应用包的对应目录中。

> **注意：**
>
> 如果未安装 `OpenSSL 3` 软件包或者安装低版本的软件包，程序可能无法使用并抛出相关异常 TlsException: Can not load openssl library or function xxx.。

## API 列表

### 类型别名

| 类型别名                                              | 功能                             |
| ----------------------------------------------------- | -------------------------------- |
| [KeylessDecryptFunc](./tls_package_api/tls_package_type.md#type-keylessdecryptfunc) | 供无私钥握手使用的解密回调函数类型。 |
| [KeylessSignFunc](./tls_package_api/tls_package_type.md#type-keylesssignfunc) | 供无私钥握手使用的签名回调函数类型。 |

### 类

| 类名                                                                                | 功能                                                                                                                                                       |
| ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [DefaultTlsKit](./tls_package_api/tls_package_classes.md#class-defaulttlskit)       | [TlsKit](../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlskit) 的默认实现。用于获取 TLS 服务端、客户端连接和服务端会话。 |
| [KeylessTlsServerConfig](./tls_package_api/tls_package_classes.md#class-keylesstlsserverconfig) | 无私钥服务端配置。       |
| [TlsClientSession](./tls_package_api/tls_package_classes.md#class-tlsclientsession) | 当客户端 TLS 握手成功后，将会生成一个会话，当连接因一些原因丢失后，客户端可以通过这个会话 id 复用此次会话，省略握手流程。                                  |
| [TlsServerSession](./tls_package_api/tls_package_classes.md#class-tlsserversession) | 表示 TLS 会话上下文，用于连接复用时验证客户端合法性。                                                                                   |
| [TlsSocket](./tls_package_api/tls_package_classes.md#class-tlssocket)               | 用于在客户端及服务端间创建加密传输通道。                                                                                                                   |

### 枚举

| 枚举名                                                                                                 | 功能                                                               |
| ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------ |
| [SignatureAlgorithm](./tls_package_api/tls_package_enums.md#enum-signaturealgorithm)                   | 签名算法类型，签名算法用于确保传输数据的身份验证、完整性和真实性。 |
| [SignatureSchemeType](./tls_package_api/tls_package_enums.md#enum-signatureschemetype)                 | 加密算法类型，用于保护网络通信的安全性和隐私性。                   |
| [SignatureType](./tls_package_api/tls_package_enums.md#enum-signaturetype)                             | 签名算法类型，用于认证真实性。                                     |
| [TlsClientIdentificationMode](./tls_package_api/tls_package_enums.md#enum-tlsclientidentificationmode) | 服务端对客户端证书的认证模式。                                     |

### 结构体

| 结构体名                                                                           | 功能               |
| ---------------------------------------------------------------------------------- | ------------------ |
| [CipherSuite](./tls_package_api/tls_package_structs.md#struct-ciphersuite)         | TLS 中的密码套件。 |
| [TlsClientConfig](./tls_package_api/tls_package_structs.md#struct-tlsclientconfig) | 客户端配置。       |
| [TlsServerConfig](./tls_package_api/tls_package_structs.md#struct-tlsserverconfig) | 服务端配置。       |