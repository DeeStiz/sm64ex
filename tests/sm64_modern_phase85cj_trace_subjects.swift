import Foundation

private func u32(_ data: Data, _ offset: Int) -> UInt32 {
    data[offset..<offset + 4].enumerated().reduce(0) {
        $0 | UInt32($1.element) << UInt32($1.offset * 8)
    }
}

private func u64(_ data: Data, _ offset: Int) -> UInt64 {
    data[offset..<offset + 8].enumerated().reduce(0) {
        $0 | UInt64($1.element) << UInt64($1.offset * 8)
    }
}

private enum ProbeError: Error, CustomStringConvertible {
    case invalid(String)

    var description: String {
        switch self {
        case .invalid(let message): return message
        }
    }
}

private let headerSize = 72
private let recordSize = 128

do {
    let paths = Array(CommandLine.arguments.dropFirst())
    guard paths.count >= 1 else {
        throw ProbeError.invalid("usage: phase85cj-trace-subjects DEBUG [ASAN RELEASE]")
    }
    for path in paths {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        print("phase85cj_path=\(path)")
        for index in 340...380 {
            let offset = headerSize + index * recordSize
            guard offset + recordSize <= data.count else { continue }
            let domain = u32(data, offset + 16)
            let kind = u32(data, offset + 20)
            guard domain == 12, kind == 4 else { continue }
            let values = [u64(data, offset + 56), u64(data, offset + 64), u64(data, offset + 72)]
            print(
                "phase85cj_record=\(index) tick=\(u64(data, offset + 8)) subject=\(u64(data, offset + 24)) " +
                    "record_id=\(u64(data, offset + 32)) sequence=\(u32(data, offset + 40)) " +
                    "value_count=\(u32(data, offset + 44)) values=(0x\(String(values[0], radix: 16))," +
                    "0x\(String(values[1], radix: 16)),0x\(String(values[2], radix: 16)))"
            )
        }
    }
} catch {
    FileHandle.standardError.write(Data("phase85cj_trace_subjects_failed=\(error)\n".utf8))
    exit(1)
}
