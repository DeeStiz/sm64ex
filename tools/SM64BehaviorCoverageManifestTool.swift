import Foundation

private struct ManifestRow: Comparable, Hashable {
    let identity: String
    let source: String
    let mapping: String
    let owner: String
    let reason: String

    var encoded: String {
        [identity, source, mapping, owner, reason].joined(separator: "|")
    }

    static func < (lhs: ManifestRow, rhs: ManifestRow) -> Bool {
        Array(lhs.encoded.utf8).lexicographicallyPrecedes(Array(rhs.encoded.utf8))
    }
}

private enum ManifestError: Error, CustomStringConvertible {
    case invalidArguments(String)
    case invalidReachabilityRow(String)
    case duplicateRow(String)
    case outputFailed(String)

    var description: String {
        switch self {
        case let .invalidArguments(message), let .invalidReachabilityRow(message),
             let .duplicateRow(message), let .outputFailed(message):
            return message
        }
    }
}

@main
struct SM64BehaviorCoverageManifestTool {
    private struct Options {
        let reachability: String
        let output: String
    }

    private static let swiftRoutes: [String: (owner: String, reason: String)] = [
        "bhvAmp": ("AmpObjectBridge", "value kernel plus generation-safe owner bridge"),
        "bhvBigBoo": ("BigBooObjectBridge", "variant value kernel plus owner/effect route"),
        "bhvBigBully": ("BullyObjectBridge", "Bully value/movement/reward owner route"),
        "bhvBigBullyWithMinions": ("BullyObjectBridge", "Bully minion-parent owner route"),
        "bhvBigChillBully": ("BullyObjectBridge", "Chief Chilly big-bully owner route"),
        "bhvBalconyBigBoo": ("BigBooObjectBridge", "balcony Big Boo variant owner route"),
        "bhvBird": ("BirdObjectBridge", "bird value and owner route"),
        "bhvBouncingFireball": ("BouncingFireballObjectBridge", "bouncing fireball owner route"),
        "bhvBouncingFireballFlame": ("BouncingFireballObjectBridge", "bouncing fireball flame child route"),
        "bhvBobomb": ("BobombObjectBridge", "Bob-omb value/owner route"),
        "bhvBobombBuddy": ("BobombBuddyObjectBridge", "dialog/cannon owner route"),
        "bhvBobombBullyDeathSmoke": ("ExplosionObjectBridge", "shared ground-smoke child route"),
        "bhvBobombExplosionBubble": ("ExplosionObjectBridge", "shared water-bubble child route"),
        "bhvBobombExplosionBubble3600": ("ExplosionObjectBridge", "embedded bubble3600 deterministic jitter route"),
        "bhvBoo": ("BooObjectBridge", "Boo value/owner route"),
        "bhvBowserBomb": ("BowserBombObjectBridge", "Bowser bomb owner route"),
        "bhvBowserBombExplosion": ("BowserBombObjectBridge", "Bowser mine-flame route"),
        "bhvBowserBombSmoke": ("BowserBombObjectBridge", "Bowser mine-smoke route"),
        "bhvBowserKey": ("BowserKeyObjectBridge", "Bowser key owner route"),
        "bhvBowserKeyCourseExit": ("BowserKeyCutsceneObjectBridge", "course-exit key cutscene route"),
        "bhvBowserKeyUnlockDoor": ("BowserKeyCutsceneObjectBridge", "unlock-door key cutscene route"),
        "bhvBowserShockWave": ("BowserShockwaveObjectBridge", "Bowser shockwave owner route"),
        "bhvBulletBill": ("BulletBillObjectBridge", "Bullet Bill value/owner route"),
        "bhvChainChomp": ("ChainChompObjectBridge", "chain chomp value/owner route"),
        "bhvChainChompChainPart": ("ChainChompObjectBridge", "chain chomp segment child route"),
        "bhvChainChompGate": ("ChainChompReleaseObjectBridge", "chain chomp gate owner route"),
        "bhvChuckya": ("ChuckyaObjectBridge", "Chuckya value/owner route"),
        "bhvChuckyaAnchorMario": ("ChuckyaObjectBridge", "Chuckya anchored-Mario child route"),
        "bhvEyerok": ("EyerokObjectBridge", "Eyerok boss owner route"),
        "bhvEyerokBoss": ("EyerokObjectBridge", "Eyerok boss owner route"),
        "bhvEyerokHand": ("EyerokObjectBridge", "Eyerok hand owner route"),
        "bhvEnemyLakitu": ("EnemyLakituObjectBridge", "enemy Lakitu owner route"),
        "bhvExplosion": ("ExplosionObjectBridge", "shared generic explosion route"),
        "bhvFlyGuy": ("FlyGuyObjectBridge", "Fly Guy value/owner route"),
        "bhvFlyguyFlame": ("FlyGuyObjectBridge", "Fly Guy flame child route"),
        "bhvGoomba": ("GoombaObjectBridge", "Goomba value/owner route"),
        "bhvGoombaTripletSpawner": ("GoombaObjectBridge", "Goomba triplet spawner owner route"),
        "bhvHeaveHo": ("HeaveHoObjectBridge", "Heave Ho value/owner route"),
        "bhvGhostHuntBigBoo": ("BigBooObjectBridge", "Ghost Hunt Big Boo variant owner route"),
        "bhvHomingAmp": ("AmpObjectBridge", "homing Amp variant owner route"),
        "bhvKingBobomb": ("KingBobombObjectBridge", "King Bob-omb value/owner route"),
        "bhvKingWhomp": ("WhompObjectBridge", "King Whomp value/owner route"),
        "bhvKoopaShell": ("KoopaShellObjectBridge", "Koopa shell value/owner route"),
        "bhvKoopaShellUnderwater": ("KoopaShellObjectBridge", "underwater Koopa shell owner route"),
        "bhvLakitu": ("LakituObjectBridge", "Lakitu value/owner route"),
        "bhvMoneybag": ("MoneybagObjectBridge", "Moneybag value/owner route"),
        "bhvMoneybagHidden": ("MoneybagObjectBridge", "hidden Moneybag coin owner route"),
        "bhvMrI": ("MrIObjectBridge", "Mr. I value/owner route"),
        "bhvMrIBody": ("MrIObjectBridge", "Mr. I iris child owner route"),
        "bhvMrIParticle": ("MrIObjectBridge", "Mr. I particle child owner route"),
        "bhvPiranhaPlant": ("PiranhaPlantObjectBridge", "Piranha Plant value/owner route"),
        "bhvPokey": ("PokeyObjectBridge", "Pokey value/owner route"),
        "bhvRacingPenguin": ("RacingPenguinObjectBridge", "racing penguin path/owner route"),
        "bhvPenguinRaceFinishLine": ("RacingPenguinObjectBridge", "racing penguin finish-line child route"),
        "bhvPenguinRaceShortcutCheck": ("RacingPenguinObjectBridge", "racing penguin shortcut child route"),
        "bhvRespawner": ("RespawnerObjectBridge", "respawner value/owner route"),
        "bhvSmallBully": ("BullyObjectBridge", "Bully small variant owner route"),
        "bhvSmallChillBully": ("BullyObjectBridge", "Chief Chilly small-bully owner route"),
        "bhvScuttlebug": ("ScuttlebugObjectBridge", "Scuttlebug value/owner route"),
        "bhvSkeeter": ("SkeeterObjectBridge", "Skeeter value/owner route"),
        "bhvSkeeterWave": ("SkeeterObjectBridge", "Skeeter wave child route"),
        "bhvSnufitBalls": ("SnufitObjectBridge", "Snufit bullet child owner route"),
        "bhvSLWalkingPenguin": ("SLWalkingPenguinObjectBridge", "walking penguin value/owner route"),
        "bhvSnufit": ("SnufitObjectBridge", "Snufit value/owner route"),
        "bhvSnufitBullet": ("SnufitObjectBridge", "Snufit bullet owner route"),
        "bhvSpiny": ("SpinyObjectBridge", "Spiny value/owner route"),
        "bhvSpinyBall": ("SpinyObjectBridge", "Spiny ball owner route"),
        "bhvSwoop": ("SwoopObjectBridge", "Swoop value/owner route"),
        "bhvTuxiesMother": ("TuxiesMotherObjectBridge", "Tuxie's mother value/owner route"),
        "bhvSmallPenguin": ("SmallPenguinObjectBridge", "small penguin value/owner route"),
        "bhvWaterBomb": ("WaterBombObjectBridge", "water bomb value/owner route"),
        "bhvWaterBombShadow": ("WaterBombObjectBridge", "water bomb shadow child route"),
        "bhvWaterBombSpawner": ("WaterBombObjectBridge", "water bomb spawner owner route"),
        "bhvWhomp": ("WhompObjectBridge", "Whomp value/owner route"),
        "bhvWhompKingBoss": ("WhompObjectBridge", "King Whomp variant owner route"),
        "bhvSmallWhomp": ("WhompObjectBridge", "small Whomp variant owner route"),
        "bhvMerryGoRoundBigBoo": ("BigBooObjectBridge", "Merry-Go-Round Big Boo variant owner route"),
        "bhvCirclingAmp": ("AmpObjectBridge", "circling Amp variant owner route"),
        "bhvWoodenPost": ("ChainChompReleaseObjectBridge", "wooden-post release owner route"),
        "bhvYoshi": ("YoshiObjectBridge", "Yoshi value/owner route"),
    ]

    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("sm64-behavior-manifest: \(error)\n".utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        let options = try parse(arguments: arguments)
        let reachability = try String(contentsOfFile: options.reachability, encoding: .utf8)
        var rows: [ManifestRow] = []
        var seen: Set<String> = []
        for line in reachability.split(whereSeparator: \.isNewline) {
            if line.hasPrefix("#") { continue }
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 5, fields[0] == "behavior" else { continue }
            let identity = fields[1]
            let source = fields[2]
            guard !identity.isEmpty, !source.isEmpty else {
                throw ManifestError.invalidReachabilityRow(String(line))
            }
            let key = identity + "|" + source
            guard seen.insert(key).inserted else {
                throw ManifestError.duplicateRow(key)
            }
            if let route = swiftRoutes[identity] {
                rows.append(ManifestRow(
                    identity: identity,
                    source: source,
                    mapping: "swift_value_owner",
                    owner: route.owner,
                    reason: route.reason
                ))
            } else {
                rows.append(ManifestRow(
                    identity: identity,
                    source: source,
                    mapping: "unmigrated_c_adapter",
                    owner: "CBehaviorAdapter",
                    reason: "reachable behavior has no registered Swift value/owner route"
                ))
            }
        }

        let ordered = rows.sorted()
        let header = [
            "# sm64-modern-behavior-coverage-v1",
            "# identity|source|mapping|owner|reason",
        ]
        let output = (header + ordered.map(\.encoded)).joined(separator: "\n") + "\n"
        do {
            let outputURL = URL(fileURLWithPath: options.output).standardizedFileURL
            try FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(output.utf8).write(to: outputURL, options: .atomic)
        } catch {
            throw ManifestError.outputFailed("cannot write \(options.output): \(error)")
        }

        var fingerprint = UInt64(1_469_598_103_934_665_603)
        for byte in output.utf8 {
            fingerprint ^= UInt64(byte)
            fingerprint &*= UInt64(1_099_511_628_211)
        }
        let swiftCount = ordered.filter { $0.mapping == "swift_value_owner" }.count
        let adapterCount = ordered.filter { $0.mapping == "unmigrated_c_adapter" }.count
        print(String(format: "behaviorManifestFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern behavior manifest rows=\(ordered.count) swiftValueOwner=\(swiftCount) unmigratedCAdapter=\(adapterCount)")
    }

    private static func parse(arguments: [String]) throws -> Options {
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            guard index + 1 < arguments.count, arguments[index].hasPrefix("--") else {
                throw ManifestError.invalidArguments("usage: sm64-behavior-manifest --reachability TSV --output TSV")
            }
            values[arguments[index]] = arguments[index + 1]
            index += 2
        }
        guard let reachability = values["--reachability"], let output = values["--output"] else {
            throw ManifestError.invalidArguments("usage: sm64-behavior-manifest --reachability TSV --output TSV")
        }
        return Options(reachability: reachability, output: output)
    }
}
