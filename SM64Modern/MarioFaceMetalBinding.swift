import Foundation

/// Value-only descriptions of the Metal 4 resources needed by a Goddard face
/// route.  These raw values deliberately describe the production renderer's
/// contract without importing Metal or crossing an `MTL*` handle between
/// owner/display threads.
enum SM64MarioFaceMetalStorageMode: UInt32, Sendable {
    case privateResource = 1
    case sharedUpload = 2
}

enum SM64MarioFaceMetalResidencyScope: UInt32, Sendable {
    case scene = 1
    case frame = 2
}

enum SM64MarioFaceMetalEncoderDomain: UInt32, Sendable {
    case uploadCompute = 1
    case vertexRender = 2
    case fragmentRender = 4
}

enum SM64MarioFaceMetalUploadFormat: UInt32, Sendable {
    /// The current Metal 4 leaf accepts RGBA8 private textures. Source
    /// Goddard RGBA16 and IA8 bytes therefore carry an explicit conversion
    /// policy instead of being silently treated as RGBA8 source bytes.
    case rgba8Unorm = 1
}

enum SM64MarioFaceMetalSourceConversion: UInt32, Sendable {
    case rgba16ToRGBA8 = 1
    case ia8ToRGBA8 = 2
}

enum SM64MarioFaceMetalSamplerFilter: UInt32, Sendable {
    case nearest = 0
    case linear = 1
}

enum SM64MarioFaceMetalSamplerAddress: UInt32, Sendable {
    case repeatMode = 0
    case mirrorRepeat = 1
    case clampToEdge = 2
}

enum SM64MarioFaceMetalResourceUsage {
    static let fragmentRead: UInt32 = 1 << 0
    static let vertexRead: UInt32 = 1 << 1
    static let copySource: UInt32 = 1 << 2
    static let copyDestination: UInt32 = 1 << 3
    static let constantRead: UInt32 = 1 << 4
}

struct SM64MarioFaceMetalSamplerBinding: Equatable, Sendable {
    let filter: SM64MarioFaceMetalSamplerFilter
    let addressS: SM64MarioFaceMetalSamplerAddress
    let addressT: SM64MarioFaceMetalSamplerAddress

    var packed: UInt32 {
        filter.rawValue | (addressS.rawValue << 8) | (addressT.rawValue << 16)
    }
}

struct SM64MarioFaceMetalTextureBinding: Equatable, Sendable {
    let textureID: UInt32
    let sourceFormat: SM64MarioFaceTextureFormat
    let sourceBitsPerTexel: UInt32
    let uploadFormat: SM64MarioFaceMetalUploadFormat
    let conversion: SM64MarioFaceMetalSourceConversion
    let width: UInt32
    let height: UInt32
    let frameIndex: UInt32
    let family: SM64MarioFaceTextureFamily
    let sampler: SM64MarioFaceMetalSamplerBinding
    let usageFlags: UInt32
    let storageMode: SM64MarioFaceMetalStorageMode
    let residencyScope: SM64MarioFaceMetalResidencyScope
    let encoderDomains: UInt32

    var formatCode: UInt32 {
        sourceFormat.rawValue
            | (sourceBitsPerTexel << 8)
            | (uploadFormat.rawValue << 16)
            | (conversion.rawValue << 24)
    }

    var dimensionsCode: UInt32 { width | (height << 16) }

    var identityCode: UInt32 { family.rawValue | (frameIndex << 8) }

    var policyCode: UInt32 {
        usageFlags
            | (storageMode.rawValue << 8)
            | (residencyScope.rawValue << 12)
            | (encoderDomains << 16)
    }
}

struct SM64MarioFaceMetalMeshBinding: Equatable, Sendable {
    let meshID: UInt32
    let vertexGroupID: UInt32
    let planeGroupID: UInt32
    let materialGroupID: UInt32
    let shapeID: UInt32
    let vertexCount: UInt32
    let faceCount: UInt32
    let materialCount: UInt32
    let usageFlags: UInt32
    let storageMode: SM64MarioFaceMetalStorageMode
    let residencyScope: SM64MarioFaceMetalResidencyScope
    let encoderDomains: UInt32

    var policyCode: UInt32 {
        (materialCount & 0xff)
            | (usageFlags << 8)
            | (storageMode.rawValue << 16)
            | (residencyScope.rawValue << 20)
            | (encoderDomains << 24)
    }
}

struct SM64MarioFaceMetalMaterialGroupBinding: Equatable, Sendable {
    let meshID: UInt32
    let materialGroupID: UInt32
    let materialCount: UInt32
    let usageFlags: UInt32
    let storageMode: SM64MarioFaceMetalStorageMode
    let residencyScope: SM64MarioFaceMetalResidencyScope
    let encoderDomains: UInt32

    var policyCode: UInt32 {
        (materialCount & 0xff)
            | (usageFlags << 8)
            | (storageMode.rawValue << 16)
            | (residencyScope.rawValue << 20)
            | (encoderDomains << 24)
    }
}

struct SM64MarioFaceMetalBindingPacket: Equatable, Sendable {
    let route: SM64MarioFaceRouteRecord
    let textures: [SM64MarioFaceMetalTextureBinding]
    let meshes: [SM64MarioFaceMetalMeshBinding]
    let materialGroups: [SM64MarioFaceMetalMaterialGroupBinding]
    let activeMeshMask: UInt64
    let ownerDomain: UInt32
    let resourceFingerprint: UInt64
    let bindingFingerprint: UInt64
}

enum SM64MarioFaceMetalBindingPacketBuilder {
    static let ownerDomain: UInt32 = 1 // dedicated engine-owner/display admission
    static let textureUsage: UInt32 = SM64MarioFaceMetalResourceUsage.fragmentRead
        | SM64MarioFaceMetalResourceUsage.copyDestination
    static let meshUsage: UInt32 = SM64MarioFaceMetalResourceUsage.vertexRead
    static let materialUsage: UInt32 = SM64MarioFaceMetalResourceUsage.fragmentRead
        | SM64MarioFaceMetalResourceUsage.constantRead
    static let sceneResidency: SM64MarioFaceMetalResidencyScope = .scene
    static let privateStorage: SM64MarioFaceMetalStorageMode = .privateResource
    static let uploadStorage: SM64MarioFaceMetalStorageMode = .sharedUpload

    static func make(routeID: SM64MarioFaceGoddardRouteID) -> SM64MarioFaceMetalBindingPacket? {
        guard let route = SM64MarioFaceRouteResourceCatalog.route(routeID) else { return nil }
        let textures = route.textureIDs.compactMap { textureID -> SM64MarioFaceMetalTextureBinding? in
            guard let resource = SM64MarioFaceRouteResourceCatalog.texture(textureID) else {
                return nil
            }
            let conversion: SM64MarioFaceMetalSourceConversion = resource.format == .rgba16
                ? .rgba16ToRGBA8 : .ia8ToRGBA8
            let filter: SM64MarioFaceMetalSamplerFilter = resource.policyFlags & 0b010 != 0
                ? .linear : .nearest
            let address: SM64MarioFaceMetalSamplerAddress = resource.policyFlags & 0b100 != 0
                ? .repeatMode : .clampToEdge
            return SM64MarioFaceMetalTextureBinding(
                textureID: resource.textureID,
                sourceFormat: resource.format,
                sourceBitsPerTexel: resource.bitsPerTexel,
                uploadFormat: .rgba8Unorm,
                conversion: conversion,
                width: resource.width,
                height: resource.height,
                frameIndex: resource.frameIndex,
                family: resource.family,
                sampler: SM64MarioFaceMetalSamplerBinding(
                    filter: filter, addressS: address, addressT: address
                ),
                usageFlags: textureUsage,
                storageMode: privateStorage,
                residencyScope: sceneResidency,
                encoderDomains: SM64MarioFaceMetalEncoderDomain.uploadCompute.rawValue
                    | SM64MarioFaceMetalEncoderDomain.fragmentRender.rawValue
            )
        }
        guard textures.count == route.textureIDs.count else { return nil }

        let meshes = SM64MarioFaceResourceCatalog.meshes.map { mesh in
            SM64MarioFaceMetalMeshBinding(
                meshID: mesh.meshID,
                vertexGroupID: mesh.vertexGroupID,
                planeGroupID: mesh.planeGroupID,
                materialGroupID: mesh.materialGroupID,
                shapeID: mesh.shapeID,
                vertexCount: mesh.vertexCount,
                faceCount: mesh.faceCount,
                materialCount: mesh.materialCount,
                usageFlags: meshUsage,
                storageMode: privateStorage,
                residencyScope: sceneResidency,
                encoderDomains: SM64MarioFaceMetalEncoderDomain.vertexRender.rawValue
            )
        }
        let materialGroups = meshes.map { mesh in
            SM64MarioFaceMetalMaterialGroupBinding(
                meshID: mesh.meshID,
                materialGroupID: mesh.materialGroupID,
                materialCount: mesh.materialCount,
                usageFlags: materialUsage,
                storageMode: privateStorage,
                residencyScope: sceneResidency,
                encoderDomains: SM64MarioFaceMetalEncoderDomain.fragmentRender.rawValue
            )
        }
        let activeMeshMask: UInt64 = route.policyFlags & 1 != 0 ? 0x3f : 0
        let resourceFingerprint = SM64MarioFaceMetalBindingFingerprint.resources()
        let bindingFingerprint = SM64MarioFaceMetalBindingFingerprint.packet(
            route: route, textures: textures, meshes: meshes,
            materialGroups: materialGroups, activeMeshMask: activeMeshMask,
            ownerDomain: ownerDomain, resourceFingerprint: resourceFingerprint
        )
        return SM64MarioFaceMetalBindingPacket(
            route: route, textures: textures, meshes: meshes,
            materialGroups: materialGroups, activeMeshMask: activeMeshMask,
            ownerDomain: ownerDomain, resourceFingerprint: resourceFingerprint,
            bindingFingerprint: bindingFingerprint
        )
    }
}

enum SM64MarioFaceMetalBindingFingerprint {
    static let offset: UInt64 = 1_469_598_103_934_665_603
    static let prime: UInt64 = 1_099_511_628_211

    private static func hash(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xff
            result &*= prime
        }
        return result
    }

    private static func hash(_ initial: UInt64, _ value: UInt32) -> UInt64 {
        hash(initial, UInt64(value))
    }

    private static func hash(_ initial: UInt64, _ values: [UInt32]) -> UInt64 {
        values.reduce(initial) { hash($0, $1) }
    }

    static func resources() -> UInt64 {
        var result = hash(offset, SM64MarioFaceRouteResourceFingerprint.catalog())
        result = hash(result, SM64MarioFaceResourceCatalogFingerprint.catalog())
        result = hash(result, [
            SM64MarioFaceMetalBindingPacketBuilder.ownerDomain,
            SM64MarioFaceMetalBindingPacketBuilder.textureUsage,
            SM64MarioFaceMetalBindingPacketBuilder.meshUsage,
            SM64MarioFaceMetalBindingPacketBuilder.materialUsage,
            SM64MarioFaceMetalBindingPacketBuilder.sceneResidency.rawValue,
            SM64MarioFaceMetalBindingPacketBuilder.privateStorage.rawValue,
            SM64MarioFaceMetalBindingPacketBuilder.uploadStorage.rawValue,
        ])
        return result
    }

    static func packet(
        route: SM64MarioFaceRouteRecord,
        textures: [SM64MarioFaceMetalTextureBinding],
        meshes: [SM64MarioFaceMetalMeshBinding],
        materialGroups: [SM64MarioFaceMetalMaterialGroupBinding],
        activeMeshMask: UInt64,
        ownerDomain: UInt32,
        resourceFingerprint: UInt64
    ) -> UInt64 {
        var result = hash(offset, resourceFingerprint)
        result = hash(result, [
            route.routeID.rawValue, route.displayListID,
            route.updateDomain.rawValue, route.policyFlags,
            UInt32(truncatingIfNeeded: activeMeshMask),
            UInt32(truncatingIfNeeded: activeMeshMask >> 32),
            ownerDomain, UInt32(textures.count), UInt32(meshes.count),
            UInt32(materialGroups.count),
        ])
        for texture in textures {
            result = hash(result, [
                texture.textureID, texture.formatCode, texture.dimensionsCode,
                texture.identityCode, texture.sampler.packed, texture.policyCode,
            ])
        }
        for mesh in meshes {
            result = hash(result, [
                mesh.meshID, mesh.vertexGroupID, mesh.planeGroupID,
                mesh.materialGroupID, mesh.shapeID, mesh.vertexCount,
                mesh.faceCount, mesh.policyCode,
            ])
        }
        for material in materialGroups {
            result = hash(result, [
                material.meshID, material.materialGroupID, material.policyCode,
            ])
        }
        return result
    }
}

/// Schema-4 records for the value-only Metal binding packet. Record kind `8`
/// is intentionally distinct from M30m/M30n route metadata and live event `5`.
enum SM64MarioFaceMetalBindingOracle {
    static let domain: UInt32 = 11
    static let recordKind: UInt32 = 8
    static let headerRecordBase: UInt64 = 0x4d46_5800
    static let digestRecordBase: UInt64 = 0x4d46_5900
    static let textureRecordBase: UInt64 = 0x4d46_5a00
    static let meshRecordBase: UInt64 = 0x4d46_5b00
    static let materialRecordBase: UInt64 = 0x4d46_5c00

    static func records(
        packet: SM64MarioFaceMetalBindingPacket,
        simulationTick: UInt64,
        sequenceStart: UInt32 = 0
    ) throws -> [SM64OracleTraceRecord] {
        var sequence = sequenceStart
        let subject = UInt64(packet.route.routeID.rawValue)
        var records = [try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: subject,
            recordID: headerRecordBase | subject, sequence: sequence,
            values: [
                subject, UInt64(packet.route.displayListID),
                UInt64(packet.route.updateDomain.rawValue), UInt64(packet.route.policyFlags),
                packet.activeMeshMask, UInt64(packet.textures.count),
                UInt64(packet.meshes.count), UInt64(packet.materialGroups.count),
            ]
        )]
        sequence &+= 1
        records.append(try SM64OracleTraceRecord(
            simulationTick: simulationTick, domain: domain, recordKind: recordKind,
            subjectID: subject,
            recordID: digestRecordBase | subject, sequence: sequence,
            values: [
                packet.resourceFingerprint, packet.bindingFingerprint,
                UInt64(SM64MarioFaceMetalBindingPacketBuilder.textureUsage),
                UInt64(SM64MarioFaceMetalBindingPacketBuilder.meshUsage),
                UInt64(SM64MarioFaceMetalBindingPacketBuilder.materialUsage),
                packet.activeMeshMask, UInt64(packet.ownerDomain), subject,
            ]
        ))
        sequence &+= 1

        for texture in packet.textures {
            records.append(try SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: subject,
                recordID: textureRecordBase | UInt64(texture.textureID), sequence: sequence,
                values: [
                    UInt64(texture.textureID), UInt64(texture.formatCode),
                    UInt64(texture.dimensionsCode), UInt64(texture.identityCode),
                    UInt64(texture.sampler.packed), UInt64(texture.policyCode),
                ]
            ))
            sequence &+= 1
        }
        for mesh in packet.meshes {
            records.append(try SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: subject,
                recordID: meshRecordBase | UInt64(mesh.meshID), sequence: sequence,
                values: [
                    UInt64(mesh.meshID), UInt64(mesh.vertexGroupID),
                    UInt64(mesh.planeGroupID), UInt64(mesh.materialGroupID),
                    UInt64(mesh.shapeID), UInt64(mesh.vertexCount),
                    UInt64(mesh.faceCount), UInt64(mesh.policyCode),
                ]
            ))
            sequence &+= 1
        }
        for material in packet.materialGroups {
            records.append(try SM64OracleTraceRecord(
                simulationTick: simulationTick, domain: domain, recordKind: recordKind,
                subjectID: subject,
                recordID: materialRecordBase | UInt64(material.meshID), sequence: sequence,
                values: [
                    UInt64(material.meshID), UInt64(material.materialGroupID),
                    UInt64(material.policyCode),
                ]
            ))
            sequence &+= 1
        }
        return records
    }

    static func fingerprint(_ records: [SM64OracleTraceRecord]) -> UInt64 {
        var result = SM64OracleTraceHash.offset
        result = update(result, UInt64(records.count))
        for record in records { result = update(result, record.canonicalHash) }
        return result
    }

    private static func update(_ initial: UInt64, _ value: UInt64) -> UInt64 {
        var result = initial
        for byte in 0..<8 {
            result ^= (value >> UInt64(byte * 8)) & 0xff
            result &*= SM64OracleTraceHash.prime
        }
        return result
    }
}
