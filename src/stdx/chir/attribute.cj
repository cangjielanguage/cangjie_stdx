/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

import std.deriving.*

const ATTR_SIZE: UInt64 = 64

@Derive[Equatable]
internal enum Attribute <: ToString {
    AttrBegin |
    Static |    ///< Mark whether a member is a static one.
    Public |    ///< Mark whether a member is a public one.
    Private |   ///< Mark whether a member is a private one.
    Protected | ///< Mark whether a member is a protected one.

    Abstract | ///< Mark whether a function is an abstract one.
    Virtual |  ///< Mark whether a declaration is in fact open (even if the user does not use `open` keyword).

    Override | ///< Mark whether a declaration in fact overrides the inherited one
              ///(even if the user does not use `override` keyword).

    Redef | ///< Mark whether a declaration in fact overrides the inherited one (even if the user does not use
           ///< `redef` keyword).

    Sealed |  ///< Mark whether a declaration is a sealed one.
    Foreign | ///< Mark whether a declaration is a foreign one.

    Mut |      ///< Mark whether a declaration is a mutable one.
    Final |    ///< Mark a Func override a parent class's func, and this func self does not have VIRTUAL Attribute.
    Operator | ///< Mark whether a declaration is a operator one.
    ReadOnly |             ///< 'let x = xxx', 'x' enable READONLY attribute
    Const |                ///< correspond `const` keyword in Cangjie source code.
    Imported |             ///< Mark whether variable、func、enum、struct、class is imported from other package.
    GenericInstantiated | ///< Mark whether a `GlobalVar/Func/Type` is instantiated.
    NoDebugInfo |        ///< Mark a `Value` doesn't contain debug info, like line/column number.
    Generic |              ///< Mark a declaration is generic
    Internal |             ///< GlobalVar/Func/Enum/Class/Struct/Interface is visible in current and sub package.
    CompilerAdd |         ///< Mark a `Value` is added by compiler, like "copied default func from interface".

    // compiler attribute
    NoReflectInfo | ///< Mark a `Value` is't used by `reflect` feature.
    NoInline |       ///< Mark a Func can't be inlined.
    NonRecompile |   ///< only used in `ImportedValue` in incremental compilation, indicate this ImportedValue is
                     ///< converted from a decl in current package that is not recompiled.
    Unreachable |     ///< Mark a Block is unreachable.
    NoSideEffect |  ///< Mark a Func does't have side effect.
    Common |          ///< Mark whether it's common declaration.
    Platform |        ///< Mark whether it's platform declaration.
    SkipAnalysis |   ///< Mark node that is not used for analysis.
                     ///< e.g. Node can be skiped if it has no body when creating 'common part'
    Deserialized |    ///< Node deserialized from .chir file
    Initializer |     ///< Mark nodes that related to initialization process.
                     ///< Marked functions are package initializer, file initializers, variable initializer or so.
                     ///< On the block is used to search for it among other blocks of the function.
    Unsafe |   ///< Mark whether a function that was marked as `unsafe`
    // Native FFI attributes
    JavaMirror |      ///< Mark whether it's @JavaMirror declaration (binding for a java type).
    JavaImpl |        ///< Mark whether it's @JavaImpl declaration.
    ObjCMirror |     ///< Mark whether it's @ObjCMirror declaration (binding for an Objective-C type).
    HasInitedField | ///< Mark whether a node is a special flag, which marks the class instance as initialized.
    JavaHasDefault | ///< Mark whether JAVA_MIRROR interface has default method.
    PreviouslyDeserialized | ///< Mark that deserialization occurs not in the newly created node, but in an existing one.
    PluginAdded | ///< Mark that the declaration is added by chir plugin.

    AttrEnd

    /**
     * Converts this attribute flag to its stable keyword string used in CHIR text output.
     * @return The attribute name string, or "UNKNOWN" for sentinel values.
     */
    public func toString(): String {
        match (this) {
            case Static                 => "static"
            case Public                 => "public"
            case Private                => "private"
            case Protected              => "protected"
            case Abstract               => "abstract"
            case Virtual                => "virtual"
            case Override               => "override"
            case Redef                  => "redef"
            case Sealed                 => "sealed"
            case Foreign                => "foreign"
            case Mut                    => "mut"
            case Operator               => "operator"
            case Const                  => "compileTimeVal"
            case ReadOnly               => "readOnly"
            case Imported               => "imported"
            case NonRecompile           => "nonRecompile"
            case GenericInstantiated    => "generic_instantiated"
            case Internal               => "internal"
            case CompilerAdd            => "compilerAdd"
            case Generic                => "generic"
            case NoReflectInfo          => "noReflectInfo"
            case NoInline               => "noInline"
            case NoDebugInfo            => "noDebugInfo"
            case Unreachable            => "unreachable"
            case NoSideEffect           => "noSideEffect"
            case Final                  => "final"
            case Common                 => "common"
            case Platform               => "platform"
            case SkipAnalysis           => "skip_analysis"
            case Deserialized           => "deserialized"
            case Initializer            => "initializer"
            case Unsafe                 => "unsafe"
            case JavaMirror             => "javaMirror"
            case JavaImpl               => "javaImpl"
            case ObjCMirror             => "objCMirror"
            case HasInitedField         => "hasInitedField"
            case JavaHasDefault         => "javaHasDefault"
            case PreviouslyDeserialized => "previouslyDeserialized"
            case PluginAdded            => "pluginAdded"
            case AttrBegin | AttrEnd => "UNKNOWN"
        }
    }

    internal func getNextAttribute(): Attribute {
        match (this) {
            case AttrBegin              => Static
            case Static                 => Public
            case Public                 => Private
            case Private                => Protected
            case Protected              => Abstract
            case Abstract               => Virtual
            case Virtual                => Override
            case Override               => Redef
            case Redef                  => Sealed
            case Sealed                 => Foreign
            case Foreign                => Mut
            case Mut                    => Final
            case Final                  => Operator
            case Operator               => ReadOnly
            case ReadOnly               => Const
            case Const                  => Imported
            case Imported               => GenericInstantiated
            case GenericInstantiated    => NoDebugInfo
            case NoDebugInfo            => Generic
            case Generic                => Internal
            case Internal               => CompilerAdd
            case CompilerAdd            => NoReflectInfo
            case NoReflectInfo          => NoInline
            case NoInline               => NonRecompile
            case NonRecompile           => Unreachable
            case Unreachable            => NoSideEffect
            case NoSideEffect           => Common
            case Common                 => Platform
            case Platform               => SkipAnalysis
            case SkipAnalysis           => Deserialized
            case Deserialized           => Initializer
            case Initializer            => Unsafe
            case Unsafe                 => JavaMirror
            case JavaMirror             => JavaImpl
            case JavaImpl               => ObjCMirror
            case ObjCMirror             => HasInitedField
            case HasInitedField         => JavaHasDefault
            case JavaHasDefault         => PreviouslyDeserialized
            case PreviouslyDeserialized => PluginAdded
            case PluginAdded            => AttrEnd
            case AttrEnd                => AttrEnd
        }
    }

    internal func toUInt64(): UInt64 {
        match (this) {
            case AttrBegin              => 0  // just a placeholder
            case Static                 => 0
            case Public                 => 1
            case Private                => 2
            case Protected              => 3
            case Abstract               => 4
            case Virtual                => 5
            case Override               => 6
            case Redef                  => 7
            case Sealed                 => 8
            case Foreign                => 9
            case Mut                    => 10
            case Final                  => 11
            case Operator               => 12
            case ReadOnly               => 13
            case Const                  => 14
            case Imported               => 15
            case GenericInstantiated    => 16
            case NoDebugInfo            => 17
            case Generic                => 18
            case Internal               => 19
            case CompilerAdd            => 20
            case NoReflectInfo          => 21
            case NoInline               => 22
            case NonRecompile           => 23
            case Unreachable            => 24
            case NoSideEffect           => 25
            case Common                 => 26
            case Platform               => 27
            case SkipAnalysis           => 28
            case Deserialized           => 29
            case Initializer            => 30
            case Unsafe                 => 31
            case JavaMirror             => 32
            case JavaImpl               => 33
            case ObjCMirror             => 34
            case HasInitedField         => 35
            case JavaHasDefault         => 36
            case PreviouslyDeserialized => 37
            case PluginAdded            => 38
            case AttrEnd                => ATTR_SIZE  // Invalid, return size to indicate error
        }
    }
}

/**
 * AttributeInfo class for managing attribute flags
 * Uses a bitset-like approach with UInt64 to store up to 64 attributes
 */
internal struct AttributeInfo <: ToString {
    internal var _attributesInfo: UInt64 = 0

    /**
     * Builds a bracketed list of all set attribute names (e.g. "[public][static]").
     * @return Concatenated attribute tags for debugging or pretty-printing.
     */
    public func toString(): String {
        let result = StringBuilder()
        // Iterate through all attributes and build string
        var current: Attribute = Attribute.AttrBegin.getNextAttribute()
        while (true) {
            if (testAttr(current)) {
                result.append("[")
                result.append(current.toString())
                result.append("]")
            }
            // Move to next attribute (simplified iteration)
            current = current.getNextAttribute()
            if (current == Attribute.AttrEnd) {
                break
            }
        }
        return result.toString()
    }

    internal init() {
        this._attributesInfo = 0
    }

    internal init(attrs: UInt64) {
        this._attributesInfo = attrs
    }

    internal func clone(): AttributeInfo {
        return AttributeInfo(_attributesInfo)
    }

    /**
     * Set an attribute to enabled or disabled
     */
    internal mut func setAttr(attr: Attribute, enable: Bool): Unit {
        if (enable) {
            let bitIndex = attr.toUInt64()
            if (bitIndex < ATTR_SIZE) {
                _attributesInfo |= UInt64(1)  << bitIndex
            } else {
                throw CHIRException("set failed, Attribute index out of range")
            }
        } else {
            let bitIndex = attr.toUInt64()
            if (bitIndex < ATTR_SIZE) {
                _attributesInfo &= !(UInt64(1) << bitIndex)
            } else {
                throw CHIRException("set failed, Attribute index out of range")
            }
        }
    }

    /**
     * Test whether an attribute is set
     */
    internal func testAttr(attr: Attribute): Bool {
        let bitIndex = attr.toUInt64()
        if (bitIndex >= ATTR_SIZE) {
            return false
        }
        return (_attributesInfo & (UInt64(1) << bitIndex)) != 0
    }

    internal mut func appendAttrs(info : AttributeInfo): Unit {
        _attributesInfo |= info._attributesInfo
    }

    internal func getRawAttrs(): UInt64 {
        return _attributesInfo
    }

    internal mut func setInternal(): Unit {
        setAttr(Attribute.Internal, true)
        setAttr(Attribute.Public, false)
        setAttr(Attribute.Private, false)
        setAttr(Attribute.Protected, false)
    }

    internal mut func setPublic(): Unit {
        setAttr(Attribute.Public, true)
        setAttr(Attribute.Private, false)
        setAttr(Attribute.Protected, false)
        setAttr(Attribute.Internal, false)
    }

    internal mut func setPrivate(): Unit {
        setAttr(Attribute.Private, true)
        setAttr(Attribute.Public, false)
        setAttr(Attribute.Protected, false)
        setAttr(Attribute.Internal, false)
    }

    internal mut func setProtected(): Unit {
        setAttr(Attribute.Protected, true)
        setAttr(Attribute.Public, false)
        setAttr(Attribute.Private, false)
        setAttr(Attribute.Internal, false)
    }
}
