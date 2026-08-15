import Foundation
import os

private let oracleTraceLogger = Logger(
    subsystem: "io.github.deestiz.sm64modern",
    category: "OracleTrace"
)

private func oracleTraceSession(from context: UnsafeMutableRawPointer?)
    -> SM64ModernOracleTraceSession? {
    guard let context else { return nil }
    return Unmanaged<SM64ModernOracleTraceSession>.fromOpaque(context).takeUnretainedValue()
}

private let oracleTraceWriteHeader: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernOracleTraceConfigV1>?
) -> SM64ModernStatus = { context, config in
    guard let session = oracleTraceSession(from: context), let config else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return session.write(config: config)
}

private let oracleTraceReadHeader: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<SM64ModernOracleTraceConfigV1>?
) -> SM64ModernStatus = { context, config in
    guard let session = oracleTraceSession(from: context), let config else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return session.read(config: config)
}

private let oracleTraceWriteRecord: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafePointer<SM64ModernOracleTraceRecordV1>?
) -> SM64ModernStatus = { context, record in
    guard let session = oracleTraceSession(from: context), let record else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return session.write(record: record)
}

private let oracleTraceReadRecord: @convention(c) (
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<SM64ModernOracleTraceRecordV1>?
) -> SM64ModernStatus = { context, record in
    guard let session = oracleTraceSession(from: context), let record else {
        return SM64_MODERN_STATUS_INVALID_ARGUMENT
    }
    return session.read(record: record)
}

/// Engine-owner-thread trace file session. The C stream callbacks below are
/// the only unsafe boundary; the mutable file handle never crosses into a
/// Swift concurrency domain.
final class SM64ModernOracleTraceSession {
    private enum Mode {
        case record
        case replay

        var cValue: SM64ModernOracleTraceMode {
            switch self {
                case .record: return SM64_MODERN_ORACLE_TRACE_RECORD
                case .replay: return SM64_MODERN_ORACLE_TRACE_REPLAY
            }
        }
    }

    private let mode: Mode
    private let traceURL: URL
    private let handle: FileHandle
    private let tickLimit: UInt64?
    private var active = false

    private init(mode: Mode, traceURL: URL, handle: FileHandle, tickLimit: UInt64?) {
        self.mode = mode
        self.traceURL = traceURL
        self.handle = handle
        self.tickLimit = tickLimit
    }

    static func beginFromEnvironment(
        saveDirectory: String
    ) -> (session: SM64ModernOracleTraceSession?, status: SM64ModernStatus) {
        let environment = ProcessInfo.processInfo.environment
        guard let modeName = environment["SM64_MODERN_ORACLE_TRACE_MODE"], !modeName.isEmpty else {
            return (nil, SM64_MODERN_STATUS_OK)
        }
        let mode: Mode
        switch modeName.lowercased() {
            case "record": mode = .record
            case "replay": mode = .replay
            default:
                oracleTraceLogger.error("oracle_trace_configuration_invalid key=mode")
                return (nil, SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }
        guard let path = environment["SM64_MODERN_ORACLE_TRACE_PATH"], !path.isEmpty else {
            oracleTraceLogger.error("oracle_trace_configuration_invalid key=path")
            return (nil, SM64_MODERN_STATUS_INVALID_ARGUMENT)
        }

        let traceURL = URL(fileURLWithPath: path).standardizedFileURL
        let handle: FileHandle
        do {
            if mode == .record {
                try FileManager.default.createDirectory(
                    at: traceURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try Data().write(to: traceURL, options: .atomic)
                handle = try FileHandle(forWritingTo: traceURL)
            } else {
                handle = try FileHandle(forReadingFrom: traceURL)
            }
        } catch {
            oracleTraceLogger.error("oracle_trace_open_failed error=io")
            return (nil, SM64_MODERN_STATUS_PLATFORM_ERROR)
        }

        let tickLimit = environment["SM64_MODERN_ORACLE_TRACE_TICKS"]
            .flatMap(UInt64.init)
            .flatMap { $0 == 0 ? nil : $0 }
        let session = SM64ModernOracleTraceSession(
            mode: mode,
            traceURL: traceURL,
            handle: handle,
            tickLimit: tickLimit
        )
        let status = session.begin(saveDirectory: saveDirectory)
        guard status == SM64_MODERN_STATUS_OK else {
            try? handle.close()
            return (nil, status)
        }
        return (session, SM64_MODERN_STATUS_OK)
    }

    func shouldStop(after step: UInt64) -> Bool {
        guard active, let tickLimit else { return false }
        return step >= tickLimit
    }

    func end() -> SM64ModernStatus {
        guard active else { return SM64_MODERN_STATUS_OK }
        active = false
        let status = sm64_modern_oracle_trace_end()
        if mode == .record {
            try? handle.synchronize()
        }
        try? handle.close()
        oracleTraceLogger.notice(
            "oracle_trace_finished status=\(status) path=\(self.traceURL.lastPathComponent, privacy: .public)"
        )
        return status
    }

    fileprivate func write(config: UnsafePointer<SM64ModernOracleTraceConfigV1>)
        -> SM64ModernStatus {
        do {
            try handle.write(contentsOf: Data(
                bytes: config,
                count: MemoryLayout<SM64ModernOracleTraceConfigV1>.size
            ))
            return SM64_MODERN_STATUS_OK
        } catch {
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }
    }

    fileprivate func read(config: UnsafeMutablePointer<SM64ModernOracleTraceConfigV1>)
        -> SM64ModernStatus {
        do {
            let size = MemoryLayout<SM64ModernOracleTraceConfigV1>.size
            guard let data = try handle.read(upToCount: size), data.count == size else {
                return SM64_MODERN_STATUS_END_OF_STREAM
            }
            data.copyBytes(to: UnsafeMutableRawBufferPointer(start: config, count: size))
            return SM64_MODERN_STATUS_OK
        } catch {
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }
    }

    fileprivate func write(record: UnsafePointer<SM64ModernOracleTraceRecordV1>)
        -> SM64ModernStatus {
        do {
            try handle.write(contentsOf: Data(
                bytes: record,
                count: MemoryLayout<SM64ModernOracleTraceRecordV1>.size
            ))
            return SM64_MODERN_STATUS_OK
        } catch {
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }
    }

    fileprivate func read(record: UnsafeMutablePointer<SM64ModernOracleTraceRecordV1>)
        -> SM64ModernStatus {
        do {
            let size = MemoryLayout<SM64ModernOracleTraceRecordV1>.size
            guard let data = try handle.read(upToCount: size) else {
                return SM64_MODERN_STATUS_END_OF_STREAM
            }
            guard data.count == size else { return SM64_MODERN_STATUS_INVALID_ARGUMENT }
            data.copyBytes(to: UnsafeMutableRawBufferPointer(start: record, count: size))
            return SM64_MODERN_STATUS_OK
        } catch {
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }
    }

    private func begin(saveDirectory: String) -> SM64ModernStatus {
        var config = SM64ModernOracleTraceConfigV1()
        config.header.abi_version = SM64_MODERN_ABI_VERSION_1
        config.header.struct_size = UInt32(MemoryLayout<SM64ModernOracleTraceConfigV1>.size)
        config.schema_version = SM64_MODERN_ORACLE_TRACE_SCHEMA_VERSION
        config.region_code = 0x5553
        config.mode = mode.cValue
        // STUB(M3): Save/render/script/collision/RNG/audio-sequencing hooks
        // still need to be wired before full-inventory qualification.
        // Live capture records observed coverage while whole-inventory
        // reachability is still being closed. Set the opt-in flag for the
        // qualification harness once every declared entry is expected.
        config.coverage_fingerprint = ProcessInfo.processInfo.environment[
            "SM64_MODERN_ORACLE_REQUIRE_FULL_COVERAGE"
        ] == "1" ? sm64_modern_oracle_inventory_fingerprint() : 0

        do {
            guard let executableURL = Bundle.main.executableURL else {
                return SM64_MODERN_STATUS_PLATFORM_ERROR
            }
            config.build_fingerprint = try Self.fingerprint(
                directory: executableURL.deletingLastPathComponent()
            )
            config.initial_save_fingerprint = try Self.fingerprint(
                directory: URL(fileURLWithPath: saveDirectory)
            )
            config.timebase_fingerprint = sm64_modern_timebase_fingerprint()
            config.configuration_fingerprint = Self.configurationFingerprint(
                environment: ProcessInfo.processInfo.environment
            )
            if let contentPath = ProcessInfo.processInfo.environment["SM64_MODERN_CONTENT_PACK"] {
                config.content_fingerprint = try Self.fileFingerprint(
                    url: URL(fileURLWithPath: contentPath)
                )
            }
        } catch {
            oracleTraceLogger.error("oracle_trace_fingerprint_failed error=io")
            return SM64_MODERN_STATUS_PLATFORM_ERROR
        }

        var stream = SM64ModernOracleTraceStreamApiV1()
        stream.header.abi_version = SM64_MODERN_ABI_VERSION_1
        stream.header.struct_size = UInt32(MemoryLayout<SM64ModernOracleTraceStreamApiV1>.size)
        stream.context = Unmanaged.passUnretained(self).toOpaque()
        stream.write_header = oracleTraceWriteHeader
        stream.read_header = oracleTraceReadHeader
        stream.write_record = oracleTraceWriteRecord
        stream.read_record = oracleTraceReadRecord

        let status = sm64_modern_oracle_trace_begin(&config, &stream)
        guard status == SM64_MODERN_STATUS_OK else {
            oracleTraceLogger.error("oracle_trace_begin_failed status=\(status)")
            return status
        }
        active = true
        oracleTraceLogger.notice(
            "oracle_trace_started mode=\(self.mode.cValue) schema=\(config.schema_version) path=\(self.traceURL.lastPathComponent, privacy: .public) ticks=\(self.tickLimit ?? 0)"
        )
        return status
    }

    private static func fingerprint(directory: URL) throws -> UInt64 {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ).filter { (try? $0.resourceValues(forKeys: Set(keys)).isRegularFile) == true }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var hash = SM64OracleTraceHash.offset
        for file in files {
            hash = update(hash, with: Data(file.lastPathComponent.utf8))
            hash = update(hash, with: try Data(contentsOf: file, options: .mappedIfSafe))
        }
        return hash
    }

    private static func fileFingerprint(url: URL) throws -> UInt64 {
        update(SM64OracleTraceHash.offset, with: try Data(contentsOf: url, options: .mappedIfSafe))
    }

    private static func configurationFingerprint(environment: [String: String]) -> UInt64 {
        let ignored = Set([
            "SM64_MODERN_ORACLE_TRACE_MODE",
            "SM64_MODERN_ORACLE_TRACE_PATH",
            "SM64_MODERN_ORACLE_TRACE_TICKS",
            "SM64_MODERN_CONTENT_PACK",
        ])
        let bytes = environment
            .filter { !ignored.contains($0.key) }
            .sorted { $0.key < $1.key }
            .flatMap { Array("\($0.key)=\($0.value)\n".utf8) }
        return update(SM64OracleTraceHash.offset, with: Data(bytes))
    }

    private static func update(_ startingHash: UInt64, with data: Data) -> UInt64 {
        data.reduce(startingHash) { hash, byte in
            (hash ^ UInt64(byte)) &* SM64OracleTraceHash.prime
        }
    }
}
