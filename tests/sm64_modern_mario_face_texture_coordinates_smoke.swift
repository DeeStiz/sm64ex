import Foundation

@main
struct SM64ModernMarioFaceTextureCoordinatesSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw NSError(domain: "MarioFaceTextureCoordinatesSmoke", code: 1)
        }
        let rootURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let traceURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
        let source = try SM64MarioFaceSourceGeometryProvider.load(rootURL: rootURL)
        guard let packet = SM64MarioFaceMetalTextureCoordinateBuilder.make(source: source) else {
            throw NSError(domain: "MarioFaceTextureCoordinatesSmoke", code: 2)
        }
        precondition(packet.schemaVersion == 1)
        precondition(packet.meshID == 1)
        precondition(packet.textureID == 0x300)
        precondition(packet.textureScaleS == 0x07C0 && packet.textureScaleT == 0x07C0)
        precondition(packet.hiliteOriginS == 64 && packet.hiliteOriginT == 64)
        precondition(packet.tileWidth == 32 && packet.tileHeight == 32)
        precondition(packet.vertices.count == 440)
        precondition(packet.vertices[0].sourceIndex == 0)
        precondition(packet.vertices.allSatisfy {
            $0.normalQ8.count == 3 && $0.generatedST.count == 2
        })
        precondition(packet.vertices.allSatisfy {
            (0...0x07C0).contains(Int($0.generatedST[0]))
                && (0...0x07C0).contains(Int($0.generatedST[1]))
        })
        let records = try SM64MarioFaceMetalTextureCoordinateOracle.records(packet: packet)
        precondition(records.count == 442)
        precondition(records.allSatisfy { $0.domain == 11 && $0.recordKind == 8 })
        let roundTrip = try records.map { try SM64OracleTraceRecord.decode($0.encoded()) }
        precondition(roundTrip == records)
        let configuration = SM64OracleTraceConfiguration(
            regionCode: 0x5553,
            mode: .record,
            buildFingerprint: 0x4d30_1701,
            contentFingerprint: 0x4d30_1702,
            timebaseFingerprint: 0x4d30_1703,
            configurationFingerprint: 0x4d30_1704,
            initialSaveFingerprint: 0x4d30_1705,
            coverageFingerprint: 0
        )
        try SM64OracleTraceFile.write(configuration: configuration, records: records, to: traceURL)
        print("marioFaceMetalTextureCoordinateVertices=\(packet.vertices.count)")
        print(String(format: "marioFaceMetalTextureCoordinateFingerprint=0x%016llx", packet.fingerprint))
        print(String(format: "marioFaceMetalTextureCoordinateTraceFingerprint=0x%016llx", SM64MarioFaceMetalTextureCoordinateOracle.fingerprint(records)))
        print("marioFaceMetalTextureCoordinateTraceRecords=\(records.count)")
        print("marioFaceMetalTextureCoordinateFirstNormal=\(packet.vertices[0].normalQ8.map(String.init).joined(separator: ":"))")
        print("marioFaceMetalTextureCoordinateFirstST=\(packet.vertices[0].generatedST.map(String.init).joined(separator: ":"))")
        print("SM64 Modern Mario-face exact texture-coordinate Swift trace passed")
    }
}
