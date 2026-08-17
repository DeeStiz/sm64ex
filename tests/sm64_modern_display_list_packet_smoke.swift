import Foundation

private let fixture: [SM64DisplayListWords] = [
    SM64DisplayListWords(word0: 0xda00_0001, word1: 0x0000_1000), // matrix push
    SM64DisplayListWords(word0: 0xd9ff_ffff, word1: 0x0000_0400), // geometry mode
    SM64DisplayListWords(word0: 0xd7ab_1234, word1: 0x1000_2000), // texture
    SM64DisplayListWords(word0: 0xdb02_0000, word1: 0x0000_0003), // number of lights
    SM64DisplayListWords(word0: 0xdb08_0000, word1: 0x0000_0099), // fog mode
    SM64DisplayListWords(word0: 0xdc00_0808, word1: 0x0000_2040), // viewport copy
    SM64DisplayListWords(word0: 0xdc00_300a, word1: 0x0000_3050), // light copy
    SM64DisplayListWords(word0: 0xfc12_3456, word1: 0x789a_bcde), // combiner
    SM64DisplayListWords(word0: 0xed00_1002, word1: 0x0100_3004), // scissor
    SM64DisplayListWords(word0: 0xff00_0000, word1: 0x0000_1111), // color image
    SM64DisplayListWords(word0: 0xfe00_0000, word1: 0x0000_2222), // depth image
    SM64DisplayListWords(word0: 0xfd00_0000, word1: 0x0000_3333), // texture image
    SM64DisplayListWords(word0: 0xf500_0000, word1: 0x0200_1234), // tile
    SM64DisplayListWords(word0: 0xf200_0000, word1: 0x0200_5678), // tile size
    SM64DisplayListWords(word0: 0xfb00_0000, word1: 0x0102_0304), // environment
    SM64DisplayListWords(word0: 0xfa00_0000, word1: 0x1122_3344), // primitive
    SM64DisplayListWords(word0: 0xf900_0000, word1: 0x5566_7788), // blend
    SM64DisplayListWords(word0: 0xf800_0000, word1: 0x99aa_bbcc), // fog color
    SM64DisplayListWords(word0: 0xf700_0000, word1: 0xddee_ff00), // fill
    SM64DisplayListWords(word0: 0xe300_0010, word1: 0x0102_0304), // other high
    SM64DisplayListWords(word0: 0xe200_0018, word1: 0x0007_0000), // other low/layer
    SM64DisplayListWords(word0: 0x0112_3456, word1: 0x0000_4444), // vertices
    SM64DisplayListWords(word0: 0x0500_0000, word1: 0x000a_141e), // triangle 1
    SM64DisplayListWords(word0: 0x060a_141e, word1: 0x0028_323c), // triangle 2
    SM64DisplayListWords(word0: 0x0800_0000, word1: 0x0001_0203), // line
    SM64DisplayListWords(word0: 0xf600_0000, word1: 0x0004_0506), // fill rect
    SM64DisplayListWords(word0: 0xe400_0000, word1: 0x0007_0809), // texture rect
    SM64DisplayListWords(word0: 0xe500_0000, word1: 0x000a_0b0c), // texture rect flip
    SM64DisplayListWords(word0: 0xde00_0001, word1: 0x0000_5555), // nested display list ID
    SM64DisplayListWords(word0: 0x0410_0203, word1: 0x0000_6666), // branch resource ID
    SM64DisplayListWords(word0: 0xaa00_0000, word1: 0x0000_7777), // unsupported, retained
    SM64DisplayListWords(word0: 0xdf00_0000, word1: 0x0000_0000), // end
]

@main
struct SM64ModernDisplayListPacketSmoke {
    static func main() {
        var builder = SM64DisplayListPacketBuilder(sequence: 7, maxCommands: 64)
        for words in fixture {
            precondition(builder.append(words))
        }
        precondition(builder.appendRenderLayer(9))
        let packet = builder.finish()
        precondition(packet.sequence == 7)
        precondition(packet.isComplete)
        precondition(!packet.truncated)
        precondition(packet.unsupportedCommandCount == 1)
        precondition(packet.commands.count == fixture.count + 1)
        precondition(packet.draws.count == 6)
        precondition(packet.finalState.renderLayer == 9)
        precondition(packet.finalState.lightCount == 3)
        precondition(packet.finalState.fogMode == 0x99)
        precondition(packet.finalState.viewportResourceID == 0x2040)
        precondition(packet.finalState.textureImageResourceID == 0x3333)
        precondition(packet.draws.map(\.renderLayer) == [7, 7, 7, 7, 7, 7])

        let decoded = SM64DisplayListDecoder.decode(fixture, sequence: 7, maxCommands: 64)
        precondition(decoded.commands.count == fixture.count)
        precondition(decoded.finalState.renderLayer == 7)
        precondition(decoded.isComplete)

        let truncated = SM64DisplayListDecoder.decode(fixture, sequence: 7, maxCommands: 3)
        precondition(truncated.truncated)
        precondition(!truncated.isComplete)

        let immutableFingerprint = packet.fingerprint
        var secondBuilder = SM64DisplayListPacketBuilder(sequence: 8, maxCommands: 64)
        for words in fixture {
            precondition(secondBuilder.append(words))
        }
        precondition(secondBuilder.appendRenderLayer(9))
        let secondPacket = secondBuilder.finish()
        precondition(packet.fingerprint == immutableFingerprint)
        precondition(secondPacket.fingerprint != packet.fingerprint)
        print("displayListPacketFingerprint=0x\(String(packet.fingerprint, radix: 16))")
        print("SM64 Modern display-list packet smoke passed")
    }
}
