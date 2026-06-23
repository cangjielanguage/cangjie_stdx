# stdx.chir

> **Note:**
>
> Under active development; functionality is not yet complete.

## Overview

The **chir** (Cangjie High-level IR) package provides the type system and CHIR declaration model, including:

- **Type nodes** (`Type` and subclasses): built-in scalars, reference, boxed, raw arrays and VArray, class/interface/struct/enum instantiated types, function types, generic parameters, tuples, `This`, and more;
- **Type definitions** (`CustomTypeDef` family): classes, interfaces, structs, enums, extensions, and member variables;
- **Packages** (`Package`) and **access levels** (`AccessLevel`);
- **Custom annotation instances** (public type `CustomAnnoInstance`; multiple annotations on a node are exposed as `Array<CustomAnnoInstance>`) and **debug locations** (`Position`, `DebugLocation`);
- **Function definitions** (`Function`) and global/local variables (`GlobalVar`, `LocalVar`, `Parameter`);
- **Literals** (`BoolLiteral`, `IntLiteral`, `FloatLiteral`, `RuneLiteral`, `StringLiteral`, `NullLiteral`, `UnitLiteral`);
- **Control flow** (`Block`, `BlockGroup`) and terminator expressions (`Branch`, `GoTo`, `Exit`, `MultiBranch`, `RaiseException`);
- **Expression base** (`Expression`) and its intermediate sealed abstract classes (`AllocateBase`, `BinaryExpressionBase`, `UnaryExpressionBase`, `NumericCastBase`, `RawArrayAllocateBase`, `SpawnBase`, `TypeCast`, `FuncCall`, `ApplyBase`, `IntrinsicBase`, `InvokeBase`);
- **Value base** (`Value`) and intermediate abstract classes (`GlobalValue`, `LiteralValue`);
- **Type conversions** (`Box`, `StaticCast`, `CastToConcrete`, `CastToGeneric`, `UnboxToRef`, `UnboxToValue`, `NumericCast`, `TryNumericCast`);
- **Builder** (`CHIRBuilder`) for inserting CHIR expressions into basic blocks at specified positions;
- **Visitor** (`CHIRVisitor`) for traversing expression nodes in CHIR function bodies; **Type Visitor** (`TypeVisitor`) for traversing type nodes and their type arguments;
- **Call contexts** (`FuncCallContext`, `InvokeCallContext`, `FuncSigInfo`);
- **Serialization** (`serializePackage`, `deserializePackage`, `freeSerializedMemory`);
- **Overflow strategies** (`OverflowStrategy`), **operator categories** (`UnaryExprKind`, `BinaryExprKind`), **insertion positions** (`InsertPosition`), and **traversal behaviors** (`IRActionMode`, `TypeActionMode`).

## API index

### Classes

| Name | Description |
| --- | --- |
| [Allocate](./chir_package_api/chir_package_classes.md#class-allocate) | Memory allocation expression. |
| [AllocateBase](./chir_package_api/chir_package_classes.md) | Sealed abstract base for memory allocation expressions. |
| [Apply](./chir_package_api/chir_package_classes.md#class-apply) | Function call (Apply) expression. |
| [ApplyBase](./chir_package_api/chir_package_classes.md) | Sealed abstract base for function call expressions. |
| [BinaryExpression](./chir_package_api/chir_package_classes.md#class-binaryexpression) | Binary operation expression. |
| [BinaryExpressionBase](./chir_package_api/chir_package_classes.md) | Sealed abstract base for binary operation expressions. |
| [Block](./chir_package_api/chir_package_classes.md#class-block) | Basic block in CHIR. |
| [BlockGroup](./chir_package_api/chir_package_classes.md#class-blockgroup) | Basic block group in CHIR. |
| [BoolLiteral](./chir_package_api/chir_package_classes.md#class-boolliteral) | Boolean literal. |
| [BoolType](./chir_package_api/chir_package_classes.md#class-booltype) | Boolean type. |
| [Box](./chir_package_api/chir_package_classes.md#class-box) | Box type conversion expression. |
| [BoxType](./chir_package_api/chir_package_classes.md#class-boxtype) | Boxed type. |
| [Branch](./chir_package_api/chir_package_classes.md#class-branch) | Conditional branch (if-else) terminator expression. |
| [BuiltinType](./chir_package_api/chir_package_classes.md#class-builtintype) | Base class for built-in types. |
| [CHIRBuilder](./chir_package_api/chir_package_classes.md#class-chirbuilder) | CHIR expression builder. |
| [CHIRException](./chir_package_api/chir_package_classes.md#class-chirexception) | Checked exception thrown when CHIR builder/IR state is inconsistent. |
| [CHIRVisitor](./chir_package_api/chir_package_classes.md#class-chirvisitor) | Abstract visitor for CHIR function body expressions. |
| [CPointerType](./chir_package_api/chir_package_classes.md#class-cpointertype) | C pointer type. |
| [CStringType](./chir_package_api/chir_package_classes.md#class-cstringtype) | C string type. |
| [CastToConcrete](./chir_package_api/chir_package_classes.md#class-casttoconcrete) | Cast to concrete type expression. |
| [CastToGeneric](./chir_package_api/chir_package_classes.md#class-casttogeneric) | Cast to generic type expression. |
| [ClassLikeDef](./chir_package_api/chir_package_classes.md#class-classlikedef) | Class or interface definition. |
| [ClassLikeType](./chir_package_api/chir_package_classes.md#class-classliketype) | Instantiated class/interface type. |
| [Constant](./chir_package_api/chir_package_classes.md#class-constant) | Literal constant expression. |
| [CustomAnnoInstance](./chir_package_api/chir_package_classes.md#class-customannoinstance) | Custom annotation instance. |
| [CustomType](./chir_package_api/chir_package_classes.md#class-customtype) | Abstract base for custom instantiated types. |
| [CustomTypeDef](./chir_package_api/chir_package_classes.md#class-customtypedef) | Abstract base for custom type definitions, with query interfaces for custom annotation instances (`customAnnoInstances`), methods (`methods`), static variables (`staticVars`), and builder interfaces for appending methods (`appendMethod`) and static variables (`appendStaticVar`). |
| [Debug](./chir_package_api/chir_package_classes.md#class-debug) | Debug marker expression. |
| [DebugLocation](./chir_package_api/chir_package_classes.md#class-debuglocation) | Source span (debug location). |
| [EnumCtorInfo](./chir_package_api/chir_package_classes.md#class-enumctorinfo) | Enum constructor / variant info. |
| [EnumDef](./chir_package_api/chir_package_classes.md#class-enumdef) | Enum definition. |
| [EnumType](./chir_package_api/chir_package_classes.md#class-enumtype) | Instantiated enum type. |
| [Exit](./chir_package_api/chir_package_classes.md#class-exit) | Function exit terminator expression. |
| [Expression](./chir_package_api/chir_package_classes.md) | Sealed abstract base for all CHIR expressions, with `getArgs()` for retrieving sub-expression list. |
| [ExtendDef](./chir_package_api/chir_package_classes.md#class-extenddef) | Extension definition. |
| [Field](./chir_package_api/chir_package_classes.md#class-field) | Field access expression by numeric index path. |
| [FieldByName](./chir_package_api/chir_package_classes.md#class-fieldbyname) | Field access expression by field name path. |
| [FloatLiteral](./chir_package_api/chir_package_classes.md#class-floatliteral) | Floating-point literal. |
| [FloatType](./chir_package_api/chir_package_classes.md#class-floattype) | Floating-point type. |
| [FuncCall](./chir_package_api/chir_package_classes.md) | Sealed abstract base for function call expressions. |
| [FuncCallContext](./chir_package_api/chir_package_classes.md#class-funccallcontext) | Function call context, with `setArg` and `setInstTypeArg` for setting arguments and instantiation type arguments. |
| [FuncSigInfo](./chir_package_api/chir_package_classes.md#class-funcsiginfo) | Function signature information. |
| [FuncType](./chir_package_api/chir_package_classes.md#class-functype) | Function type. |
| [Function](./chir_package_api/chir_package_classes.md#class-function) | Function definition in CHIR. |
| [GenericType](./chir_package_api/chir_package_classes.md#class-generictype) | Generic parameter type. |
| [GetElementByName](./chir_package_api/chir_package_classes.md#class-getelementbyname) | Aggregate element read expression by field name. |
| [GetElementRef](./chir_package_api/chir_package_classes.md#class-getelementref) | Aggregate element reference read expression by numeric index. |
| [GetException](./chir_package_api/chir_package_classes.md#class-getexception) | Expression to retrieve the exception value. |
| [GetInstantiateValue](./chir_package_api/chir_package_classes.md#class-getinstantiatevalue) | Expression to retrieve generic function instantiation value. |
| [GetRTTI](./chir_package_api/chir_package_classes.md#class-getrtti) | Expression to retrieve runtime type information. |
| [GetRTTIStatic](./chir_package_api/chir_package_classes.md#class-getrttistatic) | Expression to statically retrieve runtime type information. |
| [GlobalValue](./chir_package_api/chir_package_classes.md) | Sealed abstract base for global values. |
| [GlobalVar](./chir_package_api/chir_package_classes.md#class-globalvar) | Global variable definition in CHIR. |
| [GoTo](./chir_package_api/chir_package_classes.md#class-goto) | Unconditional jump terminator expression. |
| [InstanceOf](./chir_package_api/chir_package_classes.md#class-instanceof) | Type check expression. |
| [IntLiteral](./chir_package_api/chir_package_classes.md#class-intliteral) | Integer literal. |
| [IntType](./chir_package_api/chir_package_classes.md#class-inttype) | Integer type. |
| [Intrinsic](./chir_package_api/chir_package_classes.md#class-intrinsic) | Intrinsic function call expression. |
| [IntrinsicBase](./chir_package_api/chir_package_classes.md) | Sealed abstract base for intrinsic function call expressions. |
| [Invoke](./chir_package_api/chir_package_classes.md#class-invoke) | Virtual method call (Invoke) expression. |
| [InvokeBase](./chir_package_api/chir_package_classes.md) | Sealed abstract base for virtual method call expressions. |
| [InvokeCallContext](./chir_package_api/chir_package_classes.md#class-invokecallcontext) | Virtual method call context. |
| [Lambda](./chir_package_api/chir_package_classes.md#class-lambda) | Lambda / local function expression, with `isCompileTimeValue`, `isLocalFunc`, and `returnValue` properties. |
| [LocalVar](./chir_package_api/chir_package_classes.md#class-localvar) | Local variable in CHIR. |
| [Load](./chir_package_api/chir_package_classes.md#class-load) | Memory load expression. |
| [MemberVar](./chir_package_api/chir_package_classes.md#class-membervar) | Member variable description. |
| [MultiBranch](./chir_package_api/chir_package_classes.md#class-multibranch) | Multi-branch (switch-case) terminator expression. |
| [NothingType](./chir_package_api/chir_package_classes.md#class-nothingtype) | Nothing (bottom) type. |
| [NullLiteral](./chir_package_api/chir_package_classes.md#class-nullliteral) | Null literal. |
| [NumericCast](./chir_package_api/chir_package_classes.md#class-numericcast) | Numeric type conversion expression. |
| [NumericCastBase](./chir_package_api/chir_package_classes.md) | Sealed abstract base for numeric type conversion expressions. |
| [NumericType](./chir_package_api/chir_package_classes.md#class-numerictype) | Abstract base for numeric types. |
| [Package](./chir_package_api/chir_package_classes.md#class-package) | CHIR package, with query interfaces for global variables (`globalVars`), functions (`functions`), all custom type definitions (`allCustomTypeDefs`), and package init function (`packageInitFunc`), plus builder interfaces for adding functions (`addFunction`), global variables (`addGlobalVar`), and retrieving functions by signature (`getSpecifiedFunction`). |
| [Parameter](./chir_package_api/chir_package_classes.md#class-parameter) | Function parameter in CHIR. |
| [RaiseException](./chir_package_api/chir_package_classes.md#class-raiseexception) | Raise exception terminator expression. |
| [RawArrayAllocate](./chir_package_api/chir_package_classes.md#class-rawarrayallocate) | Raw array allocation expression. |
| [RawArrayAllocateBase](./chir_package_api/chir_package_classes.md) | Sealed abstract base for raw array allocation expressions. |
| [RawArrayInitByValue](./chir_package_api/chir_package_classes.md#class-rawarrayinitbyvalue) | Raw array initialization by value expression. |
| [RawArrayLiteralInit](./chir_package_api/chir_package_classes.md#class-rawarrayliteralinit) | Raw array literal initialization expression. |
| [RawArrayType](./chir_package_api/chir_package_classes.md#class-rawarraytype) | Raw array type. |
| [RefType](./chir_package_api/chir_package_classes.md#class-reftype) | Reference type `T&`. |
| [RuneLiteral](./chir_package_api/chir_package_classes.md#class-runeliteral) | Rune (character) literal. |
| [RuneType](./chir_package_api/chir_package_classes.md#class-runetype) | Character type. |
| [Spawn](./chir_package_api/chir_package_classes.md#class-spawn) | Concurrent Spawn expression. |
| [SpawnBase](./chir_package_api/chir_package_classes.md) | Sealed abstract base for concurrent Spawn expressions. |
| [StaticCast](./chir_package_api/chir_package_classes.md#class-staticcast) | Static type cast expression. |
| [Store](./chir_package_api/chir_package_classes.md#class-store) | Memory store expression. |
| [StoreElementByName](./chir_package_api/chir_package_classes.md#class-storeelementbyname) | Aggregate element store expression by field name. |
| [StoreElementRef](./chir_package_api/chir_package_classes.md#class-storeelementref) | Aggregate element store expression by numeric index. |
| [StringLiteral](./chir_package_api/chir_package_classes.md#class-stringliteral) | String literal. |
| [StructDef](./chir_package_api/chir_package_classes.md#class-structdef) | Struct definition. |
| [StructType](./chir_package_api/chir_package_classes.md#class-structtype) | Instantiated struct type. |
| [ThisType](./chir_package_api/chir_package_classes.md#class-thistype) | `This` type. |
| [TryAllocate](./chir_package_api/chir_package_classes.md#class-tryallocate) | Memory allocation expression with exception handling. |
| [TryApply](./chir_package_api/chir_package_classes.md#class-tryapply) | Function call expression with exception handling. |
| [TryBinaryExpression](./chir_package_api/chir_package_classes.md#class-trybinaryexpression) | Binary operation expression with exception handling. |
| [TryIntrinsic](./chir_package_api/chir_package_classes.md#class-tryintrinsic) | Intrinsic function call expression with exception handling. |
| [TryInvoke](./chir_package_api/chir_package_classes.md#class-tryinvoke) | Virtual method call expression with exception handling. |
| [TryNumericCast](./chir_package_api/chir_package_classes.md#class-trynumericcast) | Numeric type conversion expression with exception handling. |
| [TryRawArrayAllocate](./chir_package_api/chir_package_classes.md#class-tryrawarrayallocate) | Raw array allocation expression with exception handling. |
| [TrySpawn](./chir_package_api/chir_package_classes.md#class-tryspawn) | Concurrent Spawn expression with exception handling. |
| [TryUnaryExpression](./chir_package_api/chir_package_classes.md#class-tryunaryexpression) | Unary operation expression with exception handling. |
| [Tuple](./chir_package_api/chir_package_classes.md#class-tuple) | Tuple construction expression. |
| [TupleType](./chir_package_api/chir_package_classes.md#class-tupletype) | Tuple type. |
| [Type](./chir_package_api/chir_package_classes.md#class-type) | Sealed abstract base for all types, with `isXxx` type-checking methods. |
| [TypeCast](./chir_package_api/chir_package_classes.md) | Sealed abstract base for type conversion expressions. |
| [TypeVisitor](./chir_package_api/chir_package_classes.md) | Abstract visitor for CHIR type nodes. |
| [UnaryExpression](./chir_package_api/chir_package_classes.md#class-unaryexpression) | Unary operation expression. |
| [UnaryExpressionBase](./chir_package_api/chir_package_classes.md) | Sealed abstract base for unary operation expressions. |
| [UnboxToRef](./chir_package_api/chir_package_classes.md#class-unboxtoref) | Unbox-to-reference type conversion expression. |
| [UnboxToValue](./chir_package_api/chir_package_classes.md#class-unboxtovalue) | Unbox-to-value type conversion expression. |
| [UnitLiteral](./chir_package_api/chir_package_classes.md#class-unitliteral) | Unit literal. |
| [UnitType](./chir_package_api/chir_package_classes.md#class-unittype) | Unit type. |
| [VArrayBuilder](./chir_package_api/chir_package_classes.md#class-varraybuilder) | VArray builder expression. |
| [VArrayExpr](./chir_package_api/chir_package_classes.md#class-varrayexpr) | VArray literal expression. |
| [VArrayType](./chir_package_api/chir_package_classes.md#class-varraytype) | Fixed-size VArray type. |
| [Value](./chir_package_api/chir_package_classes.md) | Sealed abstract base for all CHIR values. |

### Top-level functions

| Name | Description |
| --- | --- |
| [serializePackage](./chir_package_api/chir_package_classes.md#func-serializepackagepackage) | Serialize a Package to binary data. |
| [deserializePackage](./chir_package_api/chir_package_classes.md#func-deserializepackagecpointeruint8-int64) | Deserialize a Package from binary data. |
| [freeSerializedMemory](./chir_package_api/chir_package_classes.md#func-freeserializedmemory) | Free memory produced by serialization. |

### Enums

| Name | Description |
| --- | --- |
| [AccessLevel](./chir_package_api/chir_package_enums.md#enum-accesslevel) | Package access level. |
| [BinaryExprKind](./chir_package_api/chir_package_enums.md#enum-binaryexprkind) | Binary operator category. |
| [InsertPosition](./chir_package_api/chir_package_enums.md#enum-insertposition) | CHIRBuilder insertion position. |
| [IRActionMode](./chir_package_api/chir_package_enums.md#enum-iractionmode) | CHIRVisitor traversal behavior mode. |
| [OverflowStrategy](./chir_package_api/chir_package_enums.md#enum-overflowstrategy) | Overflow handling strategy. |
| [TypeActionMode](./chir_package_api/chir_package_enums.md#enum-typeactionmode) | TypeVisitor traversal behavior mode. |
| [UnaryExprKind](./chir_package_api/chir_package_enums.md#enum-unaryexprkind) | Unary operator category. |

### Structs

| Name | Description |
| --- | --- |
| [Position](./chir_package_api/chir_package_structs.md#struct-position) | Source line/column position. |