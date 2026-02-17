//
//  DoubaoRealtimeTypes.swift
//  Mobi
//
//  Volc 端到端实时语音 v3 二进制帧：编码/解码、事件 ID。
//

import Foundation
import Compression

/// Raw Deflate (Swift 中未导出的符号用 raw value)
private let kCompressionZlibRaw: compression_algorithm = compression_algorithm(rawValue: 0x307)

// MARK: - Gzip Helper (permissive: skip 10 bytes then raw Deflate)
extension Data {
    func gunzipped() -> Data? {
        let bufferSize = 64 * 1024
        var output = Data()
        guard self.count > 10 else { return nil }
        let subdata = self.subdata(in: 10..<self.count)
        return subdata.withUnsafeBytes { ptr -> Data? in
            guard let base = ptr.baseAddress else { return nil }
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
            defer { streamPtr.deallocate() }
            var stream = streamPtr.pointee
            stream.src_ptr = base.assumingMemoryBound(to: UInt8.self)
            stream.src_size = subdata.count
            stream.dst_ptr = buffer
            stream.dst_size = bufferSize
            let status = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, kCompressionZlibRaw)
            guard status != COMPRESSION_STATUS_ERROR else { return nil }
            defer { compression_stream_destroy(&stream) }
            while true {
                stream.dst_ptr = buffer
                stream.dst_size = bufferSize
                let result = compression_stream_process(&stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))
                switch result {
                case COMPRESSION_STATUS_OK:
                    output.append(buffer, count: bufferSize - stream.dst_size)
                case COMPRESSION_STATUS_END:
                    output.append(buffer, count: bufferSize - stream.dst_size)
                    return output
                default:
                    return nil
                }
            }
        }
    }
}

// MARK: - Event IDs
enum DoubaoClientEventId: UInt32 {
    case startConnection = 1
    case startSession = 100
    case finishSession = 102
    case taskRequest = 200      // 仅音频二进制
    case sayHello = 300
    case chatTextQuery = 501
}

enum DoubaoServerEventId: UInt32 {
    case connectionStarted = 50
    case sessionStarted = 150
    case ttsResponse = 352
    case asrResponse = 451
    case chatResponse = 550
}

// MARK: - Frame Logic
// 协议：header(4) + [event(4)] + [session_id_size(4)+session_id] + payload_size(4) + payload
struct DoubaoFrame {
    /// 编码客户端帧。Session 类事件（100/102/501 等）需传 sessionId。
    static func encode(type: Int, payload: Data, sessionId: String? = nil) -> Data {
        var data = Data()
        data.append(0x11)
        let msgType: UInt8 = (type == 200 ? 0x2 : 0x1)
        // 协议要求 event 必须：200 音频帧也带 event id，否则服务端会误解析 payload 导致 "unexpected end of JSON input"
        let hasEvent = true
        data.append((msgType << 4) | (hasEvent ? 0x04 : 0x00))
        data.append(0x10)
        data.append(0x00)

        if hasEvent {
            var eventBe = UInt32(type).bigEndian
            data.append(Data(bytes: &eventBe, count: 4))
        }

        if let sid = sessionId, let sidData = sid.data(using: .utf8), !sidData.isEmpty {
            var sidLen = UInt32(sidData.count).bigEndian
            data.append(Data(bytes: &sidLen, count: 4))
            data.append(sidData)
        }

        var size = UInt32(payload.count).bigEndian
        data.append(Data(bytes: &size, count: 4))
        data.append(payload)
        return data
    }

    static func decode(_ data: Data) -> (eventId: Int, payload: Data, isAudio: Bool)? {
        guard data.count > 8 else { return nil }

        if let jsonStartIndex = data.firstIndex(of: 0x7b) {
            let jsonPayload = data.subdata(in: jsonStartIndex..<data.count)
            if let _ = String(data: jsonPayload, encoding: .utf8) {
                var eventId = 0
                if let json = try? JSONSerialization.jsonObject(with: jsonPayload) as? [String: Any],
                   let idStr = json["event_id"] as? String {
                    eventId = Int(idStr) ?? 0
                }
                if eventId == 0, data.count >= 8 {
                    eventId = Int(data.subdata(in: 4..<8).withUnsafeBytes { UInt32(bigEndian: $0.load(as: UInt32.self)) })
                }
                if eventId == 0, !jsonPayload.isEmpty,
                   let str = String(data: jsonPayload, encoding: .utf8) {
                    print("[Doubao] 🔥 SERVER ERROR: \(str)")
                }
                return (eventId, jsonPayload, false)
            }
        }

        let msgType = Int((data[1] >> 4) & 0x0F)
        let hasEventFlag = (data[1] & 0x04) != 0
        let headerOffset12 = 12
        if hasEventFlag, data.count >= headerOffset12 {
            let eventId = Int(data.withUnsafeBytes { UInt32(bigEndian: $0.load(fromByteOffset: 4, as: UInt32.self)) })
            let afterEvent = data.subdata(in: 8..<12).withUnsafeBytes { UInt32(bigEndian: $0.load(as: UInt32.self)) }
            var payOff = headerOffset12
            var payLen = Int(afterEvent)
            // Session 级服务端响应可能带 session_id(36)：若 8-11==36 且 48-51 为合理长度，则 payload 从 52 开始
            if afterEvent == 36, data.count >= 52 {
                let payLen2 = data.subdata(in: 48..<52).withUnsafeBytes { UInt32(bigEndian: $0.load(as: UInt32.self)) }
                if payLen2 > 0, payLen2 < 10_000_000, data.count >= 52 + Int(payLen2) {
                    payOff = 52
                    payLen = Int(payLen2)
                }
            }
            if payLen > 0, payLen < 10_000_000, data.count >= payOff + payLen {
                let rawPayload = data.subdata(in: payOff..<(payOff + payLen))
                var finalPayload = rawPayload
                if (data[2] & 0x0F) == 1, let unzipped = rawPayload.gunzipped() { finalPayload = unzipped }
                return (eventId, finalPayload, msgType == 0x0B)
            }
        }
        let payloadSize8 = data.subdata(in: 4..<8).withUnsafeBytes { UInt32(bigEndian: $0.load(as: UInt32.self)) }
        let headerOffset8 = 8
        if data.count >= headerOffset8 + Int(payloadSize8) {
            let rawPayload = data.subdata(in: headerOffset8..<(headerOffset8 + Int(payloadSize8)))
            var finalPayload = rawPayload
            if (data[2] & 0x0F) == 1, let unzipped = rawPayload.gunzipped() { finalPayload = unzipped }
            var eventId = 0
            if let json = try? JSONSerialization.jsonObject(with: finalPayload) as? [String: Any],
               let idStr = json["event_id"] as? String { eventId = Int(idStr) ?? 0 }
            if eventId == 0, data.count >= 12 {
                eventId = Int(data.withUnsafeBytes { UInt32(bigEndian: $0.load(fromByteOffset: 4, as: UInt32.self)) })
            }
            return (eventId, finalPayload, msgType == 0x0B)
        }
        guard data.count >= headerOffset12 else { return nil }
        let payloadSize12 = data.subdata(in: 8..<12).withUnsafeBytes { UInt32(bigEndian: $0.load(as: UInt32.self)) }
        guard data.count >= headerOffset12 + Int(payloadSize12) else { return nil }
        let rawPayload = data.subdata(in: headerOffset12..<(headerOffset12 + Int(payloadSize12)))
        var finalPayload = rawPayload
        if (data[2] & 0x0F) == 1, let unzipped = rawPayload.gunzipped() { finalPayload = unzipped }
        var eventId = Int(data.withUnsafeBytes { UInt32(bigEndian: $0.load(fromByteOffset: 4, as: UInt32.self)) })
        if let json = try? JSONSerialization.jsonObject(with: finalPayload) as? [String: Any],
           let idStr = json["event_id"] as? String { eventId = Int(idStr) ?? eventId }
        return (eventId, finalPayload, msgType == 0x0B)
    }
}
