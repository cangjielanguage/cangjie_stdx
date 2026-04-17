/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */
#include <securec.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <openssl/crypto.h>
#include <openssl/hmac.h>
#include <openssl/provider.h>
#include <openssl/rand.h>
#include <openssl/sha.h>
#include <openssl/x509v3.h>
#ifdef _WIN32
#include <windows.h>
#define OPENSSLPATH "libcrypto-3-x64.dll"
#define OPENSSLPATHSSL "libssl-3-x64.dll"
#elif defined(__APPLE__)
#include <pthread.h>
#include <dlfcn.h>
#define OPENSSLPATH "libcrypto.3.dylib"
#define OPENSSLPATHSSL "libssl.3.dylib"
#elif defined(__ohos__)
#include <pthread.h>
#include <dlfcn.h>
#define OPENSSLPATH "libcrypto_openssl.z.so"
#define OPENSSLPATHSSL "libssl_openssl.z.so"
#else
#include <pthread.h>
#include <dlfcn.h>
#define OPENSSLPATH "libcrypto.so.3"
#define OPENSSLPATHSSL "libssl.so.3"
#endif
#include "opensslSymbols.h"
void* g_singletonHandle = NULL;
void* g_singletonHandleSsl = NULL;
#ifndef CANGJIE_OPENSSL_RESOLVE_STRONG
static bool g_singletonHandleOwned = false;
static bool g_singletonHandleSslOwned = false;
#endif

#ifndef CANGJIE_OPENSSL_RESOLVE_STRONG
typedef enum OpenSslBackendMode {
    OPENSSL_BACKEND_UNINITIALIZED = 0,
    OPENSSL_BACKEND_MAIN_IMAGE,
    OPENSSL_BACKEND_DLOPEN,
    OPENSSL_BACKEND_UNAVAILABLE,
} OpenSslBackendMode;

#ifndef _WIN32
static OpenSslBackendMode g_backendMode = OPENSSL_BACKEND_UNINITIALIZED;
#endif
#endif

typedef struct OpenSslBackendCandidate {
    const char* cryptoPath;
    const char* sslPath;
} OpenSslBackendCandidate;

#define STDX_OPENSSL_CRYPTO_FILE_ENV "STDX_OPENSSL_CRYPTO_FILE"
#define STDX_OPENSSL_SSL_FILE_ENV "STDX_OPENSSL_SSL_FILE"

#ifndef CANGJIE_OPENSSL_RESOLVE_STRONG
static char* g_configuredCryptoPath = NULL;
static char* g_configuredSslPath = NULL;
static bool g_hasConfiguredOpenSslPath = false;
static bool g_hasStartedOpenSslLoad = false;
#ifdef _WIN32
static SRWLOCK g_openSslConfigLock = SRWLOCK_INIT;
#else
static pthread_mutex_t g_openSslConfigLock = PTHREAD_MUTEX_INITIALIZER;
#endif
#endif

#ifdef _WIN32
static INIT_ONCE g_opensslLoadOnce = INIT_ONCE_STATIC_INIT;
#elif !defined(CANGJIE_OPENSSL_RESOLVE_STRONG)
static pthread_once_t g_backendSelectOnce = PTHREAD_ONCE_INIT;
#endif

#ifndef CANGJIE_OPENSSL_RESOLVE_STRONG
static void LockOpenSslConfig(void)
{
#ifdef _WIN32
    AcquireSRWLockExclusive(&g_openSslConfigLock);
#else
    (void)pthread_mutex_lock(&g_openSslConfigLock);
#endif
}

static void UnlockOpenSslConfig(void)
{
#ifdef _WIN32
    ReleaseSRWLockExclusive(&g_openSslConfigLock);
#else
    (void)pthread_mutex_unlock(&g_openSslConfigLock);
#endif
}

static char* DupCString(const char* src)
{
    if (src == NULL) {
        return NULL;
    }
    size_t len = strlen(src) + 1;
    char* copy = (char*)malloc(len);
    if (copy == NULL) {
        return NULL;
    }
    if (memcpy_s(copy, len, src, len) != EOK) {
        free(copy);
        return NULL;
    }
    return copy;
}

static bool GetConfiguredOpenSslPaths(char** cryptoPath, char** sslPath)
{
    const char* selectedCryptoPath = NULL;
    const char* selectedSslPath = NULL;
    char* cryptoCopy = NULL;
    char* sslCopy = NULL;
    const char* envCryptoPath = NULL;
    const char* envSslPath = NULL;

    *cryptoPath = NULL;
    *sslPath = NULL;

    LockOpenSslConfig();
    envCryptoPath = getenv(STDX_OPENSSL_CRYPTO_FILE_ENV);
    envSslPath = getenv(STDX_OPENSSL_SSL_FILE_ENV);
    if (envCryptoPath != NULL && envSslPath != NULL && envCryptoPath[0] != '\0' && envSslPath[0] != '\0') {
        selectedCryptoPath = envCryptoPath;
        selectedSslPath = envSslPath;
    } else if (g_configuredCryptoPath != NULL && g_configuredSslPath != NULL) {
        selectedCryptoPath = g_configuredCryptoPath;
        selectedSslPath = g_configuredSslPath;
    }
    if (selectedCryptoPath != NULL && selectedSslPath != NULL) {
        cryptoCopy = DupCString(selectedCryptoPath);
        sslCopy = DupCString(selectedSslPath);
    }
    UnlockOpenSslConfig();

    if (cryptoCopy == NULL || sslCopy == NULL) {
        free(cryptoCopy);
        free(sslCopy);
        return false;
    }

    *cryptoPath = cryptoCopy;
    *sslPath = sslCopy;
    return true;
}
#endif

DynMsg* MallocDynMsg(void)
{
    DynMsg* dynMsg = (DynMsg*)malloc(sizeof(DynMsg));
    if (dynMsg == NULL) {
        return NULL;
    }
    dynMsg->found = true;
    dynMsg->funcName = NULL;
    return dynMsg;
}

void FreeDynMsg(DynMsg* dynMsgPtr)
{
    if (dynMsgPtr == NULL) {
        return;
    }
    free((void*)dynMsgPtr);
}

#ifndef CANGJIE_OPENSSL_RESOLVE_STRONG
int CJ_OpenSSL_SetPath(const char* cryptoPath, const char* sslPath)
{
    char* cryptoCopy = NULL;
    char* sslCopy = NULL;
    const char* envCryptoPath = NULL;
    const char* envSslPath = NULL;
    int ret = 0;

    if (cryptoPath == NULL || sslPath == NULL || cryptoPath[0] == '\0' || sslPath[0] == '\0') {
        return 0;
    }

    cryptoCopy = DupCString(cryptoPath);
    sslCopy = DupCString(sslPath);
    if (cryptoCopy == NULL || sslCopy == NULL) {
        free(cryptoCopy);
        free(sslCopy);
        return 0;
    }

    LockOpenSslConfig();
    envCryptoPath = getenv(STDX_OPENSSL_CRYPTO_FILE_ENV);
    envSslPath = getenv(STDX_OPENSSL_SSL_FILE_ENV);
    if (envCryptoPath != NULL && envSslPath != NULL && envCryptoPath[0] != '\0' && envSslPath[0] != '\0') {
        goto EXIT;
    }
    if (g_hasConfiguredOpenSslPath || g_hasStartedOpenSslLoad || g_singletonHandle != NULL || g_singletonHandleSsl != NULL) {
        goto EXIT;
    }
#ifndef _WIN32
    if (g_backendMode != OPENSSL_BACKEND_UNINITIALIZED) {
        goto EXIT;
    }
#endif

    g_configuredCryptoPath = cryptoCopy;
    g_configuredSslPath = sslCopy;
    g_hasConfiguredOpenSslPath = true;
    cryptoCopy = NULL;
    sslCopy = NULL;
    ret = 1;

EXIT:
    UnlockOpenSslConfig();
    free(cryptoCopy);
    free(sslCopy);
    return ret;
}
#else
int CJ_OpenSSL_SetPath(const char* cryptoPath, const char* sslPath)
{
    (void)cryptoPath;
    (void)sslPath;
    return 0;
}
#endif

/*
 * "auto" resolver supports two discovery modes:
 *   - On ELF toolchains that support pragma-weak, prefer already linked symbols and fall back to
 *     dlopen/dlsym when they are absent.
 *   - On Apple, probe the main executable image with dlsym(RTLD_MAIN_ONLY, ...) and otherwise
 *     fall back to dlopen/dlsym.
 */
#if defined(CANGJIE_OPENSSL_RESOLVE_AUTO) && (defined(__GNUC__) || defined(__clang__)) && !defined(__APPLE__)
#define CANGJIE_OPENSSL_AUTO_WEAK_AVAILABLE 1
#define CANGJIE_DO_PRAGMA(x) _Pragma(#x)
#define CANGJIE_PRAGMA_WEAK(sym) CANGJIE_DO_PRAGMA(weak sym)
#else
/* On Apple + lld, direct weak-import of OpenSSL symbols is not reliable; use dlsym instead. */
#define CANGJIE_OPENSSL_AUTO_WEAK_AVAILABLE 0
#define CANGJIE_PRAGMA_WEAK(sym)
#endif

#ifdef CANGJIE_OPENSSL_RESOLVE_AUTO

/*
 * Allow building without explicitly linking libdl: auto mode only uses dlopen/dlsym as a fallback. 
 * Windows use LoadLibrary/GetProcAddress which are always available. 
 * 
 * Mark dlopen/dlsym/dlclose as weak references so builds that don't link libdl still succeed.
 */
#ifndef _WIN32
CANGJIE_PRAGMA_WEAK(dlopen)
CANGJIE_PRAGMA_WEAK(dlsym)
CANGJIE_PRAGMA_WEAK(dlclose)
#endif

/*
 * Mark selected OpenSSL symbols as weak references so "auto" mode can prefer direct linking
 * when users link OpenSSL, while still allowing builds that don't link OpenSSL. 
 */
CANGJIE_PRAGMA_WEAK(CRYPTO_strdup)
CANGJIE_PRAGMA_WEAK(CRYPTO_strndup)
CANGJIE_PRAGMA_WEAK(CRYPTO_memdup)
CANGJIE_PRAGMA_WEAK(CRYPTO_free)
CANGJIE_PRAGMA_WEAK(CRYPTO_secure_malloc)
CANGJIE_PRAGMA_WEAK(CRYPTO_secure_zalloc)
CANGJIE_PRAGMA_WEAK(CRYPTO_secure_free)
CANGJIE_PRAGMA_WEAK(BN_num_bits)
CANGJIE_PRAGMA_WEAK(SSL_CTX_ctrl)
CANGJIE_PRAGMA_WEAK(SSL_ctrl)
CANGJIE_PRAGMA_WEAK(SSL_CTX_callback_ctrl)
CANGJIE_PRAGMA_WEAK(BIO_ctrl)
CANGJIE_PRAGMA_WEAK(BIO_clear_flags)
CANGJIE_PRAGMA_WEAK(BIO_new)
CANGJIE_PRAGMA_WEAK(BIO_s_mem)

/* Used by DynPopFree() call sites. */
CANGJIE_PRAGMA_WEAK(GENERAL_NAME_free)
CANGJIE_PRAGMA_WEAK(X509_EXTENSION_free)
CANGJIE_PRAGMA_WEAK(X509_free)

/* Weak-mark all OpenSSL APIs referenced through defineFunction.inc. */
#undef DEFINEFUNCTION
#define DEFINEFUNCTION0(name, errCode, type0) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTION1(name, errCode, type0, type1) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTION2(name, errCode, type0, type1, type2) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTION3(name, errCode, type0, type1, type2, type3) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTION4(name, errCode, type0, type1, type2, type3, type4) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTION5(name, errCode, type0, type1, type2, type3, type4, type5) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTION6(name, errCode, type0, type1, type2, type3, type4, type5, type6) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTION7(name, errCode, type0, type1, type2, type3, type4, type5, type6, type7) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTION8(name, errCode, type0, type1, type2, type3, type4, type5, type6, type7, type8) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTIONCB2(name, errCode, type0, type1, type2) CANGJIE_PRAGMA_WEAK(name)
#define DEFINEFUNCTIONCB3(name, errCode, type0, type1, type2, type3) CANGJIE_PRAGMA_WEAK(name)
#include "defineFunction.inc"
#undef DEFINEFUNCTION0
#undef DEFINEFUNCTION1
#undef DEFINEFUNCTION2
#undef DEFINEFUNCTION3
#undef DEFINEFUNCTION4
#undef DEFINEFUNCTION5
#undef DEFINEFUNCTION6
#undef DEFINEFUNCTION7
#undef DEFINEFUNCTION8
#undef DEFINEFUNCTIONCB2
#undef DEFINEFUNCTIONCB3
#undef DEFINEFUNCTION

#endif

#ifndef CANGJIE_OPENSSL_RESOLVE_STRONG
#ifndef _WIN32
static void EnsureLoadedImpl(void);

static void* TryDlopenOne(const char* path)
{
    if (&dlopen == NULL) {
        return NULL;
    }
    return dlopen(path, RTLD_LAZY | RTLD_LOCAL);
}

static void* TryDlopen(const char* const* candidates, size_t count)
{
    for (size_t i = 0; i < count; i++) {
        void* handle = TryDlopenOne(candidates[i]);
        if (handle != NULL) {
            return handle;
        }
    }
    return NULL;
}

static void CloseHandle(void* handle)
{
    if (&dlclose != NULL && handle != NULL) {
        (void)dlclose(handle);
    }
}

static bool TryLoadBackendPair(const OpenSslBackendCandidate* candidates, size_t count)
{
    for (size_t i = 0; i < count; i++) {
        void* cryptoHandle = TryDlopenOne(candidates[i].cryptoPath);
        void* sslHandle = TryDlopenOne(candidates[i].sslPath);
        if (cryptoHandle != NULL && sslHandle != NULL) {
            g_singletonHandle = cryptoHandle;
            g_singletonHandleSsl = sslHandle;
            g_singletonHandleOwned = true;
            g_singletonHandleSslOwned = true;
            return true;
        }
        CloseHandle(cryptoHandle);
        CloseHandle(sslHandle);
    }
    return false;
}

/*
 * Classify whether a symbol belongs to libssl or libcrypto.
 *
 * This classification is used to optimize symbol lookup by choosing the most likely handle first.
 * The classification may not be exhaustive (e.g., PEM_read_bio_SSL_SESSION or future OpenSSL
 * SSL-only symbols may be missed), but this is safe because:
 *
 * 1. Fallback mechanism: When a symbol is not found in the preferred handle, the lookup logic
 *    (see GetSymbolAddressImpl) will try the other handle, provided the two handles are different.
 * 2. Single-handle case: When g_singletonHandle == g_singletonHandleSsl (e.g., in fallback mode
 *    where both point to the same library), the classification has no effect at all.
 *
 * Worst case: An extra dlsym call is made, which has negligible performance impact.
 * The fallback ensures correctness even with incomplete classification.
 */
static bool IsSslSymbol(const char* name)
{
    return strncmp(name, "SSL_", strlen("SSL_")) == 0 ||
           strncmp(name, "TLS_", strlen("TLS_")) == 0 ||
           strncmp(name, "DTLS_", strlen("DTLS_")) == 0 ||
           strncmp(name, "i2d_SSL_", strlen("i2d_SSL_")) == 0 ||
           strncmp(name, "d2i_SSL_", strlen("d2i_SSL_")) == 0 ||
           strcmp(name, "OPENSSL_cipher_name") == 0 ||
           strncmp(name, "OPENSSL_init_ssl", strlen("OPENSSL_init_ssl")) == 0;
}

#if defined(__APPLE__) && defined(CANGJIE_OPENSSL_RESOLVE_AUTO)
static const char * const g_mainImageAnchorSymbols[] = {
        "TLS_client_method",
        "SSL_CTX_new",
        "SSL_CTX_free",
        "SSL_new",
        "SSL_free",
        "CRYPTO_free",
        "BIO_new",
        "BIO_s_mem",
        "OPENSSL_init",
};

/*
 * Apple main-image mode is intentionally conservative: only select it when the main executable
 * already exports a coherent set of core TLS/OpenSSL entry points. Once selected, symbol lookups
 * stay in RTLD_MAIN_ONLY and never fall back to dlopen, so we do not mix host-provided OpenSSL
 * with a separately loaded backend.
 */
static bool MainImageBackendAvailable(void)
{
    if (&dlsym == NULL) {
        return false;
    }

    for (size_t i = 0; i < sizeof(g_mainImageAnchorSymbols) / sizeof(g_mainImageAnchorSymbols[0]); i++) {
        if (dlsym(RTLD_MAIN_ONLY, g_mainImageAnchorSymbols[i]) == NULL) {
            return false;
        }
    }
    return true;
}
#endif

static void SelectBackendOnce(void)
{
#if defined(__APPLE__) && defined(CANGJIE_OPENSSL_RESOLVE_AUTO)
    if (MainImageBackendAvailable()) {
        g_backendMode = OPENSSL_BACKEND_MAIN_IMAGE;
        return;
    }
#endif

    EnsureLoadedImpl();
    if (g_singletonHandle != NULL || g_singletonHandleSsl != NULL) {
        g_backendMode = OPENSSL_BACKEND_DLOPEN;
    } else {
        g_backendMode = OPENSSL_BACKEND_UNAVAILABLE;
    }
}

static void EnsureBackendSelected(void)
{
    (void)pthread_once(&g_backendSelectOnce, SelectBackendOnce);
}

static void* FindDlopenedFunction(const char* name)
{
    void* func = NULL;
    if (&dlsym == NULL) {
        return NULL;
    }
#if defined(CANGJIE_OPENSSL_RESOLVE_AUTO) && defined(RTLD_DEFAULT) && !defined(__APPLE__)
    /*
     * On ELF platforms, static OpenSSL can be linked into the main binary.
     * Try the default symbol scope first so static links resolve without dlopen.
     */
    func = dlsym(RTLD_DEFAULT, name);
    if (func != NULL) {
        return func;
    }
#endif
    if (g_singletonHandle == NULL && g_singletonHandleSsl == NULL) {
        return NULL;
    }
    if (IsSslSymbol(name)) {
        if (g_singletonHandleSsl != NULL) {
            func = dlsym(g_singletonHandleSsl, name);
        }
        if (func == NULL && g_singletonHandleSsl == g_singletonHandle && g_singletonHandle != NULL) {
            func = dlsym(g_singletonHandle, name);
        }
    } else {
        if (g_singletonHandle != NULL) {
            func = dlsym(g_singletonHandle, name);
        }
        if (func == NULL && g_singletonHandle == g_singletonHandleSsl && g_singletonHandleSsl != NULL) {
            func = dlsym(g_singletonHandleSsl, name);
        }
    }
    return func;
}

#endif

#ifndef _WIN32
static void EnsureLoadedImpl(void)
{
    char* configuredCryptoPath = NULL;
    char* configuredSslPath = NULL;

    if (g_singletonHandle != NULL || g_singletonHandleSsl != NULL) {
        return;
    }

    LockOpenSslConfig();
    g_hasStartedOpenSslLoad = true;
    UnlockOpenSslConfig();

    if (GetConfiguredOpenSslPaths(&configuredCryptoPath, &configuredSslPath)) {
        const OpenSslBackendCandidate configuredCandidate[] = {
                { configuredCryptoPath, configuredSslPath },
        };
        (void)TryLoadBackendPair(configuredCandidate, sizeof(configuredCandidate) / sizeof(configuredCandidate[0]));
        free(configuredCryptoPath);
        free(configuredSslPath);
        return;
    }
#if defined(__APPLE__)
    const OpenSslBackendCandidate backendCandidates[] = {
            { "libcrypto.3.dylib", "libssl.3.dylib" },
            { "libcrypto.dylib", "libssl.dylib" },
    };
#else
    const OpenSslBackendCandidate backendCandidates[] = {
            { OPENSSLPATH, OPENSSLPATHSSL },
    };
#endif
    const char* const cryptoCandidates[] = {
            OPENSSLPATH,
#if defined(__APPLE__)
            "libcrypto.dylib",
#elif defined(__ohos__)
    /* no fallback */
#else
            "libcrypto.so",
#endif
    };
    const char* const sslCandidates[] = {
            OPENSSLPATHSSL,
#if defined(__APPLE__)
            "libssl.dylib",
#elif defined(__ohos__)
    /* no fallback */
#else
            "libssl.so",
#endif
    };

    if (TryLoadBackendPair(backendCandidates, sizeof(backendCandidates) / sizeof(backendCandidates[0]))) {
        return;
    }

    /*
     * If the preferred pair cannot be opened together, still probe the standalone fallback names
     * for both libcrypto and libssl. This preserves Android compatibility when only unversioned
     * names such as libcrypto.so/libssl.so are packaged.
     */
    g_singletonHandle = TryDlopen(cryptoCandidates, sizeof(cryptoCandidates) / sizeof(cryptoCandidates[0]));
    g_singletonHandleSsl = TryDlopen(sslCandidates, sizeof(sslCandidates) / sizeof(sslCandidates[0]));
    if (g_singletonHandle != NULL && g_singletonHandleSsl != NULL) {
        g_singletonHandleOwned = true;
        g_singletonHandleSslOwned = true;
        return;
    }

    /*
     * Keep the single-handle fallback for crypto-only consumers or ssl-only deployments.
     * When only one backend is available, route both lookup paths through that handle.
     */
    if (g_singletonHandle != NULL) {
        g_singletonHandleSsl = g_singletonHandle;
        g_singletonHandleOwned = true;
        g_singletonHandleSslOwned = false;
        return;
    }

    if (g_singletonHandleSsl != NULL) {
        g_singletonHandle = g_singletonHandleSsl;
        g_singletonHandleOwned = false;
        g_singletonHandleSslOwned = true;
    }
}

#else
static BOOL CALLBACK EnsureLoadedOnceCallback(PINIT_ONCE initOnce, PVOID parameter, PVOID* context)
{
    char* configuredCryptoPath = NULL;
    char* configuredSslPath = NULL;

    (void)initOnce;
    (void)parameter;
    (void)context;

    LockOpenSslConfig();
    g_hasStartedOpenSslLoad = true;
    UnlockOpenSslConfig();

    if (GetConfiguredOpenSslPaths(&configuredCryptoPath, &configuredSslPath)) {
        g_singletonHandle = LoadLibraryA(configuredCryptoPath);
        g_singletonHandleSsl = LoadLibraryA(configuredSslPath);
        g_singletonHandleOwned = (g_singletonHandle != NULL);
        g_singletonHandleSslOwned = (g_singletonHandleSsl != NULL);
        free(configuredCryptoPath);
        free(configuredSslPath);
        return TRUE;
    }
    g_singletonHandle = LoadLibraryA(OPENSSLPATH);
    g_singletonHandleSsl = LoadLibraryA(OPENSSLPATHSSL);
    g_singletonHandleOwned = (g_singletonHandle != NULL);
    g_singletonHandleSslOwned = (g_singletonHandleSsl != NULL);
    return TRUE;
}

static void EnsureLoaded(void)
{
    (void)InitOnceExecuteOnce(&g_opensslLoadOnce, EnsureLoadedOnceCallback, NULL, NULL);
}
#endif

static void* FindFunction(const char* name)
{
    void* func = NULL;
#ifdef _WIN32
    if (g_singletonHandle == NULL && g_singletonHandleSsl == NULL) {
        EnsureLoaded();
    }
    if (g_singletonHandle != NULL) {
        func = GetProcAddress(g_singletonHandle, name);
    }
    if (func == NULL && g_singletonHandleSsl != NULL) {
        func = GetProcAddress(g_singletonHandleSsl, name);
    }
    if (func == NULL) {
        return NULL;
    }
#else
    EnsureBackendSelected();
    if (g_backendMode == OPENSSL_BACKEND_UNAVAILABLE) {
        return NULL;
    }
#if defined(__APPLE__) && defined(CANGJIE_OPENSSL_RESOLVE_AUTO)
    if (g_backendMode == OPENSSL_BACKEND_MAIN_IMAGE) {
        if (&dlsym == NULL) {
            return NULL;
        }
        /* Keep all lookups inside the main executable once that backend has been selected. */
        return dlsym(RTLD_MAIN_ONLY, name);
    }
#endif
    func = FindDlopenedFunction(name);
    if (func == NULL) {
        return NULL;
    }
#endif
    return func;
}
#endif

/* Resolve/load OpenSSL lazily on first symbol use. */
#ifndef CANGJIE_OPENSSL_RESOLVE_STRONG
__attribute__((constructor)) void Singleton(void)
{
    (void)0;
}

/* Close runtime-loaded OpenSSL libraries when the library is unloaded. */
__attribute__((destructor)) void CloseSymbolTable(void)
{
#ifdef _WIN32
    if (g_singletonHandleOwned && g_singletonHandle != NULL) {
        (void)FreeLibrary(g_singletonHandle);
    }
    if (g_singletonHandleSslOwned && g_singletonHandleSsl != NULL) {
        (void)FreeLibrary(g_singletonHandleSsl);
    }
#else
    if (g_singletonHandleOwned && &dlclose != NULL && g_singletonHandle != NULL) {
        (void)dlclose(g_singletonHandle);
    }
    if (g_singletonHandleSslOwned && &dlclose != NULL && g_singletonHandleSsl != NULL) {
        (void)dlclose(g_singletonHandleSsl);
    }
#endif
    g_singletonHandle = NULL;
    g_singletonHandleSsl = NULL;
    g_singletonHandleOwned = false;
    g_singletonHandleSslOwned = false;
    free(g_configuredCryptoPath);
    free(g_configuredSslPath);
    g_configuredCryptoPath = NULL;
    g_configuredSslPath = NULL;
}
#endif

/**============= Api =============*/

#define CHECKFUNCTION(dynMsg, index, name, errCode)                                                                                                                                \
    if (func##index == NULL) {                                                                                                                                                     \
        if ((dynMsg) != NULL) {                                                                                                                                                    \
            (dynMsg)->found = false;                                                                                                                                               \
            (dynMsg)->funcName = (char*)(name);                                                                                                                                    \
        }                                                                                                                                                                          \
        return errCode;                                                                                                                                                            \
    }

static inline uintptr_t LoadCachedFunctionBits(_Atomic(uintptr_t)* cache)
{
    return atomic_load_explicit(cache, memory_order_acquire);
}

static inline void PublishCachedFunctionBits(_Atomic(uintptr_t)* cache, uintptr_t desired)
{
    uintptr_t expected = 0;
    if (desired == 0) {
        return;
    }
    (void)atomic_compare_exchange_strong_explicit(
        cache, &expected, desired, memory_order_release, memory_order_acquire);
}

#if defined(CANGJIE_OPENSSL_RESOLVE_STRONG) || defined(CANGJIE_OPENSSL_RESOLVE_AUTO)
static void* ResolveDynPopFreeFunction(const char* funcName)
{
    /*
     * DynPopFree() is only used for X509-owned stack element destructors. Keep the allowlist
     * explicit so strong mode does not silently reintroduce runtime symbol lookup fallback.
     */
    if (strcmp(funcName, "GENERAL_NAME_free") == 0) {
        return (void*)GENERAL_NAME_free;
    }
    if (strcmp(funcName, "X509_EXTENSION_free") == 0) {
        return (void*)X509_EXTENSION_free;
    }
    if (strcmp(funcName, "X509_free") == 0) {
        return (void*)X509_free;
    }
    return NULL;
}
#endif

#if defined(CANGJIE_OPENSSL_RESOLVE_STRONG)
#define FINDFUNCTIONI(dynMsg, index, name, errCode)                                                                                                                                \
    static _Atomic(uintptr_t) funcBits##index = 0;                                                                                                                                 \
    SSLFunc##index func##index = (SSLFunc##index)LoadCachedFunctionBits(&funcBits##index);                                                                                       \
    if (func##index == NULL) {                                                                                                                                                     \
        func##index = (SSLFunc##index)(name);                                                                                                                                      \
        PublishCachedFunctionBits(&funcBits##index, (uintptr_t)func##index);                                                                                                      \
        func##index = (SSLFunc##index)LoadCachedFunctionBits(&funcBits##index);                                                                                                   \
    }                                                                                                                                                                              \
    CHECKFUNCTION(dynMsg, index, #name, errCode)
#elif defined(CANGJIE_OPENSSL_RESOLVE_AUTO)
#if CANGJIE_OPENSSL_AUTO_WEAK_AVAILABLE
#define FINDFUNCTIONI(dynMsg, index, name, errCode)                                                                                                                                \
    static _Atomic(uintptr_t) funcBits##index = 0;                                                                                                                                 \
    SSLFunc##index func##index = (SSLFunc##index)LoadCachedFunctionBits(&funcBits##index);                                                                                       \
    if (func##index == NULL) {                                                                                                                                                     \
        func##index = (SSLFunc##index)(name);                                                                                                                                      \
        if (func##index == NULL) {                                                                                                                                                 \
            func##index = (SSLFunc##index)(FindFunction(#name));                                                                                                                   \
        }                                                                                                                                                                          \
        PublishCachedFunctionBits(&funcBits##index, (uintptr_t)func##index);                                                                                                      \
        func##index = (SSLFunc##index)LoadCachedFunctionBits(&funcBits##index);                                                                                                   \
    }                                                                                                                                                                              \
    CHECKFUNCTION(dynMsg, index, #name, errCode)
#else
#define FINDFUNCTIONI(dynMsg, index, name, errCode)                                                                                                                                \
    static _Atomic(uintptr_t) funcBits##index = 0;                                                                                                                                 \
    SSLFunc##index func##index = (SSLFunc##index)LoadCachedFunctionBits(&funcBits##index);                                                                                       \
    if (func##index == NULL) {                                                                                                                                                     \
        func##index = (SSLFunc##index)(FindFunction(#name));                                                                                                                       \
        PublishCachedFunctionBits(&funcBits##index, (uintptr_t)func##index);                                                                                                      \
        func##index = (SSLFunc##index)LoadCachedFunctionBits(&funcBits##index);                                                                                                   \
    }                                                                                                                                                                              \
    CHECKFUNCTION(dynMsg, index, #name, errCode)
#endif
#else
#define FINDFUNCTIONI(dynMsg, index, name, errCode)                                                                                                                                \
    static _Atomic(uintptr_t) funcBits##index = 0;                                                                                                                                 \
    SSLFunc##index func##index = (SSLFunc##index)LoadCachedFunctionBits(&funcBits##index);                                                                                       \
    if (func##index == NULL) {                                                                                                                                                     \
        func##index = (SSLFunc##index)(FindFunction(#name));                                                                                                                       \
        PublishCachedFunctionBits(&funcBits##index, (uintptr_t)func##index);                                                                                                      \
        func##index = (SSLFunc##index)LoadCachedFunctionBits(&funcBits##index);                                                                                                   \
    }                                                                                                                                                                              \
    CHECKFUNCTION(dynMsg, index, #name, errCode)
#endif

#define FINDFUNCTION(dynMsg, name, errCode) FINDFUNCTIONI(dynMsg, , name, errCode)

char* DYN_OPENSSL_strdup(const char* str, DynMsg* dynMsg)
{
    typedef char* (*SSLFunc)(const char* str, const char* file, int line);
    FINDFUNCTION(dynMsg, CRYPTO_strdup, NULL)
    return func(str, OPENSSL_FILE, OPENSSL_LINE);
}
char* DYN_OPENSSL_strndup(const char* str, size_t s, DynMsg* dynMsg)
{
    typedef char* (*SSLFunc)(const char* str, size_t s, const char* file, int line);
    FINDFUNCTION(dynMsg, CRYPTO_strndup, NULL)
    return func(str, s, OPENSSL_FILE, OPENSSL_LINE);
}

void* DYN_OPENSSL_memdup(void* str, size_t s, DynMsg* dynMsg)
{
    typedef void* (*SSLFunc)(const void* str, size_t s, const char* file, int line);
    FINDFUNCTION(dynMsg, CRYPTO_memdup, NULL)
    return func(str, s, OPENSSL_FILE, OPENSSL_LINE);
}
void DYN_CRYPTO_free(void* str, DynMsg* dynMsg)
{
    typedef void (*SSLFunc)(void*, const char*, int);
    FINDFUNCTION(dynMsg, CRYPTO_free, )
    return func(str, OPENSSL_FILE, OPENSSL_LINE);
}

void CJ_TLS_DYN_CRYPTO_free(void* str, DynMsg* dynMsg)
{
    typedef void (*SSLFunc)(void*, const char*, int);
    FINDFUNCTION(dynMsg, CRYPTO_free, )
    return func(str, "", 0);
}

void* DYN_OPENSSL_secure_malloc(size_t num, DynMsg* dynMsg)
{
    typedef void* (*SSLFunc)(size_t, const char*, int);
    FINDFUNCTION(dynMsg, CRYPTO_secure_malloc, NULL)
    return func(num, OPENSSL_FILE, OPENSSL_LINE);
}

void* DYN_OPENSSL_zalloc(size_t num, DynMsg* dynMsg)
{
    typedef void* (*SSLFunc)(size_t, const char*, int);
    FINDFUNCTION(dynMsg, CRYPTO_secure_zalloc, NULL)
    return func(num, OPENSSL_FILE, OPENSSL_LINE);
}

int DYN_BN_num_bytes(const BIGNUM* bn, DynMsg* dynMsg)
{
    typedef int (*SSLFunc)(const BIGNUM*);
    FINDFUNCTION(dynMsg, BN_num_bits, 0)
    return (func(bn) + 7) / 8; // Convert bits to bytes, rounding up
}

void DYN_OPENSSL_secure_free(void* ptr, DynMsg* dynMsg)
{
    typedef void (*SSLFunc)(void*, const char*, int);
    FINDFUNCTION(dynMsg, CRYPTO_secure_free, )
    return func(ptr, OPENSSL_FILE, OPENSSL_LINE);
}

long DYN_SSL_CTX_set_min_proto_version(SSL_CTX* ctx, int version, DynMsg* dynMsg)
{
    typedef long (*SSLFunc)(SSL_CTX*, int, long, void*);
    FINDFUNCTION(dynMsg, SSL_CTX_ctrl, -1)
    return func(ctx, SSL_CTRL_SET_MIN_PROTO_VERSION, (long)version, NULL);
}

long DYN_SSL_CTX_set_max_proto_version(SSL_CTX* ctx, int version, DynMsg* dynMsg)
{
    typedef long (*SSLFunc)(SSL_CTX*, int, long, void*);
    FINDFUNCTION(dynMsg, SSL_CTX_ctrl, -1)
    return func(ctx, SSL_CTRL_SET_MAX_PROTO_VERSION, (long)version, NULL);
}

long DYN_SSL_CTX_set_dh_auto(SSL_CTX* ctx, int onoff, DynMsg* dynMsg)
{
    typedef long (*SSLFunc)(SSL_CTX*, int, long, void*);
    FINDFUNCTION(dynMsg, SSL_CTX_ctrl, 0)
    return func(ctx, SSL_CTRL_SET_DH_AUTO, (long)onoff, NULL);
}

long DYN_SSL_CTX_add0_chain_cert(SSL_CTX* ctx, X509* x509, DynMsg* dynMsg)
{
    typedef long (*SSLFunc)(SSL_CTX*, int, long, void*);
    FINDFUNCTION(dynMsg, SSL_CTX_ctrl, 0)
    return func(ctx, SSL_CTRL_CHAIN_CERT, 0, (void*)(x509));
}

long DYN_SSL_CTX_set_mode(SSL_CTX* ctx, long mode, DynMsg* dynMsg)
{
    typedef long (*SSLFunc)(SSL_CTX*, int, long, void*);
    FINDFUNCTION(dynMsg, SSL_CTX_ctrl, 0)
    return func((ctx), SSL_CTRL_MODE, (mode), NULL);
}

long DYN_SSL_CTX_set1_sigalgs_list(SSL_CTX* ctx, const char* str, DynMsg* dynMsg)
{
    typedef long (*SSLFunc)(SSL_CTX*, int, long, void*);
    FINDFUNCTION(dynMsg, SSL_CTX_ctrl, 0)
    return func(ctx, SSL_CTRL_SET_SIGALGS_LIST, 0, (void*)(str));
}

long DYN_SSL_CTX_set_session_cache_mode(SSL_CTX* ctx, long mode, DynMsg* dynMsg)
{
    typedef long (*SSLFunc)(SSL_CTX*, int, long, void*);
    FINDFUNCTION(dynMsg, SSL_CTX_ctrl, -1)
    return func(ctx, SSL_CTRL_SET_SESS_CACHE_MODE, mode, NULL);
}

long DYN_BIO_pending(BIO* b, DynMsg* dynMsg)
{
    typedef long (*SSLFunc)(BIO*, int, long, void*);
    FINDFUNCTION(dynMsg, BIO_ctrl, 0)
    return func(b, BIO_CTRL_PENDING, 0, NULL);
}

int DYN_BIO_eof(BIO* b, DynMsg* dynMsg)
{
    typedef int (*SSLFunc)(BIO*, int, long, void*);
    FINDFUNCTION(dynMsg, BIO_ctrl, 0)
    return func(b, BIO_CTRL_EOF, 0, NULL);
}

void DYN_BIO_clear_retry_flags(BIO* b, DynMsg* dynMsg)
{
    typedef void (*SSLFunc)(BIO*, int);
    FINDFUNCTION(dynMsg, BIO_clear_flags, )
    return func(b, (BIO_FLAGS_RWS | BIO_FLAGS_SHOULD_RETRY));
}

long DYN_BIO_get_mem_ptr(BIO* b, BUF_MEM** pp, DynMsg* dynMsg)
{
    typedef int (*SSLFunc)(BIO*, int, long, void*);
    FINDFUNCTION(dynMsg, BIO_ctrl, 0)
    return func(b, BIO_C_GET_BUF_MEM_PTR, 0, (void*)pp);
}

int DYN_SSL_set_tlsext_host_name(SSL* ssl, const char* name, DynMsg* dynMsg)
{
    typedef int (*SSLFunc)(SSL*, int, long, void*);
    FINDFUNCTION(dynMsg, SSL_ctrl, -1)
    return func(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, (void*)name);
}

long DYN_SSL_CTX_set_tlsext_servername_callback(SSL_CTX* ctx, int (*cb)(void* s, int* al, void* arg), DynMsg* dynMsg)
{
    typedef long (*SSLFunc)(SSL_CTX*, int, void(*fp));
    FINDFUNCTION(dynMsg, SSL_CTX_callback_ctrl, -1)
    return func(ctx, SSL_CTRL_SET_TLSEXT_SERVERNAME_CB, (void (*)(void))cb);
}

BIO* DYN_BIO_new_mem(DynMsg* dynMsg)
{
    typedef BIO* (*SSLFunc1)(const BIO_METHOD*);
    FINDFUNCTIONI(dynMsg, 1, BIO_new, NULL)
    typedef BIO_METHOD* (*SSLFunc2)(void);
    FINDFUNCTIONI(dynMsg, 2, BIO_s_mem, NULL)
    return func1(func2());
}

#define DEFINEFUNCTION0(name, errCode, type0)                                                                                                                                      \
    type0 DYN_##name(DynMsg* dynMsg)                                                                                                                                               \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(void);                                                                                                                                            \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func();                                                                                                                                                             \
    }

#define DEFINEFUNCTION1(name, errCode, type0, type1)                                                                                                                               \
    type0 DYN_##name(type1 arg1, DynMsg* dynMsg)                                                                                                                                   \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1);                                                                                                                                           \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1);                                                                                                                                                         \
    }

#define DEFINEFUNCTION2(name, errCode, type0, type1, type2)                                                                                                                        \
    type0 DYN_##name(type1 arg1, type2 arg2, DynMsg* dynMsg)                                                                                                                       \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1, type2);                                                                                                                                    \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1, arg2);                                                                                                                                                   \
    }
#define DEFINEFUNCTIONCB2(name, errCode, type0, type1, type2)                                                                                                                      \
    type0 DYN_##name(type1, type2, DynMsg* dynMsg)                                                                                                                                 \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1, type2);                                                                                                                                    \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1, arg2);                                                                                                                                                   \
    }
#define DEFINEFUNCTION3(name, errCode, type0, type1, type2, type3)                                                                                                                 \
    type0 DYN_##name(type1 arg1, type2 arg2, type3 arg3, DynMsg* dynMsg)                                                                                                           \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1, type2, type3);                                                                                                                             \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1, arg2, arg3);                                                                                                                                             \
    }
#define DEFINEFUNCTIONCB3(name, errCode, type0, type1, type2, type3)                                                                                                               \
    type0 DYN_##name(type1, type2, type3, DynMsg* dynMsg)                                                                                                                          \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1, type2, type3);                                                                                                                             \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1, arg2, arg3);                                                                                                                                             \
    }
#define DEFINEFUNCTION4(name, errCode, type0, type1, type2, type3, type4)                                                                                                          \
    type0 DYN_##name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, DynMsg* dynMsg)                                                                                               \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1, type2, type3, type4);                                                                                                                      \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1, arg2, arg3, arg4);                                                                                                                                       \
    }
#define DEFINEFUNCTION5(name, errCode, type0, type1, type2, type3, type4, type5)                                                                                                   \
    type0 DYN_##name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, DynMsg* dynMsg)                                                                                   \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1, type2, type3, type4, type5);                                                                                                               \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1, arg2, arg3, arg4, arg5);                                                                                                                                 \
    }
#define DEFINEFUNCTION6(name, errCode, type0, type1, type2, type3, type4, type5, type6)                                                                                            \
    type0 DYN_##name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, DynMsg* dynMsg)                                                                       \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1, type2, type3, type4, type5, type6);                                                                                                        \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1, arg2, arg3, arg4, arg5, arg6);                                                                                                                           \
    }
#define DEFINEFUNCTION7(name, errCode, type0, type1, type2, type3, type4, type5, type6, type7)                                                                                     \
    type0 DYN_##name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, DynMsg* dynMsg)                                                           \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1, type2, type3, type4, type5, type6, type7);                                                                                                 \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1, arg2, arg3, arg4, arg5, arg6, arg7);                                                                                                                     \
    }
#define DEFINEFUNCTION8(name, errCode, type0, type1, type2, type3, type4, type5, type6, type7, type8)                                                                              \
    type0 DYN_##name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8, DynMsg* dynMsg)                                               \
    {                                                                                                                                                                              \
        typedef type0 (*SSLFunc)(type1, type2, type3, type4, type5, type6, type7, type8);                                                                                          \
        FINDFUNCTION(dynMsg, name, errCode)                                                                                                                                        \
        return func(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);                                                                                                               \
    }
#include "defineFunction.inc"
#undef DEFINEFUNCTION0
#undef DEFINEFUNCTION1
#undef DEFINEFUNCTION2
#undef DEFINEFUNCTION3
#undef DEFINEFUNCTION4
#undef DEFINEFUNCTION5
#undef DEFINEFUNCTION6
#undef DEFINEFUNCTION7
#undef DEFINEFUNCTION8
#undef DEFINEFUNCTIONCB2
#undef DEFINEFUNCTIONCB3

bool LoadDynFuncForAlpnCallback(DynMsg* dynMsg)
{
    typedef SSL_CTX* (*SSLFunc0)(const SSL*);
    FINDFUNCTIONI(dynMsg, 0, SSL_get_SSL_CTX, false)

    typedef void* (*SSLFunc1)(const SSL_CTX*, int);
    FINDFUNCTIONI(dynMsg, 1, SSL_CTX_get_ex_data, false)

    typedef int (*SSLFunc2)(int, long, void*, CRYPTO_EX_new*, CRYPTO_EX_dup*, CRYPTO_EX_free*);
    FINDFUNCTIONI(dynMsg, 2, CRYPTO_get_ex_new_index, false)

    typedef int (*SSLFunc3)(unsigned char**, unsigned char*, const unsigned char*, unsigned int, const unsigned char*, unsigned int);
    FINDFUNCTIONI(dynMsg, 3, SSL_select_next_proto, false)

    return true;
}

bool LoadFuncForNewSessionCallback(DynMsg* dynMsg)
{
    typedef const unsigned char* (*SSLFunc1)(const SSL_SESSION*, unsigned int*);
    FINDFUNCTIONI(dynMsg, 1, SSL_SESSION_get_id, false)
    typedef int (*SSLFunc2)(SSL_SESSION*, unsigned char**);
    FINDFUNCTIONI(dynMsg, 2, i2d_SSL_SESSION, false)
    typedef SSL_SESSION* (*SSLFunc3)(SSL_SESSION**, const unsigned char**, long);
    FINDFUNCTIONI(dynMsg, 3, d2i_SSL_SESSION, false)
    typedef void (*SSLFunc4)(void*, const char*, int);
    FINDFUNCTIONI(dynMsg, 4, CRYPTO_free, false)
    typedef const unsigned char* (*SSLFunc5)(void*, const char*, int);
    FINDFUNCTIONI(dynMsg, 5, SSL_SESSION_get0_id_context, false)
    typedef int (*SSLFunc6)(SSL_SESSION*, const unsigned char*, unsigned int);
    FINDFUNCTIONI(dynMsg, 6, SSL_SESSION_set1_id_context, false)
    typedef void (*SSLFunc7)(SSL_SESSION*);
    FINDFUNCTIONI(dynMsg, 7, SSL_SESSION_free, false)

    return true;
}

bool LoadDynFuncForCreateMethod(DynMsg* dynMsg)
{
    typedef void (*SSLFunc1)(BIO*, void*);
    FINDFUNCTIONI(dynMsg, 1, BIO_set_data, false)
    typedef void (*SSLFunc2)(BIO*, int);
    FINDFUNCTIONI(dynMsg, 2, BIO_set_init, false)
    typedef void (*SSLFunc3)(BIO*, int);
    FINDFUNCTIONI(dynMsg, 3, BIO_set_flags, false)
    typedef void (*SSLFunc4)(BIO*, int);
    FINDFUNCTIONI(dynMsg, 4, BIO_set_retry_reason, false)
    typedef void* (*SSLFunc5)(BIO*);
    FINDFUNCTIONI(dynMsg, 5, BIO_get_data, false)
    typedef void (*SSLFunc6)(BIO*, int);
    FINDFUNCTIONI(dynMsg, 6, BIO_clear_flags, false)
    return true;
}

bool LoadDynFuncCertVerifyCallback(DynMsg* dynMsg)
{
    typedef X509* (*SSLFunc1)(const X509_STORE_CTX*);
    FINDFUNCTIONI(dynMsg, 1, X509_STORE_CTX_get0_cert, false)
    typedef STACK_OF(X509) * (*SSLFunc2)(const X509_STORE_CTX* ctx);
    FINDFUNCTIONI(dynMsg, 2, X509_STORE_CTX_get0_untrusted, false)
    typedef STACK_OF(X509) * (*SSLFunc3)(void);
    FINDFUNCTIONI(dynMsg, 3, OPENSSL_sk_new_null, false)
    typedef STACK_OF(X509) * (*SSLFunc4)(STACK_OF(X509)*);
    FINDFUNCTIONI(dynMsg, 4, X509_chain_up_ref, false)
    typedef int (*SSLFunc5)(STACK_OF(X509)*, X509*, int);
    FINDFUNCTIONI(dynMsg, 5, OPENSSL_sk_insert, false)
    typedef int (*SSLFunc6)(X509*);
    FINDFUNCTIONI(dynMsg, 6, X509_up_ref, false)
    typedef void (*SSLFunc7)(X509_STORE_CTX*, STACK_OF(X509)*);
    FINDFUNCTIONI(dynMsg, 7, X509_STORE_CTX_set0_verified_chain, false)
    typedef void (*SSLFunc8)(X509_STORE_CTX*, int);
    FINDFUNCTIONI(dynMsg, 8, X509_STORE_CTX_set_error, false)

    return true;
}

bool LoadDynFuncForCustomVerifyCallback(DynMsg* dynMsg)
{
    typedef SSL* (*SSLFunc1)(const X509_STORE_CTX*, int);
    FINDFUNCTIONI(dynMsg, 1, X509_STORE_CTX_get_ex_data, false)
    typedef int (*SSLFunc2)(void);
    FINDFUNCTIONI(dynMsg, 2, SSL_get_ex_data_X509_STORE_CTX_idx, false)
    typedef SSL_CTX* (*SSLFunc3)(const SSL*);
    FINDFUNCTIONI(dynMsg, 3, SSL_get_SSL_CTX, false)
    typedef STACK_OF(X509) * (*SSLFunc4)(const X509_STORE_CTX* ctx);
    FINDFUNCTIONI(dynMsg, 4, X509_STORE_CTX_get0_untrusted, false)
    typedef int (*SSLFunc5)(void*);
    FINDFUNCTIONI(dynMsg, 5, OPENSSL_sk_num, false)
    typedef void* (*SSLFunc6)(void*, int);
    FINDFUNCTIONI(dynMsg, 6, OPENSSL_sk_value, false)
    typedef void (*SSLFunc7)(void*, const char*, int);
    FINDFUNCTIONI(dynMsg, 7, CRYPTO_free, false)

    return true;
}

bool LoadDynForInfoCallback(DynMsg* dynMsg)
{
    typedef void* (*SSLFunc1)(const SSL*, int);
    FINDFUNCTIONI(dynMsg, 1, SSL_get_ex_data, false)
    typedef const char* (*SSLFunc2)(int);
    FINDFUNCTIONI(dynMsg, 2, SSL_alert_desc_string_long, false)
    typedef const char* (*SSLFunc3)(int);
    FINDFUNCTIONI(dynMsg, 3, SSL_alert_type_string, false)

    return true;
}

void DYN_BIO_set_retry_read(BIO* a, DynMsg* dynMsg)
{
    DYN_BIO_set_flags(a, (BIO_FLAGS_READ | BIO_FLAGS_SHOULD_RETRY), dynMsg);
}

void DYN_BIO_set_retry_write(BIO* a, DynMsg* dynMsg)
{
    DYN_BIO_set_flags(a, (BIO_FLAGS_WRITE | BIO_FLAGS_SHOULD_RETRY), dynMsg);
}

void DynPopFree(void* extlist, const char* funcName, DynMsg* dynMsg)
{
    typedef void (*SSLFunc0)(void*);
    SSLFunc0 func0 = NULL;
#if defined(CANGJIE_OPENSSL_RESOLVE_STRONG)
    func0 = (SSLFunc0)ResolveDynPopFreeFunction(funcName);
    CHECKFUNCTION(dynMsg, 0, funcName, )
#elif defined(CANGJIE_OPENSSL_RESOLVE_AUTO)
    if (CANGJIE_OPENSSL_AUTO_WEAK_AVAILABLE) {
        func0 = (SSLFunc0)ResolveDynPopFreeFunction(funcName);
    }
    if (func0 == NULL) {
        func0 = (SSLFunc0)(FindFunction(funcName));
        CHECKFUNCTION(dynMsg, 0, funcName, )
    }
#else
    func0 = (SSLFunc0)(FindFunction(funcName));
    CHECKFUNCTION(dynMsg, 0, funcName, )
#endif
    DYN_OPENSSL_sk_pop_free(extlist, func0, dynMsg);
}
