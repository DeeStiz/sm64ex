import Foundation

struct SM64SaveCapRelocationResult: Equatable, Sendable {
    let save: SM64SaveFileSnapshot
    let location: SM64ProgressionCapLocation
}

enum SM64SaveFileMutation: Equatable, Sendable {
    case setFlags(UInt32)
    case clearFlags(UInt32)
    case setStarFlags(starFlags: UInt32, courseIndex: Int)
    case setCannonUnlocked(currentCourseNumber: Int)
    case setCapPosition(
        level: UInt8,
        area: UInt8,
        position: SM64SaveInt16Vector3
    )
    case moveCapToDefaultLocation(level: UInt8)
    case setSoundMode(UInt16)
}

struct SM64SaveFileMutationResult: Equatable, Sendable {
    let save: SM64SaveFileSnapshot
    let menu: SM64MenuDataSnapshot
    /// C marks the corresponding block dirty for every admitted setter. This
    /// stays true even when the resulting bytes equal the input bytes.
    let didMutate: Bool
}

/// Pure counterparts of the C save mutation helpers. Callers choose the
/// owner-thread persistence boundary; these functions only rewrite snapshots
/// and never touch C globals or files.
enum SM64SaveFileMutator {
    static let fileExistsFlag: UInt32 = 1 << 0
    static let capOnGroundFlag: UInt32 = 1 << 16
    static let capOnKleptoFlag: UInt32 = 1 << 17
    static let capOnUkikiFlag: UInt32 = 1 << 18
    static let capOnMrBlizzardFlag: UInt32 = 1 << 19

    static func setFlags(
        _ flags: UInt32,
        in save: SM64SaveFileSnapshot
    ) -> SM64SaveFileSnapshot {
        var next = save
        next.flags |= flags | fileExistsFlag
        return next
    }

    static func clearFlags(
        _ flags: UInt32,
        in save: SM64SaveFileSnapshot
    ) -> SM64SaveFileSnapshot {
        var next = save
        next.flags &= ~flags
        next.flags |= fileExistsFlag
        return next
    }

    /// `courseIndex == -1` targets the seven castle-secret stars stored in
    /// the high byte of flags; standard courses target the courseStars byte.
    static func setStarFlags(
        _ starFlags: UInt32,
        courseIndex: Int,
        in save: SM64SaveFileSnapshot
    ) -> SM64SaveFileSnapshot? {
        var next = save
        if courseIndex == -1 {
            next.flags |= starFlags << 24
        } else {
            guard (0..<SM64SaveFileSnapshot.courseCount).contains(courseIndex) else {
                return nil
            }
            next.courseStars[courseIndex] |= UInt8(truncatingIfNeeded: starFlags)
        }
        next.flags |= fileExistsFlag
        return next
    }

    /// C's current-course helper intentionally uses the one-based course
    /// number as the byte index, because courseStars[0] is the preceding
    /// course's cannon bit in the original layout.
    static func setCannonUnlocked(
        currentCourseNumber: Int,
        in save: SM64SaveFileSnapshot
    ) -> SM64SaveFileSnapshot? {
        guard (1...SM64SaveFileSnapshot.stageCount).contains(currentCourseNumber) else {
            return nil
        }
        var next = save
        next.courseStars[currentCourseNumber] |= 0x80
        next.flags |= fileExistsFlag
        return next
    }

    static func setCapPosition(
        level: UInt8,
        area: UInt8,
        position: SM64SaveInt16Vector3,
        in save: SM64SaveFileSnapshot
    ) -> SM64SaveFileSnapshot {
        var next = save
        next.capLevel = level
        next.capArea = area
        next.capPosition = position
        next.flags |= capOnGroundFlag | fileExistsFlag
        return next
    }

    /// Mirrors `save_file_move_cap_to_default_location`: only a cap currently
    /// on the ground is relocated, and the source C order leaves unrelated
    /// location bits untouched while clearing CAP_ON_GROUND.
    static func moveCapToDefaultLocation(
        level: UInt8,
        in save: SM64SaveFileSnapshot
    ) -> SM64SaveCapRelocationResult {
        var next = save
        var location: SM64ProgressionCapLocation = .none
        if save.flags & capOnGroundFlag != 0 {
            switch level {
            case 0x08: // LEVEL_SSL
                next.flags |= capOnKleptoFlag | fileExistsFlag
                location = .klepto
            case 0x0A: // LEVEL_SL
                next.flags |= capOnMrBlizzardFlag | fileExistsFlag
                location = .mrBlizzard
            case 0x24: // LEVEL_TTM
                next.flags |= capOnUkikiFlag | fileExistsFlag
                location = .ukiki
            default:
                break
            }
            next.flags &= ~capOnGroundFlag
            next.flags |= fileExistsFlag
        }
        return SM64SaveCapRelocationResult(save: next, location: location)
    }

    static func setSoundMode(
        _ mode: UInt16,
        in menu: SM64MenuDataSnapshot
    ) -> SM64MenuDataSnapshot {
        var next = menu
        next.soundMode = mode
        return next
    }

    static func apply(
        _ mutation: SM64SaveFileMutation,
        save: SM64SaveFileSnapshot,
        menu: SM64MenuDataSnapshot
    ) -> SM64SaveFileMutationResult? {
        switch mutation {
        case let .setFlags(flags):
            return .init(
                save: setFlags(flags, in: save), menu: menu, didMutate: true
            )
        case let .clearFlags(flags):
            return .init(
                save: clearFlags(flags, in: save), menu: menu, didMutate: true
            )
        case let .setStarFlags(starFlags, courseIndex):
            guard let next = setStarFlags(
                starFlags, courseIndex: courseIndex, in: save
            ) else { return nil }
            return .init(save: next, menu: menu, didMutate: true)
        case let .setCannonUnlocked(currentCourseNumber):
            guard let next = setCannonUnlocked(
                currentCourseNumber: currentCourseNumber, in: save
            ) else { return nil }
            return .init(save: next, menu: menu, didMutate: true)
        case let .setCapPosition(level, area, position):
            return .init(
                save: setCapPosition(
                    level: level, area: area, position: position, in: save
                ), menu: menu, didMutate: true
            )
        case let .moveCapToDefaultLocation(level):
            guard save.flags & capOnGroundFlag != 0 else { return nil }
            return .init(
                save: moveCapToDefaultLocation(level: level, in: save).save,
                menu: menu,
                didMutate: true
            )
        case let .setSoundMode(mode):
            return .init(
                save: save, menu: setSoundMode(mode, in: menu), didMutate: true
            )
        }
    }
}
