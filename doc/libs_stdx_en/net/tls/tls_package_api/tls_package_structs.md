# Structures

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

Return value: An array containing cipher suites.

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

Function: Determines whether two cipher suites are unequal.

Parameters:

- that: [CipherSuite](tls_package_structs.md#struct-ciphersuite) - The cipher suite object to be compared.

Return value:

- Bool - Returns `true` if unequal; otherwise, returns `false`.

### operator func ==(CipherSuite)

```cangjie
public operator func ==(that: CipherSuite): Bool
```

Function: Determines whether two cipher suites are equal.

Parameters:

- that: [CipherSuite](tls_package_structs.md#struct-ciphersuite) - The cipher suite object to be compared.

Return value:

- Bool - Returns `true` if equal; otherwise, returns `false`.

## struct TlsClientConfig

```cangjie
public struct TlsClientConfig {
    public var keylogCallback: ?(TlsSocket, String) -> Unit = None
    public var verifyMode: CertificateVerifyMode = CertificateVerifyMode.Default
    public init()
}
```

Function: Client configuration.

### var keylogCallback

```cangjie
public var keylogCallback: ?(TlsSocket, String) -> Unit = None
```

Function: Callback function during the handshake process, providing TLS initial key material for debugging and decryption purposes.

Type: ?([TlsSocket](tls_package_classes.md#class-tlssocket), String) -> Unit

### var verifyMode

```cangjie
public var verifyMode: CertificateVerifyMode = CertificateVerifyMode.Default
```

Function: Sets or gets the certificate verification mode, defaulting to `Default`.

Type: [CertificateVerifyMode](tls_package_enums.md#enum-certificateverifymode)

### prop alpnProtocolsList

```cangjie
public mut prop alpnProtocolsList: Array<String>
```

Function: Required application-layer protocol names. If the list is empty, the client will not negotiate application-layer protocols.

Type: Array\<String>

Exceptions:

- IllegalArgumentException - Throws an exception if any list element contains a '\0' character.

### prop cipherSuitesV1_2

```cangjie
public mut prop cipherSuitesV1_2: ?Array<String>
```

Function: Cipher suites based on the TLS 1.2 protocol.

Type: ?Array\<String>

Exceptions:

- IllegalArgumentException - Throws an exception if any list element contains a '\0' character.

### prop cipherSuitesV1_3

```cangjie
public mut prop cipherSuitesV1_3: ?Array<String>
```

Function: Cipher suites based on the TLS 1.3 protocol.

Type: ?Array\<String>

Exceptions:

- IllegalArgumentException - Throws an exception if any list element contains a '\0' character.

### prop clientCertificate

```cangjie
public mut prop clientCertificate: ?(Array<X509Certificate>, PrivateKey)
```

Function: Client certificate and private key.

Type: ?(Array\<[X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate)>, PrivateKey)

### prop domain

```cangjie
public mut prop domain: ?String
```

Function: Reads or writes the required server host address (SNI). `None` indicates no requirement. When sending a request via an `stdx.net.http` client with this field unset, the host name from the request URL is used as the SNI and for server certificate verification (the handshake fails if the host name is empty).

Type: ?String

Exceptions:

- IllegalArgumentException - Throws an exception if the parameter contains a '\0' character.

### prop maxVersion

```cangjie
public mut prop maxVersion: TlsVersion
```

Function: The maximum supported TLS version.

> **Note:**
>
> If only `maxVersion` is set without `minVersion`, or if the set `maxVersion` is lower than `minVersion`, a [TlsException](tls_package_exceptions.md#class-tlsexception) will be thrown during the handshake phase.

Type: [TlsVersion](tls_package_enums.md#enum-tlsversion)

### prop minVersion

```cangjie
public mut prop minVersion: TlsVersion
```

Function: The minimum supported TLS version.

> **Note:**
>
> If only `minVersion` is set without `maxVersion`, or if the set `minVersion` is higher than `maxVersion`, a [TlsException](tls_package_exceptions.md#class-tlsexception) will be thrown during the handshake phase.

Type: [TlsVersion](tls_package_enums.md#enum-tlsversion)

### prop securityLevel

```cangjie
public mut prop securityLevel: Int32
```

Function: Specifies the client's security level. The default value is 2, with optional parameter values ranging from 0 to 5. For parameter value meanings, refer to openssl-SSL_CTX_set_security_level documentation.

Type: Int32

### prop signatureAlgorithms

```cangjie
public mut prop signatureAlgorithms: ?Array<SignatureAlgorithm>
```

Function: Specifies an ordered list of signature and hash algorithms. When the value is `None` or the list is empty, the client will use the default list. After specifying the list, the client may not send inappropriate signature algorithms.
Refer to [RFC5246 7.4.1.4.1 (TLS 1.2)](https://www.rfc-editor.org/rfc/rfc5246.html#section-7.4.1.4.1) and [RFC8446 4.2.3. (TLS 1.3)](https://www.rfc-editor.org/rfc/rfc8446.html#section-4.2.3) for details.

Type: ?Array\<[SignatureAlgorithm](tls_package_enums.md#enum-signaturealgorithm)>

### init()

```cangjie
public init()
```

Function: Constructs a [TlsClientConfig](tls_package_structs.md#struct-tlsclientconfig).

## struct TlsServerConfig

```cangjie
public struct TlsServerConfig <: TlsConfig {
    public var keylogCallback: ?(TlsSocket, String) -> Unit = None
    public mut prop clientIdentityRequired: TlsClientIdentificationMode
    public mut prop verifyMode: CertificateVerifyMode
    public init(certChain: Array<X509Certificate>, certKey: PrivateKey)
}
```

Function: Server configuration.

### var clientIdentityRequired

```cangjie
public var clientIdentityRequired: TlsClientIdentificationMode = Disabled
```

Function: Sets or gets the server's client authentication mode. By default, the server neither requires client authentication of the server certificate nor requests the client to send its own certificate.

Type: [TlsClientIdentificationMode](tls_package_enums.md#enum-tlsclientidentificationmode)

### var keylogCallback

```cangjie
public var keylogCallback: ?(TlsSocket, String) -> Unit = None
```

Function: Callback function during the handshake process, providing TLS initial key material for debugging and decryption purposes.

Type: ?([TlsSocket](tls_package_classes.md#class-tlssocket), String) -> Unit

### var verifyMode

```cangjie
public var verifyMode: CertificateVerifyMode = CertificateVerifyMode.Default
```

Function: Sets or gets the verification mode, defaulting to system certificate verification.

Type: [CertificateVerifyMode](tls_package_enums.md#enum-certificateverifymode)

### prop cipherSuitesV1_2

```cangjie
public mut prop cipherSuitesV1_2: Array<String>
```

Function: Cipher suites based on the TLS 1.2 protocol.

Type: Array\<String>

Exceptions:

- IllegalArgumentException - Throws an exception if any list element contains a '\0' character.

### prop cipherSuitesV1_3

```cangjie
public mut prop cipherSuitesV1_3: Array<String>
```

Function: Cipher suites based on the TLS 1.3 protocol.

Type: Array\<String>

Exceptions:

- IllegalArgumentException - Throws an exception if any list element contains a '\0' character.

### prop dhParameters

```cangjie
public mut prop dhParameters: ?DHParameters
```

Function: Specifies the server's DH key parameters. Default is `None`, in which case OpenSSL auto-generated parameter values are used.

Type: ?[DHParameters](../../../crypto/x509/x509_package_api/x509_package_interfaces.md#interface-dhparameters)

### prop maxVersion

```cangjie
public mut prop maxVersion: TlsVersion
```

Function: The maximum supported TLS version.

> **Note:**
>
> When only `maxVersion` is set without `minVersion`, or when `maxVersion` is set lower than `minVersion`, a [TlsException](tls_package_exceptions.md#class-tlsexception) will be thrown during the handshake phase.

Type: [TlsVersion](tls_package_enums.md#enum-tlsversion)

### prop minVersion

```cangjie
public mut prop minVersion: TlsVersion
```

Function: The minimum supported TLS version.

> **Note:**
>
> When only `minVersion` is set without `maxVersion`, or when `minVersion` is set higher than `maxVersion`, a [TlsException](tls_package_exceptions.md#class-tlsexception) will be thrown during the handshake phase.

Type: [TlsVersion](tls_package_enums.md#enum-tlsversion)

### prop securityLevel

```cangjie
public mut prop securityLevel: Int32
```

Function: Specifies the server's security level. Default value is 2, with valid parameter range [0,5]. For parameter meanings, refer to [openssl-SSL_CTX_set_security_level](https://www.openssl.org/docs/man1.1.1/man3/SSL_CTX_set_security_level.html).

Type: Int32

Exceptions:

- IllegalArgumentException - Thrown when the configured value is outside the 0-5 range.

### prop serverCertificate(Array\<X509Certificate>, PrivateKey)

```cangjie
public mut prop serverCertificate: (Array<X509Certificate>, PrivateKey)
```

Function: Server certificate and corresponding private key file.

Type: (Array\<[X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate)>, PrivateKey)

### prop supportedAlpnProtocols

```cangjie
public mut prop supportedAlpnProtocols: Array<String>
```

Function: Application-Layer Protocol Negotiation (ALPN). If the client attempts to negotiate these protocols, the server will select the mutually supported protocol names. If the client doesn't attempt protocol negotiation, this configuration will be ignored.

Type: Array\<String>

Exceptions:

- IllegalArgumentException - Thrown when list elements contain '\0' characters.

### init(Array\<X509Certificate>, PrivateKey)

```cangjie
public init(certChain: Array<X509Certificate>, certKey: PrivateKey)
```

Function: Constructs a [TlsServerConfig](tls_package_structs.md#struct-tlsserverconfig) object.

Parameters:

- certChain: Array\<[X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate)> - Certificate object.
- certKey: [PrivateKey](../../../crypto/x509/x509_package_api/x509_package_interfaces.md#interface-privatekey) - Private key object.

## struct TlsSession

```cangjie
public struct TlsSession <: Equatable<TlsSession> & ToString & Hashable
```

Function: This struct represents an established client session. Users cannot create instances of this struct, and its internal structure is not visible to users.

When a client successfully completes TLS handshake, a session is generated. If the connection is lost for some reason, the client can reuse this session via the session ID, skipping the handshake process.

Parent Types:

- Equatable\<[TlsSession](#struct-tlssession)>
- ToString
- Hashable

### func hashCode()

```cangjie
public override func hashCode(): Int64
```

Function: Generates a hash value for the session ID.

Return Value:

- Int64 - Hash value of the session ID.

### func toString()

```cangjie
public override func toString(): String
```

Function: Generates a session ID string.

Return Value:

- String - [TlsSession](tls_package_structs.md#struct-tlssession)(session ID string).

### operator func !=(TlsSession)

```cangjie
public override operator func !=(other: TlsSession): Bool
```

Function: Determines whether session IDs differ.

Parameters:

- other: [TlsSession](tls_package_structs.md#struct-tlssession) - The session object to compare.

Return Value:

- Bool - Returns `true` if session objects differ; otherwise, returns `false`.

### operator func ==(TlsSession)

```cangjie
public override operator func ==(other: TlsSession): Bool
```

Function: Determines whether session IDs are identical.

Parameters:

- other: [TlsSession](tls_package_structs.md#struct-tlssession) - The session object to compare.

Return Value:

- Bool - Returns `true` if session objects are identical; otherwise, returns `false`.
```