import Foundation

struct SM64NoOpInput: Equatable, Sendable { let position: SM64ObjectVector3; let faceAngles: SM64ObjectAngles }
struct SM64NoOpOutput: Equatable, Sendable { let position: SM64ObjectVector3; let faceAngles: SM64ObjectAngles; let scriptBreaks: Bool }

enum SM64NoOpBehavior {
    static func update(_ input: SM64NoOpInput) -> SM64NoOpOutput { .init(position: input.position, faceAngles: input.faceAngles, scriptBreaks: true) }
}
