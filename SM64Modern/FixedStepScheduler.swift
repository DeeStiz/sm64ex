import Darwin
import Foundation

struct FixedStepPlan: Equatable {
    let dueSteps: UInt32
    let droppedSteps: UInt64
    let latenessNanoseconds: UInt64
    let waitNanoseconds: UInt64
}

enum MonotonicClock {
    static func nowNanoseconds() -> UInt64 {
        clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
    }
}

// The deadline series is exact rational arithmetic. Wakes may be early, late,
// or coalesced, but every admitted simulation step advances by the same fixed
// period and all excess debt is explicitly counted instead of spiraling.
struct RationalFixedStepScheduler {
    private let periodWholeNanoseconds: UInt64
    private let periodRemainder: UInt64
    private let periodDenominator: UInt64
    private let maxCatchUpSteps: UInt32
    private var nextDeadlineNanoseconds: UInt64?
    private var fractionalRemainder: UInt64 = 0

    init(rateNumerator: UInt32, rateDenominator: UInt32, maxCatchUpSteps: UInt32) {
        precondition(rateNumerator > 0 && rateDenominator > 0)
        precondition(maxCatchUpSteps > 0)
        let periodNumerator = UInt64(rateDenominator) * 1_000_000_000
        let denominator = UInt64(rateNumerator)
        periodWholeNanoseconds = periodNumerator / denominator
        periodRemainder = periodNumerator % denominator
        periodDenominator = denominator
        self.maxCatchUpSteps = maxCatchUpSteps
        precondition(periodWholeNanoseconds > 0)
    }

    mutating func start(atNanoseconds now: UInt64) {
        precondition(nextDeadlineNanoseconds == nil)
        nextDeadlineNanoseconds = now
        fractionalRemainder = 0
    }

    mutating func plan(atNanoseconds now: UInt64) -> FixedStepPlan {
        guard let firstDeadline = nextDeadlineNanoseconds else {
            preconditionFailure("The fixed-step scheduler must be started before planning")
        }
        if now < firstDeadline {
            return FixedStepPlan(
                dueSteps: 0,
                droppedSteps: 0,
                latenessNanoseconds: 0,
                waitNanoseconds: firstDeadline - now
            )
        }

        var dueSteps: UInt32 = 0
        while dueSteps < maxCatchUpSteps,
              let deadline = nextDeadlineNanoseconds,
              deadline <= now {
            dueSteps += 1
            advanceDeadlines(by: 1)
        }

        var droppedSteps: UInt64 = 0
        while let deadline = nextDeadlineNanoseconds, deadline <= now {
            let delta = now - deadline
            let ceilingPeriod = periodWholeNanoseconds + (periodRemainder == 0 ? 0 : 1)
            let count = max(UInt64(1), delta / ceilingPeriod + 1)
            advanceDeadlines(by: count)
            droppedSteps += count
        }

        let nextDeadline = nextDeadlineNanoseconds!
        return FixedStepPlan(
            dueSteps: dueSteps,
            droppedSteps: droppedSteps,
            latenessNanoseconds: now - firstDeadline,
            waitNanoseconds: nextDeadline - now
        )
    }

    private mutating func advanceDeadlines(by count: UInt64) {
        guard let deadline = nextDeadlineNanoseconds else {
            preconditionFailure("The fixed-step scheduler must be started before advancing")
        }
        let wholeAdvance = periodWholeNanoseconds.multipliedReportingOverflow(by: count)
        precondition(!wholeAdvance.overflow, "Fixed-step whole deadline overflow")
        let fractionalAdvance = periodRemainder.multipliedReportingOverflow(by: count)
        precondition(!fractionalAdvance.overflow, "Fixed-step fractional deadline overflow")
        let combinedRemainder = fractionalRemainder.addingReportingOverflow(fractionalAdvance.partialValue)
        precondition(!combinedRemainder.overflow, "Fixed-step remainder overflow")
        let carry = combinedRemainder.partialValue / periodDenominator
        fractionalRemainder = combinedRemainder.partialValue % periodDenominator
        let withWhole = deadline.addingReportingOverflow(wholeAdvance.partialValue)
        precondition(!withWhole.overflow, "Fixed-step deadline overflow")
        let withCarry = withWhole.partialValue.addingReportingOverflow(carry)
        precondition(!withCarry.overflow, "Fixed-step deadline carry overflow")
        nextDeadlineNanoseconds = withCarry.partialValue
    }
}
