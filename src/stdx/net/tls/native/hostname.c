/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

#include "api.h"
#include "opensslSymbols.h"

extern const char* CJ_TLS_DYN_GetHostName(SSL* ssl, DynMsg* dynMsg)
{
    if (ssl == NULL) {
        return NULL;
    }

    return DYN_SSL_get_servername(ssl, TLSEXT_NAMETYPE_host_name, dynMsg);
}

static int CJ_TLS_SetHostName_Callback(void* s, int* al, void* arg)
{
    (void)s;
    (void)al;
    (void)arg;
    // If we ever want to do SNI filtering on server,
    // this is the place to do it
    return SSL_TLSEXT_ERR_OK;
}

extern int CJ_TLS_DYN_ServerEnableSNI(SSL_CTX* context, DynMsg* dynMsg)
{
    if (context == NULL) {
        return 0;
    }

    (void)DYN_SSL_CTX_set_tlsext_servername_callback(context, CJ_TLS_SetHostName_Callback, dynMsg);
    return 1;
}

extern int CJ_TLS_DYN_SetHostName(SSL* stream, const char* name, DynMsg* dynMsg)
{
    if (stream == NULL || name == NULL) {
        return 0;
    }

    return (int)DYN_SSL_set_tlsext_host_name(stream, name, dynMsg);
}

extern int CJ_TLS_DYN_SetHostNameForVerify(SSL* stream, const char* name, DynMsg* dynMsg)
{
    if (stream == NULL || name == NULL) {
        return 0;
    }

    X509_VERIFY_PARAM* param = DYN_SSL_get0_param(stream, dynMsg);
    if (param == NULL) {
        return 0;
    }

    /* An IP literal must be validated against the iPAddress SAN instead of the
     * DNS SAN, so try the IP-aware API first; it fails (without side effects)
     * for non-IP names and we fall back to the DNS hostname API. */
    if (DYN_X509_VERIFY_PARAM_set1_ip_asc(param, name, dynMsg) == 1) {
        return 1;
    }

    return DYN_X509_VERIFY_PARAM_set1_host(param, name, 0, dynMsg);
}
