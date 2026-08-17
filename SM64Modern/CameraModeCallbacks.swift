import Foundation

/// The callback table in camera.c is an ABI-facing dispatch table.  Keeping
/// its mode number and callback kind in a value-only descriptor lets the Swift
/// owner thread select a mode without passing C function pointers or mutable
/// camera globals across the boundary.
enum SM64CameraCallbackKind: UInt8, Equatable, Sendable {
    case none = 0
    case radial = 1
    case outwardRadial = 2
    case behindMario = 3
    case mario = 4
    case cUp = 5
    case waterSurface = 6
    case slideHoot = 7
    case insideCannon = 8
    case bossFight = 9
    case parallelTracking = 10
    case fixed = 11
    case eightDirections = 12
    case spiralStairs = 13
}

struct SM64CameraModeCallbackDescriptor: Equatable, Sendable {
    let rawMode: Int16
    let callback: SM64CameraCallbackKind
    let pureGeometryImplemented: Bool
    let ownerThreadRequired: Bool
    let outputsSwapped: Bool
    let baseDistance: Float
    let positionYOffset: Float
    let focusYOffset: Float
    let basePitch: Int16
    let returnsMarioYaw: Bool
    let pansAhead: Bool
}

struct SM64CameraCallbackInput: Equatable, Sendable {
    let mode: Int16
    let marioPosition: SM64ObjectVector3
    let areaCenter: SM64ObjectVector3
    let cameraPosition: SM64ObjectVector3
    let cameraFocus: SM64ObjectVector3
    let cameraDistance: Float
    let cameraPitch: Int16
    let cameraYaw: Int16
    let faceYaw: Int16
    let facePitch: Int16
    let modeOffsetYaw: Int16
    let lakituPitch: Int16
    let lakituDistance: Float
    let zoomDistance: Float?
    let eightDirectionBaseYaw: Int16
    let eightDirectionYawOffset: Int16
    let cannonYOffset: Float
    let cButtonsPressed: UInt16
    let sideButtonYaw: Int16
    let behindMarioSoundTimer: Int16
    let marioModeActive: Bool
    let waterOrMetalAction: Bool
    let fixedBasePosition: SM64ObjectVector3
    let fixedScaleToMario: Float
    let fixedHeightOffset: Float
    let fixedFloorHeight: Float?
    let fixedCeilingHeight: Float?
    let fixedGoalHeight: Float
    let fixedFocusFloorOffset: Float
    let fixedSmoothMovement: Bool
    let bossSecondFocus: SM64ObjectVector3
    let bossFocusDistance: Float
    let bossAngleVelocity: Float
    let bossYaw: Int16
    let bossHeldState: Int16
    let bossFloorHeight: Float?
    let bossForceHeight: Bool
    let spiralBasePosition: SM64ObjectVector3
    let spiralFocusFloorOffset: Float
    let spiralFloorHeight: Float?
    let spiralCurrentFloorHeight: Float
    let parallelPathStart: SM64ObjectVector3
    let parallelPathEnd: SM64ObjectVector3
    let parallelDistanceThreshold: Float
    let parallelZoom: Float
    let parallelMarioFloorOffset: Float
    let parallelTransitionOffset: SM64ObjectVector3
    let parallelReady: Bool
    let height: SM64CameraHeightInput?
    let slope: SM64CameraSlopeInput?

    init(
        mode: Int16,
        marioPosition: SM64ObjectVector3,
        areaCenter: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
        cameraPosition: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
        cameraFocus: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
        cameraDistance: Float = 0,
        cameraPitch: Int16 = 0,
        cameraYaw: Int16 = 0,
        faceYaw: Int16 = 0,
        facePitch: Int16 = 0,
        modeOffsetYaw: Int16 = 0,
        lakituPitch: Int16 = 0,
        lakituDistance: Float = 0,
        zoomDistance: Float? = nil,
        eightDirectionBaseYaw: Int16 = 0,
        eightDirectionYawOffset: Int16 = 0,
        cannonYOffset: Float = 0,
        cButtonsPressed: UInt16 = 0,
        sideButtonYaw: Int16 = 0,
        behindMarioSoundTimer: Int16 = 0,
        marioModeActive: Bool = false,
        waterOrMetalAction: Bool = false,
        fixedBasePosition: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
        fixedScaleToMario: Float = 0,
        fixedHeightOffset: Float = 0,
        fixedFloorHeight: Float? = nil,
        fixedCeilingHeight: Float? = nil,
        fixedGoalHeight: Float = 0,
        fixedFocusFloorOffset: Float = 0,
        fixedSmoothMovement: Bool = false,
        bossSecondFocus: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
        bossFocusDistance: Float = 0,
        bossAngleVelocity: Float = 0,
        bossYaw: Int16 = 0,
        bossHeldState: Int16 = 0,
        bossFloorHeight: Float? = nil,
        bossForceHeight: Bool = false,
        spiralBasePosition: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
        spiralFocusFloorOffset: Float = 0,
        spiralFloorHeight: Float? = nil,
        spiralCurrentFloorHeight: Float = 0,
        parallelPathStart: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
        parallelPathEnd: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
        parallelDistanceThreshold: Float = 0,
        parallelZoom: Float = 0,
        parallelMarioFloorOffset: Float = 0,
        parallelTransitionOffset: SM64ObjectVector3 = SM64ObjectVector3(x: 0, y: 0, z: 0),
        parallelReady: Bool = false,
        height: SM64CameraHeightInput? = nil,
        slope: SM64CameraSlopeInput? = nil
    ) {
        self.mode = mode
        self.marioPosition = marioPosition
        self.areaCenter = areaCenter
        self.cameraPosition = cameraPosition
        self.cameraFocus = cameraFocus
        self.cameraDistance = cameraDistance
        self.cameraPitch = cameraPitch
        self.cameraYaw = cameraYaw
        self.faceYaw = faceYaw
        self.facePitch = facePitch
        self.modeOffsetYaw = modeOffsetYaw
        self.lakituPitch = lakituPitch
        self.lakituDistance = lakituDistance
        self.zoomDistance = zoomDistance
        self.eightDirectionBaseYaw = eightDirectionBaseYaw
        self.eightDirectionYawOffset = eightDirectionYawOffset
        self.cannonYOffset = cannonYOffset
        self.cButtonsPressed = cButtonsPressed
        self.sideButtonYaw = sideButtonYaw
        self.behindMarioSoundTimer = behindMarioSoundTimer
        self.marioModeActive = marioModeActive
        self.waterOrMetalAction = waterOrMetalAction
        self.fixedBasePosition = fixedBasePosition
        self.fixedScaleToMario = fixedScaleToMario
        self.fixedHeightOffset = fixedHeightOffset
        self.fixedFloorHeight = fixedFloorHeight
        self.fixedCeilingHeight = fixedCeilingHeight
        self.fixedGoalHeight = fixedGoalHeight
        self.fixedFocusFloorOffset = fixedFocusFloorOffset
        self.fixedSmoothMovement = fixedSmoothMovement
        self.bossSecondFocus = bossSecondFocus
        self.bossFocusDistance = bossFocusDistance
        self.bossAngleVelocity = bossAngleVelocity
        self.bossYaw = bossYaw
        self.bossHeldState = bossHeldState
        self.bossFloorHeight = bossFloorHeight
        self.bossForceHeight = bossForceHeight
        self.spiralBasePosition = spiralBasePosition
        self.spiralFocusFloorOffset = spiralFocusFloorOffset
        self.spiralFloorHeight = spiralFloorHeight
        self.spiralCurrentFloorHeight = spiralCurrentFloorHeight
        self.parallelPathStart = parallelPathStart
        self.parallelPathEnd = parallelPathEnd
        self.parallelDistanceThreshold = parallelDistanceThreshold
        self.parallelZoom = parallelZoom
        self.parallelMarioFloorOffset = parallelMarioFloorOffset
        self.parallelTransitionOffset = parallelTransitionOffset
        self.parallelReady = parallelReady
        self.height = height
        self.slope = slope
    }
}

struct SM64CameraCallbackResult: Equatable, Sendable {
    /// Semantic camera outputs.  `outputsSwapped` tells the owner adapter to
    /// reproduce update_in_cannon's legacy pointer order when it installs them.
    let focus: SM64ObjectVector3
    let position: SM64ObjectVector3
    let cameraYaw: Int16
    let returnedYaw: Int16
    let areaYaw: Int16
    let pitch: Int16
    let distance: Float
    let outputsSwapped: Bool
    let panAhead: Bool
    let sideButtonYaw: Int16
    let behindMarioSoundTimer: Int16
}

/// Bounded-mode callback descriptors plus the callbacks whose C bodies are
/// already reducible to immutable geometry. Water
/// callbacks deliberately return nil until their owner-thread path data and
/// collision policy have their own Swift boundaries.
enum SM64CameraModeCallbacks {
    static let descriptors: [SM64CameraModeCallbackDescriptor] = [
        descriptor(0, .none, false, false, false, 0, 0, 0, 0, false, false),
        descriptor(1, .radial, true, true, false, 1000, 125, 125, 0x05B0, false, true),
        descriptor(2, .outwardRadial, true, true, false, 1000, 125, 125, 0x05B0, false, true),
        descriptor(3, .behindMario, true, true, false, 800, 125, 125, 0x05B0, false, true),
        descriptor(4, .mario, true, true, false, 800, 125, 125, 0x05B0, true, true),
        descriptor(5, .none, false, false, false, 0, 0, 0, 0, false, false),
        descriptor(6, .cUp, true, true, false, 250, 125, 125, 0, true, false),
        descriptor(7, .mario, true, true, false, 800, 125, 125, 0x05B0, true, true),
        descriptor(8, .waterSurface, false, true, false, 800, 125, 125, 0x05B0, false, true),
        descriptor(9, .slideHoot, true, true, false, 800, 125, 125, 0x1555, true, false),
        descriptor(10, .insideCannon, true, true, true, 800, 125, 125, 0, true, false),
        descriptor(11, .bossFight, true, true, false, 0, 0, 0, 0, false, false),
        descriptor(12, .parallelTracking, true, true, false, 0, 0, 0, 0, false, false),
        descriptor(13, .fixed, true, true, false, 0, 0, 0, 0, false, false),
        descriptor(14, .eightDirections, true, true, false, 1000, 125, 125, 0x05B0, false, true),
        descriptor(15, .slideHoot, true, true, false, 800, 125, 125, 0x1555, true, false),
        descriptor(16, .mario, true, true, false, 800, 125, 125, 0x05B0, true, true),
        descriptor(17, .spiralStairs, true, true, false, 0, 0, 0, 0, false, false),
        descriptor(18, .none, false, false, false, 0, 0, 0, 0, false, false)
    ]

    static func descriptor(for rawMode: Int16) -> SM64CameraModeCallbackDescriptor? {
        descriptors.first { $0.rawMode == rawMode }
    }

    static func evaluate(
        _ input: SM64CameraCallbackInput
    ) -> SM64CameraCallbackResult? {
        guard let descriptor = descriptor(for: input.mode),
              descriptor.pureGeometryImplemented,
              finite(input.marioPosition), finite(input.areaCenter),
              input.lakituDistance.isFinite,
              input.zoomDistance?.isFinite ?? true,
              input.cannonYOffset.isFinite,
              finite(input.fixedBasePosition),
              input.fixedScaleToMario.isFinite,
              input.fixedHeightOffset.isFinite,
              input.fixedFloorHeight?.isFinite ?? true,
              input.fixedCeilingHeight?.isFinite ?? true,
              input.fixedGoalHeight.isFinite,
              input.fixedFocusFloorOffset.isFinite,
              finite(input.bossSecondFocus),
              input.bossFocusDistance.isFinite,
              input.bossAngleVelocity.isFinite,
              input.bossFloorHeight?.isFinite ?? true,
              finite(input.spiralBasePosition),
              input.spiralFocusFloorOffset.isFinite,
              input.spiralFloorHeight?.isFinite ?? true,
              input.spiralCurrentFloorHeight.isFinite,
              finite(input.parallelPathStart),
              finite(input.parallelPathEnd),
              input.parallelDistanceThreshold.isFinite,
              input.parallelZoom.isFinite,
              input.parallelMarioFloorOffset.isFinite,
              finite(input.parallelTransitionOffset) else { return nil }

        switch descriptor.callback {
        case .radial:
            return radial(input, descriptor: descriptor)
        case .outwardRadial:
            return outwardRadial(input, descriptor: descriptor)
        case .eightDirections:
            return eightDirections(input, descriptor: descriptor)
        case .mario:
            return mario(input, descriptor: descriptor)
        case .slideHoot:
            return slideHoot(input, descriptor: descriptor)
        case .insideCannon:
            return cannon(input, descriptor: descriptor)
        case .cUp:
            return cUp(input, descriptor: descriptor)
        case .behindMario:
            return behindMario(input, descriptor: descriptor)
        case .fixed:
            return fixed(input, descriptor: descriptor)
        case .bossFight:
            return boss(input, descriptor: descriptor)
        case .spiralStairs:
            return spiral(input, descriptor: descriptor)
        case .parallelTracking:
            return parallel(input, descriptor: descriptor)
        case .none, .waterSurface:
            return nil
        }
    }

    private static func descriptor(
        _ rawMode: Int16,
        _ callback: SM64CameraCallbackKind,
        _ pure: Bool,
        _ ownerThread: Bool,
        _ swapped: Bool,
        _ distance: Float,
        _ positionYOffset: Float,
        _ focusYOffset: Float,
        _ pitch: Int16,
        _ returnsMarioYaw: Bool,
        _ pansAhead: Bool
    ) -> SM64CameraModeCallbackDescriptor {
        SM64CameraModeCallbackDescriptor(
            rawMode: rawMode, callback: callback,
            pureGeometryImplemented: pure,
            ownerThreadRequired: ownerThread,
            outputsSwapped: swapped,
            baseDistance: distance,
            positionYOffset: positionYOffset,
            focusYOffset: focusYOffset,
            basePitch: pitch,
            returnsMarioYaw: returnsMarioYaw,
            pansAhead: pansAhead
        )
    }

    private static func radial(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        let deltaX = input.marioPosition.x - input.areaCenter.x
        let deltaZ = input.marioPosition.z - input.areaCenter.z
        let yaw = SM64CanonicalTrig.atan2s(y: deltaZ, x: deltaX)
            &+ input.modeOffsetYaw
        return placement(
            input: input, descriptor: descriptor, cameraYaw: yaw,
            areaYaw: yaw &- input.modeOffsetYaw,
            distance: input.lakituDistance + descriptor.baseDistance,
            returnedYaw: yaw
        )
    }

    private static func outwardRadial(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        let deltaX = input.marioPosition.x - input.areaCenter.x
        let deltaZ = input.marioPosition.z - input.areaCenter.z
        let yaw = SM64CanonicalTrig.atan2s(y: deltaZ, x: deltaX)
            &+ input.modeOffsetYaw &+ Int16(bitPattern: 0x8000)
        return placement(
            input: input, descriptor: descriptor, cameraYaw: yaw,
            areaYaw: yaw &- input.modeOffsetYaw &- Int16(bitPattern: 0x8000),
            distance: input.lakituDistance + descriptor.baseDistance,
            returnedYaw: yaw
        )
    }

    private static func eightDirections(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        let yaw = input.eightDirectionBaseYaw &+
            input.eightDirectionYawOffset
        return placement(
            input: input, descriptor: descriptor, cameraYaw: yaw,
            areaYaw: yaw,
            distance: input.lakituDistance + descriptor.baseDistance,
            returnedYaw: yaw
        )
    }

    private static func mario(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        let yaw = input.faceYaw &+ input.modeOffsetYaw &+
            Int16(bitPattern: 0x8000)
        let distance = input.zoomDistance ?? descriptor.baseDistance
        return placement(
            input: input, descriptor: descriptor, cameraYaw: yaw,
            areaYaw: yaw,
            distance: distance,
            returnedYaw: input.faceYaw
        )
    }

    private static func slideHoot(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        let yaw = input.faceYaw &+ input.modeOffsetYaw &+
            Int16(bitPattern: 0x8000)
        return placement(
            input: input, descriptor: descriptor, cameraYaw: yaw,
            areaYaw: yaw,
            distance: descriptor.baseDistance,
            returnedYaw: input.faceYaw
        )
    }

    private static func cannon(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        let yaw = input.faceYaw
        return placement(
            input: input, descriptor: descriptor, cameraYaw: yaw,
            areaYaw: yaw,
            distance: descriptor.baseDistance,
            positionYOffset: descriptor.positionYOffset + input.cannonYOffset,
            pitchOverride: input.facePitch,
            returnedYaw: input.faceYaw
        )
    }

    private static func cUp(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        guard let placement = SM64CameraCUp.update(
            marioPosition: input.marioPosition,
            marioFaceYaw: input.faceYaw,
            pitch: input.facePitch,
            modeOffsetYaw: input.modeOffsetYaw,
            lakituPitch: input.lakituPitch
        ) else { return nil }
        return SM64CameraCallbackResult(
            focus: placement.focus,
            position: placement.position,
            cameraYaw: placement.yaw,
            returnedYaw: input.faceYaw,
            areaYaw: placement.yaw,
            pitch: input.facePitch,
            distance: descriptor.baseDistance,
            outputsSwapped: descriptor.outputsSwapped,
            panAhead: descriptor.pansAhead,
            sideButtonYaw: 0,
            behindMarioSoundTimer: 0
        )
    }

    private static func behindMario(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        guard let result = SM64CameraBehindKernel.update(
            SM64CameraBehindInput(
                distance: input.cameraDistance,
                pitch: input.cameraPitch,
                yaw: input.cameraYaw,
                marioFacePitch: input.facePitch,
                marioYaw: input.faceYaw &+ Int16(bitPattern: 0x8000),
                marioModeActive: input.marioModeActive,
                waterOrMetalAction: input.waterOrMetalAction,
                cButtonsPressed: input.cButtonsPressed,
                sideButtonYaw: input.sideButtonYaw,
                behindMarioSoundTimer: input.behindMarioSoundTimer
            )
        ), let placement = SM64CameraGeometry.focusOnMario(
            marioPosition: input.marioPosition,
            positionYOffset: result.focusYOffset,
            focusYOffset: result.focusYOffset,
            distance: result.distance,
            pitch: result.pitch,
            yaw: result.yaw
        ) else { return nil }
        return SM64CameraCallbackResult(
            focus: placement.focus,
            position: placement.position,
            cameraYaw: result.yaw,
            returnedYaw: result.yaw,
            areaYaw: result.yaw,
            pitch: result.pitch,
            distance: result.distance,
            outputsSwapped: descriptor.outputsSwapped,
            panAhead: descriptor.pansAhead,
            sideButtonYaw: result.sideButtonYaw,
            behindMarioSoundTimer: result.behindMarioSoundTimer
        )
    }

    private static func fixed(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        guard let result = SM64CameraFixed.update(
            SM64CameraFixedInput(
                marioPosition: input.marioPosition,
                cameraPosition: input.cameraPosition,
                basePosition: input.fixedBasePosition,
                scaleToMario: input.fixedScaleToMario,
                heightOffset: input.fixedHeightOffset,
                floorHeight: input.fixedFloorHeight,
                ceilingHeight: input.fixedCeilingHeight,
                goalHeight: input.fixedGoalHeight,
                focusFloorOffset: input.fixedFocusFloorOffset,
                smoothMovement: input.fixedSmoothMovement
            )
        ) else { return nil }
        return SM64CameraCallbackResult(
            focus: result.focus,
            position: result.position,
            cameraYaw: result.yaw,
            returnedYaw: result.yaw,
            areaYaw: result.yaw,
            pitch: result.pitch,
            distance: result.distance,
            outputsSwapped: descriptor.outputsSwapped,
            panAhead: descriptor.pansAhead,
            sideButtonYaw: 0,
            behindMarioSoundTimer: 0
        )
    }

    private static func boss(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        guard let result = SM64CameraBoss.update(
            SM64CameraBossInput(
                marioPosition: input.marioPosition,
                secondFocus: input.bossSecondFocus,
                focusDistance: input.bossFocusDistance,
                yaw: input.bossYaw,
                heldState: input.bossHeldState,
                angleVelocity: input.bossAngleVelocity,
                floorHeight: input.bossFloorHeight,
                forceHeight: input.bossForceHeight,
                lakituDistance: input.lakituDistance,
                lakituPitch: input.lakituPitch
            )
        ) else { return nil }
        return SM64CameraCallbackResult(
            focus: result.focus,
            position: result.position,
            cameraYaw: result.yaw,
            returnedYaw: result.yaw,
            areaYaw: result.yaw,
            pitch: 0x1000,
            distance: result.distance,
            outputsSwapped: descriptor.outputsSwapped,
            panAhead: descriptor.pansAhead,
            sideButtonYaw: 0,
            behindMarioSoundTimer: 0
        )
    }

    private static func spiral(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        guard let result = SM64CameraSpiral.update(
            SM64CameraSpiralInput(
                marioPosition: input.marioPosition,
                cameraPosition: input.cameraPosition,
                cameraFocus: input.cameraFocus,
                basePosition: input.spiralBasePosition,
                focusFloorOffset: input.spiralFocusFloorOffset,
                floorHeight: input.spiralFloorHeight,
                currentFloorHeight: input.spiralCurrentFloorHeight
            )
        ) else { return nil }
        return SM64CameraCallbackResult(
            focus: result.focus,
            position: result.position,
            cameraYaw: result.yaw,
            returnedYaw: result.yaw,
            areaYaw: result.yawOffset,
            pitch: 0,
            distance: 300,
            outputsSwapped: descriptor.outputsSwapped,
            panAhead: descriptor.pansAhead,
            sideButtonYaw: 0,
            behindMarioSoundTimer: 0
        )
    }

    private static func parallel(
        _ input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor
    ) -> SM64CameraCallbackResult? {
        guard input.parallelReady,
              let result = SM64CameraParallel.update(
                SM64CameraParallelInput(
                    marioPosition: input.marioPosition,
                    cameraPosition: input.cameraPosition,
                    pathStart: input.parallelPathStart,
                    pathEnd: input.parallelPathEnd,
                    distanceThreshold: input.parallelDistanceThreshold,
                    zoom: input.parallelZoom,
                    marioFloorOffset: input.parallelMarioFloorOffset,
                    transitionOffset: input.parallelTransitionOffset
                )
              ) else { return nil }
        return SM64CameraCallbackResult(
            focus: result.focus,
            position: result.position,
            cameraYaw: result.yaw,
            returnedYaw: result.yaw,
            areaYaw: result.yaw,
            pitch: 0,
            distance: 0,
            outputsSwapped: descriptor.outputsSwapped,
            panAhead: descriptor.pansAhead,
            sideButtonYaw: 0,
            behindMarioSoundTimer: 0
        )
    }

    private static func placement(
        input: SM64CameraCallbackInput,
        descriptor: SM64CameraModeCallbackDescriptor,
        cameraYaw: Int16,
        areaYaw: Int16,
        distance: Float,
        positionYOffset: Float? = nil,
        pitchOverride: Int16? = nil,
        returnedYaw: Int16
    ) -> SM64CameraCallbackResult? {
        guard distance.isFinite else { return nil }
        let offsets: SM64CameraHeightOffsets
        if let height = input.height {
            guard let calculated = SM64CameraGeometry.calculateHeightOffsets(height) else {
                return nil
            }
            offsets = calculated
        } else {
            offsets = SM64CameraHeightOffsets(position: 0, focus: 0)
        }

        let pitch: Int16
        if let pitchOverride {
            pitch = pitchOverride
        } else if let slope = input.slope {
            guard let calculated = SM64CameraGeometry.lookDownSlopes(slope) else {
                return nil
            }
            pitch = calculated
        } else {
            pitch = descriptor.basePitch
        }

        guard let placement = SM64CameraGeometry.focusOnMario(
            marioPosition: input.marioPosition,
            positionYOffset: (positionYOffset ?? descriptor.positionYOffset) + offsets.position,
            focusYOffset: descriptor.focusYOffset + offsets.focus,
            distance: distance,
            pitch: pitch,
            yaw: cameraYaw,
            lakituPitch: input.lakituPitch
        ) else { return nil }
        return SM64CameraCallbackResult(
            focus: placement.focus,
            position: placement.position,
            cameraYaw: cameraYaw,
            returnedYaw: returnedYaw,
            areaYaw: areaYaw,
            pitch: pitch,
            distance: distance,
            outputsSwapped: descriptor.outputsSwapped,
            panAhead: descriptor.pansAhead,
            sideButtonYaw: 0,
            behindMarioSoundTimer: 0
        )
    }

    private static func finite(_ vector: SM64ObjectVector3) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}
