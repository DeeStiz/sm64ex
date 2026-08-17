import Foundation

struct SM64MarioFaceAnimationResourceManifestEntry: Equatable, Sendable {
    let componentID: UInt32
    let animatorID: UInt32
    let sourcePath: String
    let primarySymbol: String
    let secondarySymbol: String
    let primaryCount: UInt32
    let primaryType: SM64MarioFaceAnimationType
    let secondaryCount: UInt32
    let secondaryType: SM64MarioFaceAnimationType
    let primaryStride: UInt32
    let secondaryStride: UInt32
}

/// Source inventory for the complete Mario-face/intro/star animation bank.
/// This names the checked-in C arrays and their exact `AnimDataInfo` shape;
/// it does not load their payload bytes or make them renderer-authoritative.
enum SM64MarioFaceAnimationResourceManifest {
    static let entries: [SM64MarioFaceAnimationResourceManifestEntry] = [
        .init(componentID: 0x07, animatorID: 0x08, sourcePath: "src/goddard/dynlists/anim_mario_mustache_right.c", primarySymbol: "animdata_mario_mustache_right_1", secondarySymbol: "animdata_mario_mustache_right_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x10, animatorID: 0x11, sourcePath: "src/goddard/dynlists/anim_mario_mustache_left.c", primarySymbol: "animdata_mario_mustache_left_1", secondarySymbol: "animdata_mario_mustache_left_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x20, animatorID: 0x21, sourcePath: "src/goddard/dynlists/anim_mario_lips_1.c", primarySymbol: "animdata_mario_lips_1_1", secondarySymbol: "animdata_mario_lips_1_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x29, animatorID: 0x2A, sourcePath: "src/goddard/dynlists/anim_mario_lips_2.c", primarySymbol: "animdata_mario_lips_2_1", secondarySymbol: "animdata_mario_lips_2_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x32, animatorID: 0x33, sourcePath: "src/goddard/dynlists/anim_mario_eyebrows_1.c", primarySymbol: "animdata_mario_eyebrows_1_1", secondarySymbol: "animdata_mario_eyebrows_1_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x3F, animatorID: 0x40, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_eyebrows_equalizer_1", secondarySymbol: "", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty, primaryStride: 3, secondaryStride: 0),
        .init(componentID: 0x42, animatorID: 0x43, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_eyebrows_2_1", secondarySymbol: "animdata_mario_eyebrows_2_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x48, animatorID: 0x49, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "anim_mario_eyebrows_3_1", secondarySymbol: "", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty, primaryStride: 3, secondaryStride: 0),
        .init(componentID: 0x4B, animatorID: 0x4C, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_eyebrows_4_1", secondarySymbol: "animdata_mario_eyebrows_4_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x54, animatorID: 0x55, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_eyebrows_5_1", secondarySymbol: "", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty, primaryStride: 3, secondaryStride: 0),
        .init(componentID: 0x6B, animatorID: 0x6C, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_eye_left_1", secondarySymbol: "animdata_mario_eye_left_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x7B, animatorID: 0x7C, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_eye_right_1", secondarySymbol: "animdata_mario_eye_right_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x84, animatorID: 0x85, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_hat_1", secondarySymbol: "animdata_mario_hat_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x96, animatorID: 0x97, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_lips_3_1", secondarySymbol: "animdata_mario_lips_3_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0x9F, animatorID: 0xA0, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_lips_4_1", secondarySymbol: "animdata_mario_lips_4_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0xA8, animatorID: 0xA9, sourcePath: "src/goddard/dynlists/anim_group_1.c", primarySymbol: "animdata_mario_ear_left_1", secondarySymbol: "", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty, primaryStride: 3, secondaryStride: 0),
        .init(componentID: 0xB1, animatorID: 0xB2, sourcePath: "src/goddard/dynlists/anim_group_2.c", primarySymbol: "animdata_mario_ear_right_1", secondarySymbol: "", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 0, secondaryType: .empty, primaryStride: 3, secondaryStride: 0),
        .init(componentID: 0xBA, animatorID: 0xBB, sourcePath: "src/goddard/dynlists/anim_group_2.c", primarySymbol: "animdata_mario_nose_1", secondarySymbol: "animdata_mario_nose_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0xC3, animatorID: 0xC4, sourcePath: "src/goddard/dynlists/anim_group_2.c", primarySymbol: "animdata_mario_lips_5_1", secondarySymbol: "animdata_mario_lips_5_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0xC6, animatorID: 0xC7, sourcePath: "src/goddard/dynlists/anim_group_2.c", primarySymbol: "animdata_mario_lip_6_1", secondarySymbol: "animdata_mario_lip_6_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0xCF, animatorID: 0xD0, sourcePath: "src/goddard/dynlists/anim_group_2.c", primarySymbol: "animdata_mario_eyelid_left_1", secondarySymbol: "animdata_mario_eyelid_left_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0xD8, animatorID: 0xD9, sourcePath: "src/goddard/dynlists/anim_group_2.c", primarySymbol: "animdata_mario_eyelid_right_1", secondarySymbol: "animdata_mario_eyelid_right_2", primaryCount: 820, primaryType: .threeHScaled, secondaryCount: 166, secondaryType: .threeHScaled, primaryStride: 3, secondaryStride: 3),
        .init(componentID: 0xE2, animatorID: 0xE3, sourcePath: "src/goddard/dynlists/anim_group_2.c", primarySymbol: "animdata_mario_intro_1", secondarySymbol: "animdata_mario_intro_2", primaryCount: 820, primaryType: .sixHScaled, secondaryCount: 166, secondaryType: .sixHScaled, primaryStride: 6, secondaryStride: 6),
        .init(componentID: 0xE5, animatorID: 0xE6, sourcePath: "src/goddard/dynlists/anim_group_2.c", primarySymbol: "animdata_silver_star_1", secondarySymbol: "animdata_silver_star_2", primaryCount: 820, primaryType: .sixHScaled, secondaryCount: 166, secondaryType: .sixHScaled, primaryStride: 6, secondaryStride: 6),
        .init(componentID: 0xE8, animatorID: 0xE9, sourcePath: "src/goddard/dynlists/anim_group_2.c", primarySymbol: "animdata_red_star_1", secondarySymbol: "animdata_red_star_2", primaryCount: 820, primaryType: .sixHScaled, secondaryCount: 166, secondaryType: .sixHScaled, primaryStride: 6, secondaryStride: 6),
    ]

    static func entry(componentID: UInt32) -> SM64MarioFaceAnimationResourceManifestEntry? {
        entries.first { $0.componentID == componentID }
    }

    static func matchesCatalog() -> Bool {
        entries.count == SM64MarioFaceAnimationTimeline.catalog.count
            && zip(entries, SM64MarioFaceAnimationTimeline.catalog).allSatisfy { manifest, channel in
                manifest.componentID == channel.componentID
                    && manifest.animatorID == channel.animatorID
                    && manifest.primaryCount == channel.primaryCount
                    && manifest.primaryType == channel.primaryType
                    && manifest.secondaryCount == channel.secondaryCount
                    && manifest.secondaryType == channel.secondaryType
            }
    }
}

enum SM64MarioFaceAnimationResourceManifestFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    private static func hash(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xFF
            result &*= prime
        }
        return result
    }

    private static func hash(_ initial: UInt64, _ string: String) -> UInt64 {
        var result = hash(initial, UInt64(string.utf8.count))
        for byte in string.utf8 {
            result = hash(result, UInt64(byte))
        }
        return result
    }

    static func manifest(_ entries: [SM64MarioFaceAnimationResourceManifestEntry]) -> UInt64 {
        var result = hash(offset, UInt64(entries.count))
        for entry in entries {
            for value in [
                entry.componentID, entry.animatorID, entry.primaryCount,
                entry.primaryType.rawValue, entry.secondaryCount,
                entry.secondaryType.rawValue, entry.primaryStride, entry.secondaryStride,
            ] {
                result = hash(result, UInt64(value))
            }
            result = hash(result, entry.sourcePath)
            result = hash(result, entry.primarySymbol)
            result = hash(result, entry.secondarySymbol)
        }
        return result
    }
}
