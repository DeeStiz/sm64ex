import Foundation
private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h(_ x:UInt64,_ v:UInt64)->UInt64{var x=x;for i in 0..<8{x^=(v>>UInt64(i*8))&0xff;x&*=fnvPrime};return x}
@main struct SM64WaterMist2Smoke{static func main(){let o=SM64WaterMist2Behavior.update(.init(homePosition:.init(x:10,y:0,z:20),waterLevel:100,randomOffsetX:-50,randomOffsetZ:25,randomOpacity:0.5));precondition(o.position == .init(x:-40,y:120,z:45)&&o.opacity==225);var f=fnvOffset;f=h(f,UInt64(o.position.x.bitPattern));f=h(f,UInt64(o.position.y.bitPattern));f=h(f,UInt64(o.position.z.bitPattern));f=h(f,UInt64(bitPattern:Int64(o.opacity)));print(String(format:"waterMist2Fingerprint=0x%016llx",f));print("SM64 Modern water mist 2 smoke passed")}}
