import Foundation
struct SM64SeaweedDescriptor: Equatable, Sendable { let faceAngles: SM64ObjectAngles; let scale: SM64ObjectVector3 }
enum SM64SeaweedBehavior {
    static let bundleDescriptors:[SM64SeaweedDescriptor]=[
        .init(faceAngles:.init(pitch:5500,yaw:14523,roll:9600),scale:.one),
        .init(faceAngles:.init(pitch:6102,yaw:41800,roll:0),scale:.init(x:0.8,y:0.9,z:0.8)),
        .init(faceAngles:.init(pitch:8700,yaw:40500,roll:4100),scale:.init(x:0.8,y:0.8,z:0.8)),
        .init(faceAngles:.init(pitch:9500,yaw:57236,roll:0),scale:.init(x:1.2,y:1.2,z:1.2))
    ]
}
