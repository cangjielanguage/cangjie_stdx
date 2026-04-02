/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

/**
 * Represents a class definition in the CHIR representation.
 *
 * A ClassLikeDef can represent either a class or an interface. It extends CustomTypeDef
 * and provides methods to access class-specific information such as the super class.
 */
public class ClassLikeDef <: CustomTypeDef & Equatable<ClassLikeDef> {
    internal var _isAnnotation: Bool = false
    internal var _isClass: Bool
    internal var _superClass: ?ClassLikeType = None

    /**
     * Gets the ClassLikeType associated with this class definition.
     * @type { ClassLikeType }
     */
    public prop classType: ClassLikeType {
        get() {
            return (_type.getOrThrow() as ClassLikeType).getOrThrow()
        }
    }

    /**
     * Gets or sets whether this class-like definition represents an annotation class.
     * @type { Bool }
     */
    public mut prop isAnnotation: Bool {
        get() {
            return _isAnnotation
        }
        set(v) {
            _isAnnotation = v
        }
    }

    /**
     * Gets or sets the super class type of this class.
     *
     * If this class has no super class, the value is None.
     * @type { ?ClassLikeType }
     */
    public mut prop superClass: ?ClassLikeType {
        get() {
            return _superClass
        }
        set(v) {
            _superClass = v
        }
    }

    internal init(identifier: String, srcName: String, pkgName: String, isClass: Bool) {
        super(CustomDefKind.ClassLike, identifier, srcName, pkgName)
        this._isClass = isClass
        this._hashCode = calculateHashCode()
    }

    /**
     * Sets or clears the abstract attribute on this class or interface.
     * @param enable true to mark abstract, false to clear.
     */
    public func setAbstract(enable: Bool): Unit {
        _attributes.setAttr(Attribute.Abstract, enable)
    }

    /**
     * Sets or clears the open (virtual) attribute on this class or interface.
     * @param enable true to mark open for inheritance, false to clear virtual flag used for that purpose.
     */
    public func setOpen(enable: Bool): Unit {
        _attributes.setAttr(Attribute.Virtual, enable)
    }

    /**
     * Sets or clears the sealed attribute on this class or interface.
     * @param enable true to mark sealed, false to clear.
     */
    public func setSealed(enable: Bool): Unit {
        _attributes.setAttr(Attribute.Sealed, enable)
    }

    protected override func printTitle(): String {
        let superClassStr = StringBuilder()
        if (let Some(superClass) <- _superClass) {
            superClassStr.append(superClass.toString())
            superClassStr.append(if (implementedInterfaceTypes.isEmpty()) { " <: " } else { " & " })
        }
        return super.printTitle() + superClassStr.toString()
    }

    /**
     * Checks if this ClassLikeDef is equal to another ClassLikeDef.
     * @param other The ClassLikeDef to compare with.
     * @return true if the definitions are equal, false otherwise.
     */
    public operator func==(other: ClassLikeDef): Bool {
        return isSameDef(other)
    }
}
