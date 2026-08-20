import Foundation

/// Pure Swift 6 counterparts for the scalar operations that define the
/// legacy simulation contract.  These routines intentionally use explicit
/// wrapping and IEEE-754 bit conversions: a native Swift caller must not
/// inherit trapping integer arithmetic or platform-dependent serialization.
enum SM64DeterministicPrimitives {
    /// C-oracle Float operations kept out of fused multiply-add optimization.
    /// The legacy engine evaluates these as distinct `f32` expressions.
    @inline(never) static func cFloatMultiply(_ lhs: Float, _ rhs: Float) -> Float {
        let result = lhs * rhs
        return Float(bitPattern: result.bitPattern)
    }

    static func floatBits(_ value: Float) -> UInt32 {
        value.bitPattern
    }

    static func float(fromBits bits: UInt32) -> Float {
        Float(bitPattern: bits)
    }

    static func approachS32(
        current: Int32,
        target: Int32,
        increment: Int32,
        decrement: Int32
    ) -> Int32 {
        if current < target {
            let advanced = current &+ increment
            return advanced > target ? target : advanced
        }
        let retreated = current &- decrement
        return retreated < target ? target : retreated
    }

    static func approachFloat(
        current: Float,
        target: Float,
        increment: Float,
        decrement: Float
    ) -> Float {
        if current < target {
            let advanced = current + increment
            return advanced > target ? target : advanced
        }
        let retreated = current - decrement
        return retreated < target ? target : retreated
    }

    static func roundFloatToS16(_ value: Float) -> Int16 {
        let rounded = value >= 0 ? Double(value) + 0.5 : Double(value) - 0.5
        return Int16(truncatingIfNeeded: Int32(rounded))
    }
}

/// Table-backed trigonometry from the US C engine. Angles are the legacy
/// 16-bit circle (`0x10000 == 2π`); using the generated table is mandatory for
/// parity because platform libm implementations are not bit-identical.
enum SM64CanonicalTrig {
    static func sins(_ angle: Int16) -> Float {
        let index = Int(UInt16(bitPattern: angle) >> 4)
        return SM64CanonicalTrigTables.sine[index]
    }

    static func coss(_ angle: Int16) -> Float {
        let index = Int(UInt16(bitPattern: angle) >> 4)
        return SM64CanonicalTrigTables.cosine[index]
    }

    static func atan2s(y: Float, x: Float) -> Int16 {
        var y = y
        var x = x
        let result: UInt16

        if x >= 0 {
            if y >= 0 {
                if y >= x {
                    result = atan2Lookup(y: x, x: y)
                } else {
                    result = 0x4000 &- atan2Lookup(y: y, x: x)
                }
            } else {
                y = -y
                if y < x {
                    result = 0x4000 &+ atan2Lookup(y: y, x: x)
                } else {
                    result = 0x8000 &- atan2Lookup(y: x, x: y)
                }
            }
        } else {
            x = -x
            if y < 0 {
                y = -y
                if y >= x {
                    result = 0x8000 &+ atan2Lookup(y: x, x: y)
                } else {
                    result = 0xC000 &- atan2Lookup(y: y, x: x)
                }
            } else if y < x {
                result = 0xC000 &+ atan2Lookup(y: y, x: x)
            } else {
                result = 0 &- atan2Lookup(y: x, x: y)
            }
        }
        return Int16(bitPattern: result)
    }

    static func atan2f(y: Float, x: Float) -> Float {
        let angle = Int16(atan2s(y: y, x: x))
        return Float(Double(angle) * Double.pi / 32_768.0)
    }

    static func tableFingerprint() -> UInt64 {
        var hash = UInt64(1_469_598_103_934_665_603)
        for value in SM64CanonicalTrigTables.sine {
            hash = hashU32(hash, value.bitPattern)
        }
        for value in SM64CanonicalTrigTables.cosine {
            hash = hashU32(hash, value.bitPattern)
        }
        for value in SM64CanonicalTrigTables.arctangent {
            hash = hashU32(hash, UInt32(UInt16(bitPattern: value)))
        }
        return hash
    }

    private static func atan2Lookup(y: Float, x: Float) -> UInt16 {
        guard x != 0 else {
            return UInt16(bitPattern: SM64CanonicalTrigTables.arctangent[0])
        }
        let index = Int(y / x * 1_024.0 + 0.5)
        precondition(index >= 0 && index < SM64CanonicalTrigTables.arctangent.count)
        return UInt16(bitPattern: SM64CanonicalTrigTables.arctangent[index])
    }

    private static func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
        var hash = hash
        for byte in 0..<4 {
            hash ^= UInt64((value >> UInt32(byte * 8)) & 0xff)
            hash &*= 1_099_511_628_211
        }
        return hash
    }
}

struct SM64Fixed16_16: Equatable, Sendable {
    let rawValue: Int32

    init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    init(integer: Int32) {
        self.rawValue = integer &* 0x1_0000
    }

    init(float value: Float) {
        precondition(value.isFinite)
        let scaled = Double(value) * 65_536.0
        precondition(scaled >= Double(Int32.min) && scaled <= Double(Int32.max))
        self.rawValue = Int32(scaled)
    }

    var integerPart: Int32 {
        rawValue >> 16
    }

    var fractionPart: UInt16 {
        UInt16(truncatingIfNeeded: rawValue)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        Self(rawValue: lhs.rawValue &+ rhs.rawValue)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        Self(rawValue: lhs.rawValue &- rhs.rawValue)
    }

    static func multiply(_ lhs: Self, _ rhs: Self) -> Self {
        let product = Int64(lhs.rawValue) * Int64(rhs.rawValue)
        return Self(rawValue: Int32(truncatingIfNeeded: product >> 16))
    }
}

struct SM64Random16: Equatable, Sendable {
    private(set) var seed: UInt16

    init(seed: UInt16) {
        self.seed = seed
    }

    mutating func next() -> UInt16 {
        if seed == 22_026 {
            seed = 0
        }

        var temp1 = ((seed & 0x00ff) << 8) ^ seed
        seed = ((temp1 & 0x00ff) << 8) &+ ((temp1 & 0xff00) >> 8)
        temp1 = (((temp1 & 0x00ff) << 1) ^ seed)
        let temp2 = (temp1 >> 1) ^ 0xff80

        if (temp1 & 1) == 0 {
            seed = temp2 == 43_605 ? 0 : temp2 ^ 0x1ff4
        } else {
            seed = temp2 ^ 0x8180
        }
        return seed
    }

    mutating func nextFloatBits() -> UInt32 {
        let raw = next()
        let value = Float(Double(raw) / 65_536.0)
        return value.bitPattern
    }

    mutating func nextSign() -> Int32 {
        next() >= 0x7fff ? 1 : -1
    }
}

enum SM64TimebaseConfigurationError: Error, Equatable {
    case lifecycleActive
    case invalidConfiguration
    case unsupportedRatio
}

struct SM64LegacyTimebase: Equatable, Sendable {
    struct Configuration: Equatable, Sendable {
        let simulationRateNumerator: UInt32
        let simulationRateDenominator: UInt32
        let legacyRateNumerator: UInt32
        let legacyRateDenominator: UInt32
        let maxCatchUpSteps: UInt32
    }

    static let rateLimit: UInt32 = 1_000
    static let maxCatchUpLimit: UInt32 = 8

    private(set) var configuration: Configuration
    private(set) var simulationTicksPerLegacyTick: UInt32
    private(set) var simulationTick: UInt64 = 0
    private(set) var legacyTick: UInt64 = 0
    private(set) var pairPhase: UInt32 = 0
    private(set) var legacyBoundary = false
    private var lifecycleActive = false
    private var simulationStepStarted = false

    init(
        simulationRateNumerator: UInt32 = 30,
        simulationRateDenominator: UInt32 = 1,
        legacyRateNumerator: UInt32 = 30,
        legacyRateDenominator: UInt32 = 1,
        maxCatchUpSteps: UInt32 = 2
    ) throws {
        let normalized = try Self.normalizedConfiguration(
            simulationRateNumerator: simulationRateNumerator,
            simulationRateDenominator: simulationRateDenominator,
            legacyRateNumerator: legacyRateNumerator,
            legacyRateDenominator: legacyRateDenominator,
            maxCatchUpSteps: maxCatchUpSteps
        )
        self.configuration = normalized.configuration
        self.simulationTicksPerLegacyTick = normalized.ratio
    }

    mutating func configure(
        simulationRateNumerator: UInt32,
        simulationRateDenominator: UInt32,
        legacyRateNumerator: UInt32,
        legacyRateDenominator: UInt32,
        maxCatchUpSteps: UInt32
    ) throws {
        guard !lifecycleActive else { throw SM64TimebaseConfigurationError.lifecycleActive }
        let normalized = try Self.normalizedConfiguration(
            simulationRateNumerator: simulationRateNumerator,
            simulationRateDenominator: simulationRateDenominator,
            legacyRateNumerator: legacyRateNumerator,
            legacyRateDenominator: legacyRateDenominator,
            maxCatchUpSteps: maxCatchUpSteps
        )
        configuration = normalized.configuration
        simulationTicksPerLegacyTick = normalized.ratio
    }

    mutating func setLifecycleActive(_ active: Bool) {
        simulationTick = 0
        legacyTick = 0
        pairPhase = 0
        legacyBoundary = false
        simulationStepStarted = false
        lifecycleActive = active
    }

    var isLifecycleActive: Bool { lifecycleActive }

    mutating func beginSimulationStep() {
        guard lifecycleActive else {
            legacyBoundary = true
            return
        }

        simulationTick &+= 1
        simulationStepStarted = true
        if simulationTicksPerLegacyTick <= 1 {
            pairPhase = 0
            legacyBoundary = true
            legacyTick &+= 1
            return
        }

        if pairPhase == 0 {
            pairPhase = 1
            legacyBoundary = true
            legacyTick &+= 1
        } else if pairPhase >= simulationTicksPerLegacyTick - 1 {
            pairPhase = 0
            legacyBoundary = false
        } else {
            pairPhase &+= 1
            legacyBoundary = false
        }
    }

    var shouldAdvanceLegacyDomain: Bool {
        !lifecycleActive
            || simulationTicksPerLegacyTick <= 1
            || (simulationStepStarted && legacyBoundary)
    }

    var shouldAdvanceNativeDynamics: Bool {
        !lifecycleActive
            || simulationTicksPerLegacyTick <= 1
            || simulationStepStarted
    }

    var nativeStepScale: Float {
        if !lifecycleActive || simulationTicksPerLegacyTick <= 1 {
            return 1
        }
        return 1 / Float(simulationTicksPerLegacyTick)
    }

    var isLegacyIntervalFinalStep: Bool {
        if !lifecycleActive || simulationTicksPerLegacyTick <= 1 {
            return true
        }
        if !simulationStepStarted {
            return false
        }
        return !legacyBoundary && pairPhase == 0
    }

    private static func normalizedConfiguration(
        simulationRateNumerator: UInt32,
        simulationRateDenominator: UInt32,
        legacyRateNumerator: UInt32,
        legacyRateDenominator: UInt32,
        maxCatchUpSteps: UInt32
    ) throws -> (configuration: Configuration, ratio: UInt32) {
        guard simulationRateNumerator > 0,
              simulationRateDenominator > 0,
              legacyRateNumerator > 0,
              legacyRateDenominator > 0,
              simulationRateNumerator <= rateLimit,
              simulationRateDenominator <= rateLimit,
              legacyRateNumerator <= rateLimit,
              legacyRateDenominator <= rateLimit,
              maxCatchUpSteps > 0,
              maxCatchUpSteps <= maxCatchUpLimit else {
            throw SM64TimebaseConfigurationError.invalidConfiguration
        }

        let simulationDivisor = gcd(simulationRateNumerator, simulationRateDenominator)
        let legacyDivisor = gcd(legacyRateNumerator, legacyRateDenominator)
        let simulationNumerator = simulationRateNumerator / simulationDivisor
        let simulationDenominator = simulationRateDenominator / simulationDivisor
        let legacyNumerator = legacyRateNumerator / legacyDivisor
        let legacyDenominator = legacyRateDenominator / legacyDivisor
        let ratioNumerator = UInt64(simulationNumerator) * UInt64(legacyDenominator)
        let ratioDenominator = UInt64(simulationDenominator) * UInt64(legacyNumerator)

        guard ratioNumerator >= ratioDenominator,
              ratioNumerator % ratioDenominator == 0 else {
            throw SM64TimebaseConfigurationError.unsupportedRatio
        }
        let ratio = ratioNumerator / ratioDenominator
        guard ratio <= UInt64(UInt32.max) else {
            throw SM64TimebaseConfigurationError.unsupportedRatio
        }
        return (
            Configuration(
                simulationRateNumerator: simulationNumerator,
                simulationRateDenominator: simulationDenominator,
                legacyRateNumerator: legacyNumerator,
                legacyRateDenominator: legacyDenominator,
                maxCatchUpSteps: maxCatchUpSteps
            ),
            UInt32(ratio)
        )
    }

    private static func gcd(_ left: UInt32, _ right: UInt32) -> UInt32 {
        var left = left
        var right = right
        while right != 0 {
            let remainder = left % right
            left = right
            right = remainder
        }
        return left
    }
}

struct SM64AnimationClock: Equatable, Sendable {
    let frameCount: UInt16
    let fixedStep: UInt32
    private(set) var integerFrame: UInt16 = 0
    private(set) var fixedPosition: UInt32 = 0

    init(frameCount: UInt16, fixedStep: UInt32 = 0x1_0000) {
        precondition(frameCount > 0)
        self.frameCount = frameCount
        self.fixedStep = fixedStep
    }

    mutating func advance() -> (integerFrame: UInt16, fixedPosition: UInt32, crossedFrame: Bool) {
        let oldIntegerFrame = integerFrame
        integerFrame = integerFrame &+ 1
        if integerFrame >= frameCount {
            integerFrame = 0
        }
        let oldFixedFrame = fixedPosition >> 16
        fixedPosition &+= fixedStep
        let newFixedFrame = fixedPosition >> 16
        return (
            integerFrame: integerFrame,
            fixedPosition: fixedPosition,
            crossedFrame: integerFrame != oldIntegerFrame || newFixedFrame != oldFixedFrame
        )
    }
}
