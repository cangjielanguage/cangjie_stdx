# Cangjie Programming Language Extension Library Overview

The Cangjie programming language extension library (stdx) contains several packages that provide related functionalities.

The standard library offers the most commonly used APIs for developers, while the extension library focuses on specific domains. For example, the `compress` package provides compression and decompression capabilities, the `crypto` package offers encryption and decryption functionalities, and the `net` package specializes in efficient network protocol parsing and communication.

> **Note:**
>
> Currently, the officially provided extension libraries are not bundled with the Cangjie compiler and toolchain. Users need to download them separately.

## Usage Guide

### Package Dependencies

| Import Library Name                                                            |  Dependent Packages |
| ------------------------------------------------------------------ | ------------------    |
| import stdx.actors.* | stdx.actors |
| import stdx.actors.macros.* | stdx.actors.macros |
| import stdx.aspectCJ.* | stdx.aspectCJ |
| import stdx.compress.zlib.* | stdx.compress.zlib |
| import stdx.crypto.common.* | stdx.crypto.common、stdx.encoding.base64 |
| import stdx.crypto.crypto.* | stdx.crypto.crypto、stdx.crypto.digest |
| import stdx.crypto.digest.* | stdx.crypto.digest |
| import stdx.crypto.keys.* | stdx.crypto.keys、stdx.crypto.x509、stdx.encoding.hex、stdx.encoding.base64、stdx.crypto.crypto、stdx.crypto.digest |
| import stdx.crypto.kit.*  | stdx.crypto.keys、stdx.crypto.x509、stdx.encoding.hex、stdx.crypto.crypto、stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64 |
| import stdx.crypto.x509.* | stdx.crypto.x509、stdx.encoding.hex、stdx.encoding.base64、stdx.crypto.crypto、stdx.crypto.digest |
| import stdx.effect.*   | stdx.effect |
| import stdx.encoding.hex.* | stdx.encoding.hex |
| import stdx.encoding.base64.* | stdx.encoding.base64 |
| import stdx.encoding.json.* | stdx.encoding.json、stdx.serialization.serialization |
| import stdx.encoding.json.stream.* | stdx.encoding.json.stream|
| import stdx.encoding.url.* | stdx.encoding.url |
| import stdx.log.* | stdx.log |
| import stdx.logger.* | stdx.logger |
| import stdx.serialization.serialization.* | stdx.serialization.serialization |
| import stdx.fuzz.fuzz.* | stdx.fuzz.fuzz |
| import stdx.net.http .* | stdx.net.http、stdx.net.tls、stdx.logger、stdx.log、stdx.encoding.url、stdx.encoding.json.stream、stdx.crypto.x509 、stdx.encoding.hex、stdx.encoding.base64、stdx.crypto.crypto、stdx.crypto.digest |
| import stdx.net.tls.* | stdx.net.tls、stdx.crypto.x509、stdx.encoding.hex、stdx.encoding.base64、stdx.crypto.crypto、stdx.crypto.digest |
| import stdx.net.tls.common.* | stdx.net.tls.common、stdx.crypto.x509、stdx.encoding.hex、stdx.crypto.crypto、stdx.crypto.digest、stdx.crypto.common、stdx.encoding.base64 |
| import stdx.unittest.data.* | stdx.encoding.json、stdx.serialization.serialization |

When importing the above packages in code and compiling with the `cjc` command, the linking order must strictly follow the package dependencies listed above. If using `cjpm`, this is not necessary.

When using static libraries, importing `crypto` and `net` libraries requires additional system symbols. On `Windows` OS, add `-lcrypt32`, and on `Linux` OS, add `-ldl`. When using static libraries, importing `syntax` library requires additional system symbols. On `Windows` OS, add `-lc++ -lunwind`, on `macOS` OS, add `-lc++`, on `Linux` OS, add `-lstdc++ -lgcc_s`, on `Android` OS, add `-lc++ -lunwind`, and `iOS` OS, add `-lc++`. 

### cjc Command Example

For an introduction to `cjc` and compilation, refer to the Cangjie User Manual.

```cangjie
import stdx.actors.*
import stdx.actors.macros.*
import stdx.aspectCJ.*
import stdx.compress.zlib.*
import stdx.crypto.crypto.*
import stdx.crypto.digest.*
import stdx.crypto.keys.*
import stdx.crypto.x509.*
import stdx.encoding.hex.*
import stdx.encoding.base64.*
import stdx.encoding.json.*
import stdx.encoding.url.*
import stdx.encoding.json.stream.*
import stdx.net.tls.*
import stdx.net.http.*
import stdx.log.*
import stdx.logger.*
import stdx.serialization.serialization.*
main() {
    0
}
```

Compilation commands for Linux and macOS:

```shell
cjc main.cj -L $CANGJIE_STDX_PATH -lstdx.actors -lstdx.aspectCJ -lstdx.encoding.json -lstdx.serialization.serialization -lstdx.net.http -lstdx.net.tls -lstdx.logger -lstdx.log -lstdx.encoding.url -lstdx.encoding.json.stream -lstdx.crypto.keys -lstdx.crypto.x509 -lstdx.encoding.hex -lstdx.encoding.base64 -lstdx.crypto.crypto -lstdx.crypto.digest -lstdx.compress.zlib -lstdx.compress -ldl --import-path $CANGJIE_STDX_PATH -o main.out
```

Windows compilation command:

```shell
cjc main.cj -L $CANGJIE_STDX_PATH -lstdx.actors -lstdx.aspectCJ -lstdx.encoding.json -lstdx.serialization.serialization -lstdx.net.http -lstdx.net.tls -lstdx.logger -lstdx.log -lstdx.encoding.url -lstdx.encoding.json.stream -lstdx.crypto.keys -lstdx.crypto.x509 -lstdx.encoding.hex -lstdx.encoding.base64 -lstdx.crypto.crypto -lstdx.crypto.digest -lstdx.compress.zlib -lstdx.compress -lcrypt32 --import-path $CANGJIE_STDX_PATH -o main.out
```

`CANGJIE_STDX_PATH` is the path to the stdx library.

For example, on Linux systems:

```shell
export CANGJIE_STDX_PATH=/target/linux_x86_64_cjnative/dynamic/stdx
```

Before running, ensure the extension library path is set:

- On Linux: Set in `LD_LIBRARY_PATH`
- On Windows: Set in `PATH`
- On macOS: Set in `DYLD_LIBRARY_PATH`

### cjpm Usage Example

For an introduction to `cjpm` and usage, refer to the cjpm manual.

Add the following configuration to `cjpm.toml`:

```text
[target.x86_64-unknown-linux-gnu]
  [target.x86_64-unknown-linux-gnu.bin-dependencies]
    path-option = ["${CANGJIE_STDX_PATH}"]
```

In the above configuration, `x86_64-unknown-linux-gnu` represents the system architecture information, which can be obtained via `cjc -v`. Replace it with your system's architecture information.
`CANGJIE_STDX_PATH` is the path to the stdx library.

> **Note:**
>
> In cross-compilation scenarios, if there is a need to develop custom macro packages and their business logic must rely on stdx for implementation, the stdx path for the local development platform must also be configured in addition to that for the target runtime platform.

## Package List

stdx includes several packages that offer rich extension functionalities:

| Package Name                                                     | Functionality      |
| ---------------------------------------------------------- | --------- |
| [actors](./actors/actors_package_overview.md)    | The `actors` package provides the foundational capabilities for the actor programming model. |
| [actors.macros](./actors/macros/macros_package_overview.md) | The `actors.macros` package provides the ability to transform a class into an active object. |
| [aspectCJ](./aspectCJ/aspectCJ_package_overview.md) | The aspectCJ package provides Aspect-Oriented Programming (AOP) capabilities in Cangjie. |
| [compress.zlib](./compress/zlib/zlib_package_overview.md)                        | The compress package provides compression and decompression functionalities. |
| [crypto.common](./crypto/common/crypto_common_package_overview.md)             | The common package provides interfaces related to encryption and decryption.  |
| [crypto.crypto](./crypto/crypto/crypto_package_overview.md)                        | The crypto package provides secure encryption capabilities. |
| [crypto.digest](./crypto/digest/crypto_digest_package_overview.md)                        | The digest package provides commonly used message digest algorithms. |
| [crypto.keys](./crypto/keys/keys_package_overview.md)                        | The keys package provides asymmetric encryption and signature algorithms. |
| [crypto.kit](./crypto/kit/crypto_kit_package_overview.md)                      | The kit package provides a default implementation of [CryptoKit](./crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-cryptokit), along with the capabilities of a random number generator and decoding DER and PEM. |
| [crypto.x509](./crypto/x509/x509_package_overview.md)                        | The x509 package provides functionalities for handling digital certificates. |
| [effect](./effect/effect_package_overview.md)                                | The effect package is a user-level API in Cangjie for using Effect Handlers. It is an experimental feature and requires the use of a Cangjie compiler that supports this mechanism. |
| [encoding.base64](./encoding/base64/base64_package_overview.md)                        | The base package provides Base64 encoding and decoding for strings.|
| [encoding.hex](./encoding/hex/hex_package_overview.md)                        | The hex package provides Hex encoding and decoding for strings.|
| [encoding.json](./encoding/json/json_package_overview.md)                        | The json package is used for processing JSON data, enabling mutual conversion between String, JsonValue, and DataModel.|
| [encoding.json.stream](./encoding/json_stream/json_stream_package_overview.md)                        | The json.stream package is primarily used for mutual conversion between Cangjie objects and JSON data streams.|
| [encoding.url](./encoding/url/url_package_overview.md)                        | The url package provides URL-related capabilities, including parsing URL components, encoding and decoding URLs, and merging URLs or paths.|
| [fuzz](./fuzz/fuzz_package_overview.md)                        | The fuzz package provides developers with a coverage-guided fuzz engine for Cangjie and corresponding interfaces, allowing developers to write code to test APIs. |
| [log](./log/log_package_overview.md) | The log package provides logging-related capabilities. |
| [logger](./logger/logger_package_overview.md) | The logger package provides text and JSON format logging functionalities. |
| [net.http](./net/http/http_package_overview.md)                        | The http package provides server and client implementations for HTTP/1.1, HTTP/2, and WebSocket protocols. |
| [net.tls](./net/tls/tls_package_overview.md)                        | The tls package is used for secure encrypted network communication, providing capabilities such as creating TLS servers, performing TLS handshakes based on protocols, sending and receiving encrypted data, and resuming TLS sessions.|
| [net.tls.common](./net/tls/common/tls_common_package_overview.md)   | The common package provides TLS-related abstract interfaces for adapting to multiple TLS implementations. |
| [serialization](./serialization/serialization_package_overview.md)                        | The serialization package provides serialization and deserialization capabilities. |
| [unittest.data](./unittest/data/data_package_overview.md)                        | The unittest module provides extended unit testing capabilities. |
