import Foundation
import Metal
import os

private let metalShaderLogger = Logger(subsystem: "io.github.deestiz.sm64modern", category: "MetalShaderCompiler")

enum MetalShaderCompilerError: LocalizedError {
    case compilerUnavailable
    case pipelineNotReady(shaderID: UInt32)
    case pipelineUnavailable(shaderID: UInt32)

    var errorDescription: String? {
        switch self {
        case .compilerUnavailable:
            "Metal 4 shader compiler creation failed"
        case let .pipelineNotReady(shaderID):
            "Metal 4 pipeline 0x\(String(shaderID, radix: 16)) is still compiling"
        case let .pipelineUnavailable(shaderID):
            "Metal 4 pipeline creation failed for SM64 shader 0x\(String(shaderID, radix: 16))"
        }
    }
}

/// Metal compiler state is shared between the engine owner thread and the
/// dedicated pipeline queue. The lock guards the mutable cache; Metal compiler
/// objects are confined to the compiler queue and completion results return
/// through `finish` before the owner thread reads them.
final class MetalShaderCompiler {
    struct CompiledPipeline {
        let state: any MTLRenderPipelineState
        let vertexStride: Int
    }

    private static let alphaOption: UInt32 = 1 << 24
    private static let fogOption: UInt32 = 1 << 25
    private static let textureEdgeOption: UInt32 = 1 << 26
    private static let noiseOption: UInt32 = 1 << 27
    private static let marioFaceMaterialOption: UInt32 = 1 << 28
    private static let marioFaceTransformOption: UInt32 = 1 << 29
    private static let marioFaceTextureOption: UInt32 = 1 << 30

    private static let archiveSchema = 1
    private static let rendererSchema = 2

    private let compiler: any MTL4Compiler
    private let serializer: (any MTL4PipelineDataSetSerializer)?
    private let archiveURL: URL?
    private let descriptorCacheURL: URL?
    private let lookupArchives: [any MTL4Archive]
    private let archiveLoaded: Bool
    private let descriptorCacheFound: Bool
    private let compileQueue = DispatchQueue(label: "io.github.deestiz.sm64modern.metal4-pipeline", qos: .userInitiated)
    private let lock = NSLock()
    private var cache: [MetalShaderKey: CompiledPipeline] = [:]
    private var pending: Set<MetalShaderKey> = []
    private var failures: [MetalShaderKey: Error] = [:]

    init(device: any MTLDevice) throws {
        let descriptor = MTL4CompilerDescriptor()
        descriptor.label = "SM64 Modern Dynamic MSL Compiler"
        let serializer = SM64ModernMakePipelineDataSetSerializer(device)
        descriptor.pipelineDataSetSerializer = serializer
        guard let compiler = try? device.makeCompiler(descriptor: descriptor) else {
            throw MetalShaderCompilerError.compilerUnavailable
        }
        self.compiler = compiler
        self.serializer = serializer

        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("io.github.deestiz.sm64modern", isDirectory: true)
            .appendingPathComponent("Metal4", isDirectory: true)
        self.archiveURL = cacheDirectory?.appendingPathComponent(
            "pipelines-v\(Self.rendererSchema)-s\(Self.archiveSchema)-device-\(device.registryID).metallib",
            isDirectory: false
        )
        self.descriptorCacheURL = self.archiveURL?.deletingPathExtension().appendingPathExtension("mtl4-json")

        var archives: [any MTL4Archive] = []
        var loadedArchive = false
        let archiveExists = archiveURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        if let archiveURL, archiveExists {
            var error: NSError?
            if let archive = SM64ModernLoadArchive(device, archiveURL, &error) {
                archives.append(archive)
                loadedArchive = true
                metalShaderLogger.notice("metal4_archive_loaded path=\(archiveURL.path, privacy: .public) lookup_archives=1")
            } else if let error {
                metalShaderLogger.info("metal4_archive_ignored path=\(archiveURL.path, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            }
        }
        let descriptorCacheFound = descriptorCacheURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        if let descriptorCacheURL, descriptorCacheFound {
            metalShaderLogger.notice("metal4_descriptor_cache_found path=\(descriptorCacheURL.path, privacy: .public)")
        }
        self.lookupArchives = archives
        self.archiveLoaded = loadedArchive
        self.descriptorCacheFound = descriptorCacheFound
        if loadedArchive {
            metalShaderLogger.notice("metal4_archive_reuse enabled=true source=binary_archive")
        } else {
            let reason = archiveExists ? "load_failed" : "missing"
            let fallback = descriptorCacheFound ? "descriptor_cache" : "compile"
            metalShaderLogger.notice("metal4_archive_reuse enabled=false source=none fallback=\(fallback) reason=\(reason)")
        }
        if serializer != nil {
            if let cacheDirectory {
                try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            }
            metalShaderLogger.notice("metal4_pipeline_cache_ready schema=\(Self.rendererSchema) archive_schema=\(Self.archiveSchema) device=\(device.registryID) archive_loaded=\(loadedArchive) lookup_archives=\(archives.count) descriptor_cache_found=\(descriptorCacheFound)")
        } else {
            metalShaderLogger.info("metal4_pipeline_cache_unavailable reason=serializer_creation_failed")
        }
    }

    func pipeline(for key: MetalShaderKey) throws -> CompiledPipeline {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[key] { return cached }
        if let failure = failures[key] { throw failure }
        throw MetalShaderCompilerError.pipelineNotReady(shaderID: key.shaderID)
    }

    /// Ensure the pipelines needed by the next immutable scene packet are
    /// complete before the renderer submits a drawable. This keeps the first
    /// captured frame source-backed instead of presenting a clear-only frame
    /// while asynchronous Metal 4 compiler tasks are still in flight.
    func waitUntilReady(for keys: [MetalShaderKey]) throws {
        let uniqueKeys = Array(Set(keys))
        guard !uniqueKeys.isEmpty else { return }
        for key in uniqueKeys { prepare(key) }
        // `prepare` enqueues the compiler-owned work asynchronously. Drain
        // that enqueue barrier before waiting on Metal's compiler tasks, or a
        // display-link callback can observe an empty task store and submit
        // while the first scene pipeline is still compiling.
        compileQueue.sync {}
        SM64ModernWaitForRenderPipelineTasks()

        lock.lock()
        let failed = uniqueKeys.compactMap { key -> Error? in failures[key] }
        let missing = uniqueKeys.first { cache[$0] == nil && failures[$0] == nil }
        lock.unlock()

        if let failure = failed.first { throw failure }
        if let missing {
            throw MetalShaderCompilerError.pipelineNotReady(shaderID: missing.shaderID)
        }
        metalShaderLogger.notice("metal4_pipeline_warmup_ready requested=\(uniqueKeys.count) archive_reuse=\(self.archiveLoaded) lookup_archives=\(self.lookupArchives.count) descriptor_cache=\(self.descriptorCacheFound)")
    }

    /// Drain every registration-time pipeline before the engine profile starts.
    /// C shader registration intentionally remains asynchronous, but leaving
    /// those tasks outstanding lets compiler CPU work contend with the fixed
    /// simulation owner and manufacture scheduler drops during M34 stress.
    func waitForPreparedPipelines() throws {
        compileQueue.sync {}
        SM64ModernWaitForRenderPipelineTasks()
        lock.lock()
        let failure = failures.values.first
        let pendingCount = pending.count
        lock.unlock()
        if let failure { throw failure }
        guard pendingCount == 0 else {
            throw MetalShaderCompilerError.pipelineNotReady(shaderID: 0)
        }
        metalShaderLogger.notice("metal4_pipeline_registration_ready archive_reuse=\(self.archiveLoaded) lookup_archives=\(self.lookupArchives.count) descriptor_cache=\(self.descriptorCacheFound)")
    }

    func prepare(_ key: MetalShaderKey) {
        lock.lock()
        guard cache[key] == nil, failures[key] == nil, !pending.contains(key) else {
            lock.unlock()
            return
        }
        pending.insert(key)
        lock.unlock()
        // Capture only an integer address in the @Sendable queue closure;
        // recovery is the compiler-queue ownership leaf and the compiler is
        // retained by its renderer until shutdown drains this queue.
        let contextAddress = UInt(bitPattern: Unmanaged.passUnretained(self).toOpaque())
        compileQueue.async {
            guard let context = UnsafeMutableRawPointer(bitPattern: contextAddress) else {
                preconditionFailure("MetalShaderCompiler queue context must be non-nil")
            }
            Unmanaged<MetalShaderCompiler>.fromOpaque(context)
                .takeUnretainedValue()
                .compile(key)
        }
    }

    /// Compile a bootstrap pipeline before the renderer starts presenting.
    /// The face-source gate has only a small number of drawable callbacks in
    /// headless/native verification, so leaving its first pipeline entirely
    /// asynchronous can exhaust those callbacks before the private mesh is
    /// eligible to draw.  Normal scene shaders remain asynchronous.
    func prepareSynchronously(_ key: MetalShaderKey) {
        lock.lock()
        guard cache[key] == nil, failures[key] == nil, !pending.contains(key) else {
            lock.unlock()
            return
        }
        pending.insert(key)
        lock.unlock()
        compile(key)
        SM64ModernWaitForRenderPipelineTasks()
    }

    func removeAll() {
        flushArchive()
        lock.lock()
        cache.removeAll()
        failures.removeAll()
        pending.removeAll()
        lock.unlock()
    }

    private func compile(_ key: MetalShaderKey) {
        do {
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

            let archives: [any MTL4Archive]? = lookupArchives.isEmpty ? nil : lookupArchives
            SM64ModernMakeRenderPipelineStateAsync(compiler, descriptor, archives) { [self, library] state, error in
                if let state {
                    finish(key: key, result: CompiledPipeline(state: state, vertexStride: Self.vertexStride(for: key)), error: nil)
                } else {
                    finish(key: key, result: nil, error: error ?? MetalShaderCompilerError.pipelineUnavailable(shaderID: key.shaderID))
                }
                _ = library
            }
            metalShaderLogger.debug("metal4_pipeline_compile_started shader=0x\(String(key.shaderID, radix: 16), privacy: .public) lookup_archives=\(self.lookupArchives.count)")
        } catch {
            finish(key: key, result: nil, error: error)
        }
    }

    private func finish(key: MetalShaderKey, result: CompiledPipeline?, error: Error?) {
        lock.lock()
        pending.remove(key)
        if let result {
            cache[key] = result
        } else if let error {
            failures[key] = error
        }
        lock.unlock()
        if let result {
            metalShaderLogger.notice("metal4_pipeline_ready shader=0x\(String(key.shaderID, radix: 16), privacy: .public) stride=\(result.vertexStride) archive_reuse=\(self.archiveLoaded)")
        } else {
            metalShaderLogger.error("metal4_pipeline_failed shader=0x\(String(key.shaderID, radix: 16), privacy: .public) error=\(error?.localizedDescription ?? "unknown", privacy: .public)")
        }
    }

    private func flushArchive() {
        guard let serializer, let archiveURL else { return }
        do {
            SM64ModernWaitForRenderPipelineTasks()
            try FileManager.default.createDirectory(at: archiveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            metalShaderLogger.notice("metal4_archive_flush_begin path=\(archiveURL.path, privacy: .public)")
            var archiveError: NSError?
            if SM64ModernFlushPipelineDataSetSerializer(serializer, archiveURL, &archiveError) {
                metalShaderLogger.notice("metal4_archive_flushed path=\(archiveURL.path, privacy: .public)")
                return
            }
            let archiveReason = archiveError?.localizedDescription ?? "runtime serializer returned false"
            metalShaderLogger.info("metal4_archive_flush_failed path=\(archiveURL.path, privacy: .public) reason=\(archiveReason, privacy: .public)")
            guard let descriptorCacheURL else {
                metalShaderLogger.info("metal4_archive_deferred reason=\(archiveReason, privacy: .public)")
                return
            }
            var scriptError: NSError?
            guard let script = SM64ModernSerializePipelineDataSetScript(serializer, &scriptError) else {
                throw scriptError ?? NSError(
                    domain: "io.github.deestiz.sm64modern.metal4",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Metal 4 pipeline dataset script serialization returned nil"]
                )
            }
            try script.write(to: descriptorCacheURL, options: .atomic)
            metalShaderLogger.notice("metal4_descriptor_cache_flushed path=\(descriptorCacheURL.path, privacy: .public) bytes=\(script.count) archive_deferred=\(archiveReason, privacy: .public)")
        } catch {
            metalShaderLogger.error("metal4_pipeline_cache_flush_failed path=\(archiveURL.path, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
        }
    }

    private static func vertexStride(for key: MetalShaderKey) -> Int {
        let alpha = key.shaderID & alphaOption != 0
        let marioFaceTexture = key.shaderID & marioFaceTextureOption != 0
        let textured = key.textureMask != 0 || marioFaceTexture
        let fog = key.shaderID & fogOption != 0
        return 4 + (textured ? 2 : 0) + (fog ? 4 : 0) + Int(key.inputCount) * (alpha ? 4 : 3)
    }

    private static func makeSource(for key: MetalShaderKey) -> String {
        let alpha = key.shaderID & alphaOption != 0
        let fog = key.shaderID & fogOption != 0
        let textureEdge = key.shaderID & textureEdgeOption != 0
        let noise = key.shaderID & noiseOption != 0
        let marioFaceMaterial = key.shaderID & marioFaceMaterialOption != 0
        let marioFaceTransform = key.shaderID & marioFaceTransformOption != 0
        let marioFaceTexture = key.shaderID & marioFaceTextureOption != 0
        let useTexture0 = key.textureMask & 1 != 0 || marioFaceTexture
        let useTexture1 = key.textureMask & 2 != 0
        let manualFilter = key.filteringMode == 2
        let inputWidth = alpha ? 4 : 3

        var vertexAssignments = """
            uint cursor = vertexID * \(vertexStride(for: key));
            out.position = \(marioFaceTransform ? "uniforms.transform * " : "")float4(vertices[cursor], vertices[cursor + 1], vertices[cursor + 2], vertices[cursor + 3]);
            cursor += 4;
        """
        if key.textureMask != 0 || marioFaceTexture {
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
        if marioFaceMaterial {
            vertexAssignments += "\n    out.materialID = materialIndices[vertexID];"
        }

        let vertexFields = (key.textureMask != 0 || marioFaceTexture ? "    float2 uv;\n" : "")
            + (fog ? "    float4 fog;\n" : "")
            + (0..<Int(key.inputCount)).map { "    float4 input\($0);\n" }.joined()
            + (marioFaceMaterial ? "    uint materialID [[flat]];\n" : "")

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

        let rgbExpression = marioFaceMaterial
            ? (marioFaceTexture
                ? "materials[in.materialID].rgb * texel0.rgb"
                : "materials[in.materialID].rgb")
            : combinerExpression(shaderID: key.shaderID, alpha: false)
        let alphaExpression = alpha ? combinerExpression(shaderID: key.shaderID, alpha: true) : "1.0"
        let materialBinding = marioFaceMaterial
            ? "            device const float4 *materials [[buffer(2)]],\n"
            : ""
        let indexBinding = marioFaceMaterial
            ? "            device const ushort *sourceIndices [[buffer(3)]],\n"
            : ""
        let materialBindingUse = marioFaceMaterial
            ? "            (void)sourceIndices;\n"
            : ""
        let vertexUniformBinding = marioFaceTransform
            ? ",\n            constant DrawUniforms &uniforms [[buffer(1)]]"
            : ""
        let vertexMaterialBinding = marioFaceMaterial
            ? ",\n            device const ushort *materialIndices [[buffer(4)]]"
            : ""
        let marioFaceLighting = marioFaceTransform
            ? "\n            float3 light = normalize(uniforms.lightDirection.xyz);\n            float intensity = 0.65 + 0.35 * max(dot(float3(0.0, 0.0, 1.0), light), 0.0);\n            color.rgb *= uniforms.lightColor.rgb * intensity;"
            : ""
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

        struct DrawUniforms {
            uint frame;
            uint3 padding;
            float4x4 transform;
            float4 lightDirection;
            float4 lightColor;
        };
        struct VertexOut {
            float4 position [[position]];
        \(vertexFields)};

        \(filterHelper)

        vertex VertexOut sm64_vertex(
            uint vertexID [[vertex_id]],
            device const float *vertices [[buffer(0)]]\(vertexUniformBinding)\(vertexMaterialBinding)) {
            VertexOut out;
            \(vertexAssignments)
            return out;
        }

            fragment float4 sm64_fragment(
            VertexOut in [[stage_in]],
            constant DrawUniforms &uniforms [[buffer(1)]],
        \(materialBinding)
        \(indexBinding)
            texture2d<float> texture0 [[texture(0)]],
            texture2d<float> texture1 [[texture(1)]],
            sampler sampler0 [[sampler(0)]],
            sampler sampler1 [[sampler(1)]]) {
            (void)uniforms;
            (void)texture0;
            (void)texture1;
            (void)sampler0;
            (void)sampler1;
        \(materialBindingUse)
        \(sampling)
            float3 rgb = \(rgbExpression);
            float alpha = \(alphaExpression);
            float4 color = float4(rgb, alpha);\(post)\(marioFaceLighting)
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
