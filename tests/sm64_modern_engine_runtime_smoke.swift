import Foundation

typealias SM64ModernStatus = Int32
typealias SM64ModernExitReason = Int32

private final class CallbackRecorder {
    var initializeCalls = 0
    var stepCalls = 0
    var stopCalls = 0
    var shutdownCalls = 0
    var lastStopReason: SM64ModernExitReason?

    let initializeStatus: SM64ModernStatus
    let stepStatus: SM64ModernStatus
    let stopStatus: SM64ModernStatus
    let shutdownStatus: SM64ModernStatus

    init(
        initializeStatus: SM64ModernStatus,
        stepStatus: SM64ModernStatus,
        stopStatus: SM64ModernStatus,
        shutdownStatus: SM64ModernStatus
    ) {
        self.initializeStatus = initializeStatus
        self.stepStatus = stepStatus
        self.stopStatus = stopStatus
        self.shutdownStatus = shutdownStatus
    }

    var callbacks: SM64ModernEngineRuntimeCallbacks {
        SM64ModernEngineRuntimeCallbacks(
            initialize: {
                self.initializeCalls += 1
                return self.initializeStatus
            },
            step: {
                self.stepCalls += 1
                return self.stepStatus
            },
            requestStop: { reason in
                self.stopCalls += 1
                self.lastStopReason = reason
                return self.stopStatus
            },
            shutdown: {
                self.shutdownCalls += 1
                return self.shutdownStatus
            }
        )
    }
}

@main
enum SM64ModernEngineRuntimeSmoke {
    static func main() {
        let recorder = CallbackRecorder(
            initializeStatus: 11,
            stepStatus: 12,
            stopStatus: 13,
            shutdownStatus: 14
        )
        let cAdapter = SM64ModernCEngineRuntimeAdapter(callbacks: recorder.callbacks)
        precondition(cAdapter.authority == .cCompatibility)
        precondition(cAdapter.implementation == "c_compatibility")
        precondition(cAdapter.initialize() == 11)
        precondition(cAdapter.step() == 12)
        precondition(cAdapter.requestStop(reason: 99) == 13)
        precondition(cAdapter.shutdown() == 14)
        precondition(recorder.initializeCalls == 1)
        precondition(recorder.stepCalls == 1)
        precondition(recorder.stopCalls == 1)
        precondition(recorder.shutdownCalls == 1)
        precondition(recorder.lastStopReason == 99)

        let swiftRecorder = CallbackRecorder(
            initializeStatus: 0,
            stepStatus: 0,
            stopStatus: 8,
            shutdownStatus: 0
        )
        let swiftShell = SM64ModernSwiftEngineRuntime(
            cFallback: SM64ModernCEngineRuntimeAdapter(callbacks: swiftRecorder.callbacks)
        )
        precondition(swiftShell.authority == .swift)
        precondition(swiftShell.implementation == "swift_lifecycle_owner_c_domain_bridge")
        precondition(swiftShell.phase == .cold)
        precondition(swiftShell.step() == 4)
        precondition(swiftShell.initialize() == 0)
        precondition(swiftShell.phase == .initialized)
        precondition(swiftShell.initialize() == 4)
        precondition(swiftShell.swiftContext.domainReadiness.isSwiftOwned(.state))
        precondition(swiftShell.swiftContext.domainReadiness.isSwiftOwned(.objectScheduler))
        precondition(swiftShell.swiftContext.domainReadiness.isSwiftOwned(.progression))
        precondition(swiftShell.swiftContext.domainReadiness.isSwiftOwned(.input))
        precondition(swiftShell.swiftContext.domainReadiness.isSwiftOwned(.marioInput))
        precondition(!swiftShell.swiftContext.domainReadiness.isSwiftOwned(.audio))
        precondition(swiftShell.swiftContext.domainReadiness.cFallbackRequired.contains(.savePersistence))
        let heldInput = swiftShell.swiftContext.ingestInput(
            .init(buttons: 0x0001, rawStickX: 16, rawStickY: 0),
            advanceLegacyDomain: false
        )!
        precondition(heldInput.engineTick == 0)
        precondition(heldInput.controller.buttonDown == 0x0001)
        precondition(heldInput.controller.buttonPressed == 0)
        let edgeInput = swiftShell.swiftContext.ingestInput(
            .init(buttons: 0x0001, rawStickX: 16, rawStickY: 0),
            advanceLegacyDomain: true
        )!
        precondition(edgeInput.controller.buttonPressed == 0x0001)
        let marioInput = swiftShell.swiftContext.ingestInput(
            .init(buttons: 0x8000, rawStickX: 38),
            advanceLegacyDomain: true
        )!
        let marioReceipt = swiftShell.swiftContext.updateMarioInput(
            squishTimer: 0,
            faceYaw: 0x1111,
            cameraYaw: 0x0200
        )!
        precondition(marioReceipt.engineTick == 0)
        precondition(marioReceipt.controller == marioInput.controller)
        precondition(marioReceipt.mario.input.contains(.aPressed))
        precondition(marioReceipt.mario.intendedMagnitude == 8)
        precondition(marioReceipt.mario.intendedYaw == 0x4200)
        let progressionReceipt = swiftShell.swiftContext.applyProgression(
            .collectRedCoin, simulationTick: 0
        )!
        precondition(progressionReceipt.engineTick == 0)
        precondition(progressionReceipt.simulationTick == 0)
        precondition(progressionReceipt.eventID == .collectRedCoin)
        precondition(progressionReceipt.accepted)
        precondition(progressionReceipt.actorEffects.contains(.redCoin))
        precondition(swiftShell.swiftContext.progression.progression.coins == 2)
        let actor = try! swiftShell.swiftContext.state.spawnObject(
            in: .generalActor,
            behaviorIdentity: 0x44
        )
        precondition(swiftShell.swiftContext.state.objects.contains(actor))
        precondition(swiftShell.step() == 0)
        precondition(swiftShell.lastSwiftTick?.tick == 1)
        precondition(swiftShell.lastSwiftTick?.frame == 1)
        precondition(swiftShell.lastSwiftTick?.objectCount == 1)
        precondition(swiftShell.swiftContext.state.globals.frame == 1)
        precondition(swiftShell.requestStop(reason: 199) == 8)
        precondition(swiftShell.phase == .stopping)
        precondition(swiftShell.step() == 4)
        precondition(swiftShell.shutdown() == 0)
        precondition(swiftShell.phase == .stopped)
        precondition(swiftShell.swiftContext.phase == .stopped)
        precondition(swiftShell.swiftContext.lastProgressionReceipt == nil)
        precondition(swiftShell.swiftContext.lastInputReceipt == nil)
        precondition(swiftShell.swiftContext.lastMarioInputReceipt == nil)
        precondition(swiftShell.swiftContext.progression.progression.coins == 0)
        precondition(swiftShell.swiftContext.state.snapshot().objects.isEmpty)
        precondition(swiftShell.shutdown() == 4)
        precondition(swiftRecorder.initializeCalls == 1)
        precondition(swiftRecorder.stepCalls == 1)
        precondition(swiftRecorder.stopCalls == 1)
        precondition(swiftRecorder.shutdownCalls == 1)
        precondition(swiftRecorder.lastStopReason == 199)

        print("SM64 Modern engine runtime smoke passed")
    }
}
