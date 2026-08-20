import Foundation

struct SM64MusicTouchInput: Equatable, Sendable { let action: Int32; let timer: Int32; let distanceToMario: Float }
struct SM64MusicTouchOutput: Equatable, Sendable { let action: Int32; let timer: Int32; let playPuzzleJingle: Bool }
enum SM64MusicTouchBehavior { static func update(_ input: SM64MusicTouchInput) -> SM64MusicTouchOutput { let trigger = input.action == 0 && input.distanceToMario < 200; return .init(action: trigger ? 1 : input.action, timer: input.timer &+ 1, playPuzzleJingle: trigger) } }
