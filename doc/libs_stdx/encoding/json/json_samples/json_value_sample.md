# JsonValue 和 String 互相转换

下面是 JsonValue 和 String 互相转换的示例。该示例使用 JsonValue.fromStr 将一个 JSON 字符串转换为 JsonValue，随后以两种格式打印了该 JsonValue 对象。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    // 准备 JSON 字符串
    let jsonString = ##"[true,"kjjjke\"eed",{"sdfd":"ggggg","eeeee":[341,false,{"nnnn":55.87}]},3422,22.341,false,[22,22.22,true,"ddd"],43]"##

    // 将 JSON 字符串解析为 JsonValue 对象
    let jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    // 转换为紧凑格式的 JSON 字符串
    let compactString = jsonValue.toString()
    println("紧凑格式:")
    println(compactString)

    // 转换为格式化的 JSON 字符串（带缩进）
    let prettyString = jsonValue.toJsonString()
    println("\n格式化输出:")
    println(prettyString)
}
```

运行结果：

```text
紧凑格式:
[true,"kjjjke\"eed",{"sdfd":"ggggg","eeeee":[341,false,{"nnnn":55.87}]},3422,22.341,false,[22,22.22,true,"ddd"],43]

格式化输出:
[
  true,
  "kjjjke\"eed",
  {
    "sdfd": "ggggg",
    "eeeee": [
      341,
      false,
      {
        "nnnn": 55.87
      }
    ]
  },
  3422,
  22.341,
  false,
  [
    22,
    22.22,
    true,
    "ddd"
  ],
  43
]
```
