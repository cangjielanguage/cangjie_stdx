/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

#ifndef CJTLS_API_H
#define CJTLS_API_H

#include <stdbool.h>
#include "opensslSymbols.h"

#define CJTLS_EOF 0
#define CJTLS_FAIL (-1)
#define CJTLS_NEED_READ (-2)
#define CJTLS_NEED_WRITE (-3)
#define CJTLS_OK 1

#define EXCEPTION_OR_RETURN(exception, ret, dynMsg)                                                                    \
    do {                                                                                                               \
        if ((exception) == NULL) {                                                                                     \
            return (ret);                                                                                              \
        };                                                                                                             \
        ExceptionClear(exception, dynMsg);                                                                             \
    } while (0)

#define EXCEPTION_OR_FAIL(exception, dynMsg) EXCEPTION_OR_RETURN((exception), CJTLS_FAIL, dynMsg)

#define NOT_NULL_OR_RETURN(exception, var, ret, dynMsg)                                                                \
    do {                                                                                                               \
        if (!CheckNotNull(exception, (void*)(var), #var, dynMsg))                                                      \
            return (ret);                                                                                              \
    } while (0)

#define NOT_NULL_OR_FAIL(exception, var, dynMsg) NOT_NULL_OR_RETURN((exception), (var), CJTLS_FAIL, dynMsg)

#define CHECK_OR_RETURN(exception, cond, ret, dynMsg)                                                                  \
    do {                                                                                                               \
        if (!CheckOrFillException(exception, (bool)(cond), #cond, dynMsg))                                             \
            return (ret);                                                                                              \
    } while (0)

#define CHECK_OR_FAIL(exception, cond, dynMsg) CHECK_OR_RETURN((exception), (cond), CJTLS_FAIL, dynMsg)

typedef struct ExceptionDataS ExceptionData;

typedef struct TlsCipherSuite {
    const char* name;
} TlsCipherSuite;

void ExceptionClear(ExceptionData* exception, DynMsg* dynMsg);

bool CheckOrFillException(ExceptionData* exception, bool condition, const char* description, DynMsg* dynMsg);

bool CheckNotNull(ExceptionData* exception, const void* candidate, const char* name, DynMsg* dynMsg);

void HandleAlertError(ExceptionData* exception, const char* description, const char* type, DynMsg* dynMsg);

void HandleError(ExceptionData* exception, const char* fallback, DynMsg* dynMsg);

BIO_METHOD* CJ_TLS_BIO_GetMethod(ExceptionData* exception, DynMsg* dynMsg);

int CJ_TLS_BIO_Map(BIO* bio, void* pointer, size_t length, int eof, ExceptionData* exception, DynMsg* dynMsg);

int CJ_TLS_BIO_Unmap(BIO* bio, int eof, ExceptionData* exception, DynMsg* dynMsg);

int NewSessionCallback(SSL* ssl, SSL_SESSION* session);

void SessionReusedCallback(SSL* ssl, SSL_SESSION* session);

BIO* InitBioWithPem(const void* pem, size_t length, ExceptionData* exception, DynMsg* dynMsg);
#endif
