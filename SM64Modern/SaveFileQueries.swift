import Foundation

/// Read-only queries that keep the C `save_file_*` indexing and tie-break
/// rules in one value-only surface. Mutation and persistence stay in the
/// progression runtime and owner-thread EEPROM adapter respectively.
enum SM64SaveFileQueries {
    static let fileExistsFlag: UInt32 = 1 << 0
    static let capOnGroundFlag: UInt32 = 1 << 16

    static func exists(_ save: SM64SaveFileSnapshot) -> Bool {
        save.flags & fileExistsFlag != 0
    }

    /// C accepts `-1` as the castle-secret-star course.
    static func starFlags(
        _ save: SM64SaveFileSnapshot,
        courseIndex: Int
    ) -> UInt8? {
        if courseIndex == -1 {
            return UInt8(truncatingIfNeeded: (save.flags >> 24) & 0x7F)
        }
        guard (0..<SM64SaveFileSnapshot.courseCount).contains(courseIndex) else {
            return nil
        }
        return save.courseStars[courseIndex] & 0x7F
    }

    /// `save_file_get_cannon_flags` intentionally reads the byte following
    /// the requested course, matching the original C layout.
    static func cannonFlags(
        _ save: SM64SaveFileSnapshot,
        courseIndex: Int
    ) -> UInt8? {
        guard (0..<SM64SaveFileSnapshot.stageCount).contains(courseIndex) else {
            return nil
        }
        return (save.courseStars[courseIndex + 1] & 0x80) == 0 ? 0 : 1
    }

    /// The current-course C helper indexes `courseStars[gCurrCourseNum]`, so
    /// a one-based course number intentionally maps directly to this array.
    static func cannonUnlocked(
        _ save: SM64SaveFileSnapshot,
        currentCourseNumber: Int
    ) -> Bool? {
        guard (1...SM64SaveFileSnapshot.stageCount).contains(currentCourseNumber) else {
            return nil
        }
        return save.courseStars[currentCourseNumber] & 0x80 != 0
    }

    static func courseCoinScore(
        _ save: SM64SaveFileSnapshot,
        courseIndex: Int
    ) -> UInt8? {
        guard (0..<SM64SaveFileSnapshot.stageCount).contains(courseIndex) else {
            return nil
        }
        return save.courseCoinScores[courseIndex]
    }

    static func courseStarCount(
        _ save: SM64SaveFileSnapshot,
        courseIndex: Int
    ) -> Int? {
        guard let flags = starFlags(save, courseIndex: courseIndex) else {
            return nil
        }
        return Int(flags.nonzeroBitCount)
    }

    static func totalStarCount(
        _ save: SM64SaveFileSnapshot,
        minimumCourse: Int,
        maximumCourse: Int
    ) -> Int? {
        guard minimumCourse <= maximumCourse,
              (0..<SM64SaveFileSnapshot.courseCount).contains(minimumCourse),
              (0..<SM64SaveFileSnapshot.courseCount).contains(maximumCourse)
        else { return nil }
        var count = 0
        for course in minimumCourse...maximumCourse {
            count += courseStarCount(save, courseIndex: course)!
        }
        // C always adds castle secret stars after the standard range.
        return count + courseStarCount(save, courseIndex: -1)!
    }

    static func capPosition(
        _ save: SM64SaveFileSnapshot,
        currentLevel: UInt8,
        currentArea: UInt8
    ) -> SM64SaveInt16Vector3? {
        guard save.capLevel == currentLevel,
              save.capArea == currentArea,
              save.flags & capOnGroundFlag != 0 else { return nil }
        return save.capPosition
    }

    /// Returns C's packed `(fileIndex + 1) << 16 | score` result. A course
    /// with no obtained star returns zero rather than selecting an empty file.
    static func maximumCoinScore(
        saves: [SM64SaveFileSnapshot],
        menu: SM64MenuDataSnapshot,
        courseIndex: Int
    ) -> UInt32? {
        guard saves.count == SM64CoinScoreAgeState.fileCount,
              (0..<SM64SaveFileSnapshot.stageCount).contains(courseIndex),
              menu.coinScoreAges.count == SM64CoinScoreAgeState.fileCount else {
            return nil
        }
        var maxScore = -1
        var maxAge = -1
        var maxFileNumber = 0
        for fileIndex in saves.indices {
            guard let flags = starFlags(saves[fileIndex], courseIndex: courseIndex),
                  flags != 0 else { continue }
            let score = Int(saves[fileIndex].courseCoinScores[courseIndex])
            let age = Int((menu.coinScoreAges[fileIndex] >> UInt32(courseIndex * 2)) & 0x3)
            if score > maxScore || (score == maxScore && age > maxAge) {
                maxScore = score
                maxAge = age
                maxFileNumber = fileIndex + 1
            }
        }
        return (UInt32(maxFileNumber) << 16) | UInt32(max(maxScore, 0))
    }
}
