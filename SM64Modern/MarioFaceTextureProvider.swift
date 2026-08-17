import CoreGraphics
import Foundation
import ImageIO

enum SM64MarioFaceTextureProviderError: Error, Equatable {
    case missingSource(URL)
    case unreadableSource(URL)
    case invalidDimensions(textureID: UInt32, width: Int, height: Int)
    case invalidPixelData(textureID: UInt32)
    case unsupportedColorModel(textureID: UInt32)
}

struct SM64MarioFaceTexturePayload: Equatable, Sendable {
    let textureID: UInt32
    let sourceFormat: SM64MarioFaceTextureFormat
    let sourceByteCount: UInt32
    let uploadByteCount: UInt32
    let width: UInt32
    let height: UInt32
    let sourcePixelFingerprint: UInt64
    let uploadPixelFingerprint: UInt64
    let rgba8Pixels: Data
}

enum SM64MarioFaceTextureProvider {
    static let expectedWidth: UInt32 = 32
    static let expectedHeight: UInt32 = 32
    static let uploadBytesPerPixel: UInt32 = 4

    static func load(
        texture: SM64MarioFaceTextureResource,
        rootURL: URL
    ) throws -> SM64MarioFaceTexturePayload {
        let sourcePath = texture.includePath.replacingOccurrences(of: ".inc.c", with: ".png")
        let url = rootURL.appendingPathComponent(sourcePath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SM64MarioFaceTextureProviderError.missingSource(url)
        }
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw SM64MarioFaceTextureProviderError.unreadableSource(url)
        }
        guard image.width == Int(expectedWidth), image.height == Int(expectedHeight) else {
            throw SM64MarioFaceTextureProviderError.invalidDimensions(
                textureID: texture.textureID, width: image.width, height: image.height
            )
        }

        let decoded = try decodePixels(image: image, texture: texture)
        let sourceByteCount = expectedWidth * expectedHeight * texture.bitsPerTexel / 8
        let uploadByteCount = expectedWidth * expectedHeight * uploadBytesPerPixel
        guard decoded.upload.count == Int(uploadByteCount) else {
            throw SM64MarioFaceTextureProviderError.invalidPixelData(textureID: texture.textureID)
        }
        return SM64MarioFaceTexturePayload(
            textureID: texture.textureID,
            sourceFormat: texture.format,
            sourceByteCount: sourceByteCount,
            uploadByteCount: uploadByteCount,
            width: expectedWidth,
            height: expectedHeight,
            sourcePixelFingerprint: byteFingerprint(decoded.source, seed: UInt64(texture.bitsPerTexel)),
            uploadPixelFingerprint: byteFingerprint(decoded.upload, seed: UInt64(texture.format.rawValue)),
            rgba8Pixels: decoded.upload
        )
    }

    static func load(
        route: SM64MarioFaceRouteRecord,
        rootURL: URL
    ) throws -> [SM64MarioFaceTexturePayload] {
        try route.textureIDs.map { textureID in
            guard let texture = SM64MarioFaceRouteResourceCatalog.texture(textureID) else {
                throw SM64MarioFaceTextureProviderError.invalidPixelData(textureID: textureID)
            }
            return try load(texture: texture, rootURL: rootURL)
        }
    }

    private static func decodePixels(
        image: CGImage,
        texture: SM64MarioFaceTextureResource
    ) throws -> (source: Data, upload: Data) {
        guard let provider = image.dataProvider,
              let providerData = provider.data,
              let sourceBytes = CFDataGetBytePtr(providerData) else {
            throw SM64MarioFaceTextureProviderError.invalidPixelData(textureID: texture.textureID)
        }
        let bytesPerRow = image.bytesPerRow
        let bitsPerPixel = image.bitsPerPixel
        let sourceRowBytes = texture.format == .rgba16 ? 4 : 2
        guard bitsPerPixel == sourceRowBytes * 8,
              bytesPerRow >= Int(expectedWidth) * sourceRowBytes,
              CFDataGetLength(providerData) >= bytesPerRow * Int(expectedHeight) else {
            throw SM64MarioFaceTextureProviderError.invalidPixelData(textureID: texture.textureID)
        }

        let sourceByteCount = bytesPerRow * Int(expectedHeight)
        var source = Data(count: sourceByteCount)
        source.withUnsafeMutableBytes { destination in
            guard let baseAddress = destination.baseAddress else { return }
            baseAddress.copyMemory(from: sourceBytes, byteCount: sourceByteCount)
        }
        var upload = Data(count: Int(expectedWidth * expectedHeight * uploadBytesPerPixel))
        upload.withUnsafeMutableBytes { destination in
            guard let destination = destination.bindMemory(to: UInt8.self).baseAddress else { return }
            source.withUnsafeBytes { sourceBuffer in
                guard let source = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
                for row in 0..<Int(expectedHeight) {
                    let sourceRow = source.advanced(by: row * bytesPerRow)
                    let uploadRow = destination.advanced(by: row * Int(expectedWidth * uploadBytesPerPixel))
                    if texture.format == .rgba16 {
                        for byte in 0..<Int(expectedWidth * uploadBytesPerPixel) {
                            uploadRow[byte] = sourceRow[byte]
                        }
                    } else {
                        for column in 0..<Int(expectedWidth) {
                            let sourcePixel = sourceRow.advanced(by: column * 2)
                            let uploadPixel = uploadRow.advanced(by: column * 4)
                            uploadPixel[0] = sourcePixel[0]
                            uploadPixel[1] = sourcePixel[0]
                            uploadPixel[2] = sourcePixel[0]
                            uploadPixel[3] = sourcePixel[1]
                        }
                    }
                }
            }
        }
        return (source, upload)
    }

    private static func byteFingerprint(_ data: Data, seed: UInt64) -> UInt64 {
        var result = SM64OracleTraceHash.offset
        for byte in seed.littleEndianBytes {
            result ^= UInt64(byte)
            result &*= SM64OracleTraceHash.prime
        }
        for byte in data {
            result ^= UInt64(byte)
            result &*= SM64OracleTraceHash.prime
        }
        return result
    }
}

private extension UInt64 {
    var littleEndianBytes: [UInt8] {
        (0..<8).map { UInt8(truncatingIfNeeded: self >> UInt64($0 * 8)) }
    }
}
