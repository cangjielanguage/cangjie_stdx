# URL 解析函数 parse 的使用

使用 parse 函数解析 URL 字符串，生成 URL 对象。示例中对一个地址进行了解析并获得了 URL 对象，并且打印该对象的各个属性。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main(): Int64 {
    // 调用 URL.parse 解析 URL 字符串
    let urlString = "http://www.example.com:80/path%E4%BB%93%E9%A2%89?key=value%E4%BB%93%E9%A2%89#%E4%BD%A0%E5%A5%BD"
    let url = URL.parse(urlString)

    // 打印 URL 的各个组件（已解码）
    println("协议 (scheme): ${url.scheme}")
    println("主机 (host): ${url.host}")
    println("主机名 (hostName): ${url.hostName}")
    println("端口 (port): ${url.port}")
    println("路径 (path): ${url.path}")
    println("查询参数 (query): ${url.query.getOrThrow()}")
    println("片段 (fragment): ${url.fragment.getOrThrow()}")

    // 打印原始（未解码）的组件
    println("\n原始路径 (rawPath): ${url.rawPath}")
    println("原始查询参数 (rawQuery): ${url.rawQuery.getOrThrow()}")
    println("原始片段 (rawFragment): ${url.rawFragment.getOrThrow()}")

    // 打印完整的 URL
    println("\n完整 URL: ${url}")

    return 0
}
```

运行结果：

```text
协议 (scheme): http
主机 (host): www.example.com:80
主机名 (hostName): www.example.com
端口 (port): 80
路径 (path): /path仓颉
查询参数 (query): key=value仓颉
片段 (fragment): 你好

原始路径 (rawPath): /path%E4%BB%93%E9%A2%89
原始查询参数 (rawQuery): key=value%E4%BB%93%E9%A2%89
原始片段 (rawFragment): %E4%BD%A0%E5%A5%BD

完整 URL: http://www.example.com:80/path%E4%BB%93%E9%A2%89?key=value%E4%BB%93%E9%A2%89#%E4%BD%A0%E5%A5%BD
```
