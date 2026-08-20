import Foundation
private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211
private func h(_ x: UInt64,_ v: UInt64)->UInt64{var x=x;for i in 0..<8{x^=(v>>UInt64(i*8))&0xff;x&*=fnvPrime};return x}
@main struct SM64WaterMistSmoke{static func main(){let o=SM64WaterMistBehavior.update(.init(position:.zero,moveYaw:0,forwardVelocity:20,velocityY:-8,opacity:254,timer:0,randomOffsetX:3,randomOffsetZ:-2));precondition(o.position == .init(x:23,y:-8,z:-2) && o.opacity == 212 && !o.shouldDelete);let q=Int32((o.scale*1000).rounded());var f=H;f=h(f,UInt64(bitPattern:Int64(o.opacity)));f=h(f,UInt64(bitPattern:Int64(q)));f=h(f,o.shouldDelete ? 1:0);print(String(format:"waterMistFingerprint=0x%016llx",f));print("SM64 Modern water mist smoke passed")}}
private let H: UInt64 = fnvOffset
