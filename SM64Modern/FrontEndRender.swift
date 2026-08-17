import Foundation

enum SM64FrontEndRenderKind: UInt8, Equatable, Sendable {
    case backgroundTile = 1
    case titleModel = 2
    case text = 3
    case selectionCursor = 4
    case fade = 5
}

enum SM64FrontEndTextID: UInt16, Equatable, Sendable {
    case pressStart = 1
    case selectFile = 2
    case score = 3
    case copy = 4
    case erase = 5
    case sound = 6
    case marioA = 7
    case marioB = 8
    case marioC = 9
    case marioD = 10
    case course = 11
    case credits = 12
    case ending = 13
    case demo = 14
}

struct SM64FrontEndRenderLayout: Equatable, Sendable {
    let width: Int32
    let height: Int32
    let aspectRatio: Double

    init(width: Int32 = 320, height: Int32 = 240, aspectRatio: Double = 4.0 / 3.0) {
        self.width = width
        self.height = height
        self.aspectRatio = aspectRatio
    }

    var tileColumns: Int32 {
        max(Int32(ceil(aspectRatio * Double(height) / 80.0)), 1)
    }

    var tileOriginX: Int32 {
        Int32(floor(Double(width) / 2.0 - aspectRatio * Double(height) / 2.0))
    }
}

struct SM64FrontEndRenderCommand: Equatable, Sendable {
    let kind: SM64FrontEndRenderKind
    let id: UInt16
    let x: Int32
    let y: Int32
    let width: Int32
    let height: Int32
    let value: Int32
    let alpha: UInt16

    static func tile(index: Int32, x: Int32, y: Int32, source: Int32) -> Self {
        Self(kind: .backgroundTile, id: UInt16(index), x: x, y: y, width: 80, height: 80, value: source, alpha: 255)
    }

    static func titleModel(counter: Int16) -> Self {
        Self(kind: .titleModel, id: 0, x: 160, y: 120, width: 0, height: 0, value: Int32(counter), alpha: 255)
    }

    static func text(_ id: SM64FrontEndTextID, x: Int32, y: Int32, alpha: UInt16 = 255) -> Self {
        Self(kind: .text, id: id.rawValue, x: x, y: y, width: 0, height: 0, value: 0, alpha: alpha)
    }

    static func cursor(x: Int32, y: Int32, selection: Int32) -> Self {
        Self(kind: .selectionCursor, id: 0, x: x, y: y, width: 16, height: 16, value: selection, alpha: 255)
    }

    static func fade(alpha: UInt16) -> Self {
        Self(kind: .fade, id: 0, x: 0, y: 0, width: 0, height: 0, value: 0, alpha: alpha)
    }
}

struct SM64FrontEndRenderPacket: Equatable, Sendable {
    let screen: SM64FrontEndScreen
    let layout: SM64FrontEndRenderLayout
    let commands: [SM64FrontEndRenderCommand]

    static func project(
        _ model: SM64FrontEndModel,
        layout: SM64FrontEndRenderLayout = SM64FrontEndRenderLayout()
    ) -> Self {
        var commands: [SM64FrontEndRenderCommand] = []
        commands.reserveCapacity(24)

        switch model.screen {
        case .title:
            for index in 0..<(layout.tileColumns * 3) {
                let x = layout.tileOriginX + (index % layout.tileColumns) * 80
                let y = (index / layout.tileColumns) * 80
                commands.append(.tile(index: index, x: x, y: y, source: 0))
            }
            commands.append(.titleModel(counter: model.title.zoomCounter))
            commands.append(.text(.pressStart, x: 160, y: 30))
            if model.title.fadeCounter > 0 {
                commands.append(.fade(alpha: UInt16(model.title.fadeCounter)))
            }
        case .fileSelect:
            commands.append(.text(.selectFile, x: 93, y: 35))
            commands.append(.text(.score, x: 52, y: 39))
            commands.append(.text(.copy, x: 117, y: 39))
            commands.append(.text(.erase, x: 177, y: 39))
            commands.append(.text(.sound, x: 235, y: 39))
            commands.append(.text(.marioA, x: 92, y: 65))
            commands.append(.text(.marioB, x: 207, y: 65))
            commands.append(.text(.marioC, x: 92, y: 105))
            commands.append(.text(.marioD, x: 207, y: 105))
            commands.append(.cursor(x: model.selectedFile <= 2 ? 92 : 92, y: model.selectedFile <= 2 ? 65 : 105, selection: Int32(model.selectedFile)))
        case .courseSelect:
            commands.append(.text(.course, x: 160, y: 35))
            commands.append(.cursor(x: 160, y: 80 + Int32(model.selectedCourse - 1) * 8, selection: Int32(model.selectedCourse)))
        case .levelSelect:
            commands.append(.text(.course, x: 160, y: 80))
            commands.append(.cursor(x: 80, y: 60, selection: Int32(model.selectedLevel)))
        case .demo:
            commands.append(.text(.demo, x: 160, y: 30))
        case .gameplay:
            break
        case .credits:
            commands.append(.text(.credits, x: 160, y: 120))
        case .ending:
            commands.append(.text(.ending, x: 160, y: 120))
        }

        return Self(screen: model.screen, layout: layout, commands: commands)
    }
}
