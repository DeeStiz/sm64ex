import Foundation

@main
enum FixedStepSchedulerSmoke {
    static func main() {
        var failures = 0

        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                FileHandle.standardError.write(Data("\(message)\n".utf8))
                failures += 1
            }
        }

        var scheduler = RationalFixedStepScheduler(
            rateNumerator: 30,
            rateDenominator: 1,
            maxCatchUpSteps: 2
        )
        scheduler.start(atNanoseconds: 1_000_000_000)
        var plan = scheduler.plan(atNanoseconds: 1_000_000_000)
        expect(plan.dueSteps == 1, "start must admit one immediate step")
        expect(plan.droppedSteps == 0, "start must not drop a step")
        expect(plan.waitNanoseconds == 33_333_333, "30 Hz first deadline must retain rational phase")

        plan = scheduler.plan(atNanoseconds: 1_033_333_332)
        expect(plan.dueSteps == 0, "an early wake must not advance simulation")
        expect(plan.waitNanoseconds == 1, "an early wake must wait for the exact deadline")

        plan = scheduler.plan(atNanoseconds: 1_100_000_000)
        expect(plan.dueSteps == 2, "a late wake must use bounded catch-up")
        expect(plan.droppedSteps == 1, "debt beyond the catch-up bound must be explicit")
        expect(plan.waitNanoseconds == 33_333_333, "dropped debt must preserve rational phase")

        var paired = RationalFixedStepScheduler(
            rateNumerator: 60,
            rateDenominator: 1,
            maxCatchUpSteps: 2
        )
        paired.start(atNanoseconds: 0)
        _ = paired.plan(atNanoseconds: 0)
        var admitted: UInt32 = 0
        for deadline in [UInt64(16_666_666), 16_666_667, 33_333_333] {
            admitted += paired.plan(atNanoseconds: deadline).dueSteps
        }
        expect(admitted == 2, "two 60 Hz steps must span one exact 30 Hz paired boundary")

        if failures != 0 {
            exit(1)
        }
        print("SM64 Modern fixed-step scheduler smoke passed")
    }
}
