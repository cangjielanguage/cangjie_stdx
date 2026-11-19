# stdx.net.http

## Feature Overview

The http package provides server and client implementations for HTTP/1.1, HTTP/2, and WebSocket protocols.

For detailed protocol specifications, please refer to [RFC 9110](https://httpwg.org/specs/rfc9110.html), [9112](https://httpwg.org/specs/rfc9112.html), [9113](https://httpwg.org/specs/rfc9113.html), [9218](https://httpwg.org/specs/rfc9218.html), [7541](https://httpwg.org/specs/rfc7541.html), etc.

This package requires external dependencies on `OpenSSL 3`'s `ssl` and `crypto` dynamic library files. Therefore, the following tools must be installed before use:

- For `Linux` operating systems:
    - If the system's package manager supports installing the `OpenSSL 3` development toolkit, you can install it this way. Ensure the system installation directory contains dynamic library files such as `libssl.so`, `libssl.so.3`, `libcrypto.so`, and `libcrypto.so.3`. For example, on `Ubuntu 22.04`, you can use the command `sudo apt install libssl-dev` to install the `libssl-dev` toolkit.
    - If the above method is unavailable, you can manually download and compile the `OpenSSL 3.x.x` source code. Ensure the installation directory contains `libssl.so`, `libssl.so.3`, `libcrypto.so`, and `libcrypto.so.3`. Then, choose one of the following methods to ensure the system linker can locate these files:
        - If OpenSSL is not installed on the system, install it directly to the system path.
        - For custom installation directories, add the directory containing these files to the environment variables `LD_LIBRARY_PATH` and `LIBRARY_PATH`.
- For `Windows` operating systems:
    - Manually download and compile the `OpenSSL 3.x.x` source code for x64 architecture, or download and install a third-party precompiled `OpenSSL 3.x.x` developer package.
    - Ensure the installation directory contains library files such as `libssl.dll.a` (or `libssl.lib`), `libssl-3-x64.dll`, `libcrypto.dll.a` (or `libcrypto.lib`), and `libcrypto-3-x64.dll`.
    - Add the directory containing `libssl.dll.a` (or `libssl.lib`) and `libcrypto.dll.a` (or `libcrypto.lib`) to the `LIBRARY_PATH` environment variable. Add the directory containing `libssl-3-x64.dll` and `libcrypto-3-x64.dll` to the `PATH` environment variable.
- For `macOS` operating systems:
    - Use `brew install openssl@3` to install, ensuring the system installation directory contains dynamic library files `libcrypto.dylib` and `libcrypto.3.dylib`.
    - If the above method is unavailable, manually download and compile the `OpenSSL 3.x.x` source code. Ensure the installation directory contains `libcrypto.dylib` and `libcrypto.3.dylib`. Then, choose one of the following methods to ensure the system linker can locate these files:
        - If OpenSSL is not installed on the system, install it directly to the system path.
        - For custom installation directories, add the directory containing these files to the environment variables `DYLD_LIBRARY_PATH` and `LIBRARY_PATH`.
- For `Android` operating systems:
    - Since `Android` ships with a stripped-down version of `OpenSSL` by default, some interfaces may throw exceptions due to missing symbols. Therefore, users need to compile and install a complete `OpenSSL 3.x.x` version themselves.
    - Download the `OpenSSL 3.x.x` source code and use Android NDK to cross-compile dynamic library files for the target architectures (currently only `arm64-v8a` is supported). Ensure the build artifacts include `libssl.so`, `libssl.so.3`, `libcrypto.so`, and `libcrypto.so.3`.
    - Add the directory containing these files to the environment variables `LD_LIBRARY_PATH`.
- For `HarmonyOS` operating systems:
    - Due to system restrictions in `HarmonyOS` 6.0 and above, `stdx` cannot directly access the system's built-in `OpenSSL`, users need to compile `OpenSSL` dynamic libraries for `HarmonyOS` and package them into the application.
    - For compiling `OpenSSL` for `HarmonyOS`, refer to [OHOS Cangjie SDK Build Guide](https://gitcode.com/Cangjie/cangjie_build/blob/main/docs/linux_ohos_toolchain.md).
    - Package the compiled dynamic library files `libcrypto_openssl.z.so` and `libssl_openssl.z.so` into the application and ensure they can be correctly loaded at runtime.

If the `OpenSSL 3` package is not installed or an older version is installed, the program may fail to function and throw TLS-related exceptions.

### HTTP

Users can select the HTTP protocol version, such as HTTP/1.1 or HTTP/2. Most APIs in the http package do not distinguish between these versions. Only when using version-specific features (e.g., chunked transfer-encoding in HTTP/1.1 or server push in HTTP/2) is such distinction necessary.

The http library defaults to HTTP/1.1. To use HTTP/2, developers must configure TLS for the Client/Server and set the ALPN value to `h2`. Upgrading from HTTP/1.1 to HTTP/2 via `Upgrade: h2c` is not supported.

When the request does not explicitly specify the HTTP/1.1 version, and the ALPN protocol list in the Client's TLS configuration contains `h2`, the Client attempts to establish an HTTP/2 connection: if the TLS handshake succeeds but the ALPN negotiation result is not `h2` (e.g., the server selects `http/1.1`, or does not respond with an ALPN extension), the Client automatically falls back to HTTP/1.1 and resends the request. If the TLS handshake itself fails (e.g., the two ends' ALPN protocol lists have no intersection and the server sends a no_application_protocol alert), the request throws an exception without automatic fallback; therefore, ensure that the ALPN configurations of the Client and the Server have a common protocol. On the Server side, the connection is served with either HTTP/2 or HTTP/1.1 automatically, according to the ALPN negotiation result of the TLS handshake.

- Users construct a Client instance via [ClientBuilder](./http_package_api/http_package_classes.md#class-clientbuilder), specifying parameters such as httpProxy, logger, cookieJar, auto-redirect, connection pool size, etc.

- Users construct a Server instance via [ServerBuilder](./http_package_api/http_package_classes.md#class-serverbuilder), specifying parameters such as addr, port, logger, distributor, etc.

If users need to set their own Logger, it must be thread-safe.

Most parameters of Client and Server cannot be modified after construction. To change them, users must construct a new Client or Server instance. If a parameter supports dynamic modification, this implementation will provide explicit functionality, such as hot updates for Server-side cert and CA.

- Using a Client instance, users can send HTTP requests and receive HTTP responses.

- Using a Server instance, users can configure request forwarding handlers and start an HTTP server. In the server handler, users can obtain detailed request information from the client via HttpContext and construct responses to send back.

The Server creates corresponding ProtocolService instances based on client requests. A single Server instance can simultaneously support both HTTP/1.1 and HTTP/2.

- On the client side, users construct requests via HttpRequestBuilder, specifying parameters such as method, url, version, headers, body, trailers, etc. Once constructed, the request cannot be modified.

- On the server side, users construct responses via HttpResponseBuilder, specifying parameters such as status, headers, body, trailers, etc. Once constructed, the response cannot be modified.

Additionally, this implementation provides utility classes for constructing common responses, such as RedirectHandler for redirect responses and NotFoundHandler for 404 responses.

### WebSocket

This implementation provides WebSocket sub-protocol negotiation, including basic frame decoding, reading, message sending, frame encoding, ping, pong, and closing functionalities.

Users upgrade from an HTTP/1.1 or HTTP/2 Client instance to WebSocket protocol via WebSocket.upgradeFromClient, then communicate using the returned WebSocket instance.

In a server-side handler, users upgrade from HTTP/1.1 or HTTP/2 to WebSocket protocol via WebSocket.upgradeFromServer, then communicate using the returned WebSocket instance.

Per protocol:

- In HTTP/1.1, the upgraded WebSocket connection is established over a TCP/TLS connection.
- In HTTP/2, the upgraded WebSocket connection is established over a stream within an HTTP/2 connection.
- In HTTP/1.1, closing terminates the TCP/TLS connection.
- In HTTP/2, closing only terminates the stream on the connection.

## API List

### Functions

| Function Name | Description |
| ------------- | ----------- |
| [handleError(HttpContext, UInt16)](./http_package_api/http_package_funcs.md#func-handleerrorhttpcontext-uint16) | Convenient HTTP request handler for replying to error requests. |
| [notFound(HttpContext)](./http_package_api/http_package_funcs.md#func-notfoundhttpcontext) | Convenient HTTP request handler for replying with a 404 response. |
| [upgrade(HttpContext)](./http_package_api/http_package_funcs.md#func-upgradehttpcontext) | Obtains a StreamingSocket within a handler, useful for protocol upgrades and handling CONNECT requests. |

### Interfaces

| Interface Name | Description |
| ------------- | ----------- |
| [CookieJar](./http_package_api/http_package_interfaces.md#interface-cookiejar) | Tool for managing cookies on the client side. |
| [HttpRequestDistributor](./http_package_api/http_package_interfaces.md#interface-httprequestdistributor) | HTTP request distributor interface that routes requests to corresponding HttpRequestHandlers based on the URL path. |
| [HttpRequestHandler](./http_package_api/http_package_interfaces.md#interface-httprequesthandler) | HTTP request handler. |
| [ProtocolServiceFactory](./http_package_api/http_package_interfaces.md#interface-protocolservicefactory) | Factory for generating `ProtocolService` instances. |

### Classes

| Class Name | Description |
| --------- | ----------- |
| [Client](./http_package_api/http_package_classes.md#class-client) | Client class for sending HTTP/1.1 or HTTP/2 requests. |
| [ClientBuilder](./http_package_api/http_package_classes.md#class-clientbuilder) | Builder for Client instances. Client has no public constructor; users must use ClientBuilder. Version configuration applies to both HTTP/1.1 and HTTP/2. |
| [Cookie](./http_package_api/http_package_classes.md#class-cookie) | Maintains stateful sessions via cookies. |
| [FileHandler](./http_package_api/http_package_classes.md#class-filehandler) | Handles file downloads or uploads. |
| [FuncHandler](./http_package_api/http_package_classes.md#class-funchandler) | Wraps a single function into an HttpRequestHandler. |
| [HttpContext](./http_package_api/http_package_classes.md#class-httpcontext) | HTTP request context, used as a parameter in HttpRequestHandler.handle on the server side. |
| [HttpHeaders](./http_package_api/http_package_classes.md#class-httpheaders) | Represents HTTP message headers and trailers, with CRUD operations. |
| [HttpRequest](./http_package_api/http_package_classes.md#class-httprequest) | HTTP request class. |
| [HttpRequestBuilder](./http_package_api/http_package_classes.md#class-httprequestbuilder) | Constructs HttpRequest instances. |
| [HttpResponse](./http_package_api/http_package_classes.md#class-httpresponse) | HTTP response class. |
| [HttpResponseBuilder](./http_package_api/http_package_classes.md#class-httpresponsebuilder) | Constructs HttpResponse instances. |
| [HttpResponsePusher](./http_package_api/http_package_classes.md#class-httpresponsepusher) | HTTP/2 server push. |
| [HttpResponseWriter](./http_package_api/http_package_classes.md#class-httpresponsewriter) | Writer for HTTP response bodies, allowing user control over the sending process. |
| [NotFoundHandler](./http_package_api/http_package_classes.md#class-notfoundhandler) | Convenient handler for `404 Not Found` responses. |
| [OptionsHandler](./http_package_api/http_package_classes.md#class-optionshandler) | Convenient handler for OPTIONS requests, returning "Allow: OPTIONS, GET, HEAD, POST, PUT, DELETE" headers. |
| [ProtocolService](./http_package_api/http_package_classes.md#class-protocolservice) | HTTP protocol service instance for single client connections, handling request parsing, distribution, and response sending. |
| [RedirectHandler](./http_package_api/http_package_classes.md#class-redirecthandler) | Convenient handler for redirect responses. |
| [Server](./http_package_api/http_package_classes.md#class-server) | HTTP server class. |
| [ServerBuilder](./http_package_api/http_package_classes.md#class-serverbuilder) | Builder for Server instances. |
| [WebSocket](./http_package_api/http_package_classes.md#class-websocket) | Provides WebSocket connection functionalities (read, write, close). Users obtain WebSocket connections via upgradeFrom functions. |
| [WebSocketFrame](./http_package_api/http_package_classes.md#class-websocketframe) | Basic unit for WebSocket reading. |

### Enums

| Enum Name | Description |
| --------- | ----------- |
| [FileHandlerType](./http_package_api/http_package_enums.md#enum-filehandlertype) | Sets `FileHandler` to upload or download mode. |
| [Protocol](./http_package_api/http_package_enums.md#enum-protocol) | Defines HTTP protocol types. |
| [WebSocketFrameType](./http_package_api/http_package_enums.md#enum-websocketframetype) | Defines `WebSocketFrame` types. |

### Structs

| Struct Name | Description |
| ----------- | ----------- |
| [HttpStatusCode](./http_package_api/http_package_structs.md#struct-httpstatuscode) | Represents 3-digit HTTP status codes. |
| [ServicePoolConfig](./http_package_api/http_package_structs.md#struct-servicepoolconfig) | Configuration for HTTP Server coroutine pools. |
| [TransportConfig](./http_package_api/http_package_structs.md#struct-transportconfig) | Transport layer configuration for server connections. |

### Exception Classes

| Exception Class Name | Description |
| ------------------- | ----------- |
| [ConnectionException](./http_package_api/http_package_exceptions.md#class-connectionexception) | TCP connection exception for HTTP. |
| [CoroutinePoolRejectException](./http_package_api/http_package_exceptions.md#class-coroutinepoolrejectexception) | Exception for rejected coroutine pool requests. |
| [HttpException](./http_package_api/http_package_exceptions.md#class-httpexception) | Generic HTTP exception. |
| [HttpStatusException](./http_package_api/http_package_exceptions.md#class-httpstatusexception) | HTTP response status exception. |
| [HttpTimeoutException](./http_package_api/http_package_exceptions.md#class-httptimeoutexception) | HTTP timeout exception. |
| [WebSocketException](./http_package_api/http_package_exceptions.md#class-websocketexception) | Generic WebSocket exception. |