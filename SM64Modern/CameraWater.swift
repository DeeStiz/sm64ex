import Foundation

/// Deterministic no-op transition value for camera mode 8. The normal
/// water-surface frame path uses the behind-Mario camera; this callback exists
/// for the mode-transition table, where the legacy C function intentionally
/// leaves focus/position untouched.
enum SM64CameraWater {
    static func update(
        _ input: SM64CameraCallbackInput
    ) -> SM64CameraCallbackResult? {
        guard input.cameraFocus.x.isFinite,
              input.cameraFocus.y.isFinite,
              input.cameraFocus.z.isFinite,
              input.cameraPosition.x.isFinite,
              input.cameraPosition.y.isFinite,
              input.cameraPosition.z.isFinite,
              input.cameraDistance.isFinite else { return nil }
        return SM64CameraCallbackResult(
            focus: input.cameraFocus,
            position: input.cameraPosition,
            cameraYaw: input.cameraYaw,
            returnedYaw: input.cameraYaw,
            areaYaw: input.cameraYaw,
            pitch: input.cameraPitch,
            distance: input.cameraDistance,
            outputsSwapped: false,
            panAhead: false,
            sideButtonYaw: 0,
            behindMarioSoundTimer: 0
        )
    }
}
