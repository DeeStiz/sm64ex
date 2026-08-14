import Foundation

@main
enum DeterministicPrimitivesSmoke {
    static func main() {
        var failures = 0

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                FileHandle.standardError.write(Data("\(message)\n".utf8))
                failures += 1
            }
        }

        var random = SM64Random16(seed: 0x1234)
        let expected: [UInt16] = [0xfa53, 0x5787, 0xa31b, 0xedb3, 0xb968, 0x4a00, 0xe051, 0x5689]
        for value in expected {
            expect(random.next() == value, "RNG sequence diverged at \(String(value, radix: 16))")
        }
        var floatRandom = SM64Random16(seed: 0x1234)
        expect(floatRandom.nextFloatBits() == 0x3f7a5300, "RNG float bits must match C")
        var signRandom = SM64Random16(seed: 1)
        expect(signRandom.nextSign() == -1, "RNG sign threshold must match C")

        expect(
            SM64DeterministicPrimitives.approachS32(
                current: 10, target: 20, increment: 3, decrement: 4
            ) == 13,
            "s32 approach increment"
        )
        expect(
            SM64DeterministicPrimitives.approachS32(
                current: 20, target: 10, increment: 3, decrement: 4
            ) == 16,
            "s32 approach decrement"
        )
        expect(
            SM64DeterministicPrimitives.approachFloat(
                current: 19, target: 20, increment: 3, decrement: 4
            ) == 20,
            "float approach clamp"
        )
        expect(SM64DeterministicPrimitives.roundFloatToS16(2.49) == 2, "positive round")
        expect(SM64DeterministicPrimitives.roundFloatToS16(-2.49) == -2, "negative round")

        let oneAndHalf = SM64Fixed16_16(float: 1.5)
        let two = SM64Fixed16_16(integer: 2)
        expect(oneAndHalf.rawValue == 0x18000, "fixed conversion")
        expect(SM64Fixed16_16.multiply(oneAndHalf, two).rawValue == 0x30000, "fixed multiply")
        expect((oneAndHalf + two).integerPart == 3, "fixed add integer part")

        var timebase = try! SM64LegacyTimebase(
            simulationRateNumerator: 60,
            simulationRateDenominator: 1,
            legacyRateNumerator: 30,
            legacyRateDenominator: 1,
            maxCatchUpSteps: 2
        )
        expect(timebase.simulationTicksPerLegacyTick == 2, "paired ratio")
        timebase.setLifecycleActive(true)
        expect(!timebase.shouldAdvanceLegacyDomain, "paired pre-step legacy gate")
        timebase.beginSimulationStep()
        expect(timebase.simulationTick == 1 && timebase.legacyTick == 1, "paired first step ticks")
        expect(timebase.legacyBoundary && !timebase.isLegacyIntervalFinalStep, "paired first boundary")
        timebase.beginSimulationStep()
        expect(timebase.simulationTick == 2 && timebase.legacyTick == 1, "paired held step ticks")
        expect(!timebase.legacyBoundary && timebase.isLegacyIntervalFinalStep, "paired final redraw")
        expect(timebase.nativeStepScale == 0.5, "native step scale")
        do {
            _ = try SM64LegacyTimebase(
                simulationRateNumerator: 30,
                simulationRateDenominator: 1,
                legacyRateNumerator: 60,
                legacyRateDenominator: 1,
                maxCatchUpSteps: 2
            )
            expect(false, "unsupported slower legacy ratio must fail")
        } catch SM64TimebaseConfigurationError.unsupportedRatio {
            // Expected: the native scheduler only admits integral paired rates.
        } catch {
            expect(false, "unsupported ratio returned the wrong error")
        }

        var animation = SM64AnimationClock(frameCount: 7)
        let firstFrame = animation.advance()
        expect(firstFrame.integerFrame == 1 && firstFrame.crossedFrame, "integer animation frame")
        for _ in 0..<6 { _ = animation.advance() }
        expect(animation.integerFrame == 0, "integer animation wrap")
        expect(animation.fixedPosition == 0x70000, "fixed animation position")

        if failures != 0 {
            exit(1)
        }
        print("SM64 Modern deterministic primitives smoke passed")
    }
}
