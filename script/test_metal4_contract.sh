#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDERER="$PROJECT_ROOT/SM64Modern/MetalRenderer.swift"
COMPILER="$PROJECT_ROOT/SM64Modern/MetalShaderCompiler.swift"
BRIDGE="$PROJECT_ROOT/SM64Modern/MetalCompilerBridge.m"
VIEW="$PROJECT_ROOT/SM64Modern/GameView.swift"

require_fixed() {
  local needle="$1"
  local file="$2"
  if ! rg -Fq -- "$needle" "$file"; then
    printf 'Metal 4 contract missing: %s (%s)\n' "$needle" "$file" >&2
    exit 1
  fi
}

require_ordered() {
  local file="$1"
  local first="$2"
  local second="$3"
  local first_line second_line
  first_line="$(rg -n -F -- "$first" "$file" | head -n 1 | cut -d: -f1)"
  second_line="$(rg -n -F -- "$second" "$file" | head -n 1 | cut -d: -f1)"
  if [[ -z "$first_line" || -z "$second_line" || "$first_line" -ge "$second_line" ]]; then
    printf 'Metal 4 contract order failure: %s must precede %s (%s)\n' "$first" "$second" "$file" >&2
    exit 1
  fi
}

require_fixed 'any MTL4CommandQueue' "$RENDERER"
require_fixed 'any MTL4CommandAllocator' "$RENDERER"
require_fixed 'any MTL4CommandBuffer' "$RENDERER"
require_fixed 'any MTL4ArgumentTable' "$RENDERER"
require_fixed 'MTL4RenderPassDescriptor()' "$RENDERER"
require_fixed 'commandBuffer.beginCommandBuffer(allocator: slot.allocator)' "$RENDERER"
require_fixed 'commandBuffer.useResidencySet(sceneResidency)' "$RENDERER"
require_fixed 'commandBuffer.useResidencySet(layer.residencySet)' "$RENDERER"
require_fixed 'commandBuffer.endCommandBuffer()' "$RENDERER"
require_fixed 'SM64ModernBarrierBlitToFragmentProducer' "$RENDERER"
require_fixed 'SM64ModernBarrierBlitToFragmentConsumer' "$RENDERER"
require_fixed 'queue.waitForDrawable(drawable)' "$RENDERER"
require_fixed 'queue.commit([commandBuffer])' "$RENDERER"
require_fixed 'queue.signalDrawable(drawable)' "$RENDERER"
require_fixed 'drawable.present()' "$RENDERER"
require_fixed 'descriptor.storageMode = .private' "$RENDERER"
require_fixed 'descriptor.storageMode = .memoryless' "$RENDERER"
require_fixed 'pass.depthAttachment.storeAction = .dontCare' "$RENDERER"
require_fixed 'MTL4CompilerDescriptor()' "$COMPILER"
require_fixed 'SM64ModernMakeRenderPipelineStateAsync' "$COMPILER"
require_fixed 'lookupArchives' "$COMPILER"
require_fixed 'newRenderPipelineStateWithDescriptor:descriptor' "$BRIDGE"
require_fixed 'metalLayer.framebufferOnly = true' "$VIEW"
require_fixed 'metalLayer.maximumDrawableCount = 2' "$VIEW"
require_fixed 'metalLayer.displaySyncEnabled = true' "$VIEW"
require_fixed 'metalLayer.allowsNextDrawableTimeout = true' "$VIEW"

require_ordered "$RENDERER" 'commandBuffer.beginCommandBuffer(allocator: slot.allocator)' 'commandBuffer.useResidencySet(sceneResidency)'
require_ordered "$RENDERER" 'commandBuffer.useResidencySet(sceneResidency)' 'commandBuffer.pushDebugGroup'
require_ordered "$RENDERER" 'queue.waitForDrawable(drawable)' 'queue.commit([commandBuffer])'
require_ordered "$RENDERER" 'queue.commit([commandBuffer])' 'queue.signalDrawable(drawable)'
require_ordered "$RENDERER" 'queue.signalDrawable(drawable)' 'drawable.present()'

if rg -n --glob '*.{swift,m,h}' -- \
  '\bMTLCommandBuffer\b|\bMTLRenderCommandEncoder\b|\bMTLComputeCommandEncoder\b|\bMTLBlitCommandEncoder\b|\bMTLParallelRenderCommandEncoder\b|\bStorageModeManaged\b|\bsetVertexBytes\b|\bsetFragmentBytes\b|\bsetBytes\b|\baddCompletedHandler\b|\bmakeCommandQueue\b' \
  "$PROJECT_ROOT/SM64Modern"; then
  printf '%s\n' 'Metal 4 contract found a legacy Metal API surface' >&2
  exit 1
fi

if rg -n -F --glob '*.{swift,m,h}' -- 'nextDrawable' "$PROJECT_ROOT/SM64Modern"; then
  printf '%s\n' 'Metal 4 display-link path must not acquire drawables with nextDrawable' >&2
  exit 1
fi

printf '%s\n' 'SM64 Modern Metal 4 source contract passed'
