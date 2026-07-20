# 类

## class Form

```cangjie
public class Form {
    public init()
    public init(queryComponent: String)
}
```

功能：[Form](url_package_classes.md#class-form) 以 key-value 键值对形式存储 http 请求的表单信息，通常为请求 [URL](url_package_classes.md#class-url) 中的 query 部分。

同一个 key 可以对应多个 value，value 以数组形式存储。`&` 符号分隔多个键值对；`=` 分隔的左侧作为 key 值，右侧作为 value 值（没有 `=` 或者 value 为空，均是允许的）。使用示例见 [Form 的构造使用](../url_samples/form.md)。

### init()

```cangjie
public init()
```

功能：构造一个默认的 [Form](url_package_classes.md#class-form) 实例。

示例：

<!-- run -->
```cangjie
import stdx.encoding.url.*

main() {
    // 使用无参构造函数创建Form实例 
    let form = Form()
}
```

### init(String)

```cangjie
public init(queryComponent: String)
```

功能：根据 [URL](url_package_classes.md#class-url) 编码的查询字符串，即 [URL](url_package_classes.md#class-url) 实例的 query 部分构造 [Form](url_package_classes.md#class-form) 实例。

解析 [URL](url_package_classes.md#class-url) 编码的查询字符串，得到若干键值对，并将其添加到新构造的 [Form](url_package_classes.md#class-form) 实例中。

参数：

- queryComponent: String - [URL](url_package_classes.md#class-url) 的 query 组件部分的字符串，但是不包括组件前面的 `?` 符号。

异常：

- IllegalArgumentException - 当[URL](url_package_classes.md#class-url) 字符串中包含不符合 utf8 编码规则的字节时，抛出异常。
- [UrlSyntaxException](url_package_exceptions.md#class-urlsyntaxexception) - 当 [URL](url_package_classes.md#class-url) 字符串中包含非法转义字符时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.encoding.url.*

main() {
    // 使用带参构造函数创建Form实例 
    let form = Form("name=Zhangsan&age=30&city=Nanjing")
}
```

### func add(String, String)

```cangjie
public func add(key: String, value: String): Unit
```

功能：新增 key-value 映射，如果 key 已存在，则将 value 添加到原来 value 数组的最后面。

参数：

- key: String - 指定键，可以是新增的。
- value: String - 将该值添加到指定键对应的值数组中。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建一个Form实例 
    let form = Form()

    // 添加键值对 
    form.add("username", "admin")
    form.add("password", "123456")

    println("toEncodeString: ${form.toEncodeString()}")
}
```

运行结果：

```text
toEncodeString: username=admin&password=123456
```

### func clone()

```cangjie
public func clone(): Form
```

功能：克隆 [Form](url_package_classes.md#class-form)。

返回值：

- [Form](url_package_classes.md#class-form) - 克隆得到的新 [Form](url_package_classes.md#class-form) 实例。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建一个Form实例并添加一些键值对 
    let originalForm = Form("item1=value1&item2=value2")

    // 克隆Form实例 
    let clonedForm = originalForm.clone()

    println("克隆的是否是 Form: ${clonedForm is Form}")
    println("toEncodeString: ${clonedForm.toEncodeString()}")
}
```

运行结果：

```text
克隆的是否是 Form: true
toEncodeString: item1=value1&item2=value2
```

### func get(String)

```cangjie
public func get(key: String): Option<String>
```

功能：根据 key 获取第一个对应的 value 值。

情况举例：

- 当 query 组件部分是 `a=b` 时，`form.get("a")`获得 `Some(b)`。
- 当 query 组件部分是 `a=` 时，`form.get("a")`获得 `Some()`。
- 当 query 组件部分是 `a` 时，`form.get("a")`获得 `Some()`。
- 当 query 组件部分是 `a` 时，`form.get("c")`获得 `None`。

参数：

- key: String - 指定键。

返回值：

- Option\<String> - 根据指定键获取的第一个值，用 Option\<String> 类型表示。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建一个Form实例并添加一些键值对 
    let form = Form()
    form.add("username", "admin")
    form.add("email", "admin@example.com")

    // 获取指定键的值 
    let usernameResult = form.get("username")
    let emailResult = form.get("email")
    let nonexistentResult = form.get("nonexistent")

    println("username: ${usernameResult}")
    println("email: ${emailResult}")
    println("nonexistent: ${nonexistentResult}")
}
```

运行结果：

```text
username: Some(admin)
email: Some(admin@example.com)
nonexistent: None
```

### func getAll(String)

```cangjie
public func getAll(key: String): ArrayList<String>
```

功能：根据指定的键（key）获取该键（key）对应的所有 value 值。

参数：

- key: String - 用户指定的键（key），用于获取对应的 value 值。

返回值：

- ArrayList\<String> - 根据指定键（key）获取的全部 value 值对应的数组。当指定键（key）不存在时，返回空数组。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建一个Form实例并添加一些键值对 
    let form = Form()
    form.add("tag", "red")
    form.add("tag", "blue")
    form.add("tag", "green")
    form.add("name", "myForm")

    // 获取指定键的所有值 
    let tagValues = form.getAll("tag")
    let nameValues = form.getAll("name")
    let nonexistentValues = form.getAll("nonexistent")

    println("tagValues: ${tagValues}")
    println("nameValues: ${nameValues}")
    println("nonexistentValues: ${nonexistentValues}")
}
```

运行结果：

```text
tagValues: [red, blue, green]
nameValues: [myForm]
nonexistentValues: []
```

### func isEmpty()

```cangjie
public func isEmpty(): Bool
```

功能：判断 [Form](url_package_classes.md#class-form) 是否为空。

返回值：

- Bool - 如果为空，则返回 true；否则，返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建一个空Form实例 
    let emptyForm = Form()

    // 检查Form是否为空 
    let isEmpty = emptyForm.isEmpty()

    // 添加一些数据后再检查 
    emptyForm.add("key", "value")
    let isNotEmpty = emptyForm.isEmpty()

    println("是否为空: ${isEmpty}")
    println("添加数据后是否为空: ${isNotEmpty}")
}
```

运行结果：

```text
是否为空: true
添加数据后是否为空: false
```

### func remove(String)

```cangjie
public func remove(key: String): Unit
```

功能：删除 key 及其对应 value。

参数：

- key: String - 需要删除的键。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建一个Form实例并添加一些键值对 
    let form = Form()
    form.add("username", "admin")
    form.add("password", "secret")

    // 移除指定的键值对 
    form.remove("password")
    // 移除不存在的键值对，无异常
    form.remove("nonexistent")

    println("toEncodeString: ${form.toEncodeString()}")
}
```

运行结果：

```text
toEncodeString: username=admin
```

### func set(String, String)

```cangjie
public func set(key: String, value: String): Unit
```

功能：重置指定 key 对应的 value。

参数：

- key: String - 指定键。
- value: String - 将指定键的值设置为 value。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建一个Form实例并添加一些键值对 
    let form = Form()
    form.add("key1", "value1")

    // 重置指定键的值 
    form.set("key1", "newvalue1")
    // 重置不存在的键的值，会创建新的键值对
    form.set("key2", "value2")

    println("toEncodeString: ${form.toEncodeString()}")
}
```

运行结果：

```text
toEncodeString: key1=newvalue1&key2=value2
```

### func toEncodeString()

```cangjie
public func toEncodeString(): String
```

功能：对表单中的键值对进行编码，编码采用百分号编码。

未保留字符不会被编码，空格将编码为 '+'。

> **说明：**
>
> RFC 3986 协议中对未保留字符定义如下： unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"

返回值：

- String - 编码后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建一个Form实例并添加一些键值对 
    let form = Form()
    // 存在空格
    form.add("name", "Zhang san")
    // 存在保留字符‘-’，不会进行编码
    form.add("生日", "2026-1-8")
    // 存在特殊字符，会进行编码
    form.add("email", "zhangsan@example.com")

    // 将表单转换为编码字符串 
    let encodedString = form.toEncodeString()

    println("toEncodeString: ${encodedString}")
}
```

运行结果：

```text
toEncodeString: name=Zhang+san&%E7%94%9F%E6%97%A5=2026-1-8&email=zhangsan%40example.com
```

## class URL

```cangjie
public class URL <: ToString {
    public init(scheme!: String, hostName!: String, path!: String)
}
```

功能：该类提供解析 [URL](url_package_classes.md#class-url) 的函数以及其他相关函数。

字符串中被百分号`%`编码的内容会被解码，保存在相应的组件之中，而初始值保存在相应的 `raw` 属性之中。[URL](url_package_classes.md#class-url) 中的用户名和密码部分（如果存在的话）也会按照 RFC 3986 协议的说明被解析。

> **注意：**
>
> RFC 3986 明确说明在任何场景下，明文保存用户信息存在被泄露风险，所以建议不要在 URL 中明文保存用户信息。

父类型：

- ToString

### prop fragment

```cangjie
public prop fragment: ?String
```

功能：获取解码后的锚点组件，用字符串表示。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://admin:password123@example.com/path?k=v#fragment%20with%20space")

    println("URL fragment: ${url.fragment}")
}
```

运行结果：

```text
URL fragment: Some(fragment with space)
```

### prop host

```cangjie
public prop host: String
```

功能：获取解码后的主机名和端口部分，用字符串表示。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://admin:password123@example.com:8080/path?k=v#fragment")

    println("URL host: ${url.host}")
}
```

运行结果：

```text
URL host: example.com:8080
```

### prop hostName

```cangjie
public prop hostName: String
```

功能：获取解码后的主机名，用字符串表示。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://admin:password123@example.com:8080/path?k=v#fragment")

    println("URL hostName: ${url.hostName}")
}
```

运行结果：

```text
URL hostName: example.com
```

### prop opaque

```cangjie
public prop opaque: String
```

功能：获取 [URL](url_package_classes.md#class-url) 中未被解析的部分，用字符串表示。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main(): Int64 {
    // 演示 opaque 属性（非层级 URL）
    // 这种 URL 格式为：scheme:opaque?query#fragment
    let mailtoUrl = URL.parse("mailto:test@example.com")
    println("=== 非层级 URL (带 opaque) ===")
    println("完整 URL: ${mailtoUrl}")
    println("scheme: ${mailtoUrl.scheme}")
    println("opaque: ${mailtoUrl.opaque}")
    println("host: ${mailtoUrl.host}")
    println("path: ${mailtoUrl.path}")

    println()

    // 对比层级 URL（没有 opaque）
    // 这种 URL 格式为：scheme://host/path?query#fragment
    let httpUrl = URL.parse("http://www.example.com/path?key=value")
    println("=== 层级 URL (无 opaque) ===")
    println("完整 URL: ${httpUrl}")
    println("scheme: ${httpUrl.scheme}")
    println("opaque: ${httpUrl.opaque}")
    println("host: ${httpUrl.host}")
    println("path: ${httpUrl.path}")

    println()

    // 其他常见的非层级 URL
    let telUrl = URL.parse("tel:+86-123-4567-8901")
    println("=== 电话号码 URL ===")
    println("完整 URL: ${telUrl}")
    println("scheme: ${telUrl.scheme}")
    println("opaque: ${telUrl.opaque}")

    return 0
}
```

运行结果：

```text
=== 非层级 URL (带 opaque) ===
完整 URL: mailto:test@example.com
scheme: mailto
opaque: test@example.com
host: 
path: 

=== 层级 URL (无 opaque) ===
完整 URL: http://www.example.com/path?key=value
scheme: http
opaque: 
host: www.example.com
path: /path

=== 电话号码 URL ===
完整 URL: tel:+86-123-4567-8901
scheme: tel
opaque: +86-123-4567-8901
```

### prop path

```cangjie
public prop path: String
```

功能：获取解码后的路径，用字符串表示。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://example.com:8080/api/v1/users?k=v#fragment")

    println("URL path: ${url.path}")
}
```

运行结果：

```text
URL path: /api/v1/users
```

### prop port

```cangjie
public prop port: String
```

功能：获取端口号，用字符串表示，空字符串表示无端口号。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://example.com:8080/api/v1/users?k=v#fragment")

    println("URL port: ${url.port}")
}
```

运行结果：

```text
URL port: 8080
```

### prop query

```cangjie
public prop query: ?String
```

功能：获取解码后的查询组件，用字符串表示。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://example.com:8080/api/v1/users?name=%E5%BC%A0%E4%B8%89&age=30#fragment")

    println("URL query: ${url.query}")
}
```

运行结果：

```text
URL query: Some(name=张三&age=30)
```

### prop queryForm

```cangjie
public prop queryForm: Form
```

功能：获取解码后的查询组件，用 [Form](url_package_classes.md#class-form) 实例表示。

类型：[Form](url_package_classes.md#class-form)

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://example.com:8080/api/v1/users?name=%E5%BC%A0%E4%B8%89&age=30#fragment")

    // 获取查询组件
    let queryForm = url.queryForm
    // 获取查询组件中的 name 值
    let name = queryForm.get("name")
    println("URL queryForm: ${name}")
}
```

运行结果：

```text
URL queryForm: Some(张三)
```

### prop rawFragment

```cangjie
public prop rawFragment: ?String
```

功能：获取解码前的锚点组件，用字符串表示。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://example.com:8080/path?k=v#fragment%20with%20space")

    println("URL rawFragment: ${url.rawFragment}")
}
```

运行结果：

```text
URL rawFragment: Some(fragment%20with%20space)
```

### prop rawPath

```cangjie
public prop rawPath: String
```

功能：获取解码前的路径，用字符串表示。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://example.com:8080/path%20with%20space?k=v#fragment")

    println("URL rawPath: ${url.rawPath}")
}
```

运行结果：

```text
URL rawPath: /path%20with%20space
```

### prop rawQuery

```cangjie
public prop rawQuery: ?String
```

功能：获取解码前的查询组件，用字符串表示。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://example.com:8080/path?name%3Djohn%26age%3D30#fragment")

    println("URL rawQuery: ${url.rawQuery}")
}
```

运行结果：

```text
URL rawQuery: Some(name%3Djohn%26age%3D30)
```

### prop rawUserInfo

```cangjie
public prop rawUserInfo: UserInfo
```

功能：获取解码前的用户名和密码信息，用 [UserInfo](url_package_classes.md#class-userinfo) 实例表示。

类型：[UserInfo](url_package_classes.md#class-userinfo)

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://admincompany:password123@example.com:8080/path?k=v#fragment")

    println("URL rawUserInfo: ${url.rawUserInfo}")
}
```

运行结果：

```text
URL rawUserInfo: admincompany:password123
```

### prop scheme

```cangjie
public prop scheme: String
```

功能：获取 [URL](url_package_classes.md#class-url) 中协议部分，用字符串表示。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://example.com:8080/path?k=v#fragment")

    println("URL scheme: ${url.scheme}")
}
```

运行结果：

```text
URL scheme: https
```

### prop userInfo

```cangjie
public prop userInfo: UserInfo
```

功能：获取解码后的用户名和密码信息，用 [UserInfo](url_package_classes.md#class-userinfo) 实例表示。

类型：[UserInfo](url_package_classes.md#class-userinfo)

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL
    let url = URL.parse("https://admin:password123@example.com:8080/path?k=v#fragment")

    println("URL userInfo: ${url.userInfo}")
}
```

运行结果：

```text
URL userInfo: admin:password123
```

### init(String, String, String)

```cangjie
public init(scheme!: String, hostName!: String, path!: String)
```

功能：构造一个 [URL](url_package_classes.md#class-url) 实例。

构造实例时需要满足要求：

- 拥有主机名 hostName 时，需要有协议 scheme。
- 不能只存在协议 scheme。
- 存在协议和路径的情况下，路径 path 必须是绝对路径。

参数：

- scheme!: String - 协议类型。
- hostName!: String - 不包含端口号的主机名。
- path!: String - 请求资源的路径。

异常：

- [UrlSyntaxException](url_package_exceptions.md#class-urlsyntaxexception) - 当构造实例不满足要求时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建URL实例
    let url = URL(scheme: "https", hostName: "example.com", path: "/path")

    println("URL created: ${url}")
}
```

运行结果：

```text
URL created: https://example.com/path
```

### static func decode(String)

```cangjie
public static func decode(url: String): String
```

功能：对经过 `URL` 编码（也就是 `%` 编码）的字符串进行解码操作，将编码后的字符串还原成原始的字符串。

> **注意：**
>
> 该函数解码所有被编码的字符，但部分字符是 URL 语法的一部分，所以以下字符将保留在输出字符串中：
>
> `#` `$` `&` `+` `,` `/` `:` `;` `=` `?` `@`

参数：

- url: String - 待解码的字符串。

返回值：

- String - 解码后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解码URL编码的字符串‘Hello & World! %’
    let encoded = "Hello%20%26%20World! %25"

    // 解码URL编码的字符串，部分字符是保留字符，如 '&'
    let decoded = URL.decode(encoded)

    println("URL decode: ${decoded}")
}
```

运行结果：

```text
URL decode: Hello %26 World! %
```

### static func decodeComponent(String)

```cangjie
public static func decodeComponent(component: String): String
```

功能：对经过 `URL` 编码（也就是 `%` 编码）的字符串进行解码操作，将编码后的字符串还原成原始的字符串。

参数：

- component: String - 待解码的字符串。

返回值：

- String - 解码后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    let encoded = "Hello%20%26%20World! %25"

    // 全部解码，无保留字符
    let decoded = URL.decodeComponent(encoded)

    println("URL decodeComponent: ${decoded}")
}
```

运行结果：

```text
URL decodeComponent: Hello & World! %
```

### static func encode(String)

```cangjie
public static func encode(url: String): String
```

功能：对普通字符串进行 `URL` 编码（也称为 `%` 编码）。`URL` 编码的目的是将字符串中的特殊字符、非 `ASCII` 字符等转换为符合 `URL` 规范的格式，以确保这些字符串能在 `URL` 中安全地传输和使用。

> **注意：**
>
> 该函数编码所有字符，但部分字符被 `URL` 语法所保留，所以以下字符将不会被编码：
>
> `0-9` `A-Z` `a-z`
>
> `!` `'` `-` `.` `*` `(` `)` `_` `~`
>
> `#` `$` `&` `+` `,` `/` `:` `;` `=` `?` `@`

参数：

- url: String - 待编码的字符串。

返回值：

- String - 编码后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 编码URL字符串
    let original = "Hello & World!"

    // 编码URL字符串，保留字符如 '&' 不会被编码
    let encoded = URL.encode(original)

    println("URL encode: ${encoded}")
}
```

运行结果：

```text
URL encode: Hello%20&%20World!
```

### static func encodeComponent(String)

```cangjie
public static func encodeComponent(component: String): String
```

功能：对普通字符串进行 `URL` 编码（也称为 `%` 编码）。`URL` 编码的目的是将字符串中的特殊字符、非 `ASCII` 字符等转换为符合 `URL` 规范的格式，以确保这些字符串能在 `URL` 中安全地传输和使用。

> **注意：**
>
> 该函数编码所有字符，包括 `URL` 语法的字符，但部分字符被 `URL` 语法所保留，所以以下字符将不会被编码：
>
> `0-9` `A-Z` `a-z`
>
> `!` `'` `-` `.` `*` `(` `)` `_` `~`

参数：

- component: String - 待编码的字符串。

返回值：

- String - 编码后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 编码URL字符串
    let original = "key & value!"

    // 编码URL字符串，保留字符如 '!' 不会被编码
    let encodeComponent = URL.encodeComponent(original)

    println("URL encodeComponent: ${encodeComponent}")
}
```

运行结果：

```text
URL encodeComponent: key%20%26%20value!
```

### static func mergePaths(String, String)

```cangjie
public static func mergePaths(basePath: String, refPath: String): String
```

功能：合并两个路径。

合并规则：将引用路径 refPath 追加到基础路径 basePath 的最后一段。如果 refPath 是绝对路径，结果就是 refPath 原本的值。如果 refPath 不是绝对路径，则将自身拼接至 basePath 最后一个 `/` 后，所有结果最终都会进行标准化（路径中的`.`字符，`..`字符，以及多个连续的 `/` 字符都会被优化）。具体行为可以参照下面示例。更详细行为参考 RFC 3986 协议。

如需合并 URL 请使用 [resolveURL](#func-resolveurlurl)。

例如：

- `/a/b/c` 合并 `/d` 输出 `/d`。
- `/a/b/c` 合并 `d` 输出 `/a/b/d`。
- `/a/b/` 合并 `d/e/../f` 输出 `/a/b/d/f`。
- `/a/b/c/` 合并 `./../../g` 输出 `/a/g`。

参数：

- basePath: String - 基础路径。
- refPath: String - 引用路径。

返回值：

- String - 合并且标准化后的路径。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 合并路径
    let basePath = "/a/b/c"
    let refPath = "d"
    let mergedPath = URL.mergePaths(basePath, refPath)

    println("URL mergePaths: ${mergedPath}")
}
```

运行结果：

```text
URL mergePaths: /a/b/d
```

### static func parse(String)

```cangjie
public static func parse(rawUrl: String): URL
```

功能：将原始 URL 字符串解析成 [URL](url_package_classes.md#class-url) 对象。

这个函数会将 [URL](url_package_classes.md#class-url) 按照组件分解，然后分别进行解码并存储在相应的组件属性中，而 rawXXX (此处泛指前缀是 raw 的 URL 属性)属性部分存储的是原始值，不做编解码处理。

使用示例请参见[URL 解析函数 parse 的使用](./../url_samples/url_parse.md)。

> **注意：**
>
> 该函数可以解析 URL 中的用户名和密码（如果存在），这是符合 RFC 3986 协议的解析功能的，但是 RFC 3986 也明确指出，任何场景下，明文保存用户信息存在被泄露风险，所以建议不要在 URL 中明文保存用户信息。

参数：

- rawUrl: String - [URL](url_package_classes.md#class-url) 字符串。

返回值：

- [URL](url_package_classes.md#class-url) - 解析字符串得到的 [URL](url_package_classes.md#class-url) 实例。

异常：

- [UrlSyntaxException](url_package_exceptions.md#class-urlsyntaxexception) - 当 [URL](url_package_classes.md#class-url) 字符串中包含非法字符时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 `UTF-8` 的字节序列规则时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL字符串
    let url = URL.parse("https://example.com:8080/path?query=value#fragment")

    println("URL parsed: ${url}")
}
```

运行结果：

```text
URL parsed: https://example.com:8080/path?query=value#fragment
```

### func isAbsoluteURL()

```cangjie
public func isAbsoluteURL(): Bool
```

功能：判断 [URL](url_package_classes.md#class-url) 是否为绝对 [URL](url_package_classes.md#class-url)（scheme 存在时，[URL](url_package_classes.md#class-url) 是绝对 [URL](url_package_classes.md#class-url)）。

返回值：

- Bool - scheme 存在时返回 true，不存在时返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL字符串
    let url = URL.parse("https://example.com:8080/path?query=value#fragment")
    let isAbsolute = url.isAbsoluteURL()
    println("isAbsolute isAbsoluteURL: ${isAbsolute}")

    let url1 = URL.parse("/path?query=value#fragment")
    let notAbsolute = url1.isAbsoluteURL()
    println("notAbsolute isAbsoluteURL: ${notAbsolute}")
}
```

运行结果：

```text
isAbsolute isAbsoluteURL: true
notAbsolute isAbsoluteURL: false
```

### func replace(Option\<String>, Option\<String>, Option\<String>, Option\<String>, Option\<String>, Option\<String>, Option\<String>)

```cangjie
public func replace(scheme!: Option<String> = None, userInfo!: Option<String> = None,
 hostName!: Option<String> = None, port!: Option<String> = None, path!: Option<String> = None, 
 query!: Option<String> = None, fragment!: Option<String> = None): URL
```

功能：替换 [URL](url_package_classes.md#class-url) 对象的各组件，并且返回一个新的 [URL](url_package_classes.md#class-url) 对象。

替换时需要满足以下要求：

- 方案 scheme 为空时，主机名必须为空。
- 主机名为空时，用户信息或端口号必须为空。
- 方案 scheme 不为空时，主机名和路径不能同时为空。
- 方案 scheme 不为空时，路径必须是绝对路径。
- 任意组件均为合法字符。

参数：

- scheme!: Option\<String> - 协议组件。
- userInfo!: Option\<String> - 用户信息。
- hostName!: Option\<String> - 主机名。
- port!: Option\<String> - 端口号。
- path!: Option\<String> - 资源路径。
- query!: Option\<String> - 查询组件。
- fragment!: Option\<String> - 锚点组件。

返回值：

- [URL](url_package_classes.md#class-url) - 新的 [URL](url_package_classes.md#class-url) 对象。

异常：

- [UrlSyntaxException](url_package_exceptions.md#class-urlsyntaxexception) - 不满足替换要求时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL字符串
    let url = URL.parse("https://example.com:8080/path?query=value#fragment")

    // 替换URL组件
    let newUrl = url.replace(path: Some("/newpath"))

    println("URL replace: ${newUrl}")
}
```

运行结果：

```text
URL replace: https://example.com:8080/newpath?query=value#fragment
```

### func resolveURL(URL)

```cangjie
public func resolveURL(ref: URL): URL
```

功能：以当前 [URL](url_package_classes.md#class-url) 实例为基础 [URL](url_package_classes.md#class-url)，以传入的 [URL](url_package_classes.md#class-url) 为参考 [URL](url_package_classes.md#class-url)，根据 RFC 3986 协议生成一个新的 [URL](url_package_classes.md#class-url) 实例。

例如：<http://a/b/c/d;p?q> 为基础 [URL](url_package_classes.md#class-url)，以下 = 左边为参考 [URL](url_package_classes.md#class-url)，右边为生成的新 [URL](url_package_classes.md#class-url)：

- "g"      =  "<http://a/b/c/g>"
- "/g"     =  "<http://a/g>"
- "g?y"    =  "<http://a/b/c/g?y>"
- "g?y#s"  =  "<http://a/b/c/g?y#s>"
- "../"    =  "<http://a/b/>"

更多详细的 URL 生成规则，请参见 RFC 3968 协议。

参数：

- ref: [URL](url_package_classes.md#class-url) - 参考 [URL](url_package_classes.md#class-url) 对象。

返回值：

- [URL](url_package_classes.md#class-url) - 新的 [URL](url_package_classes.md#class-url) 实例。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析基础URL
    let baseUrl = URL.parse("http://a/b/c/d;p?q")
    // 解析参考URL
    let refUrl = URL.parse("g")

    // 解析URL
    let resolvedUrl = baseUrl.resolveURL(refUrl)

    println("URL resolveURL: ${resolvedUrl}")
}
```

运行结果：

```text
URL resolveURL: http://a/b/c/g
```

### func toString()

```cangjie
public func toString(): String
```

功能：获取当前 [URL](url_package_classes.md#class-url) 实例的字符串值。

会把 hostName 编码，其余部分取 rawXXX (此处泛指前缀是 raw 的 URL 属性)属性值，按照 URL 组件构成顺序进行拼接而获得该函数返回值。

返回值：

- String - 当前 [URL](url_package_classes.md#class-url) 实例的字符串值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 解析URL字符串
    let url = URL.parse("https://example.com:8080/path?query=value#fragment")

    // 获取URL字符串表示
    let urlString = url.toString()

    println("URL toString: ${urlString}")
}
```

运行结果：

```text
URL toString: https://example.com:8080/path?query=value#fragment
```

## class UserInfo

```cangjie
public class UserInfo <: ToString {
    public init()
    public init(userName: String)
    public init(userName: String, passWord: String)
    public init(userName: String, passWord: Option<String>)
}
```

功能：[UserInfo](url_package_classes.md#class-userinfo) 表示 URL 中用户名和密码信息。

> **注意：**
>
> RFC 3986 明确指出，任何场景下，明文保存用户信息存在被泄露风险，所以建议不要在 URL 中明文保存用户信息。

父类型：

- ToString

### init()

```cangjie
public init()
```

功能：创建 [UserInfo](url_package_classes.md#class-userinfo) 实例。

示例：

<!-- run -->
```cangjie
import stdx.encoding.url.*

main() {
    // 使用无参构造函数创建UserInfo实例 
    let userInfo = UserInfo()
}
```

### init(String)

```cangjie
public init(userName: String)
```

功能：根据用户名创建 [UserInfo](url_package_classes.md#class-userinfo) 实例。

参数：

- userName: String - 用户名。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 使用用户名参数创建UserInfo实例 
    let userInfo = UserInfo("Zhangsan")

    println("UserInfo: ${userInfo}")
}
```

运行结果：

```text
UserInfo: Zhangsan
```

### init(String, Option\<String>)

```cangjie
public init(userName: String, passWord: Option<String>)
```

功能：根据用户名和密码创建 [UserInfo](url_package_classes.md#class-userinfo) 实例。
参数：

- userName: String - 用户名。
- passWord: Option\<String> - 密码，用 Option\<String> 类型表示。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 使用用户名和密码创建UserInfo实例 
    let userInfo = UserInfo("admin", Some("password123"))

    println("UserInfo带用户名和密码: ${userInfo}")
}
```

运行结果：

```text
UserInfo带用户名和密码: admin:password123
```

### init(String, String)

```cangjie
public init(userName: String, passWord: String)
```

功能：根据用户名和密码创建 [UserInfo](url_package_classes.md#class-userinfo) 实例。
参数：

- userName: String - 用户名。
- passWord: String - 密码。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 使用用户名和密码创建UserInfo实例 
    let userInfo = UserInfo("admin", "password123")

    println("UserInfo带用户名和密码: ${userInfo}")
}
```

运行结果：

```text
UserInfo带用户名和密码: admin:password123
```

### func password()

```cangjie
public func password(): Option<String>
```

功能：获取密码信息。

> **注意：**
>
> RFC 3986 明确指出，任何场景下，明文保存用户信息存在被泄露风险，所以建议不要在 URL 中明文保存用户信息。

返回值：

- Option\<String> - 将密码以 Option\<String> 形式返回。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建UserInfo实例 
    let userInfo = UserInfo("admin", "password123")

    // 获取密码信息 
    let passwordOption = userInfo.password()

    println("UserInfo password: ${passwordOption}")
}
```

运行结果：

```text
UserInfo password: Some(password123)
```

### func toString()

```cangjie
public func toString(): String
```

功能：将当前 [UserInfo](url_package_classes.md#class-userinfo) 实例转换为字符串。

返回值：

- String - 当前 [UserInfo](url_package_classes.md#class-userinfo) 实例的字符串表示。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建UserInfo实例 
    let userInfo = UserInfo("admin", "password123")

    // 获取字符串表示 
    let userInfoString = userInfo.toString()

    println("UserInfo toString方法示例: ${userInfoString}")
}
```

运行结果：

```text
UserInfo toString方法示例: admin:password123
```

### func username()

```cangjie
public func username(): String
```

功能：获取用户名信息。

返回值：

- String - 字符串类型的用户名。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main() {
    // 创建UserInfo实例 
    let userInfo = UserInfo("admin", "password123")

    // 获取用户名信息 
    let username = userInfo.username()

    println("UserInfo username: ${username}")
}
```

运行结果：

```text
UserInfo username: admin
```
