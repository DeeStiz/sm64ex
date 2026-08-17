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

private func hashBool(_ hash: UInt64, _ value: Bool) -> UInt64 {
    hashU32(hash, value ? 1 : 0)
}

private func record(_ hash: UInt64, _ packet: SM64HUDRenderPacket) -> UInt64 {
    var result = hash
    result = hashU32(result, UInt32(bitPattern: packet.layout.screenWidth))
    result = hashU32(result, UInt32(bitPattern: packet.layout.screenHeight))
    result = hashBool(result, packet.layout.japanese)
    result = hashU32(result, UInt32(packet.commands.count))
    for command in packet.commands {
        result = hashU32(result, UInt32(command.kind.rawValue))
        result = hashU32(result, UInt32(bitPattern: Int32(command.glyph)))
        result = hashU32(result, UInt32(bitPattern: command.x))
        result = hashU32(result, UInt32(bitPattern: command.y))
        result = hashU32(result, UInt32(bitPattern: command.width))
        result = hashU32(result, UInt32(bitPattern: command.height))
        result = hashU32(result, UInt32(bitPattern: command.advance))
        result = hashU32(result, UInt32(bitPattern: Int32(command.healthWedges)))
    }
    return result
}

@main
enum SM64ModernHUDRenderSmoke {
    static func main() {
        var power = SM64PowerMeterState()
        var fingerprint = fnvOffset
        let flags: SM64HUDDisplayFlags = [
            .lives, .coinCount, .starCount, .cameraAndPower, .keys, .timer
        ]

        let full = SM64HUDProjection.project(
            SM64HUDInput(
                flags: flags, lives: 4, coins: 23, stars: 99, keys: 1,
                timer: 1_857, healthWedges: 6
            ), powerMeter: &power
        )
        let fullPacket = SM64HUDRenderPacket.project(full, keys: 1)
        precondition(fullPacket.commands.count == 24)
        precondition(fullPacket.commands[0] == .glyph(52, x: 22, y: 209))
        precondition(fullPacket.commands[2] == .glyph(4, x: 54, y: 209))
        precondition(fullPacket.commands[7] == .glyph(53, x: 242, y: 209))
        precondition(fullPacket.commands.contains {
            $0.kind == .powerMeterBase && $0.x == 108 && $0.y == 134
        })
        precondition(fullPacket.commands.contains {
            $0.kind == .powerMeterHealth && $0.healthWedges == 6
        })
        fingerprint = record(fingerprint, fullPacket)

        let flashing = SM64HUDProjection.project(
            SM64HUDInput(
                flags: [.starCount], stars: 100, timer: 1_857,
                hudFlash: true, globalTimer: 8
            ), powerMeter: &power
        )
        let flashingPacket = SM64HUDRenderPacket.project(flashing)
        precondition(flashingPacket.commands.isEmpty)
        fingerprint = record(fingerprint, flashingPacket)

        let damaged = SM64HUDProjection.project(
            SM64HUDInput(
                flags: [.cameraAndPower], healthWedges: 6
            ), powerMeter: &power
        )
        let damagedPacket = SM64HUDRenderPacket.project(damaged)
        precondition(damagedPacket.commands.count == 2)
        precondition(damagedPacket.commands[0].kind == .powerMeterBase)
        precondition(damagedPacket.commands[1].healthWedges == 6)
        fingerprint = record(fingerprint, damagedPacket)

        let timer = SM64HUDProjection.project(
            SM64HUDInput(flags: [.timer], timer: 1_857), powerMeter: &power
        )
        let timerPacket = SM64HUDRenderPacket.project(timer)
        precondition(timerPacket.commands.count == 10)
        precondition(timerPacket.commands[0] == .glyph(29, x: 170, y: 185))
        precondition(timerPacket.commands[4] == .glyph(1, x: 229, y: 185))
        precondition(timerPacket.commands[8] == .glyph(56, x: 239, y: 32))
        fingerprint = record(fingerprint, timerPacket)

        let japanese = SM64HUDRenderPacket.project(
            full,
            keys: 1,
            layout: SM64HUDLayout(japanese: true)
        )
        precondition(japanese.commands.contains { $0.x == 247 && $0.y == 210 })
        fingerprint = record(fingerprint, japanese)

        print("hudRenderFingerprint=0x\(String(fingerprint, radix: 16))")
        print("SM64 Modern HUD render smoke passed")
    }
}
