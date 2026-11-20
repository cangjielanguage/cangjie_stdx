# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

set(HTTP_SRCS
        pool.cj
        buffered_conn.cj
        client.cj
        collection_extend.cj
        collection_multi_level_queue.cj
        collection_queue.cj
        constants.cj
        cookie_jar.cj 
        cookie.cj
        coroutine_pool.cj
        exception.cj
        frame.cj
        hpack_decoder.cj
        hpack_encoder.cj
        hpack_header_table.cj
        hpack_quick_huffman.cj
        hpack_utils.cj
        http_body.cj
        http_client1_1.cj
        http_client2_0.cj
        http_distributor.cj
        http_engine_conn.cj
        http_enum.cj
        http_handler.cj
        http_header.cj
        http_logger.cj
        http_request_context.cj
        http_request.cj
        http_response.cj
        http_server1_1.cj
        http_server2_0.cj
        http_status_code.cj
        protocol_service.cj
        server.cj
        str.cj
        stream_client.cj
        stream_server2_0.cj
        transport.cj
        utils.cj
        utils2_0.cj
        websocket_conn.cj
        websocket_frame.cj
        websocket_status_code.cj
        websocket_utf8.cj
        websocket.cj
        CACHE INTERNAL ""
)