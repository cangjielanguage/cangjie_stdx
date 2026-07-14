# Classes

## class CustomAnnoInstance

```cangjie
public class CustomAnnoInstance <: ToString {
    public init(classSrcCodeName: String)
    public init(classSrcCodeName: String, loc: DebugLocation)
}
```

Function: Represents **one** annotation instance in CHIR, corresponding to the source form `@ClassName[v1, v2, ...]`: stores the annotation class name and a list of argument values.

Parent Types:

- ToString

### prop argValues

```cangjie
public mut prop argValues: Array<String>
```

Function: Gets or sets the annotation argument values. Getter returns the current list of argument values; setter replaces the entire list.

Type: Array\<String>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("MyAnno")
    println(a.argValues.size)
}
```

Output:

```text
0
```

### prop classSrcCodeName

```cangjie
public prop classSrcCodeName: String
```

Function: The annotation class name as it appears in source code.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("MyAnno")
    println(a.classSrcCodeName)
}
```

Output:

```text
MyAnno
```

### prop location

```cangjie
public prop location: DebugLocation
```

Function: Source location where this annotation appeared.

Type: [DebugLocation](#class-debuglocation)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("MyAnno")
    println(a.location.isValid())
}
```

Output:

```text
false
```

### init(String)

```cangjie
public init(classSrcCodeName: String)
```

Function: Constructs a `CustomAnnoInstance` object with the given annotation class name, an **initially empty** argument values list, and an invalid location.

Parameters:

- classSrcCodeName: String - The annotation class name in source code (e.g. `MyAnno`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("Fresh")
    println(a.toString())
}
```

Output:

```text
@Fresh[]
```

### init(String, DebugLocation)

```cangjie
public init(classSrcCodeName: String, loc: DebugLocation)
```

Function: Constructs a `CustomAnnoInstance` object with the given annotation class name and source location.

Parameters:

- classSrcCodeName: String - The annotation class name in source code (e.g. `MyAnno`).
- loc: [DebugLocation](#class-debuglocation) - Source location where this annotation appeared.

Example:

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

Output:

```text
@Fresh[]
```

### func toString()

```cangjie
public func toString(): String
```

Function: Formats as `@ClassName[v1, v2, ...]` for logging and debugging.

Return Value:

- String - Textual form of the annotation.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let a = CustomAnnoInstance("T")
    println(a.toString())
}
```

Output:

```text
@T[]
```

## class BoolType

```cangjie
public class BoolType <: BuiltinType & Equatable<BoolType> {}
```

Function: Represents the boolean type in the type system. This is a singleton type representing the Bool type.

Parent Types:

- [BuiltinType](#class-builtintype)
- Equatable\<[BoolType](#class-booltype)>

### static func get()

```cangjie
public static func get(): BoolType
```

Function: Gets the singleton instance of BoolType.

Return Value:

- [BoolType](#class-booltype) - BoolType instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let boolType = BoolType.get()
    println("Boolean type: ${boolType.toString()}")
}
```

Output:

```text
Boolean type: Bool
```

### operator func ==(BoolType)

```cangjie
public operator func ==(_: BoolType): Bool
```

Function: Checks whether this BoolType is equal to another BoolType.

Parameters:

- _: BoolType - The other BoolType to compare with (unused; always returns true).

Return Value:

- Bool - Always returns true because all BoolType instances are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let boolType1 = BoolType.get()
    let boolType2 = BoolType.get()
    println("Two BoolType instances are equal: ${boolType1 == boolType2}")
}
```

Output:

```text
Two BoolType instances are equal: true
```

## class BoxType

```cangjie
public class BoxType <: Type & Equatable<BoxType> {}
```

Function: Represents the **boxed type** `Box<T>`, wrapping values in a box. The cache ensures a unique instance per `baseType`.

Parent Types:

- [Type](#class-type)
- Equatable\<[BoxType](#class-boxtype)>

### prop baseType

```cangjie
public prop baseType: Type
```

Function: The base type being boxed.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let b = BoxType.get(IntType.getInt32())
    println(b.baseType.toString())
}
```

Output:

```text
Int32
```

### static func get(Type)

```cangjie
public static func get(baseType: Type): BoxType
```

Function: Gets or creates the `BoxType` for the given base type.

Return Value:

- [BoxType](#class-boxtype) - The BoxType instance for the given base type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let b = BoxType.get(IntType.getInt32())
    println(b.toString())
}
```

Output:

```text
Box<Int32>
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form, typically in the `Box<...>` style.

Return Value:

- String - A string representation of the box type (Box<baseType>).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let b = BoxType.get(IntType.getUInt32())
    println(b.toString())
}
```

Output:

```text
Box<UInt32>
```

### operator func ==(BoxType)

```cangjie
public operator func ==(other: BoxType): Bool
```

Function: Compares whether two `BoxType` instances are the same.

Return Value:

- Bool - true if the types are equal, false otherwise.

Example:

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

Output:

```text
op_eq_BoxType: true
```

## class BuiltinType

```cangjie
sealed abstract class BuiltinType <: Type & Equatable<BuiltinType> {}
```

Function: Common base class for built-in types (numeric, Bool, Unit, pointer, array, etc.); can attach `ExtendDef` (`addExtend`) and collect interface parent types implemented via `extend` through `getSuperTypesRecusively`.

Parent Types:

- [Type](#class-type)
- Equatable\<[BuiltinType](#class-builtintype)>

### func addExtend(ExtendDef)

```cangjie
public func addExtend(extendDef: ExtendDef): Unit
```

Function: Registers one [ExtendDef](#class-extenddef) for this built-in type (corresponding to an `extend` block for that built-in type in source).

Parameters:

- extendDef: ExtendDef - Extension definition.

Example:

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

Output:

```text
extend id: @ext_mangled
```

(The exact `identifier` prefix and mangling rules follow the source implementation.)

### func getSuperTypesRecusively(ArrayList\<(Type, Type)>)

```cangjie
public func getSuperTypesRecusively(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType>
```

Function: Starting from interfaces implemented via `extend` on this type, recursively collects [ClassLikeType](#class-classliketype) on the parent interface/class side (for semantic and inheritance analysis).

Parameters:

- visited! - Visitation table for cycle detection; usually pass the default empty table.

Return Value:

- Array\<[ClassLikeType](#class-classliketype)> - Collected sequence of types.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = IntType.getInt32()
    println("${t.getSuperTypesRecusively().size}")
}
```

Output:

```text
0
```

### operator func ==(BuiltinType)

```cangjie
public operator func ==(other: BuiltinType): Bool
```

Function: Compares whether two built-in types denote the same class and identical type arguments.

Parameters:

- other: BuiltinType - The other built-in type.

Return Value:

- Bool - `true` if equal.

Example:

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

Output:

```text
op_eq_BuiltinType sameInt32: true
op_eq_BuiltinType int32vsInt64: false
```

## class CPointerType

```cangjie
public class CPointerType <: BuiltinType & Equatable<CPointerType> {}
```

Function: Represents a C pointer type in the type system. This type denotes a pointer to a C type for C interoperability. The class caches all C pointer types to ensure uniqueness.

Parent Types:

- [BuiltinType](#class-builtintype)
- Equatable\<[CPointerType](#class-cpointertype)>

### prop elementType

```cangjie
public prop elementType: Type
```

Function: Gets the element type that this C pointer type points to.

Return Value:

- [Type](#class-type) - Element type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let cp = CPointerType.get(intType)
    println(cp.elementType.toString())
}
```

Output:

```text
Int32
```

### static func get(Type)

```cangjie
public static func get(elementType: Type): CPointerType
```

Function: Gets or creates the CPointerType for the given element type.

This method ensures there is at most one CPointerType instance per element type.

Parameters:

- elementType: Type - The type the pointer points to.

Return Value:

- [CPointerType](#class-cpointertype) - The CPointerType instance for the given element type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let cPointerType = CPointerType.get(intType)
    println(cPointerType.toString())
}
```

Output:

```text
CPointer<Int32>
```

### func toString()

```cangjie
public func toString(): String
```

Function: Converts this CPointerType to a string representation.

Return Value:

- String - String form of the C pointer type (`CPointer\<elementType>`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let cPointerType = CPointerType.get(IntType.getUInt32())
    println(cPointerType.toString())
}
```

Output:

```text
CPointer<UInt32>
```

### operator func ==(CPointerType)

```cangjie
public operator func ==(other: CPointerType): Bool
```

Function: Checks whether this CPointerType equals another CPointerType.

Parameters:

- other: CPointerType - The CPointerType to compare with.

Return Value:

- Bool - Returns true if the types are equal, false otherwise.

Example:

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

Output:

```text
op_eq_CPointerType: true
```

## class CStringType

```cangjie
public class CStringType <: BuiltinType & Equatable<CStringType> {}
```

Function: Represents the C string type in the type system. This type denotes a C-style null-terminated string for C interoperability. It is a singleton type for the built-in C string type.

Parent Types:

- [BuiltinType](#class-builtintype)
- Equatable\<[CStringType](#class-cstringtype)>

### static func get()

```cangjie
public static func get(): CStringType
```

Function: Gets the singleton instance of CStringType.

Return Value:

- [CStringType](#class-cstringtype) - CStringType instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let cStringType = CStringType.get()
    println(cStringType.toString())
}
```

Output:

```text
CString
```

### operator func ==(CStringType)

```cangjie
public operator func ==(_: CStringType): Bool
```

Function: Checks whether this CStringType equals another CStringType.

Parameters:

- _: CStringType - The other CStringType to compare with (unused; always returns true).

Return Value:

- Bool - Always returns true because all CStringType instances are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let cStringType1 = CStringType.get()
    let cStringType2 = CStringType.get()
    println("op_eq_CStringType: ${cStringType1 == cStringType2}")
}
```

Output:

```text
op_eq_CStringType: true
```

## class ClassLikeDef

```cangjie
public class ClassLikeDef <: CustomTypeDef & Equatable<ClassLikeDef> {}
```

Function: Definition of a **class or interface**.

Parent Types:

- [CustomTypeDef](#class-customtypedef)
- Equatable\<[ClassLikeDef](#class-classlikedef)>

### prop classType

```cangjie
public prop classType: ClassLikeType
```

Function: The [ClassLikeType](#class-classliketype) corresponding to this definition.

Type: [ClassLikeType](#class-classliketype)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    println("prop_classType: ${def.classType.classLikeDef == def}")
}
```

Output:

```text
prop_classType: true
```

### prop isAnnotation

```cangjie
public prop isAnnotation: Bool
```

Function: Whether this is an annotation class.

Type: Bool

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    println(def.isAnnotation)
}
```

Output:

```text
false
```

### prop superClass

```cangjie
public mut prop superClass: ?ClassLikeType
```

Function: Superclass; `None` if there is no superclass.

Type: ?[ClassLikeType](#class-classliketype)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    println("mut_prop_superClass: ${def.superClass.isNone()}")
}
```

Output:

```text
mut_prop_superClass: true
```

### func setAbstract(Bool)

```cangjie
public func setAbstract(enable: Bool): Unit
```

Function: Sets or clears the `abstract` flag.

Example:

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

Output:

```text
fn_setAbstract: true
```

### func setOpen(Bool)

```cangjie
public func setOpen(enable: Bool): Unit
```

Function: Sets or clears markers related to `open` (inheritability / virtual).

Example:

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

Output:

```text
fn_setOpen: true
```

### func setSealed(Bool)

```cangjie
public func setSealed(enable: Bool): Unit
```

Function: Sets or clears the `sealed` flag.

Example:

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

Output:

```text
fn_setSealed: true
```

### operator func ==(ClassLikeDef)

```cangjie
public operator func ==(other: ClassLikeDef): Bool
```

Function: Compares whether two class/interface definitions are the same.

Parameters:

- other: ClassLikeDef - The other definition.

Return Value:

- Bool - Whether they are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let def = pkg.addClass("C_m", "C", true)
    println("op_eq_ClassLikeDef: ${def == def}")
}
```

Output:

```text
op_eq_ClassLikeDef: true
```

## class ClassLikeType

```cangjie
public class ClassLikeType <: CustomType & Equatable<ClassLikeType> {}
```

Function: **Instantiated** type of a class or interface; `get(def, genericTypeParams)` caches a unique instance.

Parent Types:

- [CustomType](#class-customtype)
- Equatable\<[ClassLikeType](#class-classliketype)>

### prop classLikeDef

```cangjie
public prop classLikeDef: ClassLikeDef
```

Function: The corresponding [ClassLikeDef](#class-classlikedef).

Type: [ClassLikeDef](#class-classlikedef)

Example:

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

Output:

```text
C
```

### static func get(ClassLikeDef, Array\<Type>)

```cangjie
public static func get(def: ClassLikeDef, genericTypeParams: Array<Type>): ClassLikeType
```

Function: Gets or creates the cached unique instance from the definition and generic arguments.

Parameters:

- def: ClassLikeDef - Class/interface definition.
- genericTypeParams: Array\<Type> - Generic type arguments (empty array when not generic).

Return Value:

- [ClassLikeType](#class-classliketype) - Instantiated type.

Example:

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

Output:

```text
static_get: true
```

### operator func ==(ClassLikeType)

```cangjie
public operator func ==(other: ClassLikeType): Bool
```

Function: Compares whether two instantiated class/interface types are the same.

Parameters:

- other: ClassLikeType - The other type.

Return Value:

- Bool - Whether they are equal.

Example:

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

Output:

```text
op_eq_ClassLikeType: true
```

## class CustomType

```cangjie
sealed abstract class CustomType <: Type & Equatable<CustomType> {}
```

Function: Common base class for instantiated user-defined types (class/interface/struct/enum), holding `CustomTypeDef` and generic arguments.

Parent Types:

- [Type](#class-type)
- Equatable\<[CustomType](#class-customtype)>

Subclasses include [ClassLikeType](#class-classliketype), [StructType](#class-structtype), [EnumType](#class-enumtype), etc.

### prop allMemberVarNames

```cangjie
public prop allMemberVarNames: Array<String>
```

Function: All instance member names from the linearized superclass chain up through this type’s declarations.

Type: Array\<String>

Example:

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

Output:

```text
1
```

### prop def

```cangjie
public prop def: CustomTypeDef
```

Function: The corresponding type definition node.

Type: [CustomTypeDef](#class-customtypedef)

Example:

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

Output:

```text
S
```

### prop genericTypeArgs

```cangjie
public prop genericTypeArgs: Array<Type>
```

Function: Generic type argument list (empty when not generic).

Type: Array\<Type>

Example:

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

Output:

```text
0
```

### func getExtendDefs(ArrayList\<(Type, Type)>)

```cangjie
public func getExtendDefs(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ExtendDef>
```

Function: Returns extend definitions in `def.extends` whose `extendedType` matches the current type.

Return Value:

- Array<[ExtendDef](#class-extenddef)> - Applicable ExtendDef nodes from the owning CustomTypeDef.

Example:

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

Output:

```text
0
```

### func getExtendImplementedInterfaceTypes(ArrayList\<(Type, Type)>)

```cangjie
public func getExtendImplementedInterfaceTypes(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType>
```

Function: Collects interfaces implemented by `extend` blocks applicable to this instance (with generics substituted).

Return Value:

- Array<[ClassLikeType](#class-classliketype)> - Instantiated interface ClassLikeType nodes from matching extends.

Example:

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

Output:

```text
0
```

### func getImplementedInterfaceTypes(ArrayList\<(Type, Type)>)

```cangjie
public func getImplementedInterfaceTypes(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType>
```

Function: Union of interfaces implemented via `extend` and `implementedInterfaceTypes` on the definition (instantiated).

Return Value:

- Array<[ClassLikeType](#class-classliketype)> - Combined list of instantiated ClassLikeType interfaces.

Example:

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

Output:

```text
0
```

### func getInstantiatedMemberVarTypes()

```cangjie
public func getInstantiatedMemberVarTypes(): Array<Type>
```

Function: Member types aligned with `allMemberVarNames`, substituted with current generic arguments.

Return Value:

- Array\<[Type](#class-type)> - Sequence of instantiated member types.

Example:

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

Output:

```text
1
```

### func getMemberVarInstantiatedType(String)

```cangjie
public func getMemberVarInstantiatedType(name: String): Type
```

Function: Looks up the instantiated member type by name (inner-to-outer shadowing).

Parameters:

- name: String - Member source name.

Return Value:

- [Type](#class-type) - Member type.

Exception:

- Exception - Thrown when the member name is not found.

Example:

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

Output:

```text
Int32
```

### func getSuperTypesRecusively(ArrayList\<(Type, Type)>)

```cangjie
public func getSuperTypesRecusively(visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Array<ClassLikeType>
```

Function: Recursively collects superclass and interface parent types (instantiated).

Return Value:

- Array<[ClassLikeType](#class-classliketype)> - Every ClassLikeType ancestor or interface parent.

Example:

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

Output:

```text
0
```

### func toString()

```cangjie
public func toString(): String
```

Function: Compact string of internal kind, identity, and generic arguments.

Return Value:

- String - Textual form.

Example:

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

Output:

```text
fn_toString: true
```

### operator func ==(CustomType)

```cangjie
public operator func ==(other: CustomType): Bool
```

Function: Compares whether kind, definition, and generic arguments match.

Parameters:

- other: CustomType - The other instantiated custom type.

Return Value:

- Bool - Whether they are equal.

Example:

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

Output:

```text
op_eq_CustomType: true
```

## class CustomTypeDef

```cangjie
sealed abstract class CustomTypeDef <: Equatable<CustomTypeDef> & Hashable {}
```

Function: Common base class for **definitions** of class/interface/struct/enum/extension (combined with `Base`; includes attributes, CHIR annotations, debug locations, etc.).

Parent Types:

- Equatable\<[CustomTypeDef](#class-customtypedef)>
- Hashable

### prop identifier

```cangjie
public prop identifier: String
```

Function: Internal identifier; globally unique identifier.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("prop_identifier: ${d.identifier.size > 0}")
}
```

Output:

```text
prop_identifier: true
```

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

Function: Type name in source code (may be empty in `extend` scenarios; see source comments).

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.srcCodeName)
}
```

Output:

```text
X
```

### prop packageName

```cangjie
public prop packageName: String
```

Function: Name of the owning package.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.packageName)
}
```

Output:

```text
p
```

### prop ty

```cangjie
public prop ty: Type
```

Function: For ordinary definitions, the instantiated type; for [ExtendDef](#class-extenddef), `extendedType`.

Type: [Type](#class-type)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("prop_ty: ${d.ty.toString().size > 0}")
}
```

Output:

```text
prop_ty: true
```

### prop genericTypeParams

```cangjie
public prop genericTypeParams: Array<GenericType>
```

Function: Generic type parameter list; empty if not generic or type arguments cannot be inferred.

Type: Array\<[GenericType](#class-generictype)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.genericTypeParams.size}")
}
```

Output:

```text
0
```

### prop genericDecl

```cangjie
public mut prop genericDecl: ?CustomTypeDef
```

Function: Generic template definition paired with the current **monomorphic** definition; `set` validates kind, `srcCodeName`, and generic constraints (see source assertions).

Type: ?CustomTypeDef

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("mut_prop_genericDecl: ${d.genericDecl.isNone()}")
}
```

Output:

```text
mut_prop_genericDecl: true
```

### prop instanceVars

```cangjie
public prop instanceVars: Array<MemberVar>
```

Function: Instance member variable list (declaration order).

Type: Array\<[MemberVar](#class-membervar)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.instanceVars.size}")
}
```

Output:

```text
0
```

### prop extends

```cangjie
public mut prop extends: Array<ExtendDef>
```

Function: `extend` definitions nested under this type.

Type: Array\<[ExtendDef](#class-extenddef)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.extends.size}")
}
```

Output:

```text
0
```

### prop implementedInterfaceTypes

```cangjie
public mut prop implementedInterfaceTypes: Array<ClassLikeType>
```

Function: List of directly implemented interface types.

Type: Array\<[ClassLikeType](#class-classliketype)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.implementedInterfaceTypes.size}")
}
```

Output:

```text
0
```

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

Function: Annotation instance list; getter returns the current instances, setter replaces the entire list.

Type: Array\<[CustomAnnoInstance](#class-customannoinstance)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let c = pkg.addClass("C_m", "C", true)
    println("${c.customAnnoInstances.size}")
}
```

Output:

```text
0
```

### prop methods

```cangjie
public prop methods: Array<Function>
```

Function: Methods declared on this custom type.

Type: Array\<[Function](#class-function)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let c = pkg.addClass("C_m", "C", true)
    println("${c.methods.size}")
}
```

Output:

```text
0
```

### prop staticVars

```cangjie
public prop staticVars: Array<GlobalVar>
```

Function: Static variables declared on this custom type.

Type: Array\<[GlobalVar](#class-globalvar)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let c = pkg.addClass("C_m", "C", true)
    println("${c.staticVars.size}")
}
```

Output:

```text
0
```

### func appendMethod(Function)

```cangjie
public func appendMethod(method: Function): Unit
```

Function: Appends a method to this type definition's method list.

Parameters:

- method: [Function](#class-function) - The method to append.

### func appendStaticVar(GlobalVar)

```cangjie
public func appendStaticVar(staticVar: GlobalVar): Unit
```

Function: Appends a static variable to this type definition, automatically marking it as a static member.

Parameters:

- staticVar: [GlobalVar](#class-globalvar) - The static variable to append.

### func setPublic()

```cangjie
public func setPublic(): Unit
```

Function: Marked as `public` visibility.

Example:

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

Output:

```text
fn_setPublic: true
```

### func setPrivate()

```cangjie
public func setPrivate(): Unit
```

Function: Marked as `private`.

Example:

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

Output:

```text
fn_setPrivate: true
```

### func setProtected()

```cangjie
public func setProtected(): Unit
```

Function: Marked as `protected`.

Example:

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

Output:

```text
fn_setProtected: true
```

### func setInternal()

```cangjie
public func setInternal(): Unit
```

Function: Marked as `internal`.

Example:

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

Output:

```text
fn_setInternal: true
```

### func isImported()

```cangjie
public func isImported(): Bool
```

Function: Whether this definition is imported from another package.

Return Value:

- Bool - true if the Imported attribute is set, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isImported())
}
```

Output:

```text
false
```

### func isPublic()

```cangjie
public func isPublic(): Bool
```

Function: Whether it has the `public` attribute.

Return Value:

- Bool - true if the Public attribute is set, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isPublic())
}
```

Output:

```text
false
```

### func isPrivate()

```cangjie
public func isPrivate(): Bool
```

Function: Whether it has the `private` attribute.

Return Value:

- Bool - true if the Private attribute is set, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isPrivate())
}
```

Output:

```text
false
```

### func isInternal()

```cangjie
public func isInternal(): Bool
```

Function: Whether it has the `internal` attribute.

Return Value:

- Bool - true if the Internal attribute is set, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isInternal())
}
```

Output:

```text
false
```

### func isProtected()

```cangjie
public func isProtected(): Bool
```

Function: Whether it has the `protected` attribute.

Return Value:

- Bool - true if the Protected attribute is set, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isProtected())
}
```

Output:

```text
false
```

### func isAbstract()

```cangjie
public func isAbstract(): Bool
```

Function: Whether it is `abstract`.

Return Value:

- Bool - true if the Abstract attribute is set, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isAbstract())
}
```

Output:

```text
false
```

### func isOpen()

```cangjie
public func isOpen(): Bool
```

Function: Whether it can be inherited/implemented (`virtual` or `abstract`).

Return Value:

- Bool - true if the Virtual or Abstract attribute is set, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isOpen())
}
```

Output:

```text
false
```

### func isSealed()

```cangjie
public func isSealed(): Bool
```

Function: Whether it is `sealed`.

Return Value:

- Bool - true if the Sealed attribute is set, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isSealed())
}
```

Output:

```text
false
```

### func isGeneric()

```cangjie
public func isGeneric(): Bool
```

Function: Whether it is a generic definition.

Return Value:

- Bool - true if the Generic attribute is set, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isGeneric())
}
```

Output:

```text
false
```

### func isClassLike()

```cangjie
public func isClassLike(): Bool
```

Function: Whether the kind is class/interface.

Return Value:

- Bool - true if the kind is ClassLike, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("fn_isClassLike: ${d.isClassLike()}")
}
```

Output:

```text
fn_isClassLike: true
```

### func isClass()

```cangjie
public func isClass(): Bool
```

Function: Whether it is a class (not an interface).

Return Value:

- Bool - true if this is a class, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("fn_isClass: ${d.isClass()}")
}
```

Output:

```text
fn_isClass: true
```

### func isInterface()

```cangjie
public func isInterface(): Bool
```

Function: Whether it is an interface.

Return Value:

- Bool - true if this is an interface, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isInterface())
}
```

Output:

```text
false
```

### func isEnum()

```cangjie
public func isEnum(): Bool
```

Function: Whether it is an enum definition.

Return Value:

- Bool - true if the kind is Enum, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isEnum())
}
```

Output:

```text
false
```

### func isExtend()

```cangjie
public func isExtend(): Bool
```

Function: Whether it is an extend definition.

Return Value:

- Bool - true if the kind is Extend, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isExtend())
}
```

Output:

```text
false
```

### func isStruct()

```cangjie
public func isStruct(): Bool
```

Function: Whether it is a struct definition.

Return Value:

- Bool - true if the kind is Struct, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println(d.isStruct())
}
```

Output:

```text
false
```

### func hashCode()

```cangjie
public func hashCode(): Int64
```

Function: Hash code of the definition.

Return Value:

- Int64 - Hash value.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("fn_hashCode: ${d.hashCode() != 0}")
}
```

Output:

```text
fn_hashCode: true
```

### operator func ==(CustomTypeDef)

```cangjie
public operator func ==(other: CustomTypeDef): Bool
```

Function: Compares by kind, identifier, source name, and package name.

Return Value:

- Bool - true if the definitions are equal, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("op_eq_CustomTypeDef: ${d == d}")
}
```

Output:

```text
op_eq_CustomTypeDef: true
```

### func toString()

```cangjie
public open func toString(): String
```

Function: Multi-line dump of class/interface/enum shape (including attributes, members, `extend` list).

Return Value:

- String - Readable dump of the definition.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("fn_toString: ${d.toString().size > 0}")
}
```

Output:

```text
fn_toString: true
```

### func dump()

```cangjie
public func dump(): Unit
```

Function: Prints `toString()` to standard output.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    d.dump()
}
```

Output:

```text
[pluginAdded]class @X_m { // srcCodeName: X, packageName: p
}
```

### func appendInstanceMemberVar(String, Type)

```cangjie
public func appendInstanceMemberVar(name: String, ty: Type): MemberVar
```

Function: **Appends** an instance member variable (name and type) to the current type definition and returns the corresponding [MemberVar](#class-membervar). Order in `instanceVars` matches call order; use after `Package.addClass` / `addStruct` for plugins or tests attaching CHIR members.

Return Value:

- [MemberVar](#class-membervar) - Newly created member variable node.

Example:

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

Output:

```text
f
```

### func getSuperTypesRecusively()

```cangjie
public func getSuperTypesRecusively(): Array<ClassLikeType>
```

Function: Recursively collects all superclasses of this definition, including interfaces implemented by superclasses via extension, but not interfaces implemented by this definition via extension.

Return Value:

- Array\<[ClassLikeType](#class-classliketype)> - Collected parent types; **order is not guaranteed**.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let d = pkg.addClass("X_m", "X", true)
    println("${d.getSuperTypesRecusively().size}")
}
```

Output:

```text
0
```

## class DebugLocation

```cangjie
public class DebugLocation <: ToString {}
```

Function: **Source range** (start/end `Position` and file path) for debugging and printing.

Parent Types:

- ToString

### prop start

```cangjie
public prop start: Position
```

Function: Range start (inclusive), paired with [struct Position](chir_package_structs.md#struct-position).

Type: [Position](chir_package_structs.md#struct-position)

Example:

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

Output:

```text
0
```

### prop end

```cangjie
public prop end: Position
```

Function: Range end.

Type: [Position](chir_package_structs.md#struct-position)

Example:

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

Output:

```text
0
```

### prop filePath

```cangjie
public prop filePath: Path
```

Function: Source file path (absolute or project-relative; see `std.fs.Path`).

Type: Path

Example:

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

Output:

```text
prop_filePath: true
```

### func isValid()

```cangjie
public func isValid(): Bool
```

Function: Returns `true` when both `start` and `end` are valid and `filePath` is non-empty.

Return Value:

- Bool - Whether this is a usable debug range.

Example:

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

Output:

```text
false
```

### func toString()

```cangjie
public func toString(): String
```

Function: Returns empty string when invalid; otherwise prints file name, compact `start`/`end`, and optional scope chain (see source).

Return Value:

- String - Human-readable location description.

Example:

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

Output:

```text
0
```

## class EnumCtorInfo

```cangjie
public class EnumCtorInfo <: ToString {}
```

Function: One **constructor/variant** of an enum (name, internal id, function type, annotations).

Parent Types:

- ToString

### prop identifier

```cangjie
public prop identifier: String
```

Function: Internal identifier; globally unique identifier.

Type: String

Example:

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

Output:

```text
prop_identifier: true
```

### prop funcType

```cangjie
public prop funcType: FuncType
```

Function: The [FuncType](#class-functype) for this variant’s parameter types and return type (return type is the owning enum type).

Type: [FuncType](#class-functype)

Example:

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

Output:

```text
0
```

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

Function: Constructor/variant name in source code.

Type: String

Example:

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

Output:

```text
A
```

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

Function: List of annotation instances attached to this enum constructor; getter returns the current list, setter replaces the whole list.

Type: Array\<[CustomAnnoInstance](#class-customannoinstance)>

Example:

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

Output:

```text
1
```

### func toString()

```cangjie
public func toString(): String
```

Function: Short description like `VariantName(paramTypes...)` (see source).

Return Value:

- String - Constructor text form.

Example:

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

Output:

```text
A
```

## class EnumDef

```cangjie
public class EnumDef <: CustomTypeDef & Equatable<EnumDef> {}
```

Function: **Enum** definition; includes exhaustive flag, constructor list, etc.

Parent Types:

- [CustomTypeDef](#class-customtypedef)
- Equatable\<[EnumDef](#class-enumdef)>

### prop isExhaustive

```cangjie
public prop isExhaustive: Bool
```

Function: Whether this is an **exhaustive** enum (opposite of internal `nonExhaustive` flag).

Type: Bool

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    println("prop_isExhaustive: ${e.isExhaustive}")
}
```

Output:

```text
prop_isExhaustive: true
```

### prop constructors

```cangjie
public prop constructors: Array<EnumCtorInfo>
```

Function: All enum constructors/variants in declaration order.

Type: Array\<[EnumCtorInfo](#class-enumctorinfo)>

Example:

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

Output:

```text
1
```

### prop enumType

```cangjie
public prop enumType: EnumType
```

Function: The instantiated [EnumType](#class-enumtype) corresponding to this definition.

Type: [EnumType](#class-enumtype)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    println("prop_enumType: ${e.enumType.enumDef == e}")
}
```

Output:

```text
prop_enumType: true
```

### func appendEnumCtorInfo(String, String, Array\<Type>)

```cangjie
public func appendEnumCtorInfo(identifier: String, name: String, argTypes!: Array<Type> = Array<Type>()): EnumCtorInfo
```

Function: Appends an enum variant; zero-argument variants may omit `argTypes` or pass an empty array.

Parameters:

- identifier: String - Globally unique identifier.
- name: String - Variant name in source.
- argTypes!: Array\<Type> - Parameter type list.

Return Value:

- [EnumCtorInfo](#class-enumctorinfo) - Newly created constructor info.

Example:

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

Output:

```text
A
```

### operator func ==(EnumDef)

```cangjie
public operator func ==(other: EnumDef): Bool
```

Function: Compares whether two enum definitions are the same by definition id.

Parameters:

- other: EnumDef - The other enum definition.

Return Value:

- Bool - Whether they are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let e = pkg.addEnum("E_m", "E", true)
    println("op_eq_EnumDef: ${e == e}")
}
```

Output:

```text
op_eq_EnumDef: true
```

## class EnumType

```cangjie
public class EnumType <: CustomType & Equatable<EnumType> {}
```

Function: Instantiated type of the enum; `get(def, genericTypeParams)` caches a unique instance.

Parent Types:

- [CustomType](#class-customtype)
- Equatable\<[EnumType](#class-enumtype)>

### prop enumDef

```cangjie
public prop enumDef: EnumDef
```

Function: The corresponding [EnumDef](#class-enumdef).

Type: [EnumDef](#class-enumdef)

Example:

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

Output:

```text
E
```

### static func get(EnumDef, Array\<Type>)

```cangjie
public static func get(def: EnumDef, genericTypeParams: Array<Type>): EnumType
```

Function: Gets or creates the cached instance from the enum definition and generic arguments.

Parameters:

- def: EnumDef - Enum definition.
- genericTypeParams: Array\<Type> - Generic type arguments.

Return Value:

- [EnumType](#class-enumtype) - Instantiated enum type.

Example:

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

Output:

```text
E
```

### operator func ==(EnumType)

```cangjie
public operator func ==(other: EnumType): Bool
```

Function: Compares whether two instantiated enum types are the same.

Parameters:

- other: EnumType - The other enum type.

Return Value:

- Bool - Whether they are equal.

Example:

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

Output:

```text
op_eq_EnumType: true
```

## class ExtendDef

```cangjie
public class ExtendDef <: CustomTypeDef {}
```

Function: **Extension (extend)** definition: adds implementation for a type, with `extendedType` and generic parameters.

Parent Types:

- [CustomTypeDef](#class-customtypedef)

### prop extendedType

```cangjie
public prop extendedType: Type
```

Function: The type being extended (`T` in `extend T { ... }`).

Type: [Type](#class-type)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let ext = pkg.addExtend("ext_m", IntType.getInt32())
    println(ext.extendedType.toString())
}
```

Output:

```text
Int32
```

## class FloatType

```cangjie
public class FloatType <: NumericType & Equatable<FloatType> {}
```

Function: Represents a floating-point type in the type system. This class represents Float16, Float32, and Float64.

Parent Types:

- [NumericType](#class-numerictype)
- Equatable\<[FloatType](#class-floattype)>

### static func getFloat16()

```cangjie
public static func getFloat16(): FloatType
```

Function: Gets the Float16 type instance.

Return Value:

- [FloatType](#class-floattype) - Float16 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let float16Type = FloatType.getFloat16()
    println("Float16 type: ${float16Type.toString()}")
}
```

Output:

```text
Float16 type: Float16
```

### static func getFloat32()

```cangjie
public static func getFloat32(): FloatType
```

Function: Gets the Float32 type instance.

Return Value:

- [FloatType](#class-floattype) - Float32 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let float32Type = FloatType.getFloat32()
    println("Float32 type: ${float32Type.toString()}")
}
```

Output:

```text
Float32 type: Float32
```

### static func getFloat64()

```cangjie
public static func getFloat64(): FloatType
```

Function: Gets the Float64 type instance.

Return Value:

- [FloatType](#class-floattype) - Float64 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let float64Type = FloatType.getFloat64()
    println("Float64 type: ${float64Type.toString()}")
}
```

Output:

```text
Float64 type: Float64
```

### operator func ==(FloatType)

```cangjie
public operator func ==(other: FloatType): Bool
```

Function: Checks whether this FloatType equals another FloatType.

Parameters:

- other: FloatType - The FloatType to compare with.

Return Value:

- Bool - Returns true if the types are equal, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let float32Type1 = FloatType.getFloat32()
    let float32Type2 = FloatType.getFloat32()
    let float64Type = FloatType.getFloat64()
    println("Two Float32 instances are equal: ${float32Type1 == float32Type2}")
    println("Float32 and Float64 are equal: ${float32Type1 == float64Type}")
}
```

Output:

```text
Two Float32 instances are equal: true
Float32 and Float64 are equal: false
```

## class FuncType

```cangjie
public class FuncType <: Type & Equatable<FuncType> {}
```

Function: Function type (parameter type list + return type), optional varargs and C function flag; cached by signature.

Parent Types:

- [Type](#class-type)
- Equatable\<[FuncType](#class-functype)>

### prop hasVarArg

```cangjie
public prop hasVarArg: Bool
```

Function: Whether this is a varargs function type.

Type: Bool

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println(f.hasVarArg)
}
```

Output:

```text
false
```

### prop isCFunc

```cangjie
public prop isCFunc: Bool
```

Function: Whether this denotes a C function type (affects `toString()` prefix `CFunc<...>`).

Type: Bool

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println(f.isCFunc)
}
```

Output:

```text
false
```

### prop paramTypes

```cangjie
public prop paramTypes: Array<Type>
```

Function: Array of formal parameter types.

Type: Array\<Type>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println("${f.paramTypes.size}")
}
```

Output:

```text
1
```

### prop returnType

```cangjie
public prop returnType: Type
```

Function: Return type.

Type: Type

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println(f.returnType.toString())
}
```

Output:

```text
Int32
```

### static func get(Array\<Type>, Type, Bool, Bool)

```cangjie
public static func get(paramTypes: Array<Type>, retType: Type, varArg!: Bool = false, cFunc!: Bool = false): FuncType
```

Function: Gets or creates the uniquely cached instance from parameter list, return type, and varargs/C flag.

Parameters:

- paramTypes: Array\<Type> - Formal parameter type sequence.
- retType: Type - Return type.
- varArg! - Whether this is a varargs function type; default `false`.
- cFunc! - Whether this is in `CFunc<...>` form; default `false`.

Return Value:

- [FuncType](#class-functype) - Function type instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let i32 = IntType.getInt32()
    let f = FuncType.get([i32], i32)
    println(f.toString())
}
```

Output:

```text
(Int32) -> Int32
```

### func toString()

```cangjie
public func toString(): String
```

Function: String like `(T1, T2) -> R` or `CFunc<(T1)-> R>` (see source).

Return Value:

- String - Function type text.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let u = IntType.getUInt32()
    let f = FuncType.get([u], UnitType.get())
    println(f.toString())
}
```

Output:

```text
(UInt32) -> Unit
```

### operator func ==(FuncType)

```cangjie
public operator func ==(other: FuncType): Bool
```

Function: Compares whether signature, `varArg`, and `cFunc` match.

Parameters:

- other: FuncType - The other function type.

Return Value:

- Bool - Whether they are equal.

Example:

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

Output:

```text
op_eq_FuncType: true
```

## class GenericType

```cangjie
public class GenericType <: Type & Equatable<GenericType> {}
```

Function: Generic **type parameter** (e.g. `T`), optional `upperBounds`; cached by internal `identifier`.

Parent Types:

- [Type](#class-type)
- Equatable\<[GenericType](#class-generictype)>

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

Function: Generic parameter name in source (e.g. `T`).

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = GenericType.get("g:T", "T")
    println(t.srcCodeName)
}
```

Output:

```text
T
```

### prop upperBounds

```cangjie
public mut prop upperBounds: Array<Type>
```

Function: Upper bound type list; assignment rejects **value type** upper bounds (see source validation).

Type: Array\<Type>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = GenericType.get("g:T", "T")
    println("${t.upperBounds.size}")
}
```

Output:

```text
0
```

### static func get(String, String)

```cangjie
public static func get(identifier: String, srcCodeName: String): GenericType
```

Function: Gets or creates the generic parameter type cached by internal `identifier` (e.g. `T`).

Parameters:

- identifier: String - Internal unique key (for mangling).
- srcCodeName: String - Parameter name in source.

Return Value:

- [GenericType](#class-generictype) - Generic parameter type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = GenericType.get("g:T", "T")
    println("static_get: ${t.toString().size > 0}")
}
```

Output:

```text
static_get: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: Internal debug string (includes kind and identifier).

Return Value:

- String - Textual form.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = GenericType.get("g:U", "U")
    println("fn_toString: ${t.toString().size > 0}")
}
```

Output:

```text
fn_toString: true
```

### operator func ==(GenericType)

```cangjie
public operator func ==(other: GenericType): Bool
```

Function: Compares whether two generic parameter nodes are the same.

Parameters:

- other: GenericType - The other generic parameter.

Return Value:

- Bool - Whether they are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t1 = GenericType.get("g:T", "T")
    let t2 = GenericType.get("g:T", "T")
    println("op_eq_GenericType: ${t1 == t2}")
}
```

Output:

```text
op_eq_GenericType: true
```

## class IntType

```cangjie
public class IntType <: NumericType & Equatable<IntType> {}
```

Function: Represents an integer type in the type system. This class represents signed and unsigned integer types of various sizes.

Parent Types:

- [NumericType](#class-numerictype)
- Equatable\<[IntType](#class-inttype)>

### static func getInt16()

```cangjie
public static func getInt16(): IntType
```

Function: Gets the Int16 type instance.

Return Value:

- [IntType](#class-inttype) - Int16 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int16Type = IntType.getInt16()
    println("Int16 type: ${int16Type.toString()}")
}
```

Output:

```text
Int16 type: Int16
```

### static func getInt32()

```cangjie
public static func getInt32(): IntType
```

Function: Gets the Int32 type instance.

Return Value:

- [IntType](#class-inttype) - Int32 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int32Type = IntType.getInt32()
    println("Int32 type: ${int32Type.toString()}")
}
```

Output:

```text
Int32 type: Int32
```

### static func getInt64()

```cangjie
public static func getInt64(): IntType
```

Function: Gets the Int64 type instance.

Return Value:

- [IntType](#class-inttype) - Int64 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int64Type = IntType.getInt64()
    println("Int64 type: ${int64Type.toString()}")
}
```

Output:

```text
Int64 type: Int64
```

### static func getInt8()

```cangjie
public static func getInt8(): IntType
```

Function: Gets the Int8 type instance.

Return Value:

- [IntType](#class-inttype) - Int8 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int8Type = IntType.getInt8()
    println("Int8 type: ${int8Type.toString()}")
}
```

Output:

```text
Int8 type: Int8
```

### static func getIntNative()

```cangjie
public static func getIntNative(): IntType
```

Function: Gets the IntNative type instance.

Return Value:

- [IntType](#class-inttype) - IntNative type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intNativeType = IntType.getIntNative()
    println("IntNative type: ${intNativeType.toString()}")
}
```

Output:

```text
IntNative type: IntNative
```

### static func getUInt16()

```cangjie
public static func getUInt16(): IntType
```

Function: Gets the UInt16 type instance.

Return Value:

- [IntType](#class-inttype) - UInt16 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uint16Type = IntType.getUInt16()
    println("UInt16 type: ${uint16Type.toString()}")
}
```

Output:

```text
UInt16 type: UInt16
```

### static func getUInt32()

```cangjie
public static func getUInt32(): IntType
```

Function: Gets the UInt32 type instance.

Return Value:

- [IntType](#class-inttype) - UInt32 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uint32Type = IntType.getUInt32()
    println("UInt32 type: ${uint32Type.toString()}")
}
```

Output:

```text
UInt32 type: UInt32
```

### static func getUInt64()

```cangjie
public static func getUInt64(): IntType
```

Function: Gets the UInt64 type instance.

Return Value:

- [IntType](#class-inttype) - UInt64 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uint64Type = IntType.getUInt64()
    println("UInt64 type: ${uint64Type.toString()}")
}
```

Output:

```text
UInt64 type: UInt64
```

### static func getUInt8()

```cangjie
public static func getUInt8(): IntType
```

Function: Gets the UInt8 type instance.

Return Value:

- [IntType](#class-inttype) - UInt8 type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uint8Type = IntType.getUInt8()
    println("UInt8 type: ${uint8Type.toString()}")
}
```

Output:

```text
UInt8 type: UInt8
```

### static func getUIntNative()

```cangjie
public static func getUIntNative(): IntType
```

Function: Gets the UIntNative type instance.

Return Value:

- [IntType](#class-inttype) - UIntNative type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let uintNativeType = IntType.getUIntNative()
    println("UIntNative type: ${uintNativeType.toString()}")
}
```

Output:

```text
UIntNative type: UIntNative
```

### operator func ==(IntType)

```cangjie
public operator func ==(other: IntType): Bool
```

Function: Checks whether this IntType equals another IntType.

Parameters:

- other: IntType - The IntType to compare with.

Return Value:

- Bool - Returns true if the types are equal, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int32Type1 = IntType.getInt32()
    let int32Type2 = IntType.getInt32()
    let int64Type = IntType.getInt64()
    println("Two Int32 instances are equal: ${int32Type1 == int32Type2}")
    println("Int32 and Int64 are equal: ${int32Type1 == int64Type}")
}
```

Output:

```text
Two Int32 instances are equal: true
Int32 and Int64 are equal: false
```

### func isSigned()

```cangjie
public func isSigned(): Bool
```

Function: Checks whether this integer type is signed.

Return Value:

- Bool - Returns true if the type is signed, false if unsigned.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let int32Type = IntType.getInt32()
    let uint32Type = IntType.getUInt32()
    println("Int32 is signed: ${int32Type.isSigned()}")
    println("UInt32 is signed: ${uint32Type.isSigned()}")
}
```

Output:

```text
Int32 is signed: true
UInt32 is signed: false
```

## class MemberVar

```cangjie
public class MemberVar <: ToString {}
```

Function: Describes an **instance member variable** on a custom type (name, type, debug location, annotations, access modifiers, etc.).

Parent Types:

- ToString

### prop name

```cangjie
public prop name: String
```

Function: Member source name.

Type: String

Example:

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

Output:

```text
x
```

### prop ty

```cangjie
public prop ty: Type
```

Function: Member type.

Type: [Type](#class-type)

Example:

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

Output:

```text
Int32
```

### prop location

```cangjie
public prop location: DebugLocation
```

Function: Source location; may be an invalid range when unset (see [DebugLocation](#class-debuglocation)).

Type: [DebugLocation](#class-debuglocation)

Example:

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

Output:

```text
false
```

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

Function: List of annotation instances on the member; getter returns the current list, setter replaces the whole list.

Type: Array\<[CustomAnnoInstance](#class-customannoinstance)>

Example:

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

Output:

```text
0
```

### prop outerDef

```cangjie
public prop outerDef: CustomTypeDef
```

Function: The outer type definition that contains this member.

Type: [CustomTypeDef](#class-customtypedef)

Example:

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

Output:

```text
S
```

### func setReadOnly(Bool)

```cangjie
public func setReadOnly(enable: Bool): Unit
```

Function: Sets or clears the read-only (`let`) flag.

Example:

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

Output:

```text
fn_setReadOnly: true
```

### func setInternal()

```cangjie
public func setInternal(): Unit
```

Function: Marks the member as `internal`.

Example:

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

Output:

```text
fn_setInternal: true
```

### func setPublic()

```cangjie
public func setPublic(): Unit
```

Function: Marks the member as `public`.

Example:

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

Output:

```text
fn_setPublic: true
```

### func setPrivate()

```cangjie
public func setPrivate(): Unit
```

Function: Marks the member as `private`.

Example:

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

Output:

```text
fn_setPrivate: true
```

### func setProtected()

```cangjie
public func setProtected(): Unit
```

Function: Marks the member as `protected`.

Example:

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

Output:

```text
fn_setProtected: true
```

### func isReadOnly()

```cangjie
public func isReadOnly(): Bool
```

Function: Whether this is a read-only member.

Return Value:

- Bool - true if the READONLY attribute is set, false otherwise.

Example:

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

Output:

```text
false
```

### func isInternal()

```cangjie
public func isInternal(): Bool
```

Function: Whether this is `internal`.

Return Value:

- Bool - true if the INTERNAL attribute is set, false otherwise.

Example:

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

Output:

```text
false
```

### func isPublic()

```cangjie
public func isPublic(): Bool
```

Function: Whether this is `public`.

Return Value:

- Bool - true if the PUBLIC attribute is set, false otherwise.

Example:

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

Output:

```text
false
```

### func isPrivate()

```cangjie
public func isPrivate(): Bool
```

Function: Whether this is `private`.

Return Value:

- Bool - true if the PRIVATE attribute is set, false otherwise.

Example:

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

Output:

```text
false
```

### func isProtected()

```cangjie
public func isProtected(): Bool
```

Function: Whether this is `protected`.

Return Value:

- Bool - true if the PROTECTED attribute is set, false otherwise.

Example:

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

Output:

```text
false
```

### func toString()

```cangjie
public func toString(): String
```

Function: Attribute prefix + `let`/`var`, name, type, and location comments.

Return Value:

- String - Single-line member description.

Example:

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

Output:

```text
fn_toString: true
```

### func dump()

```cangjie
public func dump(): Unit
```

Function: Prints `toString()`.

Example:

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

Output:

```text
[pluginAdded]var x: Int32
```

## class NothingType

```cangjie
public class NothingType <: BuiltinType & Equatable<NothingType> {}
```

Function: Represents the Nothing type (bottom type) in the type system. Used for expressions that never return.

Parent Types:

- [BuiltinType](#class-builtintype)
- Equatable\<[NothingType](#class-nothingtype)>

### static func get()

```cangjie
public static func get(): NothingType
```

Function: Gets the singleton instance of NothingType.

Return Value:

- [NothingType](#class-nothingtype) - NothingType instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let nothingType = NothingType.get()
    println("Nothing type: ${nothingType.toString()}")
}
```

Output:

```text
Nothing type: Nothing
```

### operator func ==(NothingType)

```cangjie
public operator func ==(_: NothingType): Bool
```

Function: Checks whether this NothingType equals another NothingType.

Parameters:

- _: NothingType - The other NothingType to compare with (unused; always returns true).

Return Value:

- Bool - Always returns true because all NothingType instances are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let nothingType1 = NothingType.get()
    let nothingType2 = NothingType.get()
    println("Two NothingType instances are equal: ${nothingType1 == nothingType2}")
}
```

Output:

```text
Two NothingType instances are equal: true
```

## class NumericType

```cangjie
sealed abstract class NumericType <: BuiltinType & Equatable<NumericType> {}
```

Function: Abstract base class for numeric types. Represents numeric types, including integer and floating-point types.

Parent Types:

- [BuiltinType](#class-builtintype)
- Equatable\<[NumericType](#class-numerictype)>

### operator func ==(NumericType)

```cangjie
public operator func ==(other: NumericType): Bool
```

Function: Checks whether this numeric type equals another numeric type.

Parameters:

- other: NumericType - The numeric type to compare with.

Return Value:

- Bool - Returns true if the types are equal, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType1 = IntType.getInt32()
    let intType2 = IntType.getInt32()
    let floatType = FloatType.getFloat32()
    println("Two Int32 instances are equal: ${intType1 == intType2}")
    println("Int32 and Float32 are equal: ${intType1 == floatType}")
}
```

Output:

```text
Two Int32 instances are equal: true
Int32 and Float32 are equal: false
```

## class Package

```cangjie
public class Package <: ToString {
    public init(name: String, accessLevel: AccessLevel)
}
```

Function: Represents a **CHIR package**: name, access level, imports, and type definitions declared in this package.

Parent Types:

- ToString

### prop name

```cangjie
public prop name: String
```

Function: Logical package name.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    println(pkg.name)
}
```

Output:

```text
demo
```

### prop accessLevel

```cangjie
public prop accessLevel: AccessLevel
```

Function: Package access level.

Type: [AccessLevel](chir_package_enums.md#enum-accesslevel)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    println("prop_accessLevel: ${pkg.accessLevel == AccessLevel.Public}")
}
```

Output:

```text
prop_accessLevel: true
```

### prop importedClassDefs

```cangjie
public prop importedClassDefs: Array<ClassLikeDef>
```

Function: Snapshot of class/interface definitions imported from other packages.

Type: Array\<[ClassLikeDef](#class-classlikedef)>

### prop importedEnumDefs

```cangjie
public prop importedEnumDefs: Array<EnumDef>
```

Function: Imported enum definitions.

Type: Array\<[EnumDef](#class-enumdef)>

### prop importedStructDefs

```cangjie
public prop importedStructDefs: Array<StructDef>
```

Function: Imported struct definitions.

Type: Array\<[StructDef](#class-structdef)>

### prop importedExtendDefs

```cangjie
public prop importedExtendDefs: Array<ExtendDef>
```

Function: Imported extend definitions.

Type: Array\<[ExtendDef](#class-extenddef)>

### prop classDefs

```cangjie
public prop classDefs: Array<ClassLikeDef>
```

Function: Class/interface definitions declared in this package.

Type: Array\<[ClassLikeDef](#class-classlikedef)>

### prop enumDefs

```cangjie
public prop enumDefs: Array<EnumDef>
```

Function: Enum definitions declared in this package.

Type: Array\<[EnumDef](#class-enumdef)>

### prop structDefs

```cangjie
public prop structDefs: Array<StructDef>
```

Function: Struct definitions declared in this package.

Type: Array\<[StructDef](#class-structdef)>

### prop extendDefs

```cangjie
public prop extendDefs: Array<ExtendDef>
```

Function: Extend definitions declared in this package.

Type: Array\<[ExtendDef](#class-extenddef)>

### prop globalVars

```cangjie
public prop globalVars: Array<GlobalVar>
```

Function: List of global variable definitions declared in this package.

Type: Array\<[GlobalVar](#class-globalvar)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    println("${pkg.globalVars.size}")
}
```

Output:

```text
0
```

### prop functions

```cangjie
public prop functions: Array<Function>
```

Function: List of function definitions declared in this package.

Type: Array\<[Function](#class-function)>

### prop allCustomTypeDefs

```cangjie
public prop allCustomTypeDefs: Array<CustomTypeDef>
```

Function: All custom type definitions in this package (including imported and locally declared classes, enums, extends, structs).

Type: Array\<[CustomTypeDef](#class-customtypedef)>

### prop packageInitFunc

```cangjie
public prop packageInitFunc: ?Function
```

Function: Package initialization function; `None` when not set.

Type: ?[Function](#class-function)

### prop packageLiteralInitFunc

```cangjie
public prop packageLiteralInitFunc: ?Function
```

Function: Package literal initialization function; `None` when not set.

Type: ?[Function](#class-function)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    println("prop_packageLiteralInitFunc: ${pkg.packageLiteralInitFunc.isNone()}")
}
```

Output:

```text
prop_packageLiteralInitFunc: true
```

### init(String, AccessLevel)

```cangjie
public init(name: String, accessLevel: AccessLevel)
```

Function: Creates an empty package with the given logical name and [AccessLevel](chir_package_enums.md#enum-accesslevel).

Parameters:

- name: String - Package name.
- accessLevel: AccessLevel - Package access level.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    println(pkg.name)
}
```

Output:

```text
demo
```

### func addClass(String, String, Bool, Array\<GenericType>)

```cangjie
public func addClass(identifier: String, srcCodeName: String, isClass: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ClassLikeDef
```

Function: Creates a new class or interface definition in this package and adds it to `classDefs`.

Return Value:

- [ClassLikeDef](#class-classlikedef) - New definition.

Example:

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

Output:

```text
1
C
```

### func addImportedClass(String, String, String, Bool, Array\<GenericType>)

```cangjie
public func addImportedClass(identifier: String, srcCodeName: String, packageName: String, isClass: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ClassLikeDef
```

Function: Registers an imported class/interface definition (with `Imported` flag).

Return Value:

- [ClassLikeDef](#class-classlikedef) - New definition.

Example:

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

Output:

```text
fn_addImportedClass importedCount: 1
fn_addImportedClass isImported: true
```

### func addStruct(String, String, Array\<GenericType>)

```cangjie
public func addStruct(identifier: String, srcCodeName: String, genericTypeParams!: Array<GenericType> = Array<GenericType>()): StructDef
```

Function: Creates a new struct definition in this package.

Return Value:

- [StructDef](#class-structdef) - New definition.

Example:

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

Output:

```text
1
S
```

### func addImportedStruct(String, String, String, Array\<GenericType>)

```cangjie
public func addImportedStruct(identifier: String, srcCodeName: String, packageName: String, genericTypeParams!: Array<GenericType> = Array<GenericType>()): StructDef
```

Function: Registers an imported struct definition.

Return Value:

- [StructDef](#class-structdef) - New definition.

Example:

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

Output:

```text
1
IS
```

### func addEnum(String, String, Bool, Array\<GenericType>)

```cangjie
public func addEnum(identifier: String, srcCodeName: String, isExhaustive: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): EnumDef
```

Function: Creates a new enum definition in this package.

Return Value:

- [EnumDef](#class-enumdef) - New definition.

Example:

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

Output:

```text
1
E
```

### func addImportedEnum(String, String, String, Bool, Array\<GenericType>)

```cangjie
public func addImportedEnum(identifier: String, srcCodeName: String, packageName: String, isExhaustive: Bool, genericTypeParams!: Array<GenericType> = Array<GenericType>()): EnumDef
```

Function: Registers an imported enum definition.

Return Value:

- [EnumDef](#class-enumdef) - New definition.

Example:

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

Output:

```text
1
IE
```

### func addExtend(String, Type, Array\<GenericType>)

```cangjie
public func addExtend(identifier: String, extendedType: Type, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ExtendDef
```

Function: Creates a new extend definition in this package.

Return Value:

- [ExtendDef](#class-extenddef) - New definition.

Example:

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

Output:

```text
1
Int32
```

### func addImportedExtend(String, String, Type, Array\<GenericType>)

```cangjie
public func addImportedExtend(identifier: String, packageName: String, extendedType: Type, genericTypeParams!: Array<GenericType> = Array<GenericType>()): ExtendDef
```

Function: Registers an imported extend definition.

Return Value:

- [ExtendDef](#class-extenddef) - New definition.

Example:

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

Output:

```text
1
Int32
```

### func addFunction(FuncType, String, String, String)

```cangjie
public func addFunction(ty: FuncType, identifier: String, srcCodeName: String, packageName: String): Function
```

Function: Adds a function definition to this package, returning the created Function (parameters auto-filled from ty).

Parameters:

- ty: FuncType - Function type.
- identifier: String - Internal identifier.
- srcCodeName: String - Source code name.
- packageName: String - Owning package name.

Return Value:

- [Function](#class-function) - The newly created function definition.

Example:

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

Output:

```text
1
f
```

### func addGlobalVar(Type, String, String, String)

```cangjie
public func addGlobalVar(ty: Type, identifier: String, srcCodeName: String, packageName: String): GlobalVar
```

Function: Adds a global variable definition to this package, returning the created GlobalVar.

Parameters:

- ty: Type - Variable type.
- identifier: String - Internal identifier.
- srcCodeName: String - Source code name.
- packageName: String - Owning package name.

Return Value:

- [GlobalVar](#class-globalvar) - The newly created global variable definition.

Example:

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

Output:

```text
1
gv
```

### func getSpecifiedClassDef(String, String)

```cangjie
public func getSpecifiedClassDef(packageName: String, srcCodeName: String): ?ClassLikeDef
```

Function: Looks up a class/interface definition by declared package name + source type name among imports and local `classDefs`.

Return Value:

- ?[ClassLikeDef](#class-classlikedef) - `Some` if found, otherwise `None`.

Example:

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

Output:

```text
fn_getSpecifiedClassDef: true
```

### func getSpecifiedStructDef(String, String)

```cangjie
public func getSpecifiedStructDef(packageName: String, srcCodeName: String): ?StructDef
```

Function: Same as above, for struct definitions.

Return Value:

- ?[StructDef](#class-structdef) - Optional result.

Example:

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

Output:

```text
fn_getSpecifiedStructDef: true
```

### func getSpecifiedEnumDef(String, String)

```cangjie
public func getSpecifiedEnumDef(packageName: String, srcCodeName: String): ?EnumDef
```

Function: Same as above, for enum definitions.

Return Value:

- ?[EnumDef](#class-enumdef) - Optional result.

Example:

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

Output:

```text
fn_getSpecifiedEnumDef: true
```

### func getSpecifiedFunction(String)

```cangjie
public func getSpecifiedFunction(mangledName: String): ?Function
```

Function: Looks up a function definition by its mangled name.

Parameters:

- mangledName: String - The function's mangled name (without global prefix).

Return Value:

- ?[Function](#class-function) - `Some` if found, `None` otherwise.

Example:

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

Output:

```text
fn_getSpecifiedFunction: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: Concatenated text of package name, access level, import section, and local type section (for debugging).

Return Value:

- String - Full package description.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("my.pkg", AccessLevel.Public)
    let _ = pkg.addClass("C1", "C", true)
    println("fn_toString: ${pkg.toString().size > 0}")
}
```

Output:

```text
fn_toString: true
```

### func dump()

```cangjie
public func dump(): Unit
```

Function: Prints `toString()` to standard output.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("my.pkg", AccessLevel.Public)
    let _ = pkg.addClass("C1", "C", true)
    pkg.dump()
}
```

Output:

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

Function: **Raw array** type with element type and dimension count `dims`. Cached uniquely by `(elementType, dims)`.

Parent Types:

- [BuiltinType](#class-builtintype)
- Equatable\<[RawArrayType](#class-rawarraytype)>

### prop elementType

```cangjie
public prop elementType: Type
```

Function: Array element type.

Type: Type

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = RawArrayType.get(IntType.getUInt32(), 1)
    println(t.elementType.toString())
}
```

Output:

```text
UInt32
```

### prop dims

```cangjie
public prop dims: UInt32
```

Function: Raw array dimension count.

Type: UInt32

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = RawArrayType.get(IntType.getInt32(), 3)
    println("${t.dims}")
}
```

Output:

```text
3
```

### static func get(Type, UInt32)

```cangjie
public static func get(elementType: Type, dims: UInt32): RawArrayType
```

Function: Gets or creates a raw array type.

Return Value:

- [RawArrayType](#class-rawarraytype) - The RawArrayType instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = RawArrayType.get(IntType.getInt32(), 2)
    println("static_get: ${t.toString().size > 0}")
}
```

Output:

```text
static_get: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form of the type (e.g. multi-dimensional `[[[T]]]` style; see source).

Return Value:

- String - Text representation.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t = RawArrayType.get(IntType.getInt32(), 2)
    println(t.toString())
}
```

Output:

```text
RawArray<RawArray<Int32>>
```

### operator func ==(RawArrayType)

```cangjie
public operator func ==(other: RawArrayType): Bool
```

Function: Compares whether element type and dimension count match.

Parameters:

- other: RawArrayType - The other raw array type.

Return Value:

- Bool - Whether they are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t1 = RawArrayType.get(IntType.getInt32(), 2)
    let t2 = RawArrayType.get(IntType.getInt32(), 2)
    println("op_eq_RawArrayType: ${t1 == t2}")
}
```

Output:

```text
op_eq_RawArrayType: true
```

## class RefType

```cangjie
public class RefType <: Type & Equatable<RefType> {}
```

Function: Represents a reference type in the type system. Wraps another type to denote a reference to it. The class caches all reference types to ensure uniqueness.

Parent Types:

- [Type](#class-type)
- Equatable\<[RefType](#class-reftype)>

### prop baseType

```cangjie
public prop baseType: Type
```

Function: Gets the base type that this reference type refers to.

Return Value:

- [Type](#class-type) - Base type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let refType = RefType.get(intType)
    println(refType.baseType.toString())
}
```

Output:

```text
Int32
```

### static func get(Type)

```cangjie
public static func get(baseType: Type): RefType
```

Function: Gets or creates the RefType for the given base type.

This method ensures there is at most one RefType instance per base type.

Parameters:

- baseType: Type - The base type to reference.

Return Value:

- [RefType](#class-reftype) - RefType instance for the given base type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let refType = RefType.get(intType)
    println(refType.toString())
}
```

Output:

```text
Int32&
```

### func toString()

```cangjie
public func toString(): String
```

Function: Converts this RefType to a string representation.

Return Value:

- String - String form of the reference type (base type followed by `&`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let refType = RefType.get(IntType.getUInt32())
    println(refType.toString())
}
```

Output:

```text
UInt32&
```

### operator func ==(RefType)

```cangjie
public operator func ==(other: RefType): Bool
```

Function: Checks whether this RefType equals another RefType.

Parameters:

- other: RefType - The RefType to compare with.

Return Value:

- Bool - Returns true if the types are equal, false otherwise.

Example:

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

Output:

```text
op_eq_RefType: true
```

## class RuneType

```cangjie
public class RuneType <: BuiltinType & Equatable<RuneType> {}
```

Function: Represents the Rune type in the type system. This type represents a character type.

Parent Types:

- [BuiltinType](#class-builtintype)
- Equatable\<[RuneType](#class-runetype)>

### static func get()

```cangjie
public static func get(): RuneType
```

Function: Gets the singleton instance of RuneType.

Return Value:

- [RuneType](#class-runetype) - RuneType instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let runeType = RuneType.get()
    println("Rune type: ${runeType.toString()}")
}
```

Output:

```text
Rune type: Rune
```

### operator func ==(RuneType)

```cangjie
public operator func ==(_: RuneType): Bool
```

Function: Checks whether this RuneType equals another RuneType.

Parameters:

- _: RuneType - The other RuneType to compare with (unused; always returns true).

Return Value:

- Bool - Always returns true because all RuneType instances are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let runeType1 = RuneType.get()
    let runeType2 = RuneType.get()
    println("Two RuneType instances are equal: ${runeType1 == runeType2}")
}
```

Output:

```text
Two RuneType instances are equal: true
```

## class StructDef

```cangjie
public class StructDef <: CustomTypeDef & Equatable<StructDef> {}
```

Function: **Struct** definition; `isCStruct` marks C-interop structs.

Parent Types:

- [CustomTypeDef](#class-customtypedef)
- Equatable\<[StructDef](#class-structdef)>

### prop structType

```cangjie
public prop structType: StructType
```

Function: The instantiated [StructType](#class-structtype) corresponding to this definition.

Type: [StructType](#class-structtype)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let s = pkg.addStruct("S_m", "S")
    println("prop_structType: ${s.structType.structDef == s}")
}
```

Output:

```text
prop_structType: true
```

### prop isCStruct

```cangjie
public mut prop isCStruct: Bool
```

Function: Whether this is marked as a C-interop struct.

Type: Bool

Example:

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

Output:

```text
mut_prop_isCStruct: true
```

### operator func ==(StructDef)

```cangjie
public operator func ==(other: StructDef): Bool
```

Function: Compares whether two struct definitions are the same.

Parameters:

- other: StructDef - The other struct definition.

Return Value:

- Bool - Whether they are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let s = pkg.addStruct("S_m", "S")
    println("op_eq_StructDef: ${s == s}")
}
```

Output:

```text
op_eq_StructDef: true
```

## class StructType

```cangjie
public class StructType <: CustomType & Equatable<StructType> {}
```

Function: Instantiated type of the struct; `get(def, genericTypeParams)` caches a unique instance.

Parent Types:

- [CustomType](#class-customtype)
- Equatable\<[StructType](#class-structtype)>

### prop structDef

```cangjie
public prop structDef: StructDef
```

Function: The corresponding [StructDef](#class-structdef).

Type: [StructDef](#class-structdef)

Example:

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

Output:

```text
S
```

### static func get(StructDef, Array\<Type>)

```cangjie
public static func get(def: StructDef, genericTypeParams: Array<Type>): StructType
```

Function: Gets or creates the cached instance from the struct definition and generic arguments.

Parameters:

- def: StructDef - Struct definition.
- genericTypeParams: Array\<Type> - Generic type arguments.

Return Value:

- [StructType](#class-structtype) - Instantiated struct type.

Example:

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

Output:

```text
S
```

### operator func ==(StructType)

```cangjie
public operator func ==(other: StructType): Bool
```

Function: Compares whether two instantiated struct types are the same.

Parameters:

- other: StructType - The other struct type.

Return Value:

- Bool - Whether they are equal.

Example:

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

Output:

```text
op_eq_StructType: true
```

## class ThisType

```cangjie
public class ThisType <: Type & Equatable<ThisType> {}
```

Function: The **`This`** type inside a class/struct body; singleton.

Parent Types:

- [Type](#class-type)
- Equatable\<[ThisType](#class-thistype)>

### static func get()

```cangjie
public static func get(): ThisType
```

Function: Returns the unique singleton of `This` type.

Return Value:

- [ThisType](#class-thistype) - Singleton.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("static_get: ${ThisType.get().toString().size > 0}")
}
```

Output:

```text
static_get: true
```

### operator func ==(ThisType)

```cangjie
public operator func ==(_: ThisType): Bool
```

Function: Compares with another `ThisType` (singleton identity).

Parameters:

- _: ThisType - The other instance.

Return Value:

- Bool - Always `true`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let t1 = ThisType.get()
    let t2 = ThisType.get()
    println("op_eq_ThisType: ${t1 == t2}")
}
```

Output:

```text
op_eq_ThisType: true
```

## class TupleType

```cangjie
public class TupleType <: Type & Equatable<TupleType> {}
```

Function: Tuple type; cached uniquely by element type sequence signature.

Parent Types:

- [Type](#class-type)
- Equatable\<[TupleType](#class-tupletype)>

### prop elementTypes

```cangjie
public prop elementTypes: Array<Type>
```

Function: Types at each tuple position.

Type: Array\<Type>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let u = UnitType.get()
    let tup = TupleType.get([IntType.getInt32(), u])
    println("${tup.elementTypes.size}")
}
```

Output:

```text
2
```

### static func get(Array\<Type>)

```cangjie
public static func get(elementTypes: Array<Type>): TupleType
```

Function: Gets or creates the unique tuple type for the given element type sequence.

Parameters:

- elementTypes: Array\<Type> - Element types from left to right.

Return Value:

- [TupleType](#class-tupletype) - Tuple type instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let tup = TupleType.get([IntType.getInt32()])
    println("${tup.elementTypes.size}")
}
```

Output:

```text
1
```

### func toString()

```cangjie
public func toString(): String
```

Function: String representation of the tuple type.

Return Value:

- String - Textual form.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let tup = TupleType.get([IntType.getUInt32()])
    println(tup.toString())
}
```

Output:

```text
Tuple(UInt32)
```

### operator func ==(TupleType)

```cangjie
public operator func ==(other: TupleType): Bool
```

Function: Compares whether two tuple types have the same element type sequence.

Parameters:

- other: TupleType - The other tuple type.

Return Value:

- Bool - Whether they are equal.

Example:

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

Output:

```text
op_eq_TupleType: true
```

## class Type

```cangjie
sealed abstract class Type <: ToString & Hashable & Equatable<Type> {}
```

Function: Abstract base class of all types in the type system. Provides equality, hashing, and string conversion.

Parent Types:

- ToString
- Hashable
- Equatable\<[Type](#class-type)>

### prop qualifiedName

```cangjie
public prop qualifiedName: String
```

Function: Qualified name of the type (for debugging and display; see `qualifiedName` `match` in source).

Type: String

### prop typeArgs

```cangjie
public prop typeArgs: Array<Type>
```

Function: Type parameter / subtype argument list for this type (depends on `TypeKind`).

Return Value:

- Array\<[Type](#class-type)> - Type parameter array.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    println("Type argument count: ${intType.typeArgs.size}")
}
```

Output:

```text
Type argument count: 0
```

### func dump()

```cangjie
public func dump(): Unit
```

Function: Prints the string representation of the type to standard output.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    intType.dump()
}
```

Output:

```text
Int32
```

### func hashCode()

```cangjie
public func hashCode(): Int64
```

Function: Gets the hash code of this type.

Return Value:

- Int64 - Hash code of the type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    println("Hash code: ${intType.hashCode()}")
}
```

Output:

```text
Hash code: -7959616418923165251
```

### func isBoolType()

```cangjie
public func isBoolType(): Bool
```

Function: Checks whether this type is a boolean type.

Return Value:

- Bool - Returns true if the type is Bool, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let boolType = BoolType.get()
    let intType = IntType.getInt32()
    println("BoolType is boolean type: ${boolType.isBoolType()}")
    println("Int32 is boolean type: ${intType.isBoolType()}")
}
```

Output:

```text
BoolType is boolean type: true
Int32 is boolean type: false
```

### func isBuiltinType()

```cangjie
public func isBuiltinType(): Bool
```

Function: Whether this is a builtin type (Int, Float, Bool, Rune, Unit, Nothing, RawArray, VArray, CPointer, CString, etc.).

Return Value:

- Bool - Returns true if the type is builtin, false otherwise.

### func isFloatType()

```cangjie
public func isFloatType(): Bool
```

Function: Checks whether this type is a floating-point type.

Return Value:

- Bool - Returns true if the type is Float16, Float32, or Float64, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let floatType = FloatType.getFloat32()
    let intType = IntType.getInt32()
    println("Float32 is float type: ${floatType.isFloatType()}")
    println("Int32 is float type: ${intType.isFloatType()}")
}
```

Output:

```text
Float32 is float type: true
Int32 is float type: false
```

### func isIntType()

```cangjie
public func isIntType(): Bool
```

Function: Checks whether this type is an integer type (signed or unsigned).

Return Value:

- Bool - Returns true if the type is any integer type, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let floatType = FloatType.getFloat32()
    println("Int32 is integer type: ${intType.isIntType()}")
    println("Float32 is integer type: ${floatType.isIntType()}")
}
```

Output:

```text
Int32 is integer type: true
Float32 is integer type: false
```

### func isNothingType()

```cangjie
public func isNothingType(): Bool
```

Function: Checks whether this type is the Nothing type.

Return Value:

- Bool - Returns true if the type is Nothing, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let nothingType = NothingType.get()
    let intType = IntType.getInt32()
    println("NothingType is Nothing type: ${nothingType.isNothingType()}")
    println("Int32 is Nothing type: ${intType.isNothingType()}")
}
```

Output:

```text
NothingType is Nothing type: true
Int32 is Nothing type: false
```

### func isNumericType()

```cangjie
public func isNumericType(): Bool
```

Function: Checks whether this type is a numeric type (integer or floating-point).

Return Value:

- Bool - Returns true if the type is numeric, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let floatType = FloatType.getFloat32()
    let boolType = BoolType.get()
    println("Int32 is numeric type: ${intType.isNumericType()}")
    println("Float32 is numeric type: ${floatType.isNumericType()}")
    println("Bool is numeric type: ${boolType.isNumericType()}")
}
```

Output:

```text
Int32 is numeric type: true
Float32 is numeric type: true
Bool is numeric type: false
```

### func isPrimitiveType()

```cangjie
public func isPrimitiveType(): Bool
```

Function: Checks whether this type is a primitive type.

Return Value:

- Bool - Returns true if the type is primitive (int, float, bool, rune, unit, or nothing), false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let boolType = BoolType.get()
    println("Int32 is primitive type: ${intType.isPrimitiveType()}")
    println("Bool is primitive type: ${boolType.isPrimitiveType()}")
}
```

Output:

```text
Int32 is primitive type: true
Bool is primitive type: true
```

### func isRefType()

```cangjie
public func isRefType(): Bool
```

Function: Checks whether this type is a reference type.

Return Value:

- Bool - Returns true if the type is a reference type, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let refType = RefType.get(intType)
    println("Int32 is reference type: ${intType.isRefType()}")
    println("Int32& is reference type: ${refType.isRefType()}")
}
```

Output:

```text
Int32 is reference type: false
Int32& is reference type: true
```

### func isRuneType()

```cangjie
public func isRuneType(): Bool
```

Function: Checks whether this type is the Rune type.

Return Value:

- Bool - Returns true if the type is Rune, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let runeType = RuneType.get()
    let intType = IntType.getInt32()
    println("RuneType is Rune type: ${runeType.isRuneType()}")
    println("Int32 is Rune type: ${intType.isRuneType()}")
}
```

Output:

```text
RuneType is Rune type: true
Int32 is Rune type: false
```

### func isSignedIntType()

```cangjie
public func isSignedIntType(): Bool
```

Function: Checks whether this type is a signed integer type.

Return Value:

- Bool - Returns true if the type is a signed integer type, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let uintType = IntType.getUInt32()
    println("Int32 is signed integer: ${intType.isSignedIntType()}")
    println("UInt32 is signed integer: ${uintType.isSignedIntType()}")
}
```

Output:

```text
Int32 is signed integer: true
UInt32 is signed integer: false
```

### func isUnitType()

```cangjie
public func isUnitType(): Bool
```

Function: Checks whether this type is the Unit type.

Return Value:

- Bool - Returns true if the type is Unit, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let unitType = UnitType.get()
    let intType = IntType.getInt32()
    println("UnitType is Unit type: ${unitType.isUnitType()}")
    println("Int32 is Unit type: ${intType.isUnitType()}")
}
```

Output:

```text
UnitType is Unit type: true
Int32 is Unit type: false
```

### func isUnsignedIntType()

```cangjie
public func isUnsignedIntType(): Bool
```

Function: Checks whether this type is an unsigned integer type.

Return Value:

- Bool - Returns true if the type is an unsigned integer type, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let uintType = IntType.getUInt32()
    println("Int32 is unsigned integer: ${intType.isUnsignedIntType()}")
    println("UInt32 is unsigned integer: ${uintType.isUnsignedIntType()}")
}
```

Output:

```text
Int32 is unsigned integer: false
UInt32 is unsigned integer: true
```

### func isAnyTypeInStd()

```cangjie
public func isAnyTypeInStd(): Bool
```

Function: Whether this is the Any type in the std package.

Return Value:

- Bool - true if the type is Any in std, false otherwise.

### func isBoxType()

```cangjie
public func isBoxType(): Bool
```

Function: Whether this is a BoxType.

Return Value:

- Bool - true if the type is a box type, false otherwise.

### func isBoxRefTypeOf(Type)

```cangjie
public func isBoxRefTypeOf(other: Type): Bool
```

Function: Whether this is the Box reference type of other.

Parameters:

- other: Type - The type to compare with.

Return Value:

- Bool - true if this type is a Box reference type of the other type, false otherwise.

### func isCFuncType()

```cangjie
public func isCFuncType(): Bool
```

Function: Whether this is a C function type.

Return Value:

- Bool - true if the type is a C function type, false otherwise.

### func isCPointerType()

```cangjie
public func isCPointerType(): Bool
```

Function: Whether this is a CPointer type.

Return Value:

- Bool - true if the type is a C pointer type, false otherwise.

### func isCStringType()

```cangjie
public func isCStringType(): Bool
```

Function: Whether this is a CString type.

Return Value:

- Bool - true if the type is a C string type, false otherwise.

### func isCTypeInStd()

```cangjie
public func isCTypeInStd(): Bool
```

Function: Whether this is a C type in the std package.

Return Value:

- Bool - true if the type is a C type in std, false otherwise.

### func isClassLikeType()

```cangjie
public func isClassLikeType(): Bool
```

Function: Whether this is a ClassLikeType.

Return Value:

- Bool - true if the type is a class-like type, false otherwise.

### func isClosureType()

```cangjie
public func isClosureType(): Bool
```

Function: Whether this is a closure type.

Return Value:

- Bool - true if the type is a closure type, false otherwise.

### func isClosureBaseType()

```cangjie
public func isClosureBaseType(): Bool
```

Function: Whether this is a closure base type.

Return Value:

- Bool - true if the type is a closure base type, false otherwise.

### func isClosureGenericBaseType()

```cangjie
public func isClosureGenericBaseType(): Bool
```

Function: Whether this is a closure generic base type.

Return Value:

- Bool - true if the type is a closure generic base type, false otherwise.

### func isClosureInstBaseType()

```cangjie
public func isClosureInstBaseType(): Bool
```

Function: Whether this is a closure instantiated base type.

Return Value:

- Bool - true if the type is a closure instantiated base type, false otherwise.

### func isCustomType()

```cangjie
public func isCustomType(): Bool
```

Function: Whether this is a CustomType.

Return Value:

- Bool - true if the type is a custom type (class, enum, or struct), false otherwise.

### func isEnumType()

```cangjie
public func isEnumType(): Bool
```

Function: Whether this is an EnumType.

Return Value:

- Bool - true if the type is an enum type, false otherwise.

### func isFuncType()

```cangjie
public func isFuncType(): Bool
```

Function: Whether this is a FuncType.

Return Value:

- Bool - true if the type is a function type, false otherwise.

### func isGenericType()

```cangjie
public func isGenericType(): Bool
```

Function: Whether this is a GenericType.

Return Value:

- Bool - true if the type is a generic type, false otherwise.

### func isGenericRelated()

```cangjie
public func isGenericRelated(): Bool
```

Function: Whether this is related to generics.

Return Value:

- Bool - true if the type or any of its type arguments is related to generics, false otherwise.

### func isReferenceType()

```cangjie
public func isReferenceType(): Bool
```

Function: Whether this is a reference type (ClassLikeType, RawArrayType, BoxType, or ThisType).

Return Value:

- Bool - true if the type is a reference type, false otherwise.

### func isRawArrayType()

```cangjie
public func isRawArrayType(): Bool
```

Function: Whether this is a RawArray type.

Return Value:

- Bool - true if the type is a raw array type, false otherwise.

### func isStructType()

```cangjie
public func isStructType(): Bool
```

Function: Whether this is a StructType.

Return Value:

- Bool - true if the type is a struct type, false otherwise.

### func isThisType()

```cangjie
public func isThisType(): Bool
```

Function: Whether this is a ThisType.

Return Value:

- Bool - true if the type is a This type, false otherwise.

### func isTupleType()

```cangjie
public func isTupleType(): Bool
```

Function: Whether this is a TupleType.

Return Value:

- Bool - true if the type is a tuple type, false otherwise.

### func isValueType()

```cangjie
public func isValueType(): Bool
```

Function: Whether this is a value type.

Return Value:

- Bool - true if the type is a value type, false otherwise.

### func isVArrayType()

```cangjie
public func isVArrayType(): Bool
```

Function: Whether this is a VArrayType.

Return Value:

- Bool - true if the type is a VArray type, false otherwise.

### func satisfyCType()

```cangjie
public func satisfyCType(): Bool
```

Function: Whether this satisfies the C type constraint.

Return Value:

- Bool - true if the type satisfies the C type constraint, false otherwise.

### func isEqualOrSubTypeOf(Type, ArrayList<(Type, Type)>)

```cangjie
public func isEqualOrSubTypeOf(parent: Type, visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Bool
```

Function: Determines whether this is an equal or subtype of parent.

Parameters:

- parent: Type - The parent type to compare with.
- visited!: ArrayList<(Type, Type)> - Visitation table for cycle detection; usually pass the default empty table.

Return Value:

- Bool - true if this type is an equal or subtype of parent, false otherwise.

### func isEqualOrInstantiatedTypeOf(Type, ArrayList<(Type, Type)>)

```cangjie
public func isEqualOrInstantiatedTypeOf(genericRelatedType: Type, visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Bool
```

Function: Determines whether this is an equal or instantiated type of genericRelatedType.

Parameters:

- genericRelatedType: Type - The generic-related type to compare with.
- visited!: ArrayList<(Type, Type)> - Visitation table for cycle detection; usually pass the default empty table.

Return Value:

- Bool - true if this type is an equal or instantiated type of genericRelatedType, false otherwise.

### func satisfyGenericConstraints(GenericType, HashMap<GenericType, Type>, ArrayList<(Type, Type)>)

```cangjie
public func satisfyGenericConstraints(gType: GenericType, instMap: HashMap<GenericType, Type>, visited!: ArrayList<(Type, Type)> = ArrayList<(Type, Type)>()): Bool
```

Function: Determines whether this satisfies the generic constraints.

Parameters:

- gType: GenericType - The generic type.
- instMap: HashMap<GenericType, Type> - The generic instantiation mapping.
- visited!: ArrayList<(Type, Type)> - Visitation table for cycle detection; usually pass the default empty table.

Return Value:

- Bool - true if this type satisfies the generic constraints, false otherwise.

### operator func ==(Type)

```cangjie
public operator func ==(other: Type): Bool
```

Function: Checks whether this type equals another type.

Parameters:

- other: Type - The type to compare with.

Return Value:

- Bool - Returns true if the types have the same kind and type arguments, false otherwise.

Example:

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

Output:

```text
type1 == type2: true
type1 == type3: false
```

### func stripAllRefs()

```cangjie
public func stripAllRefs(): Type
```

Function: Strips all reference wrappers from this type.

Recursively removes all `Ref` wrappers until a non-reference type is reached.

Return Value:

- [Type](#class-type) - Base type after stripping all reference wrappers.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    let refType = RefType.get(intType)
    let baseType = refType.stripAllRefs()
    println("Reference type: ${refType.toString()}")
    println("After stripping reference: ${baseType.toString()}")
}
```

Output:

```text
Reference type: Int32&
After stripping reference: Int32
```

### func toString()

```cangjie
public open func toString(): String
```

Function: Converts this type to a string representation.

Return Value:

- String - String representation of the type.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let intType = IntType.getInt32()
    println("Type: ${intType.toString()}")
}
```

Output:

```text
Type: Int32
```

## class UnitType

```cangjie
public class UnitType <: BuiltinType & Equatable<UnitType> {}
```

Function: Represents the Unit type in the type system. Denotes no meaningful value, similar to `void` in C.

Parent Types:

- [BuiltinType](#class-builtintype)
- Equatable\<[UnitType](#class-unittype)>

### static func get()

```cangjie
public static func get(): UnitType
```

Function: Gets the singleton instance of UnitType.

Return Value:

- [UnitType](#class-unittype) - UnitType instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let unitType = UnitType.get()
    println("Unit type: ${unitType.toString()}")
}
```

Output:

```text
Unit type: Unit
```

### operator func ==(UnitType)

```cangjie
public operator func ==(_: UnitType): Bool
```

Function: Checks whether this UnitType equals another UnitType.

Parameters:

- _: UnitType - The other UnitType to compare with (unused; always returns true).

Return Value:

- Bool - Always returns true because all UnitType instances are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let unitType1 = UnitType.get()
    let unitType2 = UnitType.get()
    println("Two UnitType instances are equal: ${unitType1 == unitType2}")
}
```

Output:

```text
Two UnitType instances are equal: true
```

## class VArrayType

```cangjie
public class VArrayType <: BuiltinType & Equatable<VArrayType> {}
```

Function: **Fixed-length VArray** type `VArray<T, $n>` with compile-time fixed length. Cached uniquely by `(elementType, size)`.

Parent Types:

- [BuiltinType](#class-builtintype)
- Equatable\<[VArrayType](#class-varraytype)>

### prop elementType

```cangjie
public prop elementType: Type
```

Function: Element type.

Type: Type

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v = VArrayType.get(IntType.getUInt32(), 4)
    println(v.elementType.toString())
}
```

Output:

```text
UInt32
```

### prop size

```cangjie
public prop size: Int64
```

Function: Compile-time fixed length.

Type: Int64

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v = VArrayType.get(IntType.getInt32(), 8)
    println("${v.size}")
}
```

Output:

```text
8
```

### static func get(Type, Int64)

```cangjie
public static func get(elementType: Type, size: Int64): VArrayType
```

Function: Gets or creates a VArray type.

Return Value:

- [VArrayType](#class-varraytype) - The VArrayType instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v = VArrayType.get(IntType.getInt32(), 8)
    println("static_get: ${v.toString().size > 0}")
}
```

Output:

```text
static_get: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: String representation of the fixed-length VArray.

Return Value:

- String - Textual form.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v = VArrayType.get(IntType.getInt32(), 2)
    println(v.toString())
}
```

Output:

```text
VArray<Int32, $2>
```

### operator func ==(VArrayType)

```cangjie
public operator func ==(other: VArrayType): Bool
```

Function: Compares whether element type and length match.

Parameters:

- other: VArrayType - The other VArray type.

Return Value:

- Bool - Whether they are equal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let v1 = VArrayType.get(IntType.getInt32(), 8)
    let v2 = VArrayType.get(IntType.getInt32(), 8)
    println("op_eq_VArrayType: ${v1 == v2}")
}
```

Output:

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

Function: Checked exception thrown when CHIR construction or IR state is inconsistent.

Parent Types:

- Exception

### init()

```cangjie
public init()
```

Function: Constructs a `CHIRException` without a detail message.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let e = CHIRException()
    println("init_no_msg: ${e.toString().size > 0}")
}
```

Output:

```text
init_no_msg: true
```

### init(String)

```cangjie
public init(message: String)
```

Function: Constructs a `CHIRException` with a detail message.

Parameters:

- message: String - Human-readable error description text.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let e = CHIRException("invalid IR")
    println("init_with_msg: ${e.toString().size > 0}")
}
```

Output:

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

Function: Lightweight signature package for function symbols (name, function type, generic type parameters), used to describe the target signature information of a function call.

### init(String, FuncType)

```cangjie
public init(name: String, ty: FuncType)
```

Function: Constructs a `FuncSigInfo` without generic type parameters; `genericTypeParams` is initialized as an empty array.

Parameters:

- name: String - The logical name or mangled name of the symbol.
- ty: [FuncType](#class-functype) - The function type (parameter list and return type).

Example:

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

Output:

```text
init_no_generic: foo
```

### init(String, FuncType, Array\<GenericType>)

```cangjie
public init(name: String, ty: FuncType, genericTypeParams: Array<GenericType>)
```

Function: Constructs a `FuncSigInfo` with generic type parameters.

Parameters:

- name: String - The logical name or mangled name of the symbol.
- ty: [FuncType](#class-functype) - The function type (parameter list and return type).
- genericTypeParams: Array\<[GenericType](#class-generictype)> - Generic type parameter list (in declaration order).

Example:

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

Output:

```text
init_with_generic: 1
```

### prop genericTypeParams

```cangjie
public prop genericTypeParams: Array<GenericType>
```

Function: Generic type parameter list attached to this signature.

Type: Array\<[GenericType](#class-generictype)>

Example:

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

Output:

```text
1
```

### prop name

```cangjie
public prop name: String
```

Function: The display name or mangled name of the symbol.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ft = FuncType.get([], UnitType.get())
    let sig = FuncSigInfo("myFunc", ft)
    println(sig.name)
}
```

Output:

```text
myFunc
```

### prop ty

```cangjie
public prop ty: FuncType
```

Function: The function type of this signature.

Type: [FuncType](#class-functype)

Example:

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

Output:

```text
(Int32) -> Int32
```

### func dump()

```cangjie
public func dump(): Unit
```

Function: Outputs signature information to standard output (prints after calling `toString()`).

Example:

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

Output:

```text
g(Int32) -> Int32
```

### func toString()

```cangjie
public func toString(): String
```

Function: Renders into the single-line text form `name<generics>(params) -> ret`, convenient for logging and debugging.

Return Value:

- String - Textual form of the signature.

Example:

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

Output:

```text
h<Generic-pkg:T>(Int32) -> Unit
```

## class CHIRVisitor

```cangjie
public abstract class CHIRVisitor {}
```

Function: **Abstract visitor** for CHIR functions, block groups, basic blocks, and nested expressions. Subclasses can override [`action`](#func-actionexpression) to observe each expression node; `walk` methods recursively traverse until `IRActionMode.Stop` is returned.

### func walk(Function)

```cangjie
public func walk(f: Function): Unit
```

Function: Traverses the body of the given function (if present); internally visits all block groups in the body sequentially.

Parameters:

- f: [Function](#class-function) - The function to traverse.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("walk_Function: ${f.body.isNone()}")
}
```

Output:

```text
walk_Function: true
```

### func walk(BlockGroup)

```cangjie
public func walk(bg: BlockGroup): Unit
```

Function: Traverses each basic block in the block group in order; terminates early when `STOP` status is encountered.

Parameters:

- bg: [BlockGroup](#class-blockgroup) - The block group to traverse.

Example:

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

Output:

```text
0
```

### func walk(Block)

```cangjie
public func walk(b: Block): Unit
```

Function: Traverses each expression in the basic block, and recursively visits nested block groups within expressions; terminates early when `STOP` status is encountered.

Parameters:

- b: [Block](#class-block) - The basic block to traverse.

Example:

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

Output:

```text
0
```

### func action(Expression)

```cangjie
public open func action(ty: Expression): IRActionMode
```

Function: Called for each visited expression node, determining whether to continue traversal. Defaults to returning `IRActionMode.Continue`; subclasses can override to implement custom observation logic or early termination.

Parameters:

- ty: Expression - The current expression node.

Return Value:

- [IRActionMode](chir_package_enums.md#enum-iractionmode) - Visitor control mode (`Continue` to continue traversal, `Stop` to terminate traversal, `Skip` to skip nested BlockGroups).

Example:

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

Output:

```text
visitor_done
```

## class FuncCallContext

```cangjie
public class FuncCallContext {
    public init(args: Array<Value>, instTypeArgs: Array<Type>, objType: ?Type)
}
```

Function: Function call context, encapsulating the argument value list, instantiation type arguments, and optional calling object type.

### init(Array\<Value>, Array\<Type>, ?Type)

```cangjie
public init(args: Array<Value>, instTypeArgs: Array<Type>, objType: ?Type)
```

Function: Constructs a `FuncCallContext`, specifying the argument list, instantiation type arguments, and calling object type.

Parameters:

- args: Array\<Value> - The argument value list of the function call.
- instTypeArgs: Array\<[Type](#class-type)> - Instantiation generic type argument list.
- objType: ?[Type](#class-type) - Calling object type (`None` for static calls).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ctx = FuncCallContext([], [], None)
    println("init_FuncCallContext: ${ctx.args.size}")
}
```

Output:

```text
init_FuncCallContext: 0
```

### prop args

```cangjie
public prop args: Array<Value>
```

Function: The argument value list of the function call.

Type: Array\<Value>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ctx = FuncCallContext([], [], None)
    println("${ctx.args.size}")
}
```

Output:

```text
0
```

### prop instTypeArgs

```cangjie
public prop instTypeArgs: Array<Type>
```

Function: Instantiation generic type argument list.

Type: Array\<[Type](#class-type)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ctx = FuncCallContext([], [], None)
    println("${ctx.instTypeArgs.size}")
}
```

Output:

```text
0
```

### prop objType

```cangjie
public prop objType: ?Type
```

Function: Calling object type; `None` for static calls.

Type: ?[Type](#class-type)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let ctx = FuncCallContext([], [], None)
    println("prop_objType: ${ctx.objType.isNone()}")
}
```

Output:

```text
prop_objType: true
```

### func setArg(Int64, Value)

```cangjie
public func setArg(index: Int64, arg: Value): Unit
```

Function: Sets the argument value at the specified position.

Parameters:

- index: Int64 - Argument position index.
- arg: Value - New argument value.

### func setInstTypeArg(Int64, Type)

```cangjie
public func setInstTypeArg(index: Int64, arg: Type): Unit
```

Function: Sets the instantiation type argument at the specified position.

Parameters:

- index: Int64 - Argument position index.
- arg: [Type](#class-type) - New instantiation type argument.

## class InvokeCallContext

```cangjie
public class InvokeCallContext {
    public init(caller: Value, virMethodCtx: FuncSigInfo, funcCallCtx: FuncCallContext)
}
```

Function: Virtual method call context, encapsulating the caller value, virtual method signature information, and function call context.

### init(Value, FuncSigInfo, FuncCallContext)

```cangjie
public init(caller: Value, virMethodCtx: FuncSigInfo, funcCallCtx: FuncCallContext)
```

Function: Constructs an `InvokeCallContext`, specifying the caller, virtual method signature information, and function call context.

Parameters:

- caller: Value - The caller value (i.e., the receiver object).
- virMethodCtx: [FuncSigInfo](#class-funcsiginfo) - Signature information of the invoked virtual method.
- funcCallCtx: [FuncCallContext](#class-funccallcontext) - Function call context for arguments and type arguments.

Example:

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

Output:

```text
init_InvokeCallContext: done
```

### prop caller

```cangjie
public prop caller: Value
```

Function: The caller value (i.e., the receiver object of the virtual method call).

Type: Value

Example:

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

Output:

```text
prop_caller: true
```

### prop virMethodCtx

```cangjie
public prop virMethodCtx: FuncSigInfo
```

Function: Signature information of the invoked virtual method.

Type: [FuncSigInfo](#class-funcsiginfo)

Example:

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

Output:

```text
prop_virMethodCtx: m
```

### prop funcCallCtx

```cangjie
public prop funcCallCtx: FuncCallContext
```

Function: Function call context for arguments and type arguments.

Type: [FuncCallContext](#class-funccallcontext)

Example:

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

Output:

```text
prop_funcCallCtx: 0
```

## class Value

```cangjie
sealed abstract class Value <: ToString & Hashable & Equatable<Value> {}
```

Function: Abstract base class of all CHIR values, covering blocks, block groups, functions, global variables, local variables, parameters and literals. Provides common information such as identifier, type and user list, plus equality, hashing and type-testing capabilities.

Parent Types:

- ToString
- Hashable
- Equatable\<[Value](#class-value)>

### prop identifier

```cangjie
public mut prop identifier: String
```

Function: Identifier of the value (may carry a prefix such as the global-symbol prefix, block prefix or local-variable prefix); readable and writable.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_identifier: ${f.identifier}")
}
```

Output:

```text
prop_identifier: @f_m
```

### prop identifierWithoutPrefix

```cangjie
public prop identifierWithoutPrefix: String
```

Function: Identifier with built-in prefixes (global-symbol prefix, block prefix, local-variable prefix) stripped.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_identifierWithoutPrefix: ${f.identifierWithoutPrefix}")
}
```

Output:

```text
prop_identifierWithoutPrefix: f_m
```

### prop ty

```cangjie
public mut prop ty: Type
```

Function: Type of the value; readable and writable.

Type: [Type](#class-type)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_ty: ${f.ty.qualifiedName}")
}
```

Output:

```text
prop_ty: ()->Unit
```

### prop users

```cangjie
public prop users: Array<Expression>
```

Function: List of expressions that use this value as an operand (user list).

Type: Array\<[Expression](#class-expression)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_users: ${f.users.size}")
}
```

Output:

```text
prop_users: 0
```

### func dump()

```cangjie
public func dump(): Unit
```

Function: Prints the string representation of the value to standard output.

Example:

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

Function: Gets the hash code of this value.

Return Value:

- Int64 - Hash code of the value.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_hashCode: ${f.hashCode() == f.hashCode()}")
}
```

Output:

```text
func_hashCode: true
```

### func isBlock()

```cangjie
public func isBlock(): Bool
```

Function: Checks whether this value is a [Block](#class-block).

Return Value:

- Bool - Returns true when this is a block, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isBlock: ${f.isBlock()}")
}
```

Output:

```text
func_isBlock: false
```

### func isBlockGroup()

```cangjie
public func isBlockGroup(): Bool
```

Function: Checks whether this value is a [BlockGroup](#class-blockgroup).

Return Value:

- Bool - Returns true when this is a block group, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isBlockGroup: ${f.isBlockGroup()}")
}
```

Output:

```text
func_isBlockGroup: false
```

### func isFunction()

```cangjie
public func isFunction(): Bool
```

Function: Checks whether this value is a [Function](#class-function).

Return Value:

- Bool - Returns true when this is a function, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isFunction: ${f.isFunction()}")
}
```

Output:

```text
func_isFunction: true
```

### func isGlobalVar()

```cangjie
public func isGlobalVar(): Bool
```

Function: Checks whether this value is a [GlobalVar](#class-globalvar).

Return Value:

- Bool - Returns true when this is a global variable, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isGlobalVar: ${f.isGlobalVar()}")
}
```

Output:

```text
func_isGlobalVar: false
```

### func isLiteral()

```cangjie
public func isLiteral(): Bool
```

Function: Checks whether this value is a subclass of [LiteralValue](#class-literalvalue).

Return Value:

- Bool - Returns true when this is a literal, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isLiteral: ${f.isLiteral()}")
}
```

Output:

```text
func_isLiteral: false
```

### func isLocalVar()

```cangjie
public func isLocalVar(): Bool
```

Function: Checks whether this value is a [LocalVar](#class-localvar).

Return Value:

- Bool - Returns true when this is a local variable, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isLocalVar: ${f.isLocalVar()}")
}
```

Output:

```text
func_isLocalVar: false
```

### func isParameter()

```cangjie
public func isParameter(): Bool
```

Function: Checks whether this value is a [Parameter](#class-parameter).

Return Value:

- Bool - Returns true when this is a parameter, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isParameter: ${f.isParameter()}")
}
```

Output:

```text
func_isParameter: false
```

### func replaceWith(Value)

```cangjie
public func replaceWith(other: Value): Unit
```

Function: Replaces this value with another value in every expression that uses it.

Parameters:

- other: [Value](#class-value) - The new value to replace with.

Example:

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

Output:

```text
func_replaceWith: 1
```

### operator func ==(Value)

```cangjie
public operator func ==(other: Value): Bool
```

Function: Reference comparison, checks whether two Value instances are identical.

Parameters:

- other: [Value](#class-value) - The other value.

Return Value:

- Bool - Whether the references are identical.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("op_eq_Value: ${f == f}")
}
```

Output:

```text
op_eq_Value: true
```

## class Block

```cangjie
public class Block <: Value & Equatable<Block> {}
```

Function: Represents a **basic block** in CHIR, the fundamental unit of control flow within a function body. Each basic block contains a sequence of expressions and can form a control flow graph with predecessor basic blocks; setting `exceptions` marks it as an exception-handling landing pad block.

Parent Types:

- Value
- Equatable\<Block>

### prop exceptions

```cangjie
public mut prop exceptions: Array<ClassLikeType>
```

Function: Exception type list; setting this property makes the basic block an exception-handling landing pad block. Internally `None` in the initial state; must be assigned before reading.

Type: Array\<ClassLikeType>

Example:

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

Output:

```text
mut_prop_exceptions: 0
```

### prop exprs

```cangjie
public prop exprs: Array<Expression>
```

Function: Expression list within the basic block.

Type: Array\<Expression>

Example:

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

Output:

```text
prop_exprs: 0
```

### prop isLandingPadBlock

```cangjie
public prop isLandingPadBlock: Bool
```

Function: Whether this is an exception-handling landing pad block; returns `true` when `exceptions` has been assigned (internally `Some`).

Type: Bool

Example:

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

Output:

```text
prop_isLandingPadBlock: false
```

### prop owner

```cangjie
public prop owner: BlockGroup
```

Function: The owning BlockGroup.

Type: [BlockGroup](#class-blockgroup)

Example:

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

Output:

```text
prop_owner: true
```

### prop predecessors

```cangjie
public prop predecessors: Array<Block>
```

Function: Predecessor basic block list.

Type: Array\<Block>

Example:

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

Output:

```text
prop_predecessors: 0
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

Function: The owning top-level function.

Type: [Function](#class-function)

Example:

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

Output:

```text
prop_topLevelFunc: true
```

### func appendExpr(Expression)

```cangjie
public func appendExpr(expr: Expression): Unit
```

Function: Appends an expression to the end of the basic block.

Parameters:

- expr: Expression - The expression to append.

Example:

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

Output:

```text
fn_appendExpr: 1
```

### func destroySelf(Bool)

```cangjie
public func destroySelf(removeFromOwner!: Bool = true): Unit
```

Function: Destroys this block and all contained expressions, and detaches related reference relationships; marks the internal `kind` as `Invalid`.

Parameters:

- removeFromOwner!: Bool - Whether to remove this block from the owning BlockGroup's `blocks` list. Defaults to `true`. Pass `false` when the owner clears the list itself during cascading destruction.

Example:

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

Output:

```text
fn_destroySelf_before: 2
fn_destroySelf_after: 1
```

### func insertExpr(Expression, Int64)

```cangjie
public func insertExpr(expr: Expression, at: Int64): Unit
```

Function: Inserts an expression at the specified position; when `at` is out of range, it is equivalent to appending to the end.

Parameters:

- expr: Expression - The expression to insert.
- at: Int64 - Insertion position index (0-based).

Example:

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

Output:

```text
fn_insertExpr: 2
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form of the basic block (including identifier, expression list, etc.).

Return Value:

- String - Textual form.

Example:

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

Output:

```text
fn_toString: true
```

### operator func ==(Block)

```cangjie
public operator func ==(other: Block): Bool
```

Function: Reference comparison, determines whether two Blocks are the same instance.

Parameters:

- other: Block - Another basic block.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Block: true
```

## class BlockGroup

```cangjie
public class BlockGroup <: Value & Equatable<BlockGroup> {}
```

Function: Represents a **basic block group** in CHIR, the control flow graph container for a function body or lambda body, containing several basic blocks and maintaining an entry block pointer.

Parent Types:

- Value
- Equatable\<BlockGroup>

### prop blocks

```cangjie
public prop blocks: Array<Block>
```

Function: Basic block list.

Type: Array\<Block>

Example:

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

Output:

```text
prop_blocks: 1
```

### prop entryBlock

```cangjie
public prop entryBlock: Block
```

Function: Entry basic block; accessing it when unset will throw an exception.

Type: Block

Example:

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

Output:

```text
prop_entryBlock: true
```

### prop owner

```cangjie
public prop owner: Value
```

Function: The owning parent value (the function or the local variable corresponding to a lambda).

Type: Value

Example:

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

Output:

```text
prop_owner: true
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

Function: The owning top-level function.

Type: [Function](#class-function)

Example:

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

Output:

```text
prop_topLevelFunc: true
```

### func appendBlock()

```cangjie
public func appendBlock(): Block
```

Function: Appends and returns a new empty basic block.

Return Value:

- [Block](#class-block) - The newly created basic block.

Example:

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

Output:

```text
fn_appendBlock: 2
```

### func destroySelf(Bool)

```cangjie
public func destroySelf(removeFromOwner!: Bool = true): Unit
```

Function: Destroys this block group and all contained blocks, and detaches related ownership relationships; marks the internal `kind` as `Invalid`.

Parameters:

- removeFromOwner!: Bool - Whether to detach this block group from its owner (clear `Function.body` or remove it from a lambda expression's blockGroups). Defaults to `true`. Pass `false` when the owner clears the reference itself during cascading destruction.

Example:

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

Output:

```text
fn_destroySelf_before: true
```

### func setEntryBlock(Block)

```cangjie
public func setEntryBlock(block: Block): Unit
```

Function: Sets the entry basic block; requires that the block is already in the current BlockGroup's `blocks` list.

Parameters:

- block: Block - The basic block to set as entry.

Example:

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

Output:

```text
fn_setEntryBlock: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form of the basic block group.

Return Value:

- String - Textual form.

Example:

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

Output:

```text
fn_toString: true
```

### operator func ==(BlockGroup)

```cangjie
public operator func ==(other: BlockGroup): Bool
```

Function: Reference comparison, determines whether two BlockGroups are the same instance.

Parameters:

- other: BlockGroup - Another basic block group.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_BlockGroup: true
```

## class LiteralValue

```cangjie
sealed abstract class LiteralValue <: Value & Equatable<LiteralValue> {}
```

Function: Abstract base class of compile-time literal values in CHIR; parent type of literal kinds such as [BoolLiteral](#class-boolliteral), [IntLiteral](#class-intliteral) and [FloatLiteral](#class-floatliteral).

Parent Types:

- [Value](#class-value)
- Equatable\<[LiteralValue](#class-literalvalue)>

### operator func ==(LiteralValue)

```cangjie
public operator func ==(other: LiteralValue): Bool
```

Function: Reference comparison, checks whether two LiteralValue instances are identical.

Parameters:

- other: [LiteralValue](#class-literalvalue) - The other literal value.

Return Value:

- Bool - Whether the references are identical.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getInt64(), 1)
    println("op_eq_LiteralValue: ${lit == lit}")
}
```

Output:

```text
op_eq_LiteralValue: true
```

## class BoolLiteral

```cangjie
public class BoolLiteral <: LiteralValue & Equatable<BoolLiteral> {}
```

Function: Represents a boolean literal (`true` or `false`), cached by value to ensure the same boolean value corresponds to a unique instance.

Parent Types:

- LiteralValue
- Equatable\<BoolLiteral>

### prop value

```cangjie
public prop value: Bool
```

Function: The boolean value.

Type: Bool

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = BoolLiteral.get(true)
    println("prop_value: ${lit.value}")
}
```

Output:

```text
prop_value: true
```

### static func get(Bool)

```cangjie
public static func get(value: Bool): BoolLiteral
```

Function: Gets a boolean literal; the same boolean value always returns the same cached instance.

Parameters:

- value: Bool - Boolean value.

Return Value:

- [BoolLiteral](#class-boolliteral) - The corresponding boolean literal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = BoolLiteral.get(false)
    println(lit.toString())
}
```

Output:

```text
false
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form, i.e. `"true"` or `"false"`.

Return Value:

- String - Textual form of the boolean value.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = BoolLiteral.get(true)
    println(lit.toString())
}
```

Output:

```text
true
```

### operator func ==(BoolLiteral)

```cangjie
public operator func ==(other: BoolLiteral): Bool
```

Function: Reference comparison, determines whether two BoolLiterals are the same instance.

Parameters:

- other: BoolLiteral - Another boolean literal.

Return Value:

- Bool - Whether they are the same reference.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = BoolLiteral.get(true)
    let lit2 = BoolLiteral.get(true)
    println("op_eq_BoolLiteral: ${lit1 == lit2}")
}
```

Output:

```text
op_eq_BoolLiteral: true
```

## class FloatLiteral

```cangjie
public class FloatLiteral <: LiteralValue & Equatable<FloatLiteral> {}
```

Function: Represents a floating-point literal, cached by `(FloatType, Float64)` to ensure the same type and value correspond to a unique instance.

Parent Types:

- LiteralValue
- Equatable\<FloatLiteral>

### prop value

```cangjie
public prop value: Float64
```

Function: The floating-point value.

Type: Float64

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = FloatLiteral.get(FloatType.getFloat64(), 3.14)
    println("prop_value: ${lit.value}")
}
```

Output:

```text
prop_value: 3.140000
```

### static func get(FloatType, Float64)

```cangjie
public static func get(ty: FloatType, value: Float64): FloatLiteral
```

Function: Gets a floating-point literal; the same type and value combination always returns the same cached instance.

Parameters:

- ty: FloatType - Floating-point type.
- value: Float64 - Floating-point value.

Return Value:

- [FloatLiteral](#class-floatliteral) - The corresponding floating-point literal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = FloatLiteral.get(FloatType.getFloat32(), 1.5)
    println(lit.toString())
}
```

Output:

```text
1.500000f
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form, the numeric value suffixed with `"f"` (e.g. `3.14f`).

Return Value:

- String - Textual form of the floating-point value.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = FloatLiteral.get(FloatType.getFloat64(), 2.0)
    println(lit.toString())
}
```

Output:

```text
2.000000f
```

### operator func ==(FloatLiteral)

```cangjie
public operator func ==(other: FloatLiteral): Bool
```

Function: Reference comparison, determines whether two FloatLiterals are the same instance.

Parameters:

- other: FloatLiteral - Another floating-point literal.

Return Value:

- Bool - Whether they are the same reference.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = FloatLiteral.get(FloatType.getFloat64(), 1.0)
    let lit2 = FloatLiteral.get(FloatType.getFloat64(), 1.0)
    println("op_eq_FloatLiteral: ${lit1 == lit2}")
}
```

Output:

```text
op_eq_FloatLiteral: true
```

## class GlobalValue

```cangjie
sealed abstract class GlobalValue <: Value & Equatable<GlobalValue> {}
```

Function: Abstract base class of package-level global values (functions and global variables). Provides source/package name, declared parent type, feature list, custom annotation instances, and query/set capabilities for access level, static/const/external-linkage attributes; also provides [`destroySelf()`](#func-destroyself) to destroy a function or global variable.

Parent Types:

- [Value](#class-value)
- Equatable\<[GlobalValue](#class-globalvalue)>

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

Function: List of custom annotation instances attached to this global value; readable and writable.

Type: Array\<[CustomAnnoInstance](#class-customannoinstance)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_customAnnoInstances: ${f.customAnnoInstances.size}")
}
```

Output:

```text
prop_customAnnoInstances: 0
```

### prop declaredParent

```cangjie
public prop declaredParent: ?CustomTypeDef
```

Function: Type definition that declares this global value; `None` for free-standing declarations.

Type: ?[CustomTypeDef](#class-customtypedef)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_declaredParent: ${f.declaredParent.isNone()}")
}
```

Output:

```text
prop_declaredParent: true
```

### prop features

```cangjie
public prop features: Array<String>
```

Function: List of feature strings carried by this global value.

Type: Array\<String>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_features: ${f.features.size}")
}
```

Output:

```text
prop_features: 0
```

### prop packageName

```cangjie
public prop packageName: String
```

Function: Name of the package this global value belongs to.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_packageName: ${f.packageName}")
}
```

Output:

```text
prop_packageName: demo
```

### prop outerType

```cangjie
public prop outerType: ?Type
```

Function: Outer type that declares this global value; `None` when there is no outer type.

Type: ?[Type](#class-type)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_outerType: ${f.outerType.isNone()}")
}
```

Output:

```text
prop_outerType: true
```

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

Function: Name of this global value in source code.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_srcCodeName: ${f.srcCodeName}")
}
```

Output:

```text
prop_srcCodeName: f
```

### func destroySelf()

```cangjie
public func destroySelf(): Unit
```

Function: Destroys this global value. Returns immediately if it is already invalid; otherwise performs the following cleanup based on the concrete type and marks the internal `kind` as `Invalid`:

- [Function](#class-function): If `declaredParent` is present, removes itself from the parent's `methods` (and matching `instanceVarInitFunc` if any). If a function body exists, destroys the body, then clears parameters, return value, and generic type parameters.
- [GlobalVar](#class-globalvar): If `declaredParent` is present, removes itself from the parent's `staticVars`. If the initializer is a function, destroys that function, then clears the initializer.

> **Note:**
>
> Does not remove entries from [Package](#class-package) `functions` / `globalVars` lists; callers must update those lists separately.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    f.initBody()
    println("fn_body_before: ${f.body.isSome()}")
    f.destroySelf()
    println("fn_body_after: ${f.body.isNone()}")
    println("fn_invalid: ${!f.isFunction()}")
    println("pkg_fn_count: ${pkg.functions.size}")
}
```

Output:

```text
fn_body_before: true
fn_body_after: true
fn_invalid: true
pkg_fn_count: 1
```
### func isCompilerAdd()

```cangjie
public func isCompilerAdd(): Bool
```

Function: Checks whether this global value was added by the compiler.

Return Value:

- Bool - Returns true when added by the compiler, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isCompilerAdd: ${f.isCompilerAdd()}")
}
```

Output:

```text
func_isCompilerAdd: false
```

### func isConst()

```cangjie
public func isConst(): Bool
```

Function: Checks whether this global value is marked as constant.

Return Value:

- Bool - Returns true when marked as constant, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isConst: ${f.isConst()}")
}
```

Output:

```text
func_isConst: false
```

### func isExternalLinkage()

```cangjie
public func isExternalLinkage(): Bool
```

Function: Checks whether this global value has external linkage (`LinkType.External`).

Return Value:

- Bool - Returns true when it has external linkage, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isExternalLinkage: ${f.isExternalLinkage()}")
}
```

Output:

```text
func_isExternalLinkage: true
```

### func isForeign()

```cangjie
public func isForeign(): Bool
```

Function: Checks whether this global value is a foreign function.

Return Value:

- Bool - Returns true when it is a foreign function, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isForeign: ${f.isForeign()}")
}
```

Output:

```text
func_isForeign: false
```

### func isImported()

```cangjie
public func isImported(): Bool
```

Function: Checks whether this global value is imported from another package.

Return Value:

- Bool - Returns true when imported, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isImported: ${f.isImported()}")
}
```

Output:

```text
func_isImported: false
```

### func isInternal()

```cangjie
public func isInternal(): Bool
```

Function: Checks whether the access level of this global value is internal.

Return Value:

- Bool - Returns true when the access level is internal, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isInternal: ${f.isInternal()}")
}
```

Output:

```text
func_isInternal: false
```

### func isPrivate()

```cangjie
public func isPrivate(): Bool
```

Function: Checks whether the access level of this global value is private.

Return Value:

- Bool - Returns true when the access level is private, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isPrivate: ${f.isPrivate()}")
}
```

Output:

```text
func_isPrivate: false
```

### func isProtected()

```cangjie
public func isProtected(): Bool
```

Function: Checks whether the access level of this global value is protected.

Return Value:

- Bool - Returns true when the access level is protected, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isProtected: ${f.isProtected()}")
}
```

Output:

```text
func_isProtected: false
```

### func isPublic()

```cangjie
public func isPublic(): Bool
```

Function: Checks whether the access level of this global value is public.

Return Value:

- Bool - Returns true when the access level is public, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isPublic: ${f.isPublic()}")
}
```

Output:

```text
func_isPublic: false
```

### func isStatic()

```cangjie
public func isStatic(): Bool
```

Function: Checks whether this global value is a static member.

Return Value:

- Bool - Returns true when it is a static member, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("func_isStatic: ${f.isStatic()}")
}
```

Output:

```text
func_isStatic: false
```

### func setConst(Bool)

```cangjie
public func setConst(enable: Bool): Unit
```

Function: Sets the constant flag of this global value.

Parameters:

- enable: Bool - true marks as constant, false clears the mark.

Example:

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

Output:

```text
func_setConst: true
```

### func setImported(Bool)

```cangjie
public func setImported(enable: Bool): Unit
```

Function: Sets the imported flag of this global value.

Parameters:

- enable: Bool - true marks as imported, false clears the mark.

Example:

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

Output:

```text
func_setImported: true
```

### func setInternal()

```cangjie
public func setInternal(): Unit
```

Function: Sets the access level of this global value to internal.

Example:

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

Output:

```text
func_setInternal: true
```

### func setPrivate()

```cangjie
public func setPrivate(): Unit
```

Function: Sets the access level of this global value to private.

Example:

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

Output:

```text
func_setPrivate: true
```

### func setProtected()

```cangjie
public func setProtected(): Unit
```

Function: Sets the access level of this global value to protected.

Example:

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

Output:

```text
func_setProtected: true
```

### func setPublic()

```cangjie
public func setPublic(): Unit
```

Function: Sets the access level of this global value to public.

Example:

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

Output:

```text
func_setPublic: true
```

### func setStatic(Bool)

```cangjie
public func setStatic(enable: Bool): Unit
```

Function: Sets the static-member flag of this global value.

Parameters:

- enable: Bool - true marks as a static member, false clears the mark.

Example:

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

Output:

```text
func_setStatic: true
```

### operator func ==(GlobalValue)

```cangjie
public operator func ==(other: GlobalValue): Bool
```

Function: Reference comparison, checks whether two GlobalValue instances are identical.

Parameters:

- other: [GlobalValue](#class-globalvalue) - The other global value.

Return Value:

- Bool - Whether the references are identical.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("op_eq_GlobalValue: ${f == f}")
}
```

Output:

```text
op_eq_GlobalValue: true
```

## class Function

```cangjie
public class Function <: GlobalValue & Equatable<Function> {}
```

Function: Represents a **function definition** in CHIR, containing function type, parameters, body (BlockGroup), generic type parameters, and abstract/open attribute markers.

Parent Types:

- GlobalValue
- Equatable\<Function>

### prop body

```cangjie
public prop body: ?BlockGroup
```

Function: Function body; `None` when not initialized.

Type: ?[BlockGroup](#class-blockgroup)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_body: ${f.body.isNone()}")
}
```

Output:

```text
prop_body: true
```

### prop funcSrcCodeType

```cangjie
public prop funcSrcCodeType: FuncType
```

Function: Source-level function type; for instance member methods, the implicit `this` parameter type is excluded; otherwise identical to `funcType`.

Type: [FuncType](#class-functype)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    println("prop_funcSrcCodeType: ${f.funcSrcCodeType == f.funcType}")
}
```

Output:

```text
prop_funcSrcCodeType: true
```

### prop funcType

```cangjie
public prop funcType: FuncType
```

Function: Function type (including parameter types and return type).

Type: [FuncType](#class-functype)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("prop_funcType: ${f.funcType.toString()}")
}
```

Output:

```text
prop_funcType: () -> Unit
```

### prop genericTypeParams

```cangjie
public mut prop genericTypeParams: Array<GenericType>
```

Function: Generic type parameters; assignment automatically updates the `Generic` attribute marker (marked as generic when non-empty).

Type: Array\<[GenericType](#class-generictype)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("mut_prop_genericTypeParams: ${f.genericTypeParams.size}")
}
```

Output:

```text
mut_prop_genericTypeParams: 0
```

### prop parameters

```cangjie
public prop parameters: Array<Parameter>
```

Function: Parameter list.

Type: Array\<[Parameter](#class-parameter)>

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([IntType.getInt32()], UnitType.get()), "f_m", "f", "demo")
    println("prop_parameters: ${f.parameters.size}")
}
```

Output:

```text
prop_parameters: 1
```

### prop returnValue

```cangjie
public mut prop returnValue: ?LocalVar
```

Function: Return value local variable; assignment automatically updates the `isRetValue` marker on the old and new LocalVars.

Type: ?[LocalVar](#class-localvar)

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("mut_prop_returnValue: ${f.returnValue.isNone()}")
}
```

Output:

```text
mut_prop_returnValue: true
```

### func initBody()

```cangjie
public func initBody(): Unit
```

Function: Initializes the function body, creating the entry BlockGroup and Block.

Example:

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

Output:

```text
fn_initBody: true
```

### func isAbstract()

```cangjie
public func isAbstract(): Bool
```

Function: Whether this is an abstract function (with `abstract` marker or a method belonging to an interface).

Return Value:

- Bool - Whether it is abstract.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isAbstract: ${f.isAbstract()}")
}
```

Output:

```text
fn_isAbstract: false
```

### func isDeclaredInCurPackage()

```cangjie
public func isDeclaredInCurPackage(): Bool
```

Function: Whether this is declared in the current package (opposite of `isImported()`).

Return Value:

- Bool - Whether it is declared in this package.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isDeclaredInCurPackage: ${f.isDeclaredInCurPackage()}")
}
```

Output:

```text
fn_isDeclaredInCurPackage: true
```

### func isGeneric()

```cangjie
public func isGeneric(): Bool
```

Function: Whether this is a generic function.

Return Value:

- Bool - Whether it has the generic marker.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isGeneric: ${f.isGeneric()}")
}
```

Output:

```text
fn_isGeneric: false
```

### func isInstanceMemberMethod()

```cangjie
public func isInstanceMemberMethod(): Bool
```

Function: Whether this is an instance member method (has `declaredParent` and is not static).

Return Value:

- Bool - Whether it is an instance member method.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isInstanceMemberMethod: ${f.isInstanceMemberMethod()}")
}
```

Output:

```text
fn_isInstanceMemberMethod: false
```

### func isMemberMethod()

```cangjie
public func isMemberMethod(): Bool
```

Function: Whether this is a member method (instance or static), i.e. whether it has `declaredParent`.

Return Value:

- Bool - Whether it is a member method.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isMemberMethod: ${f.isMemberMethod()}")
}
```

Output:

```text
fn_isMemberMethod: false
```

### func isOpen()

```cangjie
public func isOpen(): Bool
```

Function: Whether this is an open/virtual function (can be overridden by subclasses).

Return Value:

- Bool - Whether it is open.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isOpen: ${f.isOpen()}")
}
```

Output:

```text
fn_isOpen: false
```

### func isSrcCodeImported()

```cangjie
public func isSrcCodeImported(): Bool
```

Function: Whether the source code is imported (`isImported()` and already has a function body).

Return Value:

- Bool - Whether it is imported and already has a body.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isSrcCodeImported: ${f.isSrcCodeImported()}")
}
```

Output:

```text
fn_isSrcCodeImported: false
```

### func isStaticMemberMethod()

```cangjie
public func isStaticMemberMethod(): Bool
```

Function: Whether this is a static member method (has `declaredParent` and is static).

Return Value:

- Bool - Whether it is a static member method.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_isStaticMemberMethod: ${f.isStaticMemberMethod()}")
}
```

Output:

```text
fn_isStaticMemberMethod: false
```

### func moveBodyTo(Function)

```cangjie
public func moveBodyTo(other: Function): Unit
```

Function: Moves the function body, parameters, generic type parameters, and return value to another function; after calling, the above contents of this function are cleared.

Parameters:

- other: Function - Target function.

Example:

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

Output:

```text
fn_moveBodyTo_src: true
fn_moveBodyTo_dst: true
```

### func selfOrParentIsGeneric()

```cangjie
public func selfOrParentIsGeneric(): Bool
```

Function: Whether this function or its parent definition is generic.

Return Value:

- Bool - Whether it is in a generic context.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_selfOrParentIsGeneric: ${f.selfOrParentIsGeneric()}")
}
```

Output:

```text
fn_selfOrParentIsGeneric: false
```

### func setAbstract(Bool)

```cangjie
public func setAbstract(enable: Bool): Unit
```

Function: Sets or clears the `abstract` marker.

Parameters:

- enable: Bool - `true` marks as abstract, `false` clears the marker.

Example:

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

Output:

```text
fn_setAbstract: true
```

### func setOpen(Bool)

```cangjie
public func setOpen(enable: Bool): Unit
```

Function: Sets or clears the `open` (virtual) marker.

Parameters:

- enable: Bool - `true` marks as open, `false` clears the marker.

Example:

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

Output:

```text
fn_setOpen: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form of the function (including identifier, type, parameters, etc.).

Return Value:

- String - Textual form.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("fn_toString: ${f.toString().size > 0}")
}
```

Output:

```text
fn_toString: true
```

### operator func ==(Function)

```cangjie
public operator func ==(other: Function): Bool
```

Function: Reference comparison, determines whether two Functions are the same instance.

Parameters:

- other: Function - Another function.

Return Value:

- Bool - Whether they are the same reference.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let f = pkg.addFunction(FuncType.get([], UnitType.get()), "f_m", "f", "demo")
    println("op_eq_Function: ${f == f}")
}
```

Output:

```text
op_eq_Function: true
```

## class GlobalVar

```cangjie
public class GlobalVar <: GlobalValue & Equatable<GlobalVar> {}
```

Function: Represents a **global variable definition** in CHIR, containing type, initializer value, and read-only marker.

Parent Types:

- GlobalValue
- Equatable\<GlobalVar>

### prop initializer

```cangjie
public prop initializer: ?Value
```

Function: Initializer value; `None` when not set.

Type: ?Value

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("prop_initializer: ${gv.initializer.isNone()}")
}
```

Output:

```text
prop_initializer: true
```

### func isReadOnly()

```cangjie
public func isReadOnly(): Bool
```

Function: Whether this is a read-only global variable (corresponding to a `let` declaration in source code).

Return Value:

- Bool - Whether it is read-only.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("fn_isReadOnly: ${gv.isReadOnly()}")
}
```

Output:

```text
fn_isReadOnly: false
```

### func isSrcCodeImported()

```cangjie
public func isSrcCodeImported(): Bool
```

Function: Whether the source code is imported (`isImported()` and already has an initializer value).

Return Value:

- Bool - Whether it is imported and already initialized.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("fn_isSrcCodeImported: ${gv.isSrcCodeImported()}")
}
```

Output:

```text
fn_isSrcCodeImported: false
```

### func setInitializer(Value)

```cangjie
public func setInitializer(initializer: Value): Unit
```

Function: Sets the initializer value.

Parameters:

- initializer: Value - Initializer value (can be a literal or function reference).

Example:

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

Output:

```text
fn_setInitializer: true
```

### func setReadOnly(Bool)

```cangjie
public func setReadOnly(enable: Bool): Unit
```

Function: Sets or clears the read-only marker.

Parameters:

- enable: Bool - `true` marks as read-only, `false` clears the marker.

Example:

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

Output:

```text
fn_setReadOnly: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form of the global variable (including attributes, type, initializer value, etc.).

Return Value:

- String - Textual form.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("fn_toString: ${gv.toString().size > 0}")
}
```

Output:

```text
fn_toString: true
```

### operator func ==(GlobalVar)

```cangjie
public operator func ==(other: GlobalVar): Bool
```

Function: Reference comparison, determines whether two GlobalVars are the same instance.

Parameters:

- other: GlobalVar - Another global variable.

Return Value:

- Bool - Whether they are the same reference.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let gv = pkg.addGlobalVar(IntType.getInt32(), "gv_m", "gv", "demo")
    println("op_eq_GlobalVar: ${gv == gv}")
}
```

Output:

```text
op_eq_GlobalVar: true
```

## class IntLiteral

```cangjie
public class IntLiteral <: LiteralValue & Equatable<IntLiteral> {}
```

Function: Represents an integer literal, cached by `(IntType, UInt64)` to ensure the same type and value correspond to a unique instance.

Parent Types:

- LiteralValue
- Equatable\<IntLiteral>

### prop signedValue

```cangjie
public prop signedValue: Int64
```

Function: Signed integer value (converts internal `UInt64` to `Int64`).

Type: Int64

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getInt32(), 42)
    println("prop_signedValue: ${lit.signedValue}")
}
```

Output:

```text
prop_signedValue: 42
```

### prop unsignedValue

```cangjie
public prop unsignedValue: UInt64
```

Function: Unsigned integer value.

Type: UInt64

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getUInt32(), 42)
    println("prop_unsignedValue: ${lit.unsignedValue}")
}
```

Output:

```text
prop_unsignedValue: 42
```

### static func get(IntType, UInt64)

```cangjie
public static func get(ty: IntType, value: UInt64): IntLiteral
```

Function: Gets an integer literal; the same type and value combination always returns the same cached instance.

Parameters:

- ty: IntType - Integer type.
- value: UInt64 - Unsigned integer value.

Return Value:

- [IntLiteral](#class-intliteral) - The corresponding integer literal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getInt64(), 100)
    println(lit.toString())
}
```

Output:

```text
100i
```

### func isSigned()

```cangjie
public func isSigned(): Bool
```

Function: Whether this is a signed integer (determined by the owning `IntType`).

Return Value:

- Bool - Whether it is signed.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getInt32(), 0)
    println("fn_isSigned: ${lit.isSigned()}")
}
```

Output:

```text
fn_isSigned: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form, suffixed with `"i"` when signed, `"u"` when unsigned (e.g. `42i`, `42u`).

Return Value:

- String - Textual form of the integer value.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = IntLiteral.get(IntType.getUInt16(), 7)
    println(lit.toString())
}
```

Output:

```text
7u
```

### operator func ==(IntLiteral)

```cangjie
public operator func ==(other: IntLiteral): Bool
```

Function: Reference comparison, determines whether two IntLiterals are the same instance.

Parameters:

- other: IntLiteral - Another integer literal.

Return Value:

- Bool - Whether they are the same reference.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = IntLiteral.get(IntType.getInt32(), 10)
    let lit2 = IntLiteral.get(IntType.getInt32(), 10)
    println("op_eq_IntLiteral: ${lit1 == lit2}")
}
```

Output:

```text
op_eq_IntLiteral: true
```

## class LocalVar

```cangjie
public class LocalVar <: Value & Equatable<LocalVar> {}
```

Function: Represents a **local variable** in CHIR, produced by expression results, and can also serve as a function return value.

Parent Types:

- Value
- Equatable\<LocalVar>

### prop expr

```cangjie
public prop expr: Expression
```

Function: The expression that defines this local variable.

Type: Expression

Example:

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

Output:

```text
prop_expr: true
```

### prop srcCodeName

```cangjie
public mut prop srcCodeName: String
```

Function: Source code name; initially an empty string.

Type: String

Example:

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

Output:

```text
mut_prop_srcCodeName: x
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

Function: The owning top-level function.

Type: [Function](#class-function)

Example:

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

Output:

```text
prop_topLevelFunc: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form of the local variable (equivalent to the `toString()` of its defining expression).

Return Value:

- String - Textual form.

Example:

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

Output:

```text
fn_toString: true
```

### operator func ==(LocalVar)

```cangjie
public operator func ==(other: LocalVar): Bool
```

Function: Reference comparison, determines whether two LocalVars are the same instance.

Parameters:

- other: LocalVar - Another local variable.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_LocalVar: true
```

## class NullLiteral

```cangjie
public class NullLiteral <: LiteralValue & Equatable<NullLiteral> {}
```

Function: Represents a Null literal, cached by type to ensure the same type corresponds to a unique instance.

Parent Types:

- LiteralValue
- Equatable\<NullLiteral>

### static func get(Type)

```cangjie
public static func get(ty: Type): NullLiteral
```

Function: Gets a Null literal for the specified type; the same type always returns the same cached instance.

Parameters:

- ty: Type - The type of Null.

Return Value:

- [NullLiteral](#class-nullliteral) - Null literal instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = NullLiteral.get(BoxType.get(IntType.getInt32()))
    println(lit.toString())
}
```

Output:

```text
Null
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form, always `"Null"`.

Return Value:

- String - `"Null"`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = NullLiteral.get(BoxType.get(IntType.getInt32()))
    println(lit.toString())
}
```

Output:

```text
Null
```

### operator func ==(NullLiteral)

```cangjie
public operator func ==(other: NullLiteral): Bool
```

Function: Reference comparison, determines whether two NullLiterals are the same instance.

Parameters:

- other: NullLiteral - Another Null literal.

Return Value:

- Bool - Whether they are the same reference.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = NullLiteral.get(BoxType.get(IntType.getInt32()))
    let lit2 = NullLiteral.get(BoxType.get(IntType.getInt32()))
    println("op_eq_NullLiteral: ${lit1 == lit2}")
}
```

Output:

```text
op_eq_NullLiteral: true
```

## class Parameter

```cangjie
public class Parameter <: Value & Equatable<Parameter> {}
```

Function: Represents a **function parameter** in CHIR, containing type, source code name, annotations, and other information.

Parent Types:

- Value
- Equatable\<Parameter>

### prop customAnnoInstances

```cangjie
public mut prop customAnnoInstances: Array<CustomAnnoInstance>
```

Function: Parameter annotation instance list; getter returns the current list, setter replaces the entire list.

Type: Array\<[CustomAnnoInstance](#class-customannoinstance)>

Example:

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

Output:

```text
mut_prop_customAnnoInstances: 0
```

### prop srcCodeName

```cangjie
public mut prop srcCodeName: String
```

Function: Parameter source code name; initially an empty string.

Type: String

Example:

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

Output:

```text
mut_prop_srcCodeName: x
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

Function: The owning top-level function.

Type: [Function](#class-function)

Example:

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

Output:

```text
prop_topLevelFunc: true
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form of the parameter (including type, annotations, etc.).

Return Value:

- String - Textual form.

Example:

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

Output:

```text
fn_toString: true
```

### operator func ==(Parameter)

```cangjie
public operator func ==(other: Parameter): Bool
```

Function: Reference comparison, determines whether two Parameters are the same instance.

Parameters:

- other: Parameter - Another parameter.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Parameter: true
```

## class RuneLiteral

```cangjie
public class RuneLiteral <: LiteralValue & Equatable<RuneLiteral> {}
```

Function: Represents a Rune (character) literal, cached by value to ensure the same Rune value corresponds to a unique instance.

Parent Types:

- LiteralValue
- Equatable\<RuneLiteral>

### prop value

```cangjie
public prop value: Rune
```

Function: Rune value (Unicode code point).

Type: Rune

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = RuneLiteral.get(Rune(65))
    println("prop_value: ${lit.value}")
}
```

Output:

```text
prop_value: A
```

### static func get(Rune)

```cangjie
public static func get(value: Rune): RuneLiteral
```

Function: Gets a Rune literal; the same Rune value always returns the same cached instance.

Parameters:

- value: Rune - Rune value.

Return Value:

- [RuneLiteral](#class-runeliteral) - The corresponding Rune literal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = RuneLiteral.get(Rune(97))
    println(lit.toString())
}
```

Output:

```text
'a'
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form, a single-quoted character representation (e.g. `'A'`).

Return Value:

- String - Textual form of the Rune value.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = RuneLiteral.get(Rune(48))
    println(lit.toString())
}
```

Output:

```text
'0'
```

### operator func ==(RuneLiteral)

```cangjie
public operator func ==(other: RuneLiteral): Bool
```

Function: Reference comparison, determines whether two RuneLiterals are the same instance.

Parameters:

- other: RuneLiteral - Another Rune literal.

Return Value:

- Bool - Whether they are the same reference.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = RuneLiteral.get(Rune(65))
    let lit2 = RuneLiteral.get(Rune(65))
    println("op_eq_RuneLiteral: ${lit1 == lit2}")
}
```

Output:

```text
op_eq_RuneLiteral: true
```

## class StringLiteral

```cangjie
public class StringLiteral <: LiteralValue & Equatable<StringLiteral> {}
```

Function: Represents a string literal, cached by value to ensure the same string value corresponds to a unique instance.

Parent Types:

- LiteralValue
- Equatable\<StringLiteral>

### prop value

```cangjie
public prop value: String
```

Function: String value.

Type: String

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = StringLiteral.get(UnitType.get(), "hello")
    println("prop_value: ${lit.value}")
}
```

Output:

```text
prop_value: hello
```

### static func get(Type, String)

```cangjie
public static func get(ty: Type, value: String): StringLiteral
```

Function: Gets a string literal; the same string value always returns the same cached instance.

Parameters:

- ty: Type - The type the string belongs to.
- value: String - String content.

Return Value:

- [StringLiteral](#class-stringliteral) - The corresponding string literal.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = StringLiteral.get(UnitType.get(), "world")
    println(lit.toString())
}
```

Output:

```text
"world"
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form, wrapped in double quotes (e.g. `"hello"`).

Return Value:

- String - Textual form of the string value.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = StringLiteral.get(UnitType.get(), "abc")
    println(lit.toString())
}
```

Output:

```text
"abc"
```

### operator func ==(StringLiteral)

```cangjie
public operator func ==(other: StringLiteral): Bool
```

Function: Reference comparison, determines whether two StringLiterals are the same instance.

Parameters:

- other: StringLiteral - Another string literal.

Return Value:

- Bool - Whether they are the same reference.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = StringLiteral.get(UnitType.get(), "test")
    let lit2 = StringLiteral.get(UnitType.get(), "test")
    println("op_eq_StringLiteral: ${lit1 == lit2}")
}
```

Output:

```text
op_eq_StringLiteral: true
```

## class UnitLiteral

```cangjie
public class UnitLiteral <: LiteralValue & Equatable<UnitLiteral> {}
```

Function: Represents a Unit literal (singleton, denoting no return value).

Parent Types:

- LiteralValue
- Equatable\<UnitLiteral>

### static func get()

```cangjie
public static func get(): UnitLiteral
```

Function: Gets the singleton instance of the Unit literal.

Return Value:

- [UnitLiteral](#class-unitliteral) - Unit literal instance.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = UnitLiteral.get()
    println(lit.toString())
}
```

Output:

```text
Unit
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form, always `"Unit"`.

Return Value:

- String - `"Unit"`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit = UnitLiteral.get()
    println(lit.toString())
}
```

Output:

```text
Unit
```

### operator func ==(UnitLiteral)

```cangjie
public operator func ==(other: UnitLiteral): Bool
```

Function: Reference comparison, determines whether two UnitLiterals are the same instance.

Parameters:

- other: UnitLiteral - Another Unit literal.

Return Value:

- Bool - Whether they are the same reference.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let lit1 = UnitLiteral.get()
    let lit2 = UnitLiteral.get()
    println("op_eq_UnitLiteral: ${lit1 == lit2}")
}
```

Output:

```text
op_eq_UnitLiteral: true
```

</task_result>

## class Expression

```cangjie
sealed abstract class Expression <: ToString & Hashable & Equatable<Expression> {}
```

Function: Abstract base class of all CHIR expressions. An expression is the instruction unit inside a basic block; it holds the operand list, owning block, result local variable and attached block groups, and provides move, destroy, result-query and type-testing capabilities.

Parent Types:

- ToString
- Hashable
- Equatable\<[Expression](#class-expression)>

### prop blockGroups

```cangjie
public prop blockGroups: Array<BlockGroup>
```

Function: List of block groups attached to this expression.

Type: Array\<[BlockGroup](#class-blockgroup)>

Example:

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

Output:

```text
prop_blockGroups: 0
```

### prop operands

```cangjie
public prop operands: Array<Value>
```

Function: Ordered operand list of this expression.

Type: Array\<[Value](#class-value)>

Example:

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

Output:

```text
prop_operands: 0
```

### prop owner

```cangjie
public prop owner: Block
```

Function: Basic block that contains this expression; throws when not set.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_owner: true
```

### prop result

```cangjie
public prop result: LocalVar
```

Function: Result local variable produced by this expression; throws when not set.

Type: [LocalVar](#class-localvar)

Example:

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

Output:

```text
prop_result: Int32
```

### prop successors

```cangjie
public prop successors: Array<Block>
```

Function: List of successor blocks referenced by this expression's operands.

Type: Array\<[Block](#class-block)>

Example:

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

Output:

```text
prop_successors: 0
```

### prop topLevelFunc

```cangjie
public prop topLevelFunc: Function
```

Function: Top-level function this expression belongs to.

Type: [Function](#class-function)

Example:

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

Output:

```text
prop_topLevelFunc: true
```

### func destroySelf(Bool)

```cangjie
public func destroySelf(removeFromOwner!: Bool = true): Unit
```

Function: Destroys this expression, detaching all use/ownership relations with its operands, owning block and attached block groups; marks the internal `kind` as `Invalid`.

Parameters:

- removeFromOwner!: Bool - Whether to remove this expression from the owning block's `exprs` list. Defaults to `true`. Pass `false` when the owner clears the list itself during cascading destruction.

Example:

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

Output:

```text
func_destroySelf: 0
```

### func dump()

```cangjie
public func dump(): Unit
```

Function: Prints the string representation of the expression to standard output.

Example:

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

Function: Checks whether this expression carries normal/error branch operands (e.g. TryApply, TryInvoke).

Return Value:

- Bool - Returns true when it carries an exception branch, false otherwise.

Example:

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

Output:

```text
func_hasExceptionBranch: false
```

### func hashCode()

```cangjie
public func hashCode(): Int64
```

Function: Computes the hash code of this expression from its result value.

Return Value:

- Int64 - Hash code of the expression.

Example:

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

Output:

```text
func_hashCode: true
```

### func isTerminator()

```cangjie
public func isTerminator(): Bool
```

Function: Checks whether this expression is a terminator (e.g. Branch, Exit, GoTo).

Return Value:

- Bool - Returns true when it is a terminator, false otherwise.

Example:

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

Output:

```text
func_isTerminator: false
```

### func isLambda()

```cangjie
public func isLambda(): Bool
```

Function: Checks whether this expression is a Lambda expression.

Return Value:

- Bool - Returns true when it is a Lambda expression, false otherwise.

Example:

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

Output:

```text
func_isLambda: false
```

### func isExit()

```cangjie
public func isExit(): Bool
```

Function: Checks whether this expression is an Exit expression.

Return Value:

- Bool - Returns true when it is an Exit expression, false otherwise.

Example:

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

Output:

```text
func_isExit: false
```

### func moveAfter(Expression)

```cangjie
public func moveAfter(other: Expression): Unit
```

Function: Moves this expression right after another expression; cannot be moved after a terminator.

Parameters:

- other: [Expression](#class-expression) - The anchor expression.

Example:

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

Output:

```text
func_moveAfter: true
```

### func moveBefore(Expression)

```cangjie
public func moveBefore(other: Expression): Unit
```

Function: Moves this expression right before another expression; a terminator cannot be moved in front of another expression.

Parameters:

- other: [Expression](#class-expression) - The anchor expression.

Example:

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

Output:

```text
func_moveBefore: true
```

### func replaceOperand(Value, Value)

```cangjie
public func replaceOperand(operand: Value, other: Value): Unit
```

Function: Replaces a specified operand of this expression with another value.

Parameters:

- operand: [Value](#class-value) - The operand to be replaced.
- other: [Value](#class-value) - The new value to replace with.

Example:

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

Output:

```text
func_replaceOperand: true
```

### func toString()

```cangjie
public open func toString(): String
```

Function: Builds the readable string representation of this expression.

Return Value:

- String - Readable text of the expression.

Example:

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

Output:

```text
func_toString: false
```

### func tryGetResult()

```cangjie
public func tryGetResult(): Option<LocalVar>
```

Function: Tries to get the result local variable of this expression; returns `None` when not set.

Return Value:

- Option\<[LocalVar](#class-localvar)> - The result local variable, or `None` when not set.

Example:

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

Output:

```text
func_tryGetResult: true
```

### operator func ==(Expression)

```cangjie
public operator func ==(other: Expression): Bool
```

Function: Reference comparison, checks whether two Expression instances are identical.

Parameters:

- other: [Expression](#class-expression) - The other expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_Expression: true
```

## class AllocateBase

```cangjie
sealed abstract class AllocateBase <: Expression & Equatable<AllocateBase> {}
```

Function: Abstract base class of memory-allocation expressions; provides the allocated type, parent type of [Allocate](#class-allocate) and [TryAllocate](#class-tryallocate).

Parent Types:

- [Expression](#class-expression)
- Equatable\<[AllocateBase](#class-allocatebase)>

### prop allocatedType

```cangjie
public prop allocatedType: Type
```

Function: Type allocated by this allocation expression.

Type: [Type](#class-type)

Example:

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

Output:

```text
prop_allocatedType: Int32
```

### operator func ==(AllocateBase)

```cangjie
public operator func ==(other: AllocateBase): Bool
```

Function: Reference comparison, checks whether two AllocateBase instances are identical.

Parameters:

- other: [AllocateBase](#class-allocatebase) - The other allocation-base expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_AllocateBase: true
```

## class Allocate

```cangjie
public class Allocate <: AllocateBase & Equatable<Allocate> {}
```

Function: Memory allocation expression, allocating space for the specified type without exception handling.

Parent Types:

- AllocateBase
- Equatable\<Allocate>

### static func create(Type)

```cangjie
public static func create(allocatedType: Type): Allocate
```

Function: Creates a memory allocation expression.

Parameters:

- allocatedType: Type - The type to allocate.

Return Value:

- [Allocate](#class-allocate) - The created memory allocation expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(Allocate)

```cangjie
public operator func ==(other: Allocate): Bool
```

Function: Reference comparison, determines whether two Allocate instances are the same.

Parameters:

- other: Allocate - Another memory allocation expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Allocate: true
```

## class TryAllocate

```cangjie
public class TryAllocate <: AllocateBase & Equatable<TryAllocate> {}
```

Function: Memory allocation expression with exception handling; jumps to the normal branch on success and to the error branch on failure.

Parent Types:

- AllocateBase
- Equatable\<TryAllocate>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

Function: Normal branch target block.

Type: Block

Example:

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

Output:

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

Function: Error branch target block.

Type: Block

Example:

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

Output:

```text
prop_errorBranch: true
```

### static func create(Type, Block, Block)

```cangjie
public static func create(allocatedType: Type, normal: Block, err: Block): TryAllocate
```

Function: Creates a memory allocation expression with exception handling.

Parameters:

- allocatedType: Type - The type to allocate.
- normal: Block - Normal branch target block.
- err: Block - Error branch target block.

Return Value:

- [TryAllocate](#class-tryallocate) - The created memory allocation expression with exception handling.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(TryAllocate)

```cangjie
public operator func ==(other: TryAllocate): Bool
```

Function: Reference comparison, determines whether two TryAllocate instances are the same.

Parameters:

- other: TryAllocate - Another memory allocation expression with exception handling.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_TryAllocate: true
```

## class BinaryExpressionBase

```cangjie
sealed abstract class BinaryExpressionBase <: Expression & Equatable<BinaryExpressionBase> {}
```

Function: Abstract base class of binary expressions ([BinaryExpression](#class-binaryexpression), [TryBinaryExpression](#class-trybinaryexpression), etc.); provides query and set of the overflow strategy.

Parent Types:

- [Expression](#class-expression)
- Equatable\<[BinaryExpressionBase](#class-binaryexpressionbase)>

### prop overflow

```cangjie
public mut prop overflow: OverflowStrategy
```

Function: Overflow strategy used by this binary expression; readable and writable, defaults to [OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy).NA.

Type: [OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy)

Example:

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

Output:

```text
prop_overflow: Throwing
```

### operator func ==(BinaryExpressionBase)

```cangjie
public operator func ==(other: BinaryExpressionBase): Bool
```

Function: Reference comparison, checks whether two BinaryExpressionBase instances are identical.

Parameters:

- other: [BinaryExpressionBase](#class-binaryexpressionbase) - The other binary-expression-base expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_BinaryExpressionBase: true
```

## class BinaryExpression

```cangjie
public class BinaryExpression <: BinaryExpressionBase & Equatable<BinaryExpression> {}
```

Function: Binary operation expression (without exception handling), supporting arithmetic, bitwise, comparison, and logical operations.

Parent Types:

- BinaryExpressionBase
- Equatable\<BinaryExpression>

### static func create(BinaryExprKind, Value, Value)

```cangjie
public static func create(kind: BinaryExprKind, leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a binary operation expression.

Parameters:

- kind: BinaryExprKind - The binary operation type.
- leftOp: Value - The left operand.
- rightOp: Value - The right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - The created binary operation expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(BinaryExpression)

```cangjie
public operator func ==(other: BinaryExpression): Bool
```

Function: Reference comparison, determines whether two BinaryExpression instances are the same.

Parameters:

- other: BinaryExpression - Another binary operation expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_BinaryExpression: true
```

## class TryBinaryExpression

```cangjie
public class TryBinaryExpression <: BinaryExpressionBase & Equatable<TryBinaryExpression> {}
```

Function: Binary operation expression with exception handling; jumps to the normal branch on success and to the error branch on overflow or error.

Parent Types:

- BinaryExpressionBase
- Equatable\<TryBinaryExpression>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

Function: Normal branch target block.

Type: Block

Example:

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

Output:

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

Function: Error branch target block.

Type: Block

Example:

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

Output:

```text
prop_errorBranch: true
```

### static func create(BinaryExprKind, Value, Value, Block, Block)

```cangjie
public static func create(kind: BinaryExprKind, leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

Function: Creates a binary operation expression with exception handling.

Parameters:

- kind: BinaryExprKind - The binary operation type.
- leftOp: Value - The left operand.
- rightOp: Value - The right operand.
- normal: Block - Normal branch target block.
- err: Block - Error branch target block.

Return Value:

- [TryBinaryExpression](#class-trybinaryexpression) - The created binary operation expression with exception handling.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(TryBinaryExpression)

```cangjie
public operator func ==(other: TryBinaryExpression): Bool
```

Function: Reference comparison, determines whether two TryBinaryExpression instances are the same.

Parameters:

- other: TryBinaryExpression - Another binary operation expression with exception handling.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_TryBinaryExpression: true
```

## class Branch

```cangjie
public class Branch <: Expression & Equatable<Branch> {}
```

Function: Conditional branch (if-else) terminator expression, jumping to the true or false target block based on the condition value.

Parent Types:

- Expression
- Equatable\<Branch>

### prop condition

```cangjie
public prop condition: Value
```

Function: Condition value.

Type: Value

Example:

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

Output:

```text
prop_condition: true
```

### prop trueTarget

```cangjie
public prop trueTarget: Block
```

Function: Target block when the condition is true.

Type: Block

Example:

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

Output:

```text
prop_trueTarget: true
```

### prop falseTarget

```cangjie
public prop falseTarget: Block
```

Function: Target block when the condition is false.

Type: Block

Example:

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

Output:

```text
prop_falseTarget: true
```

### static func create(Value, Block, Block)

```cangjie
public static func create(condition: Value, trueTarget: Block, falseTarget: Block): Branch
```

Function: Creates a conditional branch terminator expression.

Parameters:

- condition: Value - Condition value.
- trueTarget: Block - Target block when the condition is true.
- falseTarget: Block - Target block when the condition is false.

Return Value:

- [Branch](#class-branch) - The created conditional branch expression.

Example:

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

Output:

```text
static_func_create: 2
```

### operator func ==(Branch)

```cangjie
public operator func ==(other: Branch): Bool
```

Function: Reference comparison, determines whether two Branch instances are the same.

Parameters:

- other: Branch - Another conditional branch expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Branch: true
```

## class Constant

```cangjie
public class Constant <: Expression & Equatable<Constant> {}
```

Function: Literal constant expression, representing a compile-time determined constant value.

Parent Types:

- Expression
- Equatable\<Constant>

### static func create(LiteralValue)

```cangjie
public static func create(val: LiteralValue): Constant
```

Function: Creates a literal constant expression.

Parameters:

- val: LiteralValue - The literal value.

Return Value:

- [Constant](#class-constant) - The created constant expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(Constant)

```cangjie
public operator func ==(other: Constant): Bool
```

Function: Reference comparison, determines whether two Constant instances are the same.

Parameters:

- other: Constant - Another constant expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Constant: true
```

## class Debug

```cangjie
public class Debug <: Expression & Equatable<Debug> {}
```

Function: Debug marker expression, storing source code position mapping information, used to associate values in the IR with variable names in the source code.

Parent Types:

- Expression
- Equatable\<Debug>

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

Function: Source code debug name.

Type: String

Example:

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

Output:

```text
prop_srcCodeName: var_x
```

### static func create(Value, String)

```cangjie
public static func create(location: Value, srcName: String): Debug
```

Function: Creates a debug marker expression.

Parameters:

- location: Value - The value to mark.
- srcName: String - Source code debug name.

Return Value:

- [Debug](#class-debug) - The created debug marker expression.

Example:

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

Output:

```text
static_func_create: 2
```

### operator func ==(Debug)

```cangjie
public operator func ==(other: Debug): Bool
```

Function: Reference comparison, determines whether two Debug instances are the same.

Parameters:

- other: Debug - Another debug marker expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Debug: true
```

## class Exit

```cangjie
public class Exit <: Expression & Equatable<Exit> {}
```

Function: Function exit terminator expression, indicating normal function execution completion.

Parent Types:

- Expression
- Equatable\<Exit>

### static func create()

```cangjie
public static func create(): Exit
```

Function: Creates a function exit terminator expression.

Return Value:

- [Exit](#class-exit) - The created exit expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(Exit)

```cangjie
public operator func ==(other: Exit): Bool
```

Function: Reference comparison, determines whether two Exit instances are the same.

Parameters:

- other: Exit - Another exit expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Exit: true
```

## class Field

```cangjie
public class Field <: Expression & Equatable<Field> {}
```

Function: Field access expression by numeric index path, locating a sub-field within an aggregate through a sequence of numeric indices.

Parent Types:

- Expression
- Equatable\<Field>

### prop path

```cangjie
public prop path: Array<UInt64>
```

Function: Numeric index path of the field.

Type: Array\<UInt64>

Example:

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

Output:

```text
prop_path: 1
```

### static func create(Value, ArrayList\<UInt64>)

```cangjie
public static func create(location: Value, path: ArrayList<UInt64>): Field
```

Function: Creates a field access expression by numeric index path.

Parameters:

- location: Value - Source aggregate value.
- path: ArrayList\<UInt64> - Numeric index path of the field.

Return Value:

- [Field](#class-field) - The created field access expression.

Example:

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

Output:

```text
static_func_create: 2
```

### operator func ==(Field)

```cangjie
public operator func ==(other: Field): Bool
```

Function: Reference comparison, determines whether two Field instances are the same.

Parameters:

- other: Field - Another field access expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Field: true
```

## class FieldByName

```cangjie
public class FieldByName <: Expression & Equatable<FieldByName> {}
```

Function: Field access expression by field name path, locating a sub-field within an aggregate through a sequence of string field names.

Parent Types:

- Expression
- Equatable\<FieldByName>

### prop fieldNames

```cangjie
public prop fieldNames: Array<String>
```

Function: Field name path.

Type: Array\<String>

Example:

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

Output:

```text
prop_fieldNames: 1
```

### static func create(Value, ArrayList\<String>)

```cangjie
public static func create(location: Value, fieldNames: ArrayList<String>): FieldByName
```

Function: Creates a field access expression by field name path.

Parameters:

- location: Value - Source aggregate value.
- fieldNames: ArrayList\<String> - Field name path.

Return Value:

- [FieldByName](#class-fieldbyname) - The created field name access expression.

Example:

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

Output:

```text
static_func_create: 2
```

### operator func ==(FieldByName)

```cangjie
public operator func ==(other: FieldByName): Bool
```

Function: Reference comparison, determines whether two FieldByName instances are the same.

Parameters:

- other: FieldByName - Another field name access expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_FieldByName: true
```

## class FuncCall

```cangjie
sealed abstract class FuncCall <: Expression & Equatable<FuncCall> {}
```

Function: Abstract base class of function-call expressions; parent type of [ApplyBase](#class-applybase), [IntrinsicBase](#class-intrinsicbase) and [InvokeBase](#class-invokebase); provides query of instantiated type arguments, object type and argument list.

Parent Types:

- [Expression](#class-expression)
- Equatable\<[FuncCall](#class-funccall)>

### prop instantiatedTypeArgs

```cangjie
public prop instantiatedTypeArgs: Array<Type>
```

Function: Instantiated type argument list of this function-call expression.

Type: Array\<[Type](#class-type)>

Example:

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

Output:

```text
prop_instantiatedTypeArgs: 0
```

### prop objType

```cangjie
public prop objType: ?Type
```

Function: Object type of this function-call expression (the object type for member-method calls); `None` for non-member calls.

Type: ?[Type](#class-type)

Example:

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

Output:

```text
prop_objType: true
```

### func getArgs()

```cangjie
public func getArgs(): Array<Value>
```

Function: Gets the argument list of this function-call expression.

Return Value:

- Array\<[Value](#class-value)> - The argument array.

Example:

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

Output:

```text
func_getArgs: 0
```

### operator func ==(FuncCall)

```cangjie
public operator func ==(other: FuncCall): Bool
```

Function: Reference comparison, checks whether two FuncCall instances are identical.

Parameters:

- other: [FuncCall](#class-funccall) - The other function-call-base expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_FuncCall: true
```

## class ApplyBase

```cangjie
sealed abstract class ApplyBase <: FuncCall & Equatable<ApplyBase> {}
```

Function: Abstract base class of Apply (plain function call) expressions; parent type of [Apply](#class-apply) and [TryApply](#class-tryapply); provides query of the callee value.

Parent Types:

- [FuncCall](#class-funccall)
- Equatable\<[ApplyBase](#class-applybase)>

### prop callee

```cangjie
public prop callee: Value
```

Function: Callee function value.

Type: [Value](#class-value)

Example:

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

Output:

```text
prop_callee: true
```

### operator func ==(ApplyBase)

```cangjie
public operator func ==(other: ApplyBase): Bool
```

Function: Reference comparison, checks whether two ApplyBase instances are identical.

Parameters:

- other: [ApplyBase](#class-applybase) - The other Apply-base expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_ApplyBase: true
```

## class Apply

```cangjie
public class Apply <: ApplyBase & Equatable<Apply> {}
```

Function: Function call (Apply) expression, representing a direct call to a function.

Parent Types:

- ApplyBase
- Equatable\<Apply>

### static func create(Value, FuncCallContext)

```cangjie
public static func create(callee: Value, funcCallCtx: FuncCallContext): Apply
```

Function: Creates a function call expression.

Parameters:

- callee: Value - The callee function value.
- funcCallCtx: FuncCallContext - Function call context (including arguments, generic arguments, and object type).

Return Value:

- [Apply](#class-apply) - The created function call expression.

Example:

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

Output:

```text
static_func_create: 1
```

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

Function: Returns the actual argument list of this call expression.

Return Value:

- Array\<Value> - Array of argument values.

### operator func ==(Apply)

```cangjie
public operator func ==(other: Apply): Bool
```

Function: Reference comparison, determines whether two Apply instances are the same.

Parameters:

- other: Apply - Another function call expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Apply: true
```

## class TryApply

```cangjie
public class TryApply <: ApplyBase & Equatable<TryApply> {}
```

Function: Function call expression with exception handling; jumps to the normal branch on success and to the error branch when an exception is thrown.

Parent Types:

- ApplyBase
- Equatable\<TryApply>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

Function: Normal branch target block.

Type: Block

Example:

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

Output:

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

Function: Error branch target block.

Type: Block

Example:

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

Output:

```text
prop_errorBranch: true
```

### static func create(Value, FuncCallContext, Block, Block)

```cangjie
public static func create(callee: Value, funcCallCtx: FuncCallContext, normal: Block, err: Block): TryApply
```

Function: Creates a function call expression with exception handling.

Parameters:

- callee: Value - The callee function value.
- funcCallCtx: FuncCallContext - Function call context.
- normal: Block - Normal branch target block.
- err: Block - Error branch target block.

Return Value:

- [TryApply](#class-tryapply) - The created function call expression with exception handling.

Example:

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

Output:

```text
static_func_create: 1
```

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

Function: Returns the actual argument list of this call expression.

Return Value:

- Array\<Value> - Array of argument values.

### operator func ==(TryApply)

```cangjie
public operator func ==(other: TryApply): Bool
```

Function: Reference comparison, determines whether two TryApply instances are the same.

Parameters:

- other: TryApply - Another function call expression with exception handling.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_TryApply: true
```

## class IntrinsicBase

```cangjie
sealed abstract class IntrinsicBase <: FuncCall & Equatable<IntrinsicBase> {}
```

Function: Abstract base class of intrinsic function-call expressions; parent type of [Intrinsic](#class-intrinsic) and [TryIntrinsic](#class-tryintrinsic).

Parent Types:

- [FuncCall](#class-funccall)
- Equatable\<[IntrinsicBase](#class-intrinsicbase)>

### operator func ==(IntrinsicBase)

```cangjie
public operator func ==(other: IntrinsicBase): Bool
```

Function: Reference comparison, checks whether two IntrinsicBase instances are identical.

Parameters:

- other: [IntrinsicBase](#class-intrinsicbase) - The other Intrinsic-base expression.

Return Value:

- Bool - Whether the references are identical.

## class Intrinsic

```cangjie
public class Intrinsic <: IntrinsicBase & Equatable<Intrinsic> {}
```

Function: Intrinsic function call expression (without exception handling), representing a call to a compiler intrinsic function (such as `sizeof`, `alignof`, etc.). Intrinsic instances are created by the compiler's internal process and can be accessed by traversing a Block's `exprs` list to find existing Intrinsic expressions.

Parent Types:

- IntrinsicBase
- Equatable\<Intrinsic>

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

Function: Returns the actual argument list of this call expression.

Return Value:

- Array\<Value> - Array of argument values.

### operator func ==(Intrinsic)

```cangjie
public operator func ==(other: Intrinsic): Bool
```

Function: Reference comparison, determines whether two Intrinsic instances are the same.

Parameters:

- other: Intrinsic - Another intrinsic function call expression.

Return Value:

- Bool - Whether they are the same reference.

## class TryIntrinsic

```cangjie
public class TryIntrinsic <: IntrinsicBase & Equatable<TryIntrinsic> {}
```

Function: Intrinsic function call expression with exception handling. TryIntrinsic instances are created by the compiler's internal process and can be accessed by traversing a Block's `exprs` list to find existing TryIntrinsic expressions.

Parent Types:

- IntrinsicBase
- Equatable\<TryIntrinsic>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

Function: Normal branch target block.

Type: Block

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

Function: Error branch target block.

Type: Block

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

Function: Returns the actual argument list of this call expression.

Return Value:

- Array\<Value> - Array of argument values.

### operator func ==(TryIntrinsic)

```cangjie
public operator func ==(other: TryIntrinsic): Bool
```

Function: Reference comparison, determines whether two TryIntrinsic instances are the same.

Parameters:

- other: TryIntrinsic - Another intrinsic function call expression with exception handling.

Return Value:

- Bool - Whether they are the same reference.

## class InvokeBase

```cangjie
sealed abstract class InvokeBase <: FuncCall & Equatable<InvokeBase> {}
```

Function: Abstract base class of Invoke (member-method call) expressions; parent type of [Invoke](#class-invoke) and [TryInvoke](#class-tryinvoke); provides query of method name, method type and method generic type parameters.

Parent Types:

- [FuncCall](#class-funccall)
- Equatable\<[InvokeBase](#class-invokebase)>

### prop methodGenericTypeParams

```cangjie
public prop methodGenericTypeParams: Array<GenericType>
```

Function: Method generic type parameter list of this member-method call.

Type: Array\<[GenericType](#class-generictype)>

Example:

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

Output:

```text
prop_methodGenericTypeParams: 0
```

### prop methodName

```cangjie
public prop methodName: String
```

Function: Method name of this member-method call.

Type: String

Example:

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

Output:

```text
prop_methodName: m
```

### prop methodType

```cangjie
public prop methodType: FuncType
```

Function: Method type of this member-method call.

Type: [FuncType](#class-functype)

Example:

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

Output:

```text
prop_methodType: ()->Unit
```

### operator func ==(InvokeBase)

```cangjie
public operator func ==(other: InvokeBase): Bool
```

Function: Reference comparison, checks whether two InvokeBase instances are identical.

Parameters:

- other: [InvokeBase](#class-invokebase) - The other Invoke-base expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_InvokeBase: true
```

## class Invoke

```cangjie
public class Invoke <: InvokeBase & Equatable<Invoke> {}
```

Function: Virtual method call (Invoke) expression, representing a virtual call to an instance method.

Parent Types:

- InvokeBase
- Equatable\<Invoke>

### static func create(Type, InvokeCallContext)

```cangjie
public static func create(retTy: Type, callContext: InvokeCallContext): Invoke
```

Function: Creates a virtual method call expression.

Parameters:

- retTy: Type - Return type.
- callContext: InvokeCallContext - Virtual method call context.

Return Value:

- [Invoke](#class-invoke) - The created virtual method call expression.

Example:

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

Output:

```text
static_func_create: 1
```

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

Function: Returns the actual argument list of this call expression.

Return Value:

- Array\<Value> - Array of argument values.

### operator func ==(Invoke)

```cangjie
public operator func ==(other: Invoke): Bool
```

Function: Reference comparison, determines whether two Invoke instances are the same.

Parameters:

- other: Invoke - Another virtual method call expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Invoke: true
```

## class TryInvoke

```cangjie
public class TryInvoke <: InvokeBase & Equatable<TryInvoke> {}
```

Function: Virtual method call expression with exception handling; jumps to the normal branch on success and to the error branch when an exception is thrown.

Parent Types:

- InvokeBase
- Equatable\<TryInvoke>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

Function: Normal branch target block.

Type: Block

Example:

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

Output:

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

Function: Error branch target block.

Type: Block

Example:

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

Output:

```text
prop_errorBranch: true
```

### static func create(Type, InvokeCallContext, Block, Block)

```cangjie
public static func create(retTy: Type, callContext: InvokeCallContext, normal: Block, err: Block): TryInvoke
```

Function: Creates a virtual method call expression with exception handling.

Parameters:

- retTy: Type - Return type.
- callContext: InvokeCallContext - Virtual method call context.
- normal: Block - Normal branch target block.
- err: Block - Error branch target block.

Return Value:

- [TryInvoke](#class-tryinvoke) - The created virtual method call expression with exception handling.

Example:

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

Output:

```text
static_func_create: 1
```

### func getArgs()

```cangjie
public override func getArgs(): Array<Value>
```

Function: Returns the actual argument list of this call expression.

Return Value:

- Array\<Value> - Array of argument values.

### operator func ==(TryInvoke)

```cangjie
public operator func ==(other: TryInvoke): Bool
```

Function: Reference comparison, determines whether two TryInvoke instances are the same.

Parameters:

- other: TryInvoke - Another virtual method call expression with exception handling.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_TryInvoke: true
```

## class GetElementByName

```cangjie
public class GetElementByName <: Expression & Equatable<GetElementByName> {}
```

Function: Expression that reads an aggregate element by field name, returning a reference to the element.

Parent Types:

- Expression
- Equatable\<GetElementByName>

### prop fieldNames

```cangjie
public prop fieldNames: Array<String>
```

Function: Field name path.

Type: Array\<String>

Example:

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

Output:

```text
prop_fieldNames: 1
```

### static func create(Value, ArrayList\<String>)

```cangjie
public static func create(location: Value, fieldNames: ArrayList<String>): GetElementByName
```

Function: Creates an expression that reads an aggregate element by field name.

Parameters:

- location: Value - Source aggregate value.
- fieldNames: ArrayList\<String> - Field name path.

Return Value:

- [GetElementByName](#class-getelementbyname) - The created element read expression.

Example:

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

Output:

```text
static_func_create: 2
```

### operator func ==(GetElementByName)

```cangjie
public operator func ==(other: GetElementByName): Bool
```

Function: Reference comparison, determines whether two GetElementByName instances are the same.

Parameters:

- other: GetElementByName - Another element read expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_GetElementByName: true
```

## class GetElementRef

```cangjie
public class GetElementRef <: Expression & Equatable<GetElementRef> {}
```

Function: Expression that reads an aggregate element reference by numeric index, returning a reference to the element.

Parent Types:

- Expression
- Equatable\<GetElementRef>

### prop path

```cangjie
public prop path: Array<UInt64>
```

Function: Index path.

Type: Array\<UInt64>

Example:

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

Output:

```text
prop_path: 1
```

### static func create(Value, ArrayList\<UInt64>)

```cangjie
public static func create(location: Value, path: ArrayList<UInt64>): GetElementRef
```

Function: Creates an expression that reads an aggregate element reference by numeric index.

Parameters:

- location: Value - Source aggregate value.
- path: ArrayList\<UInt64> - Index path.

Return Value:

- [GetElementRef](#class-getelementref) - The created element reference read expression.

Example:

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

Output:

```text
static_func_create: 2
```

### operator func ==(GetElementRef)

```cangjie
public operator func ==(other: GetElementRef): Bool
```

Function: Reference comparison, determines whether two GetElementRef instances are the same.

Parameters:

- other: GetElementRef - Another element reference read expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_GetElementRef: true
```

## class GetException

```cangjie
public class GetException <: Expression & Equatable<GetException> {}
```

Function: Expression that gets the exception value, used in exception handling landing pad blocks to read the captured exception object.

Parent Types:

- Expression
- Equatable\<GetException>

### static func create(Type)

```cangjie
public static func create(retTy: Type): GetException
```

Function: Creates an expression that gets the exception value.

Parameters:

- retTy: Type - The type of the exception value.

Return Value:

- [GetException](#class-getexception) - The created exception value expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(GetException)

```cangjie
public operator func ==(other: GetException): Bool
```

Function: Reference comparison, determines whether two GetException instances are the same.

Parameters:

- other: GetException - Another exception value expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_GetException: true
```

## class GetInstantiateValue

```cangjie
public class GetInstantiateValue <: Expression & Equatable<GetInstantiateValue> {}
```

Function: Expression that gets the generic function instantiation value, representing a monomorphized instance of a generic function.

Parent Types:

- Expression
- Equatable\<GetInstantiateValue>

### prop instantiateTypes

```cangjie
public prop instantiateTypes: Array<Type>
```

Function: Instantiation type parameters.

Type: Array\<Type>

Example:

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

Output:

```text
prop_instantiateTypes: 0
```

### static func create(Function, ArrayList\<Type>)

```cangjie
public static func create(val: Function, instantiateTypes: ArrayList<Type>): GetInstantiateValue
```

Function: Creates an expression that gets the generic function instantiation value.

Parameters:

- val: Function - Target function.
- instantiateTypes: ArrayList\<Type> - Instantiation type parameters.

Return Value:

- [GetInstantiateValue](#class-getinstantiatevalue) - The created instantiation value expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(GetInstantiateValue)

```cangjie
public operator func ==(other: GetInstantiateValue): Bool
```

Function: Reference comparison, determines whether two GetInstantiateValue instances are the same.

Parameters:

- other: GetInstantiateValue - Another instantiation value expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_GetInstantiateValue: true
```

## class GetRTTI

```cangjie
public class GetRTTI <: Expression & Equatable<GetRTTI> {}
```

Function: Expression that gets runtime type information, extracting RTTI data from a value.

Parent Types:

- Expression
- Equatable\<GetRTTI>

### static func create(Value)

```cangjie
public static func create(val: Value): GetRTTI
```

Function: Creates an expression that gets runtime type information.

Parameters:

- val: Value - Target value.

Return Value:

- [GetRTTI](#class-getrtti) - The created RTTI expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(GetRTTI)

```cangjie
public operator func ==(other: GetRTTI): Bool
```

Function: Reference comparison, determines whether two GetRTTI instances are the same.

Parameters:

- other: GetRTTI - Another RTTI expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_GetRTTI: true
```

## class GetRTTIStatic

```cangjie
public class GetRTTIStatic <: Expression & Equatable<GetRTTIStatic> {}
```

Function: Expression that statically gets runtime type information, extracting RTTI data directly from a type (not dependent on a value instance).

Parent Types:

- Expression
- Equatable\<GetRTTIStatic>

### prop ty

```cangjie
public prop ty: Type
```

Function: Target type.

Type: Type

Example:

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

Output:

```text
prop_ty: Int32
```

### static func create(Type)

```cangjie
public static func create(ty: Type): GetRTTIStatic
```

Function: Creates an expression that statically gets runtime type information.

Parameters:

- ty: Type - Target type.

Return Value:

- [GetRTTIStatic](#class-getrttistatic) - The created static RTTI expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(GetRTTIStatic)

```cangjie
public operator func ==(other: GetRTTIStatic): Bool
```

Function: Reference comparison, determines whether two GetRTTIStatic instances are the same.

Parameters:

- other: GetRTTIStatic - Another static RTTI expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_GetRTTIStatic: true
```

## class GoTo

```cangjie
public class GoTo <: Expression & Equatable<GoTo> {}
```

Function: Unconditional jump terminator expression, jumping directly to the target basic block.

Parent Types:

- Expression
- Equatable\<GoTo>

### static func create(Block)

```cangjie
public static func create(target: Block): GoTo
```

Function: Creates an unconditional jump terminator expression.

Parameters:

- target: Block - Jump target block.

Return Value:

- [GoTo](#class-goto) - The created unconditional jump expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(GoTo)

```cangjie
public operator func ==(other: GoTo): Bool
```

Function: Reference comparison, determines whether two GoTo instances are the same.

Parameters:

- other: GoTo - Another unconditional jump expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_GoTo: true
```

## class InstanceOf

```cangjie
public class InstanceOf <: Expression & Equatable<InstanceOf> {}
```

Function: Type check expression, determining whether a source value belongs to the target type, returning a boolean result.

Parent Types:

- Expression
- Equatable\<InstanceOf>

### prop targetType

```cangjie
public prop targetType: Type
```

Function: Target type.

Type: Type

Example:

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

Output:

```text
prop_targetType: Int32
```

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetTy: Type): InstanceOf
```

Function: Creates a type check expression.

Parameters:

- srcVal: Value - The source value to check.
- targetTy: Type - Target type.

Return Value:

- [InstanceOf](#class-instanceof) - The created type check expression.

Example:

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

Output:

```text
static_func_create: 1
```

### operator func ==(InstanceOf)

```cangjie
public operator func ==(other: InstanceOf): Bool
```

Function: Reference comparison, determines whether two InstanceOf instances are the same.

Parameters:

- other: InstanceOf - Another type check expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_InstanceOf: true
```

## class Lambda

```cangjie
public class Lambda <: Expression & Equatable<Lambda> {}
```

Function: Lambda / local function expression, representing a nested anonymous function or local function definition.

Parent Types:

- Expression
- Equatable\<Lambda>

### prop identifier

```cangjie
public prop identifier: String
```

Function: Internal identifier; globally unique identifier.

Type: String

Example:

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

Output:

```text
prop_identifier: lambda_m
```

### prop srcCodeName

```cangjie
public prop srcCodeName: String
```

Function: Source code name.

Type: String

Example:

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

Output:

```text
prop_srcCodeName: myLambda
```

### prop funcType

```cangjie
public prop funcType: FuncType
```

Function: Function type.

Type: [FuncType](#class-functype)

Example:

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

Output:

```text
prop_funcType: () -> Unit
```

### prop genericTypeParams

```cangjie
public prop genericTypeParams: Array<GenericType>
```

Function: Generic type parameters.

Type: Array\<[GenericType](#class-generictype)>

Example:

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

Output:

```text
prop_genericTypeParams: 0
```

### prop parameters

```cangjie
public prop parameters: Array<Parameter>
```

Function: Parameter list.

Type: Array\<[Parameter](#class-parameter)>

Example:

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

Output:

```text
prop_parameters: 1
```

### prop body

```cangjie
public prop body: BlockGroup
```

Function: Lambda body.

Type: [BlockGroup](#class-blockgroup)

Example:

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

Output:

```text
prop_body: true
```

### prop isCompileTimeValue

```cangjie
public mut prop isCompileTimeValue: Bool
```

Function: Whether this lambda is a compile-time value; getter returns the current flag, setter can modify it.

Type: Bool

### prop isLocalFunc

```cangjie
public mut prop isLocalFunc: Bool
```

Function: Whether this lambda is a local function; getter returns the current flag, setter can modify it.

Type: Bool

### prop returnValue

```cangjie
public mut prop returnValue: LocalVar
```

Function: The return value variable of the Lambda.

Type: [LocalVar](#class-localvar)

### static func create(FuncType, String, String, ArrayList\<GenericType>)

```cangjie
public static func create(ty: FuncType, identifier: String, srcName: String, genericTypeParams: ArrayList<GenericType>): Lambda
```

Function: Creates a Lambda / local function expression.

Parameters:

- ty: FuncType - Function type.
- identifier: String - Internal identifier (mangled name).
- srcName: String - Source code name.
- genericTypeParams: ArrayList\<GenericType> - Generic type parameter list.

Return Value:

- [Lambda](#class-lambda) - The created Lambda expression.

Example:

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

Output:

```text
static_func_create: 1
```

### func initBody()

```cangjie
public func initBody(): Unit
```

Function: Initializes the Lambda body, creating the entry BlockGroup and Block. Must be called after the Lambda has been appended to a basic block.

Example:

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

Output:

```text
fn_initBody: true
```

### func initParameters()

```cangjie
public func initParameters(): Unit
```

Function: Initializes the Lambda parameter list based on the parameter types of `funcType`.

Example:

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

Output:

```text
fn_initParameters: 1
```

### func toString()

```cangjie
public func toString(): String
```

Function: String form of the Lambda.

Return Value:

- String - Readable text dump of the Lambda.

Example:

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

Output:

```text
fn_toString: true
```

### operator func ==(Lambda)

```cangjie
public operator func ==(other: Lambda): Bool
```

Function: Reference comparison, determines whether two Lambda instances are the same.

Parameters:

- other: Lambda - Another Lambda expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Lambda: true
```

## class Load

```cangjie
public class Load <: Expression & Equatable<Load> {}
```

Function: Memory load expression.

Parent Types:

- Expression
- Equatable\<Load>

### prop srcAddress

```cangjie
public prop srcAddress: Value
```

Function: Source address.

Type: Value

Example:

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

Output:

```text
prop_srcAddress: true
```

### static func create(Value)

```cangjie
public static func create(location: Value): Load
```

Function: Creates a memory load expression, loading a value from the specified address.

Parameters:

- location: Value - Source address value.

Return Value:

- [Load](#class-load) - Memory load expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(Load)

```cangjie
public operator func ==(other: Load): Bool
```

Function: Reference comparison, determines whether two Load instances are the same.

Parameters:

- other: Load - Another memory load expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Load: true
```

## class MultiBranch

```cangjie
public class MultiBranch <: Expression & Equatable<MultiBranch> {}
```

Function: Multi-branch (switch-case) terminator expression.

Parent Types:

- Expression
- Equatable\<MultiBranch>

### prop condition

```cangjie
public prop condition: Value
```

Function: Condition value.

Type: Value

Example:

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

Output:

```text
prop_condition: true
```

### prop defaultTarget

```cangjie
public prop defaultTarget: Block
```

Function: Default target block.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_defaultTarget: true
```

### prop targetsWithoutDefault

```cangjie
public prop targetsWithoutDefault: Array<Block>
```

Function: Target blocks other than default.

Type: Array\<[Block](#class-block)>

Example:

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

Output:

```text
prop_targetsWithoutDefault: 1
```

### prop caseValues

```cangjie
public prop caseValues: Array<UInt64>
```

Function: Match values for each case.

Type: Array\<UInt64>

Example:

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

Output:

```text
prop_caseValues: 1
```

### static func create(Value, Block, ArrayList\<Block>, ArrayList\<UInt64>)

```cangjie
public static func create(condition: Value, default: Block, targets: ArrayList<Block>, caseValues: ArrayList<UInt64>): MultiBranch
```

Function: Creates a multi-branch terminator expression, specifying the condition value, default target block, case target block list, and match values for each case.

Parameters:

- condition: Value - Condition value.
- default: Block - Default target block.
- targets: ArrayList\<Block> - Target block list other than default.
- caseValues: ArrayList\<UInt64> - Match values for each case.

Return Value:

- [MultiBranch](#class-multibranch) - Multi-branch terminator expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(MultiBranch)

```cangjie
public operator func ==(other: MultiBranch): Bool
```

Function: Reference comparison, determines whether two MultiBranch instances are the same.

Parameters:

- other: MultiBranch - Another multi-branch terminator expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_MultiBranch: true
```

## class NumericCastBase

```cangjie
sealed abstract class NumericCastBase <: Expression & Equatable<NumericCastBase> {}
```

Function: Abstract base class of numeric-cast expressions; parent type of [NumericCast](#class-numericcast) and [TryNumericCast](#class-trynumericcast); provides query and set of the overflow strategy.

Parent Types:

- [Expression](#class-expression)
- Equatable\<[NumericCastBase](#class-numericcastbase)>

### prop overflow

```cangjie
public mut prop overflow: OverflowStrategy
```

Function: Overflow strategy used by this numeric-cast expression; readable and writable.

Type: [OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy)

Example:

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

Output:

```text
prop_overflow: NA
```

### operator func ==(NumericCastBase)

```cangjie
public operator func ==(other: NumericCastBase): Bool
```

Function: Reference comparison, checks whether two NumericCastBase instances are identical.

Parameters:

- other: [NumericCastBase](#class-numericcastbase) - The other numeric-cast-base expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_NumericCastBase: true
```

## class NumericCast

```cangjie
public class NumericCast <: NumericCastBase & Equatable<NumericCast> {}
```

Function: Numeric type cast expression.

Parent Types:

- NumericCastBase
- Equatable\<NumericCast>

### static func create(Value, Type, OverflowStrategy)

```cangjie
public static func create(srcVal: Value, targetType: Type, overflow: OverflowStrategy): NumericCast
```

Function: Creates a numeric type cast expression, converting the source value to the target type.

Parameters:

- srcVal: Value - Source value.
- targetType: Type - Target type.
- overflow: OverflowStrategy - Overflow handling strategy.

Return Value:

- [NumericCast](#class-numericcast) - Numeric type cast expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(NumericCast)

```cangjie
public operator func ==(other: NumericCast): Bool
```

Function: Reference comparison, determines whether two NumericCast instances are the same.

Parameters:

- other: NumericCast - Another numeric type cast expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_NumericCast: true
```

## class TryNumericCast

```cangjie
public class TryNumericCast <: NumericCastBase & Equatable<TryNumericCast> {}
```

Function: Numeric type cast expression with exception handling.

Parent Types:

- NumericCastBase
- Equatable\<TryNumericCast>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

Function: Normal branch target block.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

Function: Error branch target block.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_errorBranch: true
```

### static func create(Value, Type, Block, Block)

```cangjie
public static func create(srcVal: Value, targetType: Type, normal: Block, err: Block): TryNumericCast
```

Function: Creates a numeric type cast expression with exception handling, specifying the normal branch and error branch target blocks.

Parameters:

- srcVal: Value - Source value.
- targetType: Type - Target type.
- normal: Block - Normal branch target block.
- err: Block - Error branch target block.

Return Value:

- [TryNumericCast](#class-trynumericcast) - Numeric type cast expression instance with exception handling.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(TryNumericCast)

```cangjie
public operator func ==(other: TryNumericCast): Bool
```

Function: Reference comparison, determines whether two TryNumericCast instances are the same.

Parameters:

- other: TryNumericCast - Another numeric type cast expression with exception handling.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_TryNumericCast: true
```

## class RaiseException

```cangjie
public class RaiseException <: Expression & Equatable<RaiseException> {}
```

Function: Raise exception terminator expression.

Parent Types:

- Expression
- Equatable\<RaiseException>

### static func create(Value)

```cangjie
public static func create(value: Value): RaiseException
```

Function: Creates a raise exception terminator expression (no successor block version).

Parameters:

- value: Value - Exception value.

Return Value:

- [RaiseException](#class-raiseexception) - Raise exception terminator expression instance.

Example:

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

Output:

```text
static_create_noSuccessor: true
```

### static func create(Value, Block)

```cangjie
public static func create(value: Value, successor: Block): RaiseException
```

Function: Creates a raise exception terminator expression (with successor block version).

Parameters:

- value: Value - Exception value.
- successor: Block - Successor block.

Return Value:

- [RaiseException](#class-raiseexception) - Raise exception terminator expression instance.

Example:

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

Output:

```text
static_create_withSuccessor: done
```

### operator func ==(RaiseException)

```cangjie
public operator func ==(other: RaiseException): Bool
```

Function: Reference comparison, determines whether two RaiseException instances are the same.

Parameters:

- other: RaiseException - Another raise exception terminator expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_RaiseException: true
```
</task_result>

## class RawArrayAllocateBase

```cangjie
sealed abstract class RawArrayAllocateBase <: Expression & Equatable<RawArrayAllocateBase> {}
```

Function: Abstract base class of raw-array allocation expressions; parent type of [RawArrayAllocate](#class-rawarrayallocate) and [TryRawArrayAllocate](#class-tryrawarrayallocate); provides query of the allocated element type.

Parent Types:

- [Expression](#class-expression)
- Equatable\<[RawArrayAllocateBase](#class-rawarrayallocatebase)>

### prop elementType

```cangjie
public prop elementType: Type
```

Function: Element type allocated by this allocation expression.

Type: [Type](#class-type)

Example:

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

Output:

```text
prop_elementType: Int32
```

### operator func ==(RawArrayAllocateBase)

```cangjie
public operator func ==(other: RawArrayAllocateBase): Bool
```

Function: Reference comparison, checks whether two RawArrayAllocateBase instances are identical.

Parameters:

- other: [RawArrayAllocateBase](#class-rawarrayallocatebase) - The other raw-array-allocation-base expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_RawArrayAllocateBase: true
```

## class RawArrayAllocate

```cangjie
public class RawArrayAllocate <: RawArrayAllocateBase & Equatable<RawArrayAllocate> {}
```

Function: Raw array allocation expression.

Parent Types:

- RawArrayAllocateBase
- Equatable\<RawArrayAllocate>

### static func create(Type, Value)

```cangjie
public static func create(elementType: Type, size: Value): RawArrayAllocate
```

Function: Creates a raw array allocation expression, specifying the element type and array size.

Parameters:

- elementType: Type - The element type.
- size: Value - The array size.

Return Value:

- [RawArrayAllocate](#class-rawarrayallocate) - Raw array allocation expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(RawArrayAllocate)

```cangjie
public operator func ==(other: RawArrayAllocate): Bool
```

Function: Reference comparison, determines whether two RawArrayAllocate instances are the same instance.

Parameters:

- other: RawArrayAllocate - Another raw array allocation expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_RawArrayAllocate: true
```

## class TryRawArrayAllocate

```cangjie
public class TryRawArrayAllocate <: RawArrayAllocateBase & Equatable<TryRawArrayAllocate> {}
```

Function: Raw array allocation expression with exception handling.

Parent Types:

- RawArrayAllocateBase
- Equatable\<TryRawArrayAllocate>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

Function: Normal branch target block.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

Function: Error branch target block.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_errorBranch: true
```

### static func create(Type, Value, Block, Block)

```cangjie
public static func create(elementType: Type, size: Value, normal: Block, err: Block): TryRawArrayAllocate
```

Function: Creates a raw array allocation expression with exception handling, specifying the normal branch and error branch target blocks.

Parameters:

- elementType: Type - The element type.
- size: Value - The array size.
- normal: Block - Normal branch target block.
- err: Block - Error branch target block.

Return Value:

- [TryRawArrayAllocate](#class-tryrawarrayallocate) - Raw array allocation expression with exception handling instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(TryRawArrayAllocate)

```cangjie
public operator func ==(other: TryRawArrayAllocate): Bool
```

Function: Reference comparison, determines whether two TryRawArrayAllocate instances are the same instance.

Parameters:

- other: TryRawArrayAllocate - Another raw array allocation expression with exception handling.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_TryRawArrayAllocate: true
```

## class RawArrayInitByValue

```cangjie
public class RawArrayInitByValue <: Expression & Equatable<RawArrayInitByValue> {}
```

Function: Initialize raw array by value expression.

Parent Types:

- Expression
- Equatable\<RawArrayInitByValue>

### static func create(Value, Value, Value)

```cangjie
public static func create(memory: Value, size: Value, initVal: Value): RawArrayInitByValue
```

Function: Creates an initialize raw array by value expression, specifying the memory address, array size, and initial value.

Parameters:

- memory: Value - The memory address.
- size: Value - The array size.
- initVal: Value - The initial value.

Return Value:

- [RawArrayInitByValue](#class-rawarrayinitbyvalue) - Initialize raw array by value expression instance.

Example:

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

Output:

```text
static_create: done
```

### operator func ==(RawArrayInitByValue)

```cangjie
public operator func ==(other: RawArrayInitByValue): Bool
```

Function: Reference comparison, determines whether two RawArrayInitByValue instances are the same instance.

Parameters:

- other: RawArrayInitByValue - Another initialize raw array by value expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_RawArrayInitByValue: true
```

## class RawArrayLiteralInit

```cangjie
public class RawArrayLiteralInit <: Expression & Equatable<RawArrayLiteralInit> {}
```

Function: Initialize raw array by literal expression.

Parent Types:

- Expression
- Equatable\<RawArrayLiteralInit>

### static func create(Value, ArrayList\<Value>)

```cangjie
public static func create(memory: Value, elements: ArrayList<Value>): RawArrayLiteralInit
```

Function: Creates an initialize raw array by literal expression, specifying the memory address and element list.

Parameters:

- memory: Value - The memory address.
- elements: ArrayList\<Value> - The element value list.

Return Value:

- [RawArrayLiteralInit](#class-rawarrayliteralinit) - Initialize raw array by literal expression instance.

Example:

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

Output:

```text
static_create: done
```

### operator func ==(RawArrayLiteralInit)

```cangjie
public operator func ==(other: RawArrayLiteralInit): Bool
```

Function: Reference comparison, determines whether two RawArrayLiteralInit instances are the same instance.

Parameters:

- other: RawArrayLiteralInit - Another initialize raw array by literal expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_RawArrayLiteralInit: true
```

## class SpawnBase

```cangjie
sealed abstract class SpawnBase <: Expression & Equatable<SpawnBase> {}
```

Function: Abstract base class of Spawn (coroutine-creation) expressions; parent type of [Spawn](#class-spawn) and [TrySpawn](#class-tryspawn); provides query and set of the execute closure.

Parent Types:

- [Expression](#class-expression)
- Equatable\<[SpawnBase](#class-spawnbase)>

### prop executeClosure

```cangjie
public mut prop executeClosure: Function
```

Function: Execute closure associated with this Spawn expression; throws when read before being set.

Type: [Function](#class-function)

Example:

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

Output:

```text
prop_executeClosure: false
```

### func needExecuteClosure()

```cangjie
public func needExecuteClosure(): Bool
```

Function: Checks whether this Spawn expression has an execute closure set.

Return Value:

- Bool - Returns true when an execute closure is set, false otherwise.

Example:

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

Output:

```text
func_needExecuteClosure: false
```

### operator func ==(SpawnBase)

```cangjie
public operator func ==(other: SpawnBase): Bool
```

Function: Reference comparison, checks whether two SpawnBase instances are identical.

Parameters:

- other: [SpawnBase](#class-spawnbase) - The other Spawn-base expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_SpawnBase: true
```

## class Spawn

```cangjie
public class Spawn <: SpawnBase & Equatable<Spawn> {}
```

Function: Concurrent Spawn expression (without exception handling).

Parent Types:

- SpawnBase
- Equatable\<Spawn>

### static func create(Type, Value)

```cangjie
public static func create(retTy: Type, lambda: Value): Spawn
```

Function: Creates a concurrent Spawn expression (no-argument version).

Parameters:

- retTy: Type - The return type.
- lambda: Value - The lambda value.

Return Value:

- [Spawn](#class-spawn) - Spawn expression instance.

Example:

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

Output:

```text
static_create_noArg: true
```

### static func create(Type, Value, Value)

```cangjie
public static func create(retTy: Type, lambda: Value, arg: Value): Spawn
```

Function: Creates a concurrent Spawn expression (with-argument version).

Parameters:

- retTy: Type - The return type.
- lambda: Value - The lambda value.
- arg: Value - The Spawn argument value.

Return Value:

- [Spawn](#class-spawn) - Spawn expression instance.

Example:

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

Output:

```text
static_create_withArg: true
```

### operator func ==(Spawn)

```cangjie
public operator func ==(other: Spawn): Bool
```

Function: Reference comparison, determines whether two Spawn instances are the same instance.

Parameters:

- other: Spawn - Another Spawn expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Spawn: true
```

## class TrySpawn

```cangjie
public class TrySpawn <: SpawnBase & Equatable<TrySpawn> {}
```

Function: Concurrent Spawn expression with exception handling.

Parent Types:

- SpawnBase
- Equatable\<TrySpawn>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

Function: Normal branch target block.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

Function: Error branch target block.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_errorBranch: true
```

### static func create(Type, Value, Block, Block)

```cangjie
public static func create(retTy: Type, lambda: Value, normal: Block, err: Block): TrySpawn
```

Function: Creates a concurrent Spawn expression with exception handling (no-argument version).

Parameters:

- retTy: Type - The return type.
- lambda: Value - The lambda value.
- normal: Block - Normal branch target block.
- err: Block - Error branch target block.

Return Value:

- [TrySpawn](#class-tryspawn) - Spawn expression with exception handling instance.

Example:

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

Output:

```text
static_create_noArg: true
```

### static func create(Type, Value, Value, Block, Block)

```cangjie
public static func create(retTy: Type, lambda: Value, arg: Value, normal: Block, err: Block): TrySpawn
```

Function: Creates a concurrent Spawn expression with exception handling (with-argument version).

Parameters:

- retTy: Type - The return type.
- lambda: Value - The lambda value.
- arg: Value - The Spawn argument value.
- normal: Block - Normal branch target block.
- err: Block - Error branch target block.

Return Value:

- [TrySpawn](#class-tryspawn) - Spawn expression with exception handling instance.

Example:

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

Output:

```text
static_create_withArg: true
```

### operator func ==(TrySpawn)

```cangjie
public operator func ==(other: TrySpawn): Bool
```

Function: Reference comparison, determines whether two TrySpawn instances are the same instance.

Parameters:

- other: TrySpawn - Another Spawn expression with exception handling.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_TrySpawn: true
```

## class Store

```cangjie
public class Store <: Expression & Equatable<Store> {}
```

Function: Memory store expression.

Parent Types:

- Expression
- Equatable\<Store>

### prop dstAddress

```cangjie
public prop dstAddress: Value
```

Function: Destination address.

Type: Value

Example:

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

Output:

```text
prop_dstAddress: true
```

### prop srcValue

```cangjie
public prop srcValue: Value
```

Function: Source value.

Type: Value

Example:

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

Output:

```text
prop_srcValue: true
```

### static func create(Value, Value)

```cangjie
public static func create(val: Value, location: Value): Store
```

Function: Creates a memory store expression, storing the source value to the destination address.

Parameters:

- val: Value - The source value.
- location: Value - The destination address.

Return Value:

- [Store](#class-store) - Memory store expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(Store)

```cangjie
public operator func ==(other: Store): Bool
```

Function: Reference comparison, determines whether two Store instances are the same instance.

Parameters:

- other: Store - Another memory store expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Store: true
```

## class StoreElementByName

```cangjie
public class StoreElementByName <: Expression & Equatable<StoreElementByName> {}
```

Function: Expression that stores an aggregate element by field name.

Parent Types:

- Expression
- Equatable\<StoreElementByName>

### prop fieldNames

```cangjie
public prop fieldNames: Array<String>
```

Function: Field name path.

Type: Array\<String>

Example:

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

Output:

```text
prop_fieldNames: 1
```

### static func create(Value, Value, ArrayList\<String>)

```cangjie
public static func create(val: Value, location: Value, fieldNames: ArrayList<String>): StoreElementByName
```

Function: Creates an expression that stores an aggregate element by field name.

Parameters:

- val: Value - The source value.
- location: Value - The destination address.
- fieldNames: ArrayList\<String> - The field name path.

Return Value:

- [StoreElementByName](#class-storeelementbyname) - Store aggregate element by field name expression instance.

Example:

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

Output:

```text
static_create: 1
```

### operator func ==(StoreElementByName)

```cangjie
public operator func ==(other: StoreElementByName): Bool
```

Function: Reference comparison, determines whether two StoreElementByName instances are the same instance.

Parameters:

- other: StoreElementByName - Another store aggregate element by field name expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_StoreElementByName: true
```

## class StoreElementRef

```cangjie
public class StoreElementRef <: Expression & Equatable<StoreElementRef> {}
```

Function: Expression that stores an aggregate element by numeric index.

Parent Types:

- Expression
- Equatable\<StoreElementRef>

### prop path

```cangjie
public prop path: Array<UInt64>
```

Function: Index path.

Type: Array\<UInt64>

Example:

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

Output:

```text
prop_path: 1
```

### static func create(Value, Value, ArrayList\<UInt64>)

```cangjie
public static func create(val: Value, location: Value, path: ArrayList<UInt64>): StoreElementRef
```

Function: Creates an expression that stores an aggregate element by numeric index.

Parameters:

- val: Value - The source value.
- location: Value - The destination address.
- path: ArrayList\<UInt64> - The index path.

Return Value:

- [StoreElementRef](#class-storeelementref) - Store aggregate element by numeric index expression instance.

Example:

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

Output:

```text
static_create: 1
```

### operator func ==(StoreElementRef)

```cangjie
public operator func ==(other: StoreElementRef): Bool
```

Function: Reference comparison, determines whether two StoreElementRef instances are the same instance.

Parameters:

- other: StoreElementRef - Another store aggregate element by numeric index expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_StoreElementRef: true
```

## class Tuple

```cangjie
public class Tuple <: Expression & Equatable<Tuple> {}
```

Function: Tuple construction expression.

Parent Types:

- Expression
- Equatable\<Tuple>

### prop elements

```cangjie
public prop elements: Array<Value>
```

Function: Tuple elements.

Type: Array\<Value>

Example:

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

Output:

```text
prop_elements: 2
```

### static func create(ArrayList\<Value>)

```cangjie
public static func create(elements: ArrayList<Value>): Tuple
```

Function: Creates a tuple construction expression, specifying the element list.

Parameters:

- elements: ArrayList\<Value> - The element value list.

Return Value:

- [Tuple](#class-tuple) - Tuple construction expression instance.

Example:

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

Output:

```text
static_create: 2
```

### operator func ==(Tuple)

```cangjie
public operator func ==(other: Tuple): Bool
```

Function: Reference comparison, determines whether two Tuple instances are the same instance.

Parameters:

- other: Tuple - Another tuple construction expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Tuple: true
```

## class TypeCast

```cangjie
sealed abstract class TypeCast <: Expression & Equatable<TypeCast> {}
```

Function: Abstract base class of type-cast expressions; parent type of [Box](#class-box), [StaticCast](#class-staticcast), [CastToConcrete](#class-casttoconcrete), [CastToGeneric](#class-casttogeneric), etc.; provides query of source value, source type and target type.

Parent Types:

- [Expression](#class-expression)
- Equatable\<[TypeCast](#class-typecast)>

### prop sourceType

```cangjie
public prop sourceType: Type
```

Function: Source value type of this type cast.

Type: [Type](#class-type)

Example:

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

Output:

```text
prop_sourceType: Int64
```

### prop srcValue

```cangjie
public prop srcValue: Value
```

Function: Source value of this type cast.

Type: [Value](#class-value)

Example:

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

Output:

```text
prop_srcValue: true
```

### prop targetType

```cangjie
public prop targetType: Type
```

Function: Target type of this type cast.

Type: [Type](#class-type)

Example:

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

Output:

```text
prop_targetType: Int64
```

### operator func ==(TypeCast)

```cangjie
public operator func ==(other: TypeCast): Bool
```

Function: Reference comparison, checks whether two TypeCast instances are identical.

Parameters:

- other: [TypeCast](#class-typecast) - The other type-cast expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_TypeCast: true
```

## class Box

```cangjie
public class Box <: TypeCast & Equatable<Box> {}
```

Function: Boxing type cast expression.

Parent Types:

- TypeCast
- Equatable\<Box>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): Box
```

Function: Creates a boxing type cast expression, boxing the source value to the target type.

Parameters:

- srcVal: Value - The source value.
- targetType: Type - The target type.

Return Value:

- [Box](#class-box) - Boxing type cast expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(Box)

```cangjie
public operator func ==(other: Box): Bool
```

Function: Reference comparison, determines whether two Box instances are the same instance.

Parameters:

- other: Box - Another boxing type cast expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_Box: true
```

## class StaticCast

```cangjie
public class StaticCast <: TypeCast & Equatable<StaticCast> {}
```

Function: Static type cast expression.

Parent Types:

- TypeCast
- Equatable\<StaticCast>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): StaticCast
```

Function: Creates a static type cast expression, statically casting the source value to the target type.

Parameters:

- srcVal: Value - The source value.
- targetType: Type - The target type.

Return Value:

- [StaticCast](#class-staticcast) - Static type cast expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(StaticCast)

```cangjie
public operator func ==(other: StaticCast): Bool
```

Function: Reference comparison, determines whether two StaticCast instances are the same instance.

Parameters:

- other: StaticCast - Another static type cast expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_StaticCast: true
```

## class CastToConcrete

```cangjie
public class CastToConcrete <: TypeCast & Equatable<CastToConcrete> {}
```

Function: Cast to concrete type expression.

Parent Types:

- TypeCast
- Equatable\<CastToConcrete>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): CastToConcrete
```

Function: Creates a cast to concrete type expression.

Parameters:

- srcVal: Value - The source value.
- targetType: Type - The target concrete type.

Return Value:

- [CastToConcrete](#class-casttoconcrete) - Cast to concrete type expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(CastToConcrete)

```cangjie
public operator func ==(other: CastToConcrete): Bool
```

Function: Reference comparison, determines whether two CastToConcrete instances are the same instance.

Parameters:

- other: CastToConcrete - Another cast to concrete type expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_CastToConcrete: true
```

## class CastToGeneric

```cangjie
public class CastToGeneric <: TypeCast & Equatable<CastToGeneric> {}
```

Function: Cast to generic type expression.

Parent Types:

- TypeCast
- Equatable\<CastToGeneric>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): CastToGeneric
```

Function: Creates a cast to generic type expression.

Parameters:

- srcVal: Value - The source value.
- targetType: Type - The target generic type.

Return Value:

- [CastToGeneric](#class-casttogeneric) - Cast to generic type expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(CastToGeneric)

```cangjie
public operator func ==(other: CastToGeneric): Bool
```

Function: Reference comparison, determines whether two CastToGeneric instances are the same instance.

Parameters:

- other: CastToGeneric - Another cast to generic type expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_CastToGeneric: true
```

## class UnboxToRef

```cangjie
public class UnboxToRef <: TypeCast & Equatable<UnboxToRef> {}
```

Function: Unbox to reference type cast expression.

Parent Types:

- TypeCast
- Equatable\<UnboxToRef>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): UnboxToRef
```

Function: Creates an unbox to reference type cast expression.

Parameters:

- srcVal: Value - The source value.
- targetType: Type - The target reference type.

Return Value:

- [UnboxToRef](#class-unboxtoref) - Unbox to reference type cast expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(UnboxToRef)

```cangjie
public operator func ==(other: UnboxToRef): Bool
```

Function: Reference comparison, determines whether two UnboxToRef instances are the same instance.

Parameters:

- other: UnboxToRef - Another unbox to reference type cast expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_UnboxToRef: true
```

## class UnboxToValue

```cangjie
public class UnboxToValue <: TypeCast & Equatable<UnboxToValue>
```

Function: Unbox to value type cast expression.

Parent Types:

- TypeCast
- Equatable\<UnboxToValue>

### static func create(Value, Type)

```cangjie
public static func create(srcVal: Value, targetType: Type): UnboxToValue
```

Function: Creates an unbox to value type cast expression.

Parameters:

- srcVal: Value - The source value.
- targetType: Type - The target value type.

Return Value:

- [UnboxToValue](#class-unboxtovalue) - Unbox to value type cast expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(UnboxToValue)

```cangjie
public operator func ==(other: UnboxToValue): Bool
```

Function: Reference comparison, determines whether two UnboxToValue instances are the same instance.

Parameters:

- other: UnboxToValue - Another unbox to value type cast expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_UnboxToValue: true
```

## class UnaryExpressionBase

```cangjie
sealed abstract class UnaryExpressionBase <: Expression & Equatable<UnaryExpressionBase> {}
```

Function: Abstract base class of unary expressions ([UnaryExpression](#class-unaryexpression), [TryUnaryExpression](#class-tryunaryexpression), etc.); provides query and set of the overflow strategy.

Parent Types:

- [Expression](#class-expression)
- Equatable\<[UnaryExpressionBase](#class-unaryexpressionbase)>

### prop overflow

```cangjie
public mut prop overflow: OverflowStrategy
```

Function: Overflow strategy used by this unary expression; readable and writable, defaults to [OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy).NA.

Type: [OverflowStrategy](./chir_package_enums.md#enum-overflowstrategy)

Example:

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

Output:

```text
prop_overflow: Throwing
```

### operator func ==(UnaryExpressionBase)

```cangjie
public operator func ==(other: UnaryExpressionBase): Bool
```

Function: Reference comparison, checks whether two UnaryExpressionBase instances are identical.

Parameters:

- other: [UnaryExpressionBase](#class-unaryexpressionbase) - The other unary-expression-base expression.

Return Value:

- Bool - Whether the references are identical.

Example:

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

Output:

```text
op_eq_UnaryExpressionBase: true
```

## class UnaryExpression

```cangjie
public class UnaryExpression <: UnaryExpressionBase & Equatable<UnaryExpression>
```

Function: Unary operation expression (without exception handling).

Parent Types:

- UnaryExpressionBase
- Equatable\<UnaryExpression>

### static func create(UnaryExprKind, Value)

```cangjie
public static func create(kind: UnaryExprKind, op: Value): UnaryExpression
```

Function: Creates a unary operation expression, specifying the operation kind and operand.

Parameters:

- kind: UnaryExprKind - The unary operation kind.
- op: Value - The operand.

Return Value:

- [UnaryExpression](#class-unaryexpression) - Unary operation expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(UnaryExpression)

```cangjie
public operator func ==(other: UnaryExpression): Bool
```

Function: Reference comparison, determines whether two UnaryExpression instances are the same instance.

Parameters:

- other: UnaryExpression - Another unary operation expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_UnaryExpression: true
```

## class TryUnaryExpression

```cangjie
public class TryUnaryExpression <: UnaryExpressionBase & Equatable<TryUnaryExpression>
```

Function: Unary operation expression with exception handling.

Parent Types:

- UnaryExpressionBase
- Equatable\<TryUnaryExpression>

### prop normalBranch

```cangjie
public prop normalBranch: Block
```

Function: Normal branch target block.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_normalBranch: true
```

### prop errorBranch

```cangjie
public prop errorBranch: Block
```

Function: Error branch target block.

Type: [Block](#class-block)

Example:

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

Output:

```text
prop_errorBranch: true
```

### static func create(Value, Block, Block)

```cangjie
public static func create(op: Value, normal: Block, err: Block): TryUnaryExpression
```

Function: Creates a unary operation expression with exception handling, specifying the normal branch and error branch target blocks.

Parameters:

- op: Value - The operand.
- normal: Block - Normal branch target block.
- err: Block - Error branch target block.

Return Value:

- [TryUnaryExpression](#class-tryunaryexpression) - Unary operation expression with exception handling instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(TryUnaryExpression)

```cangjie
public operator func ==(other: TryUnaryExpression): Bool
```

Function: Reference comparison, determines whether two TryUnaryExpression instances are the same instance.

Parameters:

- other: TryUnaryExpression - Another unary operation expression with exception handling.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_TryUnaryExpression: true
```

## class VArrayBuilder

```cangjie
public class VArrayBuilder <: Expression & Equatable<VArrayBuilder>
```

Function: VArray builder expression.

Parent Types:

- Expression
- Equatable\<VArrayBuilder>

### static func create(Type, Value, Value, Value)

```cangjie
public static func create(retTy: Type, size: Value, initVal: Value, initFunc: Value): VArrayBuilder
```

Function: Creates a VArray builder expression, specifying the return type, array size, initial value, and initialization function.

Parameters:

- retTy: Type - The return type.
- size: Value - The array size.
- initVal: Value - The initial value.
- initFunc: Value - The initialization function.

Return Value:

- [VArrayBuilder](#class-varraybuilder) - VArray builder expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(VArrayBuilder)

```cangjie
public operator func ==(other: VArrayBuilder): Bool
```

Function: Reference comparison, determines whether two VArrayBuilder instances are the same instance.

Parameters:

- other: VArrayBuilder - Another VArray builder expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_VArrayBuilder: true
```

## class VArrayExpr

```cangjie
public class VArrayExpr <: Expression & Equatable<VArrayExpr>
```

Function: VArray literal expression.

Parent Types:

- Expression
- Equatable\<VArrayExpr>

### static func create(ArrayList\<Value>)

```cangjie
public static func create(elements: ArrayList<Value>): VArrayExpr
```

Function: Creates a VArray literal expression, specifying the element list.

Parameters:

- elements: ArrayList\<Value> - The element value list.

Return Value:

- [VArrayExpr](#class-varrayexpr) - VArray literal expression instance.

Example:

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

Output:

```text
static_create: true
```

### operator func ==(VArrayExpr)

```cangjie
public operator func ==(other: VArrayExpr): Bool
```

Function: Reference comparison, determines whether two VArrayExpr instances are the same instance.

Parameters:

- other: VArrayExpr - Another VArray literal expression.

Return Value:

- Bool - Whether they are the same reference.

Example:

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

Output:

```text
op_eq_VArrayExpr: true
```

</task_result>

## class CHIRBuilder

```cangjie
public class CHIRBuilder {
    public init(parent: Block)
    public init(position: InsertPosition)
}
```

Function: CHIR expression builder, used to insert various CHIR expressions (arithmetic, memory, control flow, type conversions, etc.) into a basic block at a specified position.

### init(Block)

```cangjie
public init(parent: Block)
```

Function: Constructs a CHIRBuilder with the insertion position set to the end of the given basic block.

Parameters:

- parent: Block - Target basic block for insertion.

Example:

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

Output:

```text
init_Block: 1
```

### init(InsertPosition)

```cangjie
public init(position: InsertPosition)
```

Function: Constructs a CHIRBuilder with a specified insertion position.

Parameters:

- position: InsertPosition - Insertion position enum value (AtEnd/AtStart/Before/After).

Example:

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

Output:

```text
init_InsertPosition: 1
```

### func createAllocate(Type)

```cangjie
public func createAllocate(ty: Type): Allocate
```

Function: Creates a memory allocation expression.

Parameters:

- ty: Type - The type to allocate.

Return Value:

- [Allocate](#class-allocate) - Allocation expression.

Example:

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

Output:

```text
createAllocate: true
```

### func createApply(Value, FuncCallContext)

```cangjie
public func createApply(callee: Value, funcCallCtx: FuncCallContext): Apply
```

Function: Creates a function call (Apply) expression.

Parameters:

- callee: Value - The called function value.
- funcCallCtx: FuncCallContext - Function call context.

Return Value:

- [Apply](#class-apply) - Apply expression.

Example:

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

Output:

```text
createApply: true
```

### func createBinaryAdd(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryAdd(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

Function: Creates an addition binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Addition expression.

Example:

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

Output:

```text
createBinaryAdd: true
```

### func createBinaryAnd(Value, Value)

```cangjie
public func createBinaryAnd(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a logical AND binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Logical AND expression.

Example:

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

Output:

```text
createBinaryAnd: true
```

### func createBinaryBitAnd(Value, Value)

```cangjie
public func createBinaryBitAnd(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a bitwise AND binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Bitwise AND expression.

Example:

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

Output:

```text
createBinaryBitAnd: true
```

### func createBinaryBitOr(Value, Value)

```cangjie
public func createBinaryBitOr(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a bitwise OR binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Bitwise OR expression.

Example:

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

Output:

```text
createBinaryBitOr: true
```

### func createBinaryBitXor(Value, Value)

```cangjie
public func createBinaryBitXor(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a bitwise XOR binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Bitwise XOR expression.

Example:

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

Output:

```text
createBinaryBitXor: true
```

### func createBinaryDiv(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryDiv(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

Function: Creates a division binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Division expression.

Example:

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

Output:

```text
createBinaryDiv: true
```

### func createBinaryEqual(Value, Value)

```cangjie
public func createBinaryEqual(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates an equality comparison binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Equality comparison expression.

Example:

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

Output:

```text
createBinaryEqual: true
```

### func createBinaryExp(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryExp(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

Function: Creates an exponentiation binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Exponentiation expression.

Example:

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

Output:

```text
createBinaryExp: true
```

### func createBinaryGreaterThan(Value, Value)

```cangjie
public func createBinaryGreaterThan(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a greater-than comparison binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Greater-than comparison expression.

Example:

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

Output:

```text
createBinaryGreaterThan: true
```

### func createBinaryGreaterThanOrEqual(Value, Value)

```cangjie
public func createBinaryGreaterThanOrEqual(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a greater-than-or-equal comparison binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Greater-than-or-equal comparison expression.

Example:

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

Output:

```text
createBinaryGreaterThanOrEqual: true
```

### func createBinaryLShift(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryLShift(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

Function: Creates a left-shift binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Left-shift expression.

Example:

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

Output:

```text
createBinaryLShift: true
```

### func createBinaryLessThan(Value, Value)

```cangjie
public func createBinaryLessThan(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a less-than comparison binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Less-than comparison expression.

Example:

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

Output:

```text
createBinaryLessThan: true
```

### func createBinaryLessThanOrEqual(Value, Value)

```cangjie
public func createBinaryLessThanOrEqual(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a less-than-or-equal comparison binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Less-than-or-equal comparison expression.

Example:

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

Output:

```text
createBinaryLessThanOrEqual: true
```

### func createBinaryMod(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryMod(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

Function: Creates a modulo binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Modulo expression.

Example:

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

Output:

```text
createBinaryMod: true
```

### func createBinaryMul(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryMul(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

Function: Creates a multiplication binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Multiplication expression.

Example:

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

Output:

```text
createBinaryMul: true
```

### func createBinaryNotEqual(Value, Value)

```cangjie
public func createBinaryNotEqual(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a not-equal comparison binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Not-equal comparison expression.

Example:

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

Output:

```text
createBinaryNotEqual: true
```

### func createBinaryOr(Value, Value)

```cangjie
public func createBinaryOr(leftOp: Value, rightOp: Value): BinaryExpression
```

Function: Creates a logical OR binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Logical OR expression.

Example:

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

Output:

```text
createBinaryOr: true
```

### func createBinaryRShift(Value, Value, OverflowStrategy)

```cangjie
public func createBinaryRShift(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

Function: Creates a right-shift binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Right-shift expression.

Example:

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

Output:

```text
createBinaryRShift: true
```

### func createBinarySub(Value, Value, OverflowStrategy)

```cangjie
public func createBinarySub(leftOp: Value, rightOp: Value, overflow: OverflowStrategy): BinaryExpression
```

Function: Creates a subtraction binary expression.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [BinaryExpression](#class-binaryexpression) - Subtraction expression.

Example:

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

Output:

```text
createBinarySub: true
```

### func createBox(Value, Type)

```cangjie
public func createBox(srcVal: Value, dstTy: Type): Box
```

Function: Creates a boxing (Box) type conversion expression.

Parameters:

- srcVal: Value - Source value.
- dstTy: Type - Target boxed type.

Return Value:

- [Box](#class-box) - Boxing expression.

Example:

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

Output:

```text
createBox: true
```

### func createBranch(Value, Block, Block)

```cangjie
public func createBranch(condition: Value, trueTarget: Block, falseTarget: Block): Branch
```

Function: Creates a conditional branch expression.

Parameters:

- condition: Value - Branch condition value.
- trueTarget: Block - Target basic block when the condition is true.
- falseTarget: Block - Target basic block when the condition is false.

Return Value:

- [Branch](#class-branch) - Conditional branch expression.

Example:

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

Output:

```text
createBranch: true
```

### func createCastToConcrete(Value, Type)

```cangjie
public func createCastToConcrete(srcVal: Value, targetType: Type): CastToConcrete
```

Function: Creates a cast-to-concrete-type expression.

Parameters:

- srcVal: Value - Source value.
- targetType: Type - Target concrete type.

Return Value:

- [CastToConcrete](#class-casttoconcrete) - Cast-to-concrete-type expression.

Example:

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

Output:

```text
createCastToConcrete: true
```

### func createCastToGeneric(Value, Type)

```cangjie
public func createCastToGeneric(srcVal: Value, targetType: Type): CastToGeneric
```

Function: Creates a cast-to-generic-type expression.

Parameters:

- srcVal: Value - Source value.
- targetType: Type - Target generic type.

Return Value:

- [CastToGeneric](#class-casttogeneric) - Cast-to-generic-type expression.

Example:

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

Output:

```text
createCastToGeneric: true
```

### func createConstant(LiteralValue)

```cangjie
public func createConstant(val: LiteralValue): Constant
```

Function: Creates a constant expression.

Parameters:

- val: LiteralValue - Literal value.

Return Value:

- [Constant](#class-constant) - Constant expression.

Example:

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

Output:

```text
createConstant: true
```

### func createDebug(Value, String)

```cangjie
public func createDebug(location: Value, srcCodeName: String): Debug
```

Function: Creates a debug marker expression.

Parameters:

- location: Value - Debug location value.
- srcCodeName: String - Source code variable name.

Return Value:

- [Debug](#class-debug) - Debug marker expression.

Example:

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

Output:

```text
createDebug: true
```

### func createExit()

```cangjie
public func createExit(): Exit
```

Function: Creates a function exit expression.

Return Value:

- [Exit](#class-exit) - Function exit expression.

Example:

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

Output:

```text
createExit: true
```

### func createField(Value, ArrayList\<UInt64>)

```cangjie
public func createField(val: Value, path: ArrayList<UInt64>): Field
```

Function: Creates a field access expression by numeric path.

Parameters:

- val: Value - Struct or class instance value.
- path: ArrayList\<UInt64> - Numeric path index list.

Return Value:

- [Field](#class-field) - Field access expression.

Example:

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

Output:

```text
createField: true
```

### func createFieldByName(Value, ArrayList\<String>)

```cangjie
public func createFieldByName(val: Value, fieldNames: ArrayList<String>): FieldByName
```

Function: Creates a field access expression by field name path.

Parameters:

- val: Value - Struct or class instance value.
- fieldNames: ArrayList\<String> - Field name path list.

Return Value:

- [FieldByName](#class-fieldbyname) - Field access expression by name.

Example:

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

Output:

```text
createFieldByName: true
```

### func createGetElementByName(Value, ArrayList\<String>)

```cangjie
public func createGetElementByName(location: Value, fieldNames: ArrayList<String>): GetElementByName
```

Function: Creates an element read expression by field name.

Parameters:

- location: Value - Memory location value.
- fieldNames: ArrayList\<String> - Field name path list.

Return Value:

- [GetElementByName](#class-getelementbyname) - Element read expression.

Example:

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

Output:

```text
createGetElementByName: true
```

### func createGetElementRef(Value, ArrayList\<UInt64>)

```cangjie
public func createGetElementRef(location: Value, path: ArrayList<UInt64>): GetElementRef
```

Function: Creates an element reference expression by numeric index.

Parameters:

- location: Value - Memory location value.
- path: ArrayList\<UInt64> - Numeric index path list.

Return Value:

- [GetElementRef](#class-getelementref) - Element reference expression.

Example:

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

Output:

```text
createGetElementRef: true
```

### func createGetException(Type)

```cangjie
public func createGetException(retTy: Type): GetException
```

Function: Creates an expression to get the exception value.

Parameters:

- retTy: Type - Return type.

Return Value:

- [GetException](#class-getexception) - Get exception value expression.

Example:

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

Output:

```text
createGetException: true
```

### func createGetInstantiateValue(Function, ArrayList\<Type>)

```cangjie
public func createGetInstantiateValue(val: Function, instantiateTypes: ArrayList<Type>): GetInstantiateValue
```

Function: Creates an expression to get a generic instantiation value.

Parameters:

- val: Function - Target function.
- instantiateTypes: ArrayList\<Type> - Instantiation type argument list.

Return Value:

- [GetInstantiateValue](#class-getinstantiatevalue) - Generic instantiation value expression.

Example:

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

Output:

```text
createGetInstantiateValue: true
```

### func createGetRTTI(Value)

```cangjie
public func createGetRTTI(val: Value): GetRTTI
```

Function: Creates an expression to get runtime type information.

Parameters:

- val: Value - Target value.

Return Value:

- [GetRTTI](#class-getrtti) - Runtime type information expression.

Example:

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

Output:

```text
createGetRTTI: true
```

### func createGetRTTIStatic(Type)

```cangjie
public func createGetRTTIStatic(rttiType: Type): GetRTTIStatic
```

Function: Creates an expression to statically get runtime type information.

Parameters:

- rttiType: Type - Target type.

Return Value:

- [GetRTTIStatic](#class-getrttistatic) - Static runtime type information expression.

Example:

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

Output:

```text
createGetRTTIStatic: true
```

### func createGoTo(Block)

```cangjie
public func createGoTo(target: Block): GoTo
```

Function: Creates an unconditional jump expression.

Parameters:

- target: Block - Jump target basic block.

Return Value:

- [GoTo](#class-goto) - Unconditional jump expression.

Example:

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

Output:

```text
createGoTo: true
```

### func createInstanceOf(Value, Type)

```cangjie
public func createInstanceOf(srcVal: Value, targetTy: Type): InstanceOf
```

Function: Creates a type check expression.

Parameters:

- srcVal: Value - Source value.
- targetTy: Type - Target type.

Return Value:

- [InstanceOf](#class-instanceof) - Type check expression.

Example:

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

Output:

```text
createInstanceOf: true
```

### func createInvoke(Type, InvokeCallContext)

```cangjie
public func createInvoke(retTy: Type, callContext: InvokeCallContext): Invoke
```

Function: Creates a virtual method call (Invoke) expression.

Parameters:

- retTy: Type - Return type.
- callContext: InvokeCallContext - Virtual method call context.

Return Value:

- [Invoke](#class-invoke) - Invoke expression.

Example:

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

Output:

```text
createInvoke: true
```

### func createLambda(FuncType, String, String, Array\<GenericType>)

```cangjie
public func createLambda(ty: FuncType, mangledName: String, srcName: String, genericTypeParams!: Array<GenericType> = Array<GenericType>()): Lambda
```

Function: Creates a Lambda expression.

Parameters:

- ty: FuncType - Lambda function type.
- mangledName: String - Mangled name.
- srcName: String - Source name.
- genericTypeParams!: Array\<GenericType> - Generic type parameter list (defaults to empty array).

Return Value:

- [Lambda](#class-lambda) - Lambda expression.

Example:

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

Output:

```text
createLambda: true
```

### func createLoad(Value)

```cangjie
public func createLoad(location: Value): Load
```

Function: Creates a memory load expression.

Parameters:

- location: Value - Memory location value.

Return Value:

- [Load](#class-load) - Memory load expression.

Example:

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

Output:

```text
createLoad: true
```

### func createMultiBranch(Value, Block, ArrayList\<Block>, ArrayList\<UInt64>)

```cangjie
public func createMultiBranch(condition: Value, defaultBlock: Block, targets: ArrayList<Block>, caseValues: ArrayList<UInt64>): MultiBranch
```

Function: Creates a multi-branch (switch) expression.

Parameters:

- condition: Value - Branch condition value.
- defaultBlock: Block - Default target basic block.
- targets: ArrayList\<Block> - List of case branch target basic blocks.
- caseValues: ArrayList\<UInt64> - List of values corresponding to each case branch.

Return Value:

- [MultiBranch](#class-multibranch) - Multi-branch expression.

Example:

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

Output:

```text
createMultiBranch: true
```

### func createNumericCast(Value, Type, OverflowStrategy)

```cangjie
public func createNumericCast(srcVal: Value, dstTy: Type, overflow: OverflowStrategy): NumericCast
```

Function: Creates a numeric type conversion expression.

Parameters:

- srcVal: Value - Source value.
- dstTy: Type - Target numeric type.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [NumericCast](#class-numericcast) - Numeric type conversion expression.

Example:

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

Output:

```text
createNumericCast: true
```

### func createRaiseException(Value)

```cangjie
public func createRaiseException(value: Value): RaiseException
```

Function: Creates a raise exception expression (no successor block).

Parameters:

- value: Value - Exception value.

Return Value:

- [RaiseException](#class-raiseexception) - Raise exception expression.

Example:

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

Output:

```text
createRaiseException_no_successor: true
```

### func createRaiseException(Value, Block)

```cangjie
public func createRaiseException(value: Value, successor: Block): RaiseException
```

Function: Creates a raise exception expression (with successor block).

Parameters:

- value: Value - Exception value.
- successor: Block - Successor basic block after the exception is raised.

Return Value:

- [RaiseException](#class-raiseexception) - Raise exception expression.

Example:

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

Output:

```text
createRaiseException_with_successor: true
```

### func createRawArrayAllocate(Type, Value)

```cangjie
public func createRawArrayAllocate(elementType: Type, size: Value): RawArrayAllocate
```

Function: Creates a raw array allocation expression.

Parameters:

- elementType: Type - Array element type.
- size: Value - Array size value.

Return Value:

- [RawArrayAllocate](#class-rawarrayallocate) - Raw array allocation expression.

Example:

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

Output:

```text
createRawArrayAllocate: true
```

### func createRawArrayInitByValue(Value, Value, Value)

```cangjie
public func createRawArrayInitByValue(memory: Value, size: Value, initVal: Value): RawArrayInitByValue
```

Function: Creates a raw array initialization-by-value expression.

Parameters:

- memory: Value - Array memory location value.
- size: Value - Array size value.
- initVal: Value - Initialization value.

Return Value:

- [RawArrayInitByValue](#class-rawarrayinitbyvalue) - Initialization-by-value expression.

Example:

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

Output:

```text
createRawArrayInitByValue: true
```

### func createRawArrayLiteralInit(Value, ArrayList\<Value>)

```cangjie
public func createRawArrayLiteralInit(memory: Value, elements: ArrayList<Value>): RawArrayLiteralInit
```

Function: Creates a raw array literal initialization expression.

Parameters:

- memory: Value - Array memory location value.
- elements: ArrayList\<Value> - Initialization element value list.

Return Value:

- [RawArrayLiteralInit](#class-rawarrayliteralinit) - Literal initialization expression.

Example:

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

Output:

```text
createRawArrayLiteralInit: true
```

### func createSpawn(Type, Value)

```cangjie
public func createSpawn(retTy: Type, val: Value): Spawn
```

Function: Creates a concurrent Spawn expression.

Parameters:

- retTy: Type - Return type.
- val: Value - The function value to spawn.

Return Value:

- [Spawn](#class-spawn) - Spawn expression.

Example:

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

Output:

```text
createSpawn_no_arg: true
```

### func createSpawn(Type, Value, Value)

```cangjie
public func createSpawn(retTy: Type, val: Value, arg: Value): Spawn
```

Function: Creates a concurrent Spawn expression with an argument.

Parameters:

- retTy: Type - Return type.
- val: Value - The function value to spawn.
- arg: Value - Function argument value.

Return Value:

- [Spawn](#class-spawn) - Spawn expression with argument.

Example:

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

Output:

```text
createSpawn_with_arg: true
```

### func createStaticCast(Value, Type)

```cangjie
public func createStaticCast(srcVal: Value, dstTy: Type): StaticCast
```

Function: Creates a static type conversion expression.

Parameters:

- srcVal: Value - Source value.
- dstTy: Type - Target type.

Return Value:

- [StaticCast](#class-staticcast) - Static type conversion expression.

Example:

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

Output:

```text
createStaticCast: true
```

### func createStore(Value, Value)

```cangjie
public func createStore(val: Value, location: Value): Store
```

Function: Creates a memory store expression.

Parameters:

- val: Value - The value to store.
- location: Value - Memory location value.

Return Value:

- [Store](#class-store) - Memory store expression.

Example:

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

Output:

```text
createStore: true
```

### func createStoreElementByName(Value, Value, ArrayList\<String>)

```cangjie
public func createStoreElementByName(val: Value, location: Value, fieldNames: ArrayList<String>): StoreElementByName
```

Function: Creates an element store expression by field name.

Parameters:

- val: Value - The value to store.
- location: Value - Memory location value.
- fieldNames: ArrayList\<String> - Field name path list.

Return Value:

- [StoreElementByName](#class-storeelementbyname) - Element store expression by field name.

Example:

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

Output:

```text
createStoreElementByName: true
```

### func createStoreElementRef(Value, Value, ArrayList\<UInt64>)

```cangjie
public func createStoreElementRef(val: Value, location: Value, path: ArrayList<UInt64>): StoreElementRef
```

Function: Creates an element store expression by numeric index.

Parameters:

- val: Value - The value to store.
- location: Value - Memory location value.
- path: ArrayList\<UInt64> - Numeric index path list.

Return Value:

- [StoreElementRef](#class-storeelementref) - Element store expression by numeric index.

Example:

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

Output:

```text
createStoreElementRef: true
```

### func createTryAllocate(Type, Block, Block)

```cangjie
public func createTryAllocate(ty: Type, normal: Block, err: Block): TryAllocate
```

Function: Creates a memory allocation expression with exception handling.

Parameters:

- ty: Type - The type to allocate.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryAllocate](#class-tryallocate) - Allocation expression with exception handling.

Example:

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

Output:

```text
createTryAllocate: true
```

### func createTryApply(Value, FuncCallContext, Block, Block)

```cangjie
public func createTryApply(callee: Value, funcCallCtx: FuncCallContext, normal: Block, err: Block): TryApply
```

Function: Creates a function call expression with exception handling.

Parameters:

- callee: Value - The called function value.
- funcCallCtx: FuncCallContext - Function call context.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryApply](#class-tryapply) - Function call expression with exception handling.

Example:

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

Output:

```text
createTryApply: true
```

### func createTryBinaryAdd(Value, Value, Block, Block)

```cangjie
public func createTryBinaryAdd(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

Function: Creates an addition expression with exception handling.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryBinaryExpression](#class-trybinaryexpression) - Addition expression with exception handling.

Example:

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

Output:

```text
createTryBinaryAdd: true
```

### func createTryBinaryDiv(Value, Value, OverflowStrategy, Block, Block)

```cangjie
public func createTryBinaryDiv(leftOp: Value, rightOp: Value, overflow: OverflowStrategy, normal: Block, err: Block): TryBinaryExpression
```

Function: Creates a division expression with exception handling.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- overflow: OverflowStrategy - Overflow strategy.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryBinaryExpression](#class-trybinaryexpression) - Division expression with exception handling.

Example:

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

Output:

```text
createTryBinaryDiv: true
```

### func createTryBinaryExp(Value, Value, Block, Block)

```cangjie
public func createTryBinaryExp(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

Function: Creates an exponentiation expression with exception handling.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryBinaryExpression](#class-trybinaryexpression) - Exponentiation expression with exception handling.

Example:

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

Output:

```text
createTryBinaryExp: true
```

### func createTryBinaryLShift(Value, Value, Block, Block)

```cangjie
public func createTryBinaryLShift(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

Function: Creates a left-shift expression with exception handling.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryBinaryExpression](#class-trybinaryexpression) - Left-shift expression with exception handling.

Example:

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

Output:

```text
createTryBinaryLShift: true
```

### func createTryBinaryMod(Value, Value, Block, Block)

```cangjie
public func createTryBinaryMod(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

Function: Creates a modulo expression with exception handling.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryBinaryExpression](#class-trybinaryexpression) - Modulo expression with exception handling.

Example:

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

Output:

```text
createTryBinaryMod: true
```

### func createTryBinaryMul(Value, Value, Block, Block)

```cangjie
public func createTryBinaryMul(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

Function: Creates a multiplication expression with exception handling.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryBinaryExpression](#class-trybinaryexpression) - Multiplication expression with exception handling.

Example:

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

Output:

```text
createTryBinaryMul: true
```

### func createTryBinaryRShift(Value, Value, Block, Block)

```cangjie
public func createTryBinaryRShift(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

Function: Creates a right-shift expression with exception handling.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryBinaryExpression](#class-trybinaryexpression) - Right-shift expression with exception handling.

Example:

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

Output:

```text
createTryBinaryRShift: true
```

### func createTryBinarySub(Value, Value, Block, Block)

```cangjie
public func createTryBinarySub(leftOp: Value, rightOp: Value, normal: Block, err: Block): TryBinaryExpression
```

Function: Creates a subtraction expression with exception handling.

Parameters:

- leftOp: Value - Left operand.
- rightOp: Value - Right operand.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryBinaryExpression](#class-trybinaryexpression) - Subtraction expression with exception handling.

Example:

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

Output:

```text
createTryBinarySub: true
```

### func createTryInvoke(Type, InvokeCallContext, Block, Block)

```cangjie
public func createTryInvoke(retTy: Type, callContext: InvokeCallContext, normal: Block, err: Block): TryInvoke
```

Function: Creates a virtual method call expression with exception handling.

Parameters:

- retTy: Type - Return type.
- callContext: InvokeCallContext - Virtual method call context.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryInvoke](#class-tryinvoke) - Virtual method call expression with exception handling.

Example:

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

Output:

```text
createTryInvoke: true
```

### func createTryNumericCast(Value, Type, Block, Block)

```cangjie
public func createTryNumericCast(srcVal: Value, dstTy: Type, normal: Block, err: Block): TryNumericCast
```

Function: Creates a numeric type conversion expression with exception handling.

Parameters:

- srcVal: Value - Source value.
- dstTy: Type - Target numeric type.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryNumericCast](#class-trynumericcast) - Numeric type conversion expression with exception handling.

Example:

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

Output:

```text
createTryNumericCast: true
```

### func createTryRawArrayAllocate(Type, Value, Block, Block)

```cangjie
public func createTryRawArrayAllocate(elementType: Type, size: Value, normal: Block, err: Block): TryRawArrayAllocate
```

Function: Creates a raw array allocation expression with exception handling.

Parameters:

- elementType: Type - Array element type.
- size: Value - Array size value.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryRawArrayAllocate](#class-tryrawarrayallocate) - Raw array allocation expression with exception handling.

Example:

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

Output:

```text
createTryRawArrayAllocate: true
```

### func createTrySpawn(Type, Value, Block, Block)

```cangjie
public func createTrySpawn(retTy: Type, val: Value, normal: Block, err: Block): TrySpawn
```

Function: Creates a concurrent Spawn expression with exception handling.

Parameters:

- retTy: Type - Return type.
- val: Value - The function value to spawn.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TrySpawn](#class-tryspawn) - Spawn expression with exception handling.

Example:

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

Output:

```text
createTrySpawn_no_arg: true
```

### func createTrySpawn(Type, Value, Value, Block, Block)

```cangjie
public func createTrySpawn(retTy: Type, val: Value, arg: Value, normal: Block, err: Block): TrySpawn
```

Function: Creates a concurrent Spawn expression with an argument and exception handling.

Parameters:

- retTy: Type - Return type.
- val: Value - The function value to spawn.
- arg: Value - Function argument value.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TrySpawn](#class-tryspawn) - Spawn expression with argument and exception handling.

Example:

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

Output:

```text
createTrySpawn_with_arg: true
```

### func createTryUnaryNeg(Value, Block, Block)

```cangjie
public func createTryUnaryNeg(op: Value, normal: Block, err: Block): TryUnaryExpression
```

Function: Creates a negation unary expression with exception handling.

Parameters:

- op: Value - Operand.
- normal: Block - Normal branch target basic block.
- err: Block - Exception branch target basic block.

Return Value:

- [TryUnaryExpression](#class-tryunaryexpression) - Negation expression with exception handling.

Example:

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

Output:

```text
createTryUnaryNeg: true
```

### func createTuple(Array\<Value>)

```cangjie
public func createTuple(elements: Array<Value>): Tuple
```

Function: Creates a tuple expression.

Parameters:

- elements: Array\<Value> - Tuple element value list.

Return Value:

- [Tuple](#class-tuple) - Tuple expression.

Example:

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

Output:

```text
createTuple: true
```

### func createUnaryBitNot(Value)

```cangjie
public func createUnaryBitNot(op: Value): UnaryExpression
```

Function: Creates a bitwise NOT unary expression.

Parameters:

- op: Value - Operand.

Return Value:

- [UnaryExpression](#class-unaryexpression) - Bitwise NOT expression.

Example:

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

Output:

```text
createUnaryBitNot: true
```

### func createUnaryNeg(Value, OverflowStrategy)

```cangjie
public func createUnaryNeg(op: Value, overflow: OverflowStrategy): UnaryExpression
```

Function: Creates a negation unary expression.

Parameters:

- op: Value - Operand.
- overflow: OverflowStrategy - Overflow strategy.

Return Value:

- [UnaryExpression](#class-unaryexpression) - Negation expression.

Example:

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

Output:

```text
createUnaryNeg: true
```

### func createUnaryNot(Value)

```cangjie
public func createUnaryNot(op: Value): UnaryExpression
```

Function: Creates a logical NOT unary expression.

Parameters:

- op: Value - Operand.

Return Value:

- [UnaryExpression](#class-unaryexpression) - Logical NOT expression.

Example:

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

Output:

```text
createUnaryNot: true
```

### func createUnboxToRef(Value, Type)

```cangjie
public func createUnboxToRef(srcVal: Value, dstTy: Type): UnboxToRef
```

Function: Creates an unbox-to-reference type conversion expression.

Parameters:

- srcVal: Value - Source value.
- dstTy: Type - Target reference type.

Return Value:

- [UnboxToRef](#class-unboxtoref) - Unbox-to-reference expression.

Example:

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

Output:

```text
createUnboxToRef: true
```

### func createUnboxToValue(Value, Type)

```cangjie
public func createUnboxToValue(srcVal: Value, dstTy: Type): UnboxToValue
```

Function: Creates an unbox-to-value type conversion expression.

Parameters:

- srcVal: Value - Source value.
- dstTy: Type - Target value type.

Return Value:

- [UnboxToValue](#class-unboxtovalue) - Unbox-to-value expression.

Example:

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

Output:

```text
createUnboxToValue: true
```

### func createVArray(ArrayList\<Value>)

```cangjie
public func createVArray(elements: ArrayList<Value>): VArrayExpr
```

Function: Creates a VArray expression.

Parameters:

- elements: ArrayList\<Value> - VArray element value list.

Return Value:

- [VArrayExpr](#class-varrayexpr) - VArray expression.

Example:

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

Output:

```text
createVArray: true
```

### func createVArrayBuilder(Type, Value, Value, Value)

```cangjie
public func createVArrayBuilder(retTy: Type, size: Value, initVal: Value, initFunc: Value): VArrayBuilder
```

Function: Creates a VArray builder expression.

Parameters:

- retTy: Type - Return type.
- size: Value - Array size value.
- initVal: Value - Initialization value.
- initFunc: Value - Initialization function value.

Return Value:

- [VArrayBuilder](#class-varraybuilder) - VArray builder expression.

Example:

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

Output:

```text
createVArrayBuilder: true
```

## func serializePackage(Package)

```cangjie
public func serializePackage(pkg: Package): (CPointer<UInt8>, Int64)
```

Function: Serializes an in-memory [Package](#class-package) into a CHIR FlatBuffers binary blob, returning the pointer to the serialized result and its byte length.

Parameters:

- pkg: [Package](#class-package) - The CHIR package to serialize.

Return Value:

- (CPointer\<UInt8>, Int64) - Pointer to the serialized result and its byte length. The caller should call [freeSerializedMemory](#func-freeserializedmemory) to release the memory after use.

Example:

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

Function: Deserializes a CHIR [Package](#class-package) from a FlatBuffers binary buffer.

Parameters:

- root: CPointer\<UInt8> - Pointer to the first byte of the serialized data; must not be null.
- length: Int64 - Byte length of the buffer.

Return Value:

- [Package](#class-package) - The deserialized CHIR package.

Exceptions:

- [CHIRException](#class-chirexception) - Thrown when root is null.

## func freeSerializedMemory()

```cangjie
public func freeSerializedMemory(): Unit
```

Function: Resets the shared FlatBuffers builder state produced by the last serialization.
</task_result>