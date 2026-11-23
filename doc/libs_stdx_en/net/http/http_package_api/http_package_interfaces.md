# Interfaces

## interface CookieJar

```cangjie
public interface CookieJar {
    prop isHttp: Bool
    prop rejectPublicSuffixes: ArrayList<String>
    static func createDefaultCookieJar(rejectPublicSuffixes: ArrayList<String>, isHttp: Bool): CookieJar
    static func parseSetCookieHeader(response: HttpResponse): ArrayList<Cookie>
    static func toCookieString(cookies: ArrayList<Cookie>): String
    func clear(): Unit
    func getCookies(url: URL): ArrayList<Cookie>
    func removeCookies(domain: String): Unit
    func storeCookies(url: URL, cookies: ArrayList<Cookie>): Unit
}
```

Functionality: [CookieJar](http_package_interfaces.md#interface-cookiejar) is a utility used by [Client](http_package_classes.md#class-client) to manage [Cookie](http_package_classes.md#class-cookie).

It provides two static functions:

- [toCookieString](#static-func-tocookiestringarraylistcookie) converts ArrayList\<[Cookie](http_package_classes.md#class-cookie)> into a string for setting the [Cookie](http_package_classes.md#class-cookie) header in requests.
- [parseSetCookieHeader](#static-func-parsesetcookieheaderhttpresponse) parses the `Set-Cookie` header from received responses.

[Client](http_package_classes.md#class-client) enables a built-in [CookieJar](http_package_interfaces.md#interface-cookiejar) by default, which automatically stores and sends back [Cookie](http_package_classes.md#class-cookie)s. It can be disabled by setting None via [ClientBuilder.cookieJar](http_package_classes.md#func-cookiejarcookiejar), or replaced with a custom implementation.

> **Note**
>
> - Users can implement their own [CookieJar](http_package_interfaces.md#interface-cookiejar) with custom management logic.
> - [CookieJar](http_package_interfaces.md#interface-cookiejar) management requirements follow [RFC 6265](https://httpwg.org/specs/rfc6265.html).

### prop isHttp

```cangjie
prop isHttp: Bool
```

Functionality: Indicates whether this [CookieJar](http_package_interfaces.md#interface-cookiejar) is used for HTTP protocol.

- If isHttp is true, only [Cookie](http_package_classes.md#class-cookie) from HTTP protocol will be stored.
- If isHttp is false, only [Cookie](http_package_classes.md#class-cookie) from non-HTTP protocols will be stored, and httpOnly [Cookie](http_package_classes.md#class-cookie) will not be stored.

Type: Bool

### prop rejectPublicSuffixes

```cangjie
prop rejectPublicSuffixes: ArrayList<String>
```

Functionality: Retrieves the [public suffixes](https://publicsuffix.org/) configuration, which is a domain blacklist that rejects [Cookie](http_package_classes.md#class-cookie) with domain values matching public suffixes.

> **Note:**
>
> This blacklist does not apply if the [Cookie](http_package_classes.md#class-cookie) originates from the same host as the domain.

Type: ArrayList\<String>

### static func createDefaultCookieJar(ArrayList\<String>, Bool)

```cangjie
static func createDefaultCookieJar(rejectPublicSuffixes: ArrayList<String>, isHttp: Bool): CookieJar
```

Functionality: Creates a default [CookieJar](http_package_interfaces.md#interface-cookiejar) instance for managing [Cookie](http_package_classes.md#class-cookie).

The default [CookieJar](http_package_interfaces.md#interface-cookiejar) follows the management requirements specified in [RFC 6265 5.3.](https://httpwg.org/specs/rfc6265.html#storage-model).

Parameters:

- rejectPublicSuffixes: ArrayList\<String> - User-configured public suffixes. For security, [Cookie](http_package_classes.md#class-cookie) management will reject cookies with domain values matching public suffixes (unless the [Cookie](http_package_classes.md#class-cookie) originates from the same host as the domain). Public suffixes are defined in [PUBLIC SUFFIX LIST](https://publicsuffix.org/).
- isHttp: Bool - Indicates whether this [CookieJar](http_package_interfaces.md#interface-cookiejar) is used for HTTP protocol. If true, only [Cookie](http_package_classes.md#class-cookie) from HTTP protocol will be stored.

Return Value:

- [CookieJar](http_package_interfaces.md#interface-cookiejar) - Default [CookieJar](http_package_interfaces.md#interface-cookiejar) instance.

### static func parseSetCookieHeader(HttpResponse)

```cangjie
static func parseSetCookieHeader(response: HttpResponse): ArrayList<Cookie>
```

Functionality: Parses the `Set-Cookie` header from a response.

This function parses the `Set-Cookie` header from the response and returns an ArrayList\<[Cookie](http_package_classes.md#class-cookie)>. The parsing rules for `Set-Cookie` header follow [RFC 6265 5.2.](https://httpwg.org/specs/rfc6265.html#set-cookie).

Parameters:

- response: [HttpResponse](http_package_classes.md#class-httpresponse) - The response to be parsed.

Return Value:

- ArrayList\<[Cookie](http_package_classes.md#class-cookie)> - Parsed ArrayList\<[Cookie](http_package_classes.md#class-cookie)> from the response.

### static func toCookieString(ArrayList\<Cookie>)

```cangjie
static func toCookieString(cookies: ArrayList<Cookie>): String
```

Functionality: Converts ArrayList\<[Cookie](http_package_classes.md#class-cookie)> into a string for the [Cookie](http_package_classes.md#class-cookie) header.

This function converts the input ArrayList\<[Cookie](http_package_classes.md#class-cookie)> into the string format required for the [Cookie](http_package_classes.md#class-cookie) header, as specified in [RFC 6265 5.4.4.](https://httpwg.org/specs/rfc6265.html#cookie).

Parameters:

- cookies: ArrayList\<[Cookie](http_package_classes.md#class-cookie)> - The ArrayList\<[Cookie](http_package_classes.md#class-cookie)> to be converted into a [Cookie](http_package_classes.md#class-cookie) header string.

Return Value:

- String - The string for the [Cookie](http_package_classes.md#class-cookie) header.

### func clear()

```cangjie
func clear(): Unit
```

Functionality: Clears all [Cookie](http_package_classes.md#class-cookie).

The default implementation CookieJarImpl removes all [Cookie](http_package_classes.md#class-cookie) from the [CookieJar](http_package_interfaces.md#interface-cookiejar).

### func getCookies(URL)

```cangjie
func getCookies(url: URL): ArrayList<Cookie>
```

Functionality: Retrieves ArrayList\<[Cookie](http_package_classes.md#class-cookie)> from the [CookieJar](http_package_interfaces.md#interface-cookiejar).

> The default implementation cookieJarImpl follows the requirements in [RFC 6265 5.4.](https://httpwg.org/specs/rfc6265.html#cookie) for retrieving ArrayList\<[Cookie](http_package_classes.md#class-cookie)>. Calling toCookieString on the retrieved ArrayList\<[Cookie](http_package_classes.md#class-cookie)> converts it into the value string for the [Cookie](http_package_classes.md#class-cookie) header.

Parameters:

- url: [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) - The URL for which to retrieve ArrayList\<[Cookie](http_package_classes.md#class-cookie)>.

Return Value:

- ArrayList\<[Cookie](http_package_classes.md#class-cookie)> - The ArrayList\<[Cookie](http_package_classes.md#class-cookie)> stored in the [CookieJar](http_package_interfaces.md#interface-cookiejar) corresponding to this URL.

### func removeCookies(String)

```cangjie
func removeCookies(domain: String): Unit
```

Functionality: Removes [Cookie](http_package_classes.md#class-cookie) for a specific domain from the [CookieJar](http_package_interfaces.md#interface-cookiejar).

> **Note:**
>
> The default implementation CookieJarImpl only removes [Cookie](http_package_classes.md#class-cookie) for the specified domain; [Cookie](http_package_classes.md#class-cookie) for subdomains are not removed.

Parameters:

- domain: String - The domain for which to remove [Cookie](http_package_classes.md#class-cookie).

Exceptions:

- IllegalArgumentException - Thrown if the provided domain is an empty string or invalid. Valid domain rules are specified in the parameter documentation of [Cookie](http_package_classes.md#class-cookie).

### func storeCookies(URL, ArrayList\<Cookie>)

```cangjie
func storeCookies(url: URL, cookies: ArrayList<Cookie>): Unit
```

Functionality: Stores ArrayList\<[Cookie](http_package_classes.md#class-cookie)> in the [CookieJar](http_package_interfaces.md#interface-cookiejar).

[Cookie](http_package_classes.md#class-cookie) storage follows [RFC 6265 5.3](https://httpwg.org/specs/rfc6265.html#storage-model): a [Cookie](http_package_classes.md#class-cookie) whose max-age-av value is less than or equal to 0, or whose expiry time has passed, does not add a new entry but instead deletes the stored [Cookie](http_package_classes.md#class-cookie) with the same name, domain and path (for example, a deletion instruction sent by the server via `Set-Cookie: name=; Max-Age=0`).

> **Note:**
>
> - If the [Cookie](http_package_classes.md#class-cookie) to be stored has a url scheme other than https/wss and the [CookieJar](http_package_interfaces.md#interface-cookiejar) contains a secure [Cookie](http_package_classes.md#class-cookie) with the same name, whose domain domain-matches and whose path path-matches, the storage (including the deletion instruction) is ignored and the stored secure [Cookie](http_package_classes.md#class-cookie) remains unchanged ([RFC 6265bis 5.4 step 14](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis#section-5.4), leave secure cookies alone); sources with an https/wss scheme are not subject to this restriction.

If storing [Cookie](http_package_classes.md#class-cookie) exceeds the limit (3000 entries), at least 1000 [Cookie](http_package_classes.md#class-cookie) will be cleared from the [CookieJar](http_package_interfaces.md#interface-cookiejar) before storage. The priority for clearing [Cookie](http_package_classes.md#class-cookie) follows [RFC 6265 5.3.12.](https://httpwg.org/specs/rfc6265.html#storage-model). This rule also applies to the built-in [CookieJar](http_package_interfaces.md#interface-cookiejar) enabled by default in [Client](http_package_classes.md#class-client) (see the [ClientBuilder.cookieJar](http_package_classes.md#func-cookiejarcookiejar) description).

[Cookie](http_package_classes.md#class-cookie) are cleared in the following order:

- Expired [Cookie](http_package_classes.md#class-cookie);
- Entries exceeding 50 per domain;
- If all [Cookie](http_package_classes.md#class-cookie) have the same priority, those with earlier `last-access` attributes are removed first.

Parameters:

- url: [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) - The URL that generated this [Cookie](http_package_classes.md#class-cookie).
- cookies: ArrayList\<[Cookie](http_package_classes.md#class-cookie)> - The ArrayList\<[Cookie](http_package_classes.md#class-cookie)> to be stored.

## interface HttpRequestDistributor

```cangjie
public interface HttpRequestDistributor {
    func register(path: String, handler: HttpRequestHandler): Unit
    func register(path: String, handler: (HttpContext) -> Unit): Unit
    func distribute(path: String): HttpRequestHandler
}
```

Functionality: HTTP request distributor interface that routes requests to corresponding [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler) based on the path in the URL.

> **Note:**
>
> This implementation provides a default [HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor), which is not thread-safe.
> Registration can only occur before starting the server; results are undefined if registration occurs after startup.
> If users need to register handlers after server startup, they must provide their own thread-safe [HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor) implementation.

### func distribute(String)

```cangjie
func distribute(path: String): HttpRequestHandler
```

Functionality: Distributes request handlers. Returns [NotFoundHandler](http_package_classes.md#class-notfoundhandler) to respond with a 404 status code if no matching handler is found.

Parameters:

- path: String - The request path.

Return Value:

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler) - The request handler.

### func register(String, (HttpContext) -> Unit)

```cangjie
func register(path: String, handler: (HttpContext) -> Unit): Unit
```

Functionality: Registers a request handler.

Parameters:

- path: String - The request path.
- handler: ([HttpContext](http_package_classes.md#class-httpcontext)) ->Unit - The request handler function.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the request path already has a registered handler.

### func register(String, HttpRequestHandler)

```cangjie
func register(path: String, handler: HttpRequestHandler): Unit
```

Functionality: Registers a request handler.

Parameters:

- path: String - The request path.
- handler: [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler) - The request handler.

Exceptions:

- [HttpException](http_package_exceptions.md#class-httpexception) - Thrown if the request path already has a registered handler.

## interface HttpRequestHandler

```cangjie
public interface HttpRequestHandler {
    func handle(ctx: HttpContext): Unit
}
```

Functionality: HTTP request handler.

The HTTP server processes client HTTP requests through handlers. In the handler, users can access detailed request information, including headers and body. Users can construct HTTP responses, including headers and body, and either send the response directly to the client or delegate it to the server.

When building an HTTP server, users must manually register one or more handlers via the server's [HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor). When a client HTTP request is received, the distributor routes it to the corresponding handler based on the path in the URL.

> **Warning:**
>
> Applications should guard against DNS rebinding attacks by validating the Host header value in the request to ensure it matches an authorized hostname for the application.

### func handle(HttpContext)

```cangjie
func handle(ctx: HttpContext): Unit
```

Functionality: Processes HTTP requests.

Parameters:

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - The HTTP request context.

## interface ProtocolServiceFactory

```cangjie
public interface ProtocolServiceFactory {
    func create(protocol: Protocol, socket: StreamingSocket): ProtocolService
}
```

Functionality: HTTP service instance factory for generating `ProtocolService` instances.

[ServerBuilder](http_package_classes.md#class-serverbuilder) provides the default implementation, which can generate `ProtocolService` instances for HTTP/1.1 and HTTP/2.

### func create(Protocol, StreamingSocket)

```cangjie
func create(protocol: Protocol, socket: StreamingSocket): ProtocolService
```

Functionality: Creates a protocol service instance based on the specified protocol.Parameters:

- `protocol`: [Protocol](http_package_enums.md#enum-protocol) - Protocol version, such as [HTTP1_0](./http_package_enums.md#enum-protocol), [HTTP1_1](./http_package_enums.md#enum-protocol), [HTTP2_0](./http_package_enums.md#enum-protocol).
- `socket`: `StreamingSocket` - The socket from the client.

Return Value:

- `ProtocolService` - Protocol service instance.