#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="SM64 Modern"
BUNDLE_ID="io.github.deestiz.sm64modern"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$PROJECT_ROOT/build/xcode-derived"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
SIGNING_IDENTITY="${SM64_MODERN_CODE_SIGN_IDENTITY:-Apple Development}"
DEBUG_ENTITLEMENTS="$PROJECT_ROOT/SM64Modern/SM64ModernDebug.entitlements"
DEFAULT_SAVE_ROOT="$PROJECT_ROOT/build/sm64-modern-state"

if [[ -z "${SM64_MODERN_CODE_SIGN_IDENTITY:-}" ]]; then
  if ! security find-identity -v -p codesigning 2>/dev/null | grep -Fq 'Apple Development:'; then
    # Local CI/managed shells often have no development certificate. Ad hoc
    # signing keeps the build artifact runnable without pretending it is a
    # distributable Developer ID product.
    SIGNING_IDENTITY="-"
  fi
fi

CODE_SIGN_ARGS=(--force --timestamp=none --sign "$SIGNING_IDENTITY")
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
  CODE_SIGN_ARGS+=(--options runtime)
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$PROJECT_ROOT"
if [[ "$MODE" == "--m7-shadow-live" || "$MODE" == "m7-shadow-live" ]]; then
  # The trace fingerprints the signed app directory. Re-linking between the
  # live record and shadow passes would correctly reject the trace at tick 0,
  # so shadow must reuse the exact product that produced the record.
  test -x "$APP_BINARY"
  codesign --verify --deep --strict "$APP_BUNDLE"
else
  "$PROJECT_ROOT/script/test_audio_ring.sh"
  "$PROJECT_ROOT/script/test_fixed_step_scheduler.sh"
  "$PROJECT_ROOT/script/test_mario_action_migration.sh"
  "$PROJECT_ROOT/script/test_mario_action_abi.sh"
  "$PROJECT_ROOT/script/test_mario_action_cancel_abi.sh"
  "$PROJECT_ROOT/script/test_mario_ground_step_abi.sh"
  "$PROJECT_ROOT/script/test_mario_air_step_abi.sh"
  "$PROJECT_ROOT/script/test_mario_water_step_abi.sh"
  "$PROJECT_ROOT/script/test_mario_bonk_abi.sh"
  "$PROJECT_ROOT/script/test_mario_terrain_abi.sh"
  "$PROJECT_ROOT/script/test_mario_quicksand_abi.sh"
  "$PROJECT_ROOT/script/test_mario_steep_push_abi.sh"
  "$PROJECT_ROOT/script/test_mario_terrain_sound_abi.sh"
  "$PROJECT_ROOT/script/test_mario_floor_predicates_abi.sh"
  "$PROJECT_ROOT/script/test_mario_forward_velocity_abi.sh"
  "$PROJECT_ROOT/script/test_mario_velocity_derivation_abi.sh"
  "$PROJECT_ROOT/script/test_mario_punch_abi.sh"
  "$PROJECT_ROOT/script/test_mario_wall_response_abi.sh"
  "$PROJECT_ROOT/script/test_mario_walk_animation_abi.sh"
  "$PROJECT_ROOT/script/test_mario_held_walk_animation_abi.sh"
  "$PROJECT_ROOT/script/test_mario_slope_acceleration_abi.sh"
  "$PROJECT_ROOT/script/test_mario_slope_deceleration_abi.sh"
  "$PROJECT_ROOT/script/test_mario_decelerating_speed_abi.sh"
  "$PROJECT_ROOT/script/test_mario_shell_speed_abi.sh"
  "$PROJECT_ROOT/script/test_mario_landing_acceleration_abi.sh"
  "$PROJECT_ROOT/script/test_mario_gravity_abi.sh"
  "$PROJECT_ROOT/script/test_mario_vertical_wind_abi.sh"
  "$PROJECT_ROOT/script/test_mario_sliding_abi.sh"
  "$PROJECT_ROOT/script/test_mario_ground_dive_punch_abi.sh"
  "$PROJECT_ROOT/script/test_mario_slide_predicates_abi.sh"
  "$PROJECT_ROOT/script/test_mario_begin_braking_abi.sh"
  "$PROJECT_ROOT/script/test_mario_triple_jump_selector_abi.sh"
  "$PROJECT_ROOT/script/test_mario_y_velocity_abi.sh"
  "$PROJECT_ROOT/script/test_mario_steep_jump_abi.sh"
  "$PROJECT_ROOT/script/test_timebase_audit.sh"
  "$PROJECT_ROOT/script/test_engine_authority.sh"
  "$PROJECT_ROOT/script/test_configuration.sh"
  "$PROJECT_ROOT/script/test_configuration_runtime.sh"
  "$PROJECT_ROOT/script/test_cheats.sh"
  "$PROJECT_ROOT/script/test_hud.sh"
  "$PROJECT_ROOT/script/test_hud_render.sh"
  "$PROJECT_ROOT/script/test_dialog.sh"
  "$PROJECT_ROOT/script/test_dialog_text_pause.sh"
  "$PROJECT_ROOT/script/test_course_exit_cadence.sh"
  "$PROJECT_ROOT/script/test_front_end.sh"
  "$PROJECT_ROOT/script/test_front_end_render.sh"
  "$PROJECT_ROOT/script/test_frontend_migration.sh"
  "$PROJECT_ROOT/script/test_pause_migration.sh"
  "$PROJECT_ROOT/script/test_audio.sh"
  "$PROJECT_ROOT/script/test_audio_sequence.sh"
  "$PROJECT_ROOT/script/test_audio_pools.sh"
  "$PROJECT_ROOT/script/test_audio_residency.sh"
  "$PROJECT_ROOT/script/test_audio_trace.sh"
  "$PROJECT_ROOT/script/test_audio_synthesis.sh"
  "$PROJECT_ROOT/script/test_audio_voice.sh"
  "$PROJECT_ROOT/script/test_audio_stream.sh"
  "$PROJECT_ROOT/script/test_audio_mixer.sh"
  "$PROJECT_ROOT/script/test_audio_promotion.sh"
  "$PROJECT_ROOT/script/test_audio_migration.sh"
  "$PROJECT_ROOT/script/test_display_list_packet.sh"
  "$PROJECT_ROOT/script/test_render_packet_capture.sh"
  "$PROJECT_ROOT/script/test_render_trace_adapter.sh"
  "$PROJECT_ROOT/script/test_render_file_comparison.sh"
  "$PROJECT_ROOT/script/test_mario_face.sh"
  "$PROJECT_ROOT/script/test_mario_face_animation.sh"
  "$PROJECT_ROOT/script/test_mario_face_animation_payload.sh"
  "$PROJECT_ROOT/script/test_mario_face_expression.sh"
  "$PROJECT_ROOT/script/test_mario_face_resource_manifest.sh"
  "$PROJECT_ROOT/script/test_mario_face_resource_manifest_codec.sh"
  "$PROJECT_ROOT/script/test_mario_face_resource_catalog.sh"
  "$PROJECT_ROOT/script/test_mario_face_content_pack.sh"
  "$PROJECT_ROOT/script/test_mario_face_payload_inventory.sh"
  "$PROJECT_ROOT/script/test_mario_face_payload_bundle.sh"
  "$PROJECT_ROOT/script/test_mario_face_expression_composition.sh"
  "$PROJECT_ROOT/script/test_mario_face_render_packet.sh"
  "$PROJECT_ROOT/script/test_mario_face_route_resources.sh"
  "$PROJECT_ROOT/script/test_live_route_oracle.sh" full
  "$PROJECT_ROOT/script/test_mario_face_route_shards.sh"
  "$PROJECT_ROOT/script/test_mario_face_metal_binding.sh"
  "$PROJECT_ROOT/script/test_mario_face_texture_provider.sh"
  "$PROJECT_ROOT/script/test_mario_face_texture_upload_admission.sh"
  "$PROJECT_ROOT/script/test_mario_face_texture_residency.sh"
  "$PROJECT_ROOT/script/test_mario_face_source_geometry.sh"
  "$PROJECT_ROOT/script/test_mario_face_metal_transform.sh"
  "$PROJECT_ROOT/script/test_mario_face_draw_list.sh"
  "$PROJECT_ROOT/script/test_mario_face_texture_coordinates.sh"
  "$PROJECT_ROOT/script/test_save_replay_artifact.sh"
  "$PROJECT_ROOT/script/test_save_replay_execution.sh"
  "$PROJECT_ROOT/script/test_camera_migration.sh"
  "$PROJECT_ROOT/script/test_engine_runtime.sh"
  "$PROJECT_ROOT/script/test_behavior_manifest.sh"
  "$PROJECT_ROOT/script/test_route_shards.sh"
  "$PROJECT_ROOT/script/test_route_shard_replay.sh"
  "$PROJECT_ROOT/script/test_route_shard_worker_result.sh"
  "$PROJECT_ROOT/script/test_route_shard_merge.sh"
  "$PROJECT_ROOT/script/test_mad_piano.sh"
  "$PROJECT_ROOT/script/test_npc_menu.sh"
  "$PROJECT_ROOT/script/test_pushable_metal_box.sh"
  "$PROJECT_ROOT/script/test_squarish_path_moving.sh"
  "$PROJECT_ROOT/script/test_sushi_shark.sh"
  "$PROJECT_ROOT/script/test_tilting_bowser_lava_platform.sh"
  "$PROJECT_ROOT/script/test_act_selector.sh"
  "$PROJECT_ROOT/script/test_lll_bowser_puzzle.sh"
  "$PROJECT_ROOT/script/test_snowman_bottom.sh"
  "$PROJECT_ROOT/script/test_treasure_chest.sh"
  "$PROJECT_ROOT/script/test_behavior_dispatch_bridge.sh"
  "$PROJECT_ROOT/script/test_behavior_coverage.sh"
  "$PROJECT_ROOT/script/test_arrow_lift.sh"
  "$PROJECT_ROOT/script/test_seesaw_platform.sh"
  "$PROJECT_ROOT/script/test_swing_platform.sh"
  "$PROJECT_ROOT/script/test_rotating_platform.sh"
  "$PROJECT_ROOT/script/test_ttc_moving_bar.sh"
  "$PROJECT_ROOT/script/test_ttc_spinner.sh"
  "$PROJECT_ROOT/script/test_ttc_treadmill.sh"
  "$PROJECT_ROOT/script/test_ttc_pendulum.sh"
  "$PROJECT_ROOT/script/test_ttc_elevator.sh"
  "$PROJECT_ROOT/script/test_ttc_rotating_solid.sh"
  "$PROJECT_ROOT/script/test_ttc_2d_rotator.sh"
  "$PROJECT_ROOT/script/test_ttc_cog.sh"
  "$PROJECT_ROOT/script/test_pyramid_elevator.sh"
  "$PROJECT_ROOT/script/test_pyramid_top_fragment.sh"
  "$PROJECT_ROOT/script/test_pyramid_pillar_touch_detector.sh"
  "$PROJECT_ROOT/script/test_pyramid_top.sh"
  "$PROJECT_ROOT/script/test_ttc_pit_block.sh"
  "$PROJECT_ROOT/script/test_static_checkered_platform.sh"
  "$PROJECT_ROOT/script/test_bbh_tilting_trap_platform.sh"
  "$PROJECT_ROOT/script/test_lll_sinking_platform.sh"
  "$PROJECT_ROOT/script/test_wf_rotating_wooden_platform.sh"
  "$PROJECT_ROOT/script/test_rotating_octagonal_platform.sh"
  "$PROJECT_ROOT/script/test_wf_solid_tower_platform.sh"
  "$PROJECT_ROOT/script/test_wf_tower_platform.sh"
  "$PROJECT_ROOT/script/test_track_ball.sh"
  "$PROJECT_ROOT/script/test_wf_sliding_platform.sh"
  "$PROJECT_ROOT/script/test_wdw_express_elevator.sh"
  "$PROJECT_ROOT/script/test_lll_sinking_rock_block.sh"
  "$PROJECT_ROOT/script/test_ssl_moving_pyramid_wall.sh"
  "$PROJECT_ROOT/script/test_thi_island_top.sh"
  "$PROJECT_ROOT/script/test_volcano_falling_trap.sh"
  "$PROJECT_ROOT/script/test_rolling_log.sh"
  "$PROJECT_ROOT/script/test_lll_moving_octagonal_mesh.sh"
  "$PROJECT_ROOT/script/test_ferris_wheel_platform.sh"
  "$PROJECT_ROOT/script/test_checkerboard_platform.sh"
  "$PROJECT_ROOT/script/test_wf_tower_platform_group.sh"
  "$PROJECT_ROOT/script/test_lll_rotating_hexagonal_platform.sh"
  "$PROJECT_ROOT/script/test_lll_rotating_hex_flame.sh"
  "$PROJECT_ROOT/script/test_lll_rotating_fire_bar.sh"
  "$PROJECT_ROOT/script/test_activated_back_and_forth_platform.sh"
  "$PROJECT_ROOT/script/test_bitfs_sinking_platform.sh"
  "$PROJECT_ROOT/script/test_ddd_moving_pole.sh"
  "$PROJECT_ROOT/script/test_lll_rotating_hexagonal_ring.sh"
  "$PROJECT_ROOT/script/test_lll_floating_wood_bridge.sh"
  "$PROJECT_ROOT/script/test_squishable_platform.sh"
  "$PROJECT_ROOT/script/test_lll_drawbridge.sh"
  "$PROJECT_ROOT/script/test_idle_water_wave.sh"
  "$PROJECT_ROOT/script/test_waterfall_sound_loop.sh"
  "$PROJECT_ROOT/script/test_volcano_sound_loop.sh"
  "$PROJECT_ROOT/script/test_tumbling_bridge.sh"
  "$PROJECT_ROOT/script/test_floating_platform.sh"
  "$PROJECT_ROOT/script/test_jrb_floating_box.sh"
  "$PROJECT_ROOT/script/test_jrb_sliding_box.sh"
  "$PROJECT_ROOT/script/test_sunken_ship_part.sh"
  "$PROJECT_ROOT/script/test_sliding_platform_2.sh"
  "$PROJECT_ROOT/script/test_small_water_wave.sh"
  "$PROJECT_ROOT/script/test_ambient_sound_loop.sh"
  "$PROJECT_ROOT/script/test_rotating_exclamation_mark.sh"
  "$PROJECT_ROOT/script/test_water_air_bubble.sh"
  "$PROJECT_ROOT/script/test_object_bubble.sh"
  "$PROJECT_ROOT/script/test_water_droplet.sh"
  "$PROJECT_ROOT/script/test_water_mist.sh"
  "$PROJECT_ROOT/script/test_water_mist_2.sh"
  "$PROJECT_ROOT/script/test_water_splash.sh"
  "$PROJECT_ROOT/script/test_bubble_maybe.sh"
  "$PROJECT_ROOT/script/test_wind.sh"
  "$PROJECT_ROOT/script/test_jet_stream.sh"
  "$PROJECT_ROOT/script/test_jet_stream_water_ring.sh"
  "$PROJECT_ROOT/script/test_jet_stream_ring_spawner.sh"
  "$PROJECT_ROOT/script/test_manta_ray_water_ring.sh"
  "$PROJECT_ROOT/script/test_whirlpool.sh"
  "$PROJECT_ROOT/script/test_manta_ray.sh"
  "$PROJECT_ROOT/script/test_shallow_water_wave.sh"
  "$PROJECT_ROOT/script/test_water_splash_spawner.sh"
  "$PROJECT_ROOT/script/test_bubble_particle_spawner.sh"
  "$PROJECT_ROOT/script/test_piranha_waking_bubble.sh"
  "$PROJECT_ROOT/script/test_piranha_plant_bubble.sh"
  "$PROJECT_ROOT/script/test_wave_trail.sh"
  "$PROJECT_ROOT/script/test_strong_wind_particle.sh"
  "$PROJECT_ROOT/script/test_water_particle.sh"
  "$PROJECT_ROOT/script/test_plunge_bubble.sh"
  "$PROJECT_ROOT/script/test_breath_particle_spawner.sh"
  "$PROJECT_ROOT/script/test_mist_particle.sh"
  "$PROJECT_ROOT/script/test_tweester_sand_particle.sh"
  "$PROJECT_ROOT/script/test_flame_mario.sh"
  "$PROJECT_ROOT/script/test_black_smoke_bowser.sh"
  "$PROJECT_ROOT/script/test_black_smoke_upward.sh"
  "$PROJECT_ROOT/script/test_white_puff_smoke.sh"
  "$PROJECT_ROOT/script/test_white_puff_smoke_2.sh"
  "$PROJECT_ROOT/script/test_white_puff_explosion.sh"
  "$PROJECT_ROOT/script/test_dust_smoke.sh"
  "$PROJECT_ROOT/script/test_star_key_collection_puff_spawner.sh"
  "$PROJECT_ROOT/script/test_static_flame.sh"
  "$PROJECT_ROOT/script/test_flamethrower_flame.sh"
  "$PROJECT_ROOT/script/test_flame_bouncing.sh"
  "$PROJECT_ROOT/script/test_bowser_flame.sh"
  "$PROJECT_ROOT/script/test_blue_flames_group.sh"
  "$PROJECT_ROOT/script/test_bowser_flame_family.sh"
  "$PROJECT_ROOT/script/test_volcano_flames.sh"
  "$PROJECT_ROOT/script/test_koopa_shell_flame.sh"
  "$PROJECT_ROOT/script/test_flame_moving_forward_growing.sh"
  "$PROJECT_ROOT/script/test_beta_moving_flames.sh"
  "$PROJECT_ROOT/script/test_bowser_flame_spawn.sh"
  "$PROJECT_ROOT/script/test_small_piranha_flame.sh"
  "$PROJECT_ROOT/script/test_fire_spitter.sh"
  "$PROJECT_ROOT/script/test_fire_piranha_plant.sh"
  "$PROJECT_ROOT/script/test_flamethrower.sh"
  "$PROJECT_ROOT/script/test_celebration_star.sh"
  "$PROJECT_ROOT/script/test_celebration_star_sparkle.sh"
  "$PROJECT_ROOT/script/test_warp.sh"
  "$PROJECT_ROOT/script/test_ddd_warp.sh"
  "$PROJECT_ROOT/script/test_act_selector_star_type.sh"
  "$PROJECT_ROOT/script/test_collect_star.sh"
  "$PROJECT_ROOT/script/test_star_spawn_coordinates.sh"
  "$PROJECT_ROOT/script/test_spawned_star.sh"
  "$PROJECT_ROOT/script/test_unlock_door_star.sh"
  "$PROJECT_ROOT/script/test_ccm_touched_star_spawn.sh"
  "$PROJECT_ROOT/script/test_hidden_star.sh"
  "$PROJECT_ROOT/script/test_castle_cannon_grate.sh"
  "$PROJECT_ROOT/script/test_blue_coin.sh"
  "$PROJECT_ROOT/script/test_red_coin.sh"
  "$PROJECT_ROOT/script/test_star_door.sh"
  "$PROJECT_ROOT/script/test_cap_switch.sh"
  "$PROJECT_ROOT/script/test_metal_cap.sh"
  "$PROJECT_ROOT/script/test_vanish_cap.sh"
  "$PROJECT_ROOT/script/test_wing_cap.sh"
  "$PROJECT_ROOT/script/test_normal_cap.sh"
  "$PROJECT_ROOT/script/test_tower_door.sh"
  "$PROJECT_ROOT/script/test_openable_grill.sh"
  "$PROJECT_ROOT/script/test_door.sh"
  "$PROJECT_ROOT/script/test_hidden_object.sh"
  "$PROJECT_ROOT/script/test_recovery_heart.sh"
  "$PROJECT_ROOT/script/test_coin.sh"
  "$PROJECT_ROOT/script/test_coin_formation.sh"
  "$PROJECT_ROOT/script/test_coin_inside_boo.sh"
  "$PROJECT_ROOT/script/test_blue_fish.sh"
  "$PROJECT_ROOT/script/test_haunted_bookshelf.sh"
  "$PROJECT_ROOT/script/test_haunted_bookshelf_manager.sh"
  "$PROJECT_ROOT/script/test_haunted_chair.sh"
  "$PROJECT_ROOT/script/test_clam_shell.sh"
  "$PROJECT_ROOT/script/test_bobomb_anchor_mario.sh"
  "$PROJECT_ROOT/script/test_bub.sh"
  "$PROJECT_ROOT/script/test_bubba.sh"
  "$PROJECT_ROOT/script/test_bowling_ball.sh"
  "$PROJECT_ROOT/script/test_ddd_pole.sh"
  "$PROJECT_ROOT/script/test_donut_platform.sh"
  "$PROJECT_ROOT/script/test_courtyard_boo_triplet.sh"
  "$PROJECT_ROOT/script/test_falling_bowser_platform.sh"
  "$PROJECT_ROOT/script/test_giant_pole.sh"
  "$PROJECT_ROOT/script/test_koopa_flag.sh"
  "$PROJECT_ROOT/script/test_koopa_race_endpoint.sh"
  "$PROJECT_ROOT/script/test_wf_breakable_wall.sh"
  "$PROJECT_ROOT/script/test_unused_poundable_platform.sh"
  "$PROJECT_ROOT/script/test_yellow_background_menu.sh"
  "$PROJECT_ROOT/script/test_snow_mound.sh"
  "$PROJECT_ROOT/script/test_rr_cruiser_wing.sh"
  "$PROJECT_ROOT/script/test_spindrift.sh"
  "$PROJECT_ROOT/script/test_spindel.sh"
  "$PROJECT_ROOT/script/test_rr_rotating_bridge_platform.sh"
  "$PROJECT_ROOT/script/test_snowman_wind.sh"
  "$PROJECT_ROOT/script/test_mr_blizzard_snowball.sh"
  "$PROJECT_ROOT/script/test_end_cutscene_actor.sh"
  "$PROJECT_ROOT/script/test_end_birds.sh"
  "$PROJECT_ROOT/script/test_beginning_peach.sh"
  "$PROJECT_ROOT/script/test_butterfly.sh"
  "$PROJECT_ROOT/script/test_moving_coin.sh"
  "$PROJECT_ROOT/script/test_water_level.sh"
  "$PROJECT_ROOT/script/test_water_pillar.sh"
  "$PROJECT_ROOT/script/test_floor_switch.sh"
  "$PROJECT_ROOT/script/test_animated_floor_switch.sh"
  "$PROJECT_ROOT/script/test_hidden_one_up.sh"
  "$PROJECT_ROOT/script/test_breakable_box.sh"
  "$PROJECT_ROOT/script/test_jumping_box.sh"
  "$PROJECT_ROOT/script/test_kickable_board.sh"
  "$PROJECT_ROOT/script/test_bomp.sh"
  "$PROJECT_ROOT/script/test_thwomp.sh"
  "$PROJECT_ROOT/script/test_boulder.sh"
  "$PROJECT_ROOT/script/test_boulder_generator.sh"
  "$PROJECT_ROOT/script/test_horizontal_grindel.sh"
  "$PROJECT_ROOT/script/test_unused_particle_spawn.sh"
  "$PROJECT_ROOT/script/test_snowman_checkpoint.sh"
  "$PROJECT_ROOT/script/test_snowman_head.sh"
  "$PROJECT_ROOT/script/test_bowser_body_anchor.sh"
  "$PROJECT_ROOT/script/test_bowser_tail_anchor.sh"
  "$PROJECT_ROOT/script/test_beta_chest.sh"
  "$PROJECT_ROOT/script/test_beta_trampoline.sh"
  "$PROJECT_ROOT/script/test_beta_holdable.sh"
  "$PROJECT_ROOT/script/test_exclamation_box.sh"
  "$PROJECT_ROOT/script/test_orange_number.sh"
  "$PROJECT_ROOT/script/test_sound_rock.sh"
  "$PROJECT_ROOT/script/test_tox_box.sh"
  "$PROJECT_ROOT/script/test_environment_gate.sh"
  "$PROJECT_ROOT/script/test_clock_arm.sh"
  "$PROJECT_ROOT/script/test_castle_floor_trap.sh"
  "$PROJECT_ROOT/script/test_castle_flag.sh"
  "$PROJECT_ROOT/script/test_boo_cage.sh"
  "$PROJECT_ROOT/script/test_boo_key.sh"
  "$PROJECT_ROOT/script/test_boo_in_castle.sh"
  "$PROJECT_ROOT/script/test_merry_go_round.sh"
  "$PROJECT_ROOT/script/test_music_touch.sh"
  "$PROJECT_ROOT/script/test_text_surface.sh"
  "$PROJECT_ROOT/script/test_grand_star.sh"
  "$PROJECT_ROOT/script/test_beta_bowser_anchor.sh"
  "$PROJECT_ROOT/script/test_ground_particle_spawner.sh"
  "$PROJECT_ROOT/script/test_content_pack.sh"
  "$PROJECT_ROOT/script/test_oracle_trace.sh"
  "$PROJECT_ROOT/script/test_oracle_trace_swift.sh"
  "$PROJECT_ROOT/script/test_oracle_bridge.sh"
  "$PROJECT_ROOT/script/test_oracle_reachability.sh"
  xcodegen generate --spec project.yml
  xcodebuild \
    -project SM64Modern.xcodeproj \
    -scheme SM64Modern \
    -configuration Debug \
    -derivedDataPath "$DERIVED_DATA" \
    build \
    CODE_SIGNING_ALLOWED=NO

  # The sustained-execution entitlement remains on Release. Debug uses the
  # locally available Apple Development identity without mutating portal state.
  while IFS= read -r nested_code; do
    codesign \
      "${CODE_SIGN_ARGS[@]}" \
      "$nested_code"
  done < <(find "$APP_BUNDLE/Contents" -type f -name '*.dylib' -print)

  codesign \
    "${CODE_SIGN_ARGS[@]}" \
    --entitlements "$DEBUG_ENTITLEMENTS" \
    "$APP_BUNDLE"
  codesign --verify --deep --strict "$APP_BUNDLE"
fi

open_app() {
  local -a open_arguments=(
    --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT"
    --env SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT"
  )
  if [[ "${SM64_MODERN_AUDIO_PROMOTION:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_AUDIO_PROMOTION=1)
  fi
  if [[ "${SM64_MODERN_AUTOMATED_MENU:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_AUTOMATED_MENU=1)
  fi
  if [[ "${SM64_MODERN_AUTOMATED_GAMEPLAY:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_AUTOMATED_GAMEPLAY=1)
  fi
  if [[ "${SM64_MODERN_AUTOMATED_MARIO:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_AUTOMATED_MARIO=1)
  fi
  if [[ "${SM64_MODERN_AUTOMATED_MARIO_ACTION:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_AUTOMATED_MARIO_ACTION=1)
  fi
  if [[ "${SM64_MODERN_AUTOMATED_MARIO_CANCEL:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_AUTOMATED_MARIO_CANCEL=1)
  fi
  if [[ "${SM64_MODERN_AUTOMATED_MARIO_GROUND_STEP:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_AUTOMATED_MARIO_GROUND_STEP=1)
  fi
  if [[ "${SM64_MODERN_RENDER_PACKET_CAPTURE:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_RENDER_PACKET_CAPTURE=1)
  fi
  if [[ "${SM64_MODERN_MARIO_FACE_TEXTURE_UPLOAD:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_MARIO_FACE_TEXTURE_UPLOAD=1)
  fi
  if [[ "${SM64_MODERN_MARIO_FACE_DRAW:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_MARIO_FACE_DRAW=1)
  fi
  if [[ "${SM64_MODERN_MARIO_FACE_TEXTURE_DRAW:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_MARIO_FACE_TEXTURE_DRAW=1)
  fi
  if [[ "${SM64_MODERN_M34_STRESS:-0}" == "1" ]]; then
    open_arguments+=(--env SM64_MODERN_M34_STRESS=1)
  fi
  if [[ "${SM64_MODERN_MARIO_FACE_DRAW:-0}" == "1" ]]; then
    local runtime_payload="$PROJECT_ROOT/build/sm64-modern-runtime/source_manifest/mario_face_payloads.mfpb"
    local payload_tool="$PROJECT_ROOT/build/sm64-modern-mario-face-payload-bundle/tool/mario-face-payload-bundle"
    if [[ -x "$payload_tool" ]]; then
      mkdir -p "$(dirname "$runtime_payload")"
      "$payload_tool" "$runtime_payload" >/dev/null
      open_arguments+=(--env SM64_MODERN_MARIO_FACE_PAYLOAD_PATH="$runtime_payload")
    fi
  fi
  if [[ -n "${SM64_MODERN_RENDER_PACKET_PATH:-}" ]]; then
    open_arguments+=(--env SM64_MODERN_RENDER_PACKET_PATH="$SM64_MODERN_RENDER_PACKET_PATH")
  fi
  if [[ -n "${SM64_MODERN_ORACLE_TRACE_MODE:-}" ]]; then
    open_arguments+=(--env SM64_MODERN_ORACLE_TRACE_MODE="$SM64_MODERN_ORACLE_TRACE_MODE")
  fi
  if [[ -n "${SM64_MODERN_ORACLE_TRACE_PATH:-}" ]]; then
    open_arguments+=(--env SM64_MODERN_ORACLE_TRACE_PATH="$SM64_MODERN_ORACLE_TRACE_PATH")
  fi
  if [[ -n "${SM64_MODERN_ORACLE_TRACE_TICKS:-}" ]]; then
    open_arguments+=(--env SM64_MODERN_ORACLE_TRACE_TICKS="$SM64_MODERN_ORACLE_TRACE_TICKS")
  fi
  /usr/bin/open -n "$APP_BUNDLE" "${open_arguments[@]}"
}

wait_for_app_pid() {
  local app_pid=""
  for _ in {1..50}; do
    app_pid="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
    if [[ -n "$app_pid" ]]; then
      printf '%s\n' "$app_pid"
      return 0
    fi
    sleep 0.1
  done
  return 1
}

wait_for_app_exit() {
  local app_pid="$1"
  for _ in {1..150}; do
    if ! kill -0 "$app_pid" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

wait_for_app_exit_long() {
  local app_pid="$1"
  for _ in {1..3600}; do
    if ! kill -0 "$app_pid" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    env \
      SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT" \
      lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --metal-validation|metal-validation)
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT" \
      --env MTL_DEBUG_LAYER=1 \
      --env MTL_SHADER_VALIDATION=1 \
      --env MTL_SHADER_VALIDATION_REPORT_TO_STDERR=1
    ;;
  --metal-hud|metal-hud)
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT" \
      --env MTL_HUD_ENABLED=1 \
      --env MTL_HUD_LOG_ENABLED=1
    ;;
  --metal-capture|metal-capture)
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_SAVE_DIR="$DEFAULT_SAVE_ROOT" \
      --env MTL_CAPTURE_ENABLED=1 \
      --env MTLCAPTURE_WAIT_FOR_SIGNAL=1
    ;;
  --verify|verify)
    open_app
    app_pid=""
    for _ in {1..50}; do
      app_pid="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
      if [[ -n "$app_pid" ]]; then
        break
      fi
      sleep 0.1
    done
    [[ -n "$app_pid" ]]
    sleep 3
    test "$(defaults read "$APP_BUNDLE/Contents/Info" CFBundleIdentifier)" = "$BUNDLE_ID"
    runtime_log="$(/usr/bin/log show --last 2m --style compact \
      --predicate "processIdentifier == $app_pid && subsystem == \"$BUNDLE_ID\"")"
    if [[ "${SM64_MODERN_AUTOMATED_MENU:-0}" == "1" ]]; then
      # Unified-log indexing can lag the owner thread by a few hundred
      # milliseconds. Poll the same process-scoped stream until the authored
      # input pulse has crossed the front-end reducer or the bounded wait
      # expires; never turn an observer-install line into route evidence.
      for _ in {1..20}; do
        if grep -Fq 'swift_frontend_transition' <<< "$runtime_log"; then
          break
        fi
        sleep 0.25
        runtime_log="$(/usr/bin/log show --last 2m --style compact \
          --predicate "processIdentifier == $app_pid && subsystem == \"$BUNDLE_ID\"")"
      done
    fi
    for expected in \
      'window_ready layer=CAMetalLayer' \
      'metal_device_ready' \
      'metal_display_link_started owner_main=false' \
      'metal_scene_initialized' \
      'metal_scene_presented frame=1' \
      'engine_thread_started' \
      'input_service_ready' \
      'input_bridge_installed abi=1' \
      'frontend_bridge_installed abi=1 authority=swift state_authority=c render_authority=c' \
      'pause_menu_bridge_installed abi=1 authority=swift state_authority=c render_authority=c' \
      'gameplay_bridge_installed abi=1 slices=mario_buttons,mario_ground_speed,mario_action,mario_action_cancel,mario_ground_step,mario_air_step,mario_water_step,mario_bonk,mario_terrain_impulse,mario_quicksand,mario_steep_push,mario_terrain_sound,mario_floor_predicates,mario_forward_velocity,mario_velocity_derivation,mario_punch,mario_wall_response,mario_walk_animation,mario_held_walk_animation,mario_slope_acceleration,mario_slope_deceleration,mario_decelerating_speed,mario_shell_speed,mario_landing_acceleration,mario_gravity,mario_vertical_wind,mario_sliding,mario_ground_dive_punch,mario_slide_predicates,mario_begin_braking,mario_triple_jump_selector,mario_y_velocity,mario_steep_jump,bobomb_release' \
      'input_snapshot_started owner_main=false' \
      'swift_frontend_observer' \
      'audio_service_started input_hz=32000 format=s16_interleaved_stereo' \
      'audio_sequence_bridge_installed abi=1 authority=swift pcm_authority=c' \
      'audio_enqueue_started blocks_per_native_step=1' \
      'audio_render_started' \
      'timebase_configured simulation_hz=60/1 legacy_hz=30/1 paired_ticks=2' \
      'fixed_step_scheduler_started clock=monotonic_raw max_catch_up=2' \
      'lifecycle_running cadence_hz=60/1 capabilities=rendering,input,audio' \
      'presentation_cadence native_hz=60/1 legacy_hz=30/1 drawable_per_native_tick=true' \
      'fixed_step_scheduler_status step=1' \
      'lifecycle_step count=1'; do
      grep -Fq "$expected" <<< "$runtime_log"
    done
    printf '%s\n' "$runtime_log" \
      | grep -E 'window_ready layer=CAMetalLayer|metal_device_ready|metal_display_link_started|metal_scene_initialized|metal_scene_presented frame=1|engine_thread_started|input_service_ready|input_bridge_installed|frontend_bridge_installed|pause_menu_bridge_installed|gameplay_bridge_installed|input_snapshot_started|swift_frontend_observer|swift_pause_menu_observer|audio_service_started|audio_enqueue_started|audio_render_started|timebase_configured|fixed_step_scheduler_(started|status)|lifecycle_running|presentation_cadence|lifecycle_step count=1'
    if [[ "${SM64_MODERN_AUDIO_PROMOTION:-0}" == "1" ]]; then
      for expected in \
        'swift_audio_promotion_started' \
        'swift_audio_promotion_tick'; do
        grep -Fq "$expected" <<< "$runtime_log"
      done
      printf '%s\n' "$runtime_log" | grep -E 'swift_audio_promotion_(started|tick)'
    fi
    if [[ "${SM64_MODERN_AUTOMATED_MENU:-0}" == "1" ]]; then
      # The opt-in route uses the real AppleInputService -> C input boundary;
      # require evidence that it crossed the authored front-end reducer rather
      # than merely installing the observer.
      grep -Fq 'swift_frontend_transition' <<< "$runtime_log"
      grep -Eq 'swift_frontend_observer screen=[0-9]+ tick=[1-9][0-9]*' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'swift_frontend_transition|swift_frontend_observer screen='
    fi
    if [[ "${SM64_MODERN_AUTOMATED_MENU:-0}" == "1" && "${SM64_MODERN_AUTOMATED_GAMEPLAY:-0}" == "1" ]]; then
      # The combined menu/gameplay route must also enter and exercise the
      # authored pause reducer, including at least one completed outcome.
      grep -Fq 'swift_pause_menu_observer' <<< "$runtime_log"
      grep -Fq 'swift_pause_menu_outcome' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'swift_pause_menu_observer|swift_pause_menu_outcome'
    fi
    if [[ "${SM64_MODERN_RENDER_PACKET_CAPTURE:-0}" == "1" ]]; then
      grep -Fq 'swift_render_packet_capture frame=1' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'swift_render_packet_capture frame=1'
    fi
    if [[ "${SM64_MODERN_MARIO_FACE_TEXTURE_UPLOAD:-0}" == "1" ]]; then
      grep -Eq 'mario_face_texture_upload_admitted route=2 entries=3 source_bytes=5120 upload_bytes=12288 generations=1-3 pending_residency=3 fingerprint=[0-9]+' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'mario_face_texture_upload_admitted'
      grep -Eq 'mario_face_texture_resident route=2 private_textures=3 generations=1-3 residency_committed=1 residency_requested=1 barrier_producer=blit_to_fragment visibility=device barrier_consumer=blit_to_fragment visibility=device fingerprint=[0-9]+' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'mario_face_texture_resident'
    fi
    if [[ "${SM64_MODERN_MARIO_FACE_DRAW:-0}" == "1" ]]; then
      grep -Eq 'mario_face_composition_admitted source=mfpb bank=0 frame_q16=65536 resident_channels=25 unavailable_channels=0 packet_fingerprint=[0-9]+' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'mario_face_composition_admitted'
      grep -Eq 'mario_face_geometry_source_admitted source_path=src/goddard/dynlists/dynlist_mario_face\.c schema=2 vertices=440 faces=877 materials=8 source_digest=[0-9a-f:]+ packet_fingerprint=[0-9]+' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'mario_face_geometry_source_admitted'
      grep -Eq 'mario_face_geometry_admitted mesh=1 vertices=440 faces=877 materials=8 vertex_bytes=[0-9]+ index_bytes=5262 material_index_bytes=5262 material_bytes=128 transform_fingerprint=[0-9]+ texture_coordinate_fingerprint=[0-9]+ packet_fingerprint=[0-9]+' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'mario_face_geometry_admitted'
      grep -Eq 'mario_face_transform_admitted route=2 schema=1 component=226 frame_q16=65536 viewport=320x240 transform_fingerprint=[0-9]+' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'mario_face_transform_admitted'
      grep -Eq 'mario_face_mesh_draw route=2 mesh=1 source_path=dynlist_mario_face window_faces=877 source_faces=877 source_vertices=440 materials=8 encoder=isolated_render private_geometry=1 private_index_buffer=1 private_material_index_buffer=1 private_material_buffer=1 transform_schema=1 transform_fingerprint=[0-9]+ texture_coordinate_fingerprint=[0-9]+ packet_fingerprint=[0-9]+' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'mario_face_mesh_draw'
    fi
    if [[ "${SM64_MODERN_MARIO_FACE_TEXTURE_DRAW:-0}" == "1" ]]; then
      grep -Eq 'mario_face_texture_draw texture_id=768 sampler=1 source_format=ia8 upload_format=rgba8 generated_coordinates=goddard_normal_q8_st_generated_st hilite_origin=64,64 texture_coordinate_fingerprint=[0-9]+ private_texture=1 encoder=isolated_render' <<< "$runtime_log"
      printf '%s\n' "$runtime_log" | grep -E 'mario_face_texture_draw'
    fi
    # The bounded native host may have completed its own clean shutdown during
    # the verification sleep; quitting an already-stopped app is harmless.
    /usr/bin/osascript -e "tell application id \"$BUNDLE_ID\" to quit" || true
    for _ in {1..50}; do
      if ! kill -0 "$app_pid" >/dev/null 2>&1; then
        shutdown_log="$(/usr/bin/log show --last 2m --style compact \
          --predicate "processIdentifier == $app_pid && subsystem == \"$BUNDLE_ID\"")"
        for expected in \
          'audio_service_stopped' \
          'swift_audio_sequence_observer_finished' \
          'swift_pause_menu_observer_finished' \
          'swift_frontend_observer_finished' \
          'platform_shutdown' \
          'metal_shutdown_drained' \
          'engine_thread_finished status=0' \
          'application_stopped'; do
          grep -Fq "$expected" <<< "$shutdown_log"
        done
        if [[ "${SM64_MODERN_AUTOMATED_MENU:-0}" == "1" ]]; then
          grep -Eq 'swift_frontend_observer_finished events=[1-9][0-9]* transitions=[1-9][0-9]*' <<< "$shutdown_log"
          printf '%s\n' "$shutdown_log" | grep -E 'swift_frontend_observer_finished'
        fi
        if [[ "${SM64_MODERN_AUTOMATED_MENU:-0}" == "1" && "${SM64_MODERN_AUTOMATED_GAMEPLAY:-0}" == "1" ]]; then
          grep -Eq 'swift_pause_menu_observer_finished events=[1-9][0-9]* outcomes=[1-9][0-9]*' <<< "$shutdown_log"
          printf '%s\n' "$shutdown_log" | grep -E 'swift_pause_menu_observer_finished'
        fi
        if [[ "${SM64_MODERN_AUDIO_PROMOTION:-0}" == "1" ]]; then
          grep -Fq 'swift_audio_promotion_finished' <<< "$shutdown_log"
          printf '%s\n' "$shutdown_log" | grep -E 'swift_audio_promotion_finished'
        fi
        printf '%s\n' "$shutdown_log" \
          | grep -E 'audio_service_stopped|swift_audio_sequence_observer_finished|swift_pause_menu_observer_finished|swift_frontend_observer_finished|metal_shutdown_drained|platform_shutdown|engine_thread_finished status=0|application_stopped'
        exit 0
      fi
      sleep 0.1
    done
    echo "$APP_NAME did not terminate cleanly" >&2
    exit 1
    ;;
  --parity-verify|parity-verify)
    PARITY_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-parity.XXXXXX")"
    trap '/bin/rm -rf -- "$PARITY_TEMP"' EXIT
    TRACE_PATH="$PARITY_TEMP/gameplay-v3.trace"
    RECORD_SAVE="$PARITY_TEMP/record-save"
    REPLAY_SAVE="$PARITY_TEMP/replay-save"
    mkdir -p "$RECORD_SAVE" "$REPLAY_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$TRACE_PATH" \
      --env SM64_MODERN_PARITY_TICKS=90 \
      --env SM64_MODERN_SAVE_DIR="$RECORD_SAVE"
    record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$record_pid"
    test -s "$TRACE_PATH"
    record_log="$(/usr/bin/log show --last 2m --style compact \
      --predicate "processIdentifier == $record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$record_log"
    grep -Fq 'bounded_parity_run_complete steps=90' <<< "$record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=replay \
      --env SM64_MODERN_PARITY_TRACE="$TRACE_PATH" \
      --env SM64_MODERN_PARITY_TICKS=90 \
      --env SM64_MODERN_SAVE_DIR="$REPLAY_SAVE"
    replay_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$replay_pid"
    replay_log="$(/usr/bin/log show --last 2m --style compact \
      --predicate "processIdentifier == $replay_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=2 schema=3' <<< "$replay_log"
    grep -Fq 'bounded_parity_run_complete steps=90' <<< "$replay_log"
    grep -Fq 'parity_session_finished status=0' <<< "$replay_log"
    if grep -Fq 'parity_first_divergence' <<< "$replay_log"; then
      echo "Replay reported a parity divergence" >&2
      exit 1
    fi
    printf '%s\n' "$record_log" "$replay_log" \
      | grep -E 'parity_session_started|bounded_parity_run_complete|parity_result subsystem=|parity_session_finished'
    ;;
  --m11-shadow-verify|m11-shadow-verify)
    M11_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m11-shadow.XXXXXX")"
    trap '/bin/rm -rf -- "$M11_TEMP"' EXIT
    M11_TRACE="$M11_TEMP/mario-ground-speed-v3.trace"
    M11_RECORD_SAVE="$M11_TEMP/record-save"
    M11_SHADOW_SAVE="$M11_TEMP/shadow-save"
    M11_TICKS="${SM64_MODERN_M11_TICKS:-360}"
    mkdir -p "$M11_RECORD_SAVE" "$M11_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M11_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M11_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M11_RECORD_SAVE" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1
    m11_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m11_record_pid"
    test -s "$M11_TRACE"
    m11_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m11_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m11_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M11_TICKS" <<< "$m11_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m11_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m11_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M11_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M11_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M11_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_SLICES=mario-buttons \
      --env SM64_MODERN_SWIFT_PROMOTE=0 \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1
    m11_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m11_shadow_pid"
    m11_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m11_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m11_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1 promote=false' <<< "$m11_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m11_shadow_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=[1-9][0-9]* mario_ground_speed=[1-9][0-9]*' <<< "$m11_shadow_log"
    grep -Fq "bounded_parity_run_complete steps=$M11_TICKS" <<< "$m11_shadow_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m11_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m11_shadow_log"
    printf '%s\n' "$m11_record_log" "$m11_shadow_log" \
      | grep -E 'parity_session_started|swift_shadow_started|swift_gameplay_evidence|bounded_parity_run_complete|parity_result subsystem=1|parity_session_finished|engine_thread_finished status=0'
    ;;
  --m13-shadow-verify|m13-shadow-verify)
    M13_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m13-shadow.XXXXXX")"
    trap '/bin/rm -rf -- "$M13_TEMP"' EXIT
    M13_TRACE="$M13_TEMP/bobomb-release-v3.trace"
    M13_RECORD_SAVE="$M13_TEMP/record-save"
    M13_SHADOW_SAVE="$M13_TEMP/shadow-save"
    M13_TICKS="${SM64_MODERN_M13_TICKS:-360}"
    mkdir -p "$M13_RECORD_SAVE" "$M13_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M13_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M13_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M13_RECORD_SAVE" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m13_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m13_record_pid"
    test -s "$M13_TRACE"
    m13_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m13_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m13_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M13_TICKS" <<< "$m13_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m13_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m13_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M13_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M13_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M13_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_SLICES=bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=0 \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m13_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m13_shadow_pid"
    m13_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m13_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m13_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=4 promote=false' <<< "$m13_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m13_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*bobomb_release=[1-9][0-9]*' <<< "$m13_shadow_log"
    grep -Fq "bounded_parity_run_complete steps=$M13_TICKS" <<< "$m13_shadow_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m13_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m13_shadow_log"
    printf '%s\n' "$m13_record_log" "$m13_shadow_log" \
      | grep -E 'parity_session_started|swift_shadow_started|swift_gameplay_evidence|bounded_parity_run_complete|parity_result subsystem=4|parity_session_finished|engine_thread_finished status=0'
    ;;
  --m14-native-verify|m14-native-verify)
    M14_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m14-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M14_TEMP"' EXIT
    M14_TRACE="$M14_TEMP/bobomb-native-default-v1.trace"
    M14_RECORD_SAVE="$M14_TEMP/record-save"
    M14_SHADOW_SAVE="$M14_TEMP/shadow-save"
    M14_TICKS="${SM64_MODERN_M14_TICKS:-8}"
    M14_SWIFT_TICKS="${SM64_MODERN_M14_SWIFT_TICKS:-8}"
    M14_TOTAL_TICKS=$((M14_TICKS + M14_SWIFT_TICKS))
    mkdir -p "$M14_RECORD_SAVE" "$M14_SHADOW_SAVE"

    # Explicit C fallback records the deterministic Battlefield trace. The
    # authority telemetry makes the default safe path observable.
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M14_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M14_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M14_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m14_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m14_record_pid"
    test -s "$M14_TRACE"
    m14_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m14_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m14_record_log"
    grep -Fq 'swift_authority_fallback=c' <<< "$m14_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M14_TICKS" <<< "$m14_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m14_record_log"
    grep -Eq 'swift_gameplay_evidence .*bobomb_release=0' <<< "$m14_record_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m14_record_log"

    # Native Swift authority is never enabled directly. This pass requires a
    # bounded shadow comparison, promotes only after eligibility/evidence, and
    # then proves post-promotion callback execution for a second bounded slice.
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M14_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M14_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M14_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M14_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m14_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m14_shadow_pid"
    m14_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m14_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m14_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m14_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=4 promote=true' <<< "$m14_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*bobomb_release=[1-9][0-9]*' <<< "$m14_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m14_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=4' <<< "$m14_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M14_TOTAL_TICKS authority_steps=$M14_SWIFT_TICKS" <<< "$m14_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m14_shadow_log"
    printf '%s\n' "$m14_record_log" "$m14_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=4|engine_thread_finished status=0'
    ;;
  --m15-native-verify|m15-native-verify)
    M15_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m15-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M15_TEMP"' EXIT
    M15_TRACE="$M15_TEMP/mario-native-v1.trace"
    M15_RECORD_SAVE="$M15_TEMP/record-save"
    M15_SHADOW_SAVE="$M15_TEMP/shadow-save"
    M15_TICKS="${SM64_MODERN_M15_TICKS:-8}"
    M15_SWIFT_TICKS="${SM64_MODERN_M15_SWIFT_TICKS:-8}"
    M15_TOTAL_TICKS=$((M15_TICKS + M15_SWIFT_TICKS))
    mkdir -p "$M15_RECORD_SAVE" "$M15_SHADOW_SAVE"

    # The C record exercises both production Mario callbacks and the existing
    # Bob-omb actor callback on the real game-owner thread. The Mario probe is
    # opt-in and commits its scalar outputs before the canonical snapshots.
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M15_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M15_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M15_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m15_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m15_record_pid"
    test -s "$M15_TRACE"
    m15_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m15_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m15_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M15_TICKS" <<< "$m15_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m15_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m15_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0' <<< "$m15_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m15_record_log"

    # Shadow must match both subsystems byte-for-byte, then promote only after
    # exact candidate coverage and nonzero Swift callback evidence. The second
    # bounded slice proves native Swift callbacks continue after promotion.
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M15_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M15_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M15_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-buttons,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M15_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m15_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m15_shadow_pid"
    m15_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m15_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m15_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m15_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m15_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m15_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m15_shadow_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=[1-9][0-9]* mario_ground_speed=[1-9][0-9]* bobomb_release=[1-9][0-9]*' <<< "$m15_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m15_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M15_TOTAL_TICKS authority_steps=$M15_SWIFT_TICKS" <<< "$m15_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m15_shadow_log"
    printf '%s\n' "$m15_record_log" "$m15_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m16-native-verify|m16-native-verify)
    M16_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m16-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M16_TEMP"' EXIT
    M16_TRACE="$M16_TEMP/mario-action-native-v1.trace"
    M16_RECORD_SAVE="$M16_TEMP/record-save"
    M16_SHADOW_SAVE="$M16_TEMP/shadow-save"
    M16_TICKS="${SM64_MODERN_M16_TICKS:-8}"
    M16_SWIFT_TICKS="${SM64_MODERN_M16_SWIFT_TICKS:-8}"
    M16_TOTAL_TICKS=$((M16_TICKS + M16_SWIFT_TICKS))
    mkdir -p "$M16_RECORD_SAVE" "$M16_SHADOW_SAVE"

    # The C pass enters the real set_mario_action seam through the opt-in
    # deterministic owner-thread sequence. Unsupported action families remain
    # on the original C path by contract.
    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M16_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M16_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M16_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_ACTION=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m16_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m16_record_pid"
    test -s "$M16_TRACE"
    m16_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m16_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m16_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M16_TICKS" <<< "$m16_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m16_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m16_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0' <<< "$m16_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m16_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M16_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M16_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M16_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-action,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M16_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_ACTION=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m16_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m16_shadow_pid"
    m16_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m16_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m16_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m16_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m16_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m16_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m16_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_action=[1-9][0-9]*' <<< "$m16_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m16_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M16_TOTAL_TICKS authority_steps=$M16_SWIFT_TICKS" <<< "$m16_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m16_shadow_log"
    printf '%s\n' "$m16_record_log" "$m16_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m17-native-verify|m17-native-verify)
    M17_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m17-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M17_TEMP"' EXIT
    M17_TRACE="$M17_TEMP/mario-action-cancel-native-v1.trace"
    M17_RECORD_SAVE="$M17_TEMP/record-save"
    M17_SHADOW_SAVE="$M17_TEMP/shadow-save"
    M17_TICKS="${SM64_MODERN_M17_TICKS:-8}"
    M17_SWIFT_TICKS="${SM64_MODERN_M17_SWIFT_TICKS:-8}"
    M17_TOTAL_TICKS=$((M17_TICKS + M17_SWIFT_TICKS))
    mkdir -p "$M17_RECORD_SAVE" "$M17_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M17_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M17_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M17_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_CANCEL=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m17_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m17_record_pid"
    test -s "$M17_TRACE"
    m17_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m17_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m17_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M17_TICKS" <<< "$m17_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m17_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m17_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0' <<< "$m17_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m17_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M17_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M17_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M17_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-action-cancel,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M17_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_CANCEL=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m17_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m17_shadow_pid"
    m17_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m17_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m17_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m17_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m17_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m17_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m17_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_action_cancel=[1-9][0-9]*' <<< "$m17_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m17_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M17_TOTAL_TICKS authority_steps=$M17_SWIFT_TICKS" <<< "$m17_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m17_shadow_log"
    printf '%s\n' "$m17_record_log" "$m17_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m18-native-verify|m18-native-verify)
    M18_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m18-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M18_TEMP"' EXIT
    M18_TRACE="$M18_TEMP/mario-ground-step-native-v1.trace"
    M18_RECORD_SAVE="$M18_TEMP/record-save"
    M18_SHADOW_SAVE="$M18_TEMP/shadow-save"
    M18_TICKS="${SM64_MODERN_M18_TICKS:-8}"
    M18_SWIFT_TICKS="${SM64_MODERN_M18_SWIFT_TICKS:-8}"
    M18_TOTAL_TICKS=$((M18_TICKS + M18_SWIFT_TICKS))
    mkdir -p "$M18_RECORD_SAVE" "$M18_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M18_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M18_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M18_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_GROUND_STEP=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m18_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m18_record_pid"
    test -s "$M18_TRACE"
    m18_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m18_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m18_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M18_TICKS" <<< "$m18_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m18_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m18_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0' <<< "$m18_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m18_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M18_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M18_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M18_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-ground-step,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M18_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_GROUND_STEP=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m18_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m18_shadow_pid"
    m18_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m18_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m18_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m18_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m18_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m18_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m18_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_ground_step=[1-9][0-9]*' <<< "$m18_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m18_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M18_TOTAL_TICKS authority_steps=$M18_SWIFT_TICKS" <<< "$m18_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m18_shadow_log"
    printf '%s\n' "$m18_record_log" "$m18_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m19-native-verify|m19-native-verify)
    M19_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m19-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M19_TEMP"' EXIT
    M19_TRACE="$M19_TEMP/mario-air-step-native-v1.trace"
    M19_RECORD_SAVE="$M19_TEMP/record-save"
    M19_SHADOW_SAVE="$M19_TEMP/shadow-save"
    M19_TICKS="${SM64_MODERN_M19_TICKS:-8}"
    M19_SWIFT_TICKS="${SM64_MODERN_M19_SWIFT_TICKS:-8}"
    M19_TOTAL_TICKS=$((M19_TICKS + M19_SWIFT_TICKS))
    mkdir -p "$M19_RECORD_SAVE" "$M19_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M19_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M19_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M19_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_AIR_STEP=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m19_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m19_record_pid"
    test -s "$M19_TRACE"
    m19_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m19_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m19_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M19_TICKS" <<< "$m19_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m19_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m19_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0' <<< "$m19_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m19_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M19_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M19_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M19_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-air-step,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M19_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_AIR_STEP=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m19_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m19_shadow_pid"
    m19_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m19_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m19_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m19_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m19_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m19_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m19_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_air_step=[1-9][0-9]*' <<< "$m19_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m19_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M19_TOTAL_TICKS authority_steps=$M19_SWIFT_TICKS" <<< "$m19_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m19_shadow_log"
    printf '%s\n' "$m19_record_log" "$m19_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m20-native-verify|m20-native-verify)
    M20_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m20-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M20_TEMP"' EXIT
    M20_TRACE="$M20_TEMP/mario-water-step-native-v1.trace"
    M20_RECORD_SAVE="$M20_TEMP/record-save"
    M20_SHADOW_SAVE="$M20_TEMP/shadow-save"
    M20_TICKS="${SM64_MODERN_M20_TICKS:-8}"
    M20_SWIFT_TICKS="${SM64_MODERN_M20_SWIFT_TICKS:-8}"
    M20_TOTAL_TICKS=$((M20_TICKS + M20_SWIFT_TICKS))
    mkdir -p "$M20_RECORD_SAVE" "$M20_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M20_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M20_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M20_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_WATER_STEP=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m20_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m20_record_pid"
    test -s "$M20_TRACE"
    m20_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m20_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m20_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M20_TICKS" <<< "$m20_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m20_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m20_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0' <<< "$m20_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m20_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M20_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M20_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M20_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-water-step,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M20_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_WATER_STEP=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m20_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m20_shadow_pid"
    m20_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m20_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m20_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m20_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m20_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m20_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m20_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_water_step=[1-9][0-9]*' <<< "$m20_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m20_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M20_TOTAL_TICKS authority_steps=$M20_SWIFT_TICKS" <<< "$m20_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m20_shadow_log"
    printf '%s\n' "$m20_record_log" "$m20_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m21-native-verify|m21-native-verify)
    M21_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m21-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M21_TEMP"' EXIT
    M21_TRACE="$M21_TEMP/mario-bonk-native-v1.trace"
    M21_RECORD_SAVE="$M21_TEMP/record-save"
    M21_SHADOW_SAVE="$M21_TEMP/shadow-save"
    M21_TICKS="${SM64_MODERN_M21_TICKS:-8}"
    M21_SWIFT_TICKS="${SM64_MODERN_M21_SWIFT_TICKS:-8}"
    M21_TOTAL_TICKS=$((M21_TICKS + M21_SWIFT_TICKS))
    mkdir -p "$M21_RECORD_SAVE" "$M21_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M21_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M21_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M21_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_BONK=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m21_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m21_record_pid"
    test -s "$M21_TRACE"
    m21_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m21_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m21_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M21_TICKS" <<< "$m21_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m21_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m21_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0' <<< "$m21_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m21_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M21_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M21_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M21_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-bonk,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M21_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_BONK=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m21_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m21_shadow_pid"
    m21_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m21_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m21_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m21_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m21_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m21_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m21_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_bonk=[1-9][0-9]*' <<< "$m21_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m21_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M21_TOTAL_TICKS authority_steps=$M21_SWIFT_TICKS" <<< "$m21_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m21_shadow_log"
    printf '%s\n' "$m21_record_log" "$m21_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m22-native-verify|m22-native-verify)
    M22_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m22-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M22_TEMP"' EXIT
    M22_TRACE="$M22_TEMP/mario-terrain-native-v1.trace"
    M22_RECORD_SAVE="$M22_TEMP/record-save"
    M22_SHADOW_SAVE="$M22_TEMP/shadow-save"
    M22_TICKS="${SM64_MODERN_M22_TICKS:-8}"
    M22_SWIFT_TICKS="${SM64_MODERN_M22_SWIFT_TICKS:-8}"
    M22_TOTAL_TICKS=$((M22_TICKS + M22_SWIFT_TICKS))
    mkdir -p "$M22_RECORD_SAVE" "$M22_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M22_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M22_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M22_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_TERRAIN=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m22_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m22_record_pid"
    test -s "$M22_TRACE"
    m22_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m22_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m22_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M22_TICKS" <<< "$m22_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m22_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m22_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0' <<< "$m22_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m22_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M22_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M22_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M22_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-terrain-impulse,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M22_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_TERRAIN=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m22_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m22_shadow_pid"
    m22_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m22_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m22_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m22_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m22_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m22_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m22_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_terrain_impulse=[1-9][0-9]*' <<< "$m22_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m22_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M22_TOTAL_TICKS authority_steps=$M22_SWIFT_TICKS" <<< "$m22_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m22_shadow_log"
    printf '%s\n' "$m22_record_log" "$m22_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m23-native-verify|m23-native-verify)
    M23_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m23-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M23_TEMP"' EXIT
    M23_TRACE="$M23_TEMP/mario-quicksand-native-v1.trace"
    M23_RECORD_SAVE="$M23_TEMP/record-save"
    M23_SHADOW_SAVE="$M23_TEMP/shadow-save"
    M23_TICKS="${SM64_MODERN_M23_TICKS:-8}"
    M23_SWIFT_TICKS="${SM64_MODERN_M23_SWIFT_TICKS:-8}"
    M23_TOTAL_TICKS=$((M23_TICKS + M23_SWIFT_TICKS))
    mkdir -p "$M23_RECORD_SAVE" "$M23_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M23_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M23_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M23_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_QUICKSAND=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m23_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m23_record_pid"
    test -s "$M23_TRACE"
    m23_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m23_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m23_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M23_TICKS" <<< "$m23_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m23_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m23_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0' <<< "$m23_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m23_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M23_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M23_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M23_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-quicksand,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M23_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_QUICKSAND=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m23_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m23_shadow_pid"
    m23_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m23_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m23_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m23_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m23_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m23_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m23_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_quicksand=[1-9][0-9]*' <<< "$m23_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m23_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M23_TOTAL_TICKS authority_steps=$M23_SWIFT_TICKS" <<< "$m23_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m23_shadow_log"
    printf '%s\n' "$m23_record_log" "$m23_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m24-native-verify|m24-native-verify)
    M24_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m24-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M24_TEMP"' EXIT
    M24_TRACE="$M24_TEMP/mario-steep-push-native-v1.trace"
    M24_RECORD_SAVE="$M24_TEMP/record-save"
    M24_SHADOW_SAVE="$M24_TEMP/shadow-save"
    M24_TICKS="${SM64_MODERN_M24_TICKS:-8}"
    M24_SWIFT_TICKS="${SM64_MODERN_M24_SWIFT_TICKS:-8}"
    M24_TOTAL_TICKS=$((M24_TICKS + M24_SWIFT_TICKS))
    mkdir -p "$M24_RECORD_SAVE" "$M24_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M24_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M24_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M24_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_STEEP_PUSH=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m24_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m24_record_pid"
    test -s "$M24_TRACE"
    m24_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m24_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m24_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M24_TICKS" <<< "$m24_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m24_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m24_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0' <<< "$m24_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m24_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M24_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M24_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M24_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-steep-push,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M24_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_STEEP_PUSH=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m24_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m24_shadow_pid"
    m24_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m24_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m24_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m24_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m24_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m24_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m24_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_steep_push=[1-9][0-9]*' <<< "$m24_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m24_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M24_TOTAL_TICKS authority_steps=$M24_SWIFT_TICKS" <<< "$m24_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m24_shadow_log"
    printf '%s\n' "$m24_record_log" "$m24_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m25-native-verify|m25-native-verify)
    M25_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m25-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M25_TEMP"' EXIT
    M25_TRACE="$M25_TEMP/mario-terrain-sound-native-v1.trace"
    M25_RECORD_SAVE="$M25_TEMP/record-save"
    M25_SHADOW_SAVE="$M25_TEMP/shadow-save"
    M25_TICKS="${SM64_MODERN_M25_TICKS:-8}"
    M25_SWIFT_TICKS="${SM64_MODERN_M25_SWIFT_TICKS:-8}"
    M25_TOTAL_TICKS=$((M25_TICKS + M25_SWIFT_TICKS))
    mkdir -p "$M25_RECORD_SAVE" "$M25_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M25_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M25_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M25_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_TERRAIN_SOUND=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m25_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m25_record_pid"
    test -s "$M25_TRACE"
    m25_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m25_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m25_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M25_TICKS" <<< "$m25_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m25_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m25_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0' <<< "$m25_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m25_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M25_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M25_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M25_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-terrain-sound,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M25_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_TERRAIN_SOUND=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m25_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m25_shadow_pid"
    m25_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m25_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m25_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m25_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m25_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m25_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m25_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_terrain_sound=[1-9][0-9]*' <<< "$m25_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m25_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M25_TOTAL_TICKS authority_steps=$M25_SWIFT_TICKS" <<< "$m25_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m25_shadow_log"
    printf '%s\n' "$m25_record_log" "$m25_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m26-native-verify|m26-native-verify)
    M26_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m26-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M26_TEMP"' EXIT
    M26_TRACE="$M26_TEMP/mario-floor-predicates-native-v1.trace"
    M26_RECORD_SAVE="$M26_TEMP/record-save"
    M26_SHADOW_SAVE="$M26_TEMP/shadow-save"
    M26_TICKS="${SM64_MODERN_M26_TICKS:-8}"
    M26_SWIFT_TICKS="${SM64_MODERN_M26_SWIFT_TICKS:-8}"
    M26_TOTAL_TICKS=$((M26_TICKS + M26_SWIFT_TICKS))
    mkdir -p "$M26_RECORD_SAVE" "$M26_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M26_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M26_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M26_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_FLOOR_PREDICATES=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m26_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m26_record_pid"
    test -s "$M26_TRACE"
    m26_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m26_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m26_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M26_TICKS" <<< "$m26_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m26_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m26_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0' <<< "$m26_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m26_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M26_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M26_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M26_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-floor-predicates,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M26_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_FLOOR_PREDICATES=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m26_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m26_shadow_pid"
    m26_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m26_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m26_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m26_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m26_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m26_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m26_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_floor_predicates=[1-9][0-9]*' <<< "$m26_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m26_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M26_TOTAL_TICKS authority_steps=$M26_SWIFT_TICKS" <<< "$m26_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m26_shadow_log"
    printf '%s\n' "$m26_record_log" "$m26_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m27-native-verify|m27-native-verify)
    M27_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m27-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M27_TEMP"' EXIT
    M27_TRACE="$M27_TEMP/mario-facing-downhill-native-v1.trace"
    M27_RECORD_SAVE="$M27_TEMP/record-save"
    M27_SHADOW_SAVE="$M27_TEMP/shadow-save"
    M27_TICKS="${SM64_MODERN_M27_TICKS:-8}"
    M27_SWIFT_TICKS="${SM64_MODERN_M27_SWIFT_TICKS:-8}"
    M27_TOTAL_TICKS=$((M27_TICKS + M27_SWIFT_TICKS))
    mkdir -p "$M27_RECORD_SAVE" "$M27_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M27_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M27_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M27_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_FLOOR_PREDICATES=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m27_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m27_record_pid"
    test -s "$M27_TRACE"
    m27_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m27_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m27_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M27_TICKS" <<< "$m27_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m27_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m27_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0' <<< "$m27_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m27_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M27_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M27_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M27_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-floor-predicates,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M27_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_FLOOR_PREDICATES=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m27_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m27_shadow_pid"
    m27_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m27_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m27_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m27_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m27_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m27_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m27_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_floor_predicates=[1-9][0-9]*' <<< "$m27_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m27_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M27_TOTAL_TICKS authority_steps=$M27_SWIFT_TICKS" <<< "$m27_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m27_shadow_log"
    printf '%s\n' "$m27_record_log" "$m27_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m28-native-verify|m28-native-verify)
    M28_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m28-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M28_TEMP"' EXIT
    M28_TRACE="$M28_TEMP/mario-forward-velocity-native-v1.trace"
    M28_RECORD_SAVE="$M28_TEMP/record-save"
    M28_SHADOW_SAVE="$M28_TEMP/shadow-save"
    M28_TICKS="${SM64_MODERN_M28_TICKS:-8}"
    M28_SWIFT_TICKS="${SM64_MODERN_M28_SWIFT_TICKS:-8}"
    M28_TOTAL_TICKS=$((M28_TICKS + M28_SWIFT_TICKS))
    mkdir -p "$M28_RECORD_SAVE" "$M28_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M28_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M28_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M28_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_FORWARD_VELOCITY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m28_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m28_record_pid"
    test -s "$M28_TRACE"
    m28_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m28_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m28_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M28_TICKS" <<< "$m28_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m28_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m28_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0' <<< "$m28_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m28_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M28_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M28_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M28_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-forward-velocity,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M28_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_FORWARD_VELOCITY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m28_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m28_shadow_pid"
    m28_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m28_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m28_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m28_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m28_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m28_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m28_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_forward_velocity=[1-9][0-9]*' <<< "$m28_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m28_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M28_TOTAL_TICKS authority_steps=$M28_SWIFT_TICKS" <<< "$m28_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m28_shadow_log"
    printf '%s\n' "$m28_record_log" "$m28_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m29-native-verify|m29-native-verify)
    M29_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m29-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M29_TEMP"' EXIT
    M29_TRACE="$M29_TEMP/mario-velocity-derivation-native-v1.trace"
    M29_RECORD_SAVE="$M29_TEMP/record-save"
    M29_SHADOW_SAVE="$M29_TEMP/shadow-save"
    M29_TICKS="${SM64_MODERN_M29_TICKS:-8}"
    M29_SWIFT_TICKS="${SM64_MODERN_M29_SWIFT_TICKS:-8}"
    M29_TOTAL_TICKS=$((M29_TICKS + M29_SWIFT_TICKS))
    mkdir -p "$M29_RECORD_SAVE" "$M29_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M29_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M29_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M29_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_VELOCITY_DERIVATION=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m29_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m29_record_pid"
    test -s "$M29_TRACE"
    m29_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m29_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m29_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M29_TICKS" <<< "$m29_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m29_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m29_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0' <<< "$m29_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m29_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M29_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M29_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M29_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-velocity-derivation,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M29_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_VELOCITY_DERIVATION=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m29_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m29_shadow_pid"
    m29_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m29_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m29_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m29_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m29_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m29_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m29_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_velocity_derivation=[1-9][0-9]*' <<< "$m29_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m29_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M29_TOTAL_TICKS authority_steps=$M29_SWIFT_TICKS" <<< "$m29_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m29_shadow_log"
    printf '%s\n' "$m29_record_log" "$m29_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m30-native-verify|m30-native-verify)
    M30_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m30-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M30_TEMP"' EXIT
    M30_TRACE="$M30_TEMP/mario-punch-native-v1.trace"
    M30_RECORD_SAVE="$M30_TEMP/record-save"
    M30_SHADOW_SAVE="$M30_TEMP/shadow-save"
    M30_TICKS="${SM64_MODERN_M30_TICKS:-8}"
    M30_SWIFT_TICKS="${SM64_MODERN_M30_SWIFT_TICKS:-8}"
    M30_TOTAL_TICKS=$((M30_TICKS + M30_SWIFT_TICKS))
    mkdir -p "$M30_RECORD_SAVE" "$M30_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M30_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M30_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M30_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_PUNCH=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m30_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m30_record_pid"
    test -s "$M30_TRACE"
    m30_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m30_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m30_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M30_TICKS" <<< "$m30_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m30_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m30_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0 mario_punch=0' <<< "$m30_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m30_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M30_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M30_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M30_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-punch,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M30_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_PUNCH=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m30_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m30_shadow_pid"
    m30_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m30_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m30_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m30_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m30_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m30_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m30_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_punch=[1-9][0-9]*' <<< "$m30_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m30_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M30_TOTAL_TICKS authority_steps=$M30_SWIFT_TICKS" <<< "$m30_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m30_shadow_log"
    printf '%s\n' "$m30_record_log" "$m30_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m31-native-verify|m31-native-verify)
    M31_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m31-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M31_TEMP"' EXIT
    M31_TRACE="$M31_TEMP/mario-wall-response-native-v1.trace"
    M31_RECORD_SAVE="$M31_TEMP/record-save"
    M31_SHADOW_SAVE="$M31_TEMP/shadow-save"
    M31_TICKS="${SM64_MODERN_M31_TICKS:-8}"
    M31_SWIFT_TICKS="${SM64_MODERN_M31_SWIFT_TICKS:-8}"
    M31_TOTAL_TICKS=$((M31_TICKS + M31_SWIFT_TICKS))
    mkdir -p "$M31_RECORD_SAVE" "$M31_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M31_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M31_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M31_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_WALL_RESPONSE=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m31_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m31_record_pid"
    test -s "$M31_TRACE"
    m31_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m31_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m31_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M31_TICKS" <<< "$m31_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m31_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m31_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0 mario_punch=0 mario_wall_response=0' <<< "$m31_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m31_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M31_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M31_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M31_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-wall-response,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M31_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_WALL_RESPONSE=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m31_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m31_shadow_pid"
    m31_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m31_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m31_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m31_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m31_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m31_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m31_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_wall_response=[1-9][0-9]*' <<< "$m31_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m31_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M31_TOTAL_TICKS authority_steps=$M31_SWIFT_TICKS" <<< "$m31_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m31_shadow_log"
    printf '%s\n' "$m31_record_log" "$m31_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m32-native-verify|m32-native-verify)
    M32_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m32-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M32_TEMP"' EXIT
    M32_TRACE="$M32_TEMP/mario-walk-animation-native-v1.trace"
    M32_RECORD_SAVE="$M32_TEMP/record-save"
    M32_SHADOW_SAVE="$M32_TEMP/shadow-save"
    M32_TICKS="${SM64_MODERN_M32_TICKS:-8}"
    M32_SWIFT_TICKS="${SM64_MODERN_M32_SWIFT_TICKS:-8}"
    M32_TOTAL_TICKS=$((M32_TICKS + M32_SWIFT_TICKS))
    mkdir -p "$M32_RECORD_SAVE" "$M32_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M32_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M32_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M32_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_WALK_ANIMATION=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m32_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m32_record_pid"
    test -s "$M32_TRACE"
    m32_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m32_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m32_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M32_TICKS" <<< "$m32_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m32_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m32_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0 mario_punch=0 mario_wall_response=0 mario_walk_animation=0' <<< "$m32_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m32_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M32_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M32_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M32_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-walk-animation,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M32_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_WALK_ANIMATION=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m32_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m32_shadow_pid"
    m32_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m32_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m32_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m32_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m32_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m32_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m32_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_walk_animation=[1-9][0-9]*' <<< "$m32_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m32_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M32_TOTAL_TICKS authority_steps=$M32_SWIFT_TICKS" <<< "$m32_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m32_shadow_log"
    printf '%s\n' "$m32_record_log" "$m32_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33-native-verify|m33-native-verify)
    M33_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33_TEMP"' EXIT
    M33_TRACE="$M33_TEMP/mario-held-walk-animation-native-v1.trace"
    M33_RECORD_SAVE="$M33_TEMP/record-save"
    M33_SHADOW_SAVE="$M33_TEMP/shadow-save"
    M33_TICKS="${SM64_MODERN_M33_TICKS:-8}"
    M33_SWIFT_TICKS="${SM64_MODERN_M33_SWIFT_TICKS:-8}"
    M33_TOTAL_TICKS=$((M33_TICKS + M33_SWIFT_TICKS))
    mkdir -p "$M33_RECORD_SAVE" "$M33_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_HELD_WALK_ANIMATION=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33_record_pid"
    test -s "$M33_TRACE"
    m33_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33_TICKS" <<< "$m33_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0 mario_punch=0 mario_wall_response=0 mario_walk_animation=0 mario_held_walk_animation=0' <<< "$m33_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-held-walk-animation,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_HELD_WALK_ANIMATION=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33_shadow_pid"
    m33_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_held_walk_animation=[1-9][0-9]*' <<< "$m33_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33_TOTAL_TICKS authority_steps=$M33_SWIFT_TICKS" <<< "$m33_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33_shadow_log"
    printf '%s\n' "$m33_record_log" "$m33_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33aa-native-verify|m33aa-native-verify)
    M33AA_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33aa-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AA_TEMP"' EXIT
    M33AA_TRACE="$M33AA_TEMP/mario-slope-acceleration-native-v1.trace"
    M33AA_RECORD_SAVE="$M33AA_TEMP/record-save"
    M33AA_SHADOW_SAVE="$M33AA_TEMP/shadow-save"
    M33AA_TICKS="${SM64_MODERN_M33AA_TICKS:-8}"
    M33AA_SWIFT_TICKS="${SM64_MODERN_M33AA_SWIFT_TICKS:-8}"
    M33AA_TOTAL_TICKS=$((M33AA_TICKS + M33AA_SWIFT_TICKS))
    mkdir -p "$M33AA_RECORD_SAVE" "$M33AA_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33AA_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AA_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AA_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_SLOPE_ACCEL=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33aa_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33aa_record_pid"
    test -s "$M33AA_TRACE"
    m33aa_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33aa_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33aa_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33AA_TICKS" <<< "$m33aa_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33aa_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33aa_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0 mario_punch=0 mario_wall_response=0 mario_walk_animation=0 mario_held_walk_animation=0 mario_slope_acceleration=0' <<< "$m33aa_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33aa_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33AA_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AA_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AA_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-slope-acceleration,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AA_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_SLOPE_ACCEL=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33aa_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33aa_shadow_pid"
    m33aa_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33aa_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33aa_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33aa_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33aa_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33aa_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33aa_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_slope_acceleration=[1-9][0-9]*' <<< "$m33aa_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33aa_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AA_TOTAL_TICKS authority_steps=$M33AA_SWIFT_TICKS" <<< "$m33aa_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33aa_shadow_log"
    printf '%s\n' "$m33aa_record_log" "$m33aa_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33ab-native-verify|m33ab-native-verify)
    M33AB_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33ab-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AB_TEMP"' EXIT
    M33AB_TRACE="$M33AB_TEMP/mario-slope-deceleration-native-v1.trace"
    M33AB_RECORD_SAVE="$M33AB_TEMP/record-save"
    M33AB_SHADOW_SAVE="$M33AB_TEMP/shadow-save"
    M33AB_TICKS="${SM64_MODERN_M33AB_TICKS:-8}"
    M33AB_SWIFT_TICKS="${SM64_MODERN_M33AB_SWIFT_TICKS:-8}"
    M33AB_TOTAL_TICKS=$((M33AB_TICKS + M33AB_SWIFT_TICKS))
    mkdir -p "$M33AB_RECORD_SAVE" "$M33AB_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33AB_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AB_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AB_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_SLOPE_DECEL=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ab_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ab_record_pid"
    test -s "$M33AB_TRACE"
    m33ab_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ab_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33ab_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33AB_TICKS" <<< "$m33ab_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ab_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ab_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0 mario_punch=0 mario_wall_response=0 mario_walk_animation=0 mario_held_walk_animation=0 mario_slope_acceleration=0 mario_slope_deceleration=0' <<< "$m33ab_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33ab_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33AB_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AB_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AB_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-slope-deceleration,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AB_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_SLOPE_DECEL=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ab_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ab_shadow_pid"
    m33ab_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ab_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33ab_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33ab_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33ab_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ab_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ab_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_slope_deceleration=[1-9][0-9]*' <<< "$m33ab_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33ab_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AB_TOTAL_TICKS authority_steps=$M33AB_SWIFT_TICKS" <<< "$m33ab_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33ab_shadow_log"
    printf '%s\n' "$m33ab_record_log" "$m33ab_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33ac-native-verify|m33ac-native-verify)
    M33AC_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33ac-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AC_TEMP"' EXIT
    M33AC_TRACE="$M33AC_TEMP/mario-decelerating-speed-native-v1.trace"
    M33AC_RECORD_SAVE="$M33AC_TEMP/record-save"
    M33AC_SHADOW_SAVE="$M33AC_TEMP/shadow-save"
    M33AC_TICKS="${SM64_MODERN_M33AC_TICKS:-8}"
    M33AC_SWIFT_TICKS="${SM64_MODERN_M33AC_SWIFT_TICKS:-8}"
    M33AC_TOTAL_TICKS=$((M33AC_TICKS + M33AC_SWIFT_TICKS))
    mkdir -p "$M33AC_RECORD_SAVE" "$M33AC_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33AC_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AC_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AC_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_DECELERATING_SPEED=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ac_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ac_record_pid"
    test -s "$M33AC_TRACE"
    m33ac_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ac_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33ac_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33AC_TICKS" <<< "$m33ac_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ac_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ac_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0 mario_punch=0 mario_wall_response=0 mario_walk_animation=0 mario_held_walk_animation=0 mario_slope_acceleration=0 mario_slope_deceleration=0 mario_decelerating_speed=0' <<< "$m33ac_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33ac_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33AC_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AC_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AC_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-decelerating-speed,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AC_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_DECELERATING_SPEED=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ac_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ac_shadow_pid"
    m33ac_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ac_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33ac_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33ac_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33ac_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ac_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ac_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_decelerating_speed=[1-9][0-9]*' <<< "$m33ac_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33ac_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AC_TOTAL_TICKS authority_steps=$M33AC_SWIFT_TICKS" <<< "$m33ac_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33ac_shadow_log"
    printf '%s\n' "$m33ac_record_log" "$m33ac_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33ad-native-verify|m33ad-native-verify)
    M33AD_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33ad-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AD_TEMP"' EXIT
    M33AD_TRACE="$M33AD_TEMP/mario-shell-speed-native-v1.trace"
    M33AD_RECORD_SAVE="$M33AD_TEMP/record-save"
    M33AD_SHADOW_SAVE="$M33AD_TEMP/shadow-save"
    M33AD_TICKS="${SM64_MODERN_M33AD_TICKS:-8}"
    M33AD_SWIFT_TICKS="${SM64_MODERN_M33AD_SWIFT_TICKS:-8}"
    M33AD_TOTAL_TICKS=$((M33AD_TICKS + M33AD_SWIFT_TICKS))
    mkdir -p "$M33AD_RECORD_SAVE" "$M33AD_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33AD_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AD_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AD_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_SHELL_SPEED=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ad_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ad_record_pid"
    test -s "$M33AD_TRACE"
    m33ad_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ad_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33ad_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33AD_TICKS" <<< "$m33ad_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ad_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ad_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0 mario_punch=0 mario_wall_response=0 mario_walk_animation=0 mario_held_walk_animation=0 mario_slope_acceleration=0 mario_slope_deceleration=0 mario_decelerating_speed=0 mario_shell_speed=0' <<< "$m33ad_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33ad_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33AD_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AD_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AD_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-shell-speed,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AD_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_SHELL_SPEED=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ad_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ad_shadow_pid"
    m33ad_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ad_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33ad_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33ad_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33ad_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ad_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ad_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_shell_speed=[1-9][0-9]*' <<< "$m33ad_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33ad_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AD_TOTAL_TICKS authority_steps=$M33AD_SWIFT_TICKS" <<< "$m33ad_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33ad_shadow_log"
    printf '%s\n' "$m33ad_record_log" "$m33ad_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33ae-native-verify|m33ae-native-verify)
    M33AE_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33ae-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AE_TEMP"' EXIT
    M33AE_TRACE="$M33AE_TEMP/mario-landing-acceleration-native-v1.trace"
    M33AE_RECORD_SAVE="$M33AE_TEMP/record-save"
    M33AE_SHADOW_SAVE="$M33AE_TEMP/shadow-save"
    M33AE_TICKS="${SM64_MODERN_M33AE_TICKS:-8}"
    M33AE_SWIFT_TICKS="${SM64_MODERN_M33AE_SWIFT_TICKS:-8}"
    M33AE_TOTAL_TICKS=$((M33AE_TICKS + M33AE_SWIFT_TICKS))
    mkdir -p "$M33AE_RECORD_SAVE" "$M33AE_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33AE_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AE_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AE_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_LANDING_ACCEL=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ae_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ae_record_pid"
    test -s "$M33AE_TRACE"
    m33ae_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ae_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33ae_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33AE_TICKS" <<< "$m33ae_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ae_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ae_record_log"
    grep -Eq 'swift_gameplay_evidence mario_buttons=0 mario_ground_speed=0 bobomb_release=0 cheat_policy=0 mario_action=0 mario_action_cancel=0 mario_ground_step=0 mario_air_step=0 mario_water_step=0 mario_bonk=0 mario_terrain_impulse=0 mario_quicksand=0 mario_steep_push=0 mario_terrain_sound=0 mario_floor_predicates=0 mario_forward_velocity=0 mario_velocity_derivation=0 mario_punch=0 mario_wall_response=0 mario_walk_animation=0 mario_held_walk_animation=0 mario_slope_acceleration=0 mario_slope_deceleration=0 mario_decelerating_speed=0 mario_shell_speed=0 mario_landing_acceleration=0 mario_gravity=0' <<< "$m33ae_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33ae_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33AE_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AE_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AE_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-landing-acceleration,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AE_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_LANDING_ACCEL=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ae_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ae_shadow_pid"
    m33ae_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ae_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33ae_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33ae_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33ae_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ae_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ae_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_landing_acceleration=[1-9][0-9]*' <<< "$m33ae_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33ae_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AE_TOTAL_TICKS authority_steps=$M33AE_SWIFT_TICKS" <<< "$m33ae_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33ae_shadow_log"
    printf '%s\n' "$m33ae_record_log" "$m33ae_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33af-native-verify|m33af-native-verify)
    M33AF_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33af-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AF_TEMP"' EXIT
    M33AF_TRACE="$M33AF_TEMP/mario-gravity-native-v1.trace"
    M33AF_RECORD_SAVE="$M33AF_TEMP/record-save"
    M33AF_SHADOW_SAVE="$M33AF_TEMP/shadow-save"
    M33AF_TICKS="${SM64_MODERN_M33AF_TICKS:-8}"
    M33AF_SWIFT_TICKS="${SM64_MODERN_M33AF_SWIFT_TICKS:-8}"
    M33AF_TOTAL_TICKS=$((M33AF_TICKS + M33AF_SWIFT_TICKS))
    mkdir -p "$M33AF_RECORD_SAVE" "$M33AF_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33AF_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AF_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AF_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_GRAVITY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33af_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33af_record_pid"
    test -s "$M33AF_TRACE"
    m33af_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33af_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33af_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33AF_TICKS" <<< "$m33af_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33af_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33af_record_log"
    grep -Eq 'swift_gameplay_evidence .*mario_gravity=0' <<< "$m33af_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33af_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33AF_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AF_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AF_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-gravity,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AF_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_GRAVITY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33af_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33af_shadow_pid"
    m33af_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33af_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33af_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33af_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33af_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33af_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33af_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_gravity=[1-9][0-9]*' <<< "$m33af_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33af_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AF_TOTAL_TICKS authority_steps=$M33AF_SWIFT_TICKS" <<< "$m33af_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33af_shadow_log"
    printf '%s\n' "$m33af_record_log" "$m33af_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33ag-native-verify|m33ag-native-verify)
    M33AG_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33ag-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AG_TEMP"' EXIT
    M33AG_TRACE="$M33AG_TEMP/mario-vertical-wind-native-v1.trace"
    M33AG_RECORD_SAVE="$M33AG_TEMP/record-save"
    M33AG_SHADOW_SAVE="$M33AG_TEMP/shadow-save"
    M33AG_TICKS="${SM64_MODERN_M33AG_TICKS:-8}"
    M33AG_SWIFT_TICKS="${SM64_MODERN_M33AG_SWIFT_TICKS:-8}"
    M33AG_TOTAL_TICKS=$((M33AG_TICKS + M33AG_SWIFT_TICKS))
    mkdir -p "$M33AG_RECORD_SAVE" "$M33AG_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33AG_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AG_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AG_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_VERTICAL_WIND=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ag_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ag_record_pid"
    test -s "$M33AG_TRACE"
    m33ag_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ag_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33ag_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33AG_TICKS" <<< "$m33ag_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ag_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ag_record_log"
    grep -Eq 'swift_gameplay_evidence .*mario_vertical_wind=0' <<< "$m33ag_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33ag_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33AG_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AG_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AG_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-vertical-wind,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AG_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_VERTICAL_WIND=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ag_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ag_shadow_pid"
    m33ag_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ag_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33ag_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33ag_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33ag_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ag_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ag_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_vertical_wind=[1-9][0-9]*' <<< "$m33ag_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33ag_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AG_TOTAL_TICKS authority_steps=$M33AG_SWIFT_TICKS" <<< "$m33ag_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33ag_shadow_log"
    printf '%s\n' "$m33ag_record_log" "$m33ag_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33ah-native-verify|m33ah-native-verify)
    M33AH_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33ah-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AH_TEMP"' EXIT
    M33AH_TRACE="$M33AH_TEMP/mario-sliding-native-v1.trace"
    M33AH_RECORD_SAVE="$M33AH_TEMP/record-save"
    M33AH_SHADOW_SAVE="$M33AH_TEMP/shadow-save"
    M33AH_TICKS="${SM64_MODERN_M33AH_TICKS:-8}"
    M33AH_SWIFT_TICKS="${SM64_MODERN_M33AH_SWIFT_TICKS:-8}"
    M33AH_TOTAL_TICKS=$((M33AH_TICKS + M33AH_SWIFT_TICKS))
    mkdir -p "$M33AH_RECORD_SAVE" "$M33AH_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33AH_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AH_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AH_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_SLIDING=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ah_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ah_record_pid"
    test -s "$M33AH_TRACE"
    m33ah_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ah_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33ah_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33AH_TICKS" <<< "$m33ah_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ah_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ah_record_log"
    grep -Eq 'swift_gameplay_evidence .*mario_sliding=0' <<< "$m33ah_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33ah_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33AH_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AH_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AH_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-sliding,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AH_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_SLIDING=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ah_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ah_shadow_pid"
    m33ah_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ah_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33ah_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33ah_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33ah_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ah_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ah_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_sliding=[1-9][0-9]*' <<< "$m33ah_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33ah_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AH_TOTAL_TICKS authority_steps=$M33AH_SWIFT_TICKS" <<< "$m33ah_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33ah_shadow_log"
    printf '%s\n' "$m33ah_record_log" "$m33ah_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33ai-native-verify|m33ai-native-verify)
    M33AI_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33ai-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AI_TEMP"' EXIT
    M33AI_TRACE="$M33AI_TEMP/mario-ground-dive-punch-native-v1.trace"
    M33AI_RECORD_SAVE="$M33AI_TEMP/record-save"
    M33AI_SHADOW_SAVE="$M33AI_TEMP/shadow-save"
    M33AI_TICKS="${SM64_MODERN_M33AI_TICKS:-8}"
    M33AI_SWIFT_TICKS="${SM64_MODERN_M33AI_SWIFT_TICKS:-8}"
    M33AI_TOTAL_TICKS=$((M33AI_TICKS + M33AI_SWIFT_TICKS))
    mkdir -p "$M33AI_RECORD_SAVE" "$M33AI_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M33AI_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AI_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AI_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_GROUND_DIVE_PUNCH=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ai_record_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ai_record_pid"
    test -s "$M33AI_TRACE"
    m33ai_record_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ai_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$m33ai_record_log"
    grep -Fq "bounded_parity_run_complete steps=$M33AI_TICKS" <<< "$m33ai_record_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ai_record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ai_record_log"
    grep -Eq 'swift_gameplay_evidence .*mario_ground_dive_punch=0' <<< "$m33ai_record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$m33ai_record_log"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M33AI_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AI_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M33AI_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift \
      --env SM64_MODERN_SWIFT_SLICES=mario-ground-dive-punch,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AI_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_GROUND_DIVE_PUNCH=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ai_shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit "$m33ai_shadow_pid"
    m33ai_shadow_log="$(/usr/bin/log show --last 5m --style compact \
      --predicate "processIdentifier == $m33ai_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$m33ai_shadow_log"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33ai_shadow_log"
    grep -Fq 'swift_shadow_started subsystems=1,4 promote=true' <<< "$m33ai_shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$m33ai_shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$m33ai_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_ground_dive_punch=[1-9][0-9]*' <<< "$m33ai_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33ai_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AI_TOTAL_TICKS authority_steps=$M33AI_SWIFT_TICKS" <<< "$m33ai_shadow_log"
    grep -Fq 'engine_thread_finished status=0' <<< "$m33ai_shadow_log"
    printf '%s\n' "$m33ai_record_log" "$m33ai_shadow_log" \
      | grep -E 'swift_authority_(fallback=c|requested mode=native|promoted)|swift_shadow_started|swift_gameplay_evidence|bounded_(parity_run_complete|swift_authority_run_complete)|parity_result subsystem=(1|4)|engine_thread_finished status=0'
    ;;
  --m33aj-native-verify|m33aj-native-verify)
    M33AJ_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33aj-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AJ_TEMP"' EXIT
    M33AJ_TRACE="$M33AJ_TEMP/mario-slide-predicates-native-v1.trace"
    M33AJ_RECORD_SAVE="$M33AJ_TEMP/record-save"
    M33AJ_SHADOW_SAVE="$M33AJ_TEMP/shadow-save"
    M33AJ_TICKS="${SM64_MODERN_M33AJ_TICKS:-8}"
    M33AJ_SWIFT_TICKS="${SM64_MODERN_M33AJ_SWIFT_TICKS:-8}"
    M33AJ_TOTAL_TICKS=$((M33AJ_TICKS + M33AJ_SWIFT_TICKS))
    mkdir -p "$M33AJ_RECORD_SAVE" "$M33AJ_SHADOW_SAVE"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record --env SM64_MODERN_PARITY_TRACE="$M33AJ_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AJ_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AJ_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_SLIDE_PREDICATES=1 --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33aj_record_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33aj_record_pid"; test -s "$M33AJ_TRACE"
    m33aj_record_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33aj_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq "bounded_parity_run_complete steps=$M33AJ_TICKS" <<< "$m33aj_record_log"
    grep -Eq 'swift_gameplay_evidence .*mario_slide_predicates=0' <<< "$m33aj_record_log"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow --env SM64_MODERN_PARITY_TRACE="$M33AJ_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AJ_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AJ_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift --env SM64_MODERN_SWIFT_SLICES=mario-slide-predicates,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AJ_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 --env SM64_MODERN_AUTOMATED_MARIO_SLIDE_PREDICATES=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33aj_shadow_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33aj_shadow_pid"
    m33aj_shadow_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33aj_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33aj_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_slide_predicates=[1-9][0-9]*' <<< "$m33aj_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33aj_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AJ_TOTAL_TICKS authority_steps=$M33AJ_SWIFT_TICKS" <<< "$m33aj_shadow_log"
    ;;
  --m33ak-native-verify|m33ak-native-verify)
    M33AK_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33ak-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AK_TEMP"' EXIT
    M33AK_TRACE="$M33AK_TEMP/mario-begin-braking-native-v1.trace"
    M33AK_RECORD_SAVE="$M33AK_TEMP/record-save"
    M33AK_SHADOW_SAVE="$M33AK_TEMP/shadow-save"
    M33AK_TICKS="${SM64_MODERN_M33AK_TICKS:-8}"
    M33AK_SWIFT_TICKS="${SM64_MODERN_M33AK_SWIFT_TICKS:-8}"
    M33AK_TOTAL_TICKS=$((M33AK_TICKS + M33AK_SWIFT_TICKS))
    mkdir -p "$M33AK_RECORD_SAVE" "$M33AK_SHADOW_SAVE"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record --env SM64_MODERN_PARITY_TRACE="$M33AK_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AK_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AK_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_BEGIN_BRAKING=1 --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ak_record_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33ak_record_pid"; test -s "$M33AK_TRACE"
    m33ak_record_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33ak_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq "bounded_parity_run_complete steps=$M33AK_TICKS" <<< "$m33ak_record_log"
    grep -Eq 'swift_gameplay_evidence .*mario_begin_braking=0' <<< "$m33ak_record_log"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow --env SM64_MODERN_PARITY_TRACE="$M33AK_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AK_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AK_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift --env SM64_MODERN_SWIFT_SLICES=mario-begin-braking,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AK_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 --env SM64_MODERN_AUTOMATED_MARIO_BEGIN_BRAKING=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33ak_shadow_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33ak_shadow_pid"
    m33ak_shadow_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33ak_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33ak_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_begin_braking=[1-9][0-9]*' <<< "$m33ak_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33ak_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AK_TOTAL_TICKS authority_steps=$M33AK_SWIFT_TICKS" <<< "$m33ak_shadow_log"
    ;;
  --m33al-native-verify|m33al-native-verify)
    M33AL_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33al-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AL_TEMP"' EXIT
    M33AL_TRACE="$M33AL_TEMP/mario-triple-jump-native-v1.trace"
    M33AL_RECORD_SAVE="$M33AL_TEMP/record-save"
    M33AL_SHADOW_SAVE="$M33AL_TEMP/shadow-save"
    M33AL_TICKS="${SM64_MODERN_M33AL_TICKS:-8}"
    M33AL_SWIFT_TICKS="${SM64_MODERN_M33AL_SWIFT_TICKS:-8}"
    M33AL_TOTAL_TICKS=$((M33AL_TICKS + M33AL_SWIFT_TICKS))
    mkdir -p "$M33AL_RECORD_SAVE" "$M33AL_SHADOW_SAVE"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record --env SM64_MODERN_PARITY_TRACE="$M33AL_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AL_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AL_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_TRIPLE_JUMP=1 --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33al_record_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33al_record_pid"; test -s "$M33AL_TRACE"
    m33al_record_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33al_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq "bounded_parity_run_complete steps=$M33AL_TICKS" <<< "$m33al_record_log"
    grep -Eq 'swift_gameplay_evidence .*mario_triple_jump_selector=0' <<< "$m33al_record_log"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow --env SM64_MODERN_PARITY_TRACE="$M33AL_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AL_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AL_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift --env SM64_MODERN_SWIFT_SLICES=mario-triple-jump-selector,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AL_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 --env SM64_MODERN_AUTOMATED_MARIO_TRIPLE_JUMP=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33al_shadow_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33al_shadow_pid"
    m33al_shadow_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33al_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33al_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_triple_jump_selector=[1-9][0-9]*' <<< "$m33al_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33al_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AL_TOTAL_TICKS authority_steps=$M33AL_SWIFT_TICKS" <<< "$m33al_shadow_log"
    ;;
  --m33am-native-verify|m33am-native-verify)
    M33AM_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33am-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AM_TEMP"' EXIT
    M33AM_TRACE="$M33AM_TEMP/mario-y-velocity-native-v1.trace"
    M33AM_RECORD_SAVE="$M33AM_TEMP/record-save"
    M33AM_SHADOW_SAVE="$M33AM_TEMP/shadow-save"
    M33AM_TICKS="${SM64_MODERN_M33AM_TICKS:-8}"
    M33AM_SWIFT_TICKS="${SM64_MODERN_M33AM_SWIFT_TICKS:-8}"
    M33AM_TOTAL_TICKS=$((M33AM_TICKS + M33AM_SWIFT_TICKS))
    mkdir -p "$M33AM_RECORD_SAVE" "$M33AM_SHADOW_SAVE"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record --env SM64_MODERN_PARITY_TRACE="$M33AM_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AM_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AM_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_Y_VELOCITY=1 --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33am_record_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33am_record_pid"; test -s "$M33AM_TRACE"
    m33am_record_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33am_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq "bounded_parity_run_complete steps=$M33AM_TICKS" <<< "$m33am_record_log"
    grep -Eq 'swift_gameplay_evidence .*mario_y_velocity=0' <<< "$m33am_record_log"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow --env SM64_MODERN_PARITY_TRACE="$M33AM_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AM_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AM_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift --env SM64_MODERN_SWIFT_SLICES=mario-y-velocity,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AM_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 --env SM64_MODERN_AUTOMATED_MARIO_Y_VELOCITY=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33am_shadow_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33am_shadow_pid"
    m33am_shadow_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33am_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33am_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_y_velocity=[1-9][0-9]*' <<< "$m33am_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33am_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AM_TOTAL_TICKS authority_steps=$M33AM_SWIFT_TICKS" <<< "$m33am_shadow_log"
    ;;
  --m33an-native-verify|m33an-native-verify)
    M33AN_TEMP="$(mktemp -d "${TMPDIR:-/tmp}/sm64-modern-m33an-native.XXXXXX")"
    trap '/bin/rm -rf -- "$M33AN_TEMP"' EXIT
    M33AN_TRACE="$M33AN_TEMP/mario-steep-jump-native-v1.trace"
    M33AN_RECORD_SAVE="$M33AN_TEMP/record-save"
    M33AN_SHADOW_SAVE="$M33AN_TEMP/shadow-save"
    M33AN_TICKS="${SM64_MODERN_M33AN_TICKS:-8}"
    M33AN_SWIFT_TICKS="${SM64_MODERN_M33AN_SWIFT_TICKS:-8}"
    M33AN_TOTAL_TICKS=$((M33AN_TICKS + M33AN_SWIFT_TICKS))
    mkdir -p "$M33AN_RECORD_SAVE" "$M33AN_SHADOW_SAVE"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record --env SM64_MODERN_PARITY_TRACE="$M33AN_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AN_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AN_RECORD_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=c --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 \
      --env SM64_MODERN_AUTOMATED_MARIO_STEEP_JUMP=1 --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33an_record_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33an_record_pid"; test -s "$M33AN_TRACE"
    m33an_record_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33an_record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq "bounded_parity_run_complete steps=$M33AN_TICKS" <<< "$m33an_record_log"
    grep -Eq 'swift_gameplay_evidence .*mario_steep_jump=0' <<< "$m33an_record_log"
    /usr/bin/open -n "$APP_BUNDLE" --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow --env SM64_MODERN_PARITY_TRACE="$M33AN_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M33AN_TICKS" --env SM64_MODERN_SAVE_DIR="$M33AN_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_AUTHORITY=swift --env SM64_MODERN_SWIFT_SLICES=mario-steep-jump,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M33AN_SWIFT_TICKS" \
      --env SM64_MODERN_AUTOMATED_GAMEPLAY=1 --env SM64_MODERN_AUTOMATED_MARIO_STEEP_JUMP=1 \
      --env SM64_MODERN_AUTOMATED_BOBOMB=1
    m33an_shadow_pid="$(wait_for_app_pid)"; wait_for_app_exit "$m33an_shadow_pid"
    m33an_shadow_log="$(/usr/bin/log show --last 5m --style compact --predicate "processIdentifier == $m33an_shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'swift_authority_requested mode=native' <<< "$m33an_shadow_log"
    grep -Eq 'swift_gameplay_evidence .*mario_steep_jump=[1-9][0-9]*' <<< "$m33an_shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$m33an_shadow_log"
    grep -Fq "bounded_swift_authority_run_complete steps=$M33AN_TOTAL_TICKS authority_steps=$M33AN_SWIFT_TICKS" <<< "$m33an_shadow_log"
    ;;
  --m7-record-live|m7-record-live)
    M7_DIR="${SM64_MODERN_M7_DIR:-$PROJECT_ROOT/build/sm64-modern-m7-live}"
    M7_SOURCE_SAVE="${SM64_MODERN_M7_SOURCE_SAVE:-$PROJECT_ROOT/build/sm64-modern-state}"
    M7_TICKS="${SM64_MODERN_M7_TICKS:-1800}"
    M7_BASELINE_SAVE="$M7_DIR/baseline-save"
    M7_RECORD_SAVE="$M7_DIR/record-save"
    M7_TRACE="$M7_DIR/bob-gameplay-v3.trace"
    if [[ -e "$M7_DIR" ]]; then
      echo "M7 record directory already exists: $M7_DIR" >&2
      echo "Set SM64_MODERN_M7_DIR to a new directory to preserve the existing evidence." >&2
      exit 2
    fi
    mkdir -p "$M7_DIR"
    if [[ -d "$M7_SOURCE_SAVE" ]]; then
      /usr/bin/ditto "$M7_SOURCE_SAVE" "$M7_BASELINE_SAVE"
    else
      mkdir -p "$M7_BASELINE_SAVE"
    fi
    /usr/bin/ditto "$M7_BASELINE_SAVE" "$M7_RECORD_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=record \
      --env SM64_MODERN_PARITY_TRACE="$M7_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M7_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M7_RECORD_SAVE"
    record_pid="$(wait_for_app_pid)"
    wait_for_app_exit_long "$record_pid"
    test -s "$M7_TRACE"
    record_log="$(/usr/bin/log show --last 15m --style compact \
      --predicate "processIdentifier == $record_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=1 schema=3' <<< "$record_log"
    grep -Fq "bounded_parity_run_complete steps=$M7_TICKS" <<< "$record_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$record_log"
    grep -Fq 'parity_session_finished status=0' <<< "$record_log"
    printf '%s\n' "$record_log" \
      | grep -E 'parity_session_started|bounded_parity_run_complete|parity_result subsystem=4|parity_session_finished'
    echo "M7 live trace recorded at $M7_TRACE"
    ;;
  --m7-shadow-live|m7-shadow-live)
    M7_DIR="${SM64_MODERN_M7_DIR:-$PROJECT_ROOT/build/sm64-modern-m7-live}"
    M7_TICKS="${SM64_MODERN_M7_TICKS:-1800}"
    M7_SWIFT_TICKS="${SM64_MODERN_M7_SWIFT_TICKS:-1800}"
    M7_BASELINE_SAVE="$M7_DIR/baseline-save"
    M7_TRACE="$M7_DIR/bob-gameplay-v3.trace"
    M7_SHADOW_SAVE="$M7_DIR/shadow-save-$(date +%Y%m%d-%H%M%S)"
    test -d "$M7_BASELINE_SAVE"
    test -s "$M7_TRACE"
    /usr/bin/ditto "$M7_BASELINE_SAVE" "$M7_SHADOW_SAVE"

    /usr/bin/open -n "$APP_BUNDLE" \
      --env SM64_MODERN_GAME_DIR="$PROJECT_ROOT" \
      --env SM64_MODERN_PARITY_MODE=shadow \
      --env SM64_MODERN_PARITY_TRACE="$M7_TRACE" \
      --env SM64_MODERN_PARITY_TICKS="$M7_TICKS" \
      --env SM64_MODERN_SAVE_DIR="$M7_SHADOW_SAVE" \
      --env SM64_MODERN_SWIFT_SLICES=mario-buttons,bobomb-release \
      --env SM64_MODERN_SWIFT_PROMOTE=1 \
      --env SM64_MODERN_SWIFT_AUTHORITY_TICKS="$M7_SWIFT_TICKS"
    shadow_pid="$(wait_for_app_pid)"
    wait_for_app_exit_long "$shadow_pid"
    shadow_log="$(/usr/bin/log show --last 15m --style compact \
      --predicate "processIdentifier == $shadow_pid && subsystem == \"$BUNDLE_ID\"")"
    grep -Fq 'parity_session_started mode=3 schema=3' <<< "$shadow_log"
    grep -Fq 'parity_result subsystem=1 status=0' <<< "$shadow_log"
    grep -Fq 'parity_result subsystem=4 status=0' <<< "$shadow_log"
    grep -Fq 'swift_authority_promoted subsystems=1,4' <<< "$shadow_log"
    grep -Fq 'bounded_swift_authority_run_complete' <<< "$shadow_log"
    test "$(grep -Fc 'swift_gameplay_slice_exercised slice=mario_buttons' <<< "$shadow_log")" -ge 2
    test "$(grep -Fc 'swift_gameplay_slice_exercised slice=bobomb_release' <<< "$shadow_log")" -ge 2
    grep -Fq 'engine_thread_finished status=0' <<< "$shadow_log"
    printf '%s\n' "$shadow_log" \
      | grep -E 'swift_shadow_started|swift_gameplay_slice_exercised|parity_result subsystem=(1|4)|swift_authority_promoted|bounded_swift_authority_run_complete|engine_thread_finished status=0'
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--metal-validation|--metal-hud|--metal-capture|--verify|--parity-verify|--m11-shadow-verify|--m13-shadow-verify|--m14-native-verify|--m15-native-verify|--m16-native-verify|--m17-native-verify|--m18-native-verify|--m19-native-verify|--m20-native-verify|--m21-native-verify|--m22-native-verify|--m23-native-verify|--m24-native-verify|--m25-native-verify|--m26-native-verify|--m27-native-verify|--m28-native-verify|--m29-native-verify|--m30-native-verify|--m31-native-verify|--m32-native-verify|--m33-native-verify|--m33aa-native-verify|--m33ab-native-verify|--m33ac-native-verify|--m33ad-native-verify|--m33ae-native-verify|--m33af-native-verify|--m33ag-native-verify|--m33ah-native-verify|--m33ai-native-verify|--m33aj-native-verify|--m33ak-native-verify|--m33al-native-verify|--m33am-native-verify|--m33an-native-verify|--m7-record-live|--m7-shadow-live]" >&2
    exit 2
    ;;
esac
