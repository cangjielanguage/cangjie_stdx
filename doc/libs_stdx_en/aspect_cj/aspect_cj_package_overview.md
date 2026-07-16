# stdx.aspect_cj

> **Note:**
>
> Under active development; functionality is not yet complete.

## Feature Description

The `stdx.aspect_cj` package provides annotations for Aspect-Oriented Programming (AOP) in Cangjie. When used in conjunction with the libstdx.collect_aspects and libstdx.weave_aspects compilation plugins, it enables function instrumentation (before/after) and implementation replacement.

## API List

### Classes

| Class Name                                                    | Functionality                                                |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [InsertAtEntry](./aspect_cj_package_api/aspect_cj_package_classes.md#class-insertatentry) | An annotation class that provides aspect capability. Injects a call to the annotated function at the entry point of the specified method. |
| [InsertAtExit](./aspect_cj_package_api/aspect_cj_package_classes.md#class-insertatexit) | An annotation class that provides aspect capability. Injects a call to the annotated function at the exit point of the specified method. |
| [ReplaceFuncBody](./aspect_cj_package_api/aspect_cj_package_classes.md#class-replacefuncbody) | An annotation class that provides aspect capability. Replaces the method body of the specified method with a call to the annotated function. |

## Specifications and Usage

### Specifications

**Annotation Scope:**

- Annotations currently do not support generic functions, nor can they weave into generic functions;
- Annotations can only be applied to public functions;
- Annotations can be applied to global functions, supporting:
    - Weaving into another global function,
    - Weaving into another instance member function,
    - Weaving into another static member function;
- Annotations can be applied to static member functions, supporting:
    - Weaving into another global function,
    - Weaving into another instance member function,
    - Weaving into another static member function;
- Annotations can be applied to instance member functions, supporting:
    - Weaving into other instance member functions of the same type.

**Global Variable Definition Constraints:**

- In packages defining aspects, only global variables with literal values of basic types (integer, float, Rune, Bool) are allowed; otherwise, compilation will fail. To use out-of-spec global variables, they must be defined in another package and imported to avoid potential circular dependencies after compilation.

**Parameter Constraints:**

- Functions annotated with @InsertAtEntry/@InsertAtExit must have a return type of Unit;
- Functions annotated with @ReplaceFuncBody should have the same return type as the function being woven into;
- If functions annotated with @InsertAtEntry/@InsertAtExit/@ReplaceFuncBody have no parameters, they will always be called without parameters after weaving;
- If functions annotated with @InsertAtEntry/@InsertAtExit/@ReplaceFuncBody have parameters, their parameter list should match the source parameter list of the function being woven into. Additionally:
    - Specifically, if the function being woven into is an instance member function, the `this` parameter must be explicitly included in the parameter list;
    - For functions annotated with @ReplaceFuncBody, an additional parameter must be added. The type of this parameter should match the function being woven into, representing the closure of the original version of the function.

### Usage

To fully implement AOP functionality, in addition to using the aforementioned annotation classes to define aspects, two compilation plugins are required:

- libstdx.collect_aspects.so(.dll/.dylib)
- libstdx.weave_aspects.so(.dll/.dylib)

These compilation plugins are provided as dynamic libraries in stdx.aspect_cj, with different versions for different platforms.

First, use libstdx.collect_aspects to collect all aspect and join point information during compilation. Then use libstdx.weave_aspects for secondary compilation to weave the collected aspects into the join points.