import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func word(_ a: UInt8, _ b: UInt8, _ c: UInt8 = 0, _ d: UInt8 = 0) -> [UInt8] {
    [a, b, c, d, 0, 0, 0, 0]
}

private func pair(_ first: Int16, _ second: Int16) -> [UInt8] {
    let a = UInt16(bitPattern: first)
    let b = UInt16(bitPattern: second)
    return [
        UInt8(truncatingIfNeeded: a), UInt8(truncatingIfNeeded: a >> 8),
        UInt8(truncatingIfNeeded: b), UInt8(truncatingIfNeeded: b >> 8),
        0, 0, 0, 0,
    ]
}

private func pointer(_ raw: UInt64) -> [UInt8] {
    var value = raw
    var bytes = Array(repeating: UInt8(0), count: 8)
    for index in 0..<8 { bytes[index] = UInt8(truncatingIfNeeded: value); value >>= 8 }
    return bytes
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func hashSigned(_ initial: UInt64, _ value: Int16) -> UInt64 {
    hashU64(initial, UInt64(bitPattern: Int64(value)))
}

private func commandFingerprint(_ program: SM64GeoLayoutProgram) -> UInt64 {
    program.commands.reduce(fnvOffset) { hash, command in
        var result = hashU64(hash, UInt64(command.offset))
        result = hashU64(result, UInt64(command.opcode.rawValue))
        result = hashU64(result, UInt64(command.parameter))
        return hashU64(result, UInt64(command.byteLength))
    }
}

private func sceneFingerprint(_ scene: SM64GeoLayoutScene) -> UInt64 {
    var hash = fnvOffset
    hash = hashU64(hash, scene.root.map(UInt64.init) ?? UInt64.max)
    for node in scene.nodes {
        hash = hashU64(hash, UInt64(node.kind.rawValue))
        hash = hashU64(hash, node.parent.map(UInt64.init) ?? UInt64.max)
        hash = hashSigned(hash, node.flags)
        hash = hashU64(hash, UInt64(node.children.count))
        for child in node.children { hash = hashU64(hash, UInt64(child)) }
        switch node.payload {
        case let .root(numEntries, x, y, width, height):
            hash = hashU64(hash, 1)
            for value in [numEntries, x, y, width, height] { hash = hashSigned(hash, value) }
        case let .perspective(fov, near, far, function):
            hash = hashU64(hash, 2)
            for value in [fov, near, far] { hash = hashSigned(hash, value) }
            hash = hashU64(hash, function ?? 0)
        case let .camera(type, position, focus, function):
            hash = hashU64(hash, 3)
            hash = hashSigned(hash, type)
            for value in [position.x, position.y, position.z, focus.x, focus.y, focus.z] { hash = hashSigned(hash, value) }
            hash = hashU64(hash, function)
        case let .transform(layer, translation, rotation, displayList):
            hash = hashU64(hash, 4); hash = hashU64(hash, UInt64(layer))
            for value in [translation.x, translation.y, translation.z, rotation.x, rotation.y, rotation.z] { hash = hashSigned(hash, value) }
            hash = hashU64(hash, displayList ?? 0)
        case let .translation(layer, translation, displayList):
            hash = hashU64(hash, 5); hash = hashU64(hash, UInt64(layer))
            for value in [translation.x, translation.y, translation.z] { hash = hashSigned(hash, value) }
            hash = hashU64(hash, displayList ?? 0)
        case let .displayList(layer, address):
            hash = hashU64(hash, 6); hash = hashU64(hash, UInt64(layer)); hash = hashU64(hash, address)
        case let .scale(layer, fixedScale, displayList):
            hash = hashU64(hash, 7); hash = hashU64(hash, UInt64(layer)); hash = hashU64(hash, UInt64(fixedScale)); hash = hashU64(hash, displayList ?? 0)
        case let .shadow(type, solidity, scale):
            hash = hashU64(hash, 8); hash = hashU64(hash, UInt64(type)); hash = hashU64(hash, UInt64(solidity)); hash = hashSigned(hash, scale)
        default:
            hash = hashU64(hash, 0)
        }
    }
    hash = hashU64(hash, scene.views[0].map(UInt64.init) ?? UInt64.max)
    return hash
}

private func fixture() -> Data {
    var data = Data()
    // ROOT(2, 0, 0, 320, 240)
    data.append(contentsOf: word(0x08, 0x00, 0x02))
    data.append(contentsOf: pair(0, 0))
    data.append(contentsOf: pair(320, 240))
    // OPEN, PERSPECTIVE(60, 100, 1000), OPEN, CAMERA(...)
    data.append(contentsOf: word(0x04, 0x00))
    data.append(contentsOf: word(0x0a, 0x00, 60))
    data.append(contentsOf: pair(100, 1000))
    data.append(contentsOf: word(0x04, 0x00))
    data.append(contentsOf: word(0x0f, 0x00, 1))
    data.append(contentsOf: pair(10, 20))
    data.append(contentsOf: pair(30, 0))
    data.append(contentsOf: pair(100, 0))
    data.append(contentsOf: pointer(0))
    // CLOSE, TRANSLATE_ROTATE(layer 3), TRANSLATE_NODE(layer 2 with DL)
    data.append(contentsOf: word(0x05, 0x00))
    data.append(contentsOf: word(0x10, 0x03))
    data.append(contentsOf: pair(1, 2))
    data.append(contentsOf: pair(3, 4))
    data.append(contentsOf: pair(5, 6))
    data.append(contentsOf: word(0x11, 0x82, 7))
    data.append(contentsOf: pair(8, 9))
    data.append(contentsOf: pointer(0x0100_0020))
    // DISPLAY_LIST(layer 4), SCALE(layer 5, 1.5, display list), SHADOW(2, 200, 64)
    data.append(contentsOf: word(0x15, 0x04))
    data.append(contentsOf: pointer(0x0100_0030))
    data.append(contentsOf: word(0x1d, 0x85))
    data.append(contentsOf: word(0, 0x80, 0x01, 0))
    data.append(contentsOf: pointer(0x0100_0040))
    data.append(contentsOf: word(0x16, 0x00, 2))
    data.append(contentsOf: pair(200, 64))
    // CLOSE, UPDATE_FLAGS(SET, 0x1234), ASSIGN_VIEW(0), END
    data.append(contentsOf: word(0x05, 0x00))
    data.append(contentsOf: word(0x07, 0x01, 0x34, 0x12))
    data.append(contentsOf: word(0x06, 0x00))
    data.append(contentsOf: word(0x01, 0x00))
    return data
}

@main
enum SM64ModernGeoLayoutSmoke {
    static func main() throws {
        let program = try SM64GeoLayoutProgram(data: fixture())
        require(program.commands.map(\.offset) == [0, 24, 32, 48, 56, 96, 104, 136, 160, 176, 200, 216, 224, 232, 240], "geo command offsets")
        require(program.commands.map(\.byteLength) == [24, 8, 16, 8, 40, 8, 32, 24, 16, 24, 16, 8, 8, 8, 8], "geo command lengths")

        var builder = SM64GeoLayoutBuilder(program: program)
        let scene = try builder.build()
        require(scene.root == 0, "root node")
        require(scene.nodes.map(\.kind) == [.root, .perspective, .camera, .translationRotation, .translation, .displayList, .scale, .shadow], "node ordering")
        require(scene.nodes[0].children == [1, 3, 4, 5, 6, 7], "root child ordering")
        require(scene.nodes[1].children == [2], "perspective child ordering")
        require(scene.nodes[0].flags == 0x1234, "node flags")
        require(scene.views[0] == 0, "view registration")
        if case let .camera(type, position, focus, function) = scene.nodes[2].payload {
            require(type == 1 && position == SM64GeoVec3s(x: 10, y: 20, z: 30), "camera payload")
            require(focus == SM64GeoVec3s(x: 0, y: 100, z: 0) && function == 0, "camera focus payload")
        } else { preconditionFailure("camera payload kind") }
        if case let .scale(layer, fixedScale, displayList) = scene.nodes[6].payload {
            require(layer == 5 && fixedScale == 0x0001_8000 && displayList == 0x0100_0040, "scale payload")
        } else { preconditionFailure("scale payload kind") }
        require(scene.traces.count == program.commands.count, "geo trace count")
        print(String(format: "geoCommandFingerprint=0x%016llx", commandFingerprint(program)))
        print(String(format: "geoSceneFingerprint=0x%016llx", sceneFingerprint(scene)))
        print("SM64 Modern geo-layout smoke passed nodes=\(scene.nodes.count) commands=\(scene.traces.count)")
    }
}
