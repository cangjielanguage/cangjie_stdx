# Structs

## struct CipherSuite

```cangjie
public struct CipherSuite <: ToString & Equatable<CipherSuite>
```

Function: Cipher suite in TLS.

Parent types:

- ToString
- Equatable\<[CipherSuite](#struct-ciphersuite)>

### static prop allSupported

```cangjie
public static prop allSupported: Array<CipherSuite>
```

Function: Returns all supported cipher suites.

Return value: Array containing cipher suites.

Type: Array\<[CipherSuite](tls_package_structs.md#struct-ciphersuite)>

### func toString()

```cangjie
public func toString(): String
```

Function: Returns the name of the cipher suite.

Return value:

- String - The name of the cipher suite.

### operator func !=(CipherSuite)

```cangjie
public operator func !=(that: CipherSuite): Bool
```

Function: Determines if two cipher suites are unequal.

Parameters:

- that: [CipherSuite](tls_package_structs.md#struct-ciphersuite) - The cipher suite object to compare.

Return value:

- Bool - Returns `true` if unequal; otherwise, returns `false`.

### operator func ==(CipherSuite)

```cangjie
public operator func ==(that: CipherSuite): Bool
```

Function: Determines if two cipher suites are equal.

Parameters:

- that: [CipherSuite](tls_package_structs.md#struct-ciphersuite) - The cipher suite object to compare.

Return value:

- Bool - Returns `true` if equal; otherwise, returns `false`.

## struct TlsClientConfig

```cangjie
public struct TlsClientConfig <: TlsConfig {
    public var keylogCallback: ?(TlsSocket, String) -> Unit = None
    public var verifyMode: CertificateVerifyMode = CertificateVerifyMode.Default
    public init()
}
```

Function: Client configuration.

Parent types:

- [TlsConfig](./../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig)

### var keylogCallback

```cangjie
public var keylogCallback: ?(TlsSocket, String) -> Unit = None
```

Function: Callback function during handshake that provides TLS initial key material for debugging and decryption purposes.

Type: ?([TlsSocket](tls_package_classes.md#class-tlssocket), String) -> Unit

### prop certificate

```cangjie
public mut prop certificate: ?(Array<Certificate>, PrivateKey)
```

Function: Sets or gets the client certificate and corresponding private key file. The certificate must be of type [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate).

Type: ?(Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)>, [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey))

Exceptions:

- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - Throws an exception if the set client certificate is not of type [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate).

### prop securityLevel

```cangjie
public mut prop securityLevel: Int32
```

Function: Specifies the client's security level. Default value is 2, with optional parameter values ranging from 0-5. For parameter meanings, refer to openssl's SSL_CTX_set_security_level documentation.

Type: Int32

### prop serverName

```cangjie
public mut prop serverName: ?String
```

Function: Reads/writes the server name for the TLS SNI (Server Name Indication) extension. During the TLS handshake, the client declares the host it wants to access, so the server can return the corresponding certificate, and the server certificate is verified against this name. When set to `None`, the behavior is decided by the caller: a direct `TlsSocket.client` handshake sends no SNI extension and the server responds with its default certificate for the current IP; an `stdx.net.http` client request uses the host name from the request URL as the SNI and verifies the server certificate against it (the handshake fails if the host name is empty).

Type: ?String

Exceptions:

- IllegalArgumentException - Throws an exception if the parameter contains '\0' character.

### prop signatureAlgorithms

```cangjie
public mut prop signatureAlgorithms: ?Array<SignatureAlgorithm>
```

Function: Specifies ordered signature and hash algorithms. When the value is `None` or the list is empty, the client will use the default list. After specifying the list, the client may not send inappropriate signature algorithms.
Refer to [RFC5246 7.4.1.4.1 (TLS 1.2)](https://www.rfc-editor.org/rfc/rfc5246.html#section-7.4.1.4.1) and [RFC8446 4.2.3. (TLS 1.3)](https://www.rfc-editor.org/rfc/rfc8446.html#section-4.2.3).

Type: ?Array\<[SignatureAlgorithm](tls_package_enums.md#enum-signaturealgorithm)>

### prop supportedAlpnProtocols

```cangjie
public mut prop supportedAlpnProtocols: Array<String>
```

Function: Application-Layer Protocol Negotiation. If the list is empty, the client will not negotiate application-layer protocols.

Type: Array\<String>

Exceptions:

- IllegalArgumentException - Throws an exception if list elements contain '\0' character.

### prop supportedCipherSuites

```cangjie
public mut prop supportedCipherSuites: Map<TlsVersion, Array<String>>
```

Function: Sets or gets cipher suites corresponding to each TLS version.

Type: Map\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion), Array\<String>>

Exceptions:

- IllegalArgumentException - Throws an exception when setting cipher suites via `Map` if a TLS version's corresponding cipher suite string contains null character `\0`.

### prop supportedVersions

```cangjie
public mut prop supportedVersions: Array<TlsVersion>
```

Function: Sets or gets supported TLS versions.

Type: Array\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion)>

### prop verifyMode

```cangjie
public mut prop verifyMode: CertificateVerifyMode
```

Function: Sets or gets authentication mode. Default value is [CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode).Default, meaning system certificates are authenticated.

Type: [CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode)

### init()

```cangjie
public init()
```

Function: Constructs [TlsClientConfig](tls_package_structs.md#struct-tlsclientconfig).

## struct TlsServerConfig

```cangjie
public struct TlsServerConfig <: TlsConfig {
    public var keylogCallback: ?(TlsSocket, String) -> Unit = None
    public mut prop clientIdentityRequired: TlsClientIdentificationMode
    public mut prop verifyMode: CertificateVerifyMode
    public init(certChain: Array<X509Certificate>, certKey: PrivateKey)
}
```

Parent types:

- [TlsConfig](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig)

Function: Server configuration.

### var keylogCallback

```cangjie
public var keylogCallback: ?(TlsSocket, String) -> Unit = None
```

Function: Callback function during handshake that provides TLS initial key material for debugging and decryption purposes.

Type: ?([TlsSocket](tls_package_classes.md#class-tlssocket), String) -> Unit

### prop certificate

```cangjie
public mut prop certificate: ?(Array<Certificate>, PrivateKey)
```

Function: Sets or gets the server certificate and corresponding private key file. The certificate must be of type [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate). Cannot be set to None.

Type: ?(Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)>, [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey))

Exceptions:

- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - Throws an exception if the set server certificate is not of type [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate); throws an exception if setting server certificate and corresponding private key file to None.

### prop clientIdentityRequired

```cangjie
public mut prop clientIdentityRequired: TlsClientIdentificationMode
```

Function: Sets or gets the server's required client authentication mode. Default value is [TlsClientIdentificationMode](tls_package_enums.md#enum-tlsclientidentificationmode).Disable, meaning the client is not required to authenticate server certificates nor send its own certificate.

Type: [TlsClientIdentificationMode](tls_package_enums.md#enum-tlsclientidentificationmode)

### prop dhParameters

```cangjie
public mut prop dhParameters: ?DHParameters
```

Function: Specifies the server's DH key parameters. Default is `None`, meaning openssl automatically generated parameters are used by default.

Type: ?[DHParameters](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-dhparameters)

### prop securityLevel

```cangjie
public mut prop securityLevel: Int32
```

Function: Specifies the server's security level. Default value is 2, with optional parameter values ranging from [0,5]. For parameter meanings, refer to [openssl-SSL_CTX_set_security_level](https://www.openssl.org/docs/man1.1.1/man3/SSL_CTX_set_security_level.html).
Function: Specifies the server's security level. Default value is 2, with optional parameter values ranging from 0-5. For parameter meanings, refer to openssl-SSL_CTX_set_security_level documentation.

Type: Int32

Exceptions:

- IllegalArgumentException - Throws an exception when configuration value is not within 0-5 range.

### prop supportedAlpnProtocols

```cangjie
public mut prop supportedAlpnProtocols: Array<String>
```

Function: Application-Layer Protocol Negotiation. If the client attempts to negotiate this protocol, the server will select intersecting protocol names. If the client does not attempt protocol negotiation, this configuration will be ignored.

Type: Array\<String>

Exceptions:

- IllegalArgumentException - Throws an exception if list elements contain '\0' character.

### prop supportedCipherSuites

```cangjie
public mut prop supportedCipherSuites: Map<TlsVersion, Array<String>>
```

Function: Sets or gets cipher suites corresponding to each TLS version.

Type: Map\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion), Array\<String>>

Exceptions:

- IllegalArgumentException - Throws an exception when setting cipher suites via `Map` if a TLS version's corresponding cipher suite string contains null character `\0`.

### prop supportedVersions

```cangjie
public mut prop supportedVersions: Array<TlsVersion>
```

Function: Sets or gets supported TLS versions.

Type: Array\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion)>

### prop verifyMode

```cangjie
public mut prop verifyMode: CertificateVerifyMode
```

Function: Sets or gets authentication mode. Default value is [CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode).Default, meaning system certificates are authenticated.

Type: [CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode)

### init(Array\<X509Certificate>, PrivateKey)

```cangjie
public init(certChain: Array<X509Certificate>, certKey: PrivateKey)
```

Function: Constructs [TlsServerConfig](tls_package_structs.md#struct-tlsserverconfig) object.

Parameters:

- certChain: Array\<[X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate)> - Certificate object.
- certKey: [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - Private key object.
