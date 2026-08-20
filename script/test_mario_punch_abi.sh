#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build/sm64-modern-mario-punch-abi-smoke"
mkdir -p "$BUILD_ROOT/module-cache"

xcrun clang -std=c11 -DNON_MATCHING=1 -DAVOID_UB=1 -D_LANGUAGE_C -DVERSION_US \
  -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" -I"$PROJECT_ROOT/src/pc" \
  -c "$PROJECT_ROOT/src/pc/sm64_modern_mario_punch_migration.c" \
  -o "$BUILD_ROOT/sm64_modern_mario_punch_migration.o"
xcrun clang -std=c11 -DNON_MATCHING=1 -DAVOID_UB=1 -D_LANGUAGE_C -DVERSION_US \
  -I"$PROJECT_ROOT/include" -I"$PROJECT_ROOT/src" -I"$PROJECT_ROOT/src/pc" \
  -c "$PROJECT_ROOT/tests/sm64_modern_mario_action_authority_stub.c" \
  -o "$BUILD_ROOT/sm64_modern_mario_action_authority_stub.o"

xcrun swiftc \
  -parse-as-library \
  -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  -module-cache-path "$BUILD_ROOT/module-cache" \
  -Xcc -I -Xcc "$PROJECT_ROOT/include" \
  -Xcc -I -Xcc "$PROJECT_ROOT/src" \
  -Xcc -I -Xcc "$PROJECT_ROOT/src/pc" \
  -import-objc-header "$PROJECT_ROOT/SM64Modern/SM64Modern-Bridging-Header.h" \
  "$PROJECT_ROOT/SM64Modern/InputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioInputCore.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfaceCollision.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGeometryInput.swift" \
  "$PROJECT_ROOT/SM64Modern/DeterministicPrimitives.swift" \
  "$PROJECT_ROOT/SM64Modern/GeneratedTrigTables.swift" \
  "$PROJECT_ROOT/SM64Modern/ObjectPool.swift" \
  "$PROJECT_ROOT/SM64Modern/SurfacePartition.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioState.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioAction.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioActionCancels.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGroundSpeed.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGroundStep.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioAirStep.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioWaterStep.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioBonk.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioTerrainImpulse.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioQuicksand.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioSteepPush.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioTerrainSound.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioFloorPredicates.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioForwardVelocity.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioVelocityDerivation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioPunchSequence.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioWallResponse.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioWalkAnimation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioHeldWalkAnimation.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioSlope.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioSlopeDeceleration.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioDeceleratingSpeed.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioShellSpeed.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioLandingAcceleration.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGravity.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioVerticalWind.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioSliding.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioGroundDivePunch.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioSlidePredicates.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioBeginBraking.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioTripleJumpSelector.swift" \
  "$PROJECT_ROOT/SM64Modern/MarioYVelocity.swift" "$PROJECT_ROOT/SM64Modern/MarioSteepJump.swift" \
  "$PROJECT_ROOT/SM64Modern/SwiftGameplay.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_action_abi_support.swift" \
  "$PROJECT_ROOT/tests/sm64_modern_mario_punch_abi_smoke.swift" \
  "$BUILD_ROOT/sm64_modern_mario_punch_migration.o" \
  "$BUILD_ROOT/sm64_modern_mario_action_authority_stub.o" \
  -o "$BUILD_ROOT/sm64-modern-mario-punch-abi-smoke"

"$BUILD_ROOT/sm64-modern-mario-punch-abi-smoke"
