# 类

## class SecureRandom

```cangjie
public class SecureRandom <: RandomGenerator {
    public init(priv!: Bool = false)
}
```

功能：用于生成加密安全的伪随机数。

和 Random 相比，主要有三个方面不同：

- 随机数种子： Random 使用系统时钟作为默认的种子，时间戳一样，结果就相同；[SecureRandom](crypto_package_classes.md#class-securerandom) 使用操作系统或者硬件提供的随机数种子，生成的是真随机数。
- 随机数生成： Random 使用了梅森旋转伪随机生成器；[SecureRandom](crypto_package_classes.md#class-securerandom) 则使用了 OpenSSL 库提供的 `RAND_bytes` / `RAND_priv_bytes` 密码学安全伪随机数生成接口（内部基于 AES-256-CTR DRBG 等算法，并使用操作系统提供的熵源作为种子）；如果硬件支持，OpenSSL 还可以利用硬件随机数生成器来增强随机数的安全性。
- 安全性： Random 不能用于加密安全的应用或者隐私数据的保护，可以使用 [SecureRandom](crypto_package_classes.md#class-securerandom)。

使用示例见 [SecureRandom 使用](../crypto_samples/sample_secure_random.md)。

父类型：

- [RandomGenerator](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-randomgenerator)

### init(Bool)

```cangjie
public init(priv!: Bool = false)
```

功能：创建 [SecureRandom](crypto_package_classes.md#class-securerandom) 实例，可指定是否使用更加安全的加密安全伪随机生成器，加密安全伪随机生成器可用于会话密钥和证书私钥等加密场景。

参数：

- priv!: Bool - 设置为 true 表示使用加密安全伪随机生成器。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    // 创建一个默认的SecureRandom实例
    let random1 = SecureRandom()
    println("创建默认SecureRandom实例成功")

    // 创建一个使用更加安全的SecureRandom实例
    let random2 = SecureRandom(priv: true)
    println("创建使用更加安全的SecureRandom实例成功")

    return 0
}
```

可能的运行结果：

```text
创建默认SecureRandom实例成功
创建使用更加安全的SecureRandom实例成功
```

### func nextBits(UInt64)

```cangjie
public func nextBits(bits: UInt64): UInt64
```

功能：生成一个指定位长的随机整数。

参数：

- bits: UInt64 - 要生成的随机数的位数，取值范围 (0, 64]。

返回值：

- UInt64 - 生成的指定位长的随机数。

异常：

- IllegalArgumentException - 如果 `bits` 等于 0，或大于 64，超过所能截取的 UInt64 长度，则抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个指定位数的随机数
    let num1 = random.nextBits(8) // 生成8位的随机数
    println("生成的8位随机数: ${num1}")

    let num2 = random.nextBits(16) // 生成16位的随机数
    println("生成的16位随机数: ${num2}")

    let num3 = random.nextBits(32) // 生成32位的随机数
    println("生成的32位随机数: ${num3}")

    return 0
}
```

可能的运行结果：

```text
生成的8位随机数: 17
生成的16位随机数: 45263
生成的32位随机数: 2128153426
```

### func nextBool()

```cangjie
public func nextBool(): Bool
```

功能：获取一个随机的 Bool 类型实例。

返回值：

- Bool - 一个随机的 Bool 类型实例。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个布尔类型的随机数
    let bool1 = random.nextBool()
    println("生成的布尔随机数1: ${bool1}")

    let bool2 = random.nextBool()
    println("生成的布尔随机数2: ${bool2}")
    return 0
}
```

可能的运行结果：

```text
生成的布尔随机数1: false
生成的布尔随机数2: false
```

### func nextBytes(Array\<Byte>)

```cangjie
public func nextBytes(bytes: Array<Byte>): Unit
```

功能：生成随机数替换入参数组中的每个元素。

参数：

- bytes: Array\<Byte> - 被替换的数组。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 创建一个字节数组并用随机数填充
    let bytes = Array<Byte>(10, repeat: 0) // 创建包含10个字节的数组，初始值为0
    println("填充前的数组: ${bytes}")

    random.nextBytes(bytes) // 用随机数填充数组
    println("填充后的数组: ${bytes}")

    return 0
}
```

可能的运行结果：

```text
填充前的数组: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
填充后的数组: [120, 13, 17, 140, 252, 106, 71, 121, 211, 28]
```

### func nextBytes(Int32)

```cangjie
public func nextBytes(length: Int32): Array<Byte>
```

功能：获取一个指定长度的随机字节的数组。

参数：

- length: Int32 - 要生成的随机字节数组的长度。

返回值：

- Array\<Byte> - 一个随机字节数组。

异常：

- IllegalArgumentException - 当参数 length 小于等于 0，抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成一个包含5个随机字节的数组
    let bytes1 = random.nextBytes(5)
    println("成功生成5个随机字节的数组: ${bytes1}")

    // 生成一个包含10个随机字节的数组
    let bytes2 = random.nextBytes(10)
    println("成功生成10个随机字节的数组: ${bytes2}")

    return 0
}
```

可能的运行结果：

```text
成功生成5个随机字节的数组: [89, 31, 206, 132, 25]
成功生成10个随机字节的数组: [232, 228, 56, 119, 208, 142, 53, 221, 166, 96]
```

### func nextFloat16()

```cangjie
public func nextFloat16(): Float16
```

功能：获取一个 Float16 类型且在区间 [0.0, 1.0) 内的随机数。

返回值：

- Float16 - 一个 Float16 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个Float16类型的随机数
    let num1 = random.nextFloat16()
    println("生成的Float16随机数1: ${num1}")

    let num2 = random.nextFloat16()
    println("生成的Float16随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Float16随机数1: 0.237305
生成的Float16随机数2: 0.362305
```

### func nextFloat32()

```cangjie
public func nextFloat32(): Float32
```

功能：获取一个 Float32 类型且在区间 [0.0, 1.0) 内的随机数。

返回值：

- Float32 - 一个 Float32 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个Float32类型的随机数
    let num1 = random.nextFloat32()
    println("生成的Float32随机数1: ${num1}")

    let num2 = random.nextFloat32()
    println("生成的Float32随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Float32随机数1: 0.830997
生成的Float32随机数2: 0.599951
```

### func nextFloat64()

```cangjie
public func nextFloat64(): Float64
```

功能：获取一个 Float64 类型且在区间 [0.0, 1.0) 内的随机数。

返回值：

- Float64 - 一个 Float64 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个Float64类型的随机数
    let num1 = random.nextFloat64()
    println("生成的Float64随机数1: ${num1}")

    let num2 = random.nextFloat64()
    println("生成的Float64随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Float64随机数1: 0.665093
生成的Float64随机数2: 0.026271
```

### func nextGaussianFloat16(Float16, Float16)

```cangjie
public func nextGaussianFloat16(mean!: Float16 = 0.0, sigma!: Float16 = 1.0): Float16
```

功能：默认获取一个 Float16 类型且符合均值为 0.0 标准差为 1.0 的高斯分布的随机数，其中均值是期望值，可解释为位置参数，决定了分布的位置，标准差可解释为尺度参数，决定了分布的幅度。

参数：

- mean!: Float16 - 均值。
- sigma!: Float16 - 标准差。

返回值：

- Float16 - 一个 Float16 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个高斯分布的Float16类型的随机数，均值为0.5，标准差为0.1
    let num1 = random.nextGaussianFloat16(mean: 0.5, sigma: 0.1)
    println("生成的高斯Float16随机数1: ${num1}")

    let num2 = random.nextGaussianFloat16(mean: 0.5, sigma: 0.1)
    println("生成的高斯Float16随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的高斯Float16随机数1: 0.597168
生成的高斯Float16随机数2: 0.659668
```

### func nextGaussianFloat32(Float32, Float32)

```cangjie
public func nextGaussianFloat32(mean!: Float32 = 0.0, sigma!: Float32 = 1.0): Float32
```

功能：默认获取一个 Float32 类型且符合均值为 0.0 标准差为 1.0 的高斯分布的随机数，其中均值是期望值，可解释为位置参数，决定了分布的位置，标准差可解释为尺度参数，决定了分布的幅度。

参数：

- mean!: Float32 - 均值。
- sigma!: Float32 - 标准差。

返回值：

- Float32 - 一个 Float32 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个高斯分布的Float32类型的随机数，均值为0.5，标准差为0.1
    let num1 = random.nextGaussianFloat32(mean: 0.5, sigma: 0.1)
    println("生成的高斯Float32随机数1: ${num1}")

    let num2 = random.nextGaussianFloat32(mean: 0.5, sigma: 0.1)
    println("生成的高斯Float32随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的高斯Float32随机数1: 0.512646
生成的高斯Float32随机数2: 0.457472
```

### func nextGaussianFloat64(Float64, Float64)

```cangjie
public func nextGaussianFloat64(mean!: Float64 = 0.0, sigma!: Float64 = 1.0): Float64
```

功能：默认获取一个 Float64 类型且符合均值为 0.0 标准差为 1.0 的高斯分布的随机数，其中均值是期望值，可解释为位置参数，决定了分布的位置，标准差可解释为尺度参数，决定了分布的幅度。

参数：

- mean!: Float64 - 均值。
- sigma!: Float64 - 标准差。

返回值：

- Float64 - 一个 Float64 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个高斯分布的Float64类型的随机数，均值为0.5，标准差为0.1
    let num1 = random.nextGaussianFloat64(mean: 0.5, sigma: 0.1)
    println("生成的高斯Float64随机数1: ${num1}")

    let num2 = random.nextGaussianFloat64(mean: 0.5, sigma: 0.1)
    println("生成的高斯Float64随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的高斯Float64随机数1: 0.411050
生成的高斯Float64随机数2: 0.531717
```

### func nextInt16()

```cangjie
public func nextInt16(): Int16
```

功能：获取一个 Int16 类型的随机数。

返回值：

- Int16 - 一个 Int16 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个Int16类型的随机数
    let num1 = random.nextInt16()
    println("生成的Int16随机数1: ${num1}")

    let num2 = random.nextInt16()
    println("生成的Int16随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Int16随机数1: -30796
生成的Int16随机数2: -23424
```

### func nextInt16(Int16)

```cangjie
public func nextInt16(max: Int16): Int16
```

功能：获取一个 Int16 类型且在区间 [0, max) 内的随机数。

参数：

- max: Int16 - 区间最大值。

返回值：

- Int16 - 一个 Int16 类型的随机数。

异常：

- IllegalArgumentException - 当 max 为非正数时，抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个在指定范围内的Int16类型的随机数
    let num1 = random.nextInt16(100)
    println("生成的Int16随机数1 (0-100): ${num1}")

    let num2 = random.nextInt16(100)
    println("生成的Int16随机数2 (0-100): ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Int16随机数1 (0-100): 27
生成的Int16随机数2 (0-100): 23
```

### func nextInt32()

```cangjie
public func nextInt32(): Int32
```

功能：获取一个 Int32 类型的随机数。

返回值：

- Int32 - 一个 Int32 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个Int32类型的随机数
    let num1 = random.nextInt32()
    println("生成的Int32随机数1: ${num1}")

    let num2 = random.nextInt32()
    println("生成的Int32随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Int32随机数1: -33263071
生成的Int32随机数2: -853238350
```

### func nextInt32(Int32)

```cangjie
public func nextInt32(max: Int32): Int32
```

功能：获取一个 Int32 类型且在区间 [0, max) 内的随机数。

参数：

- max: Int32 - 区间最大值。

返回值：

- Int32 - 一个 Int32 类型的随机数。

异常：

- IllegalArgumentException - 当 max 为非正数时，抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个在指定范围内的Int32类型的随机数
    let num1 = random.nextInt32(1000)
    println("生成的Int32随机数1 (0-1000): ${num1}")

    let num2 = random.nextInt32(1000)
    println("生成的Int32随机数2 (0-1000): ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Int32随机数1 (0-1000): 469
生成的Int32随机数2 (0-1000): 47
```

### func nextInt64()

```cangjie
public func nextInt64(): Int64
```

功能：获取一个 Int64 类型的随机数。

返回值：

- Int64 - 一个 Int64 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个Int64类型的随机数
    let num1 = random.nextInt64()
    println("生成的Int64随机数1: ${num1}")

    let num2 = random.nextInt64()
    println("生成的Int64随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Int64随机数1: -3331154220163065762
生成的Int64随机数2: 6412631069792762051
```

### func nextInt64(Int64)

```cangjie
public func nextInt64(max: Int64): Int64
```

功能：获取一个 Int64 类型且在区间 [0, max) 内的随机数。

参数：

- max: Int64 - 区间最大值。

返回值：

- Int64 - 一个 Int64 类型的随机数。

异常：

- IllegalArgumentException - 当 max 为非正数时，抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个在指定范围内的Int64类型的随机数
    let num1 = random.nextInt64(1000000)
    println("生成的Int64随机数1 (0-1000000): ${num1}")

    let num2 = random.nextInt64(1000000)
    println("生成的Int64随机数2 (0-1000000): ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Int64随机数1 (0-1000000): 874128
生成的Int64随机数2 (0-1000000): 129569
```

### func nextInt8()

```cangjie
public func nextInt8(): Int8
```

功能：获取一个 Int8 类型的随机数。

返回值：

- Int8 - 一个 Int8 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个Int8类型的随机数
    let num1 = random.nextInt8()
    println("生成的Int8随机数1: ${num1}")

    let num2 = random.nextInt8()
    println("生成的Int8随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Int8随机数1: -21
生成的Int8随机数2: 70
```

### func nextInt8(Int8)

```cangjie
public func nextInt8(max: Int8): Int8
```

功能：获取一个 Int8 类型且在区间 [0, max) 内的随机数。

参数：

- max: Int8 - 区间最大值。

返回值：

- Int8 - 一个 Int8 类型的随机数。

异常：

- IllegalArgumentException - 当 max 为非正数时，抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个在指定范围内的Int8类型的随机数
    let num1 = random.nextInt8(100)
    println("生成的Int8随机数1 (0-100): ${num1}")

    let num2 = random.nextInt8(100)
    println("生成的Int8随机数2 (0-100): ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的Int8随机数1 (0-100): 72
生成的Int8随机数2 (0-100): 35
```

### func nextUInt16()

```cangjie
public func nextUInt16(): UInt16
```

功能：获取一个 UInt16 类型的随机数。

返回值：

- UInt16 - 一个 UInt16 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个UInt16类型的随机数
    let num1 = random.nextUInt16()
    println("生成的UInt16随机数1: ${num1}")

    let num2 = random.nextUInt16()
    println("生成的UInt16随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的UInt16随机数1: 23354
生成的UInt16随机数2: 46516
```

### func nextUInt16(UInt16)

```cangjie
public func nextUInt16(max: UInt16): UInt16
```

功能：获取一个 UInt16 类型且在区间 [0, max) 内的随机数。

参数：

- max: UInt16 - 区间最大值。

返回值：

- UInt16 - 一个 UInt16 类型的随机数。

异常：

- IllegalArgumentException - 当 max 为 0 时，抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个UInt16范围内的随机数
    let num1 = random.nextUInt16(1000) // 生成0-999之间的随机数
    println("生成的UInt16随机数(0-999): ${num1}")

    let num2 = random.nextUInt16(5000) // 生成0-4999之间的随机数
    println("生成的UInt16随机数(0-4999): ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的UInt16随机数(0-999): 674
生成的UInt16随机数(0-4999): 3879
```

### func nextUInt32()

```cangjie
public func nextUInt32(): UInt32
```

功能：获取一个 UInt32 类型的随机数。

返回值：

- UInt32 - 一个 UInt32 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个UInt32类型的随机数
    let num1 = random.nextUInt32()
    println("生成的UInt32随机数1: ${num1}")

    let num2 = random.nextUInt32()
    println("生成的UInt32随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的UInt32随机数1: 2512231137
生成的UInt32随机数2: 1654221431
```

### func nextUInt32(UInt32)

```cangjie
public func nextUInt32(max: UInt32): UInt32
```

功能：获取一个 UInt32 类型且在区间 [0, max) 内的随机数。

参数：

- max: UInt32 - 区间最大值。

返回值：

- UInt32 - 一个 UInt32 类型的随机数。

异常：

- IllegalArgumentException - 当 max 为 0 时，抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个UInt32范围内的随机数
    let num1 = random.nextUInt32(100000) // 生成0-99999之间的随机数
    println("生成的UInt32随机数(0-99999): ${num1}")

    let num2 = random.nextUInt32(1000000) // 生成0-999999之间的随机数
    println("生成的UInt32随机数(0-999999): ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的UInt32随机数(0-99999): 99820
生成的UInt32随机数(0-999999): 661325
```

### func nextUInt64()

```cangjie
public func nextUInt64(): UInt64
```

功能：获取一个 UInt64 类型的随机数。

返回值：

- UInt64 - 一个 UInt64 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个UInt64类型的随机数
    let num1 = random.nextUInt64()
    println("生成的UInt64随机数1: ${num1}")

    let num2 = random.nextUInt64()
    println("生成的UInt64随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的UInt64随机数1: 11677076453013864441
生成的UInt64随机数2: 4153549476048086930
```

### func nextUInt64(UInt64)

```cangjie
public func nextUInt64(max: UInt64): UInt64
```

功能：获取一个 UInt64 类型且在区间 [0, max) 内的随机数。

参数：

- max: UInt64 - 区间最大值。

返回值：

- UInt64 - 一个 UInt64 类型的随机数。

异常：

- IllegalArgumentException - 当 max 为 0 时，抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个UInt64范围内的随机数
    let num1 = random.nextUInt64(1000000000000) // 生成0-999999999999之间的随机数
    println("生成的UInt64随机数(0-999999999999): ${num1}")

    let num2 = random.nextUInt64(100000000000000) // 生成0-99999999999999之间的随机数
    println("生成的UInt64随机数(0-99999999999999): ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的UInt64随机数(0-999999999999): 606328247182
生成的UInt64随机数(0-99999999999999): 24041701587638
```

### func nextUInt8()

```cangjie
public func nextUInt8(): UInt8
```

功能：获取一个 UInt8 类型的随机数。

返回值：

- UInt8 - 一个 UInt8 类型的随机数。

异常：

- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个UInt8类型的随机数
    let num1 = random.nextUInt8()
    println("生成的UInt8随机数1: ${num1}")

    let num2 = random.nextUInt8()
    println("生成的UInt8随机数2: ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的UInt8随机数1: 21
生成的UInt8随机数2: 160
```

### func nextUInt8(UInt8)

```cangjie
public func nextUInt8(max: UInt8): UInt8
```

功能：获取一个 UInt8 类型且在区间 [0, max) 内的随机数。

参数：

- max: UInt8 - 区间最大值。

返回值：

- UInt8 - 一个 UInt8 类型的随机数。

异常：

- IllegalArgumentException - 当 max 为 0 时，抛出异常。
- [SecureRandomException](crypto_package_exceptions.md#class-securerandomexception) - 当生成器不能正确生成随机数或生成随机数失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom()

    // 生成几个UInt8范围内的随机数
    let num1 = random.nextUInt8(100) // 生成0-99之间的随机数
    println("生成的UInt8随机数(0-99): ${num1}")

    let num2 = random.nextUInt8(50) // 生成0-49之间的随机数
    println("生成的UInt8随机数(0-49): ${num2}")
    return 0
}
```

可能的运行结果：

```text
生成的UInt8随机数(0-99): 60
生成的UInt8随机数(0-49): 30
```

## class SM4

```cangjie
public class SM4 <: BlockCipher {
    public init(
        optMode: OperationMode,
        key: Array<Byte>,
        iv!: Array<Byte> = Array<Byte>(),
        paddingMode!: PaddingMode = PaddingMode.PKCS7Padding,
        aad!: Array<Byte> = Array<Byte>(),
        tagSize!: Int64 = 16
    )
}
```

功能：提供国密 SM4 对称加解密。

目前 SM4 支持的加解密工作模式由 [OperationMode](crypto_package_structs.md#struct-operationmode) 定义，目前支持 ECB、CBC、OFB、CFB、CTR、GCM 模式。

不同的工作模式可能对应的加解密实现不同，安全性也不同。需要选择和场景适配的加解密工作模式。

iv 初始化向量在 GCM 模式下可以设置推荐长度是 12 字节，在 CBC、OFB、CFB、CTR 模式下 iv 长度是 16 字节，在 ECB 模式下 iv 可以不设置。

paddingMode 填充模式模式由 [PaddingMode](crypto_package_structs.md#struct-paddingmode) 定义， 目前支持 NoPadding 非填充、PKCS7Padding PKCS7 填充。默认是 PKCS7 填充。

paddingMode 设置对 ECB 和 CBC 有效，ECB 和 CBC 分组加解密需要分组长度等于 blockSize。会根据填充模式进行填充。 paddingMode 设置对 OFB、CFB、CTR、GCM 工作模式无效，这些工作模式均无需填充。

如果选择 NoPadding 模式，即不填充。则在 ECB 和 CBC 工作模式下用户需要对数据是否可以分组负责，如果数据不能分组，或者最后一组数据长度不足 blockSize 则会报错。

aad 附加数据，仅在 GCM 模式下使用，由用户填充，参与摘要计算，默认为空。

tagSize 设置摘要长度，仅在 GCM 模式下使用，默认值为 SM4_GCM_TAG_SIZE 16 字节，最小不能低于 12 字节，最大不能超过 16 字节。

如果是 GCM 工作模式。加密结果的后 tagSize 字节是摘要数据。

使用示例见 [SM4 使用](../crypto_samples/sample_crypto.md)。

> **注意：**
>
> - GCM 模式需要 OpenSSL 3.2 或者以上版本。
>
> - 对块密码来说 ECB 是已知不安全的模式。请谨慎使用。

父类型：

- BlockCipher

### prop aad

```cangjie
public prop aad: Array<Byte>
```

功能：附加数据。

类型：Array\<Byte>

示例：

<!-- compile -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(12) // GCM推荐12字节IV
    let aad = "additional authenticated data".toArray() // 附加认证数据

    // 创建SM4实例（仅GCM模式下aad参数生效，需要 OpenSSL 3.2 或者以上版本）
    let sm4 = SM4(OperationMode.GCM, key, iv: iv, aad: aad)

    // 获取附加数据
    let retrievedAad = sm4.aad
    println("附加数据长度: ${retrievedAad.size}")

    return 0
}
```

运行结果：

```text
附加数据长度: 29
```

### prop algorithm

```cangjie
public prop algorithm: String
```

功能：获取分组加解密算法的算法名称。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 获取算法名称
    let algorithm = sm4.algorithm
    println("SM4算法名称: ${algorithm}")

    return 0
}
```

运行结果：

```text
SM4算法名称: SM4
```

### prop blockSize

```cangjie
public prop blockSize: Int64
```

功能：分组长度，单位字节。

类型：Int64

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 获取分组长度
    let blockSize = sm4.blockSize
    println("SM4分组长度: ${blockSize}")

    return 0
}
```

运行结果：

```text
SM4分组长度: 16
```

### prop iv

```cangjie
public prop iv: Array<Byte>
```

功能：初始化向量。

类型：Array\<Byte>

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 获取初始化向量
    let ivValue = sm4.iv
    println("初始化向量长度: ${ivValue.size}")

    return 0
}
```

运行结果：

```text
初始化向量长度: 16
```

### prop ivSize

```cangjie
public prop ivSize: Int64
```

功能：初始化向量长度。

类型：Int64

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 获取初始化向量长度
    let ivSize = sm4.ivSize
    println("初始化向量长度: ${ivSize}")

    return 0
}
```

运行结果：

```text
初始化向量长度: 16
```

### prop key

```cangjie
public prop key: Array<Byte>
```

功能：密钥。

类型：Array\<Byte>

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 获取密钥
    let keyValue = sm4.key
    println("密钥长度: ${keyValue.size}")

    return 0
}
```

运行结果：

```text
密钥长度: 16
```

### prop keySize

```cangjie
public prop keySize: Int64
```

功能：密钥长度。

类型：Int64

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 获取密钥长度
    let keySize = sm4.keySize
    println("密钥长度: ${keySize}")

    return 0
}
```

运行结果：

```text
密钥长度: 16
```

### prop optMode

```cangjie
public prop optMode: OperationMode
```

功能：工作模式。

类型：[OperationMode](crypto_package_structs.md#struct-operationmode)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 获取工作模式
    let optMode = sm4.optMode
    println("工作模式: ${optMode}")

    return 0
}
```

运行结果：

```text
工作模式: CBC
```

### prop paddingMode

```cangjie
public prop paddingMode: PaddingMode
```

功能：填充模式。

类型：[PaddingMode](crypto_package_structs.md#struct-paddingmode)

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv, paddingMode: PaddingMode.PKCS7Padding)

    // 获取填充模式
    let paddingMode = sm4.paddingMode
    return 0
}
```

### prop tagSize

```cangjie
public prop tagSize: Int64
```

功能：摘要长度。

类型：Int64

示例：

<!-- compile -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例（GCM模式，需要 OpenSSL 3.2 或者以上版本）
    let sm4 = SM4(OperationMode.GCM, key, iv: iv, tagSize: 16)

    // 获取摘要长度
    let tagSize = sm4.tagSize
    println("摘要长度: ${tagSize}")

    return 0
}
```

运行结果：

```text
摘要长度: 16
```

### init(OperationMode, Array\<Byte>, Array\<Byte>, PaddingMode, Array\<Byte>, Int64)

```cangjie
public init(
    optMode: OperationMode,
    key: Array<Byte>,
    iv!: Array<Byte> = Array<Byte>(),
    paddingMode!: PaddingMode = PaddingMode.PKCS7Padding,
    aad!: Array<Byte> = Array<Byte>(),
    tagSize!: Int64 = 16
)
```

功能：创建 [SM4](crypto_package_classes.md#class-sm4) 实例，可指定在不同工作模式下参数。

参数：

- optMode: [OperationMode](crypto_package_structs.md#struct-operationmode) - 设置加解密工作模式。
- key: Array\<Byte> - 密钥，长度为 16 字节。
- iv!: Array\<Byte> - 初始化向量。
- paddingMode!: [PaddingMode](crypto_package_structs.md#struct-paddingmode) - 设置填充模式。
- aad!: Array\<Byte> - 设置附加数据。
- tagSize!: Int64 - 设置摘要长度。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 参数设置不正确，实例化失败。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 使用CBC模式创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    println("SM4算法名称: ${sm4.algorithm}")
    println("分组长度: ${sm4.blockSize}")
    println("密钥长度: ${sm4.keySize}")

    return 0
}
```

运行结果：

```text
SM4算法名称: SM4
分组长度: 16
密钥长度: 16
```

### func decrypt(Array\<Byte>)

```cangjie
public func decrypt(input: Array<Byte>): Array<Byte>
```

功能：解密一段数据数据。

参数：

- input: Array\<Byte> - 输入字节序列。

返回值：

- Array\<Byte> - 解密后的结果。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解密失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 要加密的数据
    let plainText = "Hello, Cangjie!".toArray()

    // 加密数据
    let encrypted = sm4.encrypt(plainText)
    println("加密成功，密文长度: ${encrypted.size}")

    // 解密数据
    let decrypted = sm4.decrypt(encrypted)
    let result = String.fromUtf8(decrypted)
    println("解密结果: ${result}")

    return 0
}
```

运行结果：

```text
加密成功，密文长度: 16
解密结果: Hello, Cangjie!
```

### func decrypt(Array\<Byte>, Array\<Byte>)

```cangjie
public func decrypt(input: Array<Byte>,  to!: Array<Byte>): Int64
```

功能：解密一段数据，将密文解密后的明文写入指定的输出字节数组，返回值为实际写入到输出数组的明文字节长度。数组长度不足时不会报错，仅会对解密后的明文进行截断处理。为保证能接收完整明文，建议输出数组的长度不小于密文数组的长度。

参数：

- input: Array\<Byte> - 待进行解密的数据。
- to!: Array\<Byte> - 输出数组。

返回值：

- Int64 - 输出长度。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解密失败，抛出异常。
- IllegalArgumentException - 当 to 的 size = 0 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 要加密的数据
    let plainText = "Hello, Cangjie!".toArray()

    // 加密数据
    let encrypted = sm4.encrypt(plainText)
    println("加密成功，密文长度: ${encrypted.size}")

    // 准备输出数组，长度为密文长度
    var output = Array<Byte>(encrypted.size, repeat: 0)

    // 解密数据到指定输出数组
    let outputLen = sm4.decrypt(encrypted, to: output)
    println("解密成功，输出长度: ${outputLen}")
    println("解密成功，输出: ${String.fromUtf8(output.slice(0, outputLen))}")

    // 准备输出数组，长度为3（会发生截断）
    var output01 = Array<Byte>(3, repeat: 0)

    // 解密数据到指定输出数组
    let outputLen01 = sm4.decrypt(encrypted, to: output01)
    println("解密成功，输出长度: ${outputLen01}")
    println("解密成功，输出（发生截断）: ${String.fromUtf8(output01)}")
    return 0
}
```

运行结果：

```text
加密成功，密文长度: 16
解密成功，输出长度: 15
解密成功，输出: Hello, Cangjie!
解密成功，输出长度: 3
解密成功，输出（发生截断）: Hel
```

### func decrypt(InputStream, OutputStream)

```cangjie
public func decrypt(input: InputStream, output: OutputStream): Unit
```

功能：对输入流进行解密，如果数据过大无法一次对其解密，可以通过数据流进行解密。

参数：

- input:InputStream  - 待解密的输入数据流。
- output: OutputStream - 解密后的输出数据流。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解密失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*
import std.fs.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 要加密的数据
    let plainText = "Hello, Cangjie!".toArray()

    // 创建一个测试文件里面放入加密数据
    let testEncrypt = Path("./test_encrypt.txt")
    removeIfExists(testEncrypt, recursive: true)
    let encrypted = sm4.encrypt(plainText)
    File.writeTo(testEncrypt, encrypted)

    // 从文件中读取加密数据并解密到文件中（File是文件流）
    let testDecrypt = Path("./test_decrypt.txt")
    removeIfExists(testDecrypt, recursive: true)
    sm4.decrypt(File(testEncrypt, Read), File(testDecrypt, Write))

    let decrypted = File.readFrom(testDecrypt)
    let result = String.fromUtf8(decrypted)
    println("从文件中解密结果: ${result}")

    // 清理临时文件
    removeIfExists(testEncrypt, recursive: true)
    removeIfExists(testDecrypt, recursive: true)
    return 0
}
```

运行结果：

```text
从文件中解密结果: Hello, Cangjie!
```

### func encrypt(Array\<Byte>)

```cangjie
public func encrypt(input: Array<Byte>): Array<Byte>
```

功能：加密一段数据数据。

参数：

- input: Array\<Byte> - 输入字节序列。

返回值：

- Array\<Byte> - 加密后的结果。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 加密失败，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 要加密的数据
    let plainText = "Hello, Cangjie!".toArray()

    // 加密数据
    let encrypted = sm4.encrypt(plainText)
    println("加密成功，密文字节数组（长度 ${encrypted.size}）: ${encrypted}")

    return 0
}
```

可能的运行结果：

```text
加密成功，密文字节数组（长度 16）: [130, 245, 173, 223, 95, 40, 68, 161, 234, 44, 26, 22, 39, 217, 140, 138]
```

### func encrypt(Array\<Byte>, Array\<Byte>)

```cangjie
public func encrypt(input: Array<Byte>, to!: Array<Byte>): Int64
```

功能：加密一段明文数据，将加密后的密文写入调用者预先创建的输出字节数组，返回值为实际写入到输出数组的密文字节长度。明文数组长度加上一个 blockSize（16），可适配所有填充场景。

> **注意：**
>
> - 输出数组长度仅影响加密结果，不影响后续解密流程；数组长度不足时不会报错，若无法容纳完整密文，加密会失败或仅写入部分密文（返回值为实际写入长度）。
> - 填充模式（CBC/ECB）：SM4 分组加密需填充，密文长度为 16 字节的整数倍，建议输出数组长度≥向上取整 (明文长度 / 16)×16（blockSize=16）；最简方案为输出数组长度 = 明文长度 + 16，可适配所有填充场景。
> - 无填充模式（GCM/CTR/OFB/CFB）：流加密无需填充，密文长度与明文长度一致，建议输出数组长度与明文长度一致。
> - 本接口为高性能底层实现，不做自动扩容与长度校验，需调用者自行保证输出数组长度足够。

参数：

- input: Array\<Byte> - 待进行加密的数据。
- to!: Array\<Byte> - 输出数组。

返回值：

- Int64 - 输出长度。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 加密失败，抛出异常。
- IllegalArgumentException - 当 to 的 size = 0 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 要加密的数据
    let plainText = "Hello, Cangjie!".toArray()

    // 准备输出数组，长度应足够存储加密结果
    var output = Array<Byte>(plainText.size + 16, repeat: 0)

    // 加密数据到指定输出数组
    let outputLen = sm4.encrypt(plainText, to: output)
    println("加密成功，输出长度: ${outputLen}")

    return 0
}
```

运行结果：

```text
加密成功，输出长度: 16
```

### func encrypt(InputStream, OutputStream)

```cangjie
public func encrypt(input: InputStream, output: OutputStream): Unit
```

功能：对输入流进行加密，如果数据过大无法一次对其加密，可以通过数据流进行加密。

参数：

- input:InputStream  - 待加密的输入数据流。
- output: OutputStream - 解密后的输出数据流。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 加密失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*
import std.fs.*

main() {
    let random = SecureRandom(priv: true)

    let key = random.nextBytes(16) // 16字节密钥，生产环节从KMS密钥管理系统获取
    let iv = random.nextBytes(16) // 16字节IV

    // 创建SM4实例
    let sm4 = SM4(OperationMode.CBC, key, iv: iv)

    // 要加密的数据
    let plainText = "Hello, Cangjie!"
    println("要加密的数据: ${plainText}")

    // 测试文件里面放入要加密的数据
    let testData = Path("./test_data.txt")
    removeIfExists(testData, recursive: true)
    File.writeTo(testData, plainText.toArray())

    // 加密的数据被写入到文件中
    let testEncrypt = Path("./test_encrypt.txt")
    removeIfExists(testEncrypt, recursive: true)
    sm4.encrypt(File(testData, Read), File(testEncrypt, Write))
    let encrypted = File.readFrom(testEncrypt)
    println("加密结果的大小: ${encrypted.size}")

    // 解密的数据被写入到文件中
    let testDecrypt = Path("./test_decrypt.txt")
    removeIfExists(testDecrypt, recursive: true)
    sm4.decrypt(File(testEncrypt, Read), File(testDecrypt, Write))

    let decrypted = File.readFrom(testDecrypt)
    let result = String.fromUtf8(decrypted)
    println("从文件中解密结果: ${result}")

    // 清理临时文件
    removeIfExists(testEncrypt, recursive: true)
    removeIfExists(testDecrypt, recursive: true)
    removeIfExists(testData, recursive: true)
    return 0
}
```

运行结果：

```text
要加密的数据: Hello, Cangjie!
加密结果的大小: 16
从文件中解密结果: Hello, Cangjie!
```
