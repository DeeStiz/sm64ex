import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

@main
enum SM64ModernBehaviorCoverageSmoke {
    static func main() {
        let opcodes = SM64BehaviorOpcode.allCases.sorted { $0.rawValue < $1.rawValue }
        require(opcodes.count == 0x39, "all behavior opcodes are represented")
        require(opcodes.enumerated().allSatisfy { $0.element.rawValue == UInt8($0.offset) }, "behavior opcode slots are contiguous")

        let expectedLengths: [Int] = [
            1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2,
            1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1,
            1, 1, 3, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2,
            1, 3, 2, 3, 3, 1, 2, 2, 5, 2, 1, 2, 1, 1,
            2, 2, 1
        ]
        require(expectedLengths.count == opcodes.count, "length fixture covers every behavior opcode")
        require(zip(opcodes, expectedLengths).allSatisfy { SM64BehaviorScriptProgram.wordLength(opcode: $0.0) == $0.1 }, "behavior word lengths match C ABI fixture")

        var fingerprint = fnvOffset
        for (opcode, length) in zip(opcodes, expectedLengths) {
            fingerprint = hashU64(fingerprint, UInt64(opcode.rawValue))
            fingerprint = hashU64(fingerprint, UInt64(length))
        }
        print(String(format: "behaviorOpcodeCoverageFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern behavior opcode coverage smoke passed opcodes=" + String(opcodes.count))
    }
}
