import Foundation

struct SM64SLWalkingPenguinInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let currentStep: Int32
    let currentStepTimer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int16
}

struct SM64SLWalkingPenguinOutput: Equatable, Sendable {
    let action: Int32
    let currentStep: Int32
    let currentStepTimer: Int32
    let forwardVelocity: Float
    let animation: Int32
    let animationSpeed: Float
    let angleVelocityYaw: Int16
    let moveYaw: Int16
    let nextPosition: SM64ObjectVector3
    let completedTurn: Bool
}

/// Value counterpart of bhv_sl_walking_penguin_loop.
///
/// The collision-aware cur_obj_move_standard(-78) caller remains outside
/// this kernel; the output includes its canonical forward X/Z displacement so
/// the owner thread can apply floor/wall resolution without sharing a C object.
enum SM64SLWalkingPenguinBehavior {
    static let movingForwards: Int32 = 0
    static let turningBack: Int32 = 1
    static let returning: Int32 = 2
    static let turningForwards: Int32 = 3
    static let walkAnimation: Int32 = 1
    static let idleAnimation: Int32 = 0

    private struct Step {
        let length: Int32
        let animation: Int32
        let speed: Float
        let animationSpeed: Float
    }

    private static let steps: [Step] = [
        Step(length: 60, animation: walkAnimation, speed: 6, animationSpeed: 1),
        Step(length: 30, animation: idleAnimation, speed: 0, animationSpeed: 1),
        Step(length: 30, animation: walkAnimation, speed: 12, animationSpeed: 2),
        Step(length: 30, animation: idleAnimation, speed: 0, animationSpeed: 1),
        Step(length: 30, animation: walkAnimation, speed: -6, animationSpeed: 1),
    ]

    static func update(_ input: SM64SLWalkingPenguinInput) -> SM64SLWalkingPenguinOutput {
        var action = input.action
        var currentStep = input.currentStep
        var currentStepTimer = input.currentStepTimer
        var forwardVelocity: Float = 0
        var animation = idleAnimation
        var animationSpeed: Float = 1
        var angleVelocityYaw: Int16 = 0
        var moveYaw = input.moveYaw
        var completedTurn = false

        switch input.action {
        case movingForwards:
            if input.timer == 0 {
                currentStep = 0
                currentStepTimer = 0
            }
            let step = steps[Int(currentStep)]
            if currentStepTimer < step.length {
                currentStepTimer += 1
            } else {
                currentStepTimer = 0
                currentStep += 1
                if currentStep >= Int32(steps.count) {
                    currentStep = 0
                }
            }
            if input.position.x < 300 {
                action += 1
            } else {
                let current = steps[Int(currentStep)]
                forwardVelocity = current.speed
                animation = current.animation
                animationSpeed = current.animationSpeed
            }
        case turningBack, turningForwards:
            animation = walkAnimation
            animationSpeed = 1
            angleVelocityYaw = 0x400
            moveYaw = Int16(
                bitPattern: UInt16(bitPattern: moveYaw)
                    &+ UInt16(bitPattern: angleVelocityYaw)
            )
            completedTurn = input.timer == 31
            if completedTurn {
                action = input.action == turningBack ? returning : movingForwards
            }
        case returning:
            forwardVelocity = 12
            animation = walkAnimation
            animationSpeed = 2
            if input.position.x > 1700 {
                action += 1
            }
        default:
            break
        }

        let deltaX = SM64CanonicalTrig.sins(moveYaw) * forwardVelocity
        let deltaZ = SM64CanonicalTrig.coss(moveYaw) * forwardVelocity
        return SM64SLWalkingPenguinOutput(
            action: action,
            currentStep: currentStep,
            currentStepTimer: currentStepTimer,
            forwardVelocity: forwardVelocity,
            animation: animation,
            animationSpeed: animationSpeed,
            angleVelocityYaw: angleVelocityYaw,
            moveYaw: moveYaw,
            nextPosition: SM64ObjectVector3(
                x: input.position.x + deltaX,
                y: input.position.y,
                z: input.position.z + deltaZ
            ),
            completedTurn: completedTurn
        )
    }
}
