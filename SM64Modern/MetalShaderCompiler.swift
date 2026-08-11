import Foundation
import Metal

enum MetalShaderCompilerError: LocalizedError {
    case compilerUnavailable
    case pipelineUnavailable(shaderID: UInt32)

    var errorDescription: String? {
        switch self {
        case .compilerUnavailable:
            "Metal 4 shader compiler creation failed"
        case let .pipelineUnavailable(shaderID):
            "Metal 4 pipeline creation failed for SM64 shader 0x\(String(shaderID, radix: 16))"
        }
    }
}

final class MetalShaderCompiler {
    struct CompiledPipeline {
        let state: any MTLRenderPipelineState
        let vertexStride: Int
    }

    private static let alphaOption: UInt32 = 1 << 24
    private static let fogOption: UInt32 = 1 << 25
    private static let textureEdgeOption: UInt32 = 1 << 26
    private static let noiseOption: UInt32 = 1 << 27

    private let compiler: any MTL4Compiler
    private var cache: [MetalShaderKey: CompiledPipeline] = [:]

    init(device: any MTLDevice) throws {
        let descriptor = MTL4CompilerDescriptor()
        descriptor.label = "SM64 Modern Dynamic MSL Compiler"
        guard let compiler = try? device.makeCompiler(descriptor: descriptor) else {
            throw MetalShaderCompilerError.compilerUnavailable
        }
        self.compiler = compiler
    }

    func pipeline(for key: MetalShaderKey) throws -> CompiledPipeline {
        if let cached = cache[key] { return cached }

        let source = Self.makeSource(for: key)
        let libraryDescriptor = MTL4LibraryDescriptor()
        libraryDescriptor.name = "SM64 Shader 0x\(String(key.shaderID, radix: 16))"
        libraryDescriptor.source = source
        let options = MTLCompileOptions()
        options.languageVersion = .version4_0
        libraryDescriptor.options = options
        let library = try compiler.makeLibrary(descriptor: libraryDescriptor)

        let vertexFunction = MTL4LibraryFunctionDescriptor()
        vertexFunction.library = library
        vertexFunction.name = "sm64_vertex"
        let fragmentFunction = MTL4LibraryFunctionDescriptor()
        fragmentFunction.library = library
        fragmentFunction.name = "sm64_fragment"

        let descriptor = MTL4RenderPipelineDescriptor()
        descriptor.label = "SM64 Pipeline 0x\(String(key.shaderID, radix: 16)) alpha=\(key.alphaBlend)"
        descriptor.vertexFunctionDescriptor = vertexFunction
        descriptor.fragmentFunctionDescriptor = fragmentFunction
        descriptor.inputPrimitiveTopology = .triangle
        guard let color = descriptor.colorAttachments[0] else {
            throw MetalShaderCompilerError.pipelineUnavailable(shaderID: key.shaderID)
        }
        color.pixelFormat = .bgra8Unorm
        if key.alphaBlend {
            color.blendingState = .enabled
            color.sourceRGBBlendFactor = .sourceAlpha
            color.destinationRGBBlendFactor = .oneMinusSourceAlpha
            color.rgbBlendOperation = .add
            color.sourceAlphaBlendFactor = .one
            color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            color.alphaBlendOperation = .add
        }

        var error: NSError?
        guard let state = SM64ModernMakeRenderPipelineState(compiler, descriptor, &error) else {
            if let error { throw error }
            throw MetalShaderCompilerError.pipelineUnavailable(shaderID: key.shaderID)
        }
        let result = CompiledPipeline(state: state, vertexStride: Self.vertexStride(for: key))
        cache[key] = result
        return result
    }

    func removeAll() {
        cache.removeAll()
    }

    private static func vertexStride(for key: MetalShaderKey) -> Int {
        let alpha = key.shaderID & alphaOption != 0
        let textured = key.textureMask != 0
        let fog = key.shaderID & fogOption != 0
        return 4 + (textured ? 2 : 0) + (fog ? 4 : 0) + Int(key.inputCount) * (alpha ? 4 : 3)
    }

    private static func makeSource(for key: MetalShaderKey) -> String {
        let alpha = key.shaderID & alphaOption != 0
        let fog = key.shaderID & fogOption != 0
        let textureEdge = key.shaderID & textureEdgeOption != 0
        let noise = key.shaderID & noiseOption != 0
        let useTexture0 = key.textureMask & 1 != 0
        let useTexture1 = key.textureMask & 2 != 0
        let manualFilter = key.filteringMode == 2
        let inputWidth = alpha ? 4 : 3

        var vertexAssignments = """
            uint cursor = vertexID * \(vertexStride(for: key));
            out.position = float4(vertices[cursor], vertices[cursor + 1], vertices[cursor + 2], vertices[cursor + 3]);
            cursor += 4;
        """
        if key.textureMask != 0 {
            vertexAssignments += "\n    out.uv = float2(vertices[cursor], vertices[cursor + 1]);\n    cursor += 2;"
        }
        if fog {
            vertexAssignments += "\n    out.fog = float4(vertices[cursor], vertices[cursor + 1], vertices[cursor + 2], vertices[cursor + 3]);\n    cursor += 4;"
        }
        for input in 0..<Int(key.inputCount) {
            if alpha {
                vertexAssignments += "\n    out.input\(input) = float4(vertices[cursor], vertices[cursor + 1], vertices[cursor + 2], vertices[cursor + 3]);\n    cursor += \(inputWidth);"
            } else {
                vertexAssignments += "\n    out.input\(input) = float4(vertices[cursor], vertices[cursor + 1], vertices[cursor + 2], 1.0);\n    cursor += \(inputWidth);"
            }
        }

        let vertexFields = (key.textureMask != 0 ? "    float2 uv;\n" : "")
            + (fog ? "    float4 fog;\n" : "")
            + (0..<Int(key.inputCount)).map { "    float4 input\($0);\n" }.joined()

        var sampling = "    float4 texel0 = float4(1.0);\n    float4 texel1 = float4(1.0);"
        if useTexture0 {
            sampling += manualFilter
                ? "\n    texel0 = sample3Point(texture0, sampler0, in.uv);"
                : "\n    texel0 = texture0.sample(sampler0, in.uv);"
        }
        if useTexture1 {
            sampling += manualFilter
                ? "\n    texel1 = sample3Point(texture1, sampler1, in.uv);"
                : "\n    texel1 = texture1.sample(sampler1, in.uv);"
        }

        let rgbExpression = combinerExpression(shaderID: key.shaderID, alpha: false)
        let alphaExpression = alpha ? combinerExpression(shaderID: key.shaderID, alpha: true) : "1.0"
        let filterHelper = manualFilter ? """
        float4 sample3Point(texture2d<float> texture, sampler state, float2 uv) {
            float2 size = float2(texture.get_width(), texture.get_height());
            float2 offset = fract(uv * size - 0.5);
            offset -= step(1.0, offset.x + offset.y);
            float2 base = uv - offset / size;
            float4 c0 = texture.sample(state, base);
            float4 c1 = texture.sample(state, base + float2(sign(offset.x), 0.0) / size);
            float4 c2 = texture.sample(state, base + float2(0.0, sign(offset.y)) / size);
            return c0 + abs(offset.x) * (c1 - c0) + abs(offset.y) * (c2 - c0);
        }
        """ : ""

        var post = ""
        if textureEdge {
            post += "\n    if (color.a > 0.3) color.a = 1.0; else discard_fragment();"
        }
        if fog {
            post += "\n    color.rgb = mix(color.rgb, in.fog.rgb, in.fog.a);"
        }
        if noise {
            post += """

                uint n = uint(in.position.x) * 1973u + uint(in.position.y) * 9277u + uniforms.frame * 26699u;
                n = (n << 13u) ^ n;
                float randomValue = 1.0 - float((n * (n * n * 15731u + 789221u) + 1376312589u) & 0x7fffffffu) / 1073741824.0;
                color.a *= floor(fract(randomValue) + 0.5);
            """
        }

        return """
        #include <metal_stdlib>
        using namespace metal;

        struct DrawUniforms { uint frame; uint3 padding; };
        struct VertexOut {
            float4 position [[position]];
        \(vertexFields)};

        \(filterHelper)

        vertex VertexOut sm64_vertex(
            uint vertexID [[vertex_id]],
            device const float *vertices [[buffer(0)]]) {
            VertexOut out;
            \(vertexAssignments)
            return out;
        }

        fragment float4 sm64_fragment(
            VertexOut in [[stage_in]],
            constant DrawUniforms &uniforms [[buffer(1)]],
            texture2d<float> texture0 [[texture(0)]],
            texture2d<float> texture1 [[texture(1)]],
            sampler sampler0 [[sampler(0)]],
            sampler sampler1 [[sampler(1)]]) {
            (void)uniforms;
            (void)texture0;
            (void)texture1;
            (void)sampler0;
            (void)sampler1;
        \(sampling)
            float3 rgb = \(rgbExpression);
            float alpha = \(alphaExpression);
            float4 color = float4(rgb, alpha);\(post)
            (void)texel0;
            (void)texel1;
            return color;
        }
        """
    }

    private static func combinerExpression(shaderID: UInt32, alpha: Bool) -> String {
        let shift = alpha ? 12 : 0
        let terms = (0..<4).map { index -> UInt32 in
            (shaderID >> UInt32(shift + index * 3)) & 7
        }
        let values = terms.map { termExpression($0, alpha: alpha) }
        if terms[2] == 0 { return values[3] }
        if terms[1] == 0 && terms[3] == 0 { return "(\(values[0]) * \(values[2]))" }
        if terms[1] == terms[3] { return "mix(\(values[1]), \(values[0]), \(values[2]))" }
        return "((\(values[0]) - \(values[1])) * \(values[2]) + \(values[3]))"
    }

    private static func termExpression(_ term: UInt32, alpha: Bool) -> String {
        let suffix = alpha ? ".a" : ".rgb"
        switch term {
        case 0: return alpha ? "0.0" : "float3(0.0)"
        case 1...4: return "in.input\(term - 1)\(suffix)"
        case 5: return "texel0\(suffix)"
        case 6: return alpha ? "texel0.a" : "float3(texel0.a)"
        case 7: return "texel1\(suffix)"
        default: return alpha ? "0.0" : "float3(0.0)"
        }
    }
}
