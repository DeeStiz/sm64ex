import Foundation

@main
struct SM64ModernMarioFaceMetalBindingSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw NSError(domain: "MarioFaceMetalBindingSmoke", code: 1)
        }

        let routes = SM64MarioFaceRouteResourceCatalog.routes
        precondition(routes.map(\.routeID.rawValue) == Array(0..<6))
        var packets: [SM64MarioFaceMetalBindingPacket] = []
        packets.reserveCapacity(routes.count)
        var records: [SM64OracleTraceRecord] = []

        for (index, route) in routes.enumerated() {
            guard let packet = SM64MarioFaceMetalBindingPacketBuilder.make(routeID: route.routeID) else {
                throw NSError(domain: "MarioFaceMetalBindingSmoke", code: 2)
            }
            precondition(packet.route == route)
            precondition(packet.meshes.count == 6)
            precondition(packet.materialGroups.count == 6)
            precondition(packet.textures.count == route.textureIDs.count)
            precondition(packet.textures.allSatisfy {
                $0.usageFlags == SM64MarioFaceMetalBindingPacketBuilder.textureUsage
                    && $0.storageMode == .privateResource
                    && $0.residencyScope == .scene
                    && $0.encoderDomains == 5
                    && $0.uploadFormat == .rgba8Unorm
            })
            precondition(packet.meshes.allSatisfy {
                $0.usageFlags == SM64MarioFaceMetalBindingPacketBuilder.meshUsage
                    && $0.storageMode == .privateResource
                    && $0.residencyScope == .scene
                    && $0.encoderDomains == 2
            })
            precondition(packet.materialGroups.allSatisfy {
                $0.usageFlags == SM64MarioFaceMetalBindingPacketBuilder.materialUsage
                    && $0.storageMode == .privateResource
                    && $0.residencyScope == .scene
                    && $0.encoderDomains == 4
            })
            precondition(packet.ownerDomain == 1)
            precondition(packet.activeMeshMask == ((route.policyFlags & 1) != 0 ? 0x3f : 0))
            packets.append(packet)
            records.append(contentsOf: try SM64MarioFaceMetalBindingOracle.records(
                packet: packet, simulationTick: UInt64(index + 1)
            ))
        }

        precondition(packets[2].textures.count == 3)
        precondition(packets[2].textures.contains { $0.conversion == .ia8ToRGBA8 })
        precondition(packets[0].textures.count == 16)
        precondition(packets[4].textures.isEmpty)
        precondition(records.count == 122)
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)

        let output = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d30_1001,
            contentFingerprint: 0x4d30_1002,
            timebaseFingerprint: 0x4d30_1003,
            configurationFingerprint: 0x4d30_1004,
            initialSaveFingerprint: 0x4d30_1005,
            coverageFingerprint: 0
        )
        try SM64OracleTraceFile.write(configuration: configuration, records: records, to: output)

        print("marioFaceMetalBindingRouteCount=\(routes.count)")
        print("marioFaceMetalBindingTextureMemberships=\(packets.reduce(0) { $0 + $1.textures.count })")
        print("marioFaceMetalBindingMeshes=\(packets.reduce(0) { $0 + $1.meshes.count })")
        print("marioFaceMetalBindingMaterials=\(packets.reduce(0) { $0 + $1.materialGroups.count })")
        print("marioFaceMetalBindingRecords=\(records.count)")
        print(String(format: "marioFaceMetalBindingResourceFingerprint=0x%016llx", packets[0].resourceFingerprint))
        print(String(format: "marioFaceMetalBindingMarioFingerprint=0x%016llx", packets[2].bindingFingerprint))
        print(String(format: "marioFaceMetalBindingTraceFingerprint=0x%016llx", SM64MarioFaceMetalBindingOracle.fingerprint(records)))
        print("SM64 Modern Mario-face Metal binding Swift trace passed path=\(output.path)")
    }
}
