# Classes

## class Client

```cangjie
public class Client
```

Functionality: Sends HTTP requests, allows immediate closure, etc. Users can send HTTP/1.1 or HTTP/2 requests through a Client instance.

> **Note:**
>
> The [Client](http_package_classes.md#class-client) documentation does not explicitly specify version configuration support; it will take effect for both HTTP/1.1 and HTTP/2.

### prop autoRedirect

```cangjie
public prop autoRedirect: Bool
```

Functionality: Determines whether the client will automatically follow redirects. Status code 304 does not trigger redirection by default.

Type: Bool

### prop connector

```cangjie
public prop connector: (SocketAddress) -> StreamingSocket
```

Functionality: The client calls this function to obtain a connection to the server.

Type: (SocketAddress) -> StreamingSocket

### prop cookieJar

```cangjie
public prop cookieJar: ?CookieJar
```

Functionality: Used to store all client [Cookie](http_package_classes.md#class-cookie) instances. If set to None, [Cookie](http_package_classes.md#class-cookie) functionality will be disabled.

Type: ?[CookieJar](http_package_interfaces.md#interface-cookiejar)

### prop enablePush

```cangjie
public prop enablePush: Bool
```

Functionality: Determines whether the client supports HTTP/2 server push. Default value is true.

Type: Bool

### prop headerTableSize

```cangjie
public prop headerTableSize: UInt32
```

Functionality: Gets the initial value of the client's HTTP/2 HPACK dynamic table. Default value is 4096.

Type: UInt32

### prop httpProxy

```cangjie
public prop httpProxy: String
```

Functionality: Gets the client's HTTP proxy. By default uses the system environment variable `http_proxy`. Represented as a string in the format: `"http://host:port"`, e.g., `"http://192.168.1.1:80"`.

Type: String

### prop httpsProxy

```cangjie
public prop httpsProxy: String
```

Functionality: Gets the client's HTTPS proxy. By default uses the system environment variable `https_proxy`. Represented as a string in the format: `"http://host:port"`, e.g., `"http://192.168.1.1:443"`.

Type: String

### prop initialWindowSize

```cangjie
public prop initialWindowSize: UInt32
```

Functionality: Gets the initial flow control window size for HTTP/2 streams. Default value is 65535, with a valid range of 0 to 2^31 - 1.

Type: UInt32

### prop logger

```cangjie
public prop logger: Logger
```

Functionality: Gets the client's logger. Setting logger.level takes effect immediately. The logger should be thread-safe.

Type: [Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

### prop maxConcurrentStreams

```cangjie
public prop maxConcurrentStreams: UInt32
```

Functionality: Gets the initial maximum number of concurrent HTTP/2 streams. Default value is 2^31 - 1.

Type: UInt32

### prop maxFrameSize

```cangjie
public prop maxFrameSize: UInt32
```

Functionality: Gets the initial maximum frame size for HTTP/2. Default value is 16384, with a valid range of 2^14 to 2^24 - 1.

Type: UInt32

### prop maxHeaderListSize

```cangjie
public prop maxHeaderListSize: UInt32
```

Functionality: Gets the maximum HTTP/2 header size supported by the client. This size refers to the maximum allowed total length of all header fields in the response headers, including the length of field names (name), field values (value), and the pseudo-header overhead automatically added for each field (typically 32 bytes per field, which includes the pseudo-header information added by the HTTP/2 protocol itself). By default, this maximum length is set to UInt32.Max.

Type: UInt32

### prop poolSize

```cangjie
public prop poolSize: Int64
```

Functionality: Configures the size of the connection pool used by the HTTP/1.1 client, which also represents the maximum number of simultaneous connections to the same host (host:port).

Type: Int64

### prop readTimeout

```cangjie
public prop readTimeout: Duration
```

Functionality: Gets the timeout duration for reading the entire response. Default value is 15 seconds.

Type: Duration

### prop writeTimeout

```cangjie
public prop writeTimeout: Duration
```

Functionality: Gets the timeout duration for writing requests. Default value is 15 seconds.

Type: Duration

### func close()

```cangjie
public func close(): Unit
```

Functionality: Closes all connections established by the client. No further requests can be sent after calling this.

### func connect(String, HttpHeaders, Protocol)

```cangjie
public func connect(url: String, header!: HttpHeaders = HttpHeaders(), version!: Protocol = HTTP1_1): (HttpResponse, ?StreamingSocket)
```

Functionality: Sends a CONNECT request to establish a tunnel with the server, returning the successfully established connection, which the user is responsible for closing. A 2xx response from the server indicates successful connection establishment; otherwise, it fails (automatic redirection is not supported, and 3xx responses are also considered failures).

Parameters:

- url: String - The request URL.
- header!: [HttpHeaders](http_package_classes.md#class-httpheaders) - Request headers, defaults to empty headers.
- version!: [Protocol](http_package_enums.md#enum-protocol) - The request protocol, defaults to [HTTP1_1](./http_package_enums.md#enum-protocol).

Return value:

- ([HttpResponse](http_package_classes.md#class-httpresponse), ?StreamingSocket) - Returns a tuple where the [HttpResponse](http_package_classes.md#class-httpresponse) instance represents the server's response body, and the Option\<StreamingSocket> instance represents the connection returned after successful request headers.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing rules.
- IllegalArgumentException - Thrown when encoded characters do not conform to UTF-8 byte sequence rules.
- Others same as func send.

### func delete(String)

```cangjie
public func delete(url: String): HttpResponse
```

Functionality: Convenience function for sending DELETE requests.

Parameters:

- url: String - The request URL.

Return value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The server's response.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing rules.
- IllegalArgumentException - Thrown when encoded characters do not conform to UTF-8 byte sequence rules.
- Others same as func send.

### func get(String)

```cangjie
public func get(url: String): HttpResponse
```

Functionality: Convenience function for sending GET requests.

Parameters:

- url: String - The request URL.

Return value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The server's response.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing rules.
- IllegalArgumentException - Thrown when encoded characters do not conform to UTF-8 byte sequence rules.
- Others same as func send.

### func getTlsConfig()

```cangjie
public func getTlsConfig(): ?TlsConfig
```

Functionality: Gets the TLS configuration set for the client.

Return value:

- ?[TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - The TLS configuration set for the client, or None if not set.

### func head(String)

```cangjie
public func head(url: String): HttpResponse
```

Functionality: Convenience function for sending HEAD requests.

Parameters:

- url: String - The request URL.

Return value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The server's response.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing rules.
- IllegalArgumentException - Thrown when encoded characters do not conform to UTF-8 byte sequence rules.
- Others same as func send.

### func options(String)

```cangjie
public func options(url: String): HttpResponse
```

Functionality: Convenience function for sending OPTIONS requests.

Parameters:

- url: String - The request URL.

Return value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The server's response.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing rules.
- IllegalArgumentException - Thrown when encoded characters do not conform to UTF-8 byte sequence rules.
- Others same as func send.

### func post(String, Array\<UInt8>)

```cangjie
public func post(url: String, body: Array<UInt8>): HttpResponse
```

Function: Convenient request function with POST method.

Parameters:

- url: String - The request URL.
- body: Array\<UInt8> - The request body.

Return Value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The response returned by the server.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing specifications.
- IllegalArgumentException - Thrown when the encoded characters do not comply with UTF-8 byte sequence rules.
- Others are the same as func send.

### func post(String, InputStream)

```cangjie
public func post(url: String, body: InputStream): HttpResponse
```

Function: Convenient request function with POST method.

Parameters:

- url: String - The request URL.
- body: InputStream - The request body.

Return Value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The response returned by the server.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing specifications.
- IllegalArgumentException - Thrown when the encoded characters do not comply with UTF-8 byte sequence rules.
- Others are the same as func send.

### func post(String, String)

```cangjie
public func post(url: String, body: String): HttpResponse
```

Function: Convenient request function with POST method.

Parameters:

- url: String - The request URL.
- body: String - The request body.

Return Value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The response returned by the server.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing specifications.
- IllegalArgumentException - Thrown when the encoded characters do not comply with UTF-8 byte sequence rules.
- Others are the same as func send.

### func put(String, Array\<UInt8>)

```cangjie
public func put(url: String, body: Array<UInt8>): HttpResponse
```

Function: Convenient request function with PUT method.

Parameters:

- url: String - The request URL.
- body: Array\<UInt8> - The request body.

Return Value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The response returned by the server.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing specifications.
- IllegalArgumentException - Thrown when the encoded characters do not comply with UTF-8 byte sequence rules.
- Others are the same as func send.

### func put(String, InputStream)

```cangjie
public func put(url: String, body: InputStream): HttpResponse
```

Function: Convenient request function with PUT method.

Parameters:

- url: String - The request URL.
- body: InputStream - The request body.

Return Value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The response returned by the server.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing specifications.
- IllegalArgumentException - Thrown when the encoded characters do not comply with UTF-8 byte sequence rules.
- Others are the same as func send.

### func put(String, String)

```cangjie
public func put(url: String, body: String): HttpResponse
```

Function: Convenient request function with PUT method.

Parameters:

- url: String - The request URL.
- body: String - The request body.

Return Value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The response returned by the server.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the url parameter does not conform to [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) parsing specifications.
- IllegalArgumentException - Thrown when the encoded characters do not comply with UTF-8 byte sequence rules.
- Others are the same as func send.

### func send(HttpRequest)

```cangjie
public func send(req: HttpRequest): HttpResponse
```

Function: General request function that sends [HttpRequest](http_package_classes.md#class-httprequest) to the server specified in the URL and receives [HttpResponse](http_package_classes.md#class-httpresponse).

> **Note:**
>
> - For HTTP/1.1, if the request has a body to send, ensure that either Content-Length or Transfer-Encoding: chunked is present (but not both). When sending in chunked form, each chunk must not exceed 8192 bytes. If the body is a custom InputStream class, the user must ensure that either Content-Length or Transfer-Encoding: chunked is set (but not both). If the user uses the default body sender and both Content-Length and Transfer-Encoding: chunked are missing, we will add a Content-Length header with the value body.size.
> - If the user sets Content-Length, its correctness must be ensured: If the body content is greater than or equal to the Content-Length value, we will send data of length Content-Length. If the body content is less than the Content-Length value and the body is the default body, [HttpException](http_package_exceptions.md#class-httpexception) will be thrown. If the body is a custom InputStream class, the behavior cannot be guaranteed (may cause server-side read request timeout or client-side receive response timeout).
> - Upgrade functions are sent via [WebSocket](http_package_classes.md#class-websocket)'s upgradeFromClient or [Client](http_package_classes.md#class-client)'s [upgrade](http_package_funcs.md#func-upgradehttpcontext) interface. Calling other client functions to send [upgrade](http_package_funcs.md#func-upgradehttpcontext) requests will throw an exception.
> - The protocol specifies that TRACE requests cannot carry content, so sending a TRACE request with a body will throw an exception.
> - HTTP/1.1 defaults to a maximum of 10 connections to the same server. The response body must be read by calling `body.read(buf: Array<Byte>)`. The connection can only be reused by the client object after the body is fully read; otherwise, new connections will be created for requests to the same server. If the connection limit is exceeded when creating a new connection, [HttpException](http_package_exceptions.md#class-httpexception) will be thrown.
> - The body.read function returns 0 after the body is fully read. If the connection is interrupted during reading, [ConnectionException](http_package_exceptions.md#class-connectionexception) will be thrown.
> - For HTTP/1.1 upgrade requests, receiving a 101 response indicates a protocol switch, and this connection is no longer managed by the client.
> - The notes for the following convenience request functions are the same as for send.

Parameters:

- req: [HttpRequest](http_package_classes.md#class-httprequest) - The request to send.

Return Value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - The response returned by the server for processing the request.

Exceptions:

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) in the request is incorrect.
- SocketException - Thrown when a socket connection error occurs.
- [ConnectionException](http_package_exceptions.md#class-connectionexception) - Thrown when the peer closes the connection while reading data.
- SocketTimeoutException - Thrown when a socket connection times out.
- [TlsException](../../tls/common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - Thrown when TLS connection establishment fails or communication errors occur.
- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown when the user does not use the http library's API to upgrade [WebSocket](http_package_classes.md#class-websocket).
- [HttpTimeoutException](http_package_exceptions.md#class-httptimeoutexception) - Thrown when the request times out or reading [HttpResponse](http_package_classes.md#class-httpresponse).body times out.

### func upgrade(HttpRequest)

```cangjie
public func upgrade(req: HttpRequest): (HttpResponse, ?StreamingSocket)
```

Function: Sends a request and upgrades the protocol. The user sets the request headers, and the upgraded connection (if successful) is returned. The user is responsible for closing the connection.

> **Description:**
>
> - A server response of 101 indicates a successful upgrade, and a StreamingSocket is obtained.
> - Required request headers:
>     - Upgrade: protocol-name ["/" protocol-version];
>     - Connection: Upgrade (automatically added when the Upgrade field is included in the request headers);
> - HTTP/1.0 and HTTP/2 are not supported.
> - HTTP/1.1 CONNECT method [HttpRequest](http_package_classes.md#class-httprequest) is not supported.

Parameters:

- req: [HttpRequest](http_package_classes.md#class-httprequest) - The request sent during the upgrade.

Return Value:

- ([HttpResponse](http_package_classes.md#class-httpresponse), ?StreamingSocket) - Returns a tuple where [HttpResponse](http_package_classes.md#class-httpresponse) represents the server's response, and ?StreamingSocket represents the underlying connection obtained (None if the upgrade fails).

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) -
    - The request or response message does not comply with the protocol;
    - The request message lacks an Upgrade header;
    - Sending a CONNECT request;
    - Sending a TRACE request with a body;
- SocketException, [ConnectionException](http_package_exceptions.md#class-connectionexception) - Socket connection errors or closures;
- SocketTimeoutException - Socket connection timeout;
- [TlsException](../../tls/common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - TLS connection establishment failure or communication errors.

## class ClientBuilder

```cangjie
public class ClientBuilder {
    public init()
}
```

Function: Used to construct [Client](http_package_classes.md#class-client) instances. [Client](http_package_classes.md#class-client) does not have a public constructor; users can only obtain [Client](http_package_classes.md#class-client) instances via [ClientBuilder](http_package_classes.md#class-clientbuilder). The [ClientBuilder](http_package_classes.md#class-clientbuilder) documentation does not explicitly state support for version configuration, which will apply to both HTTP/1.1 and HTTP/2.

> **Description:**
>
> This class provides a series of functions to configure parameters. After configuration, call the [build](./http_package_classes.md#func-build) function to construct a [Client](./http_package_classes.md#class-client) instance. The configuration functions specify parameter value ranges but do not perform parameter validity checks; these are performed uniformly during [build](./http_package_classes.md#func-build).

### init()

```cangjie
public init()
```

Function: Creates a new [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func autoRedirect(Bool)

```cangjie
public func autoRedirect(auto: Bool): ClientBuilder
```

Function: Configures whether the client automatically follows redirects. Redirects will request the resource specified in the Location header. The protocol specifies that Location can only contain one URI reference (Location = URI-reference), as detailed in [RFC 9110 10.2.2.](https://httpwg.org/specs/rfc9110.html#rfc.section.10.2.2). Status code 304 does not redirect by default.

Parameters:

- auto: Bool - Defaults to true (automatic redirect enabled).

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - A reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func build()

```cangjie
public func build(): Client
```

Function: Constructs a [Client](http_package_classes.md#class-client) instance.

This function checks the values of all parameters. If any parameter is invalid, an exception will be thrown. The valid ranges for parameters are detailed in the respective configuration functions.

Return Value:

- [Client](http_package_classes.md#class-client) - A [Client](http_package_classes.md#class-client) instance constructed with the current [ClientBuilder](http_package_classes.md#class-clientbuilder) configuration.

Exceptions:

- IllegalArgumentException - Thrown when configuration parameters are invalid.

### func connector((SocketAddress)->StreamingSocket)

```cangjie
public func connector(c: (SocketAddress) -> StreamingSocket): ClientBuilder
```

Function: The client calls this function to obtain a connection to the server.

Parameters:

- c: (SocketAddress) ->StreamingSocket - A function type that takes a SocketAddress instance as input and returns a StreamingSocket.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - A reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func cookieJar(?CookieJar)

```cangjie
public func cookieJar(cookieJar: ?CookieJar): ClientBuilder
```

Function: Used to store all client [Cookie](http_package_classes.md#class-cookie)s.

Parameters:

- cookieJar: ?[CookieJar](http_package_interfaces.md#interface-cookiejar) - Defaults to an empty [CookieJar](http_package_interfaces.md#interface-cookiejar). If set to None, [Cookie](http_package_classes.md#class-cookie) functionality will be disabled.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - A reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func enablePush(Bool)

```cangjie
public func enablePush(enable: Bool): ClientBuilder
```

Function: Configure whether the client supports HTTP/2 server push.

Parameters:

- enable: Bool - Default value is true.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func headerTableSize(UInt32)

```cangjie
public func headerTableSize(size: UInt32): ClientBuilder
```

Function: Configure the initial value of the client's HTTP/2 HPACK dynamic table.

Parameters:

- size: UInt32 - Default value is 4096.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func httpProxy(String)

```cangjie
public func httpProxy(addr: String): ClientBuilder
```

Function: Set the client's HTTP proxy. By default, it uses the value of the system environment variable `http_proxy`.

Parameters:

- addr: String - Format: `"http://host:port"`, e.g., `"http://192.168.1.1:80"`.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func httpsProxy(String)

```cangjie
public func httpsProxy(addr: String): ClientBuilder
```

Function: Set the client's HTTPS proxy. By default, it uses the value of the system environment variable `https_proxy`.

Parameters:

- addr: String - Format: `"http://host:port"`, e.g., `"http://192.168.1.1:443"`.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func initialWindowSize(UInt32)

```cangjie
public func initialWindowSize(size: UInt32): ClientBuilder
```

Function: Configure the initial flow control window size for the client's HTTP/2 streams.

Parameters:

- size: UInt32 - Default value is 65535, valid range is 0 to 2^31 - 1.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func logger(Logger)

```cangjie
public func logger(logger: Logger): ClientBuilder
```

Function: Set the client's logger. The default logger level is INFO, and log content will be written to Console.stdout.

Parameters:

- logger: [Logger](../../../log/log_package_api/log_package_classes.md#class-logger) - Must be thread-safe. The default is a built-in thread-safe logger.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func maxConcurrentStreams(UInt32)

```cangjie
public func maxConcurrentStreams(size: UInt32): ClientBuilder
```

Function: Configure the initial maximum number of concurrent streams for the client's HTTP/2.

Parameters:

- size: UInt32 - Default value is 2^31 - 1.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func maxFrameSize(UInt32)

```cangjie
public func maxFrameSize(size: UInt32): ClientBuilder
```

Function: Configure the initial maximum frame size for the client's HTTP/2.

Parameters:

- size: UInt32 - Default value is 16384. Valid range is 2^14 to 2^24 - 1.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func maxHeaderListSize(UInt32)

```cangjie
public func maxHeaderListSize(size: UInt32): ClientBuilder
```

Function: Get the maximum header size supported by the client's HTTP/2. This size refers to the maximum allowed total length of all header fields in the response headers, including the length of all field names (name), field values (value), and the pseudo-header overhead automatically added for each field (typically 32 bytes per field, which includes the pseudo-header information added by the HTTP/2 protocol itself). By default, this maximum length is set to UInt32.Max.

Parameters:

- size: UInt32 - The maximum length of HTTP/2 response headers that the client can receive.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func noProxy()

```cangjie
public func noProxy(): ClientBuilder
```

Function: After calling this function, the client will not use any proxy.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func poolSize(Int64)

```cangjie
public func poolSize(size: Int64): ClientBuilder
```

Function: Configure the size of the connection pool used by the HTTP/1.1 client, which also represents the maximum number of simultaneous connections to the same host (host:port).

Parameters:

- size: Int64 - Default is 10. poolSize must be greater than 0.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the parameter is less than or equal to 0.

### func readTimeout(Duration)

```cangjie
public func readTimeout(timeout: Duration): ClientBuilder
```

Function: Set the maximum duration for the client to read a response.

Parameters:

- timeout: Duration - Default is 15s. Duration.Max means no limit. Negative Duration values will be replaced with Duration.Zero.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func tlsConfig(TlsConfig)

```cangjie
public func tlsConfig(config: TlsConfig): ClientBuilder
```

Function: Set the TLS layer configuration. By default, it is not configured. When serverName is not specified in the TLS client configuration, the client uses the host name from the request URL as the SNI and verifies the server certificate against it; the TLS handshake fails if the host name is empty.

Parameters:

- config: [TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - Configuration information required for TLS client support.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

### func writeTimeout(Duration)

```cangjie
public func writeTimeout(timeout: Duration): ClientBuilder
```

Function: Set the maximum duration for the client to send a request.

Parameters:

- timeout: Duration - Default is 15 seconds. Duration.Max means no limit. Negative Duration values will be replaced with Duration.Zero.

Return Value:

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - Reference to the current [ClientBuilder](http_package_classes.md#class-clientbuilder) instance.

## class Cookie

```cangjie
public class Cookie {
    public init(name: String, value: String, expires!: ?DateTime = None, maxAge!: ?Int64 = None,
        domain!: String = "", path!: String = "", secure!: Bool = false, httpOnly!: Bool = false)
}
```

Function: HTTP is inherently stateless. To allow servers to track client state and provide personalized services, [Cookie](http_package_classes.md#class-cookie) can be used to maintain a stateful session.

> **Note:**
>
> - When a user first visits a site, the server sends name/value pairs and attribute-values to the user agent via the `Set-Cookie` header. Subsequent requests to the site from the user agent can include these name/value pairs in the Cookie header.
> - The [Cookie](http_package_classes.md#class-cookie) class provides functions to construct [Cookie](http_package_classes.md#class-cookie) objects and convert them into `Set-Cookie` header values, as well as functions to retrieve the attribute values of [Cookie](http_package_classes.md#class-cookie) objects.
> - The requirements and roles of each attribute of [Cookie](http_package_classes.md#class-cookie) are defined in [RFC 6265](https://httpwg.org/specs/rfc6265.html).
> - Terms such as cookie-name, cookie-value, and expires-av used below are adopted from [RFC 6265](https://httpwg.org/specs/rfc6265.html). For details, refer to the protocol.

### prop cookieName

```cangjie
public prop cookieName: String
```

Function: Get the cookie-name value of the [Cookie](http_package_classes.md#class-cookie) object.

Type: String

### prop cookieValue

```cangjie
public prop cookieValue: String
```

Function: Get the cookie-value value of the [Cookie](http_package_classes.md#class-cookie) object.

Type: String

### prop domain

```cangjie
public prop domain: String
```

Function: Get the domain-av value of the [Cookie](http_package_classes.md#class-cookie) object.

Type: String

### prop expires

```cangjie
public prop expires: ?DateTime
```

Function: Get the expires-av value of the [Cookie](http_package_classes.md#class-cookie) object.

Type: ?DateTime

### prop httpOnly

```cangjie
public prop httpOnly: Bool
```

Function: Get the httpOnly-av value of the [Cookie](http_package_classes.md#class-cookie) object.

Type: Bool

### prop maxAge

```cangjie
public prop maxAge: ?Int64
```

Function: Get the max-age-av value of the [Cookie](http_package_classes.md#class-cookie) object.

Type: ?Int64

### prop others

```cangjie
public prop others: ArrayList<String>
```

Function: Retrieves unparsed attributes.

Type: ArrayList\<String>

### prop path

```cangjie
public prop path: String
```

Function: Gets the path-av value of the [Cookie](http_package_classes.md#class-cookie) object.

Type: String

### prop secure

```cangjie
public prop secure: Bool
```

Function: Gets the secure-av value of the [Cookie](http_package_classes.md#class-cookie) object.

Type: Bool

### init(String, String, ?DateTime, ?Int64, String, String, Bool, Bool)

```cangjie
public init(name: String, value: String, expires!: ?DateTime = None, maxAge!: ?Int64 = None,
    domain!: String = "", path!: String = "", secure!: Bool = false, httpOnly!: Bool = false)
```

Function: [Cookie](http_package_classes.md#class-cookie) constructor.

This constructor checks whether the input attributes comply with protocol requirements. If not, it throws an IllegalArgumentException. Specific requirements are detailed in [RFC 6265 4.1.1.](https://httpwg.org/specs/rfc6265.html#sane-set-cookie-syntax).

> **Note:**
>
> Among the attributes of [Cookie](http_package_classes.md#class-cookie), only cookie-name and cookie-value are mandatory. The `name` and `value` parameters must be provided, but `value` can be an empty string.

Parameters:

- name: String - The cookie-name attribute.

    ```cangjie
    name         = token 
    token        = 1*tchar
    tchar        = "!" / "#" / "$" / "%" / "&" / "'" / "*"
                   / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
                   / DIGIT / ALPHA
    ```

- value: String - The cookie-value attribute.

    ```cangjie
    value        = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE )
    cookie-octet = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E
                ; US-ASCII characters excluding CTLs,
                ; whitespace DQUOTE, comma, semicolon,
                ; and backslash
    ```

- expires!: ?DateTime - Sets the expiration time of the [Cookie](http_package_classes.md#class-cookie). Default is None. The time must be after 1601.
- maxAge!: ?Int64 - The maximum lifecycle of the [Cookie](http_package_classes.md#class-cookie). Default is None. If the [Cookie](http_package_classes.md#class-cookie) has both expires and maxAge attributes, it will only persist until the session ends (until the [Client](http_package_classes.md#class-client) closes; after closure, expired [Cookie](http_package_classes.md#class-cookie) will no longer be maintained).

    ```cangjie
    max-age-av     = "Max-Age=" non-zero-digit *DIGIT
    non-zero-digit = %x31-39
                    ; digits 1 through 9
    DIGIT          = %x30-39
                    ; digits 0 through 9
    ```

- domain!: String - Default is an empty string, indicating that the client receiving this [Cookie](http_package_classes.md#class-cookie) will only send it to the original server. If a valid domain is set, the client will send the [Cookie](http_package_classes.md#class-cookie) to all subdomains of that domain (and only if other attribute conditions are met).

    ```cangjie
    domain          = <subdomain> | " "
    <subdomain>   ::= <label> | <subdomain> "." <label>
    <label>       ::= <letter> [ [ <ldh-str> ] <let-dig> ]
    <ldh-str>     ::= <let-dig-hyp> | <let-dig-hyp> <ldh-str>
    <let-dig-hyp> ::= <let-dig> | "-"
    <let-dig>     ::= <letter> | <digit>
    <letter>      ::= any one of the 52 alphabetic characters A through Z in upper case and a through z in lower case
    <digit>       ::= any one of the ten digits 0 through 9
    RFC 1035 2.3.1.
    RFC 1123 2.1. relaxes the restriction that the first character of a label must be a letter.
    Therefore, domain requirements are:
    1. Total length ≤ 255, composed of multiple labels.
    2. Labels are separated by ".", each label length ≤ 63.
    3. The start and end of a label must be a digit or letter; intermediate characters can be digits, letters, or "-".
    ```

- path!: String - Default is an empty string. The client will calculate the default path attribute based on the URL (see RFC 6265 5.1.4.). The client will only send this [Cookie](http_package_classes.md#class-cookie) to all subdirectories of this path (and only if other attribute conditions are met).

    ```cangjie
    path            = <any RUNE except CTLs or ";">
    RUNE            = <any [USASCII] character>
    CTLs            = <controls>
    ```

- secure!: Bool - Default is false. If set to true, this [Cookie](http_package_classes.md#class-cookie) will only be sent in secure protocol requests.
- httpOnly!: Bool - Default is false. If set to true, this [Cookie](http_package_classes.md#class-cookie) will only be sent in HTTP protocol requests.

Exceptions:

- IllegalArgumentException - Thrown when input parameters do not meet protocol requirements.

### func toSetCookieString()

```cangjie
public func toSetCookieString(): String
```

Function: Provides a method to convert [Cookie](http_package_classes.md#class-cookie) to a string format, facilitating server-side `Set-Cookie` header configuration.

> **Note:**
>
> - [Cookie](http_package_classes.md#class-cookie) attributes (including name and value) are checked during object creation, so toSetCookieString() will not throw exceptions.
> - The mandatory attribute of [Cookie](http_package_classes.md#class-cookie) is the cookie-pair (cookie-name "=" cookie-value). The cookie-value can be an empty string. The toSetCookieString() function only writes set attributes to the string, meaning only "cookie-name=" is mandatory; other parts depend on whether they are set.

Return Value:

- String - A string object for setting the `Set-Cookie` header.

## class FileHandler

```cangjie
public class FileHandler <: HttpRequestHandler {
    public init(path: String, handlerType!: FileHandlerType = DownLoad, bufferSize!: Int64 = 64 * 1024)
    public init(path: String, handlerType!: FileHandlerType = DownLoad, bufferSize!: Int64 = 64 * 1024, validator!: (String) -> Bool)
}
```

Function: Handles file downloads or uploads.

File Download:

- When constructing [FileHandler](http_package_classes.md#class-filehandler), provide the path of the file to download. Currently, one [FileHandler](http_package_classes.md#class-filehandler) can only handle one file download.
- Only GET requests are allowed for downloads; other requests return a 400 status code.
- If the file does not exist, a 404 status code is returned.

File Upload:

- When constructing [FileHandler](http_package_classes.md#class-filehandler), provide an existing directory path. Uploaded files will be saved in this directory.
- Only POST requests are allowed for uploads; other requests return a 400 status code.
- The HTTP request must be in `multipart/form-data` format, with the `Content-Type` header value as `multipart/form-data; boundary=----XXXXX`.
- The uploaded file's name is stored in the `form-data` payload, formatted as `Content-Disposition: form-data; name="xxx"; filename="xxxx"`, where the filename is the value of the `filename` field.
- Currently, the form-data must include the filename field.
- If the request is malformed, a 400 status code is returned.
- For other exceptions (e.g., file processing errors), a 500 status code is returned.

Parent Type:

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### init(String, FileHandlerType, Int64)

```cangjie
public init(path: String, handlerType!: FileHandlerType = DownLoad, bufferSize!: Int64 = 64 * 1024)
```

Function: Constructor for [FileHandler](http_package_classes.md#class-filehandler).

Parameters:

- path: String - The file or directory path string for [FileHandler](http_package_classes.md#class-filehandler) construction. In upload mode, only existing directory paths are allowed. If the path contains "../", ensure the normalized absolute path matches the intended input.
- handlerType!: [FileHandlerType](http_package_enums.md#enum-filehandlertype) - Specifies the working mode of [FileHandler](http_package_classes.md#class-filehandler). Default is DownLoad mode.
- bufferSize!: Int64 - Internal buffer size for network read/write operations. Default is 64*1024 (64k). If less than 4096, 4096 is used.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the path does not exist.
- IllegalArgumentException - Thrown for parameter errors (e.g., empty path or invalid strings).

### init(String, FileHandlerType, Int64, (String) -> Bool)

```cangjie
public init(path: String, handlerType!: FileHandlerType = DownLoad, bufferSize!: Int64 = 64 * 1024, validator!: (String) -> Bool)
```

Function: Constructor for [FileHandler](http_package_classes.md#class-filehandler).

Parameters:

- path: String - The file or directory path string for [FileHandler](http_package_classes.md#class-filehandler) construction. In upload mode, only existing directory paths are allowed. If the path contains "../", ensure the normalized absolute path matches the intended input.
- handlerType!: [FileHandlerType](http_package_enums.md#enum-filehandlertype) - Specifies the working mode of [FileHandler](http_package_classes.md#class-filehandler). Default is DownLoad mode.
- bufferSize!: Int64 - Internal buffer size for network read/write operations. Default is 64*1024 (64k). If less than 4096, 4096 is used.
- validator!: (String) -> Bool - The user-defined file name validation function(only effective in upload mode). It takes the filename of the uploaded file as the parameter from the multipart request, and returns the validation result from the user-defined function. If the result is false, the upload request is interrupted, a '400 Bad Request' response is returned, and any files already uploaded to the path directory are deleted. 

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the path does not exist.
- IllegalArgumentException - Thrown for parameter errors (e.g., empty path or invalid strings).

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

Function: Processes response data based on the request.

Parameters:

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - HTTP request context.

## class FuncHandler

```cangjie
public class FuncHandler <: HttpRequestHandler {
    public FuncHandler(let handler: (HttpContext) -> Unit)
}
```

Function: A wrapper class for the [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler) interface, converting a single function into an [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler).

Parent Type:

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### FuncHandler((HttpContext) -> Unit)

```cangjie
public FuncHandler(let handler: (HttpContext) -> Unit)
```

Function: Constructor for [FuncHandler](http_package_classes.md#class-funchandler).

Parameters:

- handler: ([HttpContext](http_package_classes.md#class-httpcontext)) -> Unit - The processing function called by handle.

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

Function: Processes HTTP requests.

Parameters:

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - HTTP request context.

## class HttpContext

```cangjie
public class HttpContext
```

Function: HTTP request context, used as a parameter for [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler).handle on the server side.

### prop clientCertificate

```cangjie
public prop clientCertificate: ?Array<Certificate>
```

Function: Retrieves the HTTP client certificate.

Type: ?Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)>

### prop request

```cangjie
public prop request: HttpRequest
```

Function: Retrieves the HTTP request.

Type: [HttpRequest](http_package_classes.md#class-httprequest)

### prop responseBuilder

```cangjie
public prop responseBuilder: HttpResponseBuilder
```

Function: Retrieves the HTTP response builder.

Type: [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder)

### func isClosed()

```cangjie
public func isClosed(): Bool
```

Function: When using the HTTP/1.1 protocol, determine whether the socket has been closed; when using the HTTP/2 protocol, determine whether the HTTP/2 stream has been closed.

Return Value:

- Bool - If the HTTP/1.1 socket or HTTP/2 stream is closed, return true; otherwise, return false.

## class HttpHeaders

```cangjie
public class HttpHeaders <: Iterable<(String, Collection<String>)>
```

Function: Represents HTTP message headers and trailers, defining operations for addition, deletion, modification, and query.

> **Note:**
>
> - Headers and trailers are key-value mappings composed of field-lines, each containing a key (field-name) and values (field-value).
> - Field-names consist of token characters (case-insensitive) and are stored in lowercase.
> - Field-values consist of vchar, SP, and HTAB. Leading/trailing spaces are disallowed, and empty values are invalid.
> - See [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html#name-fields) for details.

Example:

```text
Example-Field: Foo, Bar
key: Example-Field, value: Foo, Bar
field-name = token
token = 1*tchar
tchar = "!" / "#" / "$" / "%" / "&" / "'" / "*"
/ "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
/ DIGIT / ALPHA
; any VCHAR, except delimiters
```

Parent Type:

- Iterable\<(String, Collection\<String>)>

### func add(String, String)

```cangjie
public func add(name: String, value: String): Unit
```

Function: Add specified key-value pair. If the name already exists, the value will be appended to its corresponding value list; if the name does not exist, the name field and its value will be added.

Parameters:

- name: String - Field name of [HttpHeaders](http_package_classes.md#class-httpheaders).
- value: String - Field value of [HttpHeaders](http_package_classes.md#class-httpheaders).

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the provided name/value contains invalid elements.

### func del(String)

```cangjie
public func del(name: String): Unit
```

Function: Delete the key-value pair corresponding to the specified name.

Parameters:

- name: String - Field name to be deleted.

### func get(String)

```cangjie
public func get(name: String): Collection<String>
```

Function: Retrieve the value(s) corresponding to the specified name.

Parameters:

- name: String - Field name (case-insensitive).

Return Value:

- Collection\<String> - Collection of values corresponding to the name. Returns an empty collection if the specified name does not exist.

### func getFirst(String)

```cangjie
public func getFirst(name: String): ?String
```

Function: Retrieve the first value corresponding to the specified name.

Parameters:

- name: String - Field name (case-insensitive).

Return Value:

- ?String - First value corresponding to the name. Returns None if the specified name does not exist.

### func isEmpty()

```cangjie
public func isEmpty(): Bool
```

Function: Check if the current instance is empty (i.e., contains no key-value pairs).

Return Value:

- Bool - Returns true if the current instance is empty, otherwise returns false.

### func iterator()

```cangjie
public func iterator(): Iterator<(String, Collection<String>)>
```

Function: Retrieve an iterator for traversing all key-value pairs.

Return Value:

- Iterator\<(String, Collection\<String>)> - Iterator for the key-value set.

### func set(String, String)

```cangjie
public func set(name: String, value: String): Unit
```

Function: Set the specified key-value pair. If the name already exists, the provided value will overwrite the previous value(s).

Parameters:

- name: String - Field name of [HttpHeaders](http_package_classes.md#class-httpheaders).
- value: String - Field value of [HttpHeaders](http_package_classes.md#class-httpheaders).

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the provided name/values contain invalid elements.

## class HttpRequest

```cangjie
public class HttpRequest <: ToString
```

Function: This class represents an HTTP request.

When sending a request, a client needs to construct an [HttpRequest](http_package_classes.md#class-httprequest) instance and encode it into a byte message for transmission.

When processing a request, a server needs to parse the received request into an [HttpRequest](http_package_classes.md#class-httprequest) instance and pass it to the handler function.

Parent Type:

- ToString

### prop body

```cangjie
public prop body: InputStream
```

Function: Retrieve the request body.

> **Note:**
>
> - The body does not support concurrent reading;
> - The default InputStream implementation's read function does not support multiple reads.

Type: InputStream

### prop bodySize

```cangjie
public prop bodySize: Option<Int64>
```

Function: Retrieve the length of the request body.

- If the body is not set, bodySize is Some(0);
- If the body length is known (i.e., the body is passed via Array\<UInt8> or String, or the provided InputStream has a definite length (length >= 0)), bodySize is Some(Int64);
- If the body length is unknown (i.e., the body is passed via a custom InputStream instance with an indefinite length (length < 0)), bodySize is None.

Type: Option\<Int64>

### prop form

```cangjie
public prop form: Form
```

Function: Retrieve form information from the request.

- If the request method is POST, PUT, or PATCH, and the content-type includes application/x-www-form-urlencoded, the request body is parsed as form data;
- If the request method is not POST, PUT, or PATCH, the query part of the request URL is retrieved.

> **Note:**
>
> - If the body is read via this interface, it will be consumed and cannot be read again via body.read;
> - If the form does not conform to the [Form](../../../encoding/url/url_package_api/url_package_classes.md#class-form) format, a [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) will be thrown.

Type: [Form](../../../encoding/url/url_package_api/url_package_classes.md#class-form)

### prop headers

```cangjie
public prop headers: HttpHeaders
```

Function: Retrieve the headers. For details, see the [HttpHeaders](http_package_classes.md#class-httpheaders) class. After retrieval, the request headers can be modified by calling member functions of the [HttpHeaders](http_package_classes.md#class-httpheaders) instance.

Type: [HttpHeaders](http_package_classes.md#class-httpheaders)

### prop isPersistent

```cangjie
public prop isPersistent: Bool
```

Function: Indicates whether the request use a persistent connection. If it contains `Connection: close`, it is false; otherwise, it is true.

- For the server, isPersistent being false means the connection should be closed after processing the request.
- For the client, isPersistent being false means the client should actively close the connection if the server does not close it after receiving the response.

Type: Bool

### prop method

```cangjie
public prop method: String
```

Function: Retrieve the request method (e.g., "GET", "POST"). The method of a request instance cannot be modified.

Type: String

### prop readTimeout

```cangjie
public prop readTimeout: ?Duration
```

Function: Represents the request-level read timeout. None indicates no timeout is set; Some(Duration) indicates a read timeout is set.

Type: ?Duration

### prop remoteAddr

```cangjie
public prop remoteAddr: String
```

Function: Used by the server to retrieve the client's address in the format "ip:port". This property cannot be set by the user. Custom request objects return "" for this property, while server handlers return the client's address.

Type: String

### prop trailers

```cangjie
public prop trailers: HttpHeaders
```

Function: Retrieve the trailers. For details, see the [HttpHeaders](http_package_classes.md#class-httpheaders) class. After retrieval, the request trailers can be modified by calling member functions of the [HttpHeaders](http_package_classes.md#class-httpheaders) instance.

Type: [HttpHeaders](http_package_classes.md#class-httpheaders)

### prop url

```cangjie
public prop url: URL
```

Function: Retrieve the URL accessed by the client.

Type: [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url)

### prop version

```cangjie
public prop version: Protocol
```

Function: Retrieve the HTTP version (e.g., HTTP1_1 or HTTP2_0). The version of a request instance cannot be modified.

Type: [Protocol](http_package_enums.md#enum-protocol)

### prop writeTimeout

```cangjie
public prop writeTimeout: ?Duration
```

Function: Represents the request-level write timeout. None indicates no timeout is set; Some(Duration) indicates a write timeout is set.

Type: ?Duration

### func toString()

```cangjie
public override func toString(): String
```

Function: Convert the request to a string, including the start line, headers, body size, and trailers. Example: `"GET /path HTTP/1.1\r\nhost: www.example.com\r\n\r\nbody size: 5\r\nbar: foo\r\n"`.

Return Value:

- String - String representation of the request.

## class HttpRequestBuilder

```cangjie
public class HttpRequestBuilder {
    public init()
    public init(request: HttpRequest)
}
```

Function: The [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) class is used to construct [HttpRequest](http_package_classes.md#class-httprequest) instances.

### init()

```cangjie
public init()
```

Function: Construct a new [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder).

### init(HttpRequest)

```cangjie
public init(request: HttpRequest)
```

Function: Construct an [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) with the properties of the provided request. Since the body member is an InputStream, operations on the original request's body will affect the copied [HttpRequest](http_package_classes.md#class-httprequest)'s body. The headers and trailers of the [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) are deep copies of the input request's headers and trailers. All other elements are shallow copies (as they are immutable objects, deep copying is unnecessary).

Parameters:

- request: [HttpRequest](http_package_classes.md#class-httprequest) - The input [HttpRequest](http_package_classes.md#class-httprequest) object.

### func addHeaders(HttpHeaders)

```cangjie
public func addHeaders(headers: HttpHeaders): HttpRequestBuilder
```

Function: Adds key-value pairs from the [HttpHeaders](http_package_classes.md#class-httpheaders) parameter to the request headers.

Parameters:

- headers: [HttpHeaders](http_package_classes.md#class-httpheaders) - The header object to be added.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func addTrailers(HttpHeaders)

```cangjie
public func addTrailers(trailers: HttpHeaders): HttpRequestBuilder
```

Function: Adds key-value pairs from the [HttpHeaders](http_package_classes.md#class-httpheaders) parameter to the request trailers.

Parameters:

- trailers: [HttpHeaders](http_package_classes.md#class-httpheaders) - The trailer object to be added.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func body(Array\<UInt8>)

```cangjie
public func body(body: Array<UInt8>): HttpRequestBuilder
```

Function: Sets the request body. If already set, calling this function will replace the existing body.

Parameters:

- body: Array\<UInt8> - The request body in byte array format.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func body(InputStream)

```cangjie
public func body(body: InputStream): HttpRequestBuilder
```

Function: Sets the request body. If already set, calling this function will replace the existing body.

Parameters:

- body: InputStream - The request body in stream format.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func body(String)

```cangjie
public func body(body: String): HttpRequestBuilder
```

Function: Sets the request body. If already set, calling this function will replace the existing body. The body will be represented by a built-in InputStream implementation class with a known size.

Parameters:

- body: String - The request body in string format.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func build()

```cangjie
public func build(): HttpRequest
```

Function: Generates an [HttpRequest](http_package_classes.md#class-httprequest) instance based on the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

Return Value:

- [HttpRequest](http_package_classes.md#class-httprequest) - The constructed [HttpRequest](http_package_classes.md#class-httprequest) instance based on the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func connect()

```cangjie
public func connect(): HttpRequestBuilder
```

Function: Convenience function for constructing a request with "CONNECT" method.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func delete()

```cangjie
public func delete(): HttpRequestBuilder
```

Function: Convenience function for constructing a request with "DELETE" method.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func get()

```cangjie
public func get(): HttpRequestBuilder
```

Function: Convenience function for constructing a request with "GET" method.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func head()

```cangjie
public func head(): HttpRequestBuilder
```

Function: Convenience function for constructing a request with "HEAD" method.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func header(String, String)

```cangjie
public func header(name: String, value: String): HttpRequestBuilder
```

Function: Adds a specified key-value pair to the request headers, following the same rules as the add function in the [HttpHeaders](http_package_classes.md#class-httpheaders) class.

Parameters:

- name: String - The key of the request header.
- value: String - The value of the request header.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the provided name or value contains invalid elements.

### func method(String)

```cangjie
public func method(method: String): HttpRequestBuilder
```

Function: Sets the request method. The default method is "GET".

Parameters:

- method: String - The request method, which must consist of token characters. If an empty string is provided, the method will automatically be set to "GET".

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the provided method is invalid.

### func options()

```cangjie
public func options(): HttpRequestBuilder
```

Function: Convenience function for constructing a request with "OPTIONS" method.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func post()

```cangjie
public func post(): HttpRequestBuilder
```

Function: Convenience function for constructing a request with "POST" method.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func priority(Int64, Bool)

```cangjie
public func priority(urg: Int64, inc: Bool): HttpRequestBuilder
```

Function: Convenience function for setting the priority header. Calling this function will generate a priority header in the format: "priority: urgency=x, i". If the priority field is set via other header-setting functions, this function will have no effect. If called multiple times, the last call takes precedence.

Parameters:

- urg: Int64 - Indicates the request priority, with a valid range of [0, 7], where 0 represents the highest priority.
- inc: Bool - Indicates whether the request requires incremental processing. true means the server should concurrently process requests with the same urg and inc values; false means it should not.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

Exceptions:

- [HttpException](./http_package_exceptions.md#class-httpexception) - Thrown if the urg parameter is outside the valid range [0, 7].

### func put()

```cangjie
public func put(): HttpRequestBuilder
```

Function: Convenience function for constructing a request with "PUT" method.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func readTimeout(Duration)

```cangjie
public func readTimeout(timeout: Duration): HttpRequestBuilder
```

Function: Sets the read timeout for this request. If the provided Duration is negative, it will be automatically set to 0. If this read timeout is set by the user, it will override the read timeout set in the [Client](http_package_classes.md#class-client).

Parameters:

- timeout: Duration - The read timeout duration set by the user.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func setHeaders(HttpHeaders)

```cangjie
public func setHeaders(headers: HttpHeaders): HttpRequestBuilder
```

Function: Sets the request headers. If already set, calling this function will replace the existing headers.

Parameters:

- headers: [HttpHeaders](http_package_classes.md#class-httpheaders) - The header object to be set.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func setTrailers(HttpHeaders)

```cangjie
public func setTrailers(trailers: HttpHeaders): HttpRequestBuilder
```

Function: Sets the request trailers. If already set, calling this function will replace the existing trailers.

Parameters:

- trailers: [HttpHeaders](http_package_classes.md#class-httpheaders) - The trailer object to be set.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func trace()

```cangjie
public func trace(): HttpRequestBuilder
```

Function: Convenience function for constructing a request with "TRACE" method.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - Reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func trailer(String, String)

```cangjie
public func trailer(name: String, value: String): HttpRequestBuilder
```

Function: Adds specified key-value pairs to the request trailer, following the same rules as the `add` function in the [HttpHeaders](http_package_classes.md#class-httpheaders) class.

Parameters:

- `name`: String - The key of the request header.
- `value`: String - The value of the request header.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - A reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the provided `name` or `value` contains invalid elements.

### func url(String)

```cangjie
public func url(rawUrl: String): HttpRequestBuilder
```

Function: Sets the request URL. The default URL is an empty [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) object.

Parameters:

- `rawUrl`: String - The string to be parsed into a URL object. For the string format, refer to the [URL.parse](../../../encoding/url/url_package_api/url_package_classes.md#static-func-parsestring) function.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - A reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

Exceptions:

- `IllegalArgumentException` - Thrown when the encoded characters do not conform to UTF8 byte sequence rules.
- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the input string does not conform to the [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) format.

### func url(URL)

```cangjie
public func url(url: URL): HttpRequestBuilder
```

Function: Sets the request URL. The default URL is an empty [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) object, i.e., [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url).parse("").

Parameters:

- `url`: [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) - The URL object.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - A reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func version(Protocol)

```cangjie
public func version(version: Protocol): HttpRequestBuilder
```

Function: Sets the HTTP protocol version for the request. The default is `UnknownProtocol("")`, and the client will automatically select the protocol based on TLS configuration.

Parameters:

- `version`: [Protocol](http_package_enums.md#enum-protocol) - The protocol version.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - A reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

### func writeTimeout(Duration)

```cangjie
public func writeTimeout(timeout: Duration): HttpRequestBuilder
```

Function: Sets the write timeout for this request. If the provided `Duration` is negative, it will be automatically converted to 0. If the user sets this write timeout, it will override the write timeout set in the [Client](http_package_classes.md#class-client); otherwise, the write timeout from the [Client](http_package_classes.md#class-client) will be used.

Parameters:

- `timeout`: Duration - The write timeout set by the user for this request.

Return Value:

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - A reference to the current [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) instance.

## class HttpResponse

```cangjie
public class HttpResponse <: ToString
```

Function: HTTP response class.

This class defines interfaces related to the Response in HTTP. Clients use this class to read responses returned by the server.

Parent Type:

- `ToString`

### prop body

```cangjie
public prop body: InputStream
```

Function: Retrieves the body.

> **Note:**
>
> - The body does not support concurrent reading.
> - The default `InputStream` implementation's `read` function does not support multiple reads.

Type: `InputStream`

### prop bodySize

```cangjie
public prop bodySize: Option<Int64>
```

Function: Retrieves the length of the response body.

> - If the body is not set, `bodySize` will be `Some(0)`.
> - If the body length is known (i.e., passed via `Array<UInt8>` or `String`, or the provided `InputStream` has a determined length (`length >= 0`)), `bodySize` will be `Some(Int64)`.
> - If the body length is unknown (i.e., passed via a user-defined `InputStream` instance without a determined length (`length < 0`)), `bodySize` will be `None`.

Type: `Option<Int64>`

### prop headers

```cangjie
public prop headers: HttpHeaders
```

Function: Retrieves the headers. For details on headers, refer to the [HttpHeaders](http_package_classes.md#class-httpheaders) class. After retrieval, the request's headers can be modified by calling member functions of the [HttpHeaders](http_package_classes.md#class-httpheaders) instance.

Type: [HttpHeaders](http_package_classes.md#class-httpheaders)

### prop isPersistent

```cangjie
public prop isPersistent: Bool
```

Function: Indicates whether the response use a persistent connection. If it contains `Connection: close`, it is false; otherwise, it is true.

- For the server, isPersistent being false means the connection should be closed after processing the request.

- For the client, isPersistent being false means the client should actively close the connection if the server does not close it after receiving the response.

Type: `Bool`

### prop request

```cangjie
public prop request: Option<HttpRequest>
```

Function: Retrieves the request corresponding to this response. The default is `None`.

Type: `Option<[HttpRequest](http_package_classes.md#class-httprequest)>`

### prop status

```cangjie
public prop status: UInt16
```

Function: Retrieves the response status code. The default value is 200. Status codes consist of three-digit numbers ranging from 100 to 599. For specific information about status codes, refer to [RFC 9110](https://httpwg.org/specs/rfc9110.html#status.codes).

Type: `UInt16`

### prop trailers

```cangjie
public prop trailers: HttpHeaders
```

Function: Retrieves the trailers. For details on trailers, refer to the [HttpHeaders](http_package_classes.md#class-httpheaders) class. After retrieval, the request's trailers can be modified by calling member functions of the [HttpHeaders](http_package_classes.md#class-httpheaders) instance.

Type: [HttpHeaders](http_package_classes.md#class-httpheaders)

### prop version

```cangjie
public prop version: Protocol
```

Function: Retrieves the protocol version of the response. The default value is [HTTP1_1](./http_package_enums.md#enum-protocol).

Type: [Protocol](http_package_enums.md#enum-protocol)

### func close()

```cangjie
public func close(): Unit
```

Function：If the user no longer needs the unread body data, they can call this API to close the connection and release resources. For the HTTP/2 protocol, a Reset frame will be sent to close the corresponding stream.

> **Note：**
>
> There is no need to call this API to release resources again if the user has already read the body.

### func toString()

```cangjie
public override func toString(): String
```

Function: Converts the response to a string, including the status-line, headers, body size, and trailers.

Example: `HTTP/1.1 200 OK\r\ncontent-length: 5\r\n\r\nbody size: 5\r\nbar: foo\r\n`.

Return Value:

- `String` - The string representation of the response.

### extend HttpResponse

```cangjie
extend HttpResponse
```

Function: Extends `HttpResponse` with HTTP/2.0-specific methods.

#### func getPush()

```cangjie
public func getPush(): Option<ArrayList<HttpResponse>>
```

Function: Retrieves server-pushed responses. Returns `None` if server push is not enabled, or an empty `ArrayList` if there are no server-pushed responses.

Return Value:

- `Option<ArrayList<[HttpResponse](http_package_classes.md#class-httpresponse)>>` - A list of server-pushed responses.

## class HttpResponseBuilder

```cangjie
public class HttpResponseBuilder {
    public init()
}
```

Function: Used to construct instances of [HttpResponse](http_package_classes.md#class-httpresponse).

### init()

```cangjie
public init()
```

Function: Constructs a new [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder).

### func addHeaders(HttpHeaders)

```cangjie
public func addHeaders(headers: HttpHeaders): HttpResponseBuilder
```

Function: Adds key-value pairs from the parameter [HttpHeaders](http_package_classes.md#class-httpheaders) to the response header.

Parameters:

- `headers`: [HttpHeaders](http_package_classes.md#class-httpheaders) - The header object to be added.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

### func addTrailers(HttpHeaders)

```cangjie
public func addTrailers(trailers: HttpHeaders): HttpResponseBuilder
```

Function: Adds key-value pairs from the parameter [HttpHeaders](http_package_classes.md#class-httpheaders) to the response trailer.

Parameters:

- `trailers`: [HttpHeaders](http_package_classes.md#class-httpheaders) - The trailer object to be added.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

### func body(Array\<UInt8>)

```cangjie
public func body(body: Array<UInt8>): HttpResponseBuilder
```

Function: Sets the response body. If the body has already been set, calling this function will replace the original body.

Parameters:

- `body`: `Array<UInt8>` - The response body in byte array form.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

### func body(InputStream)

```cangjie
public func body(body: InputStream): HttpResponseBuilder
```

Function: Sets the response body. If the body has already been set, calling this function will replace the original body. This function sets the request body.

Parameters:

- body: InputStream - The response body in stream format.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

### func body(String)

```cangjie
public func body(body: String): HttpResponseBuilder
```

Function: Sets the response body. If already set, calling this function will replace the original body.

Parameters:

- body: String - The response body in string format.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

### func build()

```cangjie
public func build(): HttpResponse
```

Function: Generates an [HttpResponse](http_package_classes.md#class-httpresponse) instance based on the [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

Return Value:

- [HttpResponse](http_package_classes.md#class-httpresponse) - An [HttpResponse](http_package_classes.md#class-httpresponse) instance constructed from the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

### func header(String, String)

```cangjie
public func header(name: String, value: String): HttpResponseBuilder
```

Function: Adds a specified key-value pair to the response header, following the same rules as the `add` function in the [HttpHeaders](http_package_classes.md#class-httpheaders) class.

Parameters:

- name: String - The key of the response header.
- value: String - The value of the response header.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the provided `name` or `value` contains invalid elements.

### func request(HttpRequest)

```cangjie
public func request(request: HttpRequest): HttpResponseBuilder
```

Function: Sets the corresponding request for the response.

Parameters:

- request: [HttpRequest](http_package_classes.md#class-httprequest) - The corresponding request for the response.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

### func setHeaders(HttpHeaders)

```cangjie
public func setHeaders(headers: HttpHeaders): HttpResponseBuilder
```

Function: Sets the response headers. If already set, calling this function will replace the original headers.

Parameters:

- headers: [HttpHeaders](http_package_classes.md#class-httpheaders) - The header object to be set.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

### func setTrailers(HttpHeaders)

```cangjie
public func setTrailers(trailers: HttpHeaders): HttpResponseBuilder
```

Function: Sets the response trailers. If already set, calling this function will replace the original trailers.

Parameters:

- trailers: [HttpHeaders](http_package_classes.md#class-httpheaders) - The trailer object to be set.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

### func status(UInt16)

```cangjie
public func status(status: UInt16): HttpResponseBuilder
```

Function: Sets the HTTP response status code.

Parameters:

- status: UInt16 - The value of the status code.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the status code is not within the range of 100~599.

### func trailer(String, String)

```cangjie
public func trailer(name: String, value: String): HttpResponseBuilder
```

Function: Adds a specified key-value pair to the response trailer, following the same rules as the `add` function in the [HttpHeaders](http_package_classes.md#class-httpheaders) class.

Parameters:

- name: String - The key of the response trailer.
- value: String - The value of the response trailer.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the provided `name` or `value` contains invalid elements.

### func version(Protocol)

```cangjie
public func version(version: Protocol): HttpResponseBuilder
```

Function: Sets the HTTP response protocol version.

Parameters:

- version: [Protocol](http_package_enums.md#enum-protocol) - The protocol version.

Return Value:

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - A reference to the current [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) instance.

## class HttpResponsePusher

```cangjie
public class HttpResponsePusher
```

Function: HTTP/2 server push.

> **Note:**
>
> - If the server determines that the client will need certain associated resources after receiving a request, it can push them to the client in advance.
> - Server push includes both push requests and push responses.
> - To enable server push, first call the `push` function to send the push request and register the corresponding handler with the server to generate the push response.
> - The client can opt to reject server push.
> - Nested pushes are not allowed, meaning you cannot initiate another push within the handler of a push request. In such cases, the server will not execute the push and will log a warning.

### static func getPusher(HttpContext)

```cangjie
public static func getPusher(ctx: HttpContext): ?HttpResponsePusher
```

Function: Retrieves an [HttpResponsePusher](http_package_classes.md#class-httpresponsepusher) instance. Returns `None` if the client rejects the push.

Parameters:

- ctx: [HttpContext](#class-httpcontext) - The HTTP request context.

Return Value:

- ?[HttpResponsePusher](http_package_classes.md#class-httpresponsepusher) - The obtained [HttpResponsePusher](http_package_classes.md#class-httpresponsepusher) instance.

### func push(String, String, HttpHeaders)

```cangjie
public func push(path: String, method: String, header: HttpHeaders): Unit
```

Function: Sends a push request to the client, where `path` is the request address, `method` is the request method, and `header` is the request header.

Parameters:

- path: String - The address of the push request.
- method: String - The method of the push request.
- header: [HttpHeaders](#class-httpheaders) - The header of the push request.

## class HttpResponseWriter

```cangjie
public class HttpResponseWriter {
    public HttpResponseWriter(let ctx: HttpContext)
}
```

Function: HTTP response body writer, allowing users to control the sending process of the response body.

> **Note:**
>
> - The first call to the `write` function will immediately send the header and the body passed as a parameter. Subsequent calls will send the body passed in each call.
> - For HTTP/1.1, if `transfer-encoding: chunked` is set, each call to `write` will send a chunk.
> - For HTTP/2, each call to `write` will encapsulate and send the specified data.

### HttpResponseWriter(HttpContext)

```cangjie
public HttpResponseWriter(let ctx: HttpContext)
```

Function: Constructs an [HttpResponseWriter](http_package_classes.md#class-httpresponsewriter) instance.

Parameters:

- ctx: [HttpContext](#class-httpcontext) - The HTTP request context.

### func write(Array\<Byte>)

```cangjie
public func write(buf: Array<Byte>): Unit
```

Function: Sends the data in `buf` to the client.

Parameters:

- buf: Array\<Byte> - The data to be sent.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the request method is "HEAD" or the response status code is "1XX\204\304".
- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the connection is closed.
- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the response protocol version is HTTP/1.0.
- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the response connection has been upgraded to [WebSocket](http_package_classes.md#class-websocket).

## class NotFoundHandler

```cangjie
public class NotFoundHandler <: HttpRequestHandler
```

Function: A convenient HTTP request handler for `404 Not Found` responses.

Parent Type:

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

Function: Processes the HTTP request and replies with a 404 response.

Parameters:

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - The HTTP request context.

## class OptionsHandler

```cangjie
public class OptionsHandler <: HttpRequestHandler
```

Function: A convenient HTTP handler for processing OPTIONS requests. Always returns the response header "Allow: OPTIONS, GET, HEAD, POST, PUT, DELETE".

Parent Type:

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

Function: Processes the HTTP OPTIONS request.

Parameters:

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - HTTP request context.

## class ProtocolService

```cangjie
public abstract class ProtocolService
```

Functionality: HTTP protocol service instance that provides HTTP services for a single client connection, including parsing client request messages, dispatching request processing, and sending responses.

### prop distributor

```cangjie
protected prop distributor: HttpRequestDistributor
```

Function: Retrieves the request distributor, which routes requests to corresponding handlers based on URLs.

Type: [HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor)

### prop httpKeepAliveTimeout

```cangjie
protected prop httpKeepAliveTimeout: Duration
```

Function: HTTP/1.1 specific. Retrieves the server-configured timeout duration for maintaining persistent connections.

Type: Duration

### prop logger

```cangjie
protected prop logger: Logger
```

Function: Retrieves the server logger. Setting `logger.level` takes immediate effect. The logger should be thread-safe.

Type: [Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

### prop maxRequestBodySize

```cangjie
protected prop maxRequestBodySize: Int64
```

Function: Retrieves the server-configured maximum request body size for reading requests. Only applies to HTTP/1.1 requests without "Transfer-Encoding: chunked" header.

Type: Int64

### prop maxRequestHeaderSize

```cangjie
protected prop maxRequestHeaderSize: Int64
```

Function: Retrieves the server-configured maximum request header size for reading requests. Only applies to HTTP/1.1. For HTTP/2, use the dedicated `maxHeaderListSize` configuration.

Type: Int64

### prop readHeaderTimeout

```cangjie
protected prop readHeaderTimeout: Duration
```

Function: Retrieves the server-configured timeout duration for reading request headers.

Type: Duration

### prop readTimeout

```cangjie
protected prop readTimeout: Duration
```

Function: Retrieves the server-configured timeout duration for reading the entire request.

Type: Duration

### prop server

```cangjie
protected open mut prop server: Server
```

Functionality: Returns the [Server](#class-server) instance, provides default implementation, set as the bound [Server](#class-server) instance.

### prop writeTimeout

```cangjie
protected prop writeTimeout: Duration
```

Function: Gets the timeout duration for writing responses as configured by the server.

Type: Duration

### func close()

```cangjie
protected open func close(): Unit
```

Function: Forces the connection to close. Provides a default implementation with no specific behavior.

### func closeGracefully()

```cangjie
protected open func closeGracefully(): Unit
```

Functionality: Gracefully closes the connection, provides default implementation with no behavior.

### func close()

```cangjie
protected open func close(): Unit
```

Functionality: Forcefully closes the connection, provides default implementation with no behavior.

## class RedirectHandler

```cangjie
public class RedirectHandler <: HttpRequestHandler {
    public init(url: String, code: UInt16)
}
```

Functionality: Convenient HTTP handler for returning redirect responses.

Parent Type:

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### init(String, UInt16)

```cangjie
public init(url: String, code: UInt16)
```

Functionality: Constructor for [RedirectHandler](http_package_classes.md#class-redirecthandler).

Parameters:

- url: String - The URL for the Location header in the redirect response.
- code: UInt16 - The response code for the redirect response.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Throws an exception when the URL is empty or the response code is not a 3XX status code (excluding 304).

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

Functionality: Processes HTTP requests and returns redirect responses.

Parameters:

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - HTTP request context.

## class Server

```cangjie
public class Server
```

Functionality: [Server](http_package_classes.md#class-server) class that provides HTTP services.

> **Note:**
>
> - Starts the service, waiting for client connections at the specified address and port to serve HTTP requests;
> - Closes the service, including all existing connections;
> - Provides a mechanism for registering HTTP request handlers, distributing requests to corresponding handlers based on registration information;
> - Supports hot TLS certificate updates;
> - Provides shutdown callback mechanism;
> - Enables/disables log printing via [Logger](../../../log/log_package_api/log_package_classes.md#class-logger).level, including printing logs at specified levels as required;
> - The [Server](http_package_classes.md#class-server) documentation does not explicitly specify supported version configurations, which will take effect for both HTTP/1.1 and HTTP/2.

### prop addr

```cangjie
public prop addr: String
```

Functionality: Gets the server listening address.

Type: String

### prop distributor

```cangjie
public prop distributor: HttpRequestDistributor
```

Functionality: Gets the request distributor, which routes requests to corresponding handlers based on URLs.

Type: [HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor)

### prop enableConnectProtocol

```cangjie
public prop enableConnectProtocol: Bool
```

Functionality: HTTP/2 specific, used to restrict whether peer messages support protocol upgrades via the CONNECT method. true indicates support.

Type: Bool

### prop headerTableSize

```cangjie
public prop headerTableSize: UInt32
```

Functionality: Gets the initial value of the server's HTTP/2 HPACK dynamic table. Default value is 4096.

Type: UInt32

### prop httpKeepAliveTimeout

```cangjie
public prop httpKeepAliveTimeout: Duration
```

Functionality: HTTP/1.1 specific, gets the server-set timeout for keeping long connections alive.

Type: Duration

### prop initialWindowSize

```cangjie
public prop initialWindowSize: UInt32
```

Functionality: HTTP/2 specific, used to restrict the initial flow control window size for peer message streams. Default value is 65535, valid range is 0 to 2^31 - 1.

Type: UInt32

### prop listener

```cangjie
public prop listener: ServerSocket
```

Functionality: Gets the server-bound socket.

Type: ServerSocket

### prop logger

```cangjie
public prop logger: Logger
```

Functionality: Gets the server logger. Setting logger.level takes immediate effect. The logger should be thread-safe.

Type: [Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

### prop maxConcurrentStreams

```cangjie
public prop maxConcurrentStreams: UInt32
```

Functionality: HTTP/2 specific, used to restrict the maximum number of concurrent requests processed by a connection.

Type: UInt32

### prop maxFrameSize

```cangjie
public prop maxFrameSize: UInt32
```

Functionality: HTTP/2 specific, used to restrict the maximum length of a single frame in peer messages. Default value is 16384, valid range is 2^14 to 2^24 - 1.

Type: UInt32

### prop maxHeaderListSize

```cangjie
public prop maxHeaderListSize: UInt32
```

Functionality: Gets the maximum HTTP/2 header size supported by the client. This size refers to the maximum allowed total length of all header fields in the response headers, including the length of field names, values, and the pseudo-header overhead automatically added for each field (typically 32 bytes per field, including pseudo-header information added by the HTTP/2 protocol itself). By default, this maximum length is set to UInt32.Max.

Type: UInt32

### prop maxRequestBodySize

```cangjie
public prop maxRequestBodySize: Int64
```

Functionality: Gets the server-set maximum size for reading request bodies, only effective for HTTP/1.1 requests without "Transfer-Encoding: chunked".

Type: Int64

### prop maxRequestHeaderSize

```cangjie
public prop maxRequestHeaderSize: Int64
```

Functionality: Gets the server-set maximum size for reading request headers. Only effective for HTTP/1.1; HTTP/2 has a dedicated configuration maxHeaderListSize.

Type: Int64

### prop port

```cangjie
public prop port: UInt16
```

Functionality: Gets the server listening port.

Type: UInt16

### prop protocolServiceFactory

```cangjie
public prop protocolServiceFactory: ProtocolServiceFactory
```

Functionality: Gets the protocol service factory, which generates service instances required for each protocol.

Type: [ProtocolServiceFactory](http_package_interfaces.md#interface-protocolservicefactory)

### prop readHeaderTimeout

```cangjie
public prop readHeaderTimeout: Duration
```

Functionality: Gets the server-set timeout for reading request headers.

Type: Duration

### prop readTimeout

```cangjie
public prop readTimeout: Duration
```

Functionality: Gets the server-set timeout for reading the entire request. It is recommended to configure this explicitly in production. If left unlimited by default, slow requests may hold server connections and resources for a long time, increasing the risk of slow-request attacks.

Type: Duration

### prop servicePoolConfig

```cangjie
public prop servicePoolConfig: ServicePoolConfig
```

Functionality: Gets the coroutine pool configuration instance.

Type: [ServicePoolConfig](http_package_structs.md#struct-servicepoolconfig)

### prop transportConfig

```cangjie
public prop transportConfig: TransportConfig
```

Functionality: Gets the server-set transport layer configuration.

Type: [TransportConfig](http_package_structs.md#struct-transportconfig)

### prop writeTimeout

```cangjie
public prop writeTimeout: Duration
```

Function: Get the server's configured write response timeout duration. It is recommended to configure this explicitly in production. If left unlimited by default, slow reads or writes may hold server connections and resources for a long time, increasing the risk of slow-connection attacks.

Type: Duration

### func afterBind(() -> Unit)

```cangjie
public func afterBind(f: ()-> Unit): Unit
```

Function: Register a callback function to be executed after server startup. This function will be called after the internal ServerSocket instance binds but before accepting connections. Repeated calls will override previously registered functions.

Parameters:

- f: () -> Unit - Callback function with no parameters and Unit return type.

### func close()

```cangjie
public func close(): Unit
```

Function: Close the server. After closing, the server will no longer read or process requests. Repeated closures will only take effect the first time (including both close and closeGracefully).

### func closeGracefully()

```cangjie
public func closeGracefully(): Unit
```

Function: Close the server gracefully. After closing, the server will no longer read new requests but will wait for currently processing requests to complete before shutting down.

### func getTlsConfig()

```cangjie
public func getTlsConfig(): ?TlsConfig
```

Function: Get the server's configured TLS layer settings.

Return Value:

- ?[TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - The server's TLS configuration, returns None if not configured.

### func onShutdown(() -> Unit)

```cangjie
public func onShutdown(f: () -> Unit): Unit
```

Function: Register a callback function to be executed during server shutdown. This function will be called when the server shuts down. Repeated calls will override previously registered functions.

Parameters:

- f: () -> Unit - Callback function with no parameters and Unit return type.

### func serve()

```cangjie
public func serve(): Unit
```

Function: Start the server process. Does not support repeated startups.

h1 Request Validation and Processing:

- If request-line does not comply with RFC 9112 rules (request-line = method SP request-target SP HTTP-version), returns 400 response;
- Method consists of tokens and is case-sensitive; request-target must be a parsable URL; HTTP-version must be HTTP/1.0 or HTTP/1.1, otherwise returns 400 response;
- Headers name and value must comply with specific rules (see [HttpHeaders](http_package_classes.md#class-httpheaders) class documentation), otherwise returns 400 response;
- When headers size exceeds server's maxRequestHeaderSize setting, automatically returns 431 response;
- Headers must include "host" header with a unique value, otherwise returns 400 response; Headers cannot simultaneously contain "content-length" and "transfer-encoding", otherwise returns 400 response;
- For "transfer-encoding" header, the last value after splitting by "," must be "chunked", and previous values cannot contain "chunked", otherwise returns 400 response;
- For "content-length" header, value must be parsable as Int64 type and non-negative, otherwise returns 400 response. If value exceeds server's maxRequestBodySize, returns 413 response;
- If headers lack both "content-length" and "transfer-encoding: chunked", body is assumed absent by default;
- For "trailer" header, values cannot include "transfer-encoding", "trailer", or "content-length";
- For "expect" header, values containing anything other than "100-continue" will return 417 response;
- HTTP/1.0 defaults to short-lived connections. To maintain persistent connections, include headers "connection: keep-alive" and "keep-alive: timeout = XX, max = XX" to automatically maintain connections for specified timeout duration. HTTP/1.1 defaults to persistent connections. Failed request parsing closes the connection;
- Trailers are only allowed in chunked mode, and trailer entry names must be included in the "trailer" header, otherwise they will be automatically removed.

h1 Response Validation and Processing:

- If user doesn't configure response, automatically returns 200 response;
- If received request contains "connection: close" header but response configuration lacks "connection" header or its value doesn't include "close", automatically adds "connection: close". If received request lacks "connection: close" and response lacks "connection: keep-alive", automatically adds it;
- If headers contain hop-by-hop response headers: "proxy-connection", "keep-alive", "te", "transfer-encoding", "upgrade", these will be automatically added to "connection" header value;
- Automatically adds "date" response header, user-provided "date" will be ignored;
- If request method is "HEAD" or response status code is "1XX\204\304", body will be configured as empty;
- When body length is known, it will be compared with "content-length" header. If header is absent, it will be automatically added with body length value. If header value exceeds body length, throws [HttpException](http_package_exceptions.md#class-httpexception) in handler. If less than body length, body will be truncated to match "content-length" value;
- "set-cookie" headers in response will be sent separately, while other duplicate headers will be combined;
- For requests containing "expect: 100-continue" header, calling request.body.read() will automatically send 100 status response to client. User-initiated 100 status responses are prohibited and treated as server errors.

Enabling h2 Service: tlsConfig's supportedAlpnProtocols must include "h2". If TLS layer ALPN negotiation results in h2, h2 service will be enabled.

h2 Request Validation and Processing:

- Headers name and value must comply with specific rules (see [HttpHeaders](http_package_classes.md#class-httpheaders) class documentation). Additionally, names cannot contain uppercase characters, otherwise sends RST frame to close stream (no guaranteed response);
- Trailers name and value must follow same rules, otherwise closes stream;
- Headers cannot contain "connection", "transfer-encoding", "keep-alive", "upgrade", or "proxy-connection", otherwise closes stream;
- If "te" header exists, its value must be "trailers", otherwise closes stream;
- If both "host" header and ":authority" pseudo-header exist, their values must match, otherwise closes stream;
- If "content-length" header exists, all values must be parsable as Int64 type, and multiple values must be equal, otherwise closes stream;
- If "content-length" header exists with body, content-length value must match body size, otherwise closes stream;
- If "trailer" header exists, its values cannot contain "transfer-encoding", "trailer", or "content-length", otherwise closes stream;
- CONNECT method is only supported in [WebSocket](http_package_classes.md#class-websocket) upgrade scenarios, otherwise closes stream;
- Pseudo-headers must include ":method", ":scheme", ":path". ":method" value must consist of token characters, ":scheme" must be "https", ":path" cannot be empty, otherwise closes stream;
- Trailer entry names must be included in "trailer" header, otherwise automatically removed;
- Request headers size cannot exceed maxHeaderListSize, otherwise closes connection.

h2 Response Validation and Processing:

- If HEAD request response contains body, it will be automatically removed;
- Automatically adds "date" field, user-provided "date" will be ignored;
- If headers contain "connection", "transfer-encoding", "keep-alive", "upgrade", or "proxy-connection", they will be automatically removed;
- "set-cookie" headers in response will be sent separately, while other duplicate headers will be combined;
- If headers contain "content-length" and method isn't "HEAD", "content-length" will be removed;
- If method is "HEAD":
    - If headers contain "content-length" but value is invalid (not parsable as Int64 or contains multiple unequal values), calling [HttpResponseWriter](http_package_classes.md#class-httpresponsewriter)'s write function throws [HttpException](http_package_exceptions.md#class-httpexception). If user handler has already completed, logs will be printed;
    - If headers contain "content-length" and response.body.length ≠ -1, but values don't match, same handling as 6.1;
    - If headers contain "content-length" and response.body.length = -1 or matches "content-length" value, retains "content-length" header;
- Trailer entries must be included in "trailer" header, otherwise automatically removed;
- If handler throws exception and user hasn't called write to send partial response, returns 500 response. If user has sent partial response, sends RST frame to close stream.

After h2 server sends response, if stream state isn't CLOSED, sends RST frame with NO_ERROR code to close stream, preventing processed streams from consuming server resources.

h2 Flow Control:

- Connection flow window initial value is 65535. Each received DATA frame returns a connection-level WINDOW-UPDATE. When sending DATA, if connection flow window is negative, blocks until positive;
- Stream flow window initial value can be user-configured (default 65535). Each received DATA frame returns a stream-level WINDOW-UPDATE. When sending DATA, if stream flow window is negative, blocks until positive.

h2 Request Prioritization:

- Supports urgency-based request processing. h2 service processes requests concurrently by default. When concurrent resources are insufficient, processes requests by urgency (higher priority first).

Default [ProtocolServiceFactory](http_package_interfaces.md#interface-protocolservicefactory) Protocol Selection:

- For TCP connections, uses HTTP/1.1 server;
- For TLS connections, determines HTTP version based on ALPN negotiation: If result is "http/1.0", "http/1.1" or "", uses HTTP/1.1 server; If result is "h2", uses HTTP/2 server; Otherwise doesn't process request, logs and closes connection.

Exceptions:

- SocketException - Thrown when port listening fails.

### func updateCA(Array\<Certificate>)

```cangjie
public func updateCA(newCa: Array<Certificate>): Unit
```

Function: Hot update CA certificates.

Parameters:

- newCa: Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)> - CA certificates.

Exceptions:

- IllegalArgumentException - Thrown when parameters contain empty characters.
- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown when server lacks tlsConfig configuration.

### func updateCA(String)

```cangjie
public func updateCA(newCaFile: String): Unit
```

Function: Hot update CA certificates.

Parameters:

- newCaFile: String - CA certificate file.

Exceptions:

- IllegalArgumentException - Thrown when parameters contain empty characters.
- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown when server lacks tlsConfig configuration.

### func updateCert(Array\<Certificate>, PrivateKey)

```cangjie
public func updateCert(certChain: Array<Certificate>, certKey: PrivateKey): Unit
```

Function: Hot update TLS certificates.

Parameters:

- certChain: Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)> - Certificate chain.
- certKey: [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - Private key matching the certificate.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown when server lacks tlsConfig configuration.

### func updateCert(String, String)

```cangjie
public func updateCert(certificateChainFile: String, privateKeyFile: String): Unit
```

Function: Hot update TLS certificates.

Parameters:

- certificateChainFile: String - Certificate chain file.
- privateKeyFile: String - Private key file matching the certificate.

Exceptions:

- IllegalArgumentException - Thrown when parameters contain empty characters.
- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown when server lacks tlsConfig configuration.

## class ServerBuilder

```cangjie
public class ServerBuilder {
    public init()
}
```

Function: Provides builder for [Server](http_package_classes.md#class-server) instances.

Supports constructing an Http [Server](http_package_classes.md#class-server) with these parameters:

- Address and port;
- Thread-safe logger;
- [HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor) for registering handlers and distributing requests;
- HTTP/2 settings;
- Shutdown callbacks;
- Transport: listener, connections and their configurations;
- Protocol service: HTTP protocol parsing services;

Except for address/port and shutdown callbacks, all have default implementations. Users may omit other parameters during server construction.
Configurations not explicitly marked for specific versions in [ServerBuilder](http_package_classes.md#class-serverbuilder) documentation will apply to both HTTP/1.1 and HTTP/2.

> **Note:**
>
> This class provides a series of configuration functions. After configuration, call [build](./http_package_classes.md#func-build-3) to construct a [Server](./http_package_classes.md#class-server) instance. Configuration functions specify parameter ranges but don't validate them - validation occurs during [build](./http_package_classes.md#func-build-3).

### init()

```cangjie
public init()
```

Function: Creates a [ServerBuilder](http_package_classes.md#class-serverbuilder) instance.

### func addr(String)

```cangjie
public func addr(addr: String): ServerBuilder
```

Function: Sets server listening address. Ignored if listener is configured.

Format must comply with IPAddress specifications.

Parameters:

- addr: String - Address value.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func afterBind(()->Unit)

```cangjie
public func afterBind(f: ()->Unit): ServerBuilder
```

Function: Registers callback function for server startup. Called after internal ServerSocket instance binds but before accepting connections. Repeated calls override previous registrations.

Parameters:

- f: () ->Unit - Callback function with no parameters and Unit return type.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func build()

```cangjie
public func build(): Server
```

Function: Constructs [Server](http_package_classes.md#class-server) instance based on configured parameters.

Performs parameter value validation. Illegal values throw exceptions. Parameter ranges are specified in respective configuration functions.

Return Value:

- [Server](http_package_classes.md#class-server) - Generated [Server](http_package_classes.md#class-server) instance.

Exceptions:

- IllegalArgumentException - Thrown when parameters are illegal.
- IllegalFormatException - Thrown for format errors.

### func distributor(HttpRequestDistributor)

```cangjie
public func distributor(distributor: HttpRequestDistributor): ServerBuilder
```

Function: Sets the request distributor, which routes requests to corresponding handlers based on URLs. Uses the default distributor if not specified.

Parameters:

- distributor: [HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor) - Custom request distributor instance.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func enableConnectProtocol(Bool)

```cangjie
public func enableConnectProtocol(flag: Bool): ServerBuilder
```

Function: HTTP/2 specific. Configures whether the server accepts CONNECT requests. Default is false.

Parameters:

- flag: Bool - Whether the server accepts CONNECT requests.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func headerTableSize(UInt32)

```cangjie
public func headerTableSize(size: UInt32): ServerBuilder
```

Function: Sets the initial value of the HTTP/2 HPACK dynamic table for the server. Default is 4096.

Parameters:

- size: UInt32 - Maximum `table size` used by the server for response header encoding.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func httpKeepAliveTimeout(Duration)

```cangjie
public func httpKeepAliveTimeout(timeout: Duration): ServerBuilder
```

Function: HTTP/1.1 specific. Sets the server's connection keep-alive duration. The server will close persistent connections if no subsequent requests are received within this duration. Default is unlimited.

Parameters:

- timeout: Duration - Keep-alive timeout duration. Negative values will be replaced with Duration.Zero.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func initialWindowSize(UInt32)

```cangjie
public func initialWindowSize(size: UInt32): ServerBuilder
```

Function: HTTP/2 specific. Sets the initial flow control window size for receiving messages per stream on the server. Default is 65535. Valid range: 0 to 2^31 - 1.

Parameters:

- size: UInt32 - Initial flow control window size for receiving messages per stream.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func listener(ServerSocket)

```cangjie
public func listener(listener: ServerSocket): ServerBuilder
```

Function: Binds and listens on the specified socket for the server.

Parameters:

- listener: ServerSocket - The socket to bind.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func logger(Logger)

```cangjie
public func logger(logger: Logger): ServerBuilder
```

Function: Sets the server's logger. Default logger level is INFO, with output directed to Console.stdout.

Parameters:

- logger: [Logger](../../../log/log_package_api/log_package_classes.md#class-logger) - Must be thread-safe. Uses built-in thread-safe logger by default.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func maxConcurrentStreams(UInt32)

```cangjie
public func maxConcurrentStreams(size: UInt32): ServerBuilder
```

Function: HTTP/2 specific. Sets the maximum number of concurrent requests the server can handle, limiting the peer's concurrent request submissions. Default is 100.

Parameters:

- size: UInt32 - Maximum number of concurrent requests the server can handle.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func maxFrameSize(UInt32)

```cangjie
public func maxFrameSize(size: UInt32): ServerBuilder
```

Function: HTTP/2 specific. Sets the maximum frame length the server can receive, limiting the peer's frame size. Default is 16384. Valid range: 2^14 to 2^24 - 1.

Parameters:

- size: UInt32 - Maximum frame length the server can receive.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func maxHeaderListSize(UInt32)

```cangjie
public func maxHeaderListSize(size: UInt32): ServerBuilder
```

Function: Gets the client-supported maximum HTTP/2 header size. This size refers to the maximum allowed total length of all header fields in the response, including field names, values, and pseudo-header overhead (typically 32 bytes per field). Default is UInt32.Max.

Parameters:

- size: UInt32 - Maximum header length the server can receive.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func maxRequestBodySize(Int64)

```cangjie
public func maxRequestBodySize(size: Int64): ServerBuilder
```

Function: Sets the maximum allowed request body size for client requests. Returns a 413 status code if exceeded. Default is 2MB. Only applies to HTTP/1.1 requests without "Transfer-Encoding: chunked".

Parameters:

- size: Int64 - Maximum allowed request body size. 0 means unlimited.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

Exceptions:

- IllegalArgumentException - Thrown when size < 0.

### func maxRequestHeaderSize(Int64)

```cangjie
public func maxRequestHeaderSize(size: Int64): ServerBuilder
```

Function: Sets the maximum allowed request header size for client requests. Returns a 431 status code if exceeded. Only applies to HTTP/1.1 (HTTP/2 uses maxHeaderListSize).

Parameters:

- size: Int64 - Maximum allowed request header size. 0 means unlimited.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

Exceptions:

- IllegalArgumentException - Thrown when size < 0.

### func onShutdown(() -> Unit)

```cangjie
public func onShutdown(f: () -> Unit): ServerBuilder
```

Function: Registers a callback function triggered during server shutdown. Repeated calls will overwrite previous registrations.

Parameters:

- f: () ->Unit - Callback function with no parameters and Unit return type.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func port(UInt16)

```cangjie
public func port(port: UInt16): ServerBuilder
```

Function: Sets the server's listening port. Ignored if listener is specified.

Parameters:

- port: UInt16 - Port number.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func protocolServiceFactory(ProtocolServiceFactory)

```cangjie
public func protocolServiceFactory(factory: ProtocolServiceFactory): ServerBuilder
```

Function: Sets the protocol service factory, which generates service instances for each protocol. Uses default factory if not specified.

Parameters:

- factory: [ProtocolServiceFactory](http_package_interfaces.md#interface-protocolservicefactory) - Custom factory instance.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func readHeaderTimeout(Duration)

```cangjie
public func readHeaderTimeout(timeout: Duration): ServerBuilder
```

Function: Sets the maximum duration for reading a request header. Closes connection if exceeded. Default is unlimited.

Parameters:

- timeout: Duration - Header read timeout. Negative values are replaced with Duration.Zero.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func readTimeout(Duration)

```cangjie
public func readTimeout(timeout: Duration): ServerBuilder
```

Function: Sets the maximum duration for reading a complete request. Closes connection if exceeded. Default is unlimited. It is recommended to set this explicitly in production. Otherwise, slow requests may keep connections and server resources occupied for too long, increasing the risk of slow-request attacks.

Parameters:

- timeout: Duration - Request read timeout. Negative values are replaced with Duration.Zero.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func servicePoolConfig(ServicePoolConfig)

```cangjie
public func servicePoolConfig(cfg: ServicePoolConfig): ServerBuilder
```

Function: Configures coroutine pool settings used during service processing. See [ServicePoolConfig](http_package_structs.md#struct-servicepoolconfig) for details.

Parameters:

- cfg: [ServicePoolConfig](http_package_structs.md#struct-servicepoolconfig) - Coroutine pool configuration.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func tlsConfig(TlsConfig)

```cangjie
public func tlsConfig(config: TlsConfig): ServerBuilder
```

Function: Configure TLS layer settings, which are not set by default.

Parameters:

- config: [TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - Configuration information required for setting up TLS service support.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func transportConfig(TransportConfig)

```cangjie
public func transportConfig(config: TransportConfig): ServerBuilder
```

Function: Configure transport layer settings. Default configurations are detailed in the [TransportConfig](http_package_structs.md#struct-transportconfig) struct description.

Parameters:

- config: [TransportConfig](http_package_structs.md#struct-transportconfig) - Transport layer configuration information to be set.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

### func writeTimeout(Duration)

```cangjie
public func writeTimeout(timeout: Duration): ServerBuilder
```

Function: Set the maximum duration for the server to send a response. Exceeding this duration will stop writing and close the connection. By default, there is no limit. It is recommended to set this explicitly in production. Otherwise, slow reads or writes may keep connections and server resources occupied for too long, increasing the risk of slow-connection attacks.

Parameters:

- timeout: Duration - Timeout duration for writing responses. If a negative value is passed, it will be replaced with Duration.Zero.

Return Value:

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - Reference to the current [ServerBuilder](http_package_classes.md#class-serverbuilder).

## class WebSocket

```cangjie
public class WebSocket
```

Function: Provides a class for [WebSocket](http_package_classes.md#class-websocket) services, offering functions for reading, writing, and closing [WebSocket](http_package_classes.md#class-websocket) connections. Users can obtain a [WebSocket](http_package_classes.md#class-websocket) connection via the `upgradeFrom` function.

- Call `read()` to read a [WebSocketFrame](http_package_classes.md#class-websocketframe). Users can determine the frame type via [WebSocketFrame](http_package_classes.md#class-websocketframe).frameType and whether it is a fragmented frame via [WebSocketFrame](http_package_classes.md#class-websocketframe).fin.
- Call `write(frameType: WebSocketFrameType, byteArray: Array<UInt8>)` to send [WebSocket](http_package_classes.md#class-websocket) messages by specifying the message type and message bytes. Control frames are sent without fragmentation, while data frames (Text, Binary) are fragmented according to the underlying buffer size (split into multiple fragments).

Detailed descriptions are provided in the interface documentation below. Interface behavior follows RFC 6455.

### prop logger

```cangjie
public prop logger: Logger
```

Function: Logger.

Type: [Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

### prop subProtocol

```cangjie
public prop subProtocol: String
```

Function: Get the negotiated subProtocol with the peer. During negotiation, the client provides a ranked list of preferred subProtocols, and the server selects one or none.

Type: String

### static func upgradeFromClient(Client, URL, Protocol, ArrayList\<String>, HttpHeaders)

```cangjie
public static func upgradeFromClient(client: Client, url: URL,
 version!: Protocol = HTTP1_1,
 subProtocols!: ArrayList<String> = ArrayList<String>(), 
 headers!: HttpHeaders = HttpHeaders()): (WebSocket, HttpHeaders)
```

Function: Provides a function for clients to upgrade to the [WebSocket](http_package_classes.md#class-websocket) protocol.

> **Note:**
>
> The client upgrade process involves passing a client object and URL object, constructing an upgrade request, verifying the server's response. If the handshake succeeds, it returns a [WebSocket](http_package_classes.md#class-websocket) object for [WebSocket](http_package_classes.md#class-websocket) communication and the [HttpHeaders](http_package_classes.md#class-httpheaders) object from the 101 response. Extensions are not currently supported. If subprotocol negotiation succeeds, users can check the subprotocol via the returned [WebSocket](http_package_classes.md#class-websocket)'s subProtocol property.

Parameters:

- client: [Client](http_package_classes.md#class-client) - Client object for the request.
- url: [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) - URL object for the request. Note that the URL scheme must be `ws` or `wss` for WebSocket upgrades.
- version!: [Protocol](http_package_enums.md#enum-protocol) - HTTP version used to create the socket. Only [HTTP1_1](./http_package_enums.md#enum-protocol) and [HTTP2_0](./http_package_enums.md#enum-protocol) are supported for WebSocket upgrades.
- subProtocols!: ArrayList\<String> - User-configured list of subprotocols, ranked by preference. Default is empty. If configured, it will be sent to the server with the upgrade request.
- headers!: [HttpHeaders](http_package_classes.md#class-httpheaders) - Non-essential headers (e.g., cookies) to be sent with the upgrade request.

Return Value:

- ([WebSocket](http_package_classes.md#class-websocket), HttpHeaders) - If the upgrade succeeds, returns a [WebSocket](http_package_classes.md#class-websocket) object for communication and the headers from the 101 response.

Exceptions:

- SocketException - Thrown for underlying connection errors.
- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown for HTTP request errors during the handshake.
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - Thrown if the upgrade fails due to invalid response verification.

### static func upgradeFromServer(HttpContext, ArrayList\<String>, ArrayList\<String>, (HttpRequest) -> HttpHeaders)

```cangjie
public static func upgradeFromServer(ctx: HttpContext, subProtocols!: ArrayList<String> = ArrayList<String>(), 
                                        origins!: ArrayList<String> = ArrayList<String>(), 
                                        userFunc!:(HttpRequest) -> HttpHeaders = {_: HttpRequest => HttpHeaders()}): WebSocket
```

Function: Provides a function for servers to upgrade to the [WebSocket](http_package_classes.md#class-websocket) protocol, typically used in handlers.

The server upgrade process involves receiving an upgrade request from the client, verifying the request, and replying with a 101 response if verification passes. It then returns a [WebSocket](http_package_classes.md#class-websocket) object for [WebSocket](http_package_classes.md#class-websocket) communication.

- Users configure supported subprotocols and origin whitelists via the `subProtocols` and `origins` parameters. If `subProtocols` is not set, no subprotocols are supported. If `origins` is not set, all origin handshake requests are accepted.
- Users can customize upgrade request handling (e.g., processing cookies) via the `userFunc` parameter. The `userFunc` must return an [HttpHeaders](http_package_classes.md#class-httpheaders) object, which is sent back to the client in the 101 response (failed upgrades do not return headers).
- WebSocket extensions are not currently supported. If extensions are negotiated during the handshake, a [WebSocketException](http_package_exceptions.md#class-websocketexception) is thrown.
- Only [HTTP1_1](./http_package_enums.md#enum-protocol) and [HTTP2_0](./http_package_enums.md#enum-protocol) are supported for WebSocket upgrades.

Parameters:

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - HTTP request context, passed directly from the handler to `upgradeFromServer`.
- subProtocols!: ArrayList\<String> - User-configured list of subprotocols. Default is empty (no support). If configured, the most preferred subprotocol from the upgrade request is selected as the WebSocket's subprotocol. Users can check the subprotocol via the returned [WebSocket](http_package_classes.md#class-websocket)'s subProtocol property.
- origins!: ArrayList\<String> - User-configured whitelist of allowed origins. If not configured, all origins are accepted. If configured, only requests from listed origins are accepted.
- userFunc!: ([HttpRequest](http_package_classes.md#class-httprequest)) ->[HttpHeaders](http_package_classes.md#class-httpheaders) - User-defined function for custom upgrade request handling. The function returns an [HttpHeaders](http_package_classes.md#class-httpheaders) object.

Return Value:

- [WebSocket](http_package_classes.md#class-websocket) - The upgraded [WebSocket](http_package_classes.md#class-websocket) instance.

### func closeConn()

```cangjie
public func closeConn(): Unit
```

Function: Provides a function to close the underlying [WebSocket](http_package_classes.md#class-websocket) connection.

> **Note:**
>
> Directly closes the underlying connection. The standard closing process requires following the protocol's handshake procedure: first sending a Close frame to the peer and waiting for a Close frame response. The underlying connection should only be closed after the handshake completes.

### func read()

```cangjie
public func read(): WebSocketFrame
```

Function: Reads a frame from the connection. Blocks if data is not ready. Not thread-safe (i.e., multi-threaded reading on the same [WebSocket](http_package_classes.md#class-websocket) object is not supported).

The `read` function returns a [WebSocketFrame](http_package_classes.md#class-websocketframe) object. Users can determine the frame type and whether it is fragmented via the [WebSocketFrame](http_package_classes.md#class-websocketframe)'s `frameType` and `fin` properties. The raw binary data array (Array\<UInt8>) can be obtained via the [WebSocketFrame](http_package_classes.md#class-websocketframe)'s `payload` function.

- The first fragment of a fragmented frame has `fin == false` and `frameType == TextWebFrame` or `BinaryWebFrame`. Intermediate fragments have `fin == false` and `frameType == ContinuationWebFrame`. The last fragment has `fin == true` and `frameType == ContinuationWebFrame`.
- Non-fragmented frames have `fin == true` and `frameType != ContinuationWebFrame`.

> **Note:**
>
> - Data frames (Text, Binary) can be fragmented. Users must call `read` multiple times to receive all fragments (referred to as receiving a complete message) and concatenate the payloads in order. Text frame payloads are UTF-8 encoded. After receiving a complete message, users can convert the concatenated payload to a string using `String.fromUtf8`. Binary frame payloads are application-specific. After receiving a complete message, users pass the concatenated payload to the upper-layer application.
> - Control frames (Close, Ping, Pong) cannot be fragmented.
> - Control frames cannot be fragmented but can be interleaved between fragmented data frames. Fragmented data frames cannot be interleaved with other data frames. If interleaved fragments are received, treat as an error.
> - Clients must receive masked frames; servers must receive unmasked frames. Otherwise, the underlying connection is closed, and an exception is thrown.
> - If rsv1, rsv2, or rsv3 bits are set (extensions are not supported, so these bits must be 0), the underlying connection is closed, and an exception is thrown.
> - If an unrecognized frame type is received (only Continuation, Text, Binary, Close, Ping, Pong are supported), the underlying connection is closed, and an exception is thrown.
> - If a fragmented or payload length exceeds 125 bytes for control frames (Close, Ping, Pong), the underlying connection is closed, and an exception is thrown.
> - If a payload length exceeds 20MB, the underlying connection is closed, and an exception is thrown.
> - For fragmented data frames (messages composed of multiple continuation frames), there is no limit on the total size of the complete message after assembling all fragments.
> - If `read` is called after `closeConn` closes the connection, an exception is thrown.

Return Value:

- [WebSocketFrame](http_package_classes.md#class-websocketframe) - The read [WebSocketFrame](http_package_classes.md#class-websocketframe) object.

Exceptions:

- SocketException - Thrown for underlying connection errors.
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - Thrown if a frame violates protocol rules. A Close frame is sent to the peer with an error message, and the underlying connection is closed.
- [ConnectionException](http_package_exceptions.md#class-connectionexception) - Thrown if the peer closes the connection while reading.

### func write(WebSocketFrameType, Array\<UInt8>, Int64)

```cangjie
public func write(frameType: WebSocketFrameType, byteArray: Array<UInt8>, frameSize!: Int64 = 4096): Unit
```

Function: Sends data. Not thread-safe (i.e., multi-threaded writing on the same [WebSocket](http_package_classes.md#class-websocket) object is not supported).

> **Note:**
>
> The `write` function sends data to the peer as a [WebSocket](http_package_classes.md#class-websocket) frame.
>
> - For data frames (Text, Binary), if the `byteArray` exceeds `frameSize` (default 4 * 1024 bytes), it is split into payloads of `frameSize` or smaller and sent as fragmented frames. Otherwise, no fragmentation occurs.
> - For control frames (Close, Ping, Pong), the `byteArray` size must not exceed 125 bytes. Close frames include a 2-byte status code (valid codes are listed in RFC 6455 7.4. Status Codes). After sending a Close frame, sending data frames is prohibited and will throw an exception.
> - Users must ensure the `byteArray` complies with the protocol (e.g., Text frame payloads must be UTF-8 encoded). If `frameSize` is set for data frames, it must be greater than 0; otherwise, an exception is thrown.
> - If `frameSize` is less than or equal to 0 for data frames, an exception is thrown.
> - If a control frame's data exceeds 125 bytes, an exception is thrown.
> - If an unsupported frame type (not Text, Binary, Close, Ping, Pong) is passed, an exception is thrown.
> - If an invalid status code or reason exceeding 123 bytes is passed for Close frames, an exception is thrown.
> - If data frames are sent after a Close frame, an exception is thrown.
> - If `write` is called after `closeConn` closes the connection, an exception is thrown.

Parameters:

- frameType: [WebSocketFrameType](http_package_enums.md#enum-websocketframetype) - Type of frame to send.
- byteArray: Array\<UInt8> - Payload of the frame (in binary form).
- frameSize!: Int64 - Size of fragmented frames. Default is 4 * 1024 bytes. Does not apply to control frames (invalid if set).

Exceptions:

- SocketException - Thrown for underlying connection errors.
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - Thrown for invalid frame types or data.

### func writeCloseFrame(?UInt16, String)

```cangjie
public func writeCloseFrame(status!: ?UInt16 = None, reason!: String = ""): Unit
```

Function: Sends a Close frame.

> **Note:**
>
> After sending a Close frame, sending data frames is prohibited. If `status` is not set, `reason` is not sent (i.e., a reason requires a status). Control frame payloads must not exceed 125 bytes. Close frames include a 2-byte status code, so `reason` must not exceed 123 bytes. If `write` is called after `closeConn` closes the connection, an exception is thrown.

Parameters:

- status!: ?UInt16 - Status code for the Close frame. Default is `None` (no status or reason sent).
- reason!: String - Explanation for closing the connection. Default is an empty string. Sent as UTF-8 (readability not guaranteed; for debugging).

Exceptions:

- [WebSocketException](http_package_exceptions.md#class-websocketexception) - Thrown for invalid status codes or reasons exceeding 123 bytes.

### func writePingFrame(Array\<UInt8>)

```cangjie
public func writePingFrame(byteArray: Array<UInt8>): Unit
```

Function: Provides a shortcut for sending Ping frames. If `write` is called after `closeConn` closes the connection, an exception is thrown.

Parameters:

- byteArray: Array\<UInt8> - Payload of the frame (in binary form).

Exceptions:

- SocketException - Thrown for underlying connection errors.
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - Thrown if data exceeds 125 bytes.

### func writePongFrame(Array\<UInt8>)

```cangjie
public func writePongFrame(byteArray: Array<UInt8>): Unit
```

Function: Provides a shortcut for sending Pong frames. If `write` is called after `closeConn` closes the connection, an exception is thrown.

Parameters:

- byteArray: Array\<UInt8> - Payload of the frame (in binary form).

Exceptions:

- SocketException - Thrown for underlying connection errors.
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - Thrown if data exceeds 125 bytes.

## class WebSocketFrame

```cangjie
public class WebSocketFrame
```

Function: The basic unit for reading in [WebSocket](http_package_classes.md#class-websocket).

[WebSocketFrame](http_package_classes.md#class-websocketframe) provides three properties: `fin` and `frameType` indicate whether the frame is fragmented and its type, while `payload` contains the frame's payload.

- The first fragment frame has `fin == false` and `frameType == TextWebFrame` or `BinaryWebFrame`.
- Intermediate frames have `fin == false` and `frameType == ContinuationWebFrame`.
- The last fragment frame has `fin == true` and `frameType == ContinuationWebFrame`.
- Non-fragmented frames have `fin == true` and `frameType != ContinuationWebFrame`.
- Users can only obtain [WebSocketFrame](http_package_classes.md#class-websocketframe) objects via the [WebSocket](http_package_classes.md#class-websocket) object's `read` function. For fragmented data frames, users must call `read` repeatedly to receive the complete message and concatenate the payloads in order.

> **Note:**
>
> Control frames can be interleaved between fragment frames. Users must handle control frames separately when concatenating fragment payloads. Only control frames can be interleaved between fragments; interleaving other data frames is invalid and must be treated as an error.

### prop fin

```cangjie
public prop fin: Bool
```

Function: Retrieves the `fin` property of [WebSocketFrame](http_package_classes.md#class-websocketframe). Together with `frameType`, it indicates whether the frame is fragmented and its type.

Type: Bool

### prop frameType

```cangjie
public prop frameType: WebSocketFrameType
```

Function: Gets the frame type of [WebSocketFrame](http_package_classes.md#class-websocketframe). The combination of `fin` and `frameType` indicates whether the frame is fragmented and its type.

Type: [WebSocketFrameType](http_package_enums.md#enum-websocketframetype)

### prop payload

```cangjie
public prop payload: Array<UInt8>
```

Function: Gets the payload of [WebSocketFrame](http_package_classes.md#class-websocketframe). For fragmented data frames, users need to concatenate the payloads of all fragments in the order received after receiving the complete message.

Type: Array\<UInt8>
