import Foundation

@main
struct SM64ModernMarioFacePayloadInventorySmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else { throw NSError(domain: "PayloadInventorySmoke", code: 1) }
        let text = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
        let inventory = try SM64MarioFacePayloadInventory.parse(text)
        precondition(inventory.matchesManifest())
        precondition(inventory.rows.count == 50)
        precondition(inventory.rows.filter { $0.count == 0 }.count == 5)
        precondition(inventory.totalBytes == 160_668)
        precondition(inventory.rows.contains { $0.componentID == 0xE2 && $0.stride == 6 })
        precondition(inventory.rows.contains { $0.componentID == 0x07 && $0.stride == 3 })
        print("marioFacePayloadInventoryRows=\(inventory.rows.count)")
        print("marioFacePayloadInventoryBytes=\(inventory.totalBytes)")
        print(String(format: "marioFacePayloadInventoryFingerprint=0x%016llx", inventory.aggregateFingerprint))
        print("marioFacePayloadInventoryEmptyBanks=\(inventory.rows.filter { $0.count == 0 }.count)")
        print("SM64 Modern Mario face payload inventory smoke passed")
    }
}
