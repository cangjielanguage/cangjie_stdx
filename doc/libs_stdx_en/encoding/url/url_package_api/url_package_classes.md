# Class

## class Form

```cangjie
public class Form {
    public init()
    public init(queryComponent: String)
}
```

Functionality: [Form](url_package_classes.md#class-form) stores HTTP request form information in key-value pairs, typically representing the query component of a request [URL](url_package_classes.md#class-url).

A single key can correspond to multiple values, stored as an array. Key-value pairs are separated by `&`; the left side of `=` serves as the key, and the right side as the value (absence of `=` or empty values are both permitted). For usage examples, see [Form Construction and Usage](../url_samples/form.md).

### init()

```cangjie
public init()
```

Functionality: Constructs a default [Form](url_package_classes.md#class-form) instance.

### init(String)

```cangjie
public init(queryComponent: String)
```

Functionality: Constructs a [Form](url_package_classes.md#class-form) instance from a URL-encoded query string, i.e., the query component of a [URL](url_package_classes.md#class-url) instance.

Parses the URL-encoded query string to obtain key-value pairs and adds them to the newly constructed [Form](url_package_classes.md#class-form) instance.

Parameters:

- queryComponent: String - The string representing the query component of a [URL](url_package_classes.md#class-url), excluding the leading `?` character.

Exceptions:

- IllegalArgumentException - Thrown when the URL string contains bytes that violate UTF-8 encoding rules.
- [UrlSyntaxException](url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the URL string contains illegal escape characters.

### func add(String, String)

```cangjie
public func add(key: String, value: String): Unit
```

Functionality: Adds a new key-value mapping. If the key already exists, appends the value to the end of the existing value array.

Parameters:

- key: String - The specified key, which may be new.
- value: String - The value to be added to the array corresponding to the specified key.

### func clone()

```cangjie
public func clone(): Form
```

Functionality: Clones the [Form](url_package_classes.md#class-form).

Return Value:

- [Form](url_package_classes.md#class-form) - A newly cloned [Form](url_package_classes.md#class-form) instance.

### func get(String)

```cangjie
public func get(key: String): Option<String>
```

Functionality: Retrieves the first value corresponding to the specified key.

Examples:

- When the query component is `a=b`, `form.get("a")` returns `Some(b)`.
- When the query component is `a=`, `form.get("a")` returns `Some()`.
- When the query component is `a`, `form.get("a")` returns `Some()`.
- When the query component is `a`, `form.get("c")` returns `None`.

Parameters:

- key: String - The specified key.

Return Value:

- Option\<String> - The first value corresponding to the specified key, represented as Option\<String>.

### func getAll(String)

```cangjie
public func getAll(key: String): ArrayList<String>
```

Functionality: Retrieves all values corresponding to the specified key.

Parameters:

- key: String - The user-specified key used to retrieve corresponding values.

Return Value:

- ArrayList\<String> - An array containing all values corresponding to the specified key. Returns an empty array if the key does not exist.

### func isEmpty()

```cangjie
public func isEmpty(): Bool
```

Functionality: Determines whether the [Form](url_package_classes.md#class-form) is empty.

Return Value:

- Bool - Returns true if empty; otherwise, returns false.

### func remove(String)

```cangjie
public func remove(key: String): Unit
```

Functionality: Removes the specified key and its corresponding values.

Parameters:

- key: String - The key to be removed.

### func set(String, String)

```cangjie
public func set(key: String, value: String): Unit
```

Functionality: Resets the value corresponding to the specified key.

Parameters:

- key: String - The specified key.
- value: String - The new value to be set for the specified key.

### func toEncodeString()

```cangjie
public func toEncodeString(): String
```

Functionality: Encodes key-value pairs in the form using percent-encoding.

Unreserved characters are not encoded, and spaces are encoded as '+'.

> **Note:**
>
> RFC 3986 defines unreserved characters as: unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"

Return Value:

- String - The encoded string.

## class URL

```cangjie
public class URL <: ToString {
    public init(scheme!: String, hostName!: String, path!: String)
}
```

Functionality: This class provides functions for parsing [URL](url_package_classes.md#class-url) and related operations.

Percent-encoded content in the string is decoded and stored in corresponding components, while the original values are preserved in respective `raw` properties. Username and password components (if present) are parsed according to RFC 3986 specifications.

> **Warning:**
>
> RFC 3986 explicitly states that storing user information in plaintext poses leakage risks in all scenarios. Therefore, it is recommended not to store user information in URLs as plaintext.

Parent Type:

- ToString

### prop fragment

```cangjie
public prop fragment: ?String
```

Functionality: Retrieves the decoded fragment component as a string.

Type: ?String

### prop host

```cangjie
public prop host: String
```

Functionality: Retrieves the decoded hostname and port components as a string.

Type: String

### prop hostName

```cangjie
public prop hostName: String
```

Functionality: Retrieves the decoded hostname as a string.

Type: String

### prop opaque

```cangjie
public prop opaque: String
```

Functionality: Retrieves the unparsed portion of the [URL](url_package_classes.md#class-url) as a string.

Type: String

Example:

```cangjie
import stdx.encoding.url.*

main () {
    let url = URL.parse("https:\\\\/example.com/foo/bar") // '\' is not a protocol-defined separator and cannot be parsed.
    println("url.scheme=${url.scheme}")
    println("url.host=${url.host}")
    println("url.opaque=${url.opaque}")
}
```

Output:

```text
url.scheme=https
url.host=
url.opaque=\\/example.com/foo/bar
```

### prop path

```cangjie
public prop path: String
```

Functionality: Retrieves the decoded path component as a string.

Type: String

### prop port

```cangjie
public prop port: String
```

Functionality: Retrieves the port number as a string, where an empty string indicates no port number.

Type: String

### prop query

```cangjie
public prop query: ?String
```

Functionality: Retrieves the decoded query component as a string.

Type: ?String

### prop queryForm

```cangjie
public prop queryForm: Form
```

Functionality: Retrieves the decoded query component as a [Form](url_package_classes.md#class-form) instance.

Type: [Form](url_package_classes.md#class-form)

### prop rawFragment

```cangjie
public prop rawFragment: ?String
```

Functionality: Retrieves the undecoded fragment component as a string.

Type: ?String

### prop rawPath

```cangjie
public prop rawPath: String
```

Functionality: Retrieves the undecoded path component as a string.Type: String

### prop rawQuery

```cangjie
public prop rawQuery: ?String
```

Function: Gets the undecoded query component represented as a string.

Type: ?String

### prop rawUserInfo

```cangjie
public prop rawUserInfo: UserInfo
```

Function: Gets the undecoded username and password information represented as a [UserInfo](url_package_classes.md#class-userinfo) instance.

Type: [UserInfo](url_package_classes.md#class-userinfo)

### prop scheme

```cangjie
public prop scheme: String
```

Function: Gets the protocol part of the [URL](url_package_classes.md#class-url) represented as a string.

Type: String

### prop userInfo

```cangjie
public prop userInfo: UserInfo
```

Function: Gets the decoded username and password information represented as a [UserInfo](url_package_classes.md#class-userinfo) instance.

Type: [UserInfo](url_package_classes.md#class-userinfo)

### init(String, String, String)

```cangjie
public init(scheme!: String, hostName!: String, path!: String)
```

Function: Constructs a [URL](url_package_classes.md#class-url) instance.

Construction requirements:

- When hostName is present, scheme must be specified.
- Scheme alone cannot exist.
- When both scheme and path exist, the path must be absolute.

Parameters:

- scheme!: String - The protocol type.
- hostName!: String - The hostname without port number.
- path!: String - The resource request path.

Exceptions:

- [UrlSyntaxException](url_package_exceptions.md#class-urlsyntaxexception) - Thrown when construction requirements are not met.

### static func decode(String): String

```cangjie
public static func decode(url: String): String
```

Function: Perform decoding on a URL-encoded (that is, percent-encoded) string to restore the encoded string to its original form, without decoding the reserved characters.

> **Warning:**
>
> This function decodes all encoded characters. However, some characters are part of the URL syntax, so the following characters will be retained in the output string:
>
> `#` `$` `&` `+` `,` `/` `:` `;` `=` `?` `@`

Parameters:

- url: String - The string to be decoded.

Returns:

- String - The decoded string.

### static func decodeComponent(String): String

```cangjie
public static func decodeComponent(component: String): String
```

Function: It performs a decoding operation on a URL-encoded (also known as percent-encoded) string, restoring the encoded string to its original form.

Parameters:

- component: String - The string to be decoded.

Returns:

- String - The decoded string.

### static func encode(String): String

```cangjie
public static func encode(url: String): String
```

Function: Perform URL encoding (also referred to as percent-encoding) on regular strings. The purpose of URL encoding is to convert special characters, non-ASCII characters, and other such characters in the string into a format that complies with URL specifications, thereby ensuring these strings can be safely transmitted and used within a URL.

> **Warning:**
>
> This function encodes all characters. However, some characters are reserved by URL syntax, so the following characters will not be encoded:
>
> `0-9` `A-Z` `a-z`
>
> `!` `'` `-` `.` `*` `(` `)` `_` `~`
>
> `#` `$` `&` `+` `,` `/` `:` `;` `=` `?` `@`

Parameters:

- url: String - The string to be encoded.

Returns:

- String - The encoded string.

### static func encodeComponent(String): String

```cangjie
public static func encodeComponent(component: String): String
```

Function: Perform URL encoding (also known as percent-encoding) on regular strings. The purpose of URL encoding is to convert special characters, non-ASCII characters, and other such characters in the string into a format that complies with URL specifications, thereby ensuring these strings can be safely transmitted and used within a URL.

> **Warning:**
>
> This function encodes all characters, including those in URL syntax. However, some characters are reserved by URL syntax, so the following characters will not be encoded:
>
> `0-9` `A-Z` `a-z`
>
> `!` `'` `-` `.` `*` `(` `)` `_` `~`

Parameters:

- component: String - The string to be encoded.

Returns:

- String - The encoded string.

### static func mergePaths(String, String)

```cangjie
public static func mergePaths(basePath: String, refPath: String): String
```

Function: Merges two paths.

Merging rules: Appends the reference path refPath to the last segment of the base path basePath. If refPath is absolute, the result is refPath's original value. If refPath is not absolute, it is concatenated after the last `/` in basePath. All results are normalized (`.` characters, `..` characters, and consecutive `/` characters are optimized). See examples below. For detailed behavior, refer to RFC 3986.

To merge URLs, use [resolveURL](#func-resolveurlurl).

Examples:

- `/a/b/c` merged with `/d` outputs `/d`.
- `/a/b/c` merged with `d` outputs `/a/b/d`.
- `/a/b/` merged with `d/e/../f` outputs `/a/b/d/f`.
- `/a/b/c/` merged with `./../../g` outputs `/a/g`.

Parameters:

- basePath: String - The base path.
- refPath: String - The reference path.

Returns:

- String - The merged and normalized path.

### static func parse(String)

```cangjie
public static func parse(rawUrl: String): URL
```

Function: Parses a raw URL string into a [URL](url_package_classes.md#class-url) object.

This function decomposes the [URL](url_package_classes.md#class-url) into components, decodes them, and stores them in respective properties. The rawXXX properties store the original undecoded values.

For usage examples, see [URL parse function usage](../url_samples/url_parse.md#usage-of-the-url-parsing-function-parse).

> **Note:**
>
> This function can parse usernames and passwords in URLs (if present), which complies with RFC 3986. However, RFC 3986 also explicitly states that storing user information in plaintext poses leakage risks. It is recommended not to store user information in URLs.

Parameters:

- rawUrl: String - The [URL](url_package_classes.md#class-url) string.

Returns:

- [URL](url_package_classes.md#class-url) - The parsed [URL](url_package_classes.md#class-url) instance.

Exceptions:

- [UrlSyntaxException](url_package_exceptions.md#class-urlsyntaxexception) - Thrown when the URL string contains illegal characters.
- IllegalArgumentException - Thrown when encoded characters do not conform to `UTF-8` byte sequence rules.

### func isAbsoluteURL()

```cangjie
public func isAbsoluteURL(): Bool
```

Function: Determines whether the [URL](url_package_classes.md#class-url) is absolute (a URL with a scheme is absolute).

Returns:

- Bool - Returns true if scheme exists, otherwise false.

### func replace(Option\<String>, Option\<String>, Option\<String>, Option\<String>, Option\<String>, Option\<String>, Option\<String>)

```cangjie
public func replace(scheme!: Option<String> = None, userInfo!: Option<String> = None,
 hostName!: Option<String> = None, port!: Option<String> = None, path!: Option<String> = None, 
 query!: Option<String> = None, fragment!: Option<String> = None): URL
```

Function: Replaces components of the [URL](url_package_classes.md#class-url) object and returns a new [URL](url_package_classes.md#class-url) object.

Replacement requirements:

- If scheme is empty, hostName must be empty.
- If hostName is empty, userInfo or port must be empty.
- If scheme is not empty, hostName and path cannot both be empty.
- If scheme is not empty, path must be absolute.
- All components must contain valid characters.

Parameters:

- scheme!: Option\<String> - The protocol component.
- userInfo!: Option\<String> - The user information.
- hostName!: Option\<String> - The hostname.
- port!: Option\<String> - The port number.
- path!: Option\<String> - The resource path.
- query!: Option\<String> - The query component.
- fragment!: Option\<String> - The fragment component.

Returns:

- [URL](url_package_classes.md#class-url) - The new [URL](url_package_classes.md#class-url) object.

Exceptions:

- [UrlSyntaxException](url_package_exceptions.md#class-urlsyntaxexception) - Thrown when replacement requirements are not met.

### func resolveURL(URL)

```cangjie
public func resolveURL(ref: URL): URL
```

Function: Uses the current [URL](url_package_classes.md#class-url) instance as the base URL and the input [URL](url_package_classes.md#class-url) as the reference URL to generate a new [URL](url_package_classes.md#class-url) instance according to RFC 3986.

Example: With <http://a/b/c/d;p?q> as the base URL, the following shows reference URLs (left) and generated URLs (right):

- "g"      =  "<http://a/b/c/g>"
- "/g"     =  "<http://a/g>"
- "g?y"    =  "<http://a/b/c/g?y>"
- "g?y#s"  =  "<http://a/b/c/g?y#s>"
- "../"    =  "<http://a/b/>"

For detailed URL generation rules, refer to RFC 3968.

Parameters:

- ref: [URL](url_package_classes.md#class-url) - The reference [URL](url_package_classes.md#class-url) object.

Returns:

- [URL](url_package_classes.md#class-url) - The new [URL](url_package_classes.md#class-url) instance.

### func toString()

```cangjie
public func toString(): String
```

Function: Gets the string value of the current [URL](url_package_classes.md#class-url) instance.

Encodes hostName and uses rawXXX property values for other components, concatenating them in URL component order.

Returns:

- String - The string value of the current [URL](url_package_classes.md#class-url) instance.

## class UserInfo

```cangjie
public class UserInfo <: ToString {
    public init()
    public init(userName: String)
    public init(userName: String, passWord: String)
    public init(userName: String, passWord: Option<String>)
}
```

Function: [UserInfo](url_package_classes.md#class-userinfo) represents username and password information in URLs.

> **Note:**
>
> RFC 3986 explicitly states that storing user information in plaintext poses leakage risks. It is recommended not to store user information in URLs.

Parent Type:

- ToString

### init()

```cangjie
public init()
```

Function: Creates a [UserInfo](url_package_classes.md#class-userinfo) instance.

### init(String)

```cangjie
public init(userName: String)
```

Function: Creates a [UserInfo](url_package_classes.md#class-userinfo) instance with a username.

Parameters:

- userName: String - The username.

### init(String, Option\<String>)

```cangjie
public init(userName: String, passWord: Option<String>)
```

Function: Creates a [UserInfo](url_package_classes.md#class-userinfo) instance with a username and password.

Parameters:

- userName: String - The username.
- passWord: Option\<String> - The password, represented as Option\<String>.

### init(String, String)

```cangjie
public init(userName: String, passWord: String)
```

Function: Creates a [UserInfo](url_package_classes.md#class-userinfo) instance with a username and password.

Parameters:

- userName: String - The username.
- passWord: String - The password.

### func password()

```cangjie
public func password(): Option<String>
```

Function: Gets the password information.

> **Note:**
>
> RFC 3986 explicitly states that storing user information in plaintext poses leakage risks. It is recommended not to store user information in URLs.

Returns:

- Option\<String> - The password as Option\<String>.

### func toString()

```cangjie
public func toString(): String
```

Function: Converts the current [UserInfo](url_package_classes.md#class-userinfo) instance to a string.

Return Value:

- String - The string representation of the current [UserInfo](url_package_classes.md#class-userinfo) instance.

### func username()

```cangjie
public func username(): String
```

Function: Retrieves the username information.

Return Value:

- String - The username as a String type.