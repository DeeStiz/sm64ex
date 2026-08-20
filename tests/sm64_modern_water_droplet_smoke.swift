import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 { var h=initial;for i in 0..<8{h^=(value>>UInt64(i*8))&0xff;h&*=fnvPrime};return h }
private func hashF(_ initial: UInt64, _ value: Float) -> UInt64 { hashU64(initial, UInt64(value.bitPattern)) }
@main struct SM64WaterDropletSmoke {
    static func main() {
        let falling = SM64WaterDropletBehavior.update(.init(position: .zero, velocityY: 5, timer: 0, waterLevel: 100, interacted: false))
        let splash = SM64WaterDropletBehavior.update(.init(position: .init(x: 0, y: 0, z: 0), velocityY: -1, timer: 1, waterLevel: 100, interacted: false))
        let timeout = SM64WaterDropletBehavior.update(.init(position: .zero, velocityY: -1, timer: 21, waterLevel: -100, interacted: false))
        precondition(falling.position.y == 1 && falling.velocityY == 1 && !falling.shouldDelete)
        precondition(splash.shouldDelete && splash.spawnSplash && splash.position.y == -5)
        precondition(timeout.shouldDelete && !timeout.spawnSplash)
        var f=fnvOffset;for o in [falling,splash,timeout]{f=hashF(f,o.position.y);f=hashF(f,o.velocityY);f=hashU64(f,UInt64(bitPattern:Int64(o.timer)));f=hashU64(f,o.shouldDelete ? 1:0);f=hashU64(f,o.spawnSplash ? 1:0)}
        print(String(format:"waterDropletFingerprint=0x%016llx",f));print("SM64 Modern water droplet smoke passed")
    }
}
