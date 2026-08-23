import Foundation

/// The camera-water receipt is bound to the authored DDD area-1 camera
/// recipe.  This value-only mirror does not call a C collision helper and does
/// not accept the generic domain-7 environment record as a camera receipt.
struct SM64CameraWaterQuerySourceRecipe: Equatable, Sendable {
    static let levelNumber: Int32 = 23 // LEVEL_DDD in levels/level_defines.h
    static let areaIndex: Int32 = 1
    static let cameraMode: Int16 = 2 // CAMERA_MODE_OUTWARD_RADIAL
    static let authoredMarioSpawn = (x: Float(-3071), y: Float(3000), z: Float(500))
    static let authoredCameraNode = (x: Float(0), y: Float(2000), z: Float(6000))
    static let authoredCameraFocus = (x: Float(2560), y: Float(0), z: Float(512))
    static let identity =
        "src/game/camera.c:2471:sm64_modern_camera_evaluate_callback:find_water_level"
}

struct SM64CameraWaterQueryReceipt {
    static let domain: UInt32 = 5
    static let recordKind: UInt32 = 3
    static let recordID: UInt64 = 307
    static let subjectID: UInt64 = 0x3405_65d4_295e_a359
    static let routeFlag: UInt32 = 0x4341_4d57
    static let queryExecutedFlag: UInt32 = 1 << 0
    static let hasHeightFlag: UInt32 = 1 << 1

    let record: SM64OracleTraceRecord
    let mode: Int16
    let level: Int32
    let area: Int32
    let cameraPositionBits: (UInt32, UInt32, UInt32)
    let marioPositionBits: (UInt32, UInt32, UInt32)
    let queryBits: (UInt32, UInt32)
    let waterHeightBits: UInt32
    let resultFlags: UInt32

    init(native: SM64OracleTraceRecord) throws {
        guard native.domain == Self.domain,
              native.recordKind == Self.recordKind,
              native.recordID == Self.recordID,
              native.subjectID == Self.subjectID,
              native.flags == Self.routeFlag,
              native.values.count == 8 else {
            throw SM64OracleTraceCodecError.invalidHeader
        }

        let modeBits = UInt16(truncatingIfNeeded: native.values[0])
        let mode = Int16(bitPattern: modeBits)
        let level = Int32(bitPattern: UInt32(truncatingIfNeeded: native.values[1]))
        let area = Int32(bitPattern: UInt32(truncatingIfNeeded: native.values[1] >> 32))
        let cameraX = UInt32(truncatingIfNeeded: native.values[2])
        let cameraY = UInt32(truncatingIfNeeded: native.values[2] >> 32)
        let cameraZ = UInt32(truncatingIfNeeded: native.values[3])
        let marioX = UInt32(truncatingIfNeeded: native.values[3] >> 32)
        let marioY = UInt32(truncatingIfNeeded: native.values[4])
        let marioZ = UInt32(truncatingIfNeeded: native.values[4] >> 32)
        let queryX = UInt32(truncatingIfNeeded: native.values[5])
        let queryZ = UInt32(truncatingIfNeeded: native.values[5] >> 32)
        let waterHeight = UInt32(truncatingIfNeeded: native.values[6])
        let resultFlags = UInt32(truncatingIfNeeded: native.values[7])

        guard mode == SM64CameraWaterQuerySourceRecipe.cameraMode,
              level == SM64CameraWaterQuerySourceRecipe.levelNumber,
              area == SM64CameraWaterQuerySourceRecipe.areaIndex,
              resultFlags & ~Self.hasHeightFlag & ~Self.queryExecutedFlag == 0,
              resultFlags & Self.queryExecutedFlag != 0,
              queryX == marioX,
              queryZ == marioZ else {
            throw SM64OracleTraceCodecError.invalidHeader
        }

        let rebuilt = try SM64OracleTraceRecord(
            simulationTick: native.simulationTick,
            domain: native.domain,
            recordKind: native.recordKind,
            subjectID: native.subjectID,
            recordID: native.recordID,
            sequence: native.sequence,
            flags: native.flags,
            values: native.values
        )
        guard rebuilt == native else {
            throw SM64OracleTraceCodecError.nonCanonicalHash
        }

        record = native
        self.mode = mode
        self.level = level
        self.area = area
        cameraPositionBits = (cameraX, cameraY, cameraZ)
        marioPositionBits = (marioX, marioY, marioZ)
        queryBits = (queryX, queryZ)
        waterHeightBits = waterHeight
        self.resultFlags = resultFlags
    }

    static func makeRecord(
        simulationTick: UInt64,
        sequence: UInt32,
        cameraPositionBits: (UInt32, UInt32, UInt32),
        marioPositionBits: (UInt32, UInt32, UInt32),
        waterHeightBits: UInt32,
        resultFlags: UInt32 = queryExecutedFlag
    ) throws -> SM64OracleTraceRecord {
        let values: [UInt64] = [
            UInt64(UInt16(bitPattern: SM64CameraWaterQuerySourceRecipe.cameraMode)),
            UInt64(UInt32(bitPattern: SM64CameraWaterQuerySourceRecipe.levelNumber))
                | (UInt64(UInt32(bitPattern: SM64CameraWaterQuerySourceRecipe.areaIndex)) << 32),
            UInt64(cameraPositionBits.0) | (UInt64(cameraPositionBits.1) << 32),
            UInt64(cameraPositionBits.2) | (UInt64(marioPositionBits.0) << 32),
            UInt64(marioPositionBits.1) | (UInt64(marioPositionBits.2) << 32),
            UInt64(marioPositionBits.0) | (UInt64(marioPositionBits.2) << 32),
            UInt64(waterHeightBits),
            UInt64(resultFlags)
        ]
        return try SM64OracleTraceRecord(
            simulationTick: simulationTick,
            domain: Self.domain,
            recordKind: Self.recordKind,
            subjectID: Self.subjectID,
            recordID: Self.recordID,
            sequence: sequence,
            flags: Self.routeFlag,
            values: values
        )
    }
}

/// Swift-side ordering/decoding service.  Camera records may be interleaved
/// with other domain-5 records, so filtered route sequences need only advance
/// within a tick; the native sequence remains authoritative in each record.
final class SwiftCameraWaterQueryMigrationService {
    private(set) var mirror: [SM64CameraWaterQueryReceipt] = []
    private var lastTick: UInt64?
    private var lastSequence: UInt32 = 0

    func observe(native: SM64OracleTraceRecord) throws {
        let receipt = try SM64CameraWaterQueryReceipt(native: native)
        if let lastTick {
            guard receipt.record.simulationTick >= lastTick,
                  receipt.record.simulationTick != lastTick
                      || receipt.record.sequence > lastSequence else {
                throw SM64OracleTraceCodecError.invalidHeader
            }
        }
        mirror.append(receipt)
        lastTick = receipt.record.simulationTick
        lastSequence = receipt.record.sequence
    }

    var traceRecords: [SM64OracleTraceRecord] {
        mirror.map(\.record)
    }
}
