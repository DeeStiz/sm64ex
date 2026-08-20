import Foundation

enum SM64HiddenOneUpRole: UInt8, Equatable, Sendable {
    case hidden = 0
    case trigger = 1
    case hiddenInPole = 2
    case poleTrigger = 3
    case poleSpawner = 4
    case oneUp = 5
    case walking = 6
    case runningAway = 7
    case sliding = 8
    case jumpOnApproach = 9
}

struct SM64HiddenOneUpInput: Equatable, Sendable {
    let role: SM64HiddenOneUpRole
    let action: Int32
    let timer: Int32
    let behaviorByte: Int32
    let triggerCount: Int32
    let touchedMario: Bool
    let marioNear: Bool
    let outsideRange: Bool
    let pitch: Int32
    let forwardVelocity: Float
}

struct SM64HiddenOneUpOutput: Equatable, Sendable {
    let role: SM64HiddenOneUpRole
    let action: Int32
    let timer: Int32
    let triggerCount: Int32
    let visible: Bool
    let tangible: Bool
    let shouldDelete: Bool
    let pitch: Int32
    let forwardVelocity: Float
    let verticalVelocity: Float
    let spawnSparkle: Bool
    let playAppearSound: Bool
    let consumeTrigger: Bool
    let spawnPoleChildren: Bool
}

/// Value counterpart of the five `mushroom_1up.inc.c` hidden-one-up routes.
/// Pointer lookups, Mario lives, and object-list ownership remain owner-thread
/// effects; all branch/timer/motion decisions are fixed-width values here.
enum SM64HiddenOneUpBehavior {
    static func update(_ input: SM64HiddenOneUpInput) -> SM64HiddenOneUpOutput {
        switch input.role {
        case .trigger, .poleTrigger:
            return .init(
                role: input.role,
                action: input.action,
                timer: input.timer &+ 1,
                triggerCount: input.touchedMario ? input.triggerCount &+ 1 : input.triggerCount,
                visible: true,
                tangible: true,
                shouldDelete: input.touchedMario,
                pitch: input.pitch,
                forwardVelocity: input.forwardVelocity,
                verticalVelocity: 0,
                spawnSparkle: false,
                playAppearSound: false,
                consumeTrigger: input.touchedMario,
                spawnPoleChildren: false
            )

        case .poleSpawner:
            return .init(
                role: input.role,
                action: input.action,
                timer: input.timer &+ 1,
                triggerCount: input.triggerCount,
                visible: true,
                tangible: false,
                shouldDelete: input.marioNear,
                pitch: input.pitch,
                forwardVelocity: input.forwardVelocity,
                verticalVelocity: 0,
                spawnSparkle: false,
                playAppearSound: false,
                consumeTrigger: false,
                spawnPoleChildren: input.marioNear
            )

        case .oneUp:
            return .init(
                role: input.role,
                action: input.action,
                timer: input.timer &+ 1,
                triggerCount: input.triggerCount,
                visible: true,
                tangible: !input.touchedMario,
                shouldDelete: input.touchedMario,
                pitch: input.pitch,
                forwardVelocity: input.forwardVelocity,
                verticalVelocity: 0,
                spawnSparkle: false,
                playAppearSound: false,
                consumeTrigger: false,
                spawnPoleChildren: false
            )

        case .walking, .runningAway, .sliding, .jumpOnApproach:
            return updateRegularOneUp(input)

        case .hidden, .hiddenInPole:
            return updateOneUp(input)
        }
    }

    private static func updateRegularOneUp(_ input: SM64HiddenOneUpInput) -> SM64HiddenOneUpOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var visible = true
        var tangible = false
        var shouldDelete = false
        var pitch = input.pitch
        var forwardVelocity = input.forwardVelocity
        var verticalVelocity: Float = 0
        var spawnSparkle = false
        var playAppearSound = false

        switch input.role {
        case .sliding where input.action == 0:
            tangible = true
            if input.marioNear { action = 1; timer = 0 }

        case .jumpOnApproach where input.action == 0:
            tangible = true
            if input.marioNear {
                action = 1
                timer = 0
                verticalVelocity = 40
            }

        case .walking, .runningAway, .sliding, .jumpOnApproach:
            switch input.action {
            case 0:
                if input.timer == 0 { playAppearSound = true }
                verticalVelocity = input.timer < 5 ? 40 : verticalVelocity
                if input.timer >= 18 { spawnSparkle = true }
                if input.timer >= 5 {
                    pitch = input.pitch &- 0x1000
                    let phase = Float(Int16(truncatingIfNeeded: pitch)) * (Float.pi / 32768)
                    verticalVelocity = sin(phase) * 30 + 2
                    forwardVelocity = -sin(phase) * 30
                }
                if input.timer == 37 {
                    action = 1
                    timer = 0
                    tangible = true
                    forwardVelocity = input.role == .jumpOnApproach ? 8 : 2
                }

            case 1:
                tangible = true
                spawnSparkle = input.role != .walking
                forwardVelocity = input.role == .runningAway || input.role == .jumpOnApproach ? 8 : input.forwardVelocity
                if input.role != .walking && input.outsideRange {
                    action = 2
                    timer = 0
                    tangible = false
                }
                if input.role == .walking && input.timer > 300 {
                    action = 2
                    timer = 0
                    tangible = false
                }
                if input.touchedMario {
                    shouldDelete = true
                    tangible = false
                }

            case 2:
                tangible = false
                visible = input.timer < 30 && input.timer.isMultiple(of: 2)
                shouldDelete = input.timer >= 30

            default:
                action = 0
                timer = 0
                tangible = false
            }

        default:
            break
        }

        return .init(
            role: input.role,
            action: action,
            timer: timer,
            triggerCount: input.triggerCount,
            visible: visible,
            tangible: tangible,
            shouldDelete: shouldDelete,
            pitch: pitch,
            forwardVelocity: forwardVelocity,
            verticalVelocity: verticalVelocity,
            spawnSparkle: spawnSparkle,
            playAppearSound: playAppearSound,
            consumeTrigger: false,
            spawnPoleChildren: false
        )
    }

    private static func updateOneUp(_ input: SM64HiddenOneUpInput) -> SM64HiddenOneUpOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var visible = input.action != 0
        var tangible = input.action == 1
        var shouldDelete = false
        var pitch = input.pitch
        var forwardVelocity = input.forwardVelocity
        var verticalVelocity: Float = 0
        var spawnSparkle = false
        var playAppearSound = false

        switch input.action {
        case 0:
            visible = false
            tangible = false
            if input.triggerCount == input.behaviorByte {
                action = 3
                timer = 0
                visible = true
                playAppearSound = true
                verticalVelocity = 40
            }

        case 1:
            visible = true
            tangible = true
            if input.role == .hidden && (input.outsideRange || input.timer > 300) {
                action = 2
                timer = 0
                tangible = false
            }
            if input.touchedMario {
                shouldDelete = true
                tangible = false
            }
            forwardVelocity = input.role == .hiddenInPole ? 30 : 8

        case 2:
            tangible = false
            visible = input.timer < 30 && input.timer.isMultiple(of: 2)
            shouldDelete = input.timer >= 30

        case 3:
            visible = true
            if input.timer >= 18 { spawnSparkle = true }
            if input.timer < 5 {
                verticalVelocity = 40
            } else {
                pitch = input.pitch &- 0x1000
                let phase = Float(Int16(truncatingIfNeeded: pitch)) * (Float.pi / 32768)
                verticalVelocity = sin(phase) * 30 + 2
                forwardVelocity = -sin(phase) * 30
            }
            if input.timer == 37 {
                action = 1
                timer = 0
                tangible = true
                forwardVelocity = input.role == .hiddenInPole ? 10 : 8
            }

        default:
            action = 0
            timer = 0
            visible = false
            tangible = false
        }

        return .init(
            role: input.role,
            action: action,
            timer: timer,
            triggerCount: input.triggerCount,
            visible: visible,
            tangible: tangible,
            shouldDelete: shouldDelete,
            pitch: pitch,
            forwardVelocity: forwardVelocity,
            verticalVelocity: verticalVelocity,
            spawnSparkle: spawnSparkle,
            playAppearSound: playAppearSound,
            consumeTrigger: false,
            spawnPoleChildren: false
        )
    }
}
