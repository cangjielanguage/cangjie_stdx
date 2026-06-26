# 类

## class CustomAnnoInstance

```cangjie
public class CustomAnnoInstance <: ToString {
    public init(classSrcCodeName: String)
    public init(classSrcCodeName: String, loc: DebugLocation)
}
```

功能：表示 CHIR 中**一处**注解实例，对应源码形态 `@ClassName[v1, v2, ...]`：保存注解类名及参数值列表。

父类型：

- ToString

### prop argValues

```cangjie
public mut prop argValues: Array<String>
```

功能：获取或设置注解参数值列表。getter 返回当前所有参数值；setter 替换整个列表。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("MyAnno")
    println(a.argValues.size)
}
```

运行结果：

```text
0
```

### prop classSrcCodeName

```cangjie
public prop classSrcCodeName: String
```

功能：注解类在源码中的名称。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("MyAnno")
    println(a.classSrcCodeName)
}
```

运行结果：

```text
MyAnno
```

### prop location

```cangjie
public prop location: DebugLocation
```

功能：注解在源码中出现的位置。

类型：[DebugLocation](#class-debuglocation)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("MyAnno")
    println(a.location.isValid())
}
```

运行结果：

```text
false
```

### init(String)

```cangjie
public init(classSrcCodeName: String)
```

功能：构造一个 `CustomAnnoInstance` 对象，指定注解类名且**参数值列表初始为空**、位置为无效位置。

参数：

- classSrcCodeName: String - 源码中的注解类名（如 `MyAnno`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("Fresh")
    println(a.toString())
}
```

运行结果：

```text
@Fresh[]
```

### init(String, DebugLocation)

```cangjie
public init(classSrcCodeName: String, loc: DebugLocation)
```

功能：构造一个 `CustomAnnoInstance` 对象，指定注解类名和源码位置。

参数：

- classSrcCodeName: String - 源码中的注解类名（如 `MyAnno`）。
- loc: [DebugLocation](#class-debuglocation) - 注解在源码中出现的位置。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    let a = CustomAnnoInstance("Fresh", mv.location)
    println(a.toString())
}
```

运行结果：

```text
@Fresh[]
```

### func toString()

```cangjie
public func toString(): String
```

功能：格式化为 `@ClassName[v1, v2, ...]`，便于日志与调试。

返回值：

- String - 注解的文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("T")
    println(a.toString())
}
```

运行结果：

```text
@T[]
```

## class BoolType

```cangjie
public class BoolType <: BuiltinType & Equatable<BoolType> {}
```

功能：表示类型系统中的布尔类型。这是一个单例类型，表示 Bool 类型。

父类型：

- [BuiltinType](#class-builtintype)
- Equatable\<[BoolType](#class-booltype)>

### static func get()

```cangjie
public static func get(): BoolType
```

功能：获取 BoolType 的单例实例。

返回值：

- [BoolType](#class-booltype) - BoolType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let boolType = BoolType.get()
    println("布尔类型: ${boolType.toString()}")
}
```

运行结果：

```text
布尔类型: Bool
```

### operator func ==(BoolType)

```cangjie
public operator func ==(_: BoolType): Bool
```

功能：检查该 BoolType 是否与另一个 BoolType 相等。

参数：

- _: BoolType - 要比较的另一个 BoolType（未使用，始终返回 true）。

返回值：

- Bool - 始终返回 true，因为所有 BoolType 实例都相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let boolType1 = BoolType.get()
    let boolType2 = BoolType.get()
    println("两个 BoolType 相等: ${boolType1 == boolType2}")
}
```

运行结果：

```text
两个 BoolType 相等: true
```

## class BoxType

```cangjie
public class BoxType <: Type & Equatable<BoxType> {}
```

功能：表示**装箱类型** `Box<T>`，对值进行装箱包装。通过缓存保证同一 `baseType` 对应唯一实例。

父类型：

- [Type](#class-type)
- Equatable\<[BoxType](#class-boxtype)>

### prop baseType

```cangjie
public prop baseType: Type
```

功能：被装箱的基类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let b = BoxType.get(IntType.getInt32())
    println(b.baseType.toString())
}
```

运行结果：

```text
Int32
```

### static func get(Type)

```cangjie
public static func get(baseType: Type): BoxType
```

功能：获取或创建指定基类型的 `BoxType`。

返回值：

- [BoxType](#class-boxtype) - 给定基类型的 BoxType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let b = BoxType.get(IntType.getInt32())
    println(b.toString())
}
```

运行结果：

```text
Box<Int32>
```

### func toString()

```cangjie
public func toString(): String
```

功能：字符串形式，一般为 `Box<...>` 风格。

返回值：

- String - 装箱类型的字符串表示。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let b = BoxType.get(IntType.getUInt32())
    println(b.toString())
}
```

运行结果：

```text
Box<UInt32>
```

### operator func ==(BoxType)

```cangjie
public operator func ==(other: BoxType): Bool
```

功能：比较两个 `BoxType` 是否相同。

返回值：

- Bool - 相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let base = IntType.getInt32()
    let b1 = BoxType.get(base)
    let b2 = BoxType.get(base)
    println("op_eq_BoxType: ${b1 == b2}")
}
```

运行结果：

```text
op_eq_BoxType: true
```

## class BuiltinType

```cangjie
sealed abstract class BuiltinType <: Type & Equatable<BuiltinType> {}
```

功能：内置类型（数值、Bool、Unit、指针、数组等）的公共基类；可附加 `ExtendDef`（`addExtend`），并通过 `getSuperTypesRecusively` 收集由 extend 实现的接口父类型。

父类型：

- [Type](#class-type)
- Equatable\<[BuiltinType](#class-builtintype)>

### func addExtend(ExtendDef)

```cangjie
public func addExtend(extendDef: ExtendDef): Unit
```

功能：为当前内置类型登记一条 [ExtendDef](#class-extenddef)（与源码中对该内置类型的 `extend` 块对应）。

参数：

- extendDef: ExtendDef - 扩展定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let ext = pkg.addExtend("ext_mangled", IntType.getInt32())
    IntType.getInt32().addExtend(ext)
    println("extend id: ${ext.identifier}")
}
```

运行结果：

```text
extend id: @ext_mangled
```

（具体 `identifier` 前缀与 mangling 规则以源码为准。）

### func getSuperTypesRecusively(ArrayList\<(Type, Type)>)

```cangjie
public func getSuperTypesRecusively(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType>
```

功能：从本类型上通过 `extend` 所实现的接口出发，递归收集父接口/父类侧的 [ClassLikeType](#class-classliketype)（用于语义与继承分析）。

参数：

- visited! - 环检测用访问表；一般可传默认空表。

返回值：

- Array\<[ClassLikeType](#class-classliketype)> - 收集到的类型序列。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = IntType.getInt32()
    println("${t.getSuperTypesRecusively().size}")
}
```

运行结果：

```text
0
```

### operator func ==(BuiltinType)

```cangjie
public operator func ==(other: BuiltinType): Bool
```

功能：比较两个内置类型是否表示同一类及相同类型实参。

参数：

- other: BuiltinType - 另一内置类型。

返回值：

- Bool - 相等则为 `true`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = IntType.getInt32()
    let b = IntType.getInt32()
    let c = IntType.getInt64()
    println("op_eq_BuiltinType sameInt32: ${a == b}")
    println("op_eq_BuiltinType int32vsInt64: ${a == c}")
}
```

运行结果：

```text
op_eq_BuiltinType sameInt32: true
op_eq_BuiltinType int32vsInt64: false
```

## class CPointerType

```cangjie
public class CPointerType <: BuiltinType & Equatable<CPointerType> {}
```

功能：表示类型系统中的 C 指针类型。该类型表示指向 C 类型的指针，用于与 C 代码互操作。该类维护所有 C 指针类型的缓存以确保唯一性。

父类型：

- [BuiltinType](#class-builtintype)
- Equatable\<[CPointerType](#class-cpointertype)>

### prop elementType

```cangjie
public prop elementType: Type
```

功能：获取该 C 指针类型所指向的元素类型。

返回值：

- [Type](#class-type) - 元素类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let cp = CPointerType.get(intType)
    println(cp.elementType.toString())
}
```

运行结果：

```text
Int32
```

### static func get(Type)

```cangjie
public static func get(elementType: Type): CPointerType
```

功能：获取或创建给定元素类型的 CPointerType。

此方法确保每个元素类型只存在一个 CPointerType 实例。

参数：

- elementType: Type - 指针所指向的类型。

返回值：

- [CPointerType](#class-cpointertype) - 给定元素类型的 CPointerType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let cPointerType = CPointerType.get(intType)
    println(cPointerType.toString())
}
```

运行结果：

```text
CPointer<Int32>
```

### func toString()

```cangjie
public func toString(): String
```

功能：将该 CPointerType 转换为字符串表示。

返回值：

- String - C 指针类型的字符串表示（CPointer\<elementType>）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let cPointerType = CPointerType.get(IntType.getUInt32())
    println(cPointerType.toString())
}
```

运行结果：

```text
CPointer<UInt32>
```

### operator func ==(CPointerType)

```cangjie
public operator func ==(other: CPointerType): Bool
```

功能：检查该 CPointerType 是否与另一个 CPointerType 相等。

参数：

- other: CPointerType - 要比较的 CPointerType。

返回值：

- Bool - 如果类型相等则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let cPointerType1 = CPointerType.get(intType)
    let cPointerType2 = CPointerType.get(intType)
    println("op_eq_CPointerType: ${cPointerType1 == cPointerType2}")
}
```

运行结果：

```text
op_eq_CPointerType: true
```

## class CStringType

```cangjie
public class CStringType <: BuiltinType & Equatable<CStringType> {}
```

功能：表示类型系统中的 C 字符串类型。该类型表示 C 风格的空终止字符串，用于与 C 代码互操作。这是一个单例类型，表示内置的 C 字符串类型。

父类型：

- [BuiltinType](#class-builtintype)
- Equatable\<[CStringType](#class-cstringtype)>

### static func get()

```cangjie
public static func get(): CStringType
```

功能：获取 CStringType 的单例实例。

返回值：

- [CStringType](#class-cstringtype) - CStringType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let cStringType = CStringType.get()
    println(cStringType.toString())
}
```

运行结果：

```text
CString
```

### operator func ==(CStringType)

```cangjie
public operator func ==(_: CStringType): Bool
```

功能：检查该 CStringType 是否与另一个 CStringType 相等。

参数：

- _: CStringType - 要比较的另一个 CStringType（未使用，始终返回 true）。

返回值：

- Bool - 始终返回 true，因为所有 CStringType 实例都相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let cStringType1 = CStringType.get()
    let cStringType2 = CStringType.get()
    println("op_eq_CStringType: ${cStringType1 == cStringType2}")
}
```

运行结果：

```text
op_eq_CStringType: true
```

## class ClassLikeDef

```cangjie
public class ClassLikeDef <: CustomTypeDef & Equatable<ClassLikeDef> {}
```

功能：**类或接口**的定义。

父类型：

- [CustomTypeDef](#class-customtypedef)
- Equatable\<[ClassLikeDef](#class-classlikedef)>

### prop classType

```cangjie
public prop classType: ClassLikeType
```

功能：与此定义对应的 [ClassLikeType](#class-classliketype)。

类型：[ClassLikeType](#class-classliketype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    println("prop_classType: ${def.classType.classLikeDef == def}")
}
```

运行结果：

```text
prop_classType: true
```

### prop isAnnotation

```cangjie
public prop isAnnotation: Bool
```

功能：是否为注解类。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    println(def.isAnnotation)
}
```

运行结果：

```text
false
```

### prop superClass

```cangjie
public mut prop superClass: ?ClassLikeType
```

功能：父类；无父类时为 `None`。

类型：?[ClassLikeType](#class-classliketype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    println("mut_prop_superClass: ${def.superClass.isNone()}")
}
```

运行结果：

```text
mut_prop_superClass: true
```

### func setAbstract(Bool)

```cangjie
public func setAbstract(enable: Bool): Unit
```

功能：设置或清除 `abstract` 标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    def.setAbstract(true)
    println("fn_setAbstract: ${def.isAbstract()}")
}
```

运行结果：

```text
fn_setAbstract: true
```

### func setOpen(Bool)

```cangjie
public func setOpen(enable: Bool): Unit
```

功能：设置或清除 `open`（可继承/虚）相关标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    def.setOpen(true)
    println("fn_setOpen: ${def.isOpen()}")
}
```

运行结果：

```text
fn_setOpen: true
```

### func setSealed(Bool)

```cangjie
public func setSealed(enable: Bool): Unit
```

功能：设置或清除 `sealed` 标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    def.setSealed(true)
    println("fn_setSealed: ${def.isSealed()}")
}
```

运行结果：

```text
fn_setSealed: true
```

### operator func ==(ClassLikeDef)

```cangjie
public operator func ==(other: ClassLikeDef): Bool
```

功能：比较是否同一类/接口定义。

参数：

- other: ClassLikeDef - 另一定义。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    println("op_eq_ClassLikeDef: ${def == def}")
}
```

运行结果：

```text
op_eq_ClassLikeDef: true
```

## class ClassLikeType

```cangjie
public class ClassLikeType <: CustomType & Equatable<ClassLikeType> {}
```

功能：类或接口的**实例化类型**。`get(def, genericTypeParams)` 缓存唯一实例。

父类型：

- [CustomType](#class-customtype)
- Equatable\<[ClassLikeType](#class-classliketype)>

### prop classLikeDef

```cangjie
public prop classLikeDef: ClassLikeDef
```

功能：对应的 [ClassLikeDef](#class-classlikedef)。

类型：[ClassLikeDef](#class-classlikedef)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("C_m", "C", true)
    let ty = ClassLikeType.get(d, [])
    println(ty.classLikeDef.srcCodeName)
}
```

运行结果：

```text
C
```

### static func get(ClassLikeDef, Array\<Type>)

```cangjie
public static func get(def: ClassLikeDef, genericTypeParams: Array<Type>): ClassLikeType
```

功能：按定义与泛型实参取得或创建缓存中的唯一实例。

参数：

- def: ClassLikeDef - 类/接口定义。
- genericTypeParams: Array\<Type> - 泛型实参（非泛型时为空数组）。

返回值：

- [ClassLikeType](#class-classliketype) - 实例化类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("C_m", "C", true)
    let ty = ClassLikeType.get(d, [])
    println("static_get: ${ty.classLikeDef.identifier.size > 0}")
}
```

运行结果：

```text
static_get: true
```

### operator func ==(ClassLikeType)

```cangjie
public operator func ==(other: ClassLikeType): Bool
```

功能：比较是否为同一实例化类/接口类型。

参数：

- other: ClassLikeType - 另一类型。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("C_m", "C", true)
    let ty1 = ClassLikeType.get(d, [])
    let ty2 = ClassLikeType.get(d, [])
    println("op_eq_ClassLikeType: ${ty1 == ty2}")
}
```

运行结果：

```text
op_eq_ClassLikeType: true
```

## class CustomType

```cangjie
sealed abstract class CustomType <: Type & Equatable<CustomType> {}
```

功能：用户自定义类型（类/接口/结构体/枚举）实例化类型的公共基类，持有 `CustomTypeDef` 与泛型实参。

父类型：

- [Type](#class-type)
- Equatable\<[CustomType](#class-customtype)>

子类包括 [ClassLikeType](#class-classliketype)、[StructType](#class-structtype)、[EnumType](#class-enumtype) 等。

### prop allMemberVarNames

```cangjie
public prop allMemberVarNames: Array<String>
```

功能：自超类链线性化后直至本类型声明的全部实例成员名。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    d.appendInstanceMemberVar("x", IntType.getInt32())
    let st = StructType.get(d, [])
    println("${st.allMemberVarNames.size}")
}
```

运行结果：

```text
1
```

### prop def

```cangjie
public prop def: CustomTypeDef
```

功能：对应的类型定义节点。

类型：[CustomTypeDef](#class-customtypedef)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    let st = StructType.get(d, [])
    println(st.def.srcCodeName)
}
```

运行结果：

```text
S
```

### prop genericTypeArgs

```cangjie
public prop genericTypeArgs: Array<Type>
```

功能：泛型实参列表（非泛型时为空）。

类型：Array\<Type>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    let st = StructType.get(d, [])
    println("${st.genericTypeArgs.size}")
}
```

运行结果：

```text
0
```

### func getExtendDefs(ArrayList\<(Type, Type)>)

```cangjie
public func getExtendDefs(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ExtendDef>
```

功能：返回 `def.extends` 中 `extendedType` 与当前类型可匹配的 extend 定义。

返回值：

- Array\<[ExtendDef](#class-extenddef)> - 适用的 ExtendDef 节点。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    let st = StructType.get(d, [])
    println("${st.getExtendDefs().size}")
}
```

运行结果：

```text
0
```

### func getExtendImplementedInterfaceTypes(ArrayList\<(Type, Type)>)

```cangjie
public func getExtendImplementedInterfaceTypes(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType>
```

功能：收集适用于当前实例的 `extend` 块所实现的接口（已代入泛型）。

返回值：

- Array\<[ClassLikeType](#class-classliketype)> - 实例化后的接口 ClassLikeType 节点。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    let st = StructType.get(d, [])
    println("${st.getExtendImplementedInterfaceTypes().size}")
}
```

运行结果：

```text
0
```

### func getImplementedInterfaceTypes(ArrayList\<(Type, Type)>)

```cangjie
public func getImplementedInterfaceTypes(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType>
```

功能：`extend` 实现的接口与定义上 `implementedInterfaceTypes` 的并集（已实例化）。

返回值：

- Array\<[ClassLikeType](#class-classliketype)> - 合并后的实例化接口类型列表。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    let st = StructType.get(d, [])
    println("${st.getImplementedInterfaceTypes().size}")
}
```

运行结果：

```text
0
```

### func getInstantiatedMemberVarTypes()

```cangjie
public func getInstantiatedMemberVarTypes(): Array<Type>
```

功能：与 `allMemberVarNames` 对齐的成员类型，已按当前泛型实参替换。

返回值：

- Array\<[Type](#class-type)> - 成员实例化类型序列。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    d.appendInstanceMemberVar("x", IntType.getInt32())
    let st = StructType.get(d, [])
    println("${st.getInstantiatedMemberVarTypes().size}")
}
```

运行结果：

```text
1
```

### func getMemberVarInstantiatedType(String)

```cangjie
public func getMemberVarInstantiatedType(name: String): Type
```

功能：按成员名查找实例化后的成员类型（自内向外遮蔽）。

参数：

- name: String - 成员源码名。

返回值：

- [Type](#class-type) - 成员类型。

异常：

- Exception - 未找到该成员名时抛出。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    d.appendInstanceMemberVar("x", IntType.getInt32())
    let st = StructType.get(d, [])
    println(st.getMemberVarInstantiatedType("x").toString())
}
```

运行结果：

```text
Int32
```

### func getSuperTypesRecusively(ArrayList\<(Type, Type)>)

```cangjie
public func getSuperTypesRecusively(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType>
```

功能：递归收集父类与接口父类型（已实例化）。

返回值：

- Array\<[ClassLikeType](#class-classliketype)> - 父类与接口父类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    let st = StructType.get(d, [])
    println("${st.getSuperTypesRecusively().size}")
}
```

运行结果：

```text
0
```

### func toString()

```cangjie
public func toString(): String
```

功能：内部 kind、标识与泛型实参的紧凑字符串。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    let st = StructType.get(d, [])
    println("fn_toString: ${st.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### operator func ==(CustomType)

```cangjie
public operator func ==(other: CustomType): Bool
```

功能：比较种类、定义与泛型实参是否一致。

参数：

- other: CustomType - 另一自定义实例化类型。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    let st = StructType.get(d, [])
    println("op_eq_CustomType: ${st == StructType.get(d, [])}")
}
```

运行结果：

```text
op_eq_CustomType: true
```

## class CustomTypeDef

```cangjie
sealed abstract class CustomTypeDef <: Equatable<CustomTypeDef> & Hashable {}
```

功能：类/接口/结构体/枚举/扩展的**定义**公共基类（与 `Base` 组合，含属性、CHIR 注解、调试位置等）。

父类型：

- Equatable\<[CustomTypeDef](#class-customtypedef)>
- Hashable

### prop identifier

```cangjie
public prop identifier: String
```

功能：内部标识，全局唯一标识符。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("prop_identifier: ${d.identifier.size > 0}")
}
```

运行结果：

```text
prop_identifier: true
```

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

功能：源码中的类型名（extend 等场景可能为空串，见源码注释）。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.srcCodeName)
}
```

运行结果：

```text
X
```

### prop packageName

```cangjie
public prop packageName: String
```

功能：所属包名。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.packageName)
}
```

运行结果：

```text
p
```

### prop ty

```cangjie
public prop ty: Type
```

功能：对普通定义为实例化类型；对 [ExtendDef](#class-extenddef) 为 `extendedType`。

类型：[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("prop_ty: ${d.ty.toString().size > 0}")
}
```

运行结果：

```text
prop_ty: true
```

### prop genericTypeParams

```cangjie
public prop genericTypeParams: Array<GenericType>
```

功能：泛型形参列表；非泛型或无法从类型实参反推时为空数组。

类型：Array\<[GenericType](#class-generictype)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.genericTypeParams.size}")
}
```

运行结果：

```text
0
```

### prop genericDecl

```cangjie
public mut prop genericDecl: ?CustomTypeDef
```

功能：与当前**单态**定义配对的泛型模板定义；`set` 时校验种类、`srcCodeName` 及泛型约束（见源码断言）。

类型：?CustomTypeDef

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("mut_prop_genericDecl: ${d.genericDecl.isNone()}")
}
```

运行结果：

```text
mut_prop_genericDecl: true
```

### prop instanceVars

```cangjie
public prop instanceVars: Array<MemberVar>
```

功能：实例成员变量列表（声明顺序）。

类型：Array\<[MemberVar](#class-membervar)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.instanceVars.size}")
}
```

运行结果：

```text
0
```

### prop extends

```cangjie
public mut prop extends: Array<ExtendDef>
```

功能：嵌套于该类型下的 `extend` 定义集合。

类型：Array\<[ExtendDef](#class-extenddef)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.extends.size}")
}
```

运行结果：

```text
0
```

### prop implementedInterfaceTypes

```cangjie
public mut prop implementedInterfaceTypes: Array<ClassLikeType>
```

功能：直接实现的接口类型列表。

类型：Array\<[ClassLikeType](#class-classliketype)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.implementedInterfaceTypes.size}")
}
```

运行结果：

```text
0
```

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

功能：注解实例列表；getter 返回当前所有实例，setter 整体替换。

类型：Array\<[CustomAnnoInstance](#class-customannoinstance)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let c = pkg.addClass("C_m", "C", true)
    println("${c.customAnnoInstances.size}")
}
```

运行结果：

```text
0
```

### prop methods

```cangjie
public prop methods: Array<Function>
```

功能：此自定义类型上声明的方法列表。

类型：Array\<[Function](#class-function)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let c = pkg.addClass("C_m", "C", true)
    println("${c.methods.size}")
}
```

运行结果：

```text
0
```

### prop staticVars

```cangjie
public prop staticVars: Array<GlobalVar>
```

功能：此自定义类型上声明的静态变量列表。

类型：Array\<[GlobalVar](#class-globalvar)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let c = pkg.addClass("C_m", "C", true)
    println("${c.staticVars.size}")
}
```

运行结果：

```text
0
```

### func appendMethod(Function)

```cangjie
public func appendMethod(method: Function): Unit
```

功能：将方法添加到此类型定义的方法列表中。

参数：

- method: [Function](#class-function) - 待添加的方法。

### func appendStaticVar(GlobalVar)

```cangjie
public func appendStaticVar(staticVar: GlobalVar): Unit
```

功能：将静态变量添加到此类型定义中，并自动标记为静态成员。

参数：

- staticVar: [GlobalVar](#class-globalvar) - 待添加的静态变量。

### func setPublic()

```cangjie
public func setPublic(): Unit
```

功能：标记为 `public` 可见性。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    d.setPublic()
    println("fn_setPublic: ${d.isPublic()}")
}
```

运行结果：

```text
fn_setPublic: true
```

### func setPrivate()

```cangjie
public func setPrivate(): Unit
```

功能：标记为 `private`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    d.setPrivate()
    println("fn_setPrivate: ${d.isPrivate()}")
}
```

运行结果：

```text
fn_setPrivate: true
```

### func setProtected()

```cangjie
public func setProtected(): Unit
```

功能：标记为 `protected`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    d.setProtected()
    println("fn_setProtected: ${d.isProtected()}")
}
```

运行结果：

```text
fn_setProtected: true
```

### func setInternal()

```cangjie
public func setInternal(): Unit
```

功能：标记为 `internal`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    d.setInternal()
    println("fn_setInternal: ${d.isInternal()}")
}
```

运行结果：

```text
fn_setInternal: true
```

### func isImported()

```cangjie
public func isImported(): Bool
```

功能：是否为从其它包导入的定义。

返回值：

- Bool - Imported 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isImported())
}
```

运行结果：

```text
false
```

### func isPublic()

```cangjie
public func isPublic(): Bool
```

功能：是否带 `public` 属性。

返回值：

- Bool - Public 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isPublic())
}
```

运行结果：

```text
false
```

### func isPrivate()

```cangjie
public func isPrivate(): Bool
```

功能：是否带 `private` 属性。

返回值：

- Bool - Private 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isPrivate())
}
```

运行结果：

```text
false
```

### func isInternal()

```cangjie
public func isInternal(): Bool
```

功能：是否带 `internal` 属性。

返回值：

- Bool - Internal 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isInternal())
}
```

运行结果：

```text
false
```

### func isProtected()

```cangjie
public func isProtected(): Bool
```

功能：是否带 `protected` 属性。

返回值：

- Bool - Protected 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isProtected())
}
```

运行结果：

```text
false
```

### func isAbstract()

```cangjie
public func isAbstract(): Bool
```

功能：是否为 `abstract`。

返回值：

- Bool - Abstract 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isAbstract())
}
```

运行结果：

```text
false
```

### func isOpen()

```cangjie
public func isOpen(): Bool
```

功能：是否可继承/实现（`virtual` 或 `abstract`）。

返回值：

- Bool - Virtual 或 Abstract 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isOpen())
}
```

运行结果：

```text
false
```

### func isSealed()

```cangjie
public func isSealed(): Bool
```

功能：是否为 `sealed`。

返回值：

- Bool - Sealed 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isSealed())
}
```

运行结果：

```text
false
```

### func isGeneric()

```cangjie
public func isGeneric(): Bool
```

功能：是否为泛型定义。

返回值：

- Bool - Generic 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isGeneric())
}
```

运行结果：

```text
false
```

### func isClassLike()

```cangjie
public func isClassLike(): Bool
```

功能：种类是否为类/接口。

返回值：

- Bool - 种类为 ClassLike 则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("fn_isClassLike: ${d.isClassLike()}")
}
```

运行结果：

```text
fn_isClassLike: true
```

### func isClass()

```cangjie
public func isClass(): Bool
```

功能：是否为类（非接口）。

返回值：

- Bool - 是类则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("fn_isClass: ${d.isClass()}")
}
```

运行结果：

```text
fn_isClass: true
```

### func isInterface()

```cangjie
public func isInterface(): Bool
```

功能：是否为接口。

返回值：

- Bool - 是接口则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isInterface())
}
```

运行结果：

```text
false
```

### func isEnum()

```cangjie
public func isEnum(): Bool
```

功能：是否为枚举定义。

返回值：

- Bool - 种类为 Enum 则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isEnum())
}
```

运行结果：

```text
false
```

### func isExtend()

```cangjie
public func isExtend(): Bool
```

功能：是否为 extend 定义。

返回值：

- Bool - 种类为 Extend 则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isExtend())
}
```

运行结果：

```text
false
```

### func isStruct()

```cangjie
public func isStruct(): Bool
```

功能：是否为结构体定义。

返回值：

- Bool - 种类为 Struct 则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isStruct())
}
```

运行结果：

```text
false
```

### func hashCode()

```cangjie
public func hashCode(): Int64
```

功能：定义的哈希码。

返回值：

- Int64 - 哈希值。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("fn_hashCode: ${d.hashCode() != 0}")
}
```

运行结果：

```text
fn_hashCode: true
```

### operator func ==(CustomTypeDef)

```cangjie
public operator func ==(other: CustomTypeDef): Bool
```

功能：按种类、标识、源码名与包名比较。

返回值：

- Bool - 相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("op_eq_CustomTypeDef: ${d == d}")
}
```

运行结果：

```text
op_eq_CustomTypeDef: true
```

### func toString()

```cangjie
public open func toString(): String
```

功能：多行类/接口/枚举等形状文本（含属性、成员、`extend` 列表）。

返回值：

- String - 定义的可读转储。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("fn_toString: ${d.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### func dump()

```cangjie
public func dump(): Unit
```

功能：将 `toString()` 输出到标准输出。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    d.dump()
}
```

运行结果：

```text
[pluginAdded]class @X_m { // srcCodeName: X, packageName: p
}
```

### func appendInstanceMemberVar(String, Type)

```cangjie
public func appendInstanceMemberVar(name: String, ty: Type): MemberVar
```

功能：向当前类型定义**追加**一个实例成员变量（名称与类型），并返回对应的 [MemberVar](#class-membervar)。成员在 `instanceVars` 中的顺序与调用顺序一致；适用于插件或测试在 `Package.addClass` / `addStruct` 等创建定义之后挂载 CHIR 成员。

返回值：

- [MemberVar](#class-membervar) - 新创建的成员变量节点。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    let mv = d.appendInstanceMemberVar("f", IntType.getInt32())
    println(mv.name)
}
```

运行结果：

```text
f
```

### func getSuperTypesRecusively()

```cangjie
public func getSuperTypesRecusively(): Array<ClassLikeType>
```

功能：递归收集这个定义的所有父类，包括父类通过扩展实现的接口，但不包括本定义通过扩展实现的接口。

返回值：

- Array\<[ClassLikeType](#class-classliketype)> - 收集到的父类型；**不保证顺序**。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.getSuperTypesRecusively().size}")
}
```

运行结果：

```text
0
```

## class DebugLocation

```cangjie
public class DebugLocation <: ToString {}
```

功能：源码中的**区间位置**（起止 `Position` 与文件路径），用于调试与打印。

父类型：

- ToString

### prop start

```cangjie
public prop start: Position
```

功能：区间起点（含），与 [struct Position](chir_package_structs.md#struct-position) 成对使用。

类型：[Position](chir_package_structs.md#struct-position)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.location.start.line)
}
```

运行结果：

```text
0
```

### prop end

```cangjie
public prop end: Position
```

功能：区间终点。

类型：[Position](chir_package_structs.md#struct-position)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.location.end.column)
}
```

运行结果：

```text
0
```

### prop filePath

```cangjie
public prop filePath: Path
```

功能：源文件路径（绝对或工程内路径，见 `std.fs.Path`）。

类型：Path

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println("prop_filePath: ${mv.location.filePath.isEmpty()}")
}
```

运行结果：

```text
prop_filePath: true
```

### func isValid()

```cangjie
public func isValid(): Bool
```

功能：当 `start`、`end` 均有效且 `filePath` 非空时返回 `true`。

返回值：

- Bool - 是否为可用调试区间。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.location.isValid())
}
```

运行结果：

```text
false
```

### func toString()

```cangjie
public func toString(): String
```

功能：无效时返回空串；否则输出文件名、`start`/`end` 的紧凑形式及可选 scope 链（见源码）。

返回值：

- String - 人类可读位置描述。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.location.toString().size)
}
```

运行结果：

```text
0
```

## class EnumCtorInfo

```cangjie
public class EnumCtorInfo <: ToString {}
```

功能：枚举的一个**构造器/变体**（名称、内部标识、函数类型、注解）。

父类型：

- ToString

### prop identifier

```cangjie
public prop identifier: String
```

功能：内部标识，全局唯一标识符。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    let ctor = e.appendEnumCtorInfo("A_m", "A")
    println("prop_identifier: ${ctor.identifier.size > 0}")
}
```

运行结果：

```text
prop_identifier: true
```

### prop funcType

```cangjie
public prop funcType: FuncType
```

功能：该变元的参数类型与返回类型（返回为所属枚举类型）的 [FuncType](#class-functype)。

类型：[FuncType](#class-functype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    let ctor = e.appendEnumCtorInfo("A_m", "A")
    println("${ctor.funcType.paramTypes.size}")
}
```

运行结果：

```text
0
```

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

功能：源码中的构造器/变体名。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    let ctor = e.appendEnumCtorInfo("A_m", "A")
    println(ctor.srcCodeName)
}
```

运行结果：

```text
A
```

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

功能：挂在此枚举构造器上的注解实例列表；getter 返回当前所有实例，setter 整体替换。

类型：Array\<[CustomAnnoInstance](#class-customannoinstance)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    let ctor = e.appendEnumCtorInfo("A_m", "A")
    let ann = CustomAnnoInstance("Marker")
    ctor.customAnnoInstances = [ann]
    println("${ctor.customAnnoInstances.size}")
}
```

运行结果：

```text
1
```

### func toString()

```cangjie
public func toString(): String
```

功能：形如 `VariantName(paramTypes...)` 的简短描述（见源码）。

返回值：

- String - 构造器文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    let ctor = e.appendEnumCtorInfo("A_m", "A")
    println(ctor.toString())
}
```

运行结果：

```text
A
```

## class EnumDef

```cangjie
public class EnumDef <: CustomTypeDef & Equatable<EnumDef> {}
```

功能：**枚举**定义；含是否穷尽、构造器列表等。

父类型：

- [CustomTypeDef](#class-customtypedef)
- Equatable\<[EnumDef](#class-enumdef)>

### prop isExhaustive

```cangjie
public prop isExhaustive: Bool
```

功能：是否为**穷尽**枚举（与内部 `nonExhaustive` 标志相反）。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    println("prop_isExhaustive: ${e.isExhaustive}")
}
```

运行结果：

```text
prop_isExhaustive: true
```

### prop constructors

```cangjie
public prop constructors: Array<EnumCtorInfo>
```

功能：全部枚举构造器/变体，按声明顺序。

类型：Array\<[EnumCtorInfo](#class-enumctorinfo)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    e.appendEnumCtorInfo("A_m", "A")
    println("${e.constructors.size}")
}
```

运行结果：

```text
1
```

### prop enumType

```cangjie
public prop enumType: EnumType
```

功能：与此定义对应的实例化 [EnumType](#class-enumtype)。

类型：[EnumType](#class-enumtype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    println("prop_enumType: ${e.enumType.enumDef == e}")
}
```

运行结果：

```text
prop_enumType: true
```

### func appendEnumCtorInfo(String, String, Array\<Type>)

```cangjie
public func appendEnumCtorInfo(identifier: String, name: String, argTypes!: Array<Type> = Array<Type>()): EnumCtorInfo
```

功能：追加一个枚举变元；无参变元可省略 `argTypes` 或传空数组。

参数：

- identifier: String - 全局唯一标识符。
- name: String - 源码变体名。
- argTypes!: Array\<Type> - 参数类型列表。

返回值：

- [EnumCtorInfo](#class-enumctorinfo) - 新创建的构造器信息。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_mangled", "E", true)
    let c = e.appendEnumCtorInfo("A_mangled", "A")
    println(c.srcCodeName)
}
```

运行结果：

```text
A
```

### operator func ==(EnumDef)

```cangjie
public operator func ==(other: EnumDef): Bool
```

功能：按定义标识比较是否同一枚举定义。

参数：

- other: EnumDef - 另一枚举定义。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    println("op_eq_EnumDef: ${e == e}")
}
```

运行结果：

```text
op_eq_EnumDef: true
```

## class EnumType

```cangjie
public class EnumType <: CustomType & Equatable<EnumType> {}
```

功能：枚举的实例化类型；`get(def, genericTypeParams)` 缓存。

父类型：

- [CustomType](#class-customtype)
- Equatable\<[EnumType](#class-enumtype)>

### prop enumDef

```cangjie
public prop enumDef: EnumDef
```

功能：对应的 [EnumDef](#class-enumdef)。

类型：[EnumDef](#class-enumdef)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addEnum("E_m", "E", true)
    let t = EnumType.get(d, [])
    println(t.enumDef.srcCodeName)
}
```

运行结果：

```text
E
```

### static func get(EnumDef, Array\<Type>)

```cangjie
public static func get(def: EnumDef, genericTypeParams: Array<Type>): EnumType
```

功能：按枚举定义与泛型实参取得或创建缓存实例。

参数：

- def: EnumDef - 枚举定义。
- genericTypeParams: Array\<Type> - 泛型实参。

返回值：

- [EnumType](#class-enumtype) - 实例化枚举类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addEnum("E_m", "E", true)
    let t = EnumType.get(d, [])
    println(t.enumDef.srcCodeName)
}
```

运行结果：

```text
E
```

### operator func ==(EnumType)

```cangjie
public operator func ==(other: EnumType): Bool
```

功能：比较是否为同一实例化枚举类型。

参数：

- other: EnumType - 另一枚举类型。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addEnum("E_m", "E", true)
    let t1 = EnumType.get(d, [])
    let t2 = EnumType.get(d, [])
    println("op_eq_EnumType: ${t1 == t2}")
}
```

运行结果：

```text
op_eq_EnumType: true
```

## class ExtendDef

```cangjie
public class ExtendDef <: CustomTypeDef {}
```

功能：**扩展（extend）**定义：对某类型增加实现等，带 `extendedType` 与泛型参数。

父类型：

- [CustomTypeDef](#class-customtypedef)

### prop extendedType

```cangjie
public prop extendedType: Type
```

功能：被扩展的目标类型（`extend T { ... }` 中的 `T`）。

类型：[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let ext = pkg.addExtend("ext_m", IntType.getInt32())
    println(ext.extendedType.toString())
}
```

运行结果：

```text
Int32
```

## class FloatType

```cangjie
public class FloatType <: NumericType & Equatable<FloatType> {}
```

功能：表示类型系统中的浮点类型。该类表示三种浮点类型：Float16、Float32 和 Float64。

父类型：

- [NumericType](#class-numerictype)
- Equatable\<[FloatType](#class-floattype)>

### static func getFloat16()

```cangjie
public static func getFloat16(): FloatType
```

功能：获取 Float16 类型实例。

返回值：

- [FloatType](#class-floattype) - Float16 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let float16Type = FloatType.getFloat16()
    println("Float16 类型: ${float16Type.toString()}")
}
```

运行结果：

```text
Float16 类型: Float16
```

### static func getFloat32()

```cangjie
public static func getFloat32(): FloatType
```

功能：获取 Float32 类型实例。

返回值：

- [FloatType](#class-floattype) - Float32 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let float32Type = FloatType.getFloat32()
    println("Float32 类型: ${float32Type.toString()}")
}
```

运行结果：

```text
Float32 类型: Float32
```

### static func getFloat64()

```cangjie
public static func getFloat64(): FloatType
```

功能：获取 Float64 类型实例。

返回值：

- [FloatType](#class-floattype) - Float64 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let float64Type = FloatType.getFloat64()
    println("Float64 类型: ${float64Type.toString()}")
}
```

运行结果：

```text
Float64 类型: Float64
```

### operator func ==(FloatType)

```cangjie
public operator func ==(other: FloatType): Bool
```

功能：检查该 FloatType 是否与另一个 FloatType 相等。

参数：

- other: FloatType - 要比较的 FloatType。

返回值：

- Bool - 如果类型相等则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let float32Type1 = FloatType.getFloat32()
    let float32Type2 = FloatType.getFloat32()
    let float64Type = FloatType.getFloat64()
    println("两个 Float32 相等: ${float32Type1 == float32Type2}")
    println("Float32 和 Float64 相等: ${float32Type1 == float64Type}")
}
```

运行结果：

```text
两个 Float32 相等: true
Float32 和 Float64 相等: false
```

## class FuncType

```cangjie
public class FuncType <: Type & Equatable<FuncType> {}
```

功能：函数类型（参数类型列表 + 返回类型），可选可变参数与 C 函数标记；按签名缓存。

父类型：

- [Type](#class-type)
- Equatable\<[FuncType](#class-functype)>

### prop hasVarArg

```cangjie
public prop hasVarArg: Bool
```

功能：是否为可变参数函数类型。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println(f.hasVarArg)
}
```

运行结果：

```text
false
```

### prop isCFunc

```cangjie
public prop isCFunc: Bool
```

功能：是否表示 C 函数类型（影响 `toString()` 前缀 `CFunc<...>`）。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println(f.isCFunc)
}
```

运行结果：

```text
false
```

### prop paramTypes

```cangjie
public prop paramTypes: Array<Type>
```

功能：形参类型数组。

类型：Array\<Type>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println("${f.paramTypes.size}")
}
```

运行结果：

```text
1
```

### prop returnType

```cangjie
public prop returnType: Type
```

功能：返回类型。

类型：Type

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println(f.returnType.toString())
}
```

运行结果：

```text
Int32
```

### static func get(Array\<Type>, Type, Bool, Bool)

```cangjie
public static func get(paramTypes: Array<Type>, retType: Type, varArg!: Bool = false, cFunc!: Bool = false): FuncType
```

功能：按形参列表、返回类型及可变参/C 函数标记取得或创建唯一缓存实例。

参数：

- paramTypes: Array\<Type> - 形参类型序列。
- retType: Type - 返回类型。
- varArg! - 是否为可变参数函数类型，默认 `false`。
- cFunc! - 是否为 `CFunc<...>` 形式，默认 `false`。

返回值：

- [FuncType](#class-functype) - 函数类型实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println(f.toString())
}
```

运行结果：

```text
(Int32) -> Int32
```

### func toString()

```cangjie
public func toString(): String
```

功能：形如 `(T1, T2) -> R` 或 `CFunc<(T1)-> R>` 的字符串（见源码）。

返回值：

- String - 函数类型文本。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let u = IntType.getUInt32()
    let f = FuncType.get([u], UnitType.get())
    println(f.toString())
}
```

运行结果：

```text
(UInt32) -> Unit
```

### operator func ==(FuncType)

```cangjie
public operator func ==(other: FuncType): Bool
```

功能：比较签名、`varArg`、`cFunc` 是否一致。

参数：

- other: FuncType - 另一函数类型。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f1 = FuncType.get([i32], i32)
    let f2 = FuncType.get([i32], i32)
    println("op_eq_FuncType: ${f1 == f2}")
}
```

运行结果：

```text
op_eq_FuncType: true
```

## class GenericType

```cangjie
public class GenericType <: Type & Equatable<GenericType> {}
```

功能：泛型**形参**（如 `T`），可设置上界 `upperBounds`。按内部 `identifier` 缓存。

父类型：

- [Type](#class-type)
- Equatable\<[GenericType](#class-generictype)>

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

功能：源码中的泛型参数名（如 `T`）。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = GenericType.get("g:T", "T")
    println(t.srcCodeName)
}
```

运行结果：

```text
T
```

### prop upperBounds

```cangjie
public mut prop upperBounds: Array<Type>
```

功能：上界类型列表；赋值时会拒绝**值类型**上界（见源码校验）。

类型：Array\<Type>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = GenericType.get("g:T", "T")
    println("${t.upperBounds.size}")
}
```

运行结果：

```text
0
```

### static func get(String, String)

```cangjie
public static func get(identifier: String, srcCodeName: String): GenericType
```

功能：按内部 `identifier` 缓存取得或创建泛型形参类型（如 `T`）。

参数：

- identifier: String - 内部唯一键（mangling 用）。
- srcCodeName: String - 源码中的形参名。

返回值：

- [GenericType](#class-generictype) - 泛型形参类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = GenericType.get("g:T", "T")
    println("static_get: ${t.toString().size > 0}")
}
```

运行结果：

```text
static_get: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：内部调试用字符串（含 kind 与 identifier）。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = GenericType.get("g:U", "U")
    println("fn_toString: ${t.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### operator func ==(GenericType)

```cangjie
public operator func ==(other: GenericType): Bool
```

功能：比较是否为同一泛型形参节点。

参数：

- other: GenericType - 另一泛型形参。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t1 = GenericType.get("g:T", "T")
    let t2 = GenericType.get("g:T", "T")
    println("op_eq_GenericType: ${t1 == t2}")
}
```

运行结果：

```text
op_eq_GenericType: true
```

## class IntType

```cangjie
public class IntType <: NumericType & Equatable<IntType> {}
```

功能：表示类型系统中的整数类型。该类表示各种大小的有符号和无符号整数类型。

父类型：

- [NumericType](#class-numerictype)
- Equatable\<[IntType](#class-inttype)>

### static func getInt16()

```cangjie
public static func getInt16(): IntType
```

功能：获取 Int16 类型实例。

返回值：

- [IntType](#class-inttype) - Int16 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int16Type = IntType.getInt16()
    println("Int16 类型: ${int16Type.toString()}")
}
```

运行结果：

```text
Int16 类型: Int16
```

### static func getInt32()

```cangjie
public static func getInt32(): IntType
```

功能：获取 Int32 类型实例。

返回值：

- [IntType](#class-inttype) - Int32 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int32Type = IntType.getInt32()
    println("Int32 类型: ${int32Type.toString()}")
}
```

运行结果：

```text
Int32 类型: Int32
```

### static func getInt64()

```cangjie
public static func getInt64(): IntType
```

功能：获取 Int64 类型实例。

返回值：

- [IntType](#class-inttype) - Int64 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int64Type = IntType.getInt64()
    println("Int64 类型: ${int64Type.toString()}")
}
```

运行结果：

```text
Int64 类型: Int64
```

### static func getInt8()

```cangjie
public static func getInt8(): IntType
```

功能：获取 Int8 类型实例。

返回值：

- [IntType](#class-inttype) - Int8 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int8Type = IntType.getInt8()
    println("Int8 类型: ${int8Type.toString()}")
}
```

运行结果：

```text
Int8 类型: Int8
```

### static func getIntNative()

```cangjie
public static func getIntNative(): IntType
```

功能：获取 IntNative 类型实例。

返回值：

- [IntType](#class-inttype) - IntNative 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intNativeType = IntType.getIntNative()
    println("IntNative 类型: ${intNativeType.toString()}")
}
```

运行结果：

```text
IntNative 类型: IntNative
```

### static func getUInt16()

```cangjie
public static func getUInt16(): IntType
```

功能：获取 UInt16 类型实例。

返回值：

- [IntType](#class-inttype) - UInt16 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uint16Type = IntType.getUInt16()
    println("UInt16 类型: ${uint16Type.toString()}")
}
```

运行结果：

```text
UInt16 类型: UInt16
```

### static func getUInt32()

```cangjie
public static func getUInt32(): IntType
```

功能：获取 UInt32 类型实例。

返回值：

- [IntType](#class-inttype) - UInt32 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uint32Type = IntType.getUInt32()
    println("UInt32 类型: ${uint32Type.toString()}")
}
```

运行结果：

```text
UInt32 类型: UInt32
```

### static func getUInt64()

```cangjie
public static func getUInt64(): IntType
```

功能：获取 UInt64 类型实例。

返回值：

- [IntType](#class-inttype) - UInt64 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uint64Type = IntType.getUInt64()
    println("UInt64 类型: ${uint64Type.toString()}")
}
```

运行结果：

```text
UInt64 类型: UInt64
```

### static func getUInt8()

```cangjie
public static func getUInt8(): IntType
```

功能：获取 UInt8 类型实例。

返回值：

- [IntType](#class-inttype) - UInt8 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uint8Type = IntType.getUInt8()
    println("UInt8 类型: ${uint8Type.toString()}")
}
```

运行结果：

```text
UInt8 类型: UInt8
```

### static func getUIntNative()

```cangjie
public static func getUIntNative(): IntType
```

功能：获取 UIntNative 类型实例。

返回值：

- [IntType](#class-inttype) - UIntNative 类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uintNativeType = IntType.getUIntNative()
    println("UIntNative 类型: ${uintNativeType.toString()}")
}
```

运行结果：

```text
UIntNative 类型: UIntNative
```

### operator func ==(IntType)

```cangjie
public operator func ==(other: IntType): Bool
```

功能：检查该 IntType 是否与另一个 IntType 相等。

参数：

- other: IntType - 要比较的 IntType。

返回值：

- Bool - 如果类型相等则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int32Type1 = IntType.getInt32()
    let int32Type2 = IntType.getInt32()
    let int64Type = IntType.getInt64()
    println("两个 Int32 相等: ${int32Type1 == int32Type2}")
    println("Int32 和 Int64 相等: ${int32Type1 == int64Type}")
}
```

运行结果：

```text
两个 Int32 相等: true
Int32 和 Int64 相等: false
```

### func isSigned()

```cangjie
public func isSigned(): Bool
```

功能：检查该整数类型是否为有符号类型。

返回值：

- Bool - 如果类型是有符号的则返回 true，如果是无符号的则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int32Type = IntType.getInt32()
    let uint32Type = IntType.getUInt32()
    println("Int32 是有符号的: ${int32Type.isSigned()}")
    println("UInt32 是有符号的: ${uint32Type.isSigned()}")
}
```

运行结果：

```text
Int32 是有符号的: true
UInt32 是有符号的: false
```

## class MemberVar

```cangjie
public class MemberVar <: ToString {}
```

功能：描述自定义类型上的**实例成员变量**（名称、类型、调试位置、注解与访问修饰等）。

父类型：

- ToString

### prop name

```cangjie
public prop name: String
```

功能：成员源码名。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.name)
}
```

运行结果：

```text
x
```

### prop ty

```cangjie
public prop ty: Type
```

功能：成员类型。

类型：[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.ty.toString())
}
```

运行结果：

```text
Int32
```

### prop location

```cangjie
public prop location: DebugLocation
```

功能：源码位置；未设置时可能为无效区间（见 [DebugLocation](#class-debuglocation)）。

类型：[DebugLocation](#class-debuglocation)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.location.isValid())
}
```

运行结果：

```text
false
```

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

功能：成员上的注解实例列表；getter 返回当前所有实例，setter 整体替换。

类型：Array\<[CustomAnnoInstance](#class-customannoinstance)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println("${mv.customAnnoInstances.size}")
}
```

运行结果：

```text
0
```

### prop outerDef

```cangjie
public prop outerDef: CustomTypeDef
```

功能：包含该成员的外层类型定义。

类型：[CustomTypeDef](#class-customtypedef)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.outerDef.srcCodeName)
}
```

运行结果：

```text
S
```

### func setReadOnly(Bool)

```cangjie
public func setReadOnly(enable: Bool): Unit
```

功能：设置或清除只读（`let` 语义）标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    mv.setReadOnly(true)
    println("fn_setReadOnly: ${mv.isReadOnly()}")
}
```

运行结果：

```text
fn_setReadOnly: true
```

### func setInternal()

```cangjie
public func setInternal(): Unit
```

功能：将成员标为 `internal`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    mv.setInternal()
    println("fn_setInternal: ${mv.isInternal()}")
}
```

运行结果：

```text
fn_setInternal: true
```

### func setPublic()

```cangjie
public func setPublic(): Unit
```

功能：将成员标为 `public`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    mv.setPublic()
    println("fn_setPublic: ${mv.isPublic()}")
}
```

运行结果：

```text
fn_setPublic: true
```

### func setPrivate()

```cangjie
public func setPrivate(): Unit
```

功能：将成员标为 `private`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    mv.setPrivate()
    println("fn_setPrivate: ${mv.isPrivate()}")
}
```

运行结果：

```text
fn_setPrivate: true
```

### func setProtected()

```cangjie
public func setProtected(): Unit
```

功能：将成员标为 `protected`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    mv.setProtected()
    println("fn_setProtected: ${mv.isProtected()}")
}
```

运行结果：

```text
fn_setProtected: true
```

### func isReadOnly()

```cangjie
public func isReadOnly(): Bool
```

功能：是否为只读成员。

返回值：

- Bool - READONLY 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.isReadOnly())
}
```

运行结果：

```text
false
```

### func isInternal()

```cangjie
public func isInternal(): Bool
```

功能：是否为 `internal`。

返回值：

- Bool - INTERNAL 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.isInternal())
}
```

运行结果：

```text
false
```

### func isPublic()

```cangjie
public func isPublic(): Bool
```

功能：是否为 `public`。

返回值：

- Bool - PUBLIC 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.isPublic())
}
```

运行结果：

```text
false
```

### func isPrivate()

```cangjie
public func isPrivate(): Bool
```

功能：是否为 `private`。

返回值：

- Bool - PRIVATE 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.isPrivate())
}
```

运行结果：

```text
false
```

### func isProtected()

```cangjie
public func isProtected(): Bool
```

功能：是否为 `protected`。

返回值：

- Bool - PROTECTED 属性已设置则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println(mv.isProtected())
}
```

运行结果：

```text
false
```

### func toString()

```cangjie
public func toString(): String
```

功能：属性前缀 + `let`/`var`、名称、类型及位置注释。

返回值：

- String - 单行成员描述。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    println("fn_toString: ${mv.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### func dump()

```cangjie
public func dump(): Unit
```

功能：打印 `toString()`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    mv.dump()
}
```

运行结果：

```text
[pluginAdded]var x: Int32
```

## class NothingType

```cangjie
public class NothingType <: BuiltinType & Equatable<NothingType> {}
```

功能：表示类型系统中的 Nothing 类型（底部类型）。该类型用于表示永远不会返回的表达式。

父类型：

- [BuiltinType](#class-builtintype)
- Equatable\<[NothingType](#class-nothingtype)>

### static func get()

```cangjie
public static func get(): NothingType
```

功能：获取 NothingType 的单例实例。

返回值：

- [NothingType](#class-nothingtype) - NothingType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let nothingType = NothingType.get()
    println("Nothing 类型: ${nothingType.toString()}")
}
```

运行结果：

```text
Nothing 类型: Nothing
```

### operator func ==(NothingType)

```cangjie
public operator func ==(_: NothingType): Bool
```

功能：检查该 NothingType 是否与另一个 NothingType 相等。

参数：

- _: NothingType - 要比较的另一个 NothingType（未使用，始终返回 true）。

返回值：

- Bool - 始终返回 true，因为所有 NothingType 实例都相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let nothingType1 = NothingType.get()
    let nothingType2 = NothingType.get()
    println("两个 NothingType 相等: ${nothingType1 == nothingType2}")
}
```

运行结果：

```text
两个 NothingType 相等: true
```

## class NumericType

```cangjie
sealed abstract class NumericType <: BuiltinType & Equatable<NumericType> {}
```

功能：数值类型的抽象基类。该类表示数值类型，包括整数类型和浮点类型。

父类型：

- [BuiltinType](#class-builtintype)
- Equatable\<[NumericType](#class-numerictype)>

### operator func ==(NumericType)

```cangjie
public operator func ==(other: NumericType): Bool
```

功能：检查该数值类型是否与另一个数值类型相等。

参数：

- other: NumericType - 要比较的数值类型。

返回值：

- Bool - 如果类型相等则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType1 = IntType.getInt32()
    let intType2 = IntType.getInt32()
    let floatType = FloatType.getFloat32()
    println("两个 Int32 相等: ${intType1 == intType2}")
    println("Int32 和 Float32 相等: ${intType1 == floatType}")
}
```

运行结果：

```text
两个 Int32 相等: true
Int32 和 Float32 相等: false
```

## class Package

```cangjie
public class Package <: ToString {
    public init(name: String, accessLevel: AccessLevel)
}
```

功能：表示一个 **CHIR 包**：名称、访问级别、导入与本包内的类型定义集合。

父类型：

- ToString

### prop name

```cangjie
public prop name: String
```

功能：包逻辑名。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    println(pkg.name)
}
```

运行结果：

```text
demo
```

### prop accessLevel

```cangjie
public prop accessLevel: AccessLevel
```

功能：包访问级别。

类型：[AccessLevel](chir_package_enums.md#enum-accesslevel)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    println("prop_accessLevel: ${pkg.accessLevel == AccessLevel.Public}")
}
```

运行结果：

```text
prop_accessLevel: true
```

### prop importedClassDefs

```cangjie
public prop importedClassDefs: Array<ClassLikeDef>
```

功能：从其它包导入的类/接口定义快照。

类型：Array\<[ClassLikeDef](#class-classlikedef)>

### prop importedEnumDefs

```cangjie
public prop importedEnumDefs: Array<EnumDef>
```

功能：导入的枚举定义。

类型：Array\<[EnumDef](#class-enumdef)>

### prop importedStructDefs

```cangjie
public prop importedStructDefs: Array<StructDef>
```

功能：导入的结构体定义。

类型：Array\<[StructDef](#class-structdef)>

### prop importedExtendDefs

```cangjie
public prop importedExtendDefs: Array<ExtendDef>
```

功能：导入的 extend 定义。

类型：Array\<[ExtendDef](#class-extenddef)>

### prop classDefs

```cangjie
public prop classDefs: Array<ClassLikeDef>
```

功能：本包内定义的类/接口。

类型：Array\<[ClassLikeDef](#class-classlikedef)>

### prop enumDefs

```cangjie
public prop enumDefs: Array<EnumDef>
```

功能：本包内定义的枚举。

类型：Array\<[EnumDef](#class-enumdef)>

### prop structDefs

```cangjie
public prop structDefs: Array<StructDef>
```

功能：本包内定义的结构体。

类型：Array\<[StructDef](#class-structdef)>

### prop extendDefs

```cangjie
public prop extendDefs: Array<ExtendDef>
```

功能：本包内定义的 extend。

类型：Array\<[ExtendDef](#class-extenddef)>

### prop globalVars

```cangjie
public prop globalVars: Array<GlobalVar>
```

功能：包中定义的全局变量列表。

类型：Array\<[GlobalVar](#class-globalvar)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    println("${pkg.globalVars.size}")
}
```

运行结果：

```text
0
```

### prop functions

```cangjie
public prop functions: Array<Function>
```

功能：包中定义的函数列表。

类型：Array\<[Function](#class-function)>

### prop allCustomTypeDefs

```cangjie
public prop allCustomTypeDefs: Array<CustomTypeDef>
```

功能：包中所有自定义类型定义（包括导入和本地定义的类、枚举、扩展、结构体）。

类型：Array\<[CustomTypeDef](#class-customtypedef)>

### prop packageInitFunc

```cangjie
public prop packageInitFunc: ?Function
```

功能：包初始化函数；未设置时为 None。

类型：?[Function](#class-function)

### init(String, AccessLevel)

```cangjie
public init(name: String, accessLevel: AccessLevel)
```

功能：创建空包，指定逻辑包名与 [AccessLevel](chir_package_enums.md#enum-accesslevel)。

参数：

- name: String - 包名。
- accessLevel: AccessLevel - 包访问级别。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    println(pkg.name)
}
```

运行结果：

```text
demo
```

### func addClass(String, String, Bool, Array\<GenericType>)

```cangjie
public func addClass(identifier: String, srcCodeName: String, isClass: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ClassLikeDef
```

功能：在本包中新建类或接口定义并加入 `classDefs`。

返回值：

- [ClassLikeDef](#class-classlikedef) - 新定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let d = pkg.addClass("C_m", "C", true)
    println("${pkg.classDefs.size}")
    println(d.srcCodeName)
}
```

运行结果：

```text
1
C
```

### func addImportedClass(String, String, String, Bool, Array\<GenericType>)

```cangjie
public func addImportedClass(identifier: String, srcCodeName: String, packageName: String, isClass: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ClassLikeDef
```

功能：登记导入的类/接口定义（带 `Imported` 标记）。

返回值：

- [ClassLikeDef](#class-classlikedef) - 新定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let d = pkg.addImportedClass("I_m", "I", "other", true)
    println("fn_addImportedClass importedCount: ${pkg.importedClassDefs.size}")
    println("fn_addImportedClass isImported: ${d.isImported()}")
}
```

运行结果：

```text
fn_addImportedClass importedCount: 1
fn_addImportedClass isImported: true
```

### func addStruct(String, String, Array\<GenericType>)

```cangjie
public func addStruct(identifier: String, srcCodeName: String, genericTypeParams!: Array<GenericType> = Array<GenericType>()): StructDef
```

功能：在本包中新建结构体定义。

返回值：

- [StructDef](#class-structdef) - 新定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let d = pkg.addStruct("S_m", "S")
    println("${pkg.structDefs.size}")
    println(d.srcCodeName)
}
```

运行结果：

```text
1
S
```

### func addImportedStruct(String, String, String, Array\<GenericType>)

```cangjie
public func addImportedStruct(identifier: String, srcCodeName: String, packageName: String, genericTypeParams!: Array<GenericType> = Array<GenericType>()): StructDef
```

功能：登记导入的结构体定义。

返回值：

- [StructDef](#class-structdef) - 新定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let d = pkg.addImportedStruct("IS_m", "IS", "other")
    println("${pkg.importedStructDefs.size}")
    println(d.srcCodeName)
}
```

运行结果：

```text
1
IS
```

### func addEnum(String, String, Bool, Array\<GenericType>)

```cangjie
public func addEnum(identifier: String, srcCodeName: String, isExhaustive: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): EnumDef
```

功能：在本包中新建枚举定义。

返回值：

- [EnumDef](#class-enumdef) - 新定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let d = pkg.addEnum("E_m", "E", true)
    println("${pkg.enumDefs.size}")
    println(d.srcCodeName)
}
```

运行结果：

```text
1
E
```

### func addImportedEnum(String, String, String, Bool, Array\<GenericType>)

```cangjie
public func addImportedEnum(identifier: String, srcCodeName: String, packageName: String, isExhaustive: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): EnumDef
```

功能：登记导入的枚举定义。

返回值：

- [EnumDef](#class-enumdef) - 新定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let d = pkg.addImportedEnum("IE_m", "IE", "other", true)
    println("${pkg.importedEnumDefs.size}")
    println(d.srcCodeName)
}
```

运行结果：

```text
1
IE
```

### func addExtend(String, Type, Array\<GenericType>)

```cangjie
public func addExtend(identifier: String, extendedType: Type, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ExtendDef
```

功能：在本包中新建 extend 定义。

返回值：

- [ExtendDef](#class-extenddef) - 新定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let d = pkg.addExtend("ext_m", IntType.getInt32())
    println("${pkg.extendDefs.size}")
    println(d.extendedType.toString())
}
```

运行结果：

```text
1
Int32
```

### func addImportedExtend(String, String, Type, Array\<GenericType>)

```cangjie
public func addImportedExtend(identifier: String, packageName: String, extendedType: Type, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ExtendDef
```

功能：登记导入的 extend 定义。

返回值：

- [ExtendDef](#class-extenddef) - 新定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let d = pkg.addImportedExtend("iext_m", "other", IntType.getInt32())
    println("${pkg.importedExtendDefs.size}")
    println(d.extendedType.toString())
}
```

运行结果：

```text
1
Int32
```

### func addFunction(FuncType, String, String, String)

```cangjie
public func addFunction(ty: FuncType, identifier: String, srcCodeName: String, packageName: String): Function
```

功能：向此包添加函数定义，返回创建的 Function（参数从 ty 自动填充）。

参数：

- ty: FuncType - 函数类型。
- identifier: String - 内部标识。
- srcCodeName: String - 源码名称。
- packageName: String - 所属包名。

返回值：

- [Function](#class-function) - 新创建的函数定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("${pkg.functions.size}")
    println(f.srcCodeName)
}
```

运行结果：

```text
1
f
```

### func addGlobalVar(Type, String, String, String)

```cangjie
public func addGlobalVar(ty: Type, identifier: String, srcCodeName: String, packageName: String): GlobalVar
```

功能：向此包添加全局变量定义，返回创建的 GlobalVar。

参数：

- ty: Type - 变量类型。
- identifier: String - 内部标识。
- srcCodeName: String - 源码名称。
- packageName: String - 所属包名。

返回值：

- [GlobalVar](#class-globalvar) - 新创建的全局变量定义。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("${pkg.globalVars.size}")
    println(gv.srcCodeName)
}
```

运行结果：

```text
1
gv
```

### func getSpecifiedClassDef(String, String)

```cangjie
public func getSpecifiedClassDef(packageName: String, srcCodeName: String): ?ClassLikeDef
```

功能：在导入与本包 `classDefs` 中按「声明包名 + 源码类型名」查找类/接口定义。

返回值：

- ?[ClassLikeDef](#class-classlikedef) - 命中则 `Some`，否则 `None`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let _ = pkg.addImportedClass("I_m", "I", "other", true)
    let r = pkg.getSpecifiedClassDef("other", "I")
    println("fn_getSpecifiedClassDef: ${r.isSome()}")
}
```

运行结果：

```text
fn_getSpecifiedClassDef: true
```

### func getSpecifiedStructDef(String, String)

```cangjie
public func getSpecifiedStructDef(packageName: String, srcCodeName: String): ?StructDef
```

功能：同上，查找结构体定义。

返回值：

- ?[StructDef](#class-structdef) - 可选结果。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let _ = pkg.addImportedStruct("IS_m", "IS", "other")
    let r = pkg.getSpecifiedStructDef("other", "IS")
    println("fn_getSpecifiedStructDef: ${r.isSome()}")
}
```

运行结果：

```text
fn_getSpecifiedStructDef: true
```

### func getSpecifiedEnumDef(String, String)

```cangjie
public func getSpecifiedEnumDef(packageName: String, srcCodeName: String): ?EnumDef
```

功能：同上，查找枚举定义。

返回值：

- ?[EnumDef](#class-enumdef) - 可选结果。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let _ = pkg.addImportedEnum("IE_m", "IE", "other", true)
    let r = pkg.getSpecifiedEnumDef("other", "IE")
    println("fn_getSpecifiedEnumDef: ${r.isSome()}")
}
```

运行结果：

```text
fn_getSpecifiedEnumDef: true
```

### func getSpecifiedFunction(String)

```cangjie
public func getSpecifiedFunction(mangledName: String): ?Function
```

功能：按混淆名查找函数定义。

参数：

- mangledName: String - 函数的混淆名（不含全局前缀）。

返回值：

- ?[Function](#class-function) - 找到则 Some，否则 None。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let _ = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    let r = pkg.getSpecifiedFunction("f_m")
    println("fn_getSpecifiedFunction: ${r.isSome()}")
}
```

运行结果：

```text
fn_getSpecifiedFunction: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：输出包名、访问级别、导入区与本地类型区的拼接文本（调试用）。

返回值：

- String - 完整包描述。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("my.pkg", AccessLevel.Public)
    let _ = pkg.addClass("C1", "C", true)
    println("fn_toString: ${pkg.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### func dump()

```cangjie
public func dump(): Unit
```

功能：将 `toString()` 打印到标准输出。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("my.pkg", AccessLevel.Public)
    let _ = pkg.addClass("C1", "C", true)
    pkg.dump()
}
```

运行结果：

```text
package: my.pkg
packageAccessLevel: public

[pluginAdded]class @C1 { // srcCodeName: C, packageName: my.pkg
}
```

## class RawArrayType

```cangjie
public class RawArrayType <: BuiltinType & Equatable<RawArrayType> {}
```

功能：**原始数组**类型，带元素类型与维度数 `dims`。使用缓存按 `(elementType, dims)` 唯一化。

父类型：

- [BuiltinType](#class-builtintype)
- Equatable\<[RawArrayType](#class-rawarraytype)>

### prop elementType

```cangjie
public prop elementType: Type
```

功能：数组元素类型。

类型：Type

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = RawArrayType.get(IntType.getUInt32(), 1)
    println(t.elementType.toString())
}
```

运行结果：

```text
UInt32
```

### prop dims

```cangjie
public prop dims: UInt32
```

功能：原始数组维数。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = RawArrayType.get(IntType.getInt32(), 3)
    println("${t.dims}")
}
```

运行结果：

```text
3
```

### static func get(Type, UInt32)

```cangjie
public static func get(elementType: Type, dims: UInt32): RawArrayType
```

功能：获取或创建原始数组类型。

返回值：

- [RawArrayType](#class-rawarraytype) - RawArrayType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = RawArrayType.get(IntType.getInt32(), 2)
    println("static_get: ${t.toString().size > 0}")
}
```

运行结果：

```text
static_get: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：类型的字符串形式（如多维 `[[[T]]]` 风格，见源码）。

返回值：

- String - 文本表示。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = RawArrayType.get(IntType.getInt32(), 2)
    println(t.toString())
}
```

运行结果：

```text
RawArray<RawArray<Int32>>
```

### operator func ==(RawArrayType)

```cangjie
public operator func ==(other: RawArrayType): Bool
```

功能：比较元素类型与维数是否相同。

参数：

- other: RawArrayType - 另一原始数组类型。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t1 = RawArrayType.get(IntType.getInt32(), 2)
    let t2 = RawArrayType.get(IntType.getInt32(), 2)
    println("op_eq_RawArrayType: ${t1 == t2}")
}
```

运行结果：

```text
op_eq_RawArrayType: true
```

## class RefType

```cangjie
public class RefType <: Type & Equatable<RefType> {}
```

功能：表示类型系统中的引用类型。该类型包装另一个类型以表示对该类型的引用。该类维护所有引用类型的缓存以确保唯一性。

父类型：

- [Type](#class-type)
- Equatable\<[RefType](#class-reftype)>

### prop baseType

```cangjie
public prop baseType: Type
```

功能：获取该引用类型所引用的基类型。

返回值：

- [Type](#class-type) - 基类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let refType = RefType.get(intType)
    println(refType.baseType.toString())
}
```

运行结果：

```text
Int32
```

### static func get(Type)

```cangjie
public static func get(baseType: Type): RefType
```

功能：获取或创建给定基类型的 RefType。

此方法确保每个基类型只存在一个 RefType 实例。

参数：

- baseType: Type - 要创建引用的基类型。

返回值：

- [RefType](#class-reftype) - 给定基类型的 RefType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let refType = RefType.get(intType)
    println(refType.toString())
}
```

运行结果：

```text
Int32&
```

### func toString()

```cangjie
public func toString(): String
```

功能：将该 RefType 转换为字符串表示。

返回值：

- String - 引用类型的字符串表示（基类型后跟 '&'）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let refType = RefType.get(IntType.getUInt32())
    println(refType.toString())
}
```

运行结果：

```text
UInt32&
```

### operator func ==(RefType)

```cangjie
public operator func ==(other: RefType): Bool
```

功能：检查该 RefType 是否与另一个 RefType 相等。

参数：

- other: RefType - 要比较的 RefType。

返回值：

- Bool - 如果类型相等则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let refType1 = RefType.get(intType)
    let refType2 = RefType.get(intType)
    println("op_eq_RefType: ${refType1 == refType2}")
}
```

运行结果：

```text
op_eq_RefType: true
```

## class RuneType

```cangjie
public class RuneType <: BuiltinType & Equatable<RuneType> {}
```

功能：表示类型系统中的 Rune 类型。该类型表示字符类型。

父类型：

- [BuiltinType](#class-builtintype)
- Equatable\<[RuneType](#class-runetype)>

### static func get()

```cangjie
public static func get(): RuneType
```

功能：获取 RuneType 的单例实例。

返回值：

- [RuneType](#class-runetype) - RuneType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let runeType = RuneType.get()
    println("Rune 类型: ${runeType.toString()}")
}
```

运行结果：

```text
Rune 类型: Rune
```

### operator func ==(RuneType)

```cangjie
public operator func ==(_: RuneType): Bool
```

功能：检查该 RuneType 是否与另一个 RuneType 相等。

参数：

- _: RuneType - 要比较的另一个 RuneType（未使用，始终返回 true）。

返回值：

- Bool - 始终返回 true，因为所有 RuneType 实例都相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let runeType1 = RuneType.get()
    let runeType2 = RuneType.get()
    println("两个 RuneType 相等: ${runeType1 == runeType2}")
}
```

运行结果：

```text
两个 RuneType 相等: true
```

## class StructDef

```cangjie
public class StructDef <: CustomTypeDef & Equatable<StructDef> {}
```

功能：**结构体**定义；`isCStruct` 表示 C 互操作结构体。

父类型：

- [CustomTypeDef](#class-customtypedef)
- Equatable\<[StructDef](#class-structdef)>

### prop structType

```cangjie
public prop structType: StructType
```

功能：与此定义对应的实例化 [StructType](#class-structtype)。

类型：[StructType](#class-structtype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let s = pkg.addStruct("S_m", "S")
    println("prop_structType: ${s.structType.structDef == s}")
}
```

运行结果：

```text
prop_structType: true
```

### prop isCStruct

```cangjie
public mut prop isCStruct: Bool
```

功能：是否标记为与 C 互操作的结构体。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let s = pkg.addStruct("S_m", "S")
    s.isCStruct = true
    println("mut_prop_isCStruct: ${s.isCStruct}")
}
```

运行结果：

```text
mut_prop_isCStruct: true
```

### operator func ==(StructDef)

```cangjie
public operator func ==(other: StructDef): Bool
```

功能：比较是否同一结构体定义。

参数：

- other: StructDef - 另一结构体定义。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let s = pkg.addStruct("S_m", "S")
    println("op_eq_StructDef: ${s == s}")
}
```

运行结果：

```text
op_eq_StructDef: true
```

## class StructType

```cangjie
public class StructType <: CustomType & Equatable<StructType> {}
```

功能：结构体的实例化类型；`get(def, genericTypeParams)` 缓存。

父类型：

- [CustomType](#class-customtype)
- Equatable\<[StructType](#class-structtype)>

### prop structDef

```cangjie
public prop structDef: StructDef
```

功能：对应的 [StructDef](#class-structdef)。

类型：[StructDef](#class-structdef)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addStruct("S_m", "S")
    let st = StructType.get(def, [])
    println(st.structDef.srcCodeName)
}
```

运行结果：

```text
S
```

### static func get(StructDef, Array\<Type>)

```cangjie
public static func get(def: StructDef, genericTypeParams: Array<Type>): StructType
```

功能：按结构体定义与泛型实参取得或创建缓存实例。

参数：

- def: StructDef - 结构体定义。
- genericTypeParams: Array\<Type> - 泛型实参。

返回值：

- [StructType](#class-structtype) - 实例化结构体类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addStruct("S_m", "S")
    let st = StructType.get(def, [])
    println(st.structDef.srcCodeName)
}
```

运行结果：

```text
S
```

### operator func ==(StructType)

```cangjie
public operator func ==(other: StructType): Bool
```

功能：比较是否为同一实例化结构体类型。

参数：

- other: StructType - 另一结构体类型。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addStruct("S_m", "S")
    let st1 = StructType.get(def, [])
    let st2 = StructType.get(def, [])
    println("op_eq_StructType: ${st1 == st2}")
}
```

运行结果：

```text
op_eq_StructType: true
```

## class ThisType

```cangjie
public class ThisType <: Type & Equatable<ThisType> {}
```

功能：类/结构体体内的 **`This`** 类型，单例。

父类型：

- [Type](#class-type)
- Equatable\<[ThisType](#class-thistype)>

### static func get()

```cangjie
public static func get(): ThisType
```

功能：返回 `This` 类型的唯一单例。

返回值：

- [ThisType](#class-thistype) - 单例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("static_get: ${ThisType.get().toString().size > 0}")
}
```

运行结果：

```text
static_get: true
```

### operator func ==(ThisType)

```cangjie
public operator func ==(_: ThisType): Bool
```

功能：与另一 `ThisType` 比较（单例恒等）。

参数：

- _: ThisType - 另一实例。

返回值：

- Bool - 恒为 `true`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t1 = ThisType.get()
    let t2 = ThisType.get()
    println("op_eq_ThisType: ${t1 == t2}")
}
```

运行结果：

```text
op_eq_ThisType: true
```

## class TupleType

```cangjie
public class TupleType <: Type & Equatable<TupleType> {}
```

功能：元组类型；按元素类型序列签名缓存。

父类型：

- [Type](#class-type)
- Equatable\<[TupleType](#class-tupletype)>

### prop elementTypes

```cangjie
public prop elementTypes: Array<Type>
```

功能：元组各位置上的类型。

类型：Array\<Type>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let u = UnitType.get()
    let tup = TupleType.get([IntType.getInt32(), u])
    println("${tup.elementTypes.size}")
}
```

运行结果：

```text
2
```

### static func get(Array\<Type>)

```cangjie
public static func get(elementTypes: Array<Type>): TupleType
```

功能：按元素类型序列取得或创建唯一元组类型。

参数：

- elementTypes: Array\<Type> - 从左到右的元素类型。

返回值：

- [TupleType](#class-tupletype) - 元组类型实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let tup = TupleType.get([IntType.getInt32()])
    println("${tup.elementTypes.size}")
}
```

运行结果：

```text
1
```

### func toString()

```cangjie
public func toString(): String
```

功能：元组类型的字符串表示。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let tup = TupleType.get([IntType.getUInt32()])
    println(tup.toString())
}
```

运行结果：

```text
Tuple(UInt32)
```

### operator func ==(TupleType)

```cangjie
public operator func ==(other: TupleType): Bool
```

功能：按元素类型序列比较是否相同。

参数：

- other: TupleType - 另一元组类型。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let u = UnitType.get()
    let t1 = TupleType.get([IntType.getInt32(), u])
    let t2 = TupleType.get([IntType.getInt32(), u])
    println("op_eq_TupleType: ${t1 == t2}")
}
```

运行结果：

```text
op_eq_TupleType: true
```

## class Type

```cangjie
sealed abstract class Type <: ToString & Hashable & Equatable<Type> {}
```

功能：类型系统中所有类型的抽象基类。该类提供了类型的基础功能，包括相等性比较、哈希计算和字符串转换。

父类型：

- ToString
- Hashable
- Equatable\<[Type](#class-type)>

### prop qualifiedName

```cangjie
public prop qualifiedName: String
```

功能：类型的限定名（用于调试与展示，具体规则见源码中 `qualifiedName` 的 `match` 分支）。

类型：String

### prop typeArgs

```cangjie
public prop typeArgs: Array<Type>
```

功能：该类型的类型参数/子类型实参列表（依具体 `TypeKind` 而定）。

返回值：

- Array\<[Type](#class-type)> - 类型参数数组。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    println("类型参数数量: ${intType.typeArgs.size}")
}
```

运行结果：

```text
类型参数数量: 0
```

### func dump()

```cangjie
public func dump(): Unit
```

功能：将类型的字符串表示打印到标准输出。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    intType.dump()
}
```

运行结果：

```text
Int32
```

### func hashCode()

```cangjie
public func hashCode(): Int64
```

功能：获取该类型的哈希码。

返回值：

- Int64 - 类型的哈希码。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    println("哈希码: ${intType.hashCode()}")
}
```

运行结果：

```text
哈希码: -7959616418923165251
```

### func isBoolType()

```cangjie
public func isBoolType(): Bool
```

功能：检查该类型是否为布尔类型。

返回值：

- Bool - 如果类型是 Bool 则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let boolType = BoolType.get()
    let intType = IntType.getInt32()
    println("BoolType 是布尔类型: ${boolType.isBoolType()}")
    println("Int32 是布尔类型: ${intType.isBoolType()}")
}
```

运行结果：

```text
BoolType 是布尔类型: true
Int32 是布尔类型: false
```

### func isBuiltinType()

```cangjie
public func isBuiltinType(): Bool
```

功能：是否为内建类型（Int、Float、Bool、Rune、Unit、Nothing、RawArray、VArray、CPointer、CString 等）。

返回值：

- Bool - 为内建类型时返回 true，否则返回 false。

### func isFloatType()

```cangjie
public func isFloatType(): Bool
```

功能：检查该类型是否为浮点类型。

返回值：

- Bool - 如果类型是 Float16、Float32 或 Float64 则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let floatType = FloatType.getFloat32()
    let intType = IntType.getInt32()
    println("Float32 是浮点类型: ${floatType.isFloatType()}")
    println("Int32 是浮点类型: ${intType.isFloatType()}")
}
```

运行结果：

```text
Float32 是浮点类型: true
Int32 是浮点类型: false
```

### func isIntType()

```cangjie
public func isIntType(): Bool
```

功能：检查该类型是否为整数类型（有符号或无符号）。

返回值：

- Bool - 如果类型是任何整数类型则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let floatType = FloatType.getFloat32()
    println("Int32 是整数类型: ${intType.isIntType()}")
    println("Float32 是整数类型: ${floatType.isIntType()}")
}
```

运行结果：

```text
Int32 是整数类型: true
Float32 是整数类型: false
```

### func isNothingType()

```cangjie
public func isNothingType(): Bool
```

功能：检查该类型是否为 Nothing 类型。

返回值：

- Bool - 如果类型是 Nothing 则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let nothingType = NothingType.get()
    let intType = IntType.getInt32()
    println("NothingType 是 Nothing 类型: ${nothingType.isNothingType()}")
    println("Int32 是 Nothing 类型: ${intType.isNothingType()}")
}
```

运行结果：

```text
NothingType 是 Nothing 类型: true
Int32 是 Nothing 类型: false
```

### func isNumericType()

```cangjie
public func isNumericType(): Bool
```

功能：检查该类型是否为数值类型（整数或浮点数）。

返回值：

- Bool - 如果类型是数值类型则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let floatType = FloatType.getFloat32()
    let boolType = BoolType.get()
    println("Int32 是数值类型: ${intType.isNumericType()}")
    println("Float32 是数值类型: ${floatType.isNumericType()}")
    println("Bool 是数值类型: ${boolType.isNumericType()}")
}
```

运行结果：

```text
Int32 是数值类型: true
Float32 是数值类型: true
Bool 是数值类型: false
```

### func isPrimitiveType()

```cangjie
public func isPrimitiveType(): Bool
```

功能：检查该类型是否为原始类型。

返回值：

- Bool - 如果类型是原始类型（int、float、bool、rune、unit 或 nothing）则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let boolType = BoolType.get()
    println("Int32 是原始类型: ${intType.isPrimitiveType()}")
    println("Bool 是原始类型: ${boolType.isPrimitiveType()}")
}
```

运行结果：

```text
Int32 是原始类型: true
Bool 是原始类型: true
```

### func isRefType()

```cangjie
public func isRefType(): Bool
```

功能：检查该类型是否为引用类型。

返回值：

- Bool - 如果类型是引用类型则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let refType = RefType.get(intType)
    println("Int32 是引用类型: ${intType.isRefType()}")
    println("Int32& 是引用类型: ${refType.isRefType()}")
}
```

运行结果：

```text
Int32 是引用类型: false
Int32& 是引用类型: true
```

### func isRuneType()

```cangjie
public func isRuneType(): Bool
```

功能：检查该类型是否为 Rune 类型。

返回值：

- Bool - 如果类型是 Rune 则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let runeType = RuneType.get()
    let intType = IntType.getInt32()
    println("RuneType 是 Rune 类型: ${runeType.isRuneType()}")
    println("Int32 是 Rune 类型: ${intType.isRuneType()}")
}
```

运行结果：

```text
RuneType 是 Rune 类型: true
Int32 是 Rune 类型: false
```

### func isSignedIntType()

```cangjie
public func isSignedIntType(): Bool
```

功能：检查该类型是否为有符号整数类型。

返回值：

- Bool - 如果类型是有符号整数类型则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let uintType = IntType.getUInt32()
    println("Int32 是有符号整数: ${intType.isSignedIntType()}")
    println("UInt32 是有符号整数: ${uintType.isSignedIntType()}")
}
```

运行结果：

```text
Int32 是有符号整数: true
UInt32 是有符号整数: false
```

### func isUnitType()

```cangjie
public func isUnitType(): Bool
```

功能：检查该类型是否为 Unit 类型。

返回值：

- Bool - 如果类型是 Unit 则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let unitType = UnitType.get()
    let intType = IntType.getInt32()
    println("UnitType 是 Unit 类型: ${unitType.isUnitType()}")
    println("Int32 是 Unit 类型: ${intType.isUnitType()}")
}
```

运行结果：

```text
UnitType 是 Unit 类型: true
Int32 是 Unit 类型: false
```

### func isUnsignedIntType()

```cangjie
public func isUnsignedIntType(): Bool
```

功能：检查该类型是否为无符号整数类型。

返回值：

- Bool - 如果类型是无符号整数类型则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let uintType = IntType.getUInt32()
    println("Int32 是无符号整数: ${intType.isUnsignedIntType()}")
    println("UInt32 是无符号整数: ${uintType.isUnsignedIntType()}")
}
```

运行结果：

```text
Int32 是无符号整数: false
UInt32 是无符号整数: true
```

### func isAnyTypeInStd()

```cangjie
public func isAnyTypeInStd(): Bool
```

功能：是否为 std 包中的 Any 类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isBoxType()

```cangjie
public func isBoxType(): Bool
```

功能：是否为 BoxType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isBoxRefTypeOf(Type)

```cangjie
public func isBoxRefTypeOf(other: Type): Bool
```

功能：是否为 other 的 Box 引用类型。

参数：

- other: Type - 待比较的类型。

返回值：

- Bool - 是 other 的 Box 引用类型则为 `true`，否则为 `false`。

### func isCFuncType()

```cangjie
public func isCFuncType(): Bool
```

功能：是否为 C 函数类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isCPointerType()

```cangjie
public func isCPointerType(): Bool
```

功能：是否为 CPointer 类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isCStringType()

```cangjie
public func isCStringType(): Bool
```

功能：是否为 CString 类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isCTypeInStd()

```cangjie
public func isCTypeInStd(): Bool
```

功能：是否为 std 包中的 C 类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isClassLikeType()

```cangjie
public func isClassLikeType(): Bool
```

功能：是否为 ClassLikeType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isClosureType()

```cangjie
public func isClosureType(): Bool
```

功能：是否为闭包类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isClosureBaseType()

```cangjie
public func isClosureBaseType(): Bool
```

功能：是否为闭包基类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isClosureGenericBaseType()

```cangjie
public func isClosureGenericBaseType(): Bool
```

功能：是否为闭包泛型基类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isClosureInstBaseType()

```cangjie
public func isClosureInstBaseType(): Bool
```

功能：是否为闭包实例化基类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isCustomType()

```cangjie
public func isCustomType(): Bool
```

功能：是否为 CustomType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isEnumType()

```cangjie
public func isEnumType(): Bool
```

功能：是否为 EnumType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isFuncType()

```cangjie
public func isFuncType(): Bool
```

功能：是否为 FuncType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isGenericType()

```cangjie
public func isGenericType(): Bool
```

功能：是否为 GenericType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isGenericRelated()

```cangjie
public func isGenericRelated(): Bool
```

功能：是否与泛型相关。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isReferenceType()

```cangjie
public func isReferenceType(): Bool
```

功能：是否为引用类型（ClassLikeType、RawArrayType、BoxType 或 ThisType）。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isRawArrayType()

```cangjie
public func isRawArrayType(): Bool
```

功能：是否为 RawArray 类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isStructType()

```cangjie
public func isStructType(): Bool
```

功能：是否为 StructType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isThisType()

```cangjie
public func isThisType(): Bool
```

功能：是否为 ThisType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isTupleType()

```cangjie
public func isTupleType(): Bool
```

功能：是否为 TupleType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isValueType()

```cangjie
public func isValueType(): Bool
```

功能：是否为值类型。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func isVArrayType()

```cangjie
public func isVArrayType(): Bool
```

功能：是否为 VArrayType。

返回值：

- Bool - 是则为 `true`，否则为 `false`。

### func satisfyCType()

```cangjie
public func satisfyCType(): Bool
```

功能：是否满足 C 类型约束。

返回值：

- Bool - 满足则为 `true`，否则为 `false`。

### func isEqualOrSubTypeOf(Type, ArrayList<(Type, Type)>)

```cangjie
public func isEqualOrSubTypeOf(parent: Type, visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Bool
```

功能：判断是否为 parent 的相等或子类型。

参数：

- parent: Type - 待比较的父类型。
- visited!: ArrayList<(Type, Type)> - 环检测用访问表；一般可传默认空表。

返回值：

- Bool - 是 parent 的相等或子类型则为 `true`，否则为 `false`。

### func isEqualOrInstantiatedTypeOf(Type, ArrayList<(Type, Type)>)

```cangjie
public func isEqualOrInstantiatedTypeOf(genericRelatedType: Type, visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Bool
```

功能：判断是否为 genericRelatedType 的相等或实例化类型。

参数：

- genericRelatedType: Type - 待比较的泛型关联类型。
- visited!: ArrayList<(Type, Type)> - 环检测用访问表；一般可传默认空表。

返回值：

- Bool - 是 genericRelatedType 的相等或实例化类型则为 `true`，否则为 `false`。

### func satisfyGenericConstraints(GenericType, HashMap<GenericType, Type>, ArrayList<(Type, Type)>)

```cangjie
public func satisfyGenericConstraints(gType: GenericType, instMap: HashMap<GenericType, Type>, visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Bool
```

功能：判断是否满足泛型约束。

参数：

- gType: GenericType - 泛型类型。
- instMap: HashMap<GenericType, Type> - 泛型实例化映射表。
- visited!: ArrayList<(Type, Type)> - 环检测用访问表；一般可传默认空表。

返回值：

- Bool - 满足泛型约束则为 `true`，否则为 `false`。

### operator func ==(Type)

```cangjie
public operator func ==(other: Type): Bool
```

功能：检查该类型是否与另一个类型相等。

参数：

- other: Type - 要比较的类型。

返回值：

- Bool - 如果类型具有相同的种类和类型参数则返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let type1 = IntType.getInt32()
    let type2 = IntType.getInt32()
    let type3 = IntType.getInt64()
    println("type1 == type2: ${type1 == type2}")
    println("type1 == type3: ${type1 == type3}")
}
```

运行结果：

```text
type1 == type2: true
type1 == type3: false
```

### func stripAllRefs()

```cangjie
public func stripAllRefs(): Type
```

功能：去除该类型的所有引用包装。

递归地移除所有 Ref 类型包装，直到到达非引用类型。

返回值：

- [Type](#class-type) - 去除所有引用包装后的基类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let refType = RefType.get(intType)
    let baseType = refType.stripAllRefs()
    println("引用类型: ${refType.toString()}")
    println("去除引用后: ${baseType.toString()}")
}
```

运行结果：

```text
引用类型: Int32&
去除引用后: Int32
```

### func toString()

```cangjie
public open func toString(): String
```

功能：将类型转换为字符串表示。

返回值：

- String - 类型的字符串表示。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    println("类型: ${intType.toString()}")
}
```

运行结果：

```text
类型: Int32
```

## class UnitType

```cangjie
public class UnitType <: BuiltinType & Equatable<UnitType> {}
```

功能：表示类型系统中的 Unit 类型。该类型表示没有有意义的值，类似于 C 语言中的 void。

父类型：

- [BuiltinType](#class-builtintype)
- Equatable\<[UnitType](#class-unittype)>

### static func get()

```cangjie
public static func get(): UnitType
```

功能：获取 UnitType 的单例实例。

返回值：

- [UnitType](#class-unittype) - UnitType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let unitType = UnitType.get()
    println("Unit 类型: ${unitType.toString()}")
}
```

运行结果：

```text
Unit 类型: Unit
```

### operator func ==(UnitType)

```cangjie
public operator func ==(_: UnitType): Bool
```

功能：检查该 UnitType 是否与另一个 UnitType 相等。

参数：

- _: UnitType - 要比较的另一个 UnitType（未使用，始终返回 true）。

返回值：

- Bool - 始终返回 true，因为所有 UnitType 实例都相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let unitType1 = UnitType.get()
    let unitType2 = UnitType.get()
    println("两个 UnitType 相等: ${unitType1 == unitType2}")
}
```

运行结果：

```text
两个 UnitType 相等: true
```

## class VArrayType

```cangjie
public class VArrayType <: BuiltinType & Equatable<VArrayType> {}
```

功能：**定长 VArray** 类型 `VArray<T, $n>`，编译期固定长度。按 `(elementType, size)` 缓存唯一实例。

父类型：

- [BuiltinType](#class-builtintype)
- Equatable\<[VArrayType](#class-varraytype)>

### prop elementType

```cangjie
public prop elementType: Type
```

功能：元素类型。

类型：Type

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v = VArrayType.get(IntType.getUInt32(), 4)
    println(v.elementType.toString())
}
```

运行结果：

```text
UInt32
```

### prop size

```cangjie
public prop size: Int64
```

功能：编译期固定长度。

类型：Int64

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v = VArrayType.get(IntType.getInt32(), 8)
    println("${v.size}")
}
```

运行结果：

```text
8
```

### static func get(Type, Int64)

```cangjie
public static func get(elementType: Type, size: Int64): VArrayType
```

功能：获取或创建 VArray 类型。

返回值：

- [VArrayType](#class-varraytype) - VArrayType 实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v = VArrayType.get(IntType.getInt32(), 8)
    println("static_get: ${v.toString().size > 0}")
}
```

运行结果：

```text
static_get: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：定长 VArray 的字符串表示。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v = VArrayType.get(IntType.getInt32(), 2)
    println(v.toString())
}
```

运行结果：

```text
VArray<Int32, $2>
```

### operator func ==(VArrayType)

```cangjie
public operator func ==(other: VArrayType): Bool
```

功能：比较元素类型与长度是否一致。

参数：

- other: VArrayType - 另一 VArray 类型。

返回值：

- Bool - 是否相等。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v1 = VArrayType.get(IntType.getInt32(), 8)
    let v2 = VArrayType.get(IntType.getInt32(), 8)
    println("op_eq_VArrayType: ${v1 == v2}")
}
```

运行结果：

```text
op_eq_VArrayType: true
```

## class CHIRException

```cangjie
public class CHIRException <: Exception {
    public init()
    public init(message: String)
}
```

功能：CHIR 构建或 IR 状态不一致时抛出的检查型异常。

父类型：

- Exception

### init()

```cangjie
public init()
```

功能：构造一个无详细消息的 `CHIRException`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let e = CHIRException()
    println("init_no_msg: ${e.toString().size > 0}")
}
```

运行结果：

```text
init_no_msg: true
```

### init(String)

```cangjie
public init(message: String)
```

功能：构造一个带详细消息的 `CHIRException`。

参数：

- message: String - 人类可读的错误描述文本。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let e = CHIRException("invalid IR")
    println("init_with_msg: ${e.toString().size > 0}")
}
```

运行结果：

```text
init_with_msg: true
```

## class FuncSigInfo

```cangjie
public class FuncSigInfo {
    public init(name: String, ty: FuncType)
    public init(name: String, ty: FuncType, genericTypeParams: Array<GenericType>)
}
```

功能：函数符号的轻量签名包（名称、函数类型、泛型形参），用于描述函数调用的目标签名信息。

### init(String, FuncType)

```cangjie
public init(name: String, ty: FuncType)
```

功能：构造一个不含泛型形参的 `FuncSigInfo`；`genericTypeParams` 初始为空数组。

参数：

- name: String - 符号的逻辑名或混淆名。
- ty: [FuncType](#class-functype) - 函数类型（形参列表与返回类型）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let ft = FuncType.get([i32], i32)
    let sig = FuncSigInfo("foo", ft)
    println("init_no_generic: ${sig.name}")
}
```

运行结果：

```text
init_no_generic: foo
```

### init(String, FuncType, Array\<GenericType>)

```cangjie
public init(name: String, ty: FuncType, genericTypeParams: Array<GenericType>)
```

功能：构造一个带泛型形参的 `FuncSigInfo`。

参数：

- name: String - 符号的逻辑名或混淆名。
- ty: [FuncType](#class-functype) - 函数类型（形参列表与返回类型）。
- genericTypeParams: Array\<[GenericType](#class-generictype)> - 泛型形参列表（声明顺序）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let ft = FuncType.get([i32], i32)
    let g = GenericType.get("pkg:T", "T")
    let sig = FuncSigInfo("bar", ft, [g])
    println("init_with_generic: ${sig.genericTypeParams.size}")
}
```

运行结果：

```text
init_with_generic: 1
```

### prop genericTypeParams

```cangjie
public prop genericTypeParams: Array<GenericType>
```

功能：附在此签名上的泛型形参列表。

类型：Array\<[GenericType](#class-generictype)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let ft = FuncType.get([i32], i32)
    let g = GenericType.get("pkg:T", "T")
    let sig = FuncSigInfo("m", ft, [g])
    println("${sig.genericTypeParams.size}")
}
```

运行结果：

```text
1
```

### prop name

```cangjie
public prop name: String
```

功能：符号的显示名或混淆名。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("myFunc", ft)
    println(sig.name)
}
```

运行结果：

```text
myFunc
```

### prop ty

```cangjie
public prop ty: FuncType
```

功能：该签名的函数类型。

类型：[FuncType](#class-functype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let ft = FuncType.get([i32], i32)
    let sig = FuncSigInfo("f", ft)
    println(sig.ty.toString())
}
```

运行结果：

```text
(Int32) -> Int32
```

### func dump()

```cangjie
public func dump(): Unit
```

功能：将签名信息输出到标准输出（调用 `toString()` 后打印）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let ft = FuncType.get([i32], i32)
    let sig = FuncSigInfo("g", ft)
    sig.dump()
}
```

运行结果：

```text
g(Int32) -> Int32
```

### func toString()

```cangjie
public func toString(): String
```

功能：渲染为 `name<generics>(params) -> ret` 的单行文本形式，便于日志与调试。

返回值：

- String - 签名的文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let ft = FuncType.get([i32], UnitType.get())
    let g = GenericType.get("pkg:T", "T")
    let sig = FuncSigInfo("h", ft, [g])
    println(sig.toString())
}
```

运行结果：

```text
h<Generic-pkg:T>(Int32) -> Unit
```

## class CHIRVisitor

```cangjie
public abstract class CHIRVisitor {}
```

功能：CHIR 函数、块组、基本块与嵌套表达式的**抽象访问器**。子类可重写 [`action`](#func-actionexpression) 以观察每个表达式节点；`walk` 方法递归遍历直至返回 `IRActionMode.Stop`。

### func walk(Function)

```cangjie
public func walk(f: Function): Unit
```

功能：遍历给定函数的体（若存在）；内部依次访问体中所有块组。

参数：

- f: [Function](#class-function) - 待遍历的函数。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("walk_Function: ${f.body.isNone()}")
}
```

运行结果：

```text
walk_Function: true
```

### func walk(BlockGroup)

```cangjie
public func walk(bg: BlockGroup): Unit
```

功能：按顺序遍历块组中的每个基本块；遇到 `STOP` 状态时提前终止。

参数：

- bg: [BlockGroup](#class-blockgroup) - 待遍历的块组。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    if (let Some(bg) <- f.body) {
        println("${bg.blocks.size}")
    } else {
        println("0")
    }
}
```

运行结果：

```text
0
```

### func walk(Block)

```cangjie
public func walk(b: Block): Unit
```

功能：遍历基本块中的每个表达式，并递归访问表达式内的嵌套块组；遇到 `STOP` 状态时提前终止。

参数：

- b: [Block](#class-block) - 待遍历的基本块。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    if (let Some(bg) <- f.body) {
        if (bg.blocks.size > 0) {
            println("${bg.blocks[0].exprs.size}")
        } else {
            println("0")
        }
    } else {
        println("0")
    }
}
```

运行结果：

```text
0
```

### func action(Expression)

```cangjie
public open func action(ty: Expression): IRActionMode
```

功能：对每个访问到的表达式节点调用，决定是否继续遍历。默认返回 `IRActionMode.Continue`；子类可重写以实现自定义观察逻辑或提前终止。

参数：

- ty: Expression - 当前表达式节点。

返回值：

- [IRActionMode](chir_package_enums.md#enum-iractionmode) - 访问器控制模式（`Continue` 继续遍历，`Stop` 终止遍历，`Skip` 跳过嵌套 BlockGroup）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

class MyVisitor <: CHIRVisitor {
    public open func action(ty: Expression): IRActionMode {
        println(ty.toString().size > 0)
        return IRActionMode.Continue
    }
}

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    let v = MyVisitor()
    v.walk(f)
    println("visitor_done")
}
```

运行结果：

```text
visitor_done
```

## class FuncCallContext

```cangjie
public class FuncCallContext {
    public init(args: Array<Value>, instTypeArgs: Array<Type>, objType: ?Type)
}
```

功能：函数调用上下文，封装实参值列表、实例化类型实参以及可选的调用对象类型。

### init(Array\<Value>, Array\<Type>, ?Type)

```cangjie
public init(args: Array<Value>, instTypeArgs: Array<Type>, objType: ?Type)
```

功能：构造一个 `FuncCallContext`，指定实参列表、实例化类型实参和调用对象类型。

参数：

- args: Array\<Value> - 函数调用的实参值列表。
- instTypeArgs: Array\<[Type](#class-type)> - 实例化泛型实参列表。
- objType: ?[Type](#class-type) - 调用对象类型（静态调用时为 `None`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ctx = FuncCallContext([], [], None)
    println("init_FuncCallContext: ${ctx.args.size}")
}
```

运行结果：

```text
init_FuncCallContext: 0
```

### prop args

```cangjie
public prop args: Array<Value>
```

功能：函数调用的实参值列表。

类型：Array\<Value>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ctx = FuncCallContext([], [], None)
    println("${ctx.args.size}")
}
```

运行结果：

```text
0
```

### prop instTypeArgs

```cangjie
public prop instTypeArgs: Array<Type>
```

功能：实例化泛型实参列表。

类型：Array\<[Type](#class-type)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ctx = FuncCallContext([], [], None)
    println("${ctx.instTypeArgs.size}")
}
```

运行结果：

```text
0
```

### prop objType

```cangjie
public prop objType: ?Type
```

功能：调用对象类型；静态调用时为 `None`。

类型：?[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ctx = FuncCallContext([], [], None)
    println("prop_objType: ${ctx.objType.isNone()}")
}
```

运行结果：

```text
prop_objType: true
```

### func setArg(Int64, Value)

```cangjie
public func setArg(index: Int64, arg: Value): Unit
```

功能：设置指定位置的参数值。

参数：

- index: Int64 - 参数位置索引。
- arg: Value - 新的参数值。

### func setInstTypeArg(Int64, Type)

```cangjie
public func setInstTypeArg(index: Int64, arg: Type): Unit
```

功能：设置指定位置的实例化类型参数。

参数：

- index: Int64 - 参数位置索引。
- arg: [Type](#class-type) - 新的实例化类型参数。

## class InvokeCallContext

```cangjie
public class InvokeCallContext {
    public init(caller: Value, virMethodCtx: FuncSigInfo, funcCallCtx: FuncCallContext)
}
```

功能：虚方法调用上下文，封装调用者值、虚方法签名信息以及函数调用上下文。

### init(Value, FuncSigInfo, FuncCallContext)

```cangjie
public init(caller: Value, virMethodCtx: FuncSigInfo, funcCallCtx: FuncCallContext)
```

功能：构造一个 `InvokeCallContext`，指定调用者、虚方法签名信息和函数调用上下文。

参数：

- caller: Value - 调用者值（即接收对象）。
- virMethodCtx: [FuncSigInfo](#class-funcsiginfo) - 被调虚方法的签名信息。
- funcCallCtx: [FuncCallContext](#class-funccallcontext) - 函数调用的实参与类型实参上下文。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("method", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    println("init_InvokeCallContext: done")
}
```

运行结果：

```text
init_InvokeCallContext: done
```

### prop caller

```cangjie
public prop caller: Value
```

功能：调用者值（即虚方法调用的接收对象）。

类型：Value

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("m", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    println("prop_caller: ${ctx.caller.toString().size > 0}")
}
```

运行结果：

```text
prop_caller: true
```

### prop virMethodCtx

```cangjie
public prop virMethodCtx: FuncSigInfo
```

功能：被调虚方法的签名信息。

类型：[FuncSigInfo](#class-funcsiginfo)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("m", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    println("prop_virMethodCtx: ${ctx.virMethodCtx.name}")
}
```

运行结果：

```text
prop_virMethodCtx: m
```

### prop funcCallCtx

```cangjie
public prop funcCallCtx: FuncCallContext
```

功能：函数调用的实参与类型实参上下文。

类型：[FuncCallContext](#class-funccallcontext)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("m", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    println("prop_funcCallCtx: ${ctx.funcCallCtx.args.size}")
}
```

运行结果：

```text
prop_funcCallCtx: 0
```

## class Value

```cangjie
sealed abstract class Value <: ToString & Hashable & Equatable<Value> {}
```

功能：CHIR 中所有值的抽象基类，涵盖基本块、基本块组、函数、全局变量、局部变量、参数与字面量等。提供标识符、类型、使用者列表等公共信息，以及判等、哈希与类型判断能力。

父类型：

- ToString
- Hashable
- Equatable\<[Value](#class-value)>

### prop identifier

```cangjie
public mut prop identifier: String
```

功能：值的标识符（可包含前缀，如全局符号前缀、基本块前缀、局部变量前缀等）；可读可写。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_identifier: ${f.identifier}")
}
```

运行结果：

```text
prop_identifier: @f_m
```

### prop identifierWithoutPrefix

```cangjie
public prop identifierWithoutPrefix: String
```

功能：去除内置前缀（全局符号前缀、基本块前缀、局部变量前缀）后的标识符。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_identifierWithoutPrefix: ${f.identifierWithoutPrefix}")
}
```

运行结果：

```text
prop_identifierWithoutPrefix: f_m
```

### prop ty

```cangjie
public mut prop ty: Type
```

功能：值的类型；可读可写。

类型：[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_ty: ${f.ty.qualifiedName}")
}
```

运行结果：

```text
prop_ty: ()->Unit
```

### prop users

```cangjie
public prop users: Array<Expression>
```

功能：引用该值作为操作数的表达式列表（使用者列表）。

类型：Array\<[Expression](#class-expression)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_users: ${f.users.size}")
}
```

运行结果：

```text
prop_users: 0
```

### func dump()

```cangjie
public func dump(): Unit
```

功能：将该值的字符串表示打印到标准输出。

示例：

<!-- run -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.dump()
}
```

### func hashCode()

```cangjie
public func hashCode(): Int64
```

功能：获取该值的哈希码。

返回值：

- Int64 - 值的哈希码。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_hashCode: ${f.hashCode() == f.hashCode()}")
}
```

运行结果：

```text
func_hashCode: true
```

### func isBlock()

```cangjie
public func isBlock(): Bool
```

功能：判断该值是否为基本块（[Block](#class-block)）。

返回值：

- Bool - 为基本块时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isBlock: ${f.isBlock()}")
}
```

运行结果：

```text
func_isBlock: false
```

### func isBlockGroup()

```cangjie
public func isBlockGroup(): Bool
```

功能：判断该值是否为基本块组（[BlockGroup](#class-blockgroup)）。

返回值：

- Bool - 为基本块组时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isBlockGroup: ${f.isBlockGroup()}")
}
```

运行结果：

```text
func_isBlockGroup: false
```

### func isFunction()

```cangjie
public func isFunction(): Bool
```

功能：判断该值是否为函数（[Function](#class-function)）。

返回值：

- Bool - 为函数时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isFunction: ${f.isFunction()}")
}
```

运行结果：

```text
func_isFunction: true
```

### func isGlobalVar()

```cangjie
public func isGlobalVar(): Bool
```

功能：判断该值是否为全局变量（[GlobalVar](#class-globalvar)）。

返回值：

- Bool - 为全局变量时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isGlobalVar: ${f.isGlobalVar()}")
}
```

运行结果：

```text
func_isGlobalVar: false
```

### func isLiteral()

```cangjie
public func isLiteral(): Bool
```

功能：判断该值是否为字面量（[LiteralValue](#class-literalvalue) 的子类）。

返回值：

- Bool - 为字面量时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isLiteral: ${f.isLiteral()}")
}
```

运行结果：

```text
func_isLiteral: false
```

### func isLocalVar()

```cangjie
public func isLocalVar(): Bool
```

功能：判断该值是否为局部变量（[LocalVar](#class-localvar)）。

返回值：

- Bool - 为局部变量时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isLocalVar: ${f.isLocalVar()}")
}
```

运行结果：

```text
func_isLocalVar: false
```

### func isParameter()

```cangjie
public func isParameter(): Bool
```

功能：判断该值是否为函数参数（[Parameter](#class-parameter)）。

返回值：

- Bool - 为参数时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isParameter: ${f.isParameter()}")
}
```

运行结果：

```text
func_isParameter: false
```

### func replaceWith(Value)

```cangjie
public func replaceWith(other: Value): Unit
```

功能：在所有使用该值的表达式中，将该值替换为另一值。

参数：

- other: [Value](#class-value) - 替换后的新值。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt64()], IntType.getInt64()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let p0 = f.parameters[0]
    let lit = IntLiteral.get(IntType.getInt64(), 1)
    builder.createBinaryAdd(p0, lit, OverflowStrategy.NA)
    let lit2 = IntLiteral.get(IntType.getInt64(), 2)
    p0.replaceWith(lit2)
    println("func_replaceWith: ${block.exprs.size}")
}
```

运行结果：

```text
func_replaceWith: 1
```

### operator func ==(Value)

```cangjie
public operator func ==(other: Value): Bool
```

功能：引用比较，判断两个 Value 是否为同一实例。

参数：

- other: [Value](#class-value) - 另一值。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("op_eq_Value: ${f == f}")
}
```

运行结果：

```text
op_eq_Value: true
```

## class Block

```cangjie
public class Block <: Value & Equatable<Block> {}
```

功能：表示 CHIR 中的**基本块**，是函数体内控制流的基本单元。每个基本块包含一系列表达式，并可与前驱基本块形成控制流图；设置 `exceptions` 后可标记为异常处理 landing pad 块。

父类型：

- Value
- Equatable\<Block>

### prop exceptions

```cangjie
public mut prop exceptions: Array<ClassLikeType>
```

功能：异常类型列表；设置此属性后基本块即成为异常处理 landing pad 块。初始状态下内部为 `None`，需先赋值后方可读取。

类型：Array\<ClassLikeType>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    block.exceptions = []
    println("mut_prop_exceptions: ${block.exceptions.size}")
}
```

运行结果：

```text
mut_prop_exceptions: 0
```

### prop exprs

```cangjie
public prop exprs: Array<Expression>
```

功能：基本块内表达式列表。

类型：Array\<Expression>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    println("prop_exprs: ${block.exprs.size}")
}
```

运行结果：

```text
prop_exprs: 0
```

### prop isLandingPadBlock

```cangjie
public prop isLandingPadBlock: Bool
```

功能：是否为异常处理 landing pad 块；当 `exceptions` 已被赋值（内部为 `Some`）时返回 `true`。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    println("prop_isLandingPadBlock: ${block.isLandingPadBlock}")
}
```

运行结果：

```text
prop_isLandingPadBlock: false
```

### prop owner

```cangjie
public prop owner: BlockGroup
```

功能：所属 BlockGroup。

类型：[BlockGroup](#class-blockgroup)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    println("prop_owner: ${block.owner == f.body.getOrThrow()}")
}
```

运行结果：

```text
prop_owner: true
```

### prop predecessors

```cangjie
public prop predecessors: Array<Block>
```

功能：前驱基本块列表。

类型：Array\<Block>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    println("prop_predecessors: ${block.predecessors.size}")
}
```

运行结果：

```text
prop_predecessors: 0
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

功能：所属顶层函数。

类型：[Function](#class-function)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    println("prop_topLevelFunc: ${block.topLevelFunc == f}")
}
```

运行结果：

```text
prop_topLevelFunc: true
```

### func appendExpr(Expression)

```cangjie
public func appendExpr(expr: Expression): Unit
```

功能：向基本块末尾追加表达式。

参数：

- expr: Expression - 要追加的表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Constant.create(IntLiteral.get(IntType.getInt32(), 0))
    block.appendExpr(expr)
    println("fn_appendExpr: ${block.exprs.size}")
}
```

运行结果：

```text
fn_appendExpr: 1
```

### func destroySelf()

```cangjie
public func destroySelf(): Unit
```

功能：销毁自身并解除所有引用关系；销毁后该基本块从所属 BlockGroup 的 `blocks` 列表中移除，内部 `kind` 标记为 `Invalid`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let newBlock = bg.appendBlock()
    println("fn_destroySelf_before: ${bg.blocks.size}")
    newBlock.destroySelf()
    println("fn_destroySelf_after: ${bg.blocks.size}")
}
```

运行结果：

```text
fn_destroySelf_before: 2
fn_destroySelf_after: 1
```

### func insertExpr(Expression, Int64)

```cangjie
public func insertExpr(expr: Expression, at: Int64): Unit
```

功能：在指定位置插入表达式；`at` 超出范围时等同于追加到末尾。

参数：

- expr: Expression - 要插入的表达式。
- at: Int64 - 插入位置索引（0 起计）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr0 = Constant.create(IntLiteral.get(IntType.getInt32(), 0))
    let expr1 = Constant.create(IntLiteral.get(IntType.getInt32(), 1))
    block.appendExpr(expr0)
    block.insertExpr(expr1, 0)
    println("fn_insertExpr: ${block.exprs.size}")
}
```

运行结果：

```text
fn_insertExpr: 2
```

### func toString()

```cangjie
public func toString(): String
```

功能：基本块的字符串形式（包含标识、表达式列表等）。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    println("fn_toString: ${block.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### operator func ==(Block)

```cangjie
public operator func ==(other: Block): Bool
```

功能：引用比较，判断两个 Block 是否为同一实例。

参数：

- other: Block - 另一基本块。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    println("op_eq_Block: ${block == block}")
}
```

运行结果：

```text
op_eq_Block: true
```

## class BlockGroup

```cangjie
public class BlockGroup <: Value & Equatable<BlockGroup> {}
```

功能：表示 CHIR 中的**基本块组**，即函数体或 lambda 体的控制流图容器，包含若干基本块并维护入口块指针。

父类型：

- Value
- Equatable\<BlockGroup>

### prop blocks

```cangjie
public prop blocks: Array<Block>
```

功能：基本块列表。

类型：Array\<Block>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    println("prop_blocks: ${bg.blocks.size}")
}
```

运行结果：

```text
prop_blocks: 1
```

### prop entryBlock

```cangjie
public prop entryBlock: Block
```

功能：入口基本块；未设置时访问将抛出异常。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    println("prop_entryBlock: ${bg.entryBlock == bg.blocks[0]}")
}
```

运行结果：

```text
prop_entryBlock: true
```

### prop owner

```cangjie
public prop owner: Value
```

功能：所属父值（函数或 lambda 对应的局部变量）。

类型：Value

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    println("prop_owner: ${bg.owner == f}")
}
```

运行结果：

```text
prop_owner: true
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

功能：所属顶层函数。

类型：[Function](#class-function)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    println("prop_topLevelFunc: ${bg.topLevelFunc == f}")
}
```

运行结果：

```text
prop_topLevelFunc: true
```

### func appendBlock()

```cangjie
public func appendBlock(): Block
```

功能：追加并返回新的空基本块。

返回值：

- [Block](#class-block) - 新创建的基本块。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let newBlock = bg.appendBlock()
    println("fn_appendBlock: ${bg.blocks.size}")
}
```

运行结果：

```text
fn_appendBlock: 2
```

### func destroySelf()

```cangjie
public func destroySelf(): Unit
```

功能：销毁自身及下属基本块，并从所属函数或 lambda 中移除引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    println("fn_destroySelf_before: ${f.body.isSome()}")
}
```

运行结果：

```text
fn_destroySelf_before: true
```

### func setEntryBlock(Block)

```cangjie
public func setEntryBlock(block: Block): Unit
```

功能：设置入口基本块；要求该块已在当前 BlockGroup 的 `blocks` 列表中。

参数：

- block: Block - 要设为入口的基本块。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let newBlock = bg.appendBlock()
    bg.setEntryBlock(newBlock)
    println("fn_setEntryBlock: ${bg.entryBlock == newBlock}")
}
```

运行结果：

```text
fn_setEntryBlock: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：基本块组的字符串形式。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    println("fn_toString: ${bg.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### operator func ==(BlockGroup)

```cangjie
public operator func ==(other: BlockGroup): Bool
```

功能：引用比较，判断两个 BlockGroup 是否为同一实例。

参数：

- other: BlockGroup - 另一基本块组。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    println("op_eq_BlockGroup: ${bg == bg}")
}
```

运行结果：

```text
op_eq_BlockGroup: true
```

## class LiteralValue

```cangjie
sealed abstract class LiteralValue <: Value & Equatable<LiteralValue> {}
```

功能：CHIR 中编译期字面量值的抽象基类，是各类字面量（[BoolLiteral](#class-boolliteral)、[IntLiteral](#class-intliteral)、[FloatLiteral](#class-floatliteral) 等）的父类型。

父类型：

- [Value](#class-value)
- Equatable\<[LiteralValue](#class-literalvalue)>

### operator func ==(LiteralValue)

```cangjie
public operator func ==(other: LiteralValue): Bool
```

功能：引用比较，判断两个 LiteralValue 是否为同一实例。

参数：

- other: [LiteralValue](#class-literalvalue) - 另一字面量值。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getInt64(), 1)
    println("op_eq_LiteralValue: ${lit == lit}")
}
```

运行结果：

```text
op_eq_LiteralValue: true
```

## class BoolLiteral

```cangjie
public class BoolLiteral <: LiteralValue & Equatable<BoolLiteral> {}
```

功能：表示布尔字面量（`true` 或 `false`），按值缓存保证同一布尔值对应唯一实例。

父类型：

- LiteralValue
- Equatable\<BoolLiteral>

### prop value

```cangjie
public prop value: Bool
```

功能：布尔值。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = BoolLiteral.get(true)
    println("prop_value: ${lit.value}")
}
```

运行结果：

```text
prop_value: true
```

### static func get(Bool)

```cangjie
public static func get(value: Bool): BoolLiteral
```

功能：获取布尔字面量；同一布尔值始终返回同一缓存实例。

参数：

- value: Bool - 布尔值。

返回值：

- [BoolLiteral](#class-boolliteral) - 对应的布尔字面量。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = BoolLiteral.get(false)
    println(lit.toString())
}
```

运行结果：

```text
false
```

### func toString()

```cangjie
public func toString(): String
```

功能：字符串形式，即 `"true"` 或 `"false"`。

返回值：

- String - 布尔值的文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = BoolLiteral.get(true)
    println(lit.toString())
}
```

运行结果：

```text
true
```

### operator func ==(BoolLiteral)

```cangjie
public operator func ==(other: BoolLiteral): Bool
```

功能：引用比较，判断两个 BoolLiteral 是否为同一实例。

参数：

- other: BoolLiteral - 另一布尔字面量。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = BoolLiteral.get(true)
    let lit2 = BoolLiteral.get(true)
    println("op_eq_BoolLiteral: ${lit1 == lit2}")
}
```

运行结果：

```text
op_eq_BoolLiteral: true
```

## class FloatLiteral

```cangjie
public class FloatLiteral <: LiteralValue & Equatable<FloatLiteral> {}
```

功能：表示浮点字面量，按 `(FloatType, Float64)` 缓存保证同一类型与值对应唯一实例。

父类型：

- LiteralValue
- Equatable\<FloatLiteral>

### prop value

```cangjie
public prop value: Float64
```

功能：浮点值。

类型：Float64

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = FloatLiteral.get(FloatType.getFloat64(), 3.14)
    println("prop_value: ${lit.value}")
}
```

运行结果：

```text
prop_value: 3.140000
```

### static func get(FloatType, Float64)

```cangjie
public static func get(ty: FloatType, value: Float64): FloatLiteral
```

功能：获取浮点字面量；同一类型与值组合始终返回同一缓存实例。

参数：

- ty: FloatType - 浮点类型。
- value: Float64 - 浮点值。

返回值：

- [FloatLiteral](#class-floatliteral) - 对应的浮点字面量。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = FloatLiteral.get(FloatType.getFloat32(), 1.5)
    println(lit.toString())
}
```

运行结果：

```text
1.500000f
```

### func toString()

```cangjie
public func toString(): String
```

功能：字符串形式，为数值后缀 `"f"`（如 `3.14f`）。

返回值：

- String - 浮点值的文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = FloatLiteral.get(FloatType.getFloat64(), 2.0)
    println(lit.toString())
}
```

运行结果：

```text
2.000000f
```

### operator func ==(FloatLiteral)

```cangjie
public operator func ==(other: FloatLiteral): Bool
```

功能：引用比较，判断两个 FloatLiteral 是否为同一实例。

参数：

- other: FloatLiteral - 另一浮点字面量。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = FloatLiteral.get(FloatType.getFloat64(), 1.0)
    let lit2 = FloatLiteral.get(FloatType.getFloat64(), 1.0)
    println("op_eq_FloatLiteral: ${lit1 == lit2}")
}
```

运行结果：

```text
op_eq_FloatLiteral: true
```

## class GlobalValue

```cangjie
sealed abstract class GlobalValue <: Value & Equatable<GlobalValue> {}
```

功能：包级全局值（函数与全局变量）的抽象基类，提供所属包名、源码名、声明父类型、特性列表、自定义注解实例，以及访问级别、静态/常量/外部链接等属性标记的查询与设置能力。

父类型：

- [Value](#class-value)
- Equatable\<[GlobalValue](#class-globalvalue)>

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

功能：附加在该全局值上的自定义注解实例列表；可读可写。

类型：Array\<[CustomAnnoInstance](#class-customannoinstance)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_customAnnoInstances: ${f.customAnnoInstances.size}")
}
```

运行结果：

```text
prop_customAnnoInstances: 0
```

### prop declaredParent

```cangjie
public prop declaredParent: ?CustomTypeDef
```

功能：声明该全局值的外层类型定义；独立声明的全局值为 `None`。

类型：?[CustomTypeDef](#class-customtypedef)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_declaredParent: ${f.declaredParent.isNone()}")
}
```

运行结果：

```text
prop_declaredParent: true
```

### prop features

```cangjie
public prop features: Array<String>
```

功能：该全局值携带的特性（feature）字符串列表。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_features: ${f.features.size}")
}
```

运行结果：

```text
prop_features: 0
```

### prop packageName

```cangjie
public prop packageName: String
```

功能：该全局值所属的包名。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_packageName: ${f.packageName}")
}
```

运行结果：

```text
prop_packageName: demo
```

### prop outerType

```cangjie
public prop outerType: ?Type
```

功能：声明该全局值的外层类型；无外层类型时为 `None`。

类型：?[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_outerType: ${f.outerType.isNone()}")
}
```

运行结果：

```text
prop_outerType: true
```

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

功能：该全局值在源码中的名称。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_srcCodeName: ${f.srcCodeName}")
}
```

运行结果：

```text
prop_srcCodeName: f
```

### func isCompilerAdd()

```cangjie
public func isCompilerAdd(): Bool
```

功能：判断该全局值是否由编译器自动添加。

返回值：

- Bool - 由编译器添加时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isCompilerAdd: ${f.isCompilerAdd()}")
}
```

运行结果：

```text
func_isCompilerAdd: false
```

### func isConst()

```cangjie
public func isConst(): Bool
```

功能：判断该全局值是否标记为常量。

返回值：

- Bool - 标记为常量时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isConst: ${f.isConst()}")
}
```

运行结果：

```text
func_isConst: false
```

### func isExternalLinkage()

```cangjie
public func isExternalLinkage(): Bool
```

功能：判断该全局值是否具有外部链接（`LinkType.External`）。

返回值：

- Bool - 具有外部链接时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isExternalLinkage: ${f.isExternalLinkage()}")
}
```

运行结果：

```text
func_isExternalLinkage: true
```

### func isForeign()

```cangjie
public func isForeign(): Bool
```

功能：判断该全局值是否为外部函数（foreign）。

返回值：

- Bool - 为外部函数时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isForeign: ${f.isForeign()}")
}
```

运行结果：

```text
func_isForeign: false
```

### func isImported()

```cangjie
public func isImported(): Bool
```

功能：判断该全局值是否从其他包导入。

返回值：

- Bool - 为导入时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isImported: ${f.isImported()}")
}
```

运行结果：

```text
func_isImported: false
```

### func isInternal()

```cangjie
public func isInternal(): Bool
```

功能：判断该全局值的访问级别是否为 internal。

返回值：

- Bool - 为 internal 时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isInternal: ${f.isInternal()}")
}
```

运行结果：

```text
func_isInternal: false
```

### func isPrivate()

```cangjie
public func isPrivate(): Bool
```

功能：判断该全局值的访问级别是否为 private。

返回值：

- Bool - 为 private 时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isPrivate: ${f.isPrivate()}")
}
```

运行结果：

```text
func_isPrivate: false
```

### func isProtected()

```cangjie
public func isProtected(): Bool
```

功能：判断该全局值的访问级别是否为 protected。

返回值：

- Bool - 为 protected 时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isProtected: ${f.isProtected()}")
}
```

运行结果：

```text
func_isProtected: false
```

### func isPublic()

```cangjie
public func isPublic(): Bool
```

功能：判断该全局值的访问级别是否为 public。

返回值：

- Bool - 为 public 时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isPublic: ${f.isPublic()}")
}
```

运行结果：

```text
func_isPublic: false
```

### func isStatic()

```cangjie
public func isStatic(): Bool
```

功能：判断该全局值是否为静态成员。

返回值：

- Bool - 为静态成员时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isStatic: ${f.isStatic()}")
}
```

运行结果：

```text
func_isStatic: false
```

### func setConst(Bool)

```cangjie
public func setConst(enable: Bool): Unit
```

功能：设置该全局值的常量标记。

参数：

- enable: Bool - true 表示标记为常量，false 表示取消标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.setConst(true)
    println("func_setConst: ${f.isConst()}")
}
```

运行结果：

```text
func_setConst: true
```

### func setImported(Bool)

```cangjie
public func setImported(enable: Bool): Unit
```

功能：设置该全局值的导入标记。

参数：

- enable: Bool - true 表示标记为导入，false 表示取消标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.setImported(true)
    println("func_setImported: ${f.isImported()}")
}
```

运行结果：

```text
func_setImported: true
```

### func setInternal()

```cangjie
public func setInternal(): Unit
```

功能：将该全局值的访问级别设置为 internal。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.setInternal()
    println("func_setInternal: ${f.isInternal()}")
}
```

运行结果：

```text
func_setInternal: true
```

### func setPrivate()

```cangjie
public func setPrivate(): Unit
```

功能：将该全局值的访问级别设置为 private。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.setPrivate()
    println("func_setPrivate: ${f.isPrivate()}")
}
```

运行结果：

```text
func_setPrivate: true
```

### func setProtected()

```cangjie
public func setProtected(): Unit
```

功能：将该全局值的访问级别设置为 protected。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.setProtected()
    println("func_setProtected: ${f.isProtected()}")
}
```

运行结果：

```text
func_setProtected: true
```

### func setPublic()

```cangjie
public func setPublic(): Unit
```

功能：将该全局值的访问级别设置为 public。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.setPublic()
    println("func_setPublic: ${f.isPublic()}")
}
```

运行结果：

```text
func_setPublic: true
```

### func setStatic(Bool)

```cangjie
public func setStatic(enable: Bool): Unit
```

功能：设置该全局值的静态成员标记。

参数：

- enable: Bool - true 表示标记为静态成员，false 表示取消标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.setStatic(true)
    println("func_setStatic: ${f.isStatic()}")
}
```

运行结果：

```text
func_setStatic: true
```

### operator func ==(GlobalValue)

```cangjie
public operator func ==(other: GlobalValue): Bool
```

功能：引用比较，判断两个 GlobalValue 是否为同一实例。

参数：

- other: [GlobalValue](#class-globalvalue) - 另一全局值。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("op_eq_GlobalValue: ${f == f}")
}
```

运行结果：

```text
op_eq_GlobalValue: true
```

## class Function

```cangjie
public class Function <: GlobalValue & Equatable<Function> {}
```

功能：表示 CHIR 中的**函数定义**，包含函数类型、参数、函数体（BlockGroup）、泛型形参以及抽象/open 等属性标记。

父类型：

- GlobalValue
- Equatable\<Function>

### prop body

```cangjie
public prop body: ?BlockGroup
```

功能：函数体；未初始化时为 `None`。

类型：?[BlockGroup](#class-blockgroup)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_body: ${f.body.isNone()}")
}
```

运行结果：

```text
prop_body: true
```

### prop funcSrcCodeType

```cangjie
public prop funcSrcCodeType: FuncType
```

功能：源码级函数类型；实例成员方法时剔除隐含的 `this` 参数类型，其余情况与 `funcType` 相同。

类型：[FuncType](#class-functype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    println("prop_funcSrcCodeType: ${f.funcSrcCodeType == f.funcType}")
}
```

运行结果：

```text
prop_funcSrcCodeType: true
```

### prop funcType

```cangjie
public prop funcType: FuncType
```

功能：函数类型（含参数类型与返回类型）。

类型：[FuncType](#class-functype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_funcType: ${f.funcType.toString()}")
}
```

运行结果：

```text
prop_funcType: () -> Unit
```

### prop genericTypeParams

```cangjie
public mut prop genericTypeParams: Array<GenericType>
```

功能：泛型形参；赋值时自动更新 `Generic` 属性标记（非空时标记为泛型）。

类型：Array\<[GenericType](#class-generictype)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("mut_prop_genericTypeParams: ${f.genericTypeParams.size}")
}
```

运行结果：

```text
mut_prop_genericTypeParams: 0
```

### prop parameters

```cangjie
public prop parameters: Array<Parameter>
```

功能：参数列表。

类型：Array\<[Parameter](#class-parameter)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    println("prop_parameters: ${f.parameters.size}")
}
```

运行结果：

```text
prop_parameters: 1
```

### prop returnValue

```cangjie
public mut prop returnValue: ?LocalVar
```

功能：返回值局部变量；赋值时自动更新新旧 LocalVar 的 `isRetValue` 标记。

类型：?[LocalVar](#class-localvar)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("mut_prop_returnValue: ${f.returnValue.isNone()}")
}
```

运行结果：

```text
mut_prop_returnValue: true
```

### func initBody()

```cangjie
public func initBody(): Unit
```

功能：初始化函数体，创建入口 BlockGroup 和 Block。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    println("fn_initBody: ${f.body.isSome()}")
}
```

运行结果：

```text
fn_initBody: true
```

### func isAbstract()

```cangjie
public func isAbstract(): Bool
```

功能：是否为抽象函数（带 `abstract` 标记或属于接口的方法）。

返回值：

- Bool - 是否为抽象。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isAbstract: ${f.isAbstract()}")
}
```

运行结果：

```text
fn_isAbstract: false
```

### func isDeclaredInCurPackage()

```cangjie
public func isDeclaredInCurPackage(): Bool
```

功能：是否在当前包中声明（与 `isImported()` 相反）。

返回值：

- Bool - 是否为本包声明。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isDeclaredInCurPackage: ${f.isDeclaredInCurPackage()}")
}
```

运行结果：

```text
fn_isDeclaredInCurPackage: true
```

### func isGeneric()

```cangjie
public func isGeneric(): Bool
```

功能：是否为泛型函数。

返回值：

- Bool - 是否带泛型标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isGeneric: ${f.isGeneric()}")
}
```

运行结果：

```text
fn_isGeneric: false
```

### func isInstanceMemberMethod()

```cangjie
public func isInstanceMemberMethod(): Bool
```

功能：是否为实例成员方法（有 `declaredParent` 且非静态）。

返回值：

- Bool - 是否为实例成员方法。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isInstanceMemberMethod: ${f.isInstanceMemberMethod()}")
}
```

运行结果：

```text
fn_isInstanceMemberMethod: false
```

### func isMemberMethod()

```cangjie
public func isMemberMethod(): Bool
```

功能：是否为成员方法（实例或静态），即是否有 `declaredParent`。

返回值：

- Bool - 是否为成员方法。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isMemberMethod: ${f.isMemberMethod()}")
}
```

运行结果：

```text
fn_isMemberMethod: false
```

### func isOpen()

```cangjie
public func isOpen(): Bool
```

功能：是否为 open/virtual 函数（可被子类覆写）。

返回值：

- Bool - 是否为 open。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isOpen: ${f.isOpen()}")
}
```

运行结果：

```text
fn_isOpen: false
```

### func isSrcCodeImported()

```cangjie
public func isSrcCodeImported(): Bool
```

功能：源码是否来自导入（`isImported()` 且已有函数体）。

返回值：

- Bool - 是否为导入且已有体。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isSrcCodeImported: ${f.isSrcCodeImported()}")
}
```

运行结果：

```text
fn_isSrcCodeImported: false
```

### func isStaticMemberMethod()

```cangjie
public func isStaticMemberMethod(): Bool
```

功能：是否为静态成员方法（有 `declaredParent` 且为静态）。

返回值：

- Bool - 是否为静态成员方法。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isStaticMemberMethod: ${f.isStaticMemberMethod()}")
}
```

运行结果：

```text
fn_isStaticMemberMethod: false
```

### func moveBodyTo(Function)

```cangjie
public func moveBodyTo(other: Function): Unit
```

功能：将函数体、参数、泛型形参和返回值移动到另一函数；调用后本函数的上述内容被清空。

参数：

- other: Function - 目标函数。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f1 = pkg.addFunction(FuncType.get([], UnitType.get()), "f1_m", "f1", "demo")
    let f2 = pkg.addFunction(FuncType.get([], UnitType.get()), "f2_m", "f2", "demo")
    f1.initBody()
    f1.moveBodyTo(f2)
    println("fn_moveBodyTo_src: ${f1.body.isNone()}")
    println("fn_moveBodyTo_dst: ${f2.body.isSome()}")
}
```

运行结果：

```text
fn_moveBodyTo_src: true
fn_moveBodyTo_dst: true
```

### func selfOrParentIsGeneric()

```cangjie
public func selfOrParentIsGeneric(): Bool
```

功能：本函数或其父定义是否为泛型。

返回值：

- Bool - 是否为泛型上下文。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_selfOrParentIsGeneric: ${f.selfOrParentIsGeneric()}")
}
```

运行结果：

```text
fn_selfOrParentIsGeneric: false
```

### func setAbstract(Bool)

```cangjie
public func setAbstract(enable: Bool): Unit
```

功能：设置或清除 `abstract` 标记。

参数：

- enable: Bool - `true` 标记为抽象，`false` 取消标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.setAbstract(true)
    println("fn_setAbstract: ${f.isAbstract()}")
}
```

运行结果：

```text
fn_setAbstract: true
```

### func setOpen(Bool)

```cangjie
public func setOpen(enable: Bool): Unit
```

功能：设置或清除 `open`（virtual）标记。

参数：

- enable: Bool - `true` 标记为 open，`false` 取消标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.setOpen(true)
    println("fn_setOpen: ${f.isOpen()}")
}
```

运行结果：

```text
fn_setOpen: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：函数的字符串形式（含标识、类型、参数等）。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_toString: ${f.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### operator func ==(Function)

```cangjie
public operator func ==(other: Function): Bool
```

功能：引用比较，判断两个 Function 是否为同一实例。

参数：

- other: Function - 另一函数。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("op_eq_Function: ${f == f}")
}
```

运行结果：

```text
op_eq_Function: true
```

## class GlobalVar

```cangjie
public class GlobalVar <: GlobalValue & Equatable<GlobalVar> {}
```

功能：表示 CHIR 中的**全局变量定义**，包含类型、初始化值及只读标记。

父类型：

- GlobalValue
- Equatable\<GlobalVar>

### prop initializer

```cangjie
public prop initializer: ?Value
```

功能：初始化值；未设置时为 `None`。

类型：?Value

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("prop_initializer: ${gv.initializer.isNone()}")
}
```

运行结果：

```text
prop_initializer: true
```

### func isReadOnly()

```cangjie
public func isReadOnly(): Bool
```

功能：是否为只读全局变量（对应源码 `let` 声明）。

返回值：

- Bool - 是否为只读。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("fn_isReadOnly: ${gv.isReadOnly()}")
}
```

运行结果：

```text
fn_isReadOnly: false
```

### func isSrcCodeImported()

```cangjie
public func isSrcCodeImported(): Bool
```

功能：源码是否来自导入（`isImported()` 且已有初始化值）。

返回值：

- Bool - 是否为导入且已初始化。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("fn_isSrcCodeImported: ${gv.isSrcCodeImported()}")
}
```

运行结果：

```text
fn_isSrcCodeImported: false
```

### func setInitializer(Value)

```cangjie
public func setInitializer(initializer: Value): Unit
```

功能：设置初始化值。

参数：

- initializer: Value - 初始化值（可为字面量或函数引用）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    gv.setInitializer(IntLiteral.get(IntType.getInt32(), 42))
    println("fn_setInitializer: ${gv.initializer.isSome()}")
}
```

运行结果：

```text
fn_setInitializer: true
```

### func setReadOnly(Bool)

```cangjie
public func setReadOnly(enable: Bool): Unit
```

功能：设置或清除只读标记。

参数：

- enable: Bool - `true` 标记为只读，`false` 取消标记。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    gv.setReadOnly(true)
    println("fn_setReadOnly: ${gv.isReadOnly()}")
}
```

运行结果：

```text
fn_setReadOnly: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：全局变量的字符串形式（含属性、类型、初始化值等）。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("fn_toString: ${gv.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### operator func ==(GlobalVar)

```cangjie
public operator func ==(other: GlobalVar): Bool
```

功能：引用比较，判断两个 GlobalVar 是否为同一实例。

参数：

- other: GlobalVar - 另一全局变量。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("op_eq_GlobalVar: ${gv == gv}")
}
```

运行结果：

```text
op_eq_GlobalVar: true
```

## class IntLiteral

```cangjie
public class IntLiteral <: LiteralValue & Equatable<IntLiteral> {}
```

功能：表示整数字面量，按 `(IntType, UInt64)` 缓存保证同一类型与值对应唯一实例。

父类型：

- LiteralValue
- Equatable\<IntLiteral>

### prop signedValue

```cangjie
public prop signedValue: Int64
```

功能：有符号整数值（将内部 `UInt64` 转为 `Int64`）。

类型：Int64

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getInt32(), 42)
    println("prop_signedValue: ${lit.signedValue}")
}
```

运行结果：

```text
prop_signedValue: 42
```

### prop unsignedValue

```cangjie
public prop unsignedValue: UInt64
```

功能：无符号整数值。

类型：UInt64

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getUInt32(), 42)
    println("prop_unsignedValue: ${lit.unsignedValue}")
}
```

运行结果：

```text
prop_unsignedValue: 42
```

### static func get(IntType, UInt64)

```cangjie
public static func get(ty: IntType, value: UInt64): IntLiteral
```

功能：获取整数字面量；同一类型与值组合始终返回同一缓存实例。

参数：

- ty: IntType - 整数类型。
- value: UInt64 - 无符号整数值。

返回值：

- [IntLiteral](#class-intliteral) - 对应的整数字面量。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getInt64(), 100)
    println(lit.toString())
}
```

运行结果：

```text
100i
```

### func isSigned()

```cangjie
public func isSigned(): Bool
```

功能：是否为有符号整数（由所属 `IntType` 决定）。

返回值：

- Bool - 是否为有符号。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getInt32(), 0)
    println("fn_isSigned: ${lit.isSigned()}")
}
```

运行结果：

```text
fn_isSigned: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：字符串形式，有符号时后缀 `"i"`，无符号时后缀 `"u"`（如 `42i`、`42u`）。

返回值：

- String - 整数值的文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getUInt16(), 7)
    println(lit.toString())
}
```

运行结果：

```text
7u
```

### operator func ==(IntLiteral)

```cangjie
public operator func ==(other: IntLiteral): Bool
```

功能：引用比较，判断两个 IntLiteral 是否为同一实例。

参数：

- other: IntLiteral - 另一整数字面量。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = IntLiteral.get(IntType.getInt32(), 10)
    let lit2 = IntLiteral.get(IntType.getInt32(), 10)
    println("op_eq_IntLiteral: ${lit1 == lit2}")
}
```

运行结果：

```text
op_eq_IntLiteral: true
```

## class LocalVar

```cangjie
public class LocalVar <: Value & Equatable<LocalVar> {}
```

功能：表示 CHIR 中的**局部变量**，由表达式结果产生，也可作为函数返回值。

父类型：

- Value
- Equatable\<LocalVar>

### prop expr

```cangjie
public prop expr: Expression
```

功能：定义此局部变量的表达式。

类型：Expression

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let lit = IntLiteral.get(IntType.getInt32(), 1)
    let expr = Constant.create(lit)
    let lv = expr.result
    println("prop_expr: ${lv.expr == expr}")
}
```

运行结果：

```text
prop_expr: true
```

### prop srcCodeName

```cangjie
public mut prop srcCodeName: String
```

功能：源码名称；初始为空串。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let lit = IntLiteral.get(IntType.getInt32(), 1)
    let expr = Constant.create(lit)
    let lv = expr.result
    lv.srcCodeName = "x"
    println("mut_prop_srcCodeName: ${lv.srcCodeName}")
}
```

运行结果：

```text
mut_prop_srcCodeName: x
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

功能：所属顶层函数。

类型：[Function](#class-function)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let lit = IntLiteral.get(IntType.getInt32(), 1)
    let expr = Constant.create(lit)
    f.body.getOrThrow().entryBlock.appendExpr(expr)
    let lv = expr.result
    println("prop_topLevelFunc: ${lv.topLevelFunc == f}")
}
```

运行结果：

```text
prop_topLevelFunc: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：局部变量的字符串形式（等同于其定义表达式的 `toString()`）。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let lit = IntLiteral.get(IntType.getInt32(), 1)
    let expr = Constant.create(lit)
    f.body.getOrThrow().entryBlock.appendExpr(expr)
    let lv = expr.result
    println("fn_toString: ${lv.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### operator func ==(LocalVar)

```cangjie
public operator func ==(other: LocalVar): Bool
```

功能：引用比较，判断两个 LocalVar 是否为同一实例。

参数：

- other: LocalVar - 另一局部变量。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let lit = IntLiteral.get(IntType.getInt32(), 1)
    let expr = Constant.create(lit)
    f.body.getOrThrow().entryBlock.appendExpr(expr)
    let lv = expr.result
    println("op_eq_LocalVar: ${lv == lv}")
}
```

运行结果：

```text
op_eq_LocalVar: true
```

## class NullLiteral

```cangjie
public class NullLiteral <: LiteralValue & Equatable<NullLiteral> {}
```

功能：表示 Null 字面量，按类型缓存保证同一类型对应唯一实例。

父类型：

- LiteralValue
- Equatable\<NullLiteral>

### static func get(Type)

```cangjie
public static func get(ty: Type): NullLiteral
```

功能：获取指定类型的 Null 字面量；同一类型始终返回同一缓存实例。

参数：

- ty: Type - Null 的类型。

返回值：

- [NullLiteral](#class-nullliteral) - Null 字面量实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = NullLiteral.get(BoxType.get(IntType.getInt32()))
    println(lit.toString())
}
```

运行结果：

```text
Null
```

### func toString()

```cangjie
public func toString(): String
```

功能：字符串形式，始终为 `"Null"`。

返回值：

- String - `"Null"`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = NullLiteral.get(BoxType.get(IntType.getInt32()))
    println(lit.toString())
}
```

运行结果：

```text
Null
```

### operator func ==(NullLiteral)

```cangjie
public operator func ==(other: NullLiteral): Bool
```

功能：引用比较，判断两个 NullLiteral 是否为同一实例。

参数：

- other: NullLiteral - 另一 Null 字面量。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = NullLiteral.get(BoxType.get(IntType.getInt32()))
    let lit2 = NullLiteral.get(BoxType.get(IntType.getInt32()))
    println("op_eq_NullLiteral: ${lit1 == lit2}")
}
```

运行结果：

```text
op_eq_NullLiteral: true
```

## class Parameter

```cangjie
public class Parameter <: Value & Equatable<Parameter> {}
```

功能：表示 CHIR 中的**函数参数**，包含类型、源码名、注解等信息。

父类型：

- Value
- Equatable\<Parameter>

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

功能：参数注解实例列表；getter 返回当前所有实例，setter 整体替换。

类型：Array\<[CustomAnnoInstance](#class-customannoinstance)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    let param = f.parameters[0]
    println("mut_prop_customAnnoInstances: ${param.customAnnoInstances.size}")
}
```

运行结果：

```text
mut_prop_customAnnoInstances: 0
```

### prop srcCodeName

```cangjie
public mut prop srcCodeName: String
```

功能：参数源码名；初始为空串。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    let param = f.parameters[0]
    param.srcCodeName = "x"
    println("mut_prop_srcCodeName: ${param.srcCodeName}")
}
```

运行结果：

```text
mut_prop_srcCodeName: x
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

功能：所属顶层函数。

类型：[Function](#class-function)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    let param = f.parameters[0]
    println("prop_topLevelFunc: ${param.topLevelFunc == f}")
}
```

运行结果：

```text
prop_topLevelFunc: true
```

### func toString()

```cangjie
public func toString(): String
```

功能：参数的字符串形式（含类型、注解等）。

返回值：

- String - 文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    let param = f.parameters[0]
    println("fn_toString: ${param.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### operator func ==(Parameter)

```cangjie
public operator func ==(other: Parameter): Bool
```

功能：引用比较，判断两个 Parameter 是否为同一实例。

参数：

- other: Parameter - 另一参数。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    let param = f.parameters[0]
    println("op_eq_Parameter: ${param == param}")
}
```

运行结果：

```text
op_eq_Parameter: true
```

## class RuneLiteral

```cangjie
public class RuneLiteral <: LiteralValue & Equatable<RuneLiteral> {}
```

功能：表示 Rune（字符）字面量，按值缓存保证同一 Rune 值对应唯一实例。

父类型：

- LiteralValue
- Equatable\<RuneLiteral>

### prop value

```cangjie
public prop value: Rune
```

功能：Rune 值（Unicode 码点）。

类型：Rune

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = RuneLiteral.get(Rune(65))
    println("prop_value: ${lit.value}")
}
```

运行结果：

```text
prop_value: A
```

### static func get(Rune)

```cangjie
public static func get(value: Rune): RuneLiteral
```

功能：获取 Rune 字面量；同一 Rune 值始终返回同一缓存实例。

参数：

- value: Rune - Rune 值。

返回值：

- [RuneLiteral](#class-runeliteral) - 对应的 Rune 字面量。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = RuneLiteral.get(Rune(97))
    println(lit.toString())
}
```

运行结果：

```text
'a'
```

### func toString()

```cangjie
public func toString(): String
```

功能：字符串形式，为单引号包裹的字符表示（如 `'A'`）。

返回值：

- String - Rune 值的文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = RuneLiteral.get(Rune(48))
    println(lit.toString())
}
```

运行结果：

```text
'0'
```

### operator func ==(RuneLiteral)

```cangjie
public operator func ==(other: RuneLiteral): Bool
```

功能：引用比较，判断两个 RuneLiteral 是否为同一实例。

参数：

- other: RuneLiteral - 另一 Rune 字面量。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = RuneLiteral.get(Rune(65))
    let lit2 = RuneLiteral.get(Rune(65))
    println("op_eq_RuneLiteral: ${lit1 == lit2}")
}
```

运行结果：

```text
op_eq_RuneLiteral: true
```

## class StringLiteral

```cangjie
public class StringLiteral <: LiteralValue & Equatable<StringLiteral> {}
```

功能：表示字符串字面量，按值缓存保证同一字符串值对应唯一实例。

父类型：

- LiteralValue
- Equatable\<StringLiteral>

### prop value

```cangjie
public prop value: String
```

功能：字符串值。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = StringLiteral.get(UnitType.get(), "hello")
    println("prop_value: ${lit.value}")
}
```

运行结果：

```text
prop_value: hello
```

### static func get(Type, String)

```cangjie
public static func get(ty: Type, value: String): StringLiteral
```

功能：获取字符串字面量；同一字符串值始终返回同一缓存实例。

参数：

- ty: Type - 字符串所属类型。
- value: String - 字符串内容。

返回值：

- [StringLiteral](#class-stringliteral) - 对应的字符串字面量。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = StringLiteral.get(UnitType.get(), "world")
    println(lit.toString())
}
```

运行结果：

```text
"world"
```

### func toString()

```cangjie
public func toString(): String
```

功能：字符串形式，为双引号包裹（如 `"hello"`）。

返回值：

- String - 字符串值的文本形式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = StringLiteral.get(UnitType.get(), "abc")
    println(lit.toString())
}
```

运行结果：

```text
"abc"
```

### operator func ==(StringLiteral)

```cangjie
public operator func ==(other: StringLiteral): Bool
```

功能：引用比较，判断两个 StringLiteral 是否为同一实例。

参数：

- other: StringLiteral - 另一字符串字面量。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = StringLiteral.get(UnitType.get(), "test")
    let lit2 = StringLiteral.get(UnitType.get(), "test")
    println("op_eq_StringLiteral: ${lit1 == lit2}")
}
```

运行结果：

```text
op_eq_StringLiteral: true
```

## class UnitLiteral

```cangjie
public class UnitLiteral <: LiteralValue & Equatable<UnitLiteral> {}
```

功能：表示 Unit 字面量（单例，表示无返回值）。

父类型：

- LiteralValue
- Equatable\<UnitLiteral>

### static func get()

```cangjie
public static func get(): UnitLiteral
```

功能：获取 Unit 字面量的单例实例。

返回值：

- [UnitLiteral](#class-unitliteral) - Unit 字面量实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = UnitLiteral.get()
    println(lit.toString())
}
```

运行结果：

```text
Unit
```

### func toString()

```cangjie
public func toString(): String
```

功能：字符串形式，始终为 `"Unit"`。

返回值：

- String - `"Unit"`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = UnitLiteral.get()
    println(lit.toString())
}
```

运行结果：

```text
Unit
```

### operator func ==(UnitLiteral)

```cangjie
public operator func ==(other: UnitLiteral): Bool
```

功能：引用比较，判断两个 UnitLiteral 是否为同一实例。

参数：

- other: UnitLiteral - 另一 Unit 字面量。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = UnitLiteral.get()
    let lit2 = UnitLiteral.get()
    println("op_eq_UnitLiteral: ${lit1 == lit2}")
}
```

运行结果：

```text
op_eq_UnitLiteral: true
```

## class Expression

```cangjie
sealed abstract class Expression <: ToString & Hashable & Equatable<Expression> {}
```

功能：CHIR 中所有表达式的抽象基类。表达式是基本块内的指令单元，持有操作数列表、所属基本块、结果局部变量及附属基本块组等信息，并提供移动、销毁、结果查询及类型判断等能力。

父类型：

- ToString
- Hashable
- Equatable\<[Expression](#class-expression)>

### prop blockGroups

```cangjie
public prop blockGroups: Array<BlockGroup>
```

功能：附属在该表达式上的基本块组列表。

类型：Array\<[BlockGroup](#class-blockgroup)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("prop_blockGroups: ${expr.blockGroups.size}")
}
```

运行结果：

```text
prop_blockGroups: 0
```

### prop operands

```cangjie
public prop operands: Array<Value>
```

功能：该表达式的有序操作数列表。

类型：Array\<[Value](#class-value)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("prop_operands: ${expr.operands.size}")
}
```

运行结果：

```text
prop_operands: 0
```

### prop owner

```cangjie
public prop owner: Block
```

功能：包含该表达式的基本块；未设置时抛出异常。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("prop_owner: ${expr.owner == block}")
}
```

运行结果：

```text
prop_owner: true
```

### prop result

```cangjie
public prop result: LocalVar
```

功能：该表达式产生的结果局部变量；未设置时抛出异常。

类型：[LocalVar](#class-localvar)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("prop_result: ${expr.result.ty.qualifiedName}")
}
```

运行结果：

```text
prop_result: Int32
```

### prop successors

```cangjie
public prop successors: Array<Block>
```

功能：该表达式的操作数中引用的后继基本块列表。

类型：Array\<[Block](#class-block)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("prop_successors: ${expr.successors.size}")
}
```

运行结果：

```text
prop_successors: 0
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

功能：该表达式所属的顶层函数。

类型：[Function](#class-function)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("prop_topLevelFunc: ${expr.topLevelFunc == f}")
}
```

运行结果：

```text
prop_topLevelFunc: true
```

### func destroySelf()

```cangjie
public func destroySelf(): Unit
```

功能：销毁该表达式，解除其与操作数、所属基本块及附属基本块组之间的使用/归属关系。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    expr.destroySelf()
    println("func_destroySelf: ${block.exprs.size}")
}
```

运行结果：

```text
func_destroySelf: 0
```

### func dump()

```cangjie
public func dump(): Unit
```

功能：将该表达式的字符串表示打印到标准输出。

示例：

<!-- run -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    expr.dump()
}
```

### func hasExceptionBranch()

```cangjie
public func hasExceptionBranch(): Bool
```

功能：判断该表达式是否携带正常/异常分支操作数（如 TryApply、TryInvoke 等）。

返回值：

- Bool - 携带异常分支时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("func_hasExceptionBranch: ${expr.hasExceptionBranch()}")
}
```

运行结果：

```text
func_hasExceptionBranch: false
```

### func hashCode()

```cangjie
public func hashCode(): Int64
```

功能：基于结果值计算该表达式的哈希码。

返回值：

- Int64 - 表达式的哈希码。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("func_hashCode: ${expr.hashCode() == expr.hashCode()}")
}
```

运行结果：

```text
func_hashCode: true
```

### func isTerminator()

```cangjie
public func isTerminator(): Bool
```

功能：判断该表达式是否为终止指令（如 Branch、Exit、GoTo 等）。

返回值：

- Bool - 为终止指令时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("func_isTerminator: ${expr.isTerminator()}")
}
```

运行结果：

```text
func_isTerminator: false
```

### func isLambda()

```cangjie
public func isLambda(): Bool
```

功能：判断该表达式是否为 Lambda 表达式。

返回值：

- Bool - 为 Lambda 表达式时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("func_isLambda: ${expr.isLambda()}")
}
```

运行结果：

```text
func_isLambda: false
```

### func isExit()

```cangjie
public func isExit(): Bool
```

功能：判断该表达式是否为 Exit 表达式。

返回值：

- Bool - 为 Exit 表达式时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("func_isExit: ${expr.isExit()}")
}
```

运行结果：

```text
func_isExit: false
```

### func moveAfter(Expression)

```cangjie
public func moveAfter(other: Expression): Unit
```

功能：将该表达式移动到另一表达式之后；不能移动到终止指令之后。

参数：

- other: [Expression](#class-expression) - 锚点表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let e1 = builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    let e2 = builder.createBinarySub(IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt64(), 3), OverflowStrategy.NA)
    e2.moveAfter(e1)
    println("func_moveAfter: ${block.exprs[0] == e1}")
}
```

运行结果：

```text
func_moveAfter: true
```

### func moveBefore(Expression)

```cangjie
public func moveBefore(other: Expression): Unit
```

功能：将该表达式移动到另一表达式之前；终止指令不能移动到其他表达式之前。

参数：

- other: [Expression](#class-expression) - 锚点表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let e1 = builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    let e2 = builder.createBinarySub(IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt64(), 3), OverflowStrategy.NA)
    e1.moveBefore(e2)
    println("func_moveBefore: ${block.exprs[0] == e1}")
}
```

运行结果：

```text
func_moveBefore: true
```

### func replaceOperand(Value, Value)

```cangjie
public func replaceOperand(operand: Value, other: Value): Unit
```

功能：将该表达式中指定的操作数替换为另一值。

参数：

- operand: [Value](#class-value) - 待替换的操作数。
- other: [Value](#class-value) - 替换后的新值。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let l1 = IntLiteral.get(IntType.getInt64(), 1)
    let l2 = IntLiteral.get(IntType.getInt64(), 2)
    let l3 = IntLiteral.get(IntType.getInt64(), 3)
    let expr = builder.createBinaryAdd(l1, l2, OverflowStrategy.NA)
    expr.replaceOperand(l1, l3)
    println("func_replaceOperand: ${expr.operands[0] == l3}")
}
```

运行结果：

```text
func_replaceOperand: true
```

### func toString()

```cangjie
public open func toString(): String
```

功能：构建该表达式的可读字符串表示。

返回值：

- String - 表达式的可读文本。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    println("func_toString: ${expr.toString().isEmpty()}")
}
```

运行结果：

```text
func_toString: false
```

### func tryGetResult()

```cangjie
public func tryGetResult(): Option<LocalVar>
```

功能：尝试获取该表达式的结果局部变量；未设置时返回 `None`。

返回值：

- Option\<[LocalVar](#class-localvar)> - 结果局部变量，未设置时为 `None`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("func_tryGetResult: ${expr.tryGetResult().isSome()}")
}
```

运行结果：

```text
func_tryGetResult: true
```

### operator func ==(Expression)

```cangjie
public operator func ==(other: Expression): Bool
```

功能：引用比较，判断两个 Expression 是否为同一实例。

参数：

- other: [Expression](#class-expression) - 另一表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("op_eq_Expression: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Expression: true
```

## class AllocateBase

```cangjie
sealed abstract class AllocateBase <: Expression & Equatable<AllocateBase> {}
```

功能：内存分配类表达式的抽象基类，提供所分配类型信息的查询能力，是 [Allocate](#class-allocate)、[TryAllocate](#class-tryallocate) 等的父类型。

父类型：

- [Expression](#class-expression)
- Equatable\<[AllocateBase](#class-allocatebase)>

### prop allocatedType

```cangjie
public prop allocatedType: Type
```

功能：该分配表达式所分配的类型。

类型：[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("prop_allocatedType: ${expr.allocatedType.qualifiedName}")
}
```

运行结果：

```text
prop_allocatedType: Int32
```

### operator func ==(AllocateBase)

```cangjie
public operator func ==(other: AllocateBase): Bool
```

功能：引用比较，判断两个 AllocateBase 是否为同一实例。

参数：

- other: [AllocateBase](#class-allocatebase) - 另一内存分配基类表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("op_eq_AllocateBase: ${expr == expr}")
}
```

运行结果：

```text
op_eq_AllocateBase: true
```

## class Allocate

```cangjie
public class Allocate <: AllocateBase & Equatable<Allocate> {}
```

功能：内存分配表达式，分配指定类型的空间但不带异常处理。

父类型：

- AllocateBase
- Equatable\<Allocate>

### static func create(Type)

```cangjie
public static func create(allocatedType: Type): Allocate
```

功能：创建内存分配表达式。

参数：

- allocatedType: Type - 分配的类型。

返回值：

- [Allocate](#class-allocate) - 创建的内存分配表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(Allocate)

```cangjie
public operator func ==(other: Allocate): Bool
```

功能：引用比较，判断两个 Allocate 是否为同一实例。

参数：

- other: Allocate - 另一内存分配表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Allocate.create(IntType.getInt32())
    block.appendExpr(expr)
    println("op_eq_Allocate: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Allocate: true
```

## class TryAllocate

```cangjie
public class TryAllocate <: AllocateBase & Equatable<TryAllocate> {}
```

功能：带异常处理的内存分配表达式，分配成功时跳转到正常分支，失败时跳转到异常分支。

父类型：

- AllocateBase
- Equatable\<TryAllocate>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

功能：正常分支目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let expr = TryAllocate.create(IntType.getInt32(), normalBlock, errorBlock)
    block.appendExpr(expr)
    println("prop_normalBranch: ${expr.normalBranch == normalBlock}")
}
```

运行结果：

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

功能：异常分支目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let expr = TryAllocate.create(IntType.getInt32(), normalBlock, errorBlock)
    block.appendExpr(expr)
    println("prop_errorBranch: ${expr.errorBranch == errorBlock}")
}
```

运行结果：

```text
prop_errorBranch: true
```

### static func create(Type, Block, Block)

```cangjie
public static func create(allocatedType: Type, normal: Block, err: Block): TryAllocate
```

功能：创建带异常处理的内存分配表达式。

参数：

- allocatedType: Type - 分配的类型。
- normal: Block - 正常分支目标块。
- err: Block - 异常分支目标块。

返回值：

- [TryAllocate](#class-tryallocate) - 创建的带异常处理的内存分配表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let expr = TryAllocate.create(IntType.getInt32(), normalBlock, errorBlock)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(TryAllocate)

```cangjie
public operator func ==(other: TryAllocate): Bool
```

功能：引用比较，判断两个 TryAllocate 是否为同一实例。

参数：

- other: TryAllocate - 另一带异常处理的内存分配表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let expr = TryAllocate.create(IntType.getInt32(), normalBlock, errorBlock)
    block.appendExpr(expr)
    println("op_eq_TryAllocate: ${expr == expr}")
}
```

运行结果：

```text
op_eq_TryAllocate: true
```

## class BinaryExpressionBase

```cangjie
sealed abstract class BinaryExpressionBase <: Expression & Equatable<BinaryExpressionBase> {}
```

功能：二元表达式（[BinaryExpression](#class-binaryexpression)、[TryBinaryExpression](#class-trybinaryexpression) 等）的抽象基类，提供溢出策略的查询与设置能力。

父类型：

- [Expression](#class-expression)
- Equatable\<[BinaryExpressionBase](#class-binaryexpressionbase)>

### prop overflow

```cangjie
public mut prop overflow: OverflowStrategy
```

功能：该二元表达式使用的溢出策略；可读可写，默认为 [OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy).NA。

类型：[OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    expr.overflow = OverflowStrategy.Throwing
    println("prop_overflow: ${expr.overflow}")
}
```

运行结果：

```text
prop_overflow: Throwing
```

### operator func ==(BinaryExpressionBase)

```cangjie
public operator func ==(other: BinaryExpressionBase): Bool
```

功能：引用比较，判断两个 BinaryExpressionBase 是否为同一实例。

参数：

- other: [BinaryExpressionBase](#class-binaryexpressionbase) - 另一二元表达式基类表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    println("op_eq_BinaryExpressionBase: ${expr == expr}")
}
```

运行结果：

```text
op_eq_BinaryExpressionBase: true
```

## class BinaryExpression

```cangjie
public class BinaryExpression <: BinaryExpressionBase & Equatable<BinaryExpression> {}
```

功能：二元运算表达式（不带异常处理），支持数学运算、位运算、比较运算和逻辑运算。

父类型：

- BinaryExpressionBase
- Equatable\<BinaryExpression>

### static func create(BinaryExprKind, Value, Value)

```cangjie
public static func create(kind: BinaryExprKind, leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建二元运算表达式。

参数：

- kind: BinaryExprKind - 二元运算类型。
- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 创建的二元运算表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let leftOp = IntLiteral.get(IntType.getInt32(), 1)
    let rightOp = IntLiteral.get(IntType.getInt32(), 2)
    let expr = BinaryExpression.create(BinaryExprKind.Add, leftOp, rightOp)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(BinaryExpression)

```cangjie
public operator func ==(other: BinaryExpression): Bool
```

功能：引用比较，判断两个 BinaryExpression 是否为同一实例。

参数：

- other: BinaryExpression - 另一二元运算表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let leftOp = IntLiteral.get(IntType.getInt32(), 1)
    let rightOp = IntLiteral.get(IntType.getInt32(), 2)
    let expr = BinaryExpression.create(BinaryExprKind.Add, leftOp, rightOp)
    block.appendExpr(expr)
    println("op_eq_BinaryExpression: ${expr == expr}")
}
```

运行结果：

```text
op_eq_BinaryExpression: true
```

## class TryBinaryExpression

```cangjie
public class TryBinaryExpression <: BinaryExpressionBase & Equatable<TryBinaryExpression> {}
```

功能：带异常处理的二元运算表达式，运算成功时跳转到正常分支，溢出或出错时跳转到异常分支。

父类型：

- BinaryExpressionBase
- Equatable\<TryBinaryExpression>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

功能：正常分支目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let leftOp = IntLiteral.get(IntType.getInt32(), 1)
    let rightOp = IntLiteral.get(IntType.getInt32(), 2)
    let expr = TryBinaryExpression.create(BinaryExprKind.Add, leftOp, rightOp, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("prop_normalBranch: ${expr.normalBranch == normalBlock}")
}
```

运行结果：

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

功能：异常分支目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let leftOp = IntLiteral.get(IntType.getInt32(), 1)
    let rightOp = IntLiteral.get(IntType.getInt32(), 2)
    let expr = TryBinaryExpression.create(BinaryExprKind.Add, leftOp, rightOp, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("prop_errorBranch: ${expr.errorBranch == errorBlock}")
}
```

运行结果：

```text
prop_errorBranch: true
```

### static func create(BinaryExprKind, Value, Value, Block, Block)

```cangjie
public static func create(kind: BinaryExprKind, leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

功能：创建带异常处理的二元运算表达式。

参数：

- kind: BinaryExprKind - 二元运算类型。
- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- normal: Block - 正常分支目标块。
- err: Block - 异常分支目标块。

返回值：

- [TryBinaryExpression](#class-trybinaryexpression) - 创建的带异常处理的二元运算表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let leftOp = IntLiteral.get(IntType.getInt32(), 1)
    let rightOp = IntLiteral.get(IntType.getInt32(), 2)
    let expr = TryBinaryExpression.create(BinaryExprKind.Add, leftOp, rightOp, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(TryBinaryExpression)

```cangjie
public operator func ==(other: TryBinaryExpression): Bool
```

功能：引用比较，判断两个 TryBinaryExpression 是否为同一实例。

参数：

- other: TryBinaryExpression - 另一带异常处理的二元运算表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let leftOp = IntLiteral.get(IntType.getInt32(), 1)
    let rightOp = IntLiteral.get(IntType.getInt32(), 2)
    let expr = TryBinaryExpression.create(BinaryExprKind.Add, leftOp, rightOp, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("op_eq_TryBinaryExpression: ${expr == expr}")
}
```

运行结果：

```text
op_eq_TryBinaryExpression: true
```

## class Branch

```cangjie
public class Branch <: Expression & Equatable<Branch> {}
```

功能：条件分支（if-else）终止器表达式，根据条件值跳转到真分支或假分支目标块。

父类型：

- Expression
- Equatable\<Branch>

### prop condition

```cangjie
public prop condition: Value
```

功能：条件值。

类型：Value

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let trueBlock = bg.appendBlock()
    let falseBlock = bg.appendBlock()
    let cond = Constant.create(BoolLiteral.get(true))
    block.appendExpr(cond)
    let expr = Branch.create(cond.result, trueBlock, falseBlock)
    block.appendExpr(expr)
    println("prop_condition: ${expr.condition == cond.result}")
}
```

运行结果：

```text
prop_condition: true
```

### prop trueTarget

```cangjie
public prop trueTarget: Block
```

功能：条件为真时的目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let trueBlock = bg.appendBlock()
    let falseBlock = bg.appendBlock()
    let cond = Constant.create(BoolLiteral.get(true))
    block.appendExpr(cond)
    let expr = Branch.create(cond.result, trueBlock, falseBlock)
    block.appendExpr(expr)
    println("prop_trueTarget: ${expr.trueTarget == trueBlock}")
}
```

运行结果：

```text
prop_trueTarget: true
```

### prop falseTarget

```cangjie
public prop falseTarget: Block
```

功能：条件为假时的目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let trueBlock = bg.appendBlock()
    let falseBlock = bg.appendBlock()
    let cond = Constant.create(BoolLiteral.get(true))
    block.appendExpr(cond)
    let expr = Branch.create(cond.result, trueBlock, falseBlock)
    block.appendExpr(expr)
    println("prop_falseTarget: ${expr.falseTarget == falseBlock}")
}
```

运行结果：

```text
prop_falseTarget: true
```

### static func create(Value, Block, Block)

```cangjie
public static func create(condition: Value, trueTarget: Block, falseTarget: Block): Branch
```

功能：创建条件分支终止器表达式。

参数：

- condition: Value - 条件值。
- trueTarget: Block - 条件为真时的目标块。
- falseTarget: Block - 条件为假时的目标块。

返回值：

- [Branch](#class-branch) - 创建的条件分支表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let trueBlock = bg.appendBlock()
    let falseBlock = bg.appendBlock()
    let cond = Constant.create(BoolLiteral.get(true))
    block.appendExpr(cond)
    let expr = Branch.create(cond.result, trueBlock, falseBlock)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 2
```

### operator func ==(Branch)

```cangjie
public operator func ==(other: Branch): Bool
```

功能：引用比较，判断两个 Branch 是否为同一实例。

参数：

- other: Branch - 另一条件分支表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let trueBlock = bg.appendBlock()
    let falseBlock = bg.appendBlock()
    let cond = Constant.create(BoolLiteral.get(true))
    block.appendExpr(cond)
    let expr = Branch.create(cond.result, trueBlock, falseBlock)
    block.appendExpr(expr)
    println("op_eq_Branch: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Branch: true
```

## class Constant

```cangjie
public class Constant <: Expression & Equatable<Constant> {}
```

功能：字面量常量表达式，表示一个编译期确定的常量值。

父类型：

- Expression
- Equatable\<Constant>

### static func create(LiteralValue)

```cangjie
public static func create(val: LiteralValue): Constant
```

功能：创建字面量常量表达式。

参数：

- val: LiteralValue - 字面量值。

返回值：

- [Constant](#class-constant) - 创建的常量表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Constant.create(IntLiteral.get(IntType.getInt32(), 42))
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(Constant)

```cangjie
public operator func ==(other: Constant): Bool
```

功能：引用比较，判断两个 Constant 是否为同一实例。

参数：

- other: Constant - 另一常量表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Constant.create(IntLiteral.get(IntType.getInt32(), 0))
    block.appendExpr(expr)
    println("op_eq_Constant: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Constant: true
```

## class Debug

```cangjie
public class Debug <: Expression & Equatable<Debug> {}
```

功能：调试标记表达式，保存源码位置映射信息，用于将 IR 中的值与源码中的变量名关联。

父类型：

- Expression
- Equatable\<Debug>

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

功能：源码调试名。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let loc = Constant.create(IntLiteral.get(IntType.getInt32(), 0))
    block.appendExpr(loc)
    let expr = Debug.create(loc.result, "var_x")
    block.appendExpr(expr)
    println("prop_srcCodeName: ${expr.srcCodeName}")
}
```

运行结果：

```text
prop_srcCodeName: var_x
```

### static func create(Value, String)

```cangjie
public static func create(location: Value, srcName: String): Debug
```

功能：创建调试标记表达式。

参数：

- location: Value - 要标记的值。
- srcName: String - 源码调试名。

返回值：

- [Debug](#class-debug) - 创建的调试标记表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let loc = Constant.create(IntLiteral.get(IntType.getInt32(), 0))
    block.appendExpr(loc)
    let expr = Debug.create(loc.result, "x")
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 2
```

### operator func ==(Debug)

```cangjie
public operator func ==(other: Debug): Bool
```

功能：引用比较，判断两个 Debug 是否为同一实例。

参数：

- other: Debug - 另一调试标记表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let loc = Constant.create(IntLiteral.get(IntType.getInt32(), 0))
    block.appendExpr(loc)
    let expr = Debug.create(loc.result, "x")
    block.appendExpr(expr)
    println("op_eq_Debug: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Debug: true
```

## class Exit

```cangjie
public class Exit <: Expression & Equatable<Exit> {}
```

功能：函数退出终止器表达式，表示函数正常执行结束。

父类型：

- Expression
- Equatable\<Exit>

### static func create()

```cangjie
public static func create(): Exit
```

功能：创建函数退出终止器表达式。

返回值：

- [Exit](#class-exit) - 创建的退出表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Exit.create()
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(Exit)

```cangjie
public operator func ==(other: Exit): Bool
```

功能：引用比较，判断两个 Exit 是否为同一实例。

参数：

- other: Exit - 另一退出表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = Exit.create()
    block.appendExpr(expr)
    println("op_eq_Exit: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Exit: true
```

## class Field

```cangjie
public class Field <: Expression & Equatable<Field> {}
```

功能：按数字索引路径访问字段的表达式，通过数值索引序列定位聚合体中的子字段。

父类型：

- Expression
- Equatable\<Field>

### prop path

```cangjie
public prop path: Array<UInt64>
```

功能：字段数字索引路径。

类型：Array\<UInt64>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = Field.create(alloc.result, ArrayList<UInt64>([0]))
    block.appendExpr(expr)
    println("prop_path: ${expr.path.size}")
}
```

运行结果：

```text
prop_path: 1
```

### static func create(Value, ArrayList\<UInt64>)

```cangjie
public static func create(location: Value, path: ArrayList<UInt64>): Field
```

功能：创建按数字索引路径访问字段的表达式。

参数：

- location: Value - 源聚合体值。
- path: ArrayList\<UInt64> - 字段数字索引路径。

返回值：

- [Field](#class-field) - 创建的字段访问表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = Field.create(alloc.result, ArrayList<UInt64>([0]))
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 2
```

### operator func ==(Field)

```cangjie
public operator func ==(other: Field): Bool
```

功能：引用比较，判断两个 Field 是否为同一实例。

参数：

- other: Field - 另一字段访问表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = Field.create(alloc.result, ArrayList<UInt64>([0]))
    block.appendExpr(expr)
    println("op_eq_Field: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Field: true
```

## class FieldByName

```cangjie
public class FieldByName <: Expression & Equatable<FieldByName> {}
```

功能：按字段名路径访问字段的表达式，通过字符串字段名序列定位聚合体中的子字段。

父类型：

- Expression
- Equatable\<FieldByName>

### prop fieldNames

```cangjie
public prop fieldNames: Array<String>
```

功能：字段名路径。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = FieldByName.create(alloc.result, ArrayList<String>(["x"]))
    block.appendExpr(expr)
    println("prop_fieldNames: ${expr.fieldNames.size}")
}
```

运行结果：

```text
prop_fieldNames: 1
```

### static func create(Value, ArrayList\<String>)

```cangjie
public static func create(location: Value, fieldNames: ArrayList<String>): FieldByName
```

功能：创建按字段名路径访问字段的表达式。

参数：

- location: Value - 源聚合体值。
- fieldNames: ArrayList\<String> - 字段名路径。

返回值：

- [FieldByName](#class-fieldbyname) - 创建的字段名访问表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = FieldByName.create(alloc.result, ArrayList<String>(["x"]))
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 2
```

### operator func ==(FieldByName)

```cangjie
public operator func ==(other: FieldByName): Bool
```

功能：引用比较，判断两个 FieldByName 是否为同一实例。

参数：

- other: FieldByName - 另一字段名访问表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = FieldByName.create(alloc.result, ArrayList<String>(["x"]))
    block.appendExpr(expr)
    println("op_eq_FieldByName: ${expr == expr}")
}
```

运行结果：

```text
op_eq_FieldByName: true
```

## class FuncCall

```cangjie
sealed abstract class FuncCall <: Expression & Equatable<FuncCall> {}
```

功能：函数调用类表达式的抽象基类，是 [ApplyBase](#class-applybase)、[IntrinsicBase](#class-intrinsicbase)、[InvokeBase](#class-invokebase) 的父类型，提供实例化类型参数、对象类型及实参列表的查询能力。

父类型：

- [Expression](#class-expression)
- Equatable\<[FuncCall](#class-funccall)>

### prop instantiatedTypeArgs

```cangjie
public prop instantiatedTypeArgs: Array<Type>
```

功能：该函数调用表达式的实例化类型参数列表。

类型：Array\<[Type](#class-type)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get([], UnitType.get())
    let f = pkg.addFunction(fType, "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let callCtx = FuncCallContext([], [], None)
    let expr = Apply.create(f, callCtx)
    block.appendExpr(expr)
    println("prop_instantiatedTypeArgs: ${expr.instantiatedTypeArgs.size}")
}
```

运行结果：

```text
prop_instantiatedTypeArgs: 0
```

### prop objType

```cangjie
public prop objType: ?Type
```

功能：该函数调用表达式的对象类型（成员方法调用时的对象类型）；非成员方法调用时为 `None`。

类型：?[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get([], UnitType.get())
    let f = pkg.addFunction(fType, "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let callCtx = FuncCallContext([], [], None)
    let expr = Apply.create(f, callCtx)
    block.appendExpr(expr)
    println("prop_objType: ${expr.objType.isNone()}")
}
```

运行结果：

```text
prop_objType: true
```

### func getArgs()

```cangjie
public func getArgs(): Array<Value>
```

功能：获取该函数调用表达式的实参列表。

返回值：

- Array\<[Value](#class-value)> - 实参数组。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get([], UnitType.get())
    let f = pkg.addFunction(fType, "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let callCtx = FuncCallContext([], [], None)
    let expr = Apply.create(f, callCtx)
    block.appendExpr(expr)
    println("func_getArgs: ${expr.getArgs().size}")
}
```

运行结果：

```text
func_getArgs: 0
```

### operator func ==(FuncCall)

```cangjie
public operator func ==(other: FuncCall): Bool
```

功能：引用比较，判断两个 FuncCall 是否为同一实例。

参数：

- other: [FuncCall](#class-funccall) - 另一函数调用基类表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get([], UnitType.get())
    let f = pkg.addFunction(fType, "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let callCtx = FuncCallContext([], [], None)
    let expr = Apply.create(f, callCtx)
    block.appendExpr(expr)
    println("op_eq_FuncCall: ${expr == expr}")
}
```

运行结果：

```text
op_eq_FuncCall: true
```

## class ApplyBase

```cangjie
sealed abstract class ApplyBase <: FuncCall & Equatable<ApplyBase> {}
```

功能：Apply（普通函数调用）类表达式的抽象基类，是 [Apply](#class-apply)、[TryApply](#class-tryapply) 的父类型，提供被调用函数值（callee）的查询能力。

父类型：

- [FuncCall](#class-funccall)
- Equatable\<[ApplyBase](#class-applybase)>

### prop callee

```cangjie
public prop callee: Value
```

功能：被调用的函数值。

类型：[Value](#class-value)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get([], UnitType.get())
    let f = pkg.addFunction(fType, "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let callCtx = FuncCallContext([], [], None)
    let expr = Apply.create(f, callCtx)
    block.appendExpr(expr)
    println("prop_callee: ${expr.callee == f}")
}
```

运行结果：

```text
prop_callee: true
```

### operator func ==(ApplyBase)

```cangjie
public operator func ==(other: ApplyBase): Bool
```

功能：引用比较，判断两个 ApplyBase 是否为同一实例。

参数：

- other: [ApplyBase](#class-applybase) - 另一 Apply 基类表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get([], UnitType.get())
    let f = pkg.addFunction(fType, "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let callCtx = FuncCallContext([], [], None)
    let expr = Apply.create(f, callCtx)
    block.appendExpr(expr)
    println("op_eq_ApplyBase: ${expr == expr}")
}
```

运行结果：

```text
op_eq_ApplyBase: true
```

## class Apply

```cangjie
public class Apply <: ApplyBase & Equatable<Apply> {}
```

功能：函数调用（Apply）表达式，表示对函数的直接调用。

父类型：

- ApplyBase
- Equatable\<Apply>

### static func create(Value, FuncCallContext)

```cangjie
public static func create(callee: Value, funcCallCtx: FuncCallContext): Apply
```

功能：创建函数调用表达式。

参数：

- callee: Value - 被调用函数值。
- funcCallCtx: FuncCallContext - 函数调用上下文（含实参、泛型实参和对象类型）。

返回值：

- [Apply](#class-apply) - 创建的函数调用表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let calleeFunc = pkg.addFunction(FuncType.get([], UnitType.get()), "callee_m", "callee", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let ctx = FuncCallContext([], [], None)
    let expr = Apply.create(calleeFunc, ctx)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

功能：返回此调用表达式的实际参数列表。

返回值：

- Array\<Value> - 参数值数组。

### operator func ==(Apply)

```cangjie
public operator func ==(other: Apply): Bool
```

功能：引用比较，判断两个 Apply 是否为同一实例。

参数：

- other: Apply - 另一函数调用表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let calleeFunc = pkg.addFunction(FuncType.get([], UnitType.get()), "callee_m", "callee", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let ctx = FuncCallContext([], [], None)
    let expr = Apply.create(calleeFunc, ctx)
    block.appendExpr(expr)
    println("op_eq_Apply: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Apply: true
```

## class TryApply

```cangjie
public class TryApply <: ApplyBase & Equatable<TryApply> {}
```

功能：带异常处理的函数调用表达式，调用成功时跳转到正常分支，抛出异常时跳转到异常分支。

父类型：

- ApplyBase
- Equatable\<TryApply>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

功能：正常分支目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let calleeFunc = pkg.addFunction(FuncType.get([], UnitType.get()), "callee_m", "callee", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let ctx = FuncCallContext([], [], None)
    let expr = TryApply.create(calleeFunc, ctx, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("prop_normalBranch: ${expr.normalBranch == normalBlock}")
}
```

运行结果：

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

功能：异常分支目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let calleeFunc = pkg.addFunction(FuncType.get([], UnitType.get()), "callee_m", "callee", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let ctx = FuncCallContext([], [], None)
    let expr = TryApply.create(calleeFunc, ctx, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("prop_errorBranch: ${expr.errorBranch == errorBlock}")
}
```

运行结果：

```text
prop_errorBranch: true
```

### static func create(Value, FuncCallContext, Block, Block)

```cangjie
public static func create(callee: Value, funcCallCtx: FuncCallContext, normal: Block, err: Block): TryApply
```

功能：创建带异常处理的函数调用表达式。

参数：

- callee: Value - 被调用函数值。
- funcCallCtx: FuncCallContext - 函数调用上下文。
- normal: Block - 正常分支目标块。
- err: Block - 异常分支目标块。

返回值：

- [TryApply](#class-tryapply) - 创建的带异常处理的函数调用表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let calleeFunc = pkg.addFunction(FuncType.get([], UnitType.get()), "callee_m", "callee", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let ctx = FuncCallContext([], [], None)
    let expr = TryApply.create(calleeFunc, ctx, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

功能：返回此调用表达式的实际参数列表。

返回值：

- Array\<Value> - 参数值数组。

### operator func ==(TryApply)

```cangjie
public operator func ==(other: TryApply): Bool
```

功能：引用比较，判断两个 TryApply 是否为同一实例。

参数：

- other: TryApply - 另一带异常处理的函数调用表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let calleeFunc = pkg.addFunction(FuncType.get([], UnitType.get()), "callee_m", "callee", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let ctx = FuncCallContext([], [], None)
    let expr = TryApply.create(calleeFunc, ctx, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("op_eq_TryApply: ${expr == expr}")
}
```

运行结果：

```text
op_eq_TryApply: true
```

## class IntrinsicBase

```cangjie
sealed abstract class IntrinsicBase <: FuncCall & Equatable<IntrinsicBase> {}
```

功能：内置函数（Intrinsic）调用类表达式的抽象基类，是 [Intrinsic](#class-intrinsic)、[TryIntrinsic](#class-tryintrinsic) 的父类型。

父类型：

- [FuncCall](#class-funccall)
- Equatable\<[IntrinsicBase](#class-intrinsicbase)>

### operator func ==(IntrinsicBase)

```cangjie
public operator func ==(other: IntrinsicBase): Bool
```

功能：引用比较，判断两个 IntrinsicBase 是否为同一实例。

参数：

- other: [IntrinsicBase](#class-intrinsicbase) - 另一 Intrinsic 基类表达式。

返回值：

- Bool - 是否为同一引用。

## class Intrinsic

```cangjie
public class Intrinsic <: IntrinsicBase & Equatable<Intrinsic> {}
```

功能：内建函数调用表达式（不带异常处理），表示对编译器内建函数（如 `sizeof`、`alignof` 等）的调用。Intrinsic 实例由编译器内部流程创建，可通过遍历 Block 的 `exprs` 列表访问已有的 Intrinsic 表达式。

父类型：

- IntrinsicBase
- Equatable\<Intrinsic>

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

功能：返回此调用表达式的实际参数列表。

返回值：

- Array\<Value> - 参数值数组。

### operator func ==(Intrinsic)

```cangjie
public operator func ==(other: Intrinsic): Bool
```

功能：引用比较，判断两个 Intrinsic 是否为同一实例。

参数：

- other: Intrinsic - 另一内建函数调用表达式。

返回值：

- Bool - 是否为同一引用。

## class TryIntrinsic

```cangjie
public class TryIntrinsic <: IntrinsicBase & Equatable<TryIntrinsic> {}
```

功能：带异常处理的内建函数调用表达式。TryIntrinsic 实例由编译器内部流程创建，可通过遍历 Block 的 `exprs` 列表访问已有的 TryIntrinsic 表达式。

父类型：

- IntrinsicBase
- Equatable\<TryIntrinsic>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

功能：正常分支目标块。

类型：Block

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

功能：异常分支目标块。

类型：Block

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

功能：返回此调用表达式的实际参数列表。

返回值：

- Array\<Value> - 参数值数组。

### operator func ==(TryIntrinsic)

```cangjie
public operator func ==(other: TryIntrinsic): Bool
```

功能：引用比较，判断两个 TryIntrinsic 是否为同一实例。

参数：

- other: TryIntrinsic - 另一带异常处理的内建函数调用表达式。

返回值：

- Bool - 是否为同一引用。

## class InvokeBase

```cangjie
sealed abstract class InvokeBase <: FuncCall & Equatable<InvokeBase> {}
```

功能：成员方法调用（Invoke）类表达式的抽象基类，是 [Invoke](#class-invoke)、[TryInvoke](#class-tryinvoke) 的父类型，提供方法名、方法类型及方法泛型形参的查询能力。

父类型：

- [FuncCall](#class-funccall)
- Equatable\<[InvokeBase](#class-invokebase)>

### prop methodGenericTypeParams

```cangjie
public prop methodGenericTypeParams: Array<GenericType>
```

功能：该成员方法调用的方法泛型形参列表。

类型：Array\<[GenericType](#class-generictype)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let virMethodCtx = FuncSigInfo("m", FuncType.get([], UnitType.get()))
    let invokeCtx = InvokeCallContext(f, virMethodCtx, FuncCallContext([], [], None))
    let expr = Invoke.create(UnitType.get(), invokeCtx)
    block.appendExpr(expr)
    println("prop_methodGenericTypeParams: ${expr.methodGenericTypeParams.size}")
}
```

运行结果：

```text
prop_methodGenericTypeParams: 0
```

### prop methodName

```cangjie
public prop methodName: String
```

功能：该成员方法调用的方法名。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let virMethodCtx = FuncSigInfo("m", FuncType.get([], UnitType.get()))
    let invokeCtx = InvokeCallContext(f, virMethodCtx, FuncCallContext([], [], None))
    let expr = Invoke.create(UnitType.get(), invokeCtx)
    block.appendExpr(expr)
    println("prop_methodName: ${expr.methodName}")
}
```

运行结果：

```text
prop_methodName: m
```

### prop methodType

```cangjie
public prop methodType: FuncType
```

功能：该成员方法调用的方法类型。

类型：[FuncType](#class-functype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let virMethodCtx = FuncSigInfo("m", FuncType.get([], UnitType.get()))
    let invokeCtx = InvokeCallContext(f, virMethodCtx, FuncCallContext([], [], None))
    let expr = Invoke.create(UnitType.get(), invokeCtx)
    block.appendExpr(expr)
    println("prop_methodType: ${expr.methodType.qualifiedName}")
}
```

运行结果：

```text
prop_methodType: ()->Unit
```

### operator func ==(InvokeBase)

```cangjie
public operator func ==(other: InvokeBase): Bool
```

功能：引用比较，判断两个 InvokeBase 是否为同一实例。

参数：

- other: [InvokeBase](#class-invokebase) - 另一 Invoke 基类表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let virMethodCtx = FuncSigInfo("m", FuncType.get([], UnitType.get()))
    let invokeCtx = InvokeCallContext(f, virMethodCtx, FuncCallContext([], [], None))
    let expr = Invoke.create(UnitType.get(), invokeCtx)
    block.appendExpr(expr)
    println("op_eq_InvokeBase: ${expr == expr}")
}
```

运行结果：

```text
op_eq_InvokeBase: true
```

## class Invoke

```cangjie
public class Invoke <: InvokeBase & Equatable<Invoke> {}
```

功能：虚方法调用（Invoke）表达式，表示对实例方法的虚调用。

父类型：

- InvokeBase
- Equatable\<Invoke>

### static func create(Type, InvokeCallContext)

```cangjie
public static func create(retTy: Type, callContext: InvokeCallContext): Invoke
```

功能：创建虚方法调用表达式。

参数：

- retTy: Type - 返回类型。
- callContext: InvokeCallContext - 虚方法调用上下文。

返回值：

- [Invoke](#class-invoke) - 创建的虚方法调用表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("method", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    let expr = Invoke.create(UnitType.get(), ctx)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

功能：返回此调用表达式的实际参数列表。

返回值：

- Array\<Value> - 参数值数组。

### operator func ==(Invoke)

```cangjie
public operator func ==(other: Invoke): Bool
```

功能：引用比较，判断两个 Invoke 是否为同一实例。

参数：

- other: Invoke - 另一虚方法调用表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("method", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    let expr = Invoke.create(UnitType.get(), ctx)
    block.appendExpr(expr)
    println("op_eq_Invoke: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Invoke: true
```

## class TryInvoke

```cangjie
public class TryInvoke <: InvokeBase & Equatable<TryInvoke> {}
```

功能：带异常处理的虚方法调用表达式，调用成功时跳转到正常分支，抛出异常时跳转到异常分支。

父类型：

- InvokeBase
- Equatable\<TryInvoke>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

功能：正常分支目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("method", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    let expr = TryInvoke.create(UnitType.get(), ctx, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("prop_normalBranch: ${expr.normalBranch == normalBlock}")
}
```

运行结果：

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

功能：异常分支目标块。

类型：Block

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("method", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    let expr = TryInvoke.create(UnitType.get(), ctx, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("prop_errorBranch: ${expr.errorBranch == errorBlock}")
}
```

运行结果：

```text
prop_errorBranch: true
```

### static func create(Type, InvokeCallContext, Block, Block)

```cangjie
public static func create(retTy: Type, callContext: InvokeCallContext, normal: Block, err: Block): TryInvoke
```

功能：创建带异常处理的虚方法调用表达式。

参数：

- retTy: Type - 返回类型。
- callContext: InvokeCallContext - 虚方法调用上下文。
- normal: Block - 正常分支目标块。
- err: Block - 异常分支目标块。

返回值：

- [TryInvoke](#class-tryinvoke) - 创建的带异常处理的虚方法调用表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("method", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    let expr = TryInvoke.create(UnitType.get(), ctx, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

功能：返回此调用表达式的实际参数列表。

返回值：

- Array\<Value> - 参数值数组。

### operator func ==(TryInvoke)

```cangjie
public operator func ==(other: TryInvoke): Bool
```

功能：引用比较，判断两个 TryInvoke 是否为同一实例。

参数：

- other: TryInvoke - 另一带异常处理的虚方法调用表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errorBlock = bg.appendBlock()
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("method", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    let expr = TryInvoke.create(UnitType.get(), ctx, normalBlock, errorBlock)
    block.appendExpr(expr)
    println("op_eq_TryInvoke: ${expr == expr}")
}
```

运行结果：

```text
op_eq_TryInvoke: true
```

## class GetElementByName

```cangjie
public class GetElementByName <: Expression & Equatable<GetElementByName> {}
```

功能：按字段名读取聚合体元素的表达式，返回元素的引用。

父类型：

- Expression
- Equatable\<GetElementByName>

### prop fieldNames

```cangjie
public prop fieldNames: Array<String>
```

功能：字段名路径。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = GetElementByName.create(alloc.result, ArrayList<String>(["x"]))
    block.appendExpr(expr)
    println("prop_fieldNames: ${expr.fieldNames.size}")
}
```

运行结果：

```text
prop_fieldNames: 1
```

### static func create(Value, ArrayList\<String>)

```cangjie
public static func create(location: Value, fieldNames: ArrayList<String>): GetElementByName
```

功能：创建按字段名读取聚合体元素的表达式。

参数：

- location: Value - 源聚合体值。
- fieldNames: ArrayList\<String> - 字段名路径。

返回值：

- [GetElementByName](#class-getelementbyname) - 创建的元素读取表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = GetElementByName.create(alloc.result, ArrayList<String>(["x"]))
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 2
```

### operator func ==(GetElementByName)

```cangjie
public operator func ==(other: GetElementByName): Bool
```

功能：引用比较，判断两个 GetElementByName 是否为同一实例。

参数：

- other: GetElementByName - 另一元素读取表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = GetElementByName.create(alloc.result, ArrayList<String>(["x"]))
    block.appendExpr(expr)
    println("op_eq_GetElementByName: ${expr == expr}")
}
```

运行结果：

```text
op_eq_GetElementByName: true
```

## class GetElementRef

```cangjie
public class GetElementRef <: Expression & Equatable<GetElementRef> {}
```

功能：按数字索引读取聚合体元素引用的表达式，返回元素的引用。

父类型：

- Expression
- Equatable\<GetElementRef>

### prop path

```cangjie
public prop path: Array<UInt64>
```

功能：索引路径。

类型：Array\<UInt64>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = GetElementRef.create(alloc.result, ArrayList<UInt64>([0]))
    block.appendExpr(expr)
    println("prop_path: ${expr.path.size}")
}
```

运行结果：

```text
prop_path: 1
```

### static func create(Value, ArrayList\<UInt64>)

```cangjie
public static func create(location: Value, path: ArrayList<UInt64>): GetElementRef
```

功能：创建按数字索引读取聚合体元素引用的表达式。

参数：

- location: Value - 源聚合体值。
- path: ArrayList\<UInt64> - 索引路径。

返回值：

- [GetElementRef](#class-getelementref) - 创建的元素引用读取表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = GetElementRef.create(alloc.result, ArrayList<UInt64>([0]))
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 2
```

### operator func ==(GetElementRef)

```cangjie
public operator func ==(other: GetElementRef): Bool
```

功能：引用比较，判断两个 GetElementRef 是否为同一实例。

参数：

- other: GetElementRef - 另一元素引用读取表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    st.appendInstanceMemberVar("x", IntType.getInt32())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let alloc = Allocate.create(StructType.get(st, []))
    block.appendExpr(alloc)
    let expr = GetElementRef.create(alloc.result, ArrayList<UInt64>([0]))
    block.appendExpr(expr)
    println("op_eq_GetElementRef: ${expr == expr}")
}
```

运行结果：

```text
op_eq_GetElementRef: true
```

## class GetException

```cangjie
public class GetException <: Expression & Equatable<GetException> {}
```

功能：获取异常值的表达式，在异常处理 landing pad 块中用于读取捕获到的异常对象。

父类型：

- Expression
- Equatable\<GetException>

### static func create(Type)

```cangjie
public static func create(retTy: Type): GetException
```

功能：创建获取异常值的表达式。

参数：

- retTy: Type - 异常值的类型。

返回值：

- [GetException](#class-getexception) - 创建的获取异常值表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = GetException.create(IntType.getInt32())
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(GetException)

```cangjie
public operator func ==(other: GetException): Bool
```

功能：引用比较，判断两个 GetException 是否为同一实例。

参数：

- other: GetException - 另一获取异常值表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = GetException.create(IntType.getInt32())
    block.appendExpr(expr)
    println("op_eq_GetException: ${expr == expr}")
}
```

运行结果：

```text
op_eq_GetException: true
```

## class GetInstantiateValue

```cangjie
public class GetInstantiateValue <: Expression & Equatable<GetInstantiateValue> {}
```

功能：获取泛型函数实例化值的表达式，用于表示泛型函数的单态化实例。

父类型：

- Expression
- Equatable\<GetInstantiateValue>

### prop instantiateTypes

```cangjie
public prop instantiateTypes: Array<Type>
```

功能：实例化类型参数。

类型：Array\<Type>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let g = pkg.addFunction(FuncType.get([], UnitType.get()), "g_m", "g", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = GetInstantiateValue.create(g, ArrayList<Type>())
    block.appendExpr(expr)
    println("prop_instantiateTypes: ${expr.instantiateTypes.size}")
}
```

运行结果：

```text
prop_instantiateTypes: 0
```

### static func create(Function, ArrayList\<Type>)

```cangjie
public static func create(val: Function, instantiateTypes: ArrayList<Type>): GetInstantiateValue
```

功能：创建获取泛型函数实例化值的表达式。

参数：

- val: Function - 目标函数。
- instantiateTypes: ArrayList\<Type> - 实例化类型参数。

返回值：

- [GetInstantiateValue](#class-getinstantiatevalue) - 创建的实例化值表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let g = pkg.addFunction(FuncType.get([], UnitType.get()), "g_m", "g", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = GetInstantiateValue.create(g, ArrayList<Type>())
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(GetInstantiateValue)

```cangjie
public operator func ==(other: GetInstantiateValue): Bool
```

功能：引用比较，判断两个 GetInstantiateValue 是否为同一实例。

参数：

- other: GetInstantiateValue - 另一实例化值表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let g = pkg.addFunction(FuncType.get([], UnitType.get()), "g_m", "g", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = GetInstantiateValue.create(g, ArrayList<Type>())
    block.appendExpr(expr)
    println("op_eq_GetInstantiateValue: ${expr == expr}")
}
```

运行结果：

```text
op_eq_GetInstantiateValue: true
```

## class GetRTTI

```cangjie
public class GetRTTI <: Expression & Equatable<GetRTTI> {}
```

功能：获取运行时类型信息的表达式，从值中提取 RTTI 数据。

父类型：

- Expression
- Equatable\<GetRTTI>

### static func create(Value)

```cangjie
public static func create(val: Value): GetRTTI
```

功能：创建获取运行时类型信息的表达式。

参数：

- val: Value - 目标值。

返回值：

- [GetRTTI](#class-getrtti) - 创建的 RTTI 获取表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let val = IntLiteral.get(IntType.getInt32(), 0)
    let expr = GetRTTI.create(val)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(GetRTTI)

```cangjie
public operator func ==(other: GetRTTI): Bool
```

功能：引用比较，判断两个 GetRTTI 是否为同一实例。

参数：

- other: GetRTTI - 另一 RTTI 获取表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let val = IntLiteral.get(IntType.getInt32(), 0)
    let expr = GetRTTI.create(val)
    block.appendExpr(expr)
    println("op_eq_GetRTTI: ${expr == expr}")
}
```

运行结果：

```text
op_eq_GetRTTI: true
```

## class GetRTTIStatic

```cangjie
public class GetRTTIStatic <: Expression & Equatable<GetRTTIStatic> {}
```

功能：静态获取运行时类型信息的表达式，从类型直接提取 RTTI 数据（不依赖值实例）。

父类型：

- Expression
- Equatable\<GetRTTIStatic>

### prop ty

```cangjie
public prop ty: Type
```

功能：目标类型。

类型：Type

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = GetRTTIStatic.create(IntType.getInt32())
    block.appendExpr(expr)
    println("prop_ty: ${expr.ty.toString()}")
}
```

运行结果：

```text
prop_ty: Int32
```

### static func create(Type)

```cangjie
public static func create(ty: Type): GetRTTIStatic
```

功能：创建静态获取运行时类型信息的表达式。

参数：

- ty: Type - 目标类型。

返回值：

- [GetRTTIStatic](#class-getrttistatic) - 创建的静态 RTTI 获取表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = GetRTTIStatic.create(IntType.getInt32())
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(GetRTTIStatic)

```cangjie
public operator func ==(other: GetRTTIStatic): Bool
```

功能：引用比较，判断两个 GetRTTIStatic 是否为同一实例。

参数：

- other: GetRTTIStatic - 另一静态 RTTI 获取表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = GetRTTIStatic.create(IntType.getInt32())
    block.appendExpr(expr)
    println("op_eq_GetRTTIStatic: ${expr == expr}")
}
```

运行结果：

```text
op_eq_GetRTTIStatic: true
```

## class GoTo

```cangjie
public class GoTo <: Expression & Equatable<GoTo> {}
```

功能：无条件跳转终止器表达式，直接跳转到目标基本块。

父类型：

- Expression
- Equatable\<GoTo>

### static func create(Block)

```cangjie
public static func create(target: Block): GoTo
```

功能：创建无条件跳转终止器表达式。

参数：

- target: Block - 跳转目标块。

返回值：

- [GoTo](#class-goto) - 创建的无条件跳转表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let target = bg.appendBlock()
    let expr = GoTo.create(target)
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(GoTo)

```cangjie
public operator func ==(other: GoTo): Bool
```

功能：引用比较，判断两个 GoTo 是否为同一实例。

参数：

- other: GoTo - 另一无条件跳转表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let block = bg.entryBlock
    let target = bg.appendBlock()
    let expr = GoTo.create(target)
    block.appendExpr(expr)
    println("op_eq_GoTo: ${expr == expr}")
}
```

运行结果：

```text
op_eq_GoTo: true
```

## class InstanceOf

```cangjie
public class InstanceOf <: Expression & Equatable<InstanceOf> {}
```

功能：类型检查表达式，判断源值是否属于目标类型，返回布尔结果。

父类型：

- Expression
- Equatable\<InstanceOf>

### prop targetType

```cangjie
public prop targetType: Type
```

功能：目标类型。

类型：Type

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let srcVal = IntLiteral.get(IntType.getInt32(), 0)
    let expr = InstanceOf.create(srcVal, IntType.getInt32())
    block.appendExpr(expr)
    println("prop_targetType: ${expr.targetType.toString()}")
}
```

运行结果：

```text
prop_targetType: Int32
```

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetTy: Type): InstanceOf
```

功能：创建类型检查表达式。

参数：

- srcVal: Value - 要检查的源值。
- targetTy: Type - 目标类型。

返回值：

- [InstanceOf](#class-instanceof) - 创建的类型检查表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let srcVal = IntLiteral.get(IntType.getInt32(), 0)
    let expr = InstanceOf.create(srcVal, IntType.getInt32())
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### operator func ==(InstanceOf)

```cangjie
public operator func ==(other: InstanceOf): Bool
```

功能：引用比较，判断两个 InstanceOf 是否为同一实例。

参数：

- other: InstanceOf - 另一类型检查表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let srcVal = IntLiteral.get(IntType.getInt32(), 0)
    let expr = InstanceOf.create(srcVal, IntType.getInt32())
    block.appendExpr(expr)
    println("op_eq_InstanceOf: ${expr == expr}")
}
```

运行结果：

```text
op_eq_InstanceOf: true
```

## class Lambda

```cangjie
public class Lambda <: Expression & Equatable<Lambda> {}
```

功能：Lambda / 局部函数表达式，表示一个嵌套的匿名函数或局部函数定义。

父类型：

- Expression
- Equatable\<Lambda>

### prop identifier

```cangjie
public prop identifier: String
```

功能：内部标识，全局唯一标识符。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    println("prop_identifier: ${expr.identifier}")
}
```

运行结果：

```text
prop_identifier: lambda_m
```

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

功能：源码名。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    println("prop_srcCodeName: ${expr.srcCodeName}")
}
```

运行结果：

```text
prop_srcCodeName: myLambda
```

### prop funcType

```cangjie
public prop funcType: FuncType
```

功能：函数类型。

类型：[FuncType](#class-functype)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    println("prop_funcType: ${expr.funcType.toString()}")
}
```

运行结果：

```text
prop_funcType: () -> Unit
```

### prop genericTypeParams

```cangjie
public prop genericTypeParams: Array<GenericType>
```

功能：泛型形参。

类型：Array\<[GenericType](#class-generictype)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    println("prop_genericTypeParams: ${expr.genericTypeParams.size}")
}
```

运行结果：

```text
prop_genericTypeParams: 0
```

### prop parameters

```cangjie
public prop parameters: Array<Parameter>
```

功能：参数列表。

类型：Array\<[Parameter](#class-parameter)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([IntType.getInt32()], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    expr.initParameters()
    println("prop_parameters: ${expr.parameters.size}")
}
```

运行结果：

```text
prop_parameters: 1
```

### prop body

```cangjie
public prop body: BlockGroup
```

功能：Lambda 体。

类型：[BlockGroup](#class-blockgroup)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    expr.initBody()
    println("prop_body: ${expr.body.blocks.size > 0}")
}
```

运行结果：

```text
prop_body: true
```

### prop isCompileTimeValue

```cangjie
public mut prop isCompileTimeValue: Bool
```

功能：是否为编译期值；getter 返回当前标记，setter 可修改。

类型：Bool

### prop isLocalFunc

```cangjie
public mut prop isLocalFunc: Bool
```

功能：是否为局部函数；getter 返回当前标记，setter 可修改。

类型：Bool

### prop returnValue

```cangjie
public mut prop returnValue: LocalVar
```

功能：Lambda 的返回值变量。

类型：[LocalVar](#class-localvar)

### static func create(FuncType, String, String, ArrayList\<GenericType>)

```cangjie
public static func create(ty: FuncType, identifier: String, srcName: String, genericTypeParams: ArrayList<GenericType>): Lambda
```

功能：创建 Lambda / 局部函数表达式。

参数：

- ty: FuncType - 函数类型。
- identifier: String - 内部标识（混淆名）。
- srcName: String - 源码名。
- genericTypeParams: ArrayList\<GenericType> - 泛型形参列表。

返回值：

- [Lambda](#class-lambda) - 创建的 Lambda 表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    println("static_func_create: ${block.exprs.size}")
}
```

运行结果：

```text
static_func_create: 1
```

### func initBody()

```cangjie
public func initBody(): Unit
```

功能：初始化 Lambda 体，创建入口 BlockGroup 和 Block。调用前需确保 Lambda 已被追加到某基本块中。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    expr.initBody()
    println("fn_initBody: ${expr.body.blocks.size > 0}")
}
```

运行结果：

```text
fn_initBody: true
```

### func initParameters()

```cangjie
public func initParameters(): Unit
```

功能：根据 `funcType` 的参数类型初始化 Lambda 参数列表。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([IntType.getInt32()], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    expr.initParameters()
    println("fn_initParameters: ${expr.parameters.size}")
}
```

运行结果：

```text
fn_initParameters: 1
```

### func toString()

```cangjie
public func toString(): String
```

功能：Lambda 的字符串形式。

返回值：

- String - Lambda 的可读文本转储。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    expr.initBody()
    println("fn_toString: ${expr.toString().size > 0}")
}
```

运行结果：

```text
fn_toString: true
```

### operator func ==(Lambda)

```cangjie
public operator func ==(other: Lambda): Bool
```

功能：引用比较，判断两个 Lambda 是否为同一实例。

参数：

- other: Lambda - 另一 Lambda 表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let lambdaType = FuncType.get([], UnitType.get())
    let expr = Lambda.create(lambdaType, "lambda_m", "myLambda", ArrayList<GenericType>())
    block.appendExpr(expr)
    println("op_eq_Lambda: ${expr == expr}")
}
```

运行结果：

```text
op_eq_Lambda: true
```

## class Load

```cangjie
public class Load <: Expression & Equatable<Load> {}
```

功能：内存加载表达式。

父类型：

- Expression
- Equatable\<Load>

### prop srcAddress

```cangjie
public prop srcAddress: Value
```

功能：源地址。

类型：Value

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([CPointerType.get(IntType.getInt32())], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let load = Load.create(param)
    println("prop_srcAddress: ${load.srcAddress == param}")
}
```

运行结果：

```text
prop_srcAddress: true
```

### static func create(Value)

```cangjie
public static func create(location: Value): Load
```

功能：创建内存加载表达式，从指定地址加载值。

参数：

- location: Value - 源地址值。

返回值：

- [Load](#class-load) - 内存加载表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([CPointerType.get(IntType.getInt32())], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let load = Load.create(param)
    println("static_create: ${load.srcAddress == param}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(Load)

```cangjie
public operator func ==(other: Load): Bool
```

功能：引用比较，判断两个 Load 是否为同一实例。

参数：

- other: Load - 另一内存加载表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([CPointerType.get(IntType.getInt32())], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let load = Load.create(param)
    println("op_eq_Load: ${load == load}")
}
```

运行结果：

```text
op_eq_Load: true
```

## class MultiBranch

```cangjie
public class MultiBranch <: Expression & Equatable<MultiBranch> {}
```

功能：多分支（switch-case）终止器表达式。

父类型：

- Expression
- Equatable\<MultiBranch>

### prop condition

```cangjie
public prop condition: Value
```

功能：条件值。

类型：Value

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let defaultBlock = f.body.getOrThrow().appendBlock()
    let caseBlock = f.body.getOrThrow().appendBlock()
    let targets = ArrayList<Block>()
    targets.add(caseBlock)
    let caseValues = ArrayList<UInt64>()
    caseValues.add(1)
    let param = f.parameters[0]
    let mb = MultiBranch.create(param, defaultBlock, targets, caseValues)
    println("prop_condition: ${mb.condition == param}")
}
```

运行结果：

```text
prop_condition: true
```

### prop defaultTarget

```cangjie
public prop defaultTarget: Block
```

功能：默认目标块。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let defaultBlock = f.body.getOrThrow().appendBlock()
    let caseBlock = f.body.getOrThrow().appendBlock()
    let targets = ArrayList<Block>()
    targets.add(caseBlock)
    let caseValues = ArrayList<UInt64>()
    caseValues.add(1)
    let param = f.parameters[0]
    let mb = MultiBranch.create(param, defaultBlock, targets, caseValues)
    println("prop_defaultTarget: ${mb.defaultTarget == defaultBlock}")
}
```

运行结果：

```text
prop_defaultTarget: true
```

### prop targetsWithoutDefault

```cangjie
public prop targetsWithoutDefault: Array<Block>
```

功能：非 default 的目标块。

类型：Array\<[Block](#class-block)>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let defaultBlock = f.body.getOrThrow().appendBlock()
    let caseBlock = f.body.getOrThrow().appendBlock()
    let targets = ArrayList<Block>()
    targets.add(caseBlock)
    let caseValues = ArrayList<UInt64>()
    caseValues.add(1)
    let param = f.parameters[0]
    let mb = MultiBranch.create(param, defaultBlock, targets, caseValues)
    println("prop_targetsWithoutDefault: ${mb.targetsWithoutDefault.size}")
}
```

运行结果：

```text
prop_targetsWithoutDefault: 1
```

### prop caseValues

```cangjie
public prop caseValues: Array<UInt64>
```

功能：各 case 的匹配值。

类型：Array\<UInt64>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let defaultBlock = f.body.getOrThrow().appendBlock()
    let caseBlock = f.body.getOrThrow().appendBlock()
    let targets = ArrayList<Block>()
    targets.add(caseBlock)
    let caseValues = ArrayList<UInt64>()
    caseValues.add(1)
    let param = f.parameters[0]
    let mb = MultiBranch.create(param, defaultBlock, targets, caseValues)
    println("prop_caseValues: ${mb.caseValues.size}")
}
```

运行结果：

```text
prop_caseValues: 1
```

### static func create(Value, Block, ArrayList\<Block>, ArrayList\<UInt64>)

```cangjie
public static func create(condition: Value, default: Block, targets: ArrayList<Block>, caseValues: ArrayList<UInt64>): MultiBranch
```

功能：创建多分支终止器表达式，指定条件值、默认目标块、case 目标块列表及各 case 的匹配值。

参数：

- condition: Value - 条件值。
- default: Block - 默认目标块。
- targets: ArrayList\<Block> - 非 default 的目标块列表。
- caseValues: ArrayList\<UInt64> - 各 case 的匹配值。

返回值：

- [MultiBranch](#class-multibranch) - 多分支终止器表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let defaultBlock = f.body.getOrThrow().appendBlock()
    let caseBlock = f.body.getOrThrow().appendBlock()
    let targets = ArrayList<Block>()
    targets.add(caseBlock)
    let caseValues = ArrayList<UInt64>()
    caseValues.add(1)
    let param = f.parameters[0]
    let mb = MultiBranch.create(param, defaultBlock, targets, caseValues)
    println("static_create: ${mb.condition == param}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(MultiBranch)

```cangjie
public operator func ==(other: MultiBranch): Bool
```

功能：引用比较，判断两个 MultiBranch 是否为同一实例。

参数：

- other: MultiBranch - 另一多分支终止器表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let defaultBlock = f.body.getOrThrow().appendBlock()
    let caseBlock = f.body.getOrThrow().appendBlock()
    let targets = ArrayList<Block>()
    targets.add(caseBlock)
    let caseValues = ArrayList<UInt64>()
    caseValues.add(1)
    let param = f.parameters[0]
    let mb = MultiBranch.create(param, defaultBlock, targets, caseValues)
    println("op_eq_MultiBranch: ${mb == mb}")
}
```

运行结果：

```text
op_eq_MultiBranch: true
```

## class NumericCastBase

```cangjie
sealed abstract class NumericCastBase <: Expression & Equatable<NumericCastBase> {}
```

功能：数值类型转换表达式的抽象基类，是 [NumericCast](#class-numericcast)、[TryNumericCast](#class-trynumericcast) 的父类型，提供溢出策略的查询与设置能力。

父类型：

- [Expression](#class-expression)
- Equatable\<[NumericCastBase](#class-numericcastbase)>

### prop overflow

```cangjie
public mut prop overflow: OverflowStrategy
```

功能：该数值转换表达式使用的溢出策略；可读可写。

类型：[OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createNumericCast(IntLiteral.get(IntType.getInt64(), 1), IntType.getInt32(), OverflowStrategy.NA)
    println("prop_overflow: ${expr.overflow}")
}
```

运行结果：

```text
prop_overflow: NA
```

### operator func ==(NumericCastBase)

```cangjie
public operator func ==(other: NumericCastBase): Bool
```

功能：引用比较，判断两个 NumericCastBase 是否为同一实例。

参数：

- other: [NumericCastBase](#class-numericcastbase) - 另一数值转换基类表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createNumericCast(IntLiteral.get(IntType.getInt64(), 1), IntType.getInt32(), OverflowStrategy.NA)
    println("op_eq_NumericCastBase: ${expr == expr}")
}
```

运行结果：

```text
op_eq_NumericCastBase: true
```

## class NumericCast

```cangjie
public class NumericCast <: NumericCastBase & Equatable<NumericCast> {}
```

功能：数值类型转换表达式。

父类型：

- NumericCastBase
- Equatable\<NumericCast>

### static func create(Value, Type, OverflowStrategy)

```cangjie
public static func create(srcVal: Value, targetType: Type, overflow: OverflowStrategy): NumericCast
```

功能：创建数值类型转换表达式，将源值转换为目标类型。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标类型。
- overflow: OverflowStrategy - 溢出处理策略。

返回值：

- [NumericCast](#class-numericcast) - 数值类型转换表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = NumericCast.create(param, IntType.getInt64(), OverflowStrategy.Wrapping)
    println("static_create: ${cast.operands[0] == param}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(NumericCast)

```cangjie
public operator func ==(other: NumericCast): Bool
```

功能：引用比较，判断两个 NumericCast 是否为同一实例。

参数：

- other: NumericCast - 另一数值类型转换表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = NumericCast.create(param, IntType.getInt64(), OverflowStrategy.Wrapping)
    println("op_eq_NumericCast: ${cast == cast}")
}
```

运行结果：

```text
op_eq_NumericCast: true
```

## class TryNumericCast

```cangjie
public class TryNumericCast <: NumericCastBase & Equatable<TryNumericCast> {}
```

功能：带异常处理的数值类型转换表达式。

父类型：

- NumericCastBase
- Equatable\<TryNumericCast>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

功能：正常分支目标块。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let cast = TryNumericCast.create(param, IntType.getInt64(), normalBlock, errBlock)
    println("prop_normalBranch: ${cast.normalBranch == normalBlock}")
}
```

运行结果：

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

功能：异常分支目标块。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let cast = TryNumericCast.create(param, IntType.getInt64(), normalBlock, errBlock)
    println("prop_errorBranch: ${cast.errorBranch == errBlock}")
}
```

运行结果：

```text
prop_errorBranch: true
```

### static func create(Value, Type, Block, Block)

```cangjie
public static func create(srcVal: Value, targetType: Type, normal: Block, err: Block): TryNumericCast
```

功能：创建带异常处理的数值类型转换表达式，指定正常分支与异常分支目标块。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标类型。
- normal: Block - 正常分支目标块。
- err: Block - 异常分支目标块。

返回值：

- [TryNumericCast](#class-trynumericcast) - 带异常处理的数值类型转换表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let cast = TryNumericCast.create(param, IntType.getInt64(), normalBlock, errBlock)
    println("static_create: ${cast.normalBranch == normalBlock}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(TryNumericCast)

```cangjie
public operator func ==(other: TryNumericCast): Bool
```

功能：引用比较，判断两个 TryNumericCast 是否为同一实例。

参数：

- other: TryNumericCast - 另一带异常处理的数值类型转换表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let cast = TryNumericCast.create(param, IntType.getInt64(), normalBlock, errBlock)
    println("op_eq_TryNumericCast: ${cast == cast}")
}
```

运行结果：

```text
op_eq_TryNumericCast: true
```

## class RaiseException

```cangjie
public class RaiseException <: Expression & Equatable<RaiseException> {}
```

功能：抛出异常终止器表达式。

父类型：

- Expression
- Equatable\<RaiseException>

### static func create(Value)

```cangjie
public static func create(value: Value): RaiseException
```

功能：创建抛出异常终止器表达式（无后续块版本）。

参数：

- value: Value - 异常值。

返回值：

- [RaiseException](#class-raiseexception) - 抛出异常终止器表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let lit = IntLiteral.get(IntType.getInt32(), 1)
    let expr = Constant.create(lit)
    f.body.getOrThrow().entryBlock.appendExpr(expr)
    let lv = expr.result
    let raise = RaiseException.create(lv)
    println("static_create_noSuccessor: ${raise.result.toString().size > 0}")
}
```

运行结果：

```text
static_create_noSuccessor: true
```

### static func create(Value, Block)

```cangjie
public static func create(value: Value, successor: Block): RaiseException
```

功能：创建抛出异常终止器表达式（带后续块版本）。

参数：

- value: Value - 异常值。
- successor: Block - 后续块。

返回值：

- [RaiseException](#class-raiseexception) - 抛出异常终止器表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let successor = f.body.getOrThrow().appendBlock()
    let lit = IntLiteral.get(IntType.getInt32(), 1)
    let expr = Constant.create(lit)
    f.body.getOrThrow().entryBlock.appendExpr(expr)
    let lv = expr.result
    let raise = RaiseException.create(lv, successor)
    println("static_create_withSuccessor: done")
}
```

运行结果：

```text
static_create_withSuccessor: done
```

### operator func ==(RaiseException)

```cangjie
public operator func ==(other: RaiseException): Bool
```

功能：引用比较，判断两个 RaiseException 是否为同一实例。

参数：

- other: RaiseException - 另一抛出异常终止器表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let lit = IntLiteral.get(IntType.getInt32(), 1)
    let expr = Constant.create(lit)
    f.body.getOrThrow().entryBlock.appendExpr(expr)
    let lv = expr.result
    let raise = RaiseException.create(lv)
    println("op_eq_RaiseException: ${raise == raise}")
}
```

运行结果：

```text
op_eq_RaiseException: true
```

## class RawArrayAllocateBase

```cangjie
sealed abstract class RawArrayAllocateBase <: Expression & Equatable<RawArrayAllocateBase> {}
```

功能：原始数组分配表达式的抽象基类，是 [RawArrayAllocate](#class-rawarrayallocate)、[TryRawArrayAllocate](#class-tryrawarrayallocate) 的父类型，提供所分配元素类型的查询能力。

父类型：

- [Expression](#class-expression)
- Equatable\<[RawArrayAllocateBase](#class-rawarrayallocatebase)>

### prop elementType

```cangjie
public prop elementType: Type
```

功能：该分配表达式所分配的元素类型。

类型：[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = RawArrayAllocate.create(IntType.getInt32(), IntLiteral.get(IntType.getInt64(), 4))
    block.appendExpr(expr)
    println("prop_elementType: ${expr.elementType.qualifiedName}")
}
```

运行结果：

```text
prop_elementType: Int32
```

### operator func ==(RawArrayAllocateBase)

```cangjie
public operator func ==(other: RawArrayAllocateBase): Bool
```

功能：引用比较，判断两个 RawArrayAllocateBase 是否为同一实例。

参数：

- other: [RawArrayAllocateBase](#class-rawarrayallocatebase) - 另一原始数组分配基类表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let expr = RawArrayAllocate.create(IntType.getInt32(), IntLiteral.get(IntType.getInt64(), 4))
    block.appendExpr(expr)
    println("op_eq_RawArrayAllocateBase: ${expr == expr}")
}
```

运行结果：

```text
op_eq_RawArrayAllocateBase: true
```

## class RawArrayAllocate

```cangjie
public class RawArrayAllocate <: RawArrayAllocateBase & Equatable<RawArrayAllocate> {}
```

功能：原始数组分配表达式。

父类型：

- RawArrayAllocateBase
- Equatable\<RawArrayAllocate>

### static func create(Type, Value)

```cangjie
public static func create(elementType: Type, size: Value): RawArrayAllocate
```

功能：创建原始数组分配表达式，指定元素类型与数组大小。

参数：

- elementType: Type - 元素类型。
- size: Value - 数组大小。

返回值：

- [RawArrayAllocate](#class-rawarrayallocate) - 原始数组分配表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let alloc = RawArrayAllocate.create(IntType.getInt32(), param)
    println("static_create: ${alloc.elementType == IntType.getInt32()}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(RawArrayAllocate)

```cangjie
public operator func ==(other: RawArrayAllocate): Bool
```

功能：引用比较，判断两个 RawArrayAllocate 是否为同一实例。

参数：

- other: RawArrayAllocate - 另一原始数组分配表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let alloc = RawArrayAllocate.create(IntType.getInt32(), param)
    println("op_eq_RawArrayAllocate: ${alloc == alloc}")
}
```

运行结果：

```text
op_eq_RawArrayAllocate: true
```

## class TryRawArrayAllocate

```cangjie
public class TryRawArrayAllocate <: RawArrayAllocateBase & Equatable<TryRawArrayAllocate> {}
```

功能：带异常处理的原始数组分配表达式。

父类型：

- RawArrayAllocateBase
- Equatable\<TryRawArrayAllocate>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

功能：正常分支目标块。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let alloc = TryRawArrayAllocate.create(IntType.getInt32(), param, normalBlock, errBlock)
    println("prop_normalBranch: ${alloc.normalBranch == normalBlock}")
}
```

运行结果：

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

功能：异常分支目标块。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let alloc = TryRawArrayAllocate.create(IntType.getInt32(), param, normalBlock, errBlock)
    println("prop_errorBranch: ${alloc.errorBranch == errBlock}")
}
```

运行结果：

```text
prop_errorBranch: true
```

### static func create(Type, Value, Block, Block)

```cangjie
public static func create(elementType: Type, size: Value, normal: Block, err: Block): TryRawArrayAllocate
```

功能：创建带异常处理的原始数组分配表达式，指定正常分支与异常分支目标块。

参数：

- elementType: Type - 元素类型。
- size: Value - 数组大小。
- normal: Block - 正常分支目标块。
- err: Block - 异常分支目标块。

返回值：

- [TryRawArrayAllocate](#class-tryrawarrayallocate) - 带异常处理的原始数组分配表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let alloc = TryRawArrayAllocate.create(IntType.getInt32(), param, normalBlock, errBlock)
    println("static_create: ${alloc.normalBranch == normalBlock}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(TryRawArrayAllocate)

```cangjie
public operator func ==(other: TryRawArrayAllocate): Bool
```

功能：引用比较，判断两个 TryRawArrayAllocate 是否为同一实例。

参数：

- other: TryRawArrayAllocate - 另一带异常处理的原始数组分配表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let alloc = TryRawArrayAllocate.create(IntType.getInt32(), param, normalBlock, errBlock)
    println("op_eq_TryRawArrayAllocate: ${alloc == alloc}")
}
```

运行结果：

```text
op_eq_TryRawArrayAllocate: true
```

## class RawArrayInitByValue

```cangjie
public class RawArrayInitByValue <: Expression & Equatable<RawArrayInitByValue> {}
```

功能：按值初始化原始数组表达式。

父类型：

- Expression
- Equatable\<RawArrayInitByValue>

### static func create(Value, Value, Value)

```cangjie
public static func create(memory: Value, size: Value, initVal: Value): RawArrayInitByValue
```

功能：创建按值初始化原始数组表达式，指定内存地址、数组大小与初始值。

参数：

- memory: Value - 内存地址。
- size: Value - 数组大小。
- initVal: Value - 初始值。

返回值：

- [RawArrayInitByValue](#class-rawarrayinitbyvalue) - 按值初始化原始数组表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32(), IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let mem = f.parameters[0]
    let sz = f.parameters[1]
    let iv = f.parameters[2]
    let initExpr = RawArrayInitByValue.create(mem, sz, iv)
    println("static_create: done")
}
```

运行结果：

```text
static_create: done
```

### operator func ==(RawArrayInitByValue)

```cangjie
public operator func ==(other: RawArrayInitByValue): Bool
```

功能：引用比较，判断两个 RawArrayInitByValue 是否为同一实例。

参数：

- other: RawArrayInitByValue - 另一按值初始化原始数组表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32(), IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let mem = f.parameters[0]
    let sz = f.parameters[1]
    let iv = f.parameters[2]
    let initExpr = RawArrayInitByValue.create(mem, sz, iv)
    println("op_eq_RawArrayInitByValue: ${initExpr == initExpr}")
}
```

运行结果：

```text
op_eq_RawArrayInitByValue: true
```

## class RawArrayLiteralInit

```cangjie
public class RawArrayLiteralInit <: Expression & Equatable<RawArrayLiteralInit> {}
```

功能：字面量初始化原始数组表达式。

父类型：

- Expression
- Equatable\<RawArrayLiteralInit>

### static func create(Value, ArrayList\<Value>)

```cangjie
public static func create(memory: Value, elements: ArrayList<Value>): RawArrayLiteralInit
```

功能：创建字面量初始化原始数组表达式，指定内存地址与元素列表。

参数：

- memory: Value - 内存地址。
- elements: ArrayList\<Value> - 元素值列表。

返回值：

- [RawArrayLiteralInit](#class-rawarrayliteralinit) - 字面量初始化原始数组表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let mem = f.parameters[0]
    let e1 = IntLiteral.get(IntType.getInt32(), 1)
    let e2 = IntLiteral.get(IntType.getInt32(), 2)
    let elements = ArrayList<Value>()
    elements.add(e1)
    elements.add(e2)
    let initExpr = RawArrayLiteralInit.create(mem, elements)
    println("static_create: done")
}
```

运行结果：

```text
static_create: done
```

### operator func ==(RawArrayLiteralInit)

```cangjie
public operator func ==(other: RawArrayLiteralInit): Bool
```

功能：引用比较，判断两个 RawArrayLiteralInit 是否为同一实例。

参数：

- other: RawArrayLiteralInit - 另一字面量初始化原始数组表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let mem = f.parameters[0]
    let e1 = IntLiteral.get(IntType.getInt32(), 1)
    let e2 = IntLiteral.get(IntType.getInt32(), 2)
    let elements = ArrayList<Value>()
    elements.add(e1)
    elements.add(e2)
    let initExpr = RawArrayLiteralInit.create(mem, elements)
    println("op_eq_RawArrayLiteralInit: ${initExpr == initExpr}")
}
```

运行结果：

```text
op_eq_RawArrayLiteralInit: true
```

## class SpawnBase

```cangjie
sealed abstract class SpawnBase <: Expression & Equatable<SpawnBase> {}
```

功能：协程创建（Spawn）表达式的抽象基类，是 [Spawn](#class-spawn)、[TrySpawn](#class-tryspawn) 的父类型，提供执行闭包的查询与设置能力。

父类型：

- [Expression](#class-expression)
- Equatable\<[SpawnBase](#class-spawnbase)>

### prop executeClosure

```cangjie
public mut prop executeClosure: Function
```

功能：该 Spawn 表达式关联的执行闭包；未设置时读取抛出异常。

类型：[Function](#class-function)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createSpawn(UnitType.get(), f)
    println("prop_executeClosure: ${expr.needExecuteClosure()}")
}
```

运行结果：

```text
prop_executeClosure: false
```

### func needExecuteClosure()

```cangjie
public func needExecuteClosure(): Bool
```

功能：判断该 Spawn 表达式是否已设置执行闭包。

返回值：

- Bool - 已设置执行闭包时返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createSpawn(UnitType.get(), f)
    println("func_needExecuteClosure: ${expr.needExecuteClosure()}")
}
```

运行结果：

```text
func_needExecuteClosure: false
```

### operator func ==(SpawnBase)

```cangjie
public operator func ==(other: SpawnBase): Bool
```

功能：引用比较，判断两个 SpawnBase 是否为同一实例。

参数：

- other: [SpawnBase](#class-spawnbase) - 另一 Spawn 基类表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createSpawn(UnitType.get(), f)
    println("op_eq_SpawnBase: ${expr == expr}")
}
```

运行结果：

```text
op_eq_SpawnBase: true
```

## class Spawn

```cangjie
public class Spawn <: SpawnBase & Equatable<Spawn> {}
```

功能：并发 Spawn 表达式（不带异常处理）。

父类型：

- SpawnBase
- Equatable\<Spawn>

### static func create(Type, Value)

```cangjie
public static func create(retTy: Type, lambda: Value): Spawn
```

功能：创建并发 Spawn 表达式（无参数版本）。

参数：

- retTy: Type - 返回类型。
- lambda: Value - lambda 值。

返回值：

- [Spawn](#class-spawn) - Spawn 表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([FuncType.get([], IntType.getInt32())], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let spawnExpr = Spawn.create(IntType.getInt32(), param)
    println("static_create_noArg: ${spawnExpr.result.toString().size > 0}")
}
```

运行结果：

```text
static_create_noArg: true
```

### static func create(Type, Value, Value)

```cangjie
public static func create(retTy: Type, lambda: Value, arg: Value): Spawn
```

功能：创建并发 Spawn 表达式（带参数版本）。

参数：

- retTy: Type - 返回类型。
- lambda: Value - lambda 值。
- arg: Value - Spawn 参数值。

返回值：

- [Spawn](#class-spawn) - Spawn 表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([FuncType.get([IntType.getInt32()], IntType.getInt32()), IntType.getInt32()], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let lambda = f.parameters[0]
    let arg = f.parameters[1]
    let spawnExpr = Spawn.create(IntType.getInt32(), lambda, arg)
    println("static_create_withArg: ${spawnExpr.result.toString().size > 0}")
}
```

运行结果：

```text
static_create_withArg: true
```

### operator func ==(Spawn)

```cangjie
public operator func ==(other: Spawn): Bool
```

功能：引用比较，判断两个 Spawn 是否为同一实例。

参数：

- other: Spawn - 另一 Spawn 表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([FuncType.get([], IntType.getInt32())], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let spawnExpr = Spawn.create(IntType.getInt32(), param)
    println("op_eq_Spawn: ${spawnExpr == spawnExpr}")
}
```

运行结果：

```text
op_eq_Spawn: true
```

## class TrySpawn

```cangjie
public class TrySpawn <: SpawnBase & Equatable<TrySpawn> {}
```

功能：带异常处理的并发 Spawn 表达式。

父类型：

- SpawnBase
- Equatable\<TrySpawn>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

功能：正常分支目标块。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([FuncType.get([], IntType.getInt32())], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let spawnExpr = TrySpawn.create(IntType.getInt32(), param, normalBlock, errBlock)
    println("prop_normalBranch: ${spawnExpr.normalBranch == normalBlock}")
}
```

运行结果：

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

功能：异常分支目标块。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([FuncType.get([], IntType.getInt32())], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let spawnExpr = TrySpawn.create(IntType.getInt32(), param, normalBlock, errBlock)
    println("prop_errorBranch: ${spawnExpr.errorBranch == errBlock}")
}
```

运行结果：

```text
prop_errorBranch: true
```

### static func create(Type, Value, Block, Block)

```cangjie
public static func create(retTy: Type, lambda: Value, normal: Block, err: Block): TrySpawn
```

功能：创建带异常处理的并发 Spawn 表达式（无参数版本）。

参数：

- retTy: Type - 返回类型。
- lambda: Value - lambda 值。
- normal: Block - 正常分支目标块。
- err: Block - 异常分支目标块。

返回值：

- [TrySpawn](#class-tryspawn) - 带异常处理的 Spawn 表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([FuncType.get([], IntType.getInt32())], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let spawnExpr = TrySpawn.create(IntType.getInt32(), param, normalBlock, errBlock)
    println("static_create_noArg: ${spawnExpr.normalBranch == normalBlock}")
}
```

运行结果：

```text
static_create_noArg: true
```

### static func create(Type, Value, Value, Block, Block)

```cangjie
public static func create(retTy: Type, lambda: Value, arg: Value, normal: Block, err: Block): TrySpawn
```

功能：创建带异常处理的并发 Spawn 表达式（带参数版本）。

参数：

- retTy: Type - 返回类型。
- lambda: Value - lambda 值。
- arg: Value - Spawn 参数值。
- normal: Block - 正常分支目标块。
- err: Block - 异常分支目标块。

返回值：

- [TrySpawn](#class-tryspawn) - 带异常处理的 Spawn 表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([FuncType.get([IntType.getInt32()], IntType.getInt32()), IntType.getInt32()], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let lambda = f.parameters[0]
    let arg = f.parameters[1]
    let spawnExpr = TrySpawn.create(IntType.getInt32(), lambda, arg, normalBlock, errBlock)
    println("static_create_withArg: ${spawnExpr.normalBranch == normalBlock}")
}
```

运行结果：

```text
static_create_withArg: true
```

### operator func ==(TrySpawn)

```cangjie
public operator func ==(other: TrySpawn): Bool
```

功能：引用比较，判断两个 TrySpawn 是否为同一实例。

参数：

- other: TrySpawn - 另一带异常处理的 Spawn 表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([FuncType.get([], IntType.getInt32())], IntType.getInt32()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let spawnExpr = TrySpawn.create(IntType.getInt32(), param, normalBlock, errBlock)
    println("op_eq_TrySpawn: ${spawnExpr == spawnExpr}")
}
```

运行结果：

```text
op_eq_TrySpawn: true
```

## class Store

```cangjie
public class Store <: Expression & Equatable<Store> {}
```

功能：内存存储表达式。

父类型：

- Expression
- Equatable\<Store>

### prop dstAddress

```cangjie
public prop dstAddress: Value
```

功能：目标地址。

类型：Value

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), CPointerType.get(IntType.getInt32())], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let addrParam = f.parameters[1]
    let store = Store.create(valParam, addrParam)
    println("prop_dstAddress: ${store.dstAddress == addrParam}")
}
```

运行结果：

```text
prop_dstAddress: true
```

### prop srcValue

```cangjie
public prop srcValue: Value
```

功能：源值。

类型：Value

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), CPointerType.get(IntType.getInt32())], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let addrParam = f.parameters[1]
    let store = Store.create(valParam, addrParam)
    println("prop_srcValue: ${store.srcValue == valParam}")
}
```

运行结果：

```text
prop_srcValue: true
```

### static func create(Value, Value)

```cangjie
public static func create(val: Value, location: Value): Store
```

功能：创建内存存储表达式，将源值存储到目标地址。

参数：

- val: Value - 源值。
- location: Value - 目标地址。

返回值：

- [Store](#class-store) - 内存存储表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), CPointerType.get(IntType.getInt32())], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let addrParam = f.parameters[1]
    let store = Store.create(valParam, addrParam)
    println("static_create: ${store.srcValue == valParam}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(Store)

```cangjie
public operator func ==(other: Store): Bool
```

功能：引用比较，判断两个 Store 是否为同一实例。

参数：

- other: Store - 另一内存存储表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), CPointerType.get(IntType.getInt32())], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let addrParam = f.parameters[1]
    let store = Store.create(valParam, addrParam)
    println("op_eq_Store: ${store == store}")
}
```

运行结果：

```text
op_eq_Store: true
```

## class StoreElementByName

```cangjie
public class StoreElementByName <: Expression & Equatable<StoreElementByName> {}
```

功能：按字段名存储聚合体元素的表达式。

父类型：

- Expression
- Equatable\<StoreElementByName>

### prop fieldNames

```cangjie
public prop fieldNames: Array<String>
```

功能：字段名路径。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let locParam = f.parameters[1]
    let fieldNames = ArrayList<String>()
    fieldNames.add("x")
    let store = StoreElementByName.create(valParam, locParam, fieldNames)
    println("prop_fieldNames: ${store.fieldNames.size}")
}
```

运行结果：

```text
prop_fieldNames: 1
```

### static func create(Value, Value, ArrayList\<String>)

```cangjie
public static func create(val: Value, location: Value, fieldNames: ArrayList<String>): StoreElementByName
```

功能：创建按字段名存储聚合体元素的表达式。

参数：

- val: Value - 源值。
- location: Value - 目标地址。
- fieldNames: ArrayList\<String> - 字段名路径。

返回值：

- [StoreElementByName](#class-storeelementbyname) - 按字段名存储聚合体元素表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let locParam = f.parameters[1]
    let fieldNames = ArrayList<String>()
    fieldNames.add("x")
    let store = StoreElementByName.create(valParam, locParam, fieldNames)
    println("static_create: ${store.fieldNames.size}")
}
```

运行结果：

```text
static_create: 1
```

### operator func ==(StoreElementByName)

```cangjie
public operator func ==(other: StoreElementByName): Bool
```

功能：引用比较，判断两个 StoreElementByName 是否为同一实例。

参数：

- other: StoreElementByName - 另一按字段名存储聚合体元素表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let locParam = f.parameters[1]
    let fieldNames = ArrayList<String>()
    fieldNames.add("x")
    let store = StoreElementByName.create(valParam, locParam, fieldNames)
    println("op_eq_StoreElementByName: ${store == store}")
}
```

运行结果：

```text
op_eq_StoreElementByName: true
```

## class StoreElementRef

```cangjie
public class StoreElementRef <: Expression & Equatable<StoreElementRef> {}
```

功能：按数字索引存储聚合体元素的表达式。

父类型：

- Expression
- Equatable\<StoreElementRef>

### prop path

```cangjie
public prop path: Array<UInt64>
```

功能：索引路径。

类型：Array\<UInt64>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let locParam = f.parameters[1]
    let path = ArrayList<UInt64>()
    path.add(0)
    let store = StoreElementRef.create(valParam, locParam, path)
    println("prop_path: ${store.path.size}")
}
```

运行结果：

```text
prop_path: 1
```

### static func create(Value, Value, ArrayList\<UInt64>)

```cangjie
public static func create(val: Value, location: Value, path: ArrayList<UInt64>): StoreElementRef
```

功能：创建按数字索引存储聚合体元素的表达式。

参数：

- val: Value - 源值。
- location: Value - 目标地址。
- path: ArrayList\<UInt64> - 索引路径。

返回值：

- [StoreElementRef](#class-storeelementref) - 按数字索引存储聚合体元素表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let locParam = f.parameters[1]
    let path = ArrayList<UInt64>()
    path.add(0)
    let store = StoreElementRef.create(valParam, locParam, path)
    println("static_create: ${store.path.size}")
}
```

运行结果：

```text
static_create: 1
```

### operator func ==(StoreElementRef)

```cangjie
public operator func ==(other: StoreElementRef): Bool
```

功能：引用比较，判断两个 StoreElementRef 是否为同一实例。

参数：

- other: StoreElementRef - 另一按数字索引存储聚合体元素表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let valParam = f.parameters[0]
    let locParam = f.parameters[1]
    let path = ArrayList<UInt64>()
    path.add(0)
    let store = StoreElementRef.create(valParam, locParam, path)
    println("op_eq_StoreElementRef: ${store == store}")
}
```

运行结果：

```text
op_eq_StoreElementRef: true
```

## class Tuple

```cangjie
public class Tuple <: Expression & Equatable<Tuple> {}
```

功能：元组构造表达式。

父类型：

- Expression
- Equatable\<Tuple>

### prop elements

```cangjie
public prop elements: Array<Value>
```

功能：元组元素。

类型：Array\<Value>

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let e1 = IntLiteral.get(IntType.getInt32(), 1)
    let e2 = IntLiteral.get(IntType.getInt32(), 2)
    let elements = ArrayList<Value>()
    elements.add(e1)
    elements.add(e2)
    let tuple = Tuple.create(elements)
    println("prop_elements: ${tuple.elements.size}")
}
```

运行结果：

```text
prop_elements: 2
```

### static func create(ArrayList\<Value>)

```cangjie
public static func create(elements: ArrayList<Value>): Tuple
```

功能：创建元组构造表达式，指定元素列表。

参数：

- elements: ArrayList\<Value> - 元素值列表。

返回值：

- [Tuple](#class-tuple) - 元组构造表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let e1 = IntLiteral.get(IntType.getInt32(), 1)
    let e2 = IntLiteral.get(IntType.getInt32(), 2)
    let elements = ArrayList<Value>()
    elements.add(e1)
    elements.add(e2)
    let tuple = Tuple.create(elements)
    println("static_create: ${tuple.elements.size}")
}
```

运行结果：

```text
static_create: 2
```

### operator func ==(Tuple)

```cangjie
public operator func ==(other: Tuple): Bool
```

功能：引用比较，判断两个 Tuple 是否为同一实例。

参数：

- other: Tuple - 另一元组构造表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let e1 = IntLiteral.get(IntType.getInt32(), 1)
    let e2 = IntLiteral.get(IntType.getInt32(), 2)
    let elements = ArrayList<Value>()
    elements.add(e1)
    elements.add(e2)
    let tuple = Tuple.create(elements)
    println("op_eq_Tuple: ${tuple == tuple}")
}
```

运行结果：

```text
op_eq_Tuple: true
```

## class TypeCast

```cangjie
sealed abstract class TypeCast <: Expression & Equatable<TypeCast> {}
```

功能：类型转换表达式的抽象基类，是 [Box](#class-box)、[StaticCast](#class-staticcast)、[CastToConcrete](#class-casttoconcrete)、[CastToGeneric](#class-casttogeneric) 等的父类型，提供源值、源类型与目标类型的查询能力。

父类型：

- [Expression](#class-expression)
- Equatable\<[TypeCast](#class-typecast)>

### prop sourceType

```cangjie
public prop sourceType: Type
```

功能：该类型转换的源值类型。

类型：[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBox(IntLiteral.get(IntType.getInt64(), 1), IntType.getInt64())
    block.appendExpr(expr)
    println("prop_sourceType: ${expr.sourceType.qualifiedName}")
}
```

运行结果：

```text
prop_sourceType: Int64
```

### prop srcValue

```cangjie
public prop srcValue: Value
```

功能：该类型转换的源值。

类型：[Value](#class-value)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let lit = IntLiteral.get(IntType.getInt64(), 1)
    let expr = builder.createBox(lit, IntType.getInt64())
    block.appendExpr(expr)
    println("prop_srcValue: ${expr.srcValue == lit}")
}
```

运行结果：

```text
prop_srcValue: true
```

### prop targetType

```cangjie
public prop targetType: Type
```

功能：该类型转换的目标类型。

类型：[Type](#class-type)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBox(IntLiteral.get(IntType.getInt64(), 1), IntType.getInt64())
    block.appendExpr(expr)
    println("prop_targetType: ${expr.targetType.qualifiedName}")
}
```

运行结果：

```text
prop_targetType: Int64
```

### operator func ==(TypeCast)

```cangjie
public operator func ==(other: TypeCast): Bool
```

功能：引用比较，判断两个 TypeCast 是否为同一实例。

参数：

- other: [TypeCast](#class-typecast) - 另一类型转换表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBox(IntLiteral.get(IntType.getInt64(), 1), IntType.getInt64())
    block.appendExpr(expr)
    println("op_eq_TypeCast: ${expr == expr}")
}
```

运行结果：

```text
op_eq_TypeCast: true
```

## class Box

```cangjie
public class Box <: TypeCast & Equatable<Box> {}
```

功能：装箱类型转换表达式。

父类型：

- TypeCast
- Equatable\<Box>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): Box
```

功能：创建装箱类型转换表达式，将源值装箱为目标类型。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标类型。

返回值：

- [Box](#class-box) - 装箱类型转换表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.Box as BoxExpr
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let boxExpr = BoxExpr.create(param, BoxType.get(IntType.getInt32()))
    println("static_create: ${boxExpr.srcValue == param}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(Box)

```cangjie
public operator func ==(other: Box): Bool
```

功能：引用比较，判断两个 Box 是否为同一实例。

参数：

- other: Box - 另一装箱类型转换表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.Box as BoxExpr
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let boxExpr = BoxExpr.create(param, BoxType.get(IntType.getInt32()))
    println("op_eq_Box: ${boxExpr == boxExpr}")
}
```

运行结果：

```text
op_eq_Box: true
```

## class StaticCast

```cangjie
public class StaticCast <: TypeCast & Equatable<StaticCast> {}
```

功能：静态类型转换表达式。

父类型：

- TypeCast
- Equatable\<StaticCast>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): StaticCast
```

功能：创建静态类型转换表达式，将源值静态转换为目标类型。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标类型。

返回值：

- [StaticCast](#class-staticcast) - 静态类型转换表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = StaticCast.create(param, IntType.getInt64())
    println("static_create: ${cast.srcValue == param}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(StaticCast)

```cangjie
public operator func ==(other: StaticCast): Bool
```

功能：引用比较，判断两个 StaticCast 是否为同一实例。

参数：

- other: StaticCast - 另一静态类型转换表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = StaticCast.create(param, IntType.getInt64())
    println("op_eq_StaticCast: ${cast == cast}")
}
```

运行结果：

```text
op_eq_StaticCast: true
```

## class CastToConcrete

```cangjie
public class CastToConcrete <: TypeCast & Equatable<CastToConcrete> {}
```

功能：向具体类型转换表达式。

父类型：

- TypeCast
- Equatable\<CastToConcrete>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): CastToConcrete
```

功能：创建向具体类型转换表达式。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标具体类型。

返回值：

- [CastToConcrete](#class-casttoconcrete) - 向具体类型转换表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = CastToConcrete.create(param, IntType.getInt64())
    println("static_create: ${cast.srcValue == param}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(CastToConcrete)

```cangjie
public operator func ==(other: CastToConcrete): Bool
```

功能：引用比较，判断两个 CastToConcrete 是否为同一实例。

参数：

- other: CastToConcrete - 另一向具体类型转换表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = CastToConcrete.create(param, IntType.getInt64())
    println("op_eq_CastToConcrete: ${cast == cast}")
}
```

运行结果：

```text
op_eq_CastToConcrete: true
```

## class CastToGeneric

```cangjie
public class CastToGeneric <: TypeCast & Equatable<CastToGeneric> {}
```

功能：向泛型类型转换表达式。

父类型：

- TypeCast
- Equatable\<CastToGeneric>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): CastToGeneric
```

功能：创建向泛型类型转换表达式。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标泛型类型。

返回值：

- [CastToGeneric](#class-casttogeneric) - 向泛型类型转换表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let gt = GenericType.get("T_m", "T")
    let cast = CastToGeneric.create(param, gt)
    println("static_create: ${cast.srcValue == param}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(CastToGeneric)

```cangjie
public operator func ==(other: CastToGeneric): Bool
```

功能：引用比较，判断两个 CastToGeneric 是否为同一实例。

参数：

- other: CastToGeneric - 另一向泛型类型转换表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let gt = GenericType.get("T_m", "T")
    let cast = CastToGeneric.create(param, gt)
    println("op_eq_CastToGeneric: ${cast == cast}")
}
```

运行结果：

```text
op_eq_CastToGeneric: true
```

## class UnboxToRef

```cangjie
public class UnboxToRef <: TypeCast & Equatable<UnboxToRef> {}
```

功能：拆箱为引用的类型转换表达式。

父类型：

- TypeCast
- Equatable\<UnboxToRef>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): UnboxToRef
```

功能：创建拆箱为引用的类型转换表达式。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标引用类型。

返回值：

- [UnboxToRef](#class-unboxtoref) - 拆箱为引用的类型转换表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([BoxType.get(IntType.getInt32())], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = UnboxToRef.create(param, RefType.get(IntType.getInt32()))
    println("static_create: ${cast.srcValue == param}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(UnboxToRef)

```cangjie
public operator func ==(other: UnboxToRef): Bool
```

功能：引用比较，判断两个 UnboxToRef 是否为同一实例。

参数：

- other: UnboxToRef - 另一拆箱为引用的类型转换表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([BoxType.get(IntType.getInt32())], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = UnboxToRef.create(param, RefType.get(IntType.getInt32()))
    println("op_eq_UnboxToRef: ${cast == cast}")
}
```

运行结果：

```text
op_eq_UnboxToRef: true
```

## class UnboxToValue

```cangjie
public class UnboxToValue <: TypeCast & Equatable<UnboxToValue> {}
```

功能：拆箱为值的类型转换表达式。

父类型：

- TypeCast
- Equatable\<UnboxToValue>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): UnboxToValue
```

功能：创建拆箱为值的类型转换表达式。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标值类型。

返回值：

- [UnboxToValue](#class-unboxtovalue) - 拆箱为值的类型转换表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([BoxType.get(IntType.getInt32())], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = UnboxToValue.create(param, IntType.getInt32())
    println("static_create: ${cast.srcValue == param}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(UnboxToValue)

```cangjie
public operator func ==(other: UnboxToValue): Bool
```

功能：引用比较，判断两个 UnboxToValue 是否为同一实例。

参数：

- other: UnboxToValue - 另一拆箱为值的类型转换表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([BoxType.get(IntType.getInt32())], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let cast = UnboxToValue.create(param, IntType.getInt32())
    println("op_eq_UnboxToValue: ${cast == cast}")
}
```

运行结果：

```text
op_eq_UnboxToValue: true
```

## class UnaryExpressionBase

```cangjie
sealed abstract class UnaryExpressionBase <: Expression & Equatable<UnaryExpressionBase> {}
```

功能：一元表达式（[UnaryExpression](#class-unaryexpression)、[TryUnaryExpression](#class-tryunaryexpression) 等）的抽象基类，提供溢出策略的查询与设置能力。

父类型：

- [Expression](#class-expression)
- Equatable\<[UnaryExpressionBase](#class-unaryexpressionbase)>

### prop overflow

```cangjie
public mut prop overflow: OverflowStrategy
```

功能：该一元表达式使用的溢出策略；可读可写，默认为 [OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy).NA。

类型：[OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createUnaryNeg(IntLiteral.get(IntType.getInt64(), 1), OverflowStrategy.NA)
    expr.overflow = OverflowStrategy.Throwing
    println("prop_overflow: ${expr.overflow}")
}
```

运行结果：

```text
prop_overflow: Throwing
```

### operator func ==(UnaryExpressionBase)

```cangjie
public operator func ==(other: UnaryExpressionBase): Bool
```

功能：引用比较，判断两个 UnaryExpressionBase 是否为同一实例。

参数：

- other: [UnaryExpressionBase](#class-unaryexpressionbase) - 另一一元表达式基类表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createUnaryNeg(IntLiteral.get(IntType.getInt64(), 1), OverflowStrategy.NA)
    println("op_eq_UnaryExpressionBase: ${expr == expr}")
}
```

运行结果：

```text
op_eq_UnaryExpressionBase: true
```

## class UnaryExpression

```cangjie
public class UnaryExpression <: UnaryExpressionBase & Equatable<UnaryExpression> {}
```

功能：一元运算表达式（不带异常处理）。

父类型：

- UnaryExpressionBase
- Equatable\<UnaryExpression>

### static func create(UnaryExprKind, Value)

```cangjie
public static func create(kind: UnaryExprKind, op: Value): UnaryExpression
```

功能：创建一元运算表达式，指定运算类别与操作数。

参数：

- kind: UnaryExprKind - 一元运算类别。
- op: Value - 操作数。

返回值：

- [UnaryExpression](#class-unaryexpression) - 一元运算表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt64()], IntType.getInt64()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let expr = UnaryExpression.create(UnaryExprKind.Neg, param)
    println("static_create: ${expr.result.toString().size > 0}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(UnaryExpression)

```cangjie
public operator func ==(other: UnaryExpression): Bool
```

功能：引用比较，判断两个 UnaryExpression 是否为同一实例。

参数：

- other: UnaryExpression - 另一一元运算表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt64()], IntType.getInt64()), "f_m", "f", "demo")
    f.initBody()
    let param = f.parameters[0]
    let expr = UnaryExpression.create(UnaryExprKind.Neg, param)
    println("op_eq_UnaryExpression: ${expr == expr}")
}
```

运行结果：

```text
op_eq_UnaryExpression: true
```

## class TryUnaryExpression

```cangjie
public class TryUnaryExpression <: UnaryExpressionBase & Equatable<TryUnaryExpression> {}
```

功能：带异常处理的一元运算表达式。

父类型：

- UnaryExpressionBase
- Equatable\<TryUnaryExpression>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

功能：正常分支目标块。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt64()], IntType.getInt64()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let expr = TryUnaryExpression.create(param, normalBlock, errBlock)
    println("prop_normalBranch: ${expr.normalBranch == normalBlock}")
}
```

运行结果：

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

功能：异常分支目标块。

类型：[Block](#class-block)

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt64()], IntType.getInt64()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let expr = TryUnaryExpression.create(param, normalBlock, errBlock)
    println("prop_errorBranch: ${expr.errorBranch == errBlock}")
}
```

运行结果：

```text
prop_errorBranch: true
```

### static func create(Value, Block, Block)

```cangjie
public static func create(op: Value, normal: Block, err: Block): TryUnaryExpression
```

功能：创建带异常处理的一元运算表达式，指定正常分支与异常分支目标块。

参数：

- op: Value - 操作数。
- normal: Block - 正常分支目标块。
- err: Block - 异常分支目标块。

返回值：

- [TryUnaryExpression](#class-tryunaryexpression) - 带异常处理的一元运算表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt64()], IntType.getInt64()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let expr = TryUnaryExpression.create(param, normalBlock, errBlock)
    println("static_create: ${expr.normalBranch == normalBlock}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(TryUnaryExpression)

```cangjie
public operator func ==(other: TryUnaryExpression): Bool
```

功能：引用比较，判断两个 TryUnaryExpression 是否为同一实例。

参数：

- other: TryUnaryExpression - 另一带异常处理的一元运算表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt64()], IntType.getInt64()), "f_m", "f", "demo")
    f.initBody()
    let normalBlock = f.body.getOrThrow().appendBlock()
    let errBlock = f.body.getOrThrow().appendBlock()
    let param = f.parameters[0]
    let expr = TryUnaryExpression.create(param, normalBlock, errBlock)
    println("op_eq_TryUnaryExpression: ${expr == expr}")
}
```

运行结果：

```text
op_eq_TryUnaryExpression: true
```

## class VArrayBuilder

```cangjie
public class VArrayBuilder <: Expression & Equatable<VArrayBuilder> {}
```

功能：VArray 构建器表达式。

父类型：

- Expression
- Equatable\<VArrayBuilder>

### static func create(Type, Value, Value, Value)

```cangjie
public static func create(retTy: Type, size: Value, initVal: Value, initFunc: Value): VArrayBuilder
```

功能：创建 VArray 构建器表达式，指定返回类型、数组大小、初始值与初始化函数。

参数：

- retTy: Type - 返回类型。
- size: Value - 数组大小。
- initVal: Value - 初始值。
- initFunc: Value - 初始化函数。

返回值：

- [VArrayBuilder](#class-varraybuilder) - VArray 构建器表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32(), FuncType.get([IntType.getInt32()], IntType.getInt32())], VArrayType.get(IntType.getInt32(), 5)), "f_m", "f", "demo")
    f.initBody()
    let sizeVal = f.parameters[0]
    let initVal = f.parameters[1]
    let initFunc = f.parameters[2]
    let builder = VArrayBuilder.create(VArrayType.get(IntType.getInt32(), 5), sizeVal, initVal, initFunc)
    println("static_create: ${builder.result.toString().size > 0}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(VArrayBuilder)

```cangjie
public operator func ==(other: VArrayBuilder): Bool
```

功能：引用比较，判断两个 VArrayBuilder 是否为同一实例。

参数：

- other: VArrayBuilder - 另一 VArray 构建器表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32(), IntType.getInt32(), FuncType.get([IntType.getInt32()], IntType.getInt32())], VArrayType.get(IntType.getInt32(), 5)), "f_m", "f", "demo")
    f.initBody()
    let sizeVal = f.parameters[0]
    let initVal = f.parameters[1]
    let initFunc = f.parameters[2]
    let builder = VArrayBuilder.create(VArrayType.get(IntType.getInt32(), 5), sizeVal, initVal, initFunc)
    println("op_eq_VArrayBuilder: ${builder == builder}")
}
```

运行结果：

```text
op_eq_VArrayBuilder: true
```

## class VArrayExpr

```cangjie
public class VArrayExpr <: Expression & Equatable<VArrayExpr> {}
```

功能：VArray 字面量表达式。

父类型：

- Expression
- Equatable\<VArrayExpr>

### static func create(ArrayList\<Value>)

```cangjie
public static func create(elements: ArrayList<Value>): VArrayExpr
```

功能：创建 VArray 字面量表达式，指定元素列表。

参数：

- elements: ArrayList\<Value> - 元素值列表。

返回值：

- [VArrayExpr](#class-varrayexpr) - VArray 字面量表达式实例。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let e1 = IntLiteral.get(IntType.getInt32(), 1)
    let e2 = IntLiteral.get(IntType.getInt32(), 2)
    let e3 = IntLiteral.get(IntType.getInt32(), 3)
    let elements = ArrayList<Value>()
    elements.add(e1)
    elements.add(e2)
    elements.add(e3)
    let expr = VArrayExpr.create(elements)
    println("static_create: ${expr.result.toString().size > 0}")
}
```

运行结果：

```text
static_create: true
```

### operator func ==(VArrayExpr)

```cangjie
public operator func ==(other: VArrayExpr): Bool
```

功能：引用比较，判断两个 VArrayExpr 是否为同一实例。

参数：

- other: VArrayExpr - 另一 VArray 字面量表达式。

返回值：

- Bool - 是否为同一引用。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let e1 = IntLiteral.get(IntType.getInt32(), 1)
    let e2 = IntLiteral.get(IntType.getInt32(), 2)
    let elements = ArrayList<Value>()
    elements.add(e1)
    elements.add(e2)
    let expr = VArrayExpr.create(elements)
    println("op_eq_VArrayExpr: ${expr == expr}")
}
```

运行结果：

```text
op_eq_VArrayExpr: true
```

## class CHIRBuilder

```cangjie
public class CHIRBuilder {
    public init(parent: Block)
    public init(position: InsertPosition)
}
```

功能：CHIR 表达式构建器，用于在基本块中按指定位置插入各类 CHIR 表达式（算术、内存、控制流、类型转换等）。

### init(Block)

```cangjie
public init(parent: Block)
```

功能：构造一个 CHIRBuilder，指定插入位置为给定基本块的末尾。

参数：

- parent: Block - 插入目标基本块。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(block)
    builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    println("init_Block: ${block.exprs.size}")
}
```

运行结果：

```text
init_Block: 1
```

### init(InsertPosition)

```cangjie
public init(position: InsertPosition)
```

功能：构造一个 CHIRBuilder，指定插入位置。

参数：

- position: InsertPosition - 插入位置枚举值（AtEnd/AtStart/Before/After）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let pos = InsertPosition.AtEnd(block)
    let builder = CHIRBuilder(pos)
    builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    println("init_InsertPosition: ${block.exprs.size}")
}
```

运行结果：

```text
init_InsertPosition: 1
```

### func createAllocate(Type)

```cangjie
public func createAllocate(ty: Type): Allocate
```

功能：创建内存分配表达式。

参数：

- ty: Type - 分配的类型。

返回值：

- [Allocate](#class-allocate) - 分配表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(IntType.getInt32())
    println("createAllocate: ${alloc.toString().size > 0}")
}
```

运行结果：

```text
createAllocate: true
```

### func createApply(Value, FuncCallContext)

```cangjie
public func createApply(callee: Value, funcCallCtx: FuncCallContext): Apply
```

功能：创建函数调用（Apply）表达式。

参数：

- callee: Value - 被调用函数值。
- funcCallCtx: FuncCallContext - 函数调用上下文。

返回值：

- [Apply](#class-apply) - Apply 表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f1 = pkg.addFunction(FuncType.get([], UnitType.get()), "callee_m", "callee", "demo")
    let f2 = pkg.addFunction(FuncType.get([], UnitType.get()), "caller_m", "caller", "demo")
    f2.initBody()
    let block = f2.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let ctx = FuncCallContext([], [], None)
    let apply = builder.createApply(f1, ctx)
    println("createApply: ${apply.toString().size > 0}")
}
```

运行结果：

```text
createApply: true
```

### func createBinaryAdd(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryAdd(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

功能：创建加法二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [BinaryExpression](#class-binaryexpression) - 加法表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    println("createBinaryAdd: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryAdd: true
```

### func createBinaryAnd(Value, Value)

```cangjie
public func createBinaryAnd(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建逻辑与二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 逻辑与表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryAnd(BoolLiteral.get(true), BoolLiteral.get(false))
    println("createBinaryAnd: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryAnd: true
```

### func createBinaryBitAnd(Value, Value)

```cangjie
public func createBinaryBitAnd(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建按位与二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 按位与表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryBitAnd(IntLiteral.get(IntType.getInt64(), 3), IntLiteral.get(IntType.getInt64(), 5))
    println("createBinaryBitAnd: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryBitAnd: true
```

### func createBinaryBitOr(Value, Value)

```cangjie
public func createBinaryBitOr(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建按位或二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 按位或表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryBitOr(IntLiteral.get(IntType.getInt64(), 3), IntLiteral.get(IntType.getInt64(), 5))
    println("createBinaryBitOr: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryBitOr: true
```

### func createBinaryBitXor(Value, Value)

```cangjie
public func createBinaryBitXor(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建按位异或二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 按位异或表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryBitXor(IntLiteral.get(IntType.getInt64(), 3), IntLiteral.get(IntType.getInt64(), 5))
    println("createBinaryBitXor: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryBitXor: true
```

### func createBinaryDiv(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryDiv(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

功能：创建除法二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [BinaryExpression](#class-binaryexpression) - 除法表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryDiv(IntLiteral.get(IntType.getInt64(), 10), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    println("createBinaryDiv: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryDiv: true
```

### func createBinaryEqual(Value, Value)

```cangjie
public func createBinaryEqual(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建等于比较二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 等于比较表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryEqual(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 1))
    println("createBinaryEqual: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryEqual: true
```

### func createBinaryExp(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryExp(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

功能：创建指数二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [BinaryExpression](#class-binaryexpression) - 指数表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryExp(IntLiteral.get(IntType.getInt64(), 2), IntLiteral.get(IntType.getInt64(), 3), OverflowStrategy.NA)
    println("createBinaryExp: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryExp: true
```

### func createBinaryGreaterThan(Value, Value)

```cangjie
public func createBinaryGreaterThan(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建大于比较二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 大于比较表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryGreaterThan(IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt64(), 3))
    println("createBinaryGreaterThan: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryGreaterThan: true
```

### func createBinaryGreaterThanOrEqual(Value, Value)

```cangjie
public func createBinaryGreaterThanOrEqual(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建大于等于比较二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 大于等于比较表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryGreaterThanOrEqual(IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt64(), 5))
    println("createBinaryGreaterThanOrEqual: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryGreaterThanOrEqual: true
```

### func createBinaryLShift(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryLShift(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

功能：创建左移二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [BinaryExpression](#class-binaryexpression) - 左移表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryLShift(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    println("createBinaryLShift: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryLShift: true
```

### func createBinaryLessThan(Value, Value)

```cangjie
public func createBinaryLessThan(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建小于比较二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 小于比较表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryLessThan(IntLiteral.get(IntType.getInt64(), 3), IntLiteral.get(IntType.getInt64(), 5))
    println("createBinaryLessThan: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryLessThan: true
```

### func createBinaryLessThanOrEqual(Value, Value)

```cangjie
public func createBinaryLessThanOrEqual(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建小于等于比较二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 小于等于比较表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryLessThanOrEqual(IntLiteral.get(IntType.getInt64(), 3), IntLiteral.get(IntType.getInt64(), 5))
    println("createBinaryLessThanOrEqual: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryLessThanOrEqual: true
```

### func createBinaryMod(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryMod(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

功能：创建取模二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [BinaryExpression](#class-binaryexpression) - 取模表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryMod(IntLiteral.get(IntType.getInt64(), 10), IntLiteral.get(IntType.getInt64(), 3), OverflowStrategy.NA)
    println("createBinaryMod: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryMod: true
```

### func createBinaryMul(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryMul(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

功能：创建乘法二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [BinaryExpression](#class-binaryexpression) - 乘法表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryMul(IntLiteral.get(IntType.getInt64(), 3), IntLiteral.get(IntType.getInt64(), 4), OverflowStrategy.NA)
    println("createBinaryMul: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryMul: true
```

### func createBinaryNotEqual(Value, Value)

```cangjie
public func createBinaryNotEqual(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建不等于比较二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 不等于比较表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryNotEqual(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2))
    println("createBinaryNotEqual: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryNotEqual: true
```

### func createBinaryOr(Value, Value)

```cangjie
public func createBinaryOr(leftOp: Value, rightOp: Value): BinaryExpression
```

功能：创建逻辑或二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。

返回值：

- [BinaryExpression](#class-binaryexpression) - 逻辑或表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryOr(BoolLiteral.get(true), BoolLiteral.get(false))
    println("createBinaryOr: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryOr: true
```

### func createBinaryRShift(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryRShift(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

功能：创建右移二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [BinaryExpression](#class-binaryexpression) - 右移表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinaryRShift(IntLiteral.get(IntType.getInt64(), 8), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
    println("createBinaryRShift: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinaryRShift: true
```

### func createBinarySub(Value, Value, OverflowStrategy)

```cangjie
public func createBinarySub(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

功能：创建减法二元表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [BinaryExpression](#class-binaryexpression) - 减法表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBinarySub(IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt64(), 3), OverflowStrategy.NA)
    println("createBinarySub: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBinarySub: true
```

### func createBox(Value, Type)

```cangjie
public func createBox(srcVal: Value, dstTy: Type): Box
```

功能：创建装箱（Box）类型转换表达式。

参数：

- srcVal: Value - 源值。
- dstTy: Type - 目标装箱类型。

返回值：

- [Box](#class-box) - 装箱表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createBox(IntLiteral.get(IntType.getInt32(), 42), BoxType.get(IntType.getInt32()))
    println("createBox: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBox: true
```

### func createBranch(Value, Block, Block)

```cangjie
public func createBranch(condition: Value, trueTarget: Block, falseTarget: Block): Branch
```

功能：创建条件分支表达式。

参数：

- condition: Value - 分支条件值。
- trueTarget: Block - 条件为真时的目标基本块。
- falseTarget: Block - 条件为假时的目标基本块。

返回值：

- [Branch](#class-branch) - 条件分支表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let trueBlock = bg.appendBlock()
    let falseBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createBranch(BoolLiteral.get(true), trueBlock, falseBlock)
    println("createBranch: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createBranch: true
```

### func createCastToConcrete(Value, Type)

```cangjie
public func createCastToConcrete(srcVal: Value, targetType: Type): CastToConcrete
```

功能：创建向具体类型转换表达式。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标具体类型。

返回值：

- [CastToConcrete](#class-casttoconcrete) - 向具体类型转换表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createCastToConcrete(IntLiteral.get(IntType.getInt32(), 1), IntType.getInt64())
    println("createCastToConcrete: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createCastToConcrete: true
```

### func createCastToGeneric(Value, Type)

```cangjie
public func createCastToGeneric(srcVal: Value, targetType: Type): CastToGeneric
```

功能：创建向泛型类型转换表达式。

参数：

- srcVal: Value - 源值。
- targetType: Type - 目标泛型类型。

返回值：

- [CastToGeneric](#class-casttogeneric) - 向泛型类型转换表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let g = GenericType.get("pkg:T", "T")
    let expr = builder.createCastToGeneric(IntLiteral.get(IntType.getInt32(), 1), g)
    println("createCastToGeneric: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createCastToGeneric: true
```

### func createConstant(LiteralValue)

```cangjie
public func createConstant(val: LiteralValue): Constant
```

功能：创建常量表达式。

参数：

- val: LiteralValue - 字面量值。

返回值：

- [Constant](#class-constant) - 常量表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createConstant(IntLiteral.get(IntType.getInt32(), 42))
    println("createConstant: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createConstant: true
```

### func createDebug(Value, String)

```cangjie
public func createDebug(location: Value, srcCodeName: String): Debug
```

功能：创建调试标记表达式。

参数：

- location: Value - 调试位置值。
- srcCodeName: String - 源码中的变量名。

返回值：

- [Debug](#class-debug) - 调试标记表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(IntType.getInt32())
    let expr = builder.createDebug(alloc.result, "x")
    println("createDebug: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createDebug: true
```

### func createExit()

```cangjie
public func createExit(): Exit
```

功能：创建函数退出表达式。

返回值：

- [Exit](#class-exit) - 函数退出表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createExit()
    println("createExit: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createExit: true
```

### func createField(Value, ArrayList\<UInt64>)

```cangjie
public func createField(val: Value, path: ArrayList<UInt64>): Field
```

功能：创建按数字路径的字段访问表达式。

参数：

- val: Value - 结构体或类实例值。
- path: ArrayList\<UInt64> - 数字路径索引列表。

返回值：

- [Field](#class-field) - 字段访问表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let i32 = IntType.getInt32()
    let a = builder.createConstant(IntLiteral.get(i32, 1u64)).result
    let b = builder.createConstant(IntLiteral.get(i32, 1u64)).result
    let c = builder.createConstant(IntLiteral.get(i32, 1u64)).result
    let tuple = builder.createTuple([a, b, c])
    let path = ArrayList<UInt64>()
    path.add(0)
    let expr = builder.createField(tuple.result, path)
    println("createField: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createField: true
```

### func createFieldByName(Value, ArrayList\<String>)

```cangjie
public func createFieldByName(val: Value, fieldNames: ArrayList<String>): FieldByName
```

功能：创建按字段名路径的字段访问表达式。

参数：

- val: Value - 结构体或类实例值。
- fieldNames: ArrayList\<String> - 字段名路径列表。

返回值：

- [FieldByName](#class-fieldbyname) - 按字段名的字段访问表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let st = pkg.addStruct("mS", "S")
    let vx = st.appendInstanceMemberVar("x", IntType.getInt32())
    let vy = st.appendInstanceMemberVar("y", BoolType.get())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(st.ty)
    let names = ArrayList<String>()
    names.add("x")
    let expr = builder.createFieldByName(alloc.result, names)
    println("createFieldByName: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createFieldByName: true
```

### func createGetElementByName(Value, ArrayList\<String>)

```cangjie
public func createGetElementByName(location: Value, fieldNames: ArrayList<String>): GetElementByName
```

功能：创建按字段名的元素读取表达式。

参数：

- location: Value - 内存位置值。
- fieldNames: ArrayList\<String> - 字段名路径列表。

返回值：

- [GetElementByName](#class-getelementbyname) - 元素读取表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let ca = pkg.addClass("mC", "C", true)
    let vx = ca.appendInstanceMemberVar("x", IntType.getInt32())
    let vy = ca.appendInstanceMemberVar("y", BoolType.get())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(ca.ty)
    let names = ArrayList<String>()
    names.add("x")
    let expr = builder.createGetElementByName(alloc.result, names)
    println("createGetElementByName: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createGetElementByName: true
```

### func createGetElementRef(Value, ArrayList\<UInt64>)

```cangjie
public func createGetElementRef(location: Value, path: ArrayList<UInt64>): GetElementRef
```

功能：创建按数字索引的元素引用表达式。

参数：

- location: Value - 内存位置值。
- path: ArrayList\<UInt64> - 数字索引路径列表。

返回值：

- [GetElementRef](#class-getelementref) - 元素引用表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let ca = pkg.addClass("mC", "C", true)
    let vx = ca.appendInstanceMemberVar("x", IntType.getInt32())
    let vy = ca.appendInstanceMemberVar("y", BoolType.get())
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(ca.ty)
    let path = ArrayList<UInt64>()
    path.add(0)
    let expr = builder.createGetElementRef(alloc.result, path)
    println("createGetElementRef: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createGetElementRef: true
```

### func createGetException(Type)

```cangjie
public func createGetException(retTy: Type): GetException
```

功能：创建获取异常值表达式。

参数：

- retTy: Type - 返回类型。

返回值：

- [GetException](#class-getexception) - 获取异常值表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createGetException(IntType.getInt32())
    println("createGetException: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createGetException: true
```

### func createGetInstantiateValue(Function, ArrayList\<Type>)

```cangjie
public func createGetInstantiateValue(val: Function, instantiateTypes: ArrayList<Type>): GetInstantiateValue
```

功能：创建获取泛型实例化值表达式。

参数：

- val: Function - 目标函数。
- instantiateTypes: ArrayList\<Type> - 实例化类型实参列表。

返回值：

- [GetInstantiateValue](#class-getinstantiatevalue) - 泛型实例化值表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let types = ArrayList<Type>()
    types.add(IntType.getInt32())
    let expr = builder.createGetInstantiateValue(f, types)
    println("createGetInstantiateValue: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createGetInstantiateValue: true
```

### func createGetRTTI(Value)

```cangjie
public func createGetRTTI(val: Value): GetRTTI
```

功能：创建获取运行时类型信息表达式。

参数：

- val: Value - 目标值。

返回值：

- [GetRTTI](#class-getrtti) - 运行时类型信息表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(IntType.getInt32())
    let expr = builder.createGetRTTI(alloc.result)
    println("createGetRTTI: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createGetRTTI: true
```

### func createGetRTTIStatic(Type)

```cangjie
public func createGetRTTIStatic(rttiType: Type): GetRTTIStatic
```

功能：创建静态获取运行时类型信息表达式。

参数：

- rttiType: Type - 目标类型。

返回值：

- [GetRTTIStatic](#class-getrttistatic) - 静态运行时类型信息表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createGetRTTIStatic(IntType.getInt32())
    println("createGetRTTIStatic: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createGetRTTIStatic: true
```

### func createGoTo(Block)

```cangjie
public func createGoTo(target: Block): GoTo
```

功能：创建无条件跳转表达式。

参数：

- target: Block - 跳转目标基本块。

返回值：

- [GoTo](#class-goto) - 无条件跳转表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let targetBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createGoTo(targetBlock)
    println("createGoTo: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createGoTo: true
```

### func createInstanceOf(Value, Type)

```cangjie
public func createInstanceOf(srcVal: Value, targetTy: Type): InstanceOf
```

功能：创建类型检查表达式。

参数：

- srcVal: Value - 源值。
- targetTy: Type - 目标类型。

返回值：

- [InstanceOf](#class-instanceof) - 类型检查表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(IntType.getInt32())
    let expr = builder.createInstanceOf(alloc.result, IntType.getInt32())
    println("createInstanceOf: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createInstanceOf: true
```

### func createInvoke(Type, InvokeCallContext)

```cangjie
public func createInvoke(retTy: Type, callContext: InvokeCallContext): Invoke
```

功能：创建虚方法调用（Invoke）表达式。

参数：

- retTy: Type - 返回类型。
- callContext: InvokeCallContext - 虚方法调用上下文。

返回值：

- [Invoke](#class-invoke) - Invoke 表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("method", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    let expr = builder.createInvoke(UnitType.get(), ctx)
    println("createInvoke: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createInvoke: true
```

### func createLambda(FuncType, String, String, Array\<GenericType>)

```cangjie
public func createLambda(ty: FuncType, mangledName: String, srcName: String, genericTypeParams!: Array<GenericType> = Array<GenericType>()): Lambda
```

功能：创建 Lambda 表达式。

参数：

- ty: FuncType - Lambda 函数类型。
- mangledName: String - 混淆名。
- srcName: String - 源码名。
- genericTypeParams!: Array\<GenericType> - 泛型形参列表（默认为空数组）。

返回值：

- [Lambda](#class-lambda) - Lambda 表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let ft = FuncType.get([], UnitType.get())
    let expr = builder.createLambda(ft, "lambda_m", "myLambda")
    println("createLambda: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createLambda: true
```

### func createLoad(Value)

```cangjie
public func createLoad(location: Value): Load
```

功能：创建内存加载表达式。

参数：

- location: Value - 内存位置值。

返回值：

- [Load](#class-load) - 内存加载表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(IntType.getInt32())
    let expr = builder.createLoad(alloc.result)
    println("createLoad: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createLoad: true
```

### func createMultiBranch(Value, Block, ArrayList\<Block>, ArrayList\<UInt64>)

```cangjie
public func createMultiBranch(condition: Value, defaultBlock: Block, targets: ArrayList<Block>, caseValues: ArrayList<UInt64>): MultiBranch
```

功能：创建多分支（switch）表达式。

参数：

- condition: Value - 分支条件值。
- defaultBlock: Block - 默认目标基本块。
- targets: ArrayList\<Block> - 各 case 分支目标基本块列表。
- caseValues: ArrayList\<UInt64> - 各 case 分支对应的值列表。

返回值：

- [MultiBranch](#class-multibranch) - 多分支表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let defaultBlock = bg.appendBlock()
    let caseBlock1 = bg.appendBlock()
    let targets = ArrayList<Block>()
    targets.add(caseBlock1)
    let caseValues = ArrayList<UInt64>()
    caseValues.add(1)
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createMultiBranch(IntLiteral.get(IntType.getInt64(), 1), defaultBlock, targets, caseValues)
    println("createMultiBranch: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createMultiBranch: true
```

### func createNumericCast(Value, Type, OverflowStrategy)

```cangjie
public func createNumericCast(srcVal: Value, dstTy: Type, overflow: OverflowStrategy): NumericCast
```

功能：创建数值类型转换表达式。

参数：

- srcVal: Value - 源值。
- dstTy: Type - 目标数值类型。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [NumericCast](#class-numericcast) - 数值类型转换表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createNumericCast(IntLiteral.get(IntType.getInt32(), 42), IntType.getInt64(), OverflowStrategy.NA)
    println("createNumericCast: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createNumericCast: true
```

### func createRaiseException(Value)

```cangjie
public func createRaiseException(value: Value): RaiseException
```

功能：创建抛出异常表达式（无后续块）。

参数：

- value: Value - 异常值。

返回值：

- [RaiseException](#class-raiseexception) - 抛出异常表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createRaiseException(IntLiteral.get(IntType.getInt32(), 1))
    println("createRaiseException_no_successor: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createRaiseException_no_successor: true
```

### func createRaiseException(Value, Block)

```cangjie
public func createRaiseException(value: Value, successor: Block): RaiseException
```

功能：创建抛出异常表达式（带后续块）。

参数：

- value: Value - 异常值。
- successor: Block - 异常抛出后的后续基本块。

返回值：

- [RaiseException](#class-raiseexception) - 抛出异常表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let successorBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createRaiseException(IntLiteral.get(IntType.getInt32(), 1), successorBlock)
    println("createRaiseException_with_successor: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createRaiseException_with_successor: true
```

### func createRawArrayAllocate(Type, Value)

```cangjie
public func createRawArrayAllocate(elementType: Type, size: Value): RawArrayAllocate
```

功能：创建原始数组分配表达式。

参数：

- elementType: Type - 数组元素类型。
- size: Value - 数组大小值。

返回值：

- [RawArrayAllocate](#class-rawarrayallocate) - 原始数组分配表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createRawArrayAllocate(IntType.getInt32(), IntLiteral.get(IntType.getInt64(), 10))
    println("createRawArrayAllocate: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createRawArrayAllocate: true
```

### func createRawArrayInitByValue(Value, Value, Value)

```cangjie
public func createRawArrayInitByValue(memory: Value, size: Value, initVal: Value): RawArrayInitByValue
```

功能：创建按值初始化原始数组表达式。

参数：

- memory: Value - 数组内存位置值。
- size: Value - 数组大小值。
- initVal: Value - 初始化值。

返回值：

- [RawArrayInitByValue](#class-rawarrayinitbyvalue) - 按值初始化表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createRawArrayAllocate(IntType.getInt32(), IntLiteral.get(IntType.getInt64(), 5))
    let expr = builder.createRawArrayInitByValue(alloc.result, IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt32(), 0))
    println("createRawArrayInitByValue: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createRawArrayInitByValue: true
```

### func createRawArrayLiteralInit(Value, ArrayList\<Value>)

```cangjie
public func createRawArrayLiteralInit(memory: Value, elements: ArrayList<Value>): RawArrayLiteralInit
```

功能：创建字面量初始化原始数组表达式。

参数：

- memory: Value - 数组内存位置值。
- elements: ArrayList\<Value> - 初始化元素值列表。

返回值：

- [RawArrayLiteralInit](#class-rawarrayliteralinit) - 字面量初始化表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createRawArrayAllocate(IntType.getInt32(), IntLiteral.get(IntType.getInt64(), 3))
    let elements = ArrayList<Value>()
    elements.add(IntLiteral.get(IntType.getInt32(), 1))
    elements.add(IntLiteral.get(IntType.getInt32(), 2))
    elements.add(IntLiteral.get(IntType.getInt32(), 3))
    let expr = builder.createRawArrayLiteralInit(alloc.result, elements)
    println("createRawArrayLiteralInit: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createRawArrayLiteralInit: true
```

### func createSpawn(Type, Value)

```cangjie
public func createSpawn(retTy: Type, val: Value): Spawn
```

功能：创建并发 Spawn 表达式。

参数：

- retTy: Type - 返回类型。
- val: Value - 被启动的函数值。

返回值：

- [Spawn](#class-spawn) - Spawn 表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f1 = pkg.addFunction(FuncType.get([], UnitType.get()), "spawn_m", "spawnTarget", "demo")
    let f2 = pkg.addFunction(FuncType.get([], UnitType.get()), "caller_m", "caller", "demo")
    f2.initBody()
    let block = f2.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createSpawn(UnitType.get(), f1)
    println("createSpawn_no_arg: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createSpawn_no_arg: true
```

### func createSpawn(Type, Value, Value)

```cangjie
public func createSpawn(retTy: Type, val: Value, arg: Value): Spawn
```

功能：创建带参数的并发 Spawn 表达式。

参数：

- retTy: Type - 返回类型。
- val: Value - 被启动的函数值。
- arg: Value - 函数参数值。

返回值：

- [Spawn](#class-spawn) - 带参数的 Spawn 表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f1 = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "spawn_m", "spawnTarget", "demo")
    let f2 = pkg.addFunction(FuncType.get([], UnitType.get()), "caller_m", "caller", "demo")
    f2.initBody()
    let block = f2.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createSpawn(UnitType.get(), f1, IntLiteral.get(IntType.getInt32(), 42))
    println("createSpawn_with_arg: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createSpawn_with_arg: true
```

### func createStaticCast(Value, Type)

```cangjie
public func createStaticCast(srcVal: Value, dstTy: Type): StaticCast
```

功能：创建静态类型转换表达式。

参数：

- srcVal: Value - 源值。
- dstTy: Type - 目标类型。

返回值：

- [StaticCast](#class-staticcast) - 静态类型转换表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createStaticCast(IntLiteral.get(IntType.getInt32(), 1), IntType.getInt64())
    println("createStaticCast: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createStaticCast: true
```

### func createStore(Value, Value)

```cangjie
public func createStore(val: Value, location: Value): Store
```

功能：创建内存存储表达式。

参数：

- val: Value - 要存储的值。
- location: Value - 内存位置值。

返回值：

- [Store](#class-store) - 内存存储表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(IntType.getInt32())
    let expr = builder.createStore(IntLiteral.get(IntType.getInt32(), 42), alloc.result)
    println("createStore: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createStore: true
```

### func createStoreElementByName(Value, Value, ArrayList\<String>)

```cangjie
public func createStoreElementByName(val: Value, location: Value, fieldNames: ArrayList<String>): StoreElementByName
```

功能：创建按字段名的元素存储表达式。

参数：

- val: Value - 要存储的值。
- location: Value - 内存位置值。
- fieldNames: ArrayList\<String> - 字段名路径列表。

返回值：

- [StoreElementByName](#class-storeelementbyname) - 按字段名的元素存储表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(IntType.getInt32())
    let names = ArrayList<String>()
    names.add("x")
    let expr = builder.createStoreElementByName(IntLiteral.get(IntType.getInt32(), 10), alloc.result, names)
    println("createStoreElementByName: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createStoreElementByName: true
```

### func createStoreElementRef(Value, Value, ArrayList\<UInt64>)

```cangjie
public func createStoreElementRef(val: Value, location: Value, path: ArrayList<UInt64>): StoreElementRef
```

功能：创建按数字索引的元素存储表达式。

参数：

- val: Value - 要存储的值。
- location: Value - 内存位置值。
- path: ArrayList\<UInt64> - 数字索引路径列表。

返回值：

- [StoreElementRef](#class-storeelementref) - 按数字索引的元素存储表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(IntType.getInt32())
    let path = ArrayList<UInt64>()
    path.add(0)
    let expr = builder.createStoreElementRef(IntLiteral.get(IntType.getInt32(), 10), alloc.result, path)
    println("createStoreElementRef: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createStoreElementRef: true
```

### func createTryAllocate(Type, Block, Block)

```cangjie
public func createTryAllocate(ty: Type, normal: Block, err: Block): TryAllocate
```

功能：创建带异常处理的内存分配表达式。

参数：

- ty: Type - 分配的类型。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryAllocate](#class-tryallocate) - 带异常处理的分配表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryAllocate(IntType.getInt32(), normalBlock, errBlock)
    println("createTryAllocate: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryAllocate: true
```

### func createTryApply(Value, FuncCallContext, Block, Block)

```cangjie
public func createTryApply(callee: Value, funcCallCtx: FuncCallContext, normal: Block, err: Block): TryApply
```

功能：创建带异常处理的函数调用表达式。

参数：

- callee: Value - 被调用函数值。
- funcCallCtx: FuncCallContext - 函数调用上下文。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryApply](#class-tryapply) - 带异常处理的函数调用表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f1 = pkg.addFunction(FuncType.get([], UnitType.get()), "callee_m", "callee", "demo")
    let f2 = pkg.addFunction(FuncType.get([], UnitType.get()), "caller_m", "caller", "demo")
    f2.initBody()
    let bg = f2.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let ctx = FuncCallContext([], [], None)
    let expr = builder.createTryApply(f1, ctx, normalBlock, errBlock)
    println("createTryApply: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryApply: true
```

### func createTryBinaryAdd(Value, Value, Block, Block)

```cangjie
public func createTryBinaryAdd(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

功能：创建带异常处理的加法表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryBinaryExpression](#class-trybinaryexpression) - 带异常处理的加法表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), normalBlock, errBlock)
    println("createTryBinaryAdd: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryBinaryAdd: true
```

### func createTryBinaryDiv(Value, Value, OverflowStrategy, Block, Block)

```cangjie
public func createTryBinaryDiv(leftOp: Value, rightOp: Value, overflow: OverflowStrategy, normal: Block, err: Block): TryBinaryExpression
```

功能：创建带异常处理的除法表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- overflow: OverflowStrategy - 溢出策略。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryBinaryExpression](#class-trybinaryexpression) - 带异常处理的除法表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryBinaryDiv(IntLiteral.get(IntType.getInt64(), 10), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA, normalBlock, errBlock)
    println("createTryBinaryDiv: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryBinaryDiv: true
```

### func createTryBinaryExp(Value, Value, Block, Block)

```cangjie
public func createTryBinaryExp(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

功能：创建带异常处理的指数表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryBinaryExpression](#class-trybinaryexpression) - 带异常处理的指数表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryBinaryExp(IntLiteral.get(IntType.getInt64(), 2), IntLiteral.get(IntType.getInt64(), 3), normalBlock, errBlock)
    println("createTryBinaryExp: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryBinaryExp: true
```

### func createTryBinaryLShift(Value, Value, Block, Block)

```cangjie
public func createTryBinaryLShift(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

功能：创建带异常处理的左移表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryBinaryExpression](#class-trybinaryexpression) - 带异常处理的左移表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryBinaryLShift(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), normalBlock, errBlock)
    println("createTryBinaryLShift: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryBinaryLShift: true
```

### func createTryBinaryMod(Value, Value, Block, Block)

```cangjie
public func createTryBinaryMod(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

功能：创建带异常处理的取模表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryBinaryExpression](#class-trybinaryexpression) - 带异常处理的取模表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryBinaryMod(IntLiteral.get(IntType.getInt64(), 10), IntLiteral.get(IntType.getInt64(), 3), normalBlock, errBlock)
    println("createTryBinaryMod: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryBinaryMod: true
```

### func createTryBinaryMul(Value, Value, Block, Block)

```cangjie
public func createTryBinaryMul(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

功能：创建带异常处理的乘法表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryBinaryExpression](#class-trybinaryexpression) - 带异常处理的乘法表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryBinaryMul(IntLiteral.get(IntType.getInt64(), 3), IntLiteral.get(IntType.getInt64(), 4), normalBlock, errBlock)
    println("createTryBinaryMul: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryBinaryMul: true
```

### func createTryBinaryRShift(Value, Value, Block, Block)

```cangjie
public func createTryBinaryRShift(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

功能：创建带异常处理的右移表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryBinaryExpression](#class-trybinaryexpression) - 带异常处理的右移表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryBinaryRShift(IntLiteral.get(IntType.getInt64(), 8), IntLiteral.get(IntType.getInt64(), 2), normalBlock, errBlock)
    println("createTryBinaryRShift: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryBinaryRShift: true
```

### func createTryBinarySub(Value, Value, Block, Block)

```cangjie
public func createTryBinarySub(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

功能：创建带异常处理的减法表达式。

参数：

- leftOp: Value - 左操作数。
- rightOp: Value - 右操作数。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryBinaryExpression](#class-trybinaryexpression) - 带异常处理的减法表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryBinarySub(IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt64(), 3), normalBlock, errBlock)
    println("createTryBinarySub: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryBinarySub: true
```

### func createTryInvoke(Type, InvokeCallContext, Block, Block)

```cangjie
public func createTryInvoke(retTy: Type, callContext: InvokeCallContext, normal: Block, err: Block): TryInvoke
```

功能：创建带异常处理的虚方法调用表达式。

参数：

- retTy: Type - 返回类型。
- callContext: InvokeCallContext - 虚方法调用上下文。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryInvoke](#class-tryinvoke) - 带异常处理的虚方法调用表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("method", ft)
    let fcc = FuncCallContext([], [], None)
    let ctx = InvokeCallContext(BoolLiteral.get(false), sig, fcc)
    let expr = builder.createTryInvoke(UnitType.get(), ctx, normalBlock, errBlock)
    println("createTryInvoke: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryInvoke: true
```

### func createTryNumericCast(Value, Type, Block, Block)

```cangjie
public func createTryNumericCast(srcVal: Value, dstTy: Type, normal: Block, err: Block): TryNumericCast
```

功能：创建带异常处理的数值类型转换表达式。

参数：

- srcVal: Value - 源值。
- dstTy: Type - 目标数值类型。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryNumericCast](#class-trynumericcast) - 带异常处理的数值类型转换表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryNumericCast(IntLiteral.get(IntType.getInt32(), 42), IntType.getInt64(), normalBlock, errBlock)
    println("createTryNumericCast: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryNumericCast: true
```

### func createTryRawArrayAllocate(Type, Value, Block, Block)

```cangjie
public func createTryRawArrayAllocate(elementType: Type, size: Value, normal: Block, err: Block): TryRawArrayAllocate
```

功能：创建带异常处理的原始数组分配表达式。

参数：

- elementType: Type - 数组元素类型。
- size: Value - 数组大小值。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryRawArrayAllocate](#class-tryrawarrayallocate) - 带异常处理的原始数组分配表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryRawArrayAllocate(IntType.getInt32(), IntLiteral.get(IntType.getInt64(), 10), normalBlock, errBlock)
    println("createTryRawArrayAllocate: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryRawArrayAllocate: true
```

### func createTrySpawn(Type, Value, Block, Block)

```cangjie
public func createTrySpawn(retTy: Type, val: Value, normal: Block, err: Block): TrySpawn
```

功能：创建带异常处理的并发 Spawn 表达式。

参数：

- retTy: Type - 返回类型。
- val: Value - 被启动的函数值。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TrySpawn](#class-tryspawn) - 带异常处理的 Spawn 表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f1 = pkg.addFunction(FuncType.get([], UnitType.get()), "spawn_m", "spawnTarget", "demo")
    let f2 = pkg.addFunction(FuncType.get([], UnitType.get()), "caller_m", "caller", "demo")
    f2.initBody()
    let bg = f2.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTrySpawn(UnitType.get(), f1, normalBlock, errBlock)
    println("createTrySpawn_no_arg: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTrySpawn_no_arg: true
```

### func createTrySpawn(Type, Value, Value, Block, Block)

```cangjie
public func createTrySpawn(retTy: Type, val: Value, arg: Value, normal: Block, err: Block): TrySpawn
```

功能：创建带参数和异常处理的并发 Spawn 表达式。

参数：

- retTy: Type - 返回类型。
- val: Value - 被启动的函数值。
- arg: Value - 函数参数值。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TrySpawn](#class-tryspawn) - 带参数和异常处理的 Spawn 表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f1 = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "spawn_m", "spawnTarget", "demo")
    let f2 = pkg.addFunction(FuncType.get([], UnitType.get()), "caller_m", "caller", "demo")
    f2.initBody()
    let bg = f2.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTrySpawn(UnitType.get(), f1, IntLiteral.get(IntType.getInt32(), 42), normalBlock, errBlock)
    println("createTrySpawn_with_arg: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTrySpawn_with_arg: true
```

### func createTryUnaryNeg(Value, Block, Block)

```cangjie
public func createTryUnaryNeg(op: Value, normal: Block, err: Block): TryUnaryExpression
```

功能：创建带异常处理的取负一元表达式。

参数：

- op: Value - 操作数。
- normal: Block - 正常分支目标基本块。
- err: Block - 异常分支目标基本块。

返回值：

- [TryUnaryExpression](#class-tryunaryexpression) - 带异常处理的取负表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let bg = f.body.getOrThrow()
    let entryBlock = bg.entryBlock
    let normalBlock = bg.appendBlock()
    let errBlock = bg.appendBlock()
    let builder = CHIRBuilder(InsertPosition.AtEnd(entryBlock))
    let expr = builder.createTryUnaryNeg(IntLiteral.get(IntType.getInt64(), 1), normalBlock, errBlock)
    println("createTryUnaryNeg: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTryUnaryNeg: true
```

### func createTuple(Array\<Value>)

```cangjie
public func createTuple(elements: Array<Value>): Tuple
```

功能：创建元组表达式。

参数：

- elements: Array\<Value> - 元组元素值列表。

返回值：

- [Tuple](#class-tuple) - 元组表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createTuple([IntLiteral.get(IntType.getInt32(), 1), IntLiteral.get(IntType.getInt32(), 2)])
    println("createTuple: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createTuple: true
```

### func createUnaryBitNot(Value)

```cangjie
public func createUnaryBitNot(op: Value): UnaryExpression
```

功能：创建按位取反一元表达式。

参数：

- op: Value - 操作数。

返回值：

- [UnaryExpression](#class-unaryexpression) - 按位取反表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createUnaryBitNot(IntLiteral.get(IntType.getInt64(), 3))
    println("createUnaryBitNot: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createUnaryBitNot: true
```

### func createUnaryNeg(Value, OverflowStrategy)

```cangjie
public func createUnaryNeg(op: Value, overflow: OverflowStrategy): UnaryExpression
```

功能：创建取负一元表达式。

参数：

- op: Value - 操作数。
- overflow: OverflowStrategy - 溢出策略。

返回值：

- [UnaryExpression](#class-unaryexpression) - 取负表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createUnaryNeg(IntLiteral.get(IntType.getInt64(), 5), OverflowStrategy.NA)
    println("createUnaryNeg: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createUnaryNeg: true
```

### func createUnaryNot(Value)

```cangjie
public func createUnaryNot(op: Value): UnaryExpression
```

功能：创建逻辑取反一元表达式。

参数：

- op: Value - 操作数。

返回值：

- [UnaryExpression](#class-unaryexpression) - 逻辑取反表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createUnaryNot(BoolLiteral.get(true))
    println("createUnaryNot: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createUnaryNot: true
```

### func createUnboxToRef(Value, Type)

```cangjie
public func createUnboxToRef(srcVal: Value, dstTy: Type): UnboxToRef
```

功能：创建拆箱为引用类型转换表达式。

参数：

- srcVal: Value - 源值。
- dstTy: Type - 目标引用类型。

返回值：

- [UnboxToRef](#class-unboxtoref) - 拆箱为引用表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(BoxType.get(IntType.getInt32()))
    let expr = builder.createUnboxToRef(alloc.result, IntType.getInt32())
    println("createUnboxToRef: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createUnboxToRef: true
```

### func createUnboxToValue(Value, Type)

```cangjie
public func createUnboxToValue(srcVal: Value, dstTy: Type): UnboxToValue
```

功能：创建拆箱为值类型转换表达式。

参数：

- srcVal: Value - 源值。
- dstTy: Type - 目标值类型。

返回值：

- [UnboxToValue](#class-unboxtovalue) - 拆箱为值表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let alloc = builder.createAllocate(BoxType.get(IntType.getInt32()))
    let expr = builder.createUnboxToValue(alloc.result, IntType.getInt32())
    println("createUnboxToValue: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createUnboxToValue: true
```

### func createVArray(ArrayList\<Value>)

```cangjie
public func createVArray(elements: ArrayList<Value>): VArrayExpr
```

功能：创建 VArray 表达式。

参数：

- elements: ArrayList\<Value> - VArray 元素值列表。

返回值：

- [VArrayExpr](#class-varrayexpr) - VArray 表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*
import std.collection.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let elements = ArrayList<Value>()
    elements.add(IntLiteral.get(IntType.getInt32(), 1))
    elements.add(IntLiteral.get(IntType.getInt32(), 2))
    let expr = builder.createVArray(elements)
    println("createVArray: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createVArray: true
```

### func createVArrayBuilder(Type, Value, Value, Value)

```cangjie
public func createVArrayBuilder(retTy: Type, size: Value, initVal: Value, initFunc: Value): VArrayBuilder
```

功能：创建 VArray 构建器表达式。

参数：

- retTy: Type - 返回类型。
- size: Value - 数组大小值。
- initVal: Value - 初始化值。
- initFunc: Value - 初始化函数值。

返回值：

- [VArrayBuilder](#class-varraybuilder) - VArray 构建器表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let initF = pkg.addFunction(FuncType.get([IntType.getInt32()], IntType.getInt32()), "init_m", "init", "demo")
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    let block = f.body.getOrThrow().entryBlock
    let builder = CHIRBuilder(InsertPosition.AtEnd(block))
    let expr = builder.createVArrayBuilder(IntType.getInt32(), IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt32(), 0), initF)
    println("createVArrayBuilder: ${expr.toString().size > 0}")
}
```

运行结果：

```text
createVArrayBuilder: true
```

## func serializePackage(Package)

```cangjie
public func serializePackage(pkg: Package): (CPointer<UInt8>, Int64)
```

功能：将内存中的 [Package](#class-package) 序列化为 CHIR FlatBuffers 二进制数据，返回指向序列化结果的指针及字节长度。

参数：

- pkg: [Package](#class-package) - 待序列化的 CHIR 包。

返回值：

- (CPointer\<UInt8>, Int64) - 序列化结果的指针及字节长度。调用方应在使用完毕后调用 [freeSerializedMemory](#func-freeserializedmemory) 释放内存。

示例：

<!-- run -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let (data, length) = serializePackage(pkg)
    println("length: ${length}")
    unsafe { freeSerializedMemory() }
}
```

## func deserializePackage(CPointer\<UInt8>, Int64)

```cangjie
public func deserializePackage(root: CPointer<UInt8>, length: Int64): Package
```

功能：从 FlatBuffers 二进制缓冲区反序列化 CHIR [Package](#class-package)。

参数：

- root: CPointer\<UInt8> - 指向序列化数据首字节的指针；不可为 null。
- length: Int64 - 缓冲区的字节长度。

返回值：

- [Package](#class-package) - 反序列化得到的 CHIR 包。

异常：

- [CHIRException](#class-chirexception) - 当 root 为 null 时抛出异常。

## func freeSerializedMemory()

```cangjie
public func freeSerializedMemory(): Unit
```

功能：释放上次序列化产生的共享 FlatBuffers 构建器状态。
