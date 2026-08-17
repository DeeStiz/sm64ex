import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func hashU32(_ hash: UInt64, _ value: UInt32) -> UInt64 {
    var result = hash
    for shift in stride(from: 0, through: 24, by: 8) {
        result ^= UInt64((value >> UInt32(shift)) & 0xFF)
        result &*= fnvPrime
    }
    return result
}

private func record(_ hash: UInt64, _ packet: SM64FrontEndRenderPacket) -> UInt64 {
    var value = hash
    value = hashU32(value, UInt32(packet.screen.rawValue))
    value = hashU32(value, UInt32(bitPattern: packet.layout.width))
    value = hashU32(value, UInt32(bitPattern: packet.layout.height))
    value = hashU32(value, UInt32(packet.commands.count))
    for command in packet.commands {
        value = hashU32(value, UInt32(command.kind.rawValue))
        value = hashU32(value, UInt32(command.id))
        value = hashU32(value, UInt32(bitPattern: command.x))
        value = hashU32(value, UInt32(bitPattern: command.y))
        value = hashU32(value, UInt32(bitPattern: command.width))
        value = hashU32(value, UInt32(bitPattern: command.height))
        value = hashU32(value, UInt32(bitPattern: command.value))
        value = hashU32(value, UInt32(command.alpha))
    }
    return value
}

@main
enum SM64ModernFrontEndRenderSmoke {
    static func main() {
        let titleModel = SM64FrontEndModel()
        let titlePacket = SM64FrontEndRenderPacket.project(titleModel)
        precondition(titlePacket.commands.count == 14)
        precondition(titlePacket.commands[0] == .tile(index: 0, x: 0, y: 0, source: 0))
        precondition(titlePacket.commands[11] == .tile(index: 11, x: 240, y: 160, source: 0))
        precondition(titlePacket.commands[12] == .titleModel(counter: 0))
        precondition(titlePacket.commands[13] == .text(.pressStart, x: 160, y: 30))

        let widescreen = SM64FrontEndRenderPacket.project(
            titleModel,
            layout: SM64FrontEndRenderLayout(width: 1920, height: 1080, aspectRatio: 16.0 / 9.0)
        )
        precondition(widescreen.commands.count == 74)
        precondition(widescreen.commands[23].x == 1840)

        var frontEnd = SM64FrontEndModel()
        _ = frontEnd.tick(SM64FrontEndInput(startPressed: true))
        _ = frontEnd.tick(SM64FrontEndInput(selectionDelta: -1))
        let filePacket = SM64FrontEndRenderPacket.project(frontEnd)
        precondition(filePacket.screen == .fileSelect)
        precondition(filePacket.commands.count == 10)
        precondition(filePacket.commands[9] == .cursor(x: 92, y: 105, selection: 4))

        _ = frontEnd.tick(SM64FrontEndInput(confirmPressed: true))
        let coursePacket = SM64FrontEndRenderPacket.project(frontEnd)
        precondition(coursePacket.commands.count == 2)
        precondition(coursePacket.commands[0] == .text(.course, x: 160, y: 35))
        precondition(coursePacket.commands[1] == .cursor(x: 160, y: 80, selection: 1))

        var demoFrontEnd = SM64FrontEndModel()
        for _ in 0..<800 { _ = demoFrontEnd.tick(SM64FrontEndInput()) }
        let demoPacket = SM64FrontEndRenderPacket.project(demoFrontEnd)
        precondition(demoPacket.screen == .demo)
        precondition(demoPacket.commands == [.text(.demo, x: 160, y: 30)])

        var fingerprint = record(fnvOffset, titlePacket)
        fingerprint = record(fingerprint, widescreen)
        fingerprint = record(fingerprint, filePacket)
        fingerprint = record(fingerprint, coursePacket)
        fingerprint = record(fingerprint, demoPacket)
        print("frontEndRenderFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern front-end render smoke passed")
    }
}
