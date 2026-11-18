/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.net.tls.common

import std.net.StreamingSocket

public interface TlsKit {
    func getTlsServer(socket: StreamingSocket, config: TlsConfig, session!: ?TlsSession): TlsConnection
    func getTlsClient(socket: StreamingSocket, config: TlsConfig, session!: ?TlsSession): TlsConnection
    func getTlsServerSession(name: String): TlsSession
}

var globalTlsKit: ?TlsKit = None

public func setGlobalTlsKit(kit: TlsKit): Unit {
    globalTlsKit = kit
}

public func getGlobalTlsKit(): TlsKit {
    globalTlsKit ?? throw TlsException("Global TLS kit is not set. " +
        "The default implementation provided by package 'stdx.net.tls' is not imported.")
}
