# AOP Development Example

The following is an example code demonstrating function entry point instrumentation using `@InsertAtEntry`:

<!-- compile -->

```cangjie
package AOP_demo1

import stdx.aspectCJ.*
import std.time.DateTime

@InsertAtEntry[packageName: "AOP_demo1", className: "", methodName: "printCurrentTime", isStatic: false, funcTypeStr: "()->Unit", recursive: false]
public func printCurrentTimeImpl() {
    println("----- ${DateTime.now()} -----")
}

public func printCurrentTime() {
    println("hi")
    println("bye")
}

main() {
    printCurrentTime()
    0
}
```

Linux platform compilation commands:

```shell
cjc aop_demo1.cj --plugin=libcollect-aspects.so -o main	// First compilation: aspect collection
cjc aop_demo1.cj --plugin=libwave-aspects.so -o main	// Second compilation: aspect weaving
```

Possible execution output:

```text
----- 2025-06-03T00:00:18.994507-07:00 -----
hi
bye
```

The following is an example code demonstrating function exit point instrumentation using `@InsertAtExit`:

<!-- compile -->

```cangjie
package AOP_demo2

import stdx.aspectCJ.*
import std.time.DateTime

@InsertAtExit[packageName: "AOP_demo1", className: "", methodName: "printCurrentTime", isStatic: false, funcTypeStr: "()->std.core:String", recursive: false]
public func printCurrentTimeImpl() {
    println("----- ${DateTime.now()} -----")
}

public func printCurrentTime() {
    println("hi")
    println("bye")
    "done"
}

main() {
    println(printCurrentTime())
    0
}
```

Linux platform compilation commands:

```shell
cjc aop_demo2.cj --plugin=libcollect-aspects.so -o main	// First compilation: aspect collection
cjc aop_demo2.cj --plugin=libwave-aspects.so -o main	// Second compilation: aspect weaving
```

Possible execution output:

```text
hi
bye
----- 2025-06-03T00:04:59.996469-07:00 -----
done
```

The following is an example code demonstrating function body replacement using `@ReplaceFuncBody`:

<!-- compile -->

```cangjie
package AOP_demo2

import stdx.aspectCJ.*
import std.time.DateTime

@ReplaceFuncBody[packageName: "AOP_demo1", className: "", methodName: "printCurrentTime", isStatic: false, recursive: false]
public func printCurrentTimeImpl(original: (String)->String) {
    println("----- ${DateTime.now()} -----")
    println(original("abc"))
    println("----- end -----")
    "def"
}

public func printCurrentTime(x: String): String {
    println(x)
    "456"
}

main() {
    println(printCurrentTime("123"))
    0
}
```

Linux platform compilation commands:

```shell
cjc aop_demo2.cj --plugin=libcollect-aspects.so -o main	// First compilation: aspect collection
cjc aop_demo2.cj --plugin=libwave-aspects.so -o main	// Second compilation: aspect weaving
```

Possible execution output:

```text
----- 2025-06-03T00:04:59.996469-07:00 -----
abc
456
----- end -----
def
```