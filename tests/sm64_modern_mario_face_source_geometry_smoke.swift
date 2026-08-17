import Foundation

@main
struct SM64ModernMarioFaceSourceGeometrySmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw NSError(domain: "MarioFaceSourceGeometrySmoke", code: 1)
        }
        let rootURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let traceURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
        let packet = SM64MarioFaceSourceGeometry.packet
        precondition(packet.sourcePath == "src/goddard/dynlists/dynlist_mario_face.c")
        precondition(packet.sourceVertexCount == 440)
        precondition(packet.sourceFaceCount == 877)
        precondition(packet.sourceMaterialCount == 8)
        precondition(packet.faceWindowStart == 0)
        precondition(packet.triangles.count == 6)
        precondition(packet.materials == [
            SM64MarioFaceSourceMaterial(
                materialGroupID: 0xE0,
                materialID: 0,
                ambientRGB1000: [1000, 1000, 1000],
                diffuseRGB1000: [1000, 1000, 1000]
            ),
        ])
        let floats = packet.debugMetalVertexFloats()
        precondition(floats.count == packet.triangles.count * 3 * 7)
        precondition(floats[0..<4].elementsEqual([115.0 / 1024.0, -178.0 / 1024.0, 351.0 / 2048.0, 1.0]))

        let records = try SM64MarioFaceSourceGeometryOracle.records(packet: packet)
        precondition(records.count == 4)
        precondition(records.map(\.recordID) == [
            SM64MarioFaceSourceGeometryOracle.headerRecordID,
            SM64MarioFaceSourceGeometryOracle.digestRecordID,
            SM64MarioFaceSourceGeometryOracle.packetRecordID,
            SM64MarioFaceSourceGeometryOracle.materialRecordID,
        ])
        precondition(records.allSatisfy { $0.domain == 11 && $0.recordKind == 8 })
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)

        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d30_1401,
            contentFingerprint: 0x4d30_1402,
            timebaseFingerprint: 0x4d30_1403,
            configurationFingerprint: 0x4d30_1404,
            initialSaveFingerprint: 0x4d30_1405,
            coverageFingerprint: 0
        )
        try SM64OracleTraceFile.write(configuration: configuration, records: records, to: traceURL)

        print("marioFaceSourceGeometryMeshID=\(packet.meshID)")
        print("marioFaceSourceGeometrySourceVertices=\(packet.sourceVertexCount)")
        print("marioFaceSourceGeometrySourceFaces=\(packet.sourceFaceCount)")
        print("marioFaceSourceGeometrySourceMaterials=\(packet.sourceMaterialCount)")
        print("marioFaceSourceGeometryWindowVertices=\(packet.vertices.count)")
        print("marioFaceSourceGeometryWindowFaces=\(packet.triangles.count)")
        print("marioFaceSourceGeometryMaterialID=\(packet.materials[0].materialID)")
        print(String(format: "marioFaceSourceGeometryPacketFingerprint=0x%016llx", SM64MarioFaceSourceGeometryFingerprint.packet(packet)))
        print(String(format: "marioFaceSourceGeometryTraceFingerprint=0x%016llx", SM64MarioFaceSourceGeometryOracle.fingerprint(records)))
        print("marioFaceSourceGeometryMetalFloats=\(floats.count)")
        let fullPacket = try SM64MarioFaceSourceGeometryProvider.load(rootURL: rootURL)
        precondition(fullPacket.schemaVersion == 2)
        precondition(fullPacket.vertices.count == 440)
        precondition(fullPacket.triangles.count == 877)
        precondition(fullPacket.materials.count == 8)
        precondition(fullPacket.triangles[0] == packet.triangles[0])
        let fullFloats = fullPacket.debugMetalVertexFloats()
        precondition(fullFloats.count == 877 * 3 * 7)
        print("marioFaceSourceGeometryFullVertices=\(fullPacket.vertices.count)")
        print("marioFaceSourceGeometryFullFaces=\(fullPacket.triangles.count)")
        print("marioFaceSourceGeometryFullMaterials=\(fullPacket.materials.count)")
        print(String(format: "marioFaceSourceGeometryFullPacketFingerprint=0x%016llx", SM64MarioFaceSourceGeometryFingerprint.packet(fullPacket)))
        print("marioFaceSourceGeometryFullMetalFloats=\(fullFloats.count)")
        print("SM64 Modern Mario-face source geometry Swift trace passed path=\(traceURL.path)")
    }
}
