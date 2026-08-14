import Foundation

struct SM64SurfacePartitionCell: Equatable, Sendable {
    var floors: [UInt32] = []
    var ceilings: [UInt32] = []
    var walls: [UInt32] = []
}

/// The 16x16 spatial partition contract used by the C loader. Cells retain
/// duplicate surface references when a triangle crosses cell boundaries; IDs
/// are stable and the per-list insertion ordering is deterministic.
struct SM64SurfacePartitionGrid: Equatable, Sendable {
    static let dimension = 16
    static let cellSize: Int32 = 0x400
    static let boundary: Int32 = 0x2000
    static let edgeBuffer: Int32 = 50

    private(set) var staticCells: [SM64SurfacePartitionCell]
    private(set) var dynamicCells: [SM64SurfacePartitionCell]
    private var priorities: [UInt32: Int] = [:]

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.staticCells == rhs.staticCells && lhs.dynamicCells == rhs.dynamicCells
    }

    init(staticSurfaces: [SM64Surface] = [], dynamicSurfaces: [SM64Surface] = []) {
        self.staticCells = Array(repeating: SM64SurfacePartitionCell(), count: Self.dimension * Self.dimension)
        self.dynamicCells = Array(repeating: SM64SurfacePartitionCell(), count: Self.dimension * Self.dimension)
        for surface in staticSurfaces { add(surface, dynamic: false) }
        for surface in dynamicSurfaces { add(surface, dynamic: true) }
    }

    mutating func clearDynamic() {
        dynamicCells = Array(repeating: SM64SurfacePartitionCell(), count: Self.dimension * Self.dimension)
    }

    func cell(x: Int, z: Int, dynamic: Bool = false) -> SM64SurfacePartitionCell {
        let clampedX = max(0, min(Self.dimension - 1, x))
        let clampedZ = max(0, min(Self.dimension - 1, z))
        return (dynamic ? dynamicCells : staticCells)[clampedZ * Self.dimension + clampedX]
    }

    static func lowerCellIndex(_ coordinate: Int16) -> Int {
        var shifted = Int32(coordinate) + boundary
        if shifted < 0 { shifted = 0 }
        var index = Int(shifted / cellSize)
        if shifted % cellSize < edgeBuffer { index -= 1 }
        return max(0, index)
    }

    static func upperCellIndex(_ coordinate: Int16) -> Int {
        var shifted = Int32(coordinate) + boundary
        if shifted < 0 { shifted = 0 }
        var index = Int(shifted / cellSize)
        if shifted % cellSize > cellSize - edgeBuffer { index += 1 }
        return min(Self.dimension - 1, index)
    }

    private mutating func add(_ surface: SM64Surface, dynamic: Bool) {
        let xs = [surface.vertex1.x, surface.vertex2.x, surface.vertex3.x]
        let zs = [surface.vertex1.z, surface.vertex2.z, surface.vertex3.z]
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minZ = zs.min() ?? 0
        let maxZ = zs.max() ?? 0
        let minCellX = Self.lowerCellIndex(minX)
        let maxCellX = Self.upperCellIndex(maxX)
        let minCellZ = Self.lowerCellIndex(minZ)
        let maxCellZ = Self.upperCellIndex(maxZ)
        for z in minCellZ...maxCellZ {
            for x in minCellX...maxCellX {
                let index = z * Self.dimension + x
                if surface.normal.y > 0.01 {
                    priorities[surface.id] = Int(surface.vertex1.y)
                    if dynamic { Self.insert(surface.id, into: &dynamicCells[index].floors, priorities: priorities) }
                    else { Self.insert(surface.id, into: &staticCells[index].floors, priorities: priorities) }
                } else if surface.normal.y < -0.01 {
                    priorities[surface.id] = -Int(surface.vertex1.y)
                    if dynamic { Self.insert(surface.id, into: &dynamicCells[index].ceilings, priorities: priorities) }
                    else { Self.insert(surface.id, into: &staticCells[index].ceilings, priorities: priorities) }
                } else {
                    priorities[surface.id] = 0
                    if dynamic { dynamicCells[index].walls.append(surface.id) }
                    else { staticCells[index].walls.append(surface.id) }
                }
            }
        }
    }

    private static func insert(_ id: UInt32, into values: inout [UInt32], priorities: [UInt32: Int]) {
        // C inserts before the first strictly lower priority, preserving
        // source order for equal priorities.
        var index = values.count
        let priority = priorities[id] ?? 0
        for (candidateIndex, candidate) in values.enumerated()
            where priority > (priorities[candidate] ?? 0) {
            index = candidateIndex
            break
        }
        values.insert(id, at: index)
    }
}
