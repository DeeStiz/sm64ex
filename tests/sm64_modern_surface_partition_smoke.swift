import Foundation

private let fnvOffset: UInt64 = 1_469_598_103_934_665_603
private let fnvPrime: UInt64 = 1_099_511_628_211

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

private func hashU64(_ initial: UInt64, _ value: UInt64) -> UInt64 {
    var hash = initial
    for byte in 0..<8 {
        hash ^= (value >> UInt64(byte * 8)) & 0xff
        hash &*= fnvPrime
    }
    return hash
}

private func floor(id: UInt32, y: Int16) -> SM64Surface {
    SM64Surface(
        id: id,
        vertex1: SM64SurfaceVec3s(x: -100, y: y, z: -100),
        vertex2: SM64SurfaceVec3s(x: -100, y: y, z: 100),
        vertex3: SM64SurfaceVec3s(x: 100, y: y, z: -100),
        normal: SM64SurfaceVec3f(x: 0, y: 1, z: 0),
        originOffset: -Float(y)
    )
}

@main
enum SM64ModernSurfacePartitionSmoke {
    static func main() {
        let surfaces = [floor(id: 1, y: 0), floor(id: 2, y: 100)]
        let ceiling = SM64Surface(
            id: 3,
            vertex1: SM64SurfaceVec3s(x: -100, y: 200, z: -100),
            vertex2: SM64SurfaceVec3s(x: -100, y: 200, z: 100),
            vertex3: SM64SurfaceVec3s(x: 100, y: 200, z: -100),
            normal: SM64SurfaceVec3f(x: 0, y: -1, z: 0),
            originOffset: 200
        )
        let wall = SM64Surface(
            id: 4,
            flags: SM64SurfaceCollisionWorld.xProjectionFlag,
            vertex1: SM64SurfaceVec3s(x: 0, y: -100, z: -100),
            vertex2: SM64SurfaceVec3s(x: 0, y: 100, z: -100),
            vertex3: SM64SurfaceVec3s(x: 0, y: 100, z: 100),
            normal: SM64SurfaceVec3f(x: 1, y: 0, z: 0),
            originOffset: 0
        )
        var grid = SM64SurfacePartitionGrid(
            staticSurfaces: surfaces + [ceiling, wall],
            dynamicSurfaces: [floor(id: 5, y: 50)]
        )
        require(grid.cell(x: 7, z: 7).floors == [2, 1], "floor priority ordering")
        require(grid.cell(x: 8, z: 8).ceilings == [3], "ceiling cell")
        require(grid.cell(x: 7, z: 7).walls == [4], "wall cell")
        require(grid.cell(x: 7, z: 7, dynamic: true).floors == [5], "dynamic cell")
        require(SM64SurfacePartitionGrid.lowerCellIndex(-8192) == 0, "lower boundary clamp")
        require(SM64SurfacePartitionGrid.upperCellIndex(8191) == 15, "upper boundary clamp")
        grid.clearDynamic()
        require(grid.cell(x: 7, z: 7, dynamic: true).floors.isEmpty, "dynamic reset")

        var fingerprint = fnvOffset
        for cell in [grid.cell(x: 7, z: 7), grid.cell(x: 8, z: 8)] {
            for id in cell.floors + cell.ceilings + cell.walls {
                fingerprint = hashU64(fingerprint, UInt64(id))
            }
        }
        fingerprint = hashU64(fingerprint, UInt64(grid.cell(x: 7, z: 7, dynamic: true).floors.count))
        fingerprint = hashU64(fingerprint, UInt64(SM64SurfacePartitionGrid.lowerCellIndex(-8192)))
        fingerprint = hashU64(fingerprint, UInt64(SM64SurfacePartitionGrid.upperCellIndex(8191)))
        print(String(format: "surfacePartitionFingerprint=0x%016llx", fingerprint))
        print("SM64 Modern surface partition smoke passed")
    }
}
