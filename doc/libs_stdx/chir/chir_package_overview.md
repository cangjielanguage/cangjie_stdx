# stdx.chir

> **说明：**
>
> 当前处于开发阶段，尚不具备完整功能。

## 功能介绍

chir（Cangjie High-level IR）包提供类型系统与 CHIR 声明表示，包括：

- **类型节点**（`Type` 及其子类）：内置标量、引用、装箱、原始数组与 VArray、类/接口/结构体/枚举实例化类型、函数类型、泛型形参、元组、`This` 等；
- **类型定义**（`CustomTypeDef` 系）：类、接口、结构体、枚举、扩展及成员变量；
- **包**（`Package`）与访问级别（`AccessLevel`）；
- **自定义注解实例**（公开类型 `CustomAnnoInstance`；节点上多条注解以 `Array<CustomAnnoInstance>` 暴露）与**调试位置**（`Position`、`DebugLocation`）；
- **函数定义**（`Function`）与全局/局部变量（`GlobalVar`、`LocalVar`、`Parameter`）；
- **字面量**（`BoolLiteral`、`IntLiteral`、`FloatLiteral`、`RuneLiteral`、`StringLiteral`、`NullLiteral`、`UnitLiteral`）；
- **控制流**（`Block`、`BlockGroup`）与终止器表达式（`Branch`、`GoTo`、`Exit`、`MultiBranch`、`RaiseException`）；
- **表达式基类**（`Expression`）及其中间抽象类（`AllocateBase`、`BinaryExpressionBase`、`UnaryExpressionBase`、`NumericCastBase`、`RawArrayAllocateBase`、`SpawnBase`、`TypeCast`、`FuncCall`、`ApplyBase`、`IntrinsicBase`、`InvokeBase`）；
- **值基类**（`Value`）及中间抽象类（`GlobalValue`、`LiteralValue`）；
- **类型转换**（`Box`、`StaticCast`、`CastToConcrete`、`CastToGeneric`、`UnboxToRef`、`UnboxToValue`、`NumericCast`、`TryNumericCast`）；
- **构建器**（`CHIRBuilder`）用于在基本块中按指定位置插入各类 CHIR 表达式；
- **访问器**（`CHIRVisitor`）用于遍历 CHIR 函数体中的表达式节点；**类型访问器**（`TypeVisitor`）用于遍历类型节点及其类型参数；
- **调用上下文**（`FuncCallContext`、`InvokeCallContext`、`FuncSigInfo`）；
- **序列化**（`serializePackage`、`deserializePackage`、`freeSerializedMemory`）；
- **溢出策略**（`OverflowStrategy`）、**运算类别**（`UnaryExprKind`、`BinaryExprKind`）、**插入位置**（`InsertPosition`）与**遍历行为**（`IRActionMode`、`TypeActionMode`）。

## API 列表

### 类

| 类名 | 功能 |
| --- | --- |
| [Allocate](./chir_package_api/chir_package_classes.md#class-allocate) | 内存分配表达式。 |
| [AllocateBase](./chir_package_api/chir_package_classes.md) | 内存分配表达式的密封抽象基类。 |
| [Apply](./chir_package_api/chir_package_classes.md#class-apply) | 函数调用（Apply）表达式。 |
| [ApplyBase](./chir_package_api/chir_package_classes.md) | 函数调用表达式的密封抽象基类。 |
| [BinaryExpression](./chir_package_api/chir_package_classes.md#class-binaryexpression) | 二元运算表达式。 |
| [BinaryExpressionBase](./chir_package_api/chir_package_classes.md) | 二元运算表达式的密封抽象基类。 |
| [Block](./chir_package_api/chir_package_classes.md#class-block) | CHIR 中的基本块。 |
| [BlockGroup](./chir_package_api/chir_package_classes.md#class-blockgroup) | CHIR 中的基本块组。 |
| [BoolLiteral](./chir_package_api/chir_package_classes.md#class-boolliteral) | 布尔字面量。 |
| [BoolType](./chir_package_api/chir_package_classes.md#class-booltype) | 布尔类型。 |
| [Box](./chir_package_api/chir_package_classes.md#class-box) | 装箱类型转换表达式。 |
| [BoxType](./chir_package_api/chir_package_classes.md#class-boxtype) | 装箱类型。 |
| [Branch](./chir_package_api/chir_package_classes.md#class-branch) | 条件分支（if-else）终止器表达式。 |
| [BuiltinType](./chir_package_api/chir_package_classes.md#class-builtintype) | 内置类型基类。 |
| [CHIRBuilder](./chir_package_api/chir_package_classes.md#class-chirbuilder) | CHIR 表达式构建器。 |
| [CHIRException](./chir_package_api/chir_package_classes.md#class-chirexception) | CHIR 构建或 IR 状态不一致时抛出的检查型异常。 |
| [CHIRVisitor](./chir_package_api/chir_package_classes.md#class-chirvisitor) | CHIR 函数体表达式的抽象访问器。 |
| [CPointerType](./chir_package_api/chir_package_classes.md#class-cpointertype) | C 指针类型。 |
| [CStringType](./chir_package_api/chir_package_classes.md#class-cstringtype) | C 字符串类型。 |
| [CastToConcrete](./chir_package_api/chir_package_classes.md#class-casttoconcrete) | 向具体类型转换表达式。 |
| [CastToGeneric](./chir_package_api/chir_package_classes.md#class-casttogeneric) | 向泛型类型转换表达式。 |
| [ClassLikeDef](./chir_package_api/chir_package_classes.md#class-classlikedef) | 类/接口定义。 |
| [ClassLikeType](./chir_package_api/chir_package_classes.md#class-classliketype) | 类/接口实例化类型。 |
| [Constant](./chir_package_api/chir_package_classes.md#class-constant) | 字面量常量表达式。 |
| [CustomAnnoInstance](./chir_package_api/chir_package_classes.md#class-customannoinstance) | 自定义注解实例。 |
| [CustomType](./chir_package_api/chir_package_classes.md#class-customtype) | 自定义类型抽象基类。 |
| [CustomTypeDef](./chir_package_api/chir_package_classes.md#class-customtypedef) | 自定义类型定义抽象基类，提供自定义注解实例（`customAnnoInstances`）、方法（`methods`）、静态变量（`staticVars`）等查询接口，以及追加方法（`appendMethod`）、追加静态变量（`appendStaticVar`）等构建接口。 |
| [Debug](./chir_package_api/chir_package_classes.md#class-debug) | 调试标记表达式。 |
| [DebugLocation](./chir_package_api/chir_package_classes.md#class-debuglocation) | 源码区间位置。 |
| [EnumCtorInfo](./chir_package_api/chir_package_classes.md#class-enumctorinfo) | 枚举构造器/变体信息。 |
| [EnumDef](./chir_package_api/chir_package_classes.md#class-enumdef) | 枚举定义。 |
| [EnumType](./chir_package_api/chir_package_classes.md#class-enumtype) | 枚举实例化类型。 |
| [Exit](./chir_package_api/chir_package_classes.md#class-exit) | 函数退出终止器表达式。 |
| [Expression](./chir_package_api/chir_package_classes.md) | 所有 CHIR 表达式的密封抽象基类，提供 `getArgs()` 获取子表达式列表。 |
| [ExtendDef](./chir_package_api/chir_package_classes.md#class-extenddef) | 扩展定义。 |
| [Field](./chir_package_api/chir_package_classes.md#class-field) | 按数字索引路径访问字段的表达式。 |
| [FieldByName](./chir_package_api/chir_package_classes.md#class-fieldbyname) | 按字段名路径访问字段的表达式。 |
| [FloatLiteral](./chir_package_api/chir_package_classes.md#class-floatliteral) | 浮点字面量。 |
| [FloatType](./chir_package_api/chir_package_classes.md#class-floattype) | 浮点类型。 |
| [FuncCall](./chir_package_api/chir_package_classes.md) | 函数调用表达式的密封抽象基类。 |
| [FuncCallContext](./chir_package_api/chir_package_classes.md#class-funccallcontext) | 函数调用上下文，支持 `setArg`、`setInstTypeArg` 设置参数与实例化类型参数。 |
| [FuncSigInfo](./chir_package_api/chir_package_classes.md#class-funcsiginfo) | 函数签名信息。 |
| [FuncType](./chir_package_api/chir_package_classes.md#class-functype) | 函数类型。 |
| [Function](./chir_package_api/chir_package_classes.md#class-function) | CHIR 中的函数定义。 |
| [GenericType](./chir_package_api/chir_package_classes.md#class-generictype) | 泛型形参类型。 |
| [GetElementByName](./chir_package_api/chir_package_classes.md#class-getelementbyname) | 按字段名读取聚合体元素的表达式。 |
| [GetElementRef](./chir_package_api/chir_package_classes.md#class-getelementref) | 按数字索引读取聚合体元素引用的表达式。 |
| [GetException](./chir_package_api/chir_package_classes.md#class-getexception) | 获取异常值的表达式。 |
| [GetInstantiateValue](./chir_package_api/chir_package_classes.md#class-getinstantiatevalue) | 获取泛型函数实例化值的表达式。 |
| [GetRTTI](./chir_package_api/chir_package_classes.md#class-getrtti) | 获取运行时类型信息的表达式。 |
| [GetRTTIStatic](./chir_package_api/chir_package_classes.md#class-getrttistatic) | 静态获取运行时类型信息的表达式。 |
| [GlobalValue](./chir_package_api/chir_package_classes.md#class-globalvalue) | 全局值的密封抽象基类；提供 `destroySelf()` 销毁函数或全局变量。 |
| [GlobalVar](./chir_package_api/chir_package_classes.md#class-globalvar) | CHIR 中的全局变量定义。 |
| [GoTo](./chir_package_api/chir_package_classes.md#class-goto) | 无条件跳转终止器表达式。 |
| [InstanceOf](./chir_package_api/chir_package_classes.md#class-instanceof) | 类型检查表达式。 |
| [IntLiteral](./chir_package_api/chir_package_classes.md#class-intliteral) | 整数字面量。 |
| [IntType](./chir_package_api/chir_package_classes.md#class-inttype) | 整数类型。 |
| [Intrinsic](./chir_package_api/chir_package_classes.md#class-intrinsic) | 内建函数调用表达式。 |
| [IntrinsicBase](./chir_package_api/chir_package_classes.md) | 内建函数调用表达式的密封抽象基类。 |
| [Invoke](./chir_package_api/chir_package_classes.md#class-invoke) | 虚方法调用（Invoke）表达式。 |
| [InvokeBase](./chir_package_api/chir_package_classes.md) | 虚方法调用表达式的密封抽象基类。 |
| [InvokeCallContext](./chir_package_api/chir_package_classes.md#class-invokecallcontext) | 虚方法调用上下文。 |
| [Lambda](./chir_package_api/chir_package_classes.md#class-lambda) | Lambda / 局部函数表达式，提供 `isCompileTimeValue`、`isLocalFunc`、`returnValue` 等查询接口。 |
| [LocalVar](./chir_package_api/chir_package_classes.md#class-localvar) | CHIR 中的局部变量。 |
| [Load](./chir_package_api/chir_package_classes.md#class-load) | 内存加载表达式。 |
| [MemberVar](./chir_package_api/chir_package_classes.md#class-membervar) | 成员变量描述。 |
| [MultiBranch](./chir_package_api/chir_package_classes.md#class-multibranch) | 多分支（switch-case）终止器表达式。 |
| [NothingType](./chir_package_api/chir_package_classes.md#class-nothingtype) | Nothing 底类型。 |
| [NullLiteral](./chir_package_api/chir_package_classes.md#class-nullliteral) | Null 字面量。 |
| [NumericCast](./chir_package_api/chir_package_classes.md#class-numericcast) | 数值类型转换表达式。 |
| [NumericCastBase](./chir_package_api/chir_package_classes.md) | 数值类型转换表达式的密封抽象基类。 |
| [NumericType](./chir_package_api/chir_package_classes.md#class-numerictype) | 数值类型抽象基类。 |
| [Package](./chir_package_api/chir_package_classes.md#class-package) | CHIR 包，提供全局变量（`globalVars`）、函数（`functions`）、全部自定义类型定义（`allCustomTypeDefs`）、包初始化函数（`packageInitFunc`、`packageLiteralInitFunc`）等查询接口，以及添加函数（`addFunction`）、添加全局变量（`addGlobalVar`）、按签名获取函数（`getSpecifiedFunction`）等构建接口。 |
| [Parameter](./chir_package_api/chir_package_classes.md#class-parameter) | CHIR 中的函数参数。 |
| [RaiseException](./chir_package_api/chir_package_classes.md#class-raiseexception) | 抛出异常终止器表达式。 |
| [RawArrayAllocate](./chir_package_api/chir_package_classes.md#class-rawarrayallocate) | 原始数组分配表达式。 |
| [RawArrayAllocateBase](./chir_package_api/chir_package_classes.md) | 原始数组分配表达式的密封抽象基类。 |
| [RawArrayInitByValue](./chir_package_api/chir_package_classes.md#class-rawarrayinitbyvalue) | 按值初始化原始数组表达式。 |
| [RawArrayLiteralInit](./chir_package_api/chir_package_classes.md#class-rawarrayliteralinit) | 字面量初始化原始数组表达式。 |
| [RawArrayType](./chir_package_api/chir_package_classes.md#class-rawarraytype) | 原始数组类型。 |
| [RefType](./chir_package_api/chir_package_classes.md#class-reftype) | 引用类型 `T&`。 |
| [RuneLiteral](./chir_package_api/chir_package_classes.md#class-runeliteral) | Rune（字符）字面量。 |
| [RuneType](./chir_package_api/chir_package_classes.md#class-runetype) | 字符类型。 |
| [Spawn](./chir_package_api/chir_package_classes.md#class-spawn) | 并发 Spawn 表达式。 |
| [SpawnBase](./chir_package_api/chir_package_classes.md) | 并发 Spawn 表达式的密封抽象基类。 |
| [StaticCast](./chir_package_api/chir_package_classes.md#class-staticcast) | 静态类型转换表达式。 |
| [Store](./chir_package_api/chir_package_classes.md#class-store) | 内存存储表达式。 |
| [StoreElementByName](./chir_package_api/chir_package_classes.md#class-storeelementbyname) | 按字段名存储聚合体元素的表达式。 |
| [StoreElementRef](./chir_package_api/chir_package_classes.md#class-storeelementref) | 按数字索引存储聚合体元素的表达式。 |
| [StringLiteral](./chir_package_api/chir_package_classes.md#class-stringliteral) | 字符串字面量。 |
| [StructDef](./chir_package_api/chir_package_classes.md#class-structdef) | 结构体定义。 |
| [StructType](./chir_package_api/chir_package_classes.md#class-structtype) | 结构体实例化类型。 |
| [ThisType](./chir_package_api/chir_package_classes.md#class-thistype) | `This` 类型。 |
| [TryAllocate](./chir_package_api/chir_package_classes.md#class-tryallocate) | 带异常处理的内存分配表达式。 |
| [TryApply](./chir_package_api/chir_package_classes.md#class-tryapply) | 带异常处理的函数调用表达式。 |
| [TryBinaryExpression](./chir_package_api/chir_package_classes.md#class-trybinaryexpression) | 带异常处理的二元运算表达式。 |
| [TryIntrinsic](./chir_package_api/chir_package_classes.md#class-tryintrinsic) | 带异常处理的内建函数调用表达式。 |
| [TryInvoke](./chir_package_api/chir_package_classes.md#class-tryinvoke) | 带异常处理的虚方法调用表达式。 |
| [TryNumericCast](./chir_package_api/chir_package_classes.md#class-trynumericcast) | 带异常处理的数值类型转换表达式。 |
| [TryRawArrayAllocate](./chir_package_api/chir_package_classes.md#class-tryrawarrayallocate) | 带异常处理的原始数组分配表达式。 |
| [TrySpawn](./chir_package_api/chir_package_classes.md#class-tryspawn) | 带异常处理的并发 Spawn 表达式。 |
| [TryUnaryExpression](./chir_package_api/chir_package_classes.md#class-tryunaryexpression) | 带异常处理的一元运算表达式。 |
| [Tuple](./chir_package_api/chir_package_classes.md#class-tuple) | 元组构造表达式。 |
| [TupleType](./chir_package_api/chir_package_classes.md#class-tupletype) | 元组类型。 |
| [Type](./chir_package_api/chir_package_classes.md#class-type) | 所有类型的密封抽象基类，提供 `isXxx` 类型判断方法。 |
| [TypeCast](./chir_package_api/chir_package_classes.md) | 类型转换表达式的密封抽象基类。 |
| [TypeVisitor](./chir_package_api/chir_package_classes.md) | CHIR 类型节点的抽象访问器。 |
| [UnaryExpression](./chir_package_api/chir_package_classes.md#class-unaryexpression) | 一元运算表达式。 |
| [UnaryExpressionBase](./chir_package_api/chir_package_classes.md) | 一元运算表达式的密封抽象基类。 |
| [UnboxToRef](./chir_package_api/chir_package_classes.md#class-unboxtoref) | 拆箱为引用的类型转换表达式。 |
| [UnboxToValue](./chir_package_api/chir_package_classes.md#class-unboxtovalue) | 拆箱为值的类型转换表达式。 |
| [UnitLiteral](./chir_package_api/chir_package_classes.md#class-unitliteral) | Unit 字面量。 |
| [UnitType](./chir_package_api/chir_package_classes.md#class-unittype) | Unit 类型。 |
| [VArrayBuilder](./chir_package_api/chir_package_classes.md#class-varraybuilder) | VArray 构建器表达式。 |
| [VArrayExpr](./chir_package_api/chir_package_classes.md#class-varrayexpr) | VArray 字面量表达式。 |
| [VArrayType](./chir_package_api/chir_package_classes.md#class-varraytype) | 定长 VArray 类型。 |
| [Value](./chir_package_api/chir_package_classes.md) | 所有 CHIR 值的密封抽象基类。 |

### 顶层函数

| 函数名 | 功能 |
| --- | --- |
| [serializePackage](./chir_package_api/chir_package_classes.md#func-serializepackagepackage) | 将 Package 序列化为二进制数据。 |
| [deserializePackage](./chir_package_api/chir_package_classes.md#func-deserializepackagecpointeruint8-int64) | 从二进制数据反序列化 Package。 |
| [freeSerializedMemory](./chir_package_api/chir_package_classes.md#func-freeserializedmemory) | 释放序列化产生的内存。 |

### 枚举

| 枚举名 | 功能 |
| --- | --- |
| [AccessLevel](./chir_package_api/chir_package_enums.md#enum-accesslevel) | 包访问级别。 |
| [BinaryExprKind](./chir_package_api/chir_package_enums.md#enum-binaryexprkind) | 二元运算符类别。 |
| [InsertPosition](./chir_package_api/chir_package_enums.md#enum-insertposition) | CHIRBuilder 插入位置。 |
| [IRActionMode](./chir_package_api/chir_package_enums.md#enum-iractionmode) | CHIRVisitor 遍历行为模式。 |
| [OverflowStrategy](./chir_package_api/chir_package_enums.md#enum-overflowstrategy) | 溢出处理策略。 |
| [TypeActionMode](./chir_package_api/chir_package_enums.md#enum-typeactionmode) | TypeVisitor 遍历行为模式。 |
| [UnaryExprKind](./chir_package_api/chir_package_enums.md#enum-unaryexprkind) | 一元运算符类别。 |

### 结构体

| 结构体名 | 功能 |
| --- | --- |
| [Position](./chir_package_api/chir_package_structs.md#struct-position) | 源码行列位置。 |