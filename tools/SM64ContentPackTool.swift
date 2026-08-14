import CryptoKit
import Darwin
import Foundation

@main
struct SM64ContentPackTool {
    static func main() {
        do {
            try run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            let message = "sm64-content-pack: \(error)\n"
            FileHandle.standardError.write(Data(message.utf8))
            exit(2)
        }
    }

    private static func run(arguments: [String]) throws {
        guard let command = arguments.first else {
            throw SM64ContentPackError.invalidArgument(usage)
        }
        switch command {
        case "build":
            let options = try parse(arguments: Array(arguments.dropFirst()), required: ["--root", "--output"])
            let sourceOnly = options.flags.contains("--source-only")
            let romURL = options.values["--rom"].map { URL(fileURLWithPath: $0) }
            let pack = try SM64ContentPack.build(
                rootURL: URL(fileURLWithPath: options.values["--root"]!),
                outputURL: URL(fileURLWithPath: options.values["--output"]!),
                romURL: romURL,
                sourceOnly: sourceOnly
            )
            try pack.validate(requireROM: !sourceOnly)
            print(summary(pack: pack, verb: "built"))

        case "verify":
            let options = try parse(arguments: Array(arguments.dropFirst()), required: ["--pack"])
            let pack = try SM64ContentPack.load(from: URL(fileURLWithPath: options.values["--pack"]!))
            let expectedROM = try options.values["--rom"].map { path -> Data in
                let bytes = try Data(contentsOf: URL(fileURLWithPath: path), options: [.mappedIfSafe])
                return Data(Insecure.SHA1.hash(data: bytes))
            }
            try pack.validate(expectedROMSHA1: expectedROM, requireROM: options.flags.contains("--require-rom"))
            print(summary(pack: pack, verb: "verified"))

        default:
            throw SM64ContentPackError.invalidArgument(usage)
        }
    }

    private struct ParsedOptions {
        var values: [String: String] = [:]
        var flags = Set<String>()
    }

    private static func parse(arguments: [String], required: [String]) throws -> ParsedOptions {
        var options = ParsedOptions()
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if argument == "--source-only" || argument == "--require-rom" {
                options.flags.insert(argument)
                index += 1
                continue
            }
            guard argument.hasPrefix("--"), index + 1 < arguments.count else {
                throw SM64ContentPackError.invalidArgument(usage)
            }
            options.values[argument] = arguments[index + 1]
            index += 2
        }
        for name in required where options.values[name] == nil {
            throw SM64ContentPackError.invalidArgument("missing \(name)\n\(usage)")
        }
        return options
    }

    private static func summary(pack: SM64ContentPack, verb: String) -> String {
        let fileCount = pack.sections.reduce(0) { $0 + $1.files.count }
        let sectionSummary = pack.sections.map { "\($0.kind.rawValue)=\($0.files.count)" }.joined(separator: ",")
        let rom = pack.metadata.isSourceOnly ? "source-only" : hex(pack.metadata.romSHA1)
        return "SM64 content pack \(verb) version=\(pack.metadata.version) region=\(pack.metadata.region) rom=\(rom) files=\(fileCount) sections=[\(sectionSummary)]"
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private static let usage = "usage: sm64-content-pack build --root ROOT --output PACK [--rom ROM] [--source-only] | verify --pack PACK [--rom ROM] [--require-rom]"
}
