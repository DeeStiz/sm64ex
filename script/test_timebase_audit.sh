#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED="$PROJECT_ROOT/tests/fixtures/sm64_modern_timebase_audit.tsv"
CADENCE_MANIFEST="$PROJECT_ROOT/tests/fixtures/sm64_modern_timebase_cadence.tsv"
RECEIPT_DRIFT_CONTRACT="$PROJECT_ROOT/tests/fixtures/sm64_modern_timebase_receipt_drift.tsv"
RECEIPT_DRIFT_BASELINE_COMMIT="6f586de9ba16024ff0463b6f24869a896a4eeb62"
TIMEBASE_AUDIT_MODE="${SM64_MODERN_TIMEBASE_AUDIT_MODE:-strict}"
RECEIPT_DRIFT_APPROVAL="${SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED:-}"
RECEIPT_DRIFT_APPROVAL_TOKEN='M34_TIMEBASE_RECEIPT_SEAM_V1'
CALLABLE_RANDOM_PATTERN='\brandom_(u16|float|sign|fixed_seed)\s*\('
ACTUAL="$(mktemp "${TMPDIR:-/tmp}/sm64-modern-timebase-audit.XXXXXX")"
RECEIPT_EXPECTED_DELTAS=""
RECEIPT_ACTUAL_DELTAS=""
trap '/bin/rm -f -- "$ACTUAL" "$RECEIPT_EXPECTED_DELTAS" "$RECEIPT_ACTUAL_DELTAS"' EXIT

audit_fail() {
  echo "Timebase audit: $*" >&2
  exit 1
}

count_category() {
  local category="$1"
  local pattern="$2"
  local counts
  local files
  local matches
  counts="$(rg --count-matches -g '*.c' "$pattern" \
    "$PROJECT_ROOT/src/game" "$PROJECT_ROOT/src/engine" || true)"
  files="$(printf '%s\n' "$counts" | awk 'NF { files++ } END { print files + 0 }')"
  matches="$(printf '%s\n' "$counts" | awk -F: 'NF { total += $NF } END { print total + 0 }')"
  printf '%s\t%s\t%s\n' "$category" "$files" "$matches" >> "$ACTUAL"
}

count_current_file() {
  local pattern="$1"
  local source="$2"
  local count
  count="$(rg -o --count-matches "$pattern" "$PROJECT_ROOT/$source" 2>/dev/null \
    | awk -F: '{ total += $NF } END { print total + 0 }' || true)"
  printf '%s\n' "${count:-0}"
}

count_baseline_file() {
  local pattern="$1"
  local source="$2"
  local count
  count="$(git show "$RECEIPT_DRIFT_BASELINE_COMMIT:$source" \
    | rg -o -- "$pattern" \
    | wc -l | tr -d ' ' || true)"
  printf '%s\n' "${count:-0}"
}

source_inventory_paths() {
  {
    git ls-tree -r --name-only "$RECEIPT_DRIFT_BASELINE_COMMIT" -- src/game src/engine || true
    (cd "$PROJECT_ROOT" && rg --files src/game src/engine || true)
  } | rg '\.c$' | sort -u || true
}

count_tree_category() {
  local pattern="$1"
  local tree="$2"
  local source
  local count
  local files=0
  local matches=0
  local paths
  paths="$(source_inventory_paths)"
  while IFS= read -r source; do
    [[ -n "$source" ]] || continue
    if [[ "$tree" == baseline ]]; then
      count="$(count_baseline_file "$pattern" "$source")"
    else
      [[ -f "$PROJECT_ROOT/$source" ]] || continue
      count="$(count_current_file "$pattern" "$source")"
    fi
    if (( count > 0 )); then
      files=$((files + 1))
      matches=$((matches + count))
    fi
  done <<< "$paths"
  printf '%s\t%s\n' "$files" "$matches"
}

printf 'category\tfiles\tmatches\n' > "$ACTUAL"
count_category object_timer '\boTimer\b'
count_category mario_action_timer '\bactionTimer\b'
count_category global_timer '\bgGlobalTimer\b'
count_category random_calls '\brandom_(u16|float|sign|fixed_seed)\b'
count_category animation_sites 'anim(Frame|Accel)|AnimFrame|set_mario_anim|cur_obj_init_animation|cur_obj_check_if_near_animation_end'

validate_cadence_manifest() {
  local expected_header=$'category\tscope\tsource\tsymbol\tunit\tcadence_policy\tstatus\treason'
  local header
  local line_number=1
  local category
  local scope
  local source
  local symbol
  local unit
  local cadence_policy
  local status
  local reason
  local extra
  local row_count=0

  if [[ ! -f "$CADENCE_MANIFEST" ]]; then
    echo "Missing cadence manifest: $CADENCE_MANIFEST" >&2
    return 1
  fi

  header="$(head -n 1 "$CADENCE_MANIFEST")"
  if [[ "$header" != "$expected_header" ]]; then
    echo "Cadence manifest schema mismatch on line 1" >&2
    echo "Expected: $expected_header" >&2
    echo "Actual:   $header" >&2
    return 1
  fi

  # A row is a governing seam, not a raw grep count. Keep the vocabulary
  # finite so a new row cannot silently become an unclassified time source.
  while IFS=$'\t' read -r category scope source symbol unit cadence_policy status reason extra; do
    line_number=$((line_number + 1))
    if [[ -z "$category$scope$source$symbol$unit$cadence_policy$status$reason" ]]; then
      echo "Cadence manifest line $line_number is blank" >&2
      return 1
    fi
    if [[ -n "$extra" ]]; then
      echo "Cadence manifest line $line_number has more than 8 columns" >&2
      return 1
    fi
    if [[ -z "$category" || -z "$scope" || -z "$source" || -z "$symbol" || -z "$unit" \
       || -z "$cadence_policy" || -z "$status" || -z "$reason" ]]; then
      echo "Cadence manifest line $line_number has an empty column" >&2
      return 1
    fi

    case "$category" in
      named_timer_field|object_timer|mario_action_timer|level_script|behavior_script|random_calls|animation_sites|animation_event|area_cadence|global_timer|transition|save|hud|dialog|menu|file_select|star_select|title_screen|demo|input|rumble|audio|presentation)
        ;;
      *)
        echo "Cadence manifest line $line_number has invalid category: $category" >&2
        return 1
        ;;
    esac
    case "$scope" in
      M8b|M8c|M8d)
        ;;
      *)
        echo "Cadence manifest line $line_number has invalid scope: $scope" >&2
        return 1
        ;;
    esac
    case "$unit" in
      legacy_frame|legacy_tick|paired_boundary|native_tick|event|input_sample|audio_block|presentation_frame)
        ;;
      *)
        echo "Cadence manifest line $line_number has invalid unit: $unit" >&2
        return 1
        ;;
    esac
    case "$cadence_policy" in
      paired_boundary|legacy_each_tick|native_each_tick|event_ordered|render_cadence|defer_m8c|defer_m8d|input_boundary|audio_block|presentation_frame)
        ;;
      *)
        echo "Cadence manifest line $line_number has invalid cadence policy: $cadence_policy" >&2
        return 1
        ;;
    esac
    case "$status" in
      audited|deferred)
        ;;
      *)
        echo "Cadence manifest line $line_number has invalid status: $status" >&2
        echo "UNKNOWN/unclassified rows are not permitted" >&2
        return 1
        ;;
    esac
    if printf '%s\n' "$reason" | rg -qi '(^|[^[:alpha:]])(unknown|unclassified)([^[:alpha:]]|$)'; then
      echo "Cadence manifest line $line_number contains an UNKNOWN/unclassified reason" >&2
      return 1
    fi
    case "$source" in
      /*|../*|*/../*)
        echo "Cadence manifest line $line_number has an unsafe source path: $source" >&2
        return 1
        ;;
      src/*|include/*|SM64Modern/*.swift)
        ;;
      *)
        echo "Cadence manifest line $line_number has a non-source path: $source" >&2
        return 1
        ;;
    esac
    if [[ ! -f "$PROJECT_ROOT/$source" ]]; then
      echo "Cadence manifest line $line_number references missing source: $source" >&2
      return 1
    fi
    if ! rg -q -w -- "$symbol" "$PROJECT_ROOT/$source"; then
      echo "Cadence manifest line $line_number references missing symbol '$symbol' in $source" >&2
      return 1
    fi
    row_count=$((row_count + 1))
  done < <(tail -n +2 "$CADENCE_MANIFEST")

  if [[ "$row_count" -eq 0 ]]; then
    echo "Cadence manifest contains no governing seams" >&2
    return 1
  fi

  # These anchors are deliberately explicit: they prevent a future manifest
  # rewrite from dropping one of the M8b/M8c/M8d ownership boundaries while
  # still allowing additional governing rows to be added.
  local required_anchor
  local required_source
  local required_symbol
  local required_category
  local required_categories=(
    named_timer_field
    object_timer
    mario_action_timer
    level_script
    behavior_script
    random_calls
    animation_sites
    animation_event
    area_cadence
    global_timer
    transition
    save
    hud
    dialog
    menu
    file_select
    star_select
    title_screen
    demo
    input
    rumble
    audio
    presentation
  )
  for required_category in "${required_categories[@]}"; do
    if ! awk -F '\t' -v category="$required_category" \
      'NR > 1 && $1 == category { found = 1 } END { exit !found }' \
      "$CADENCE_MANIFEST"; then
      echo "Cadence manifest is missing required category: $required_category" >&2
      return 1
    fi
  done
  local required_anchors=(
    'include/object_fields.h|oTimer'
    'include/object_fields.h|oIntangibleTimer'
    'include/object_fields.h|oUnlockDoorStarTimer'
    'include/object_fields.h|oUkikiTextboxTimer'
    'include/object_fields.h|oTTCPendulumSoundTimer'
    'include/object_fields.h|oPlatformTimer'
    'include/types.h|animTimer'
    'include/types.h|bhvDelayTimer'
    'include/types.h|actionTimer'
    'src/engine/level_script.c|level_cmd_sleep'
    'src/engine/level_script.c|level_cmd_sleep2'
    'src/engine/level_script.c|level_cmd_call_loop'
    'src/engine/behavior_script.c|bhv_cmd_delay'
    'src/engine/behavior_script.c|bhv_cmd_set_random_float'
    'src/engine/behavior_script.c|bhv_cmd_animate'
    'src/engine/behavior_script.c|bhv_cmd_animate_texture'
    'src/game/area.c|area_update_objects'
    'src/game/rendering_graph_node.c|gAreaUpdateCounter'
    'src/engine/graph_node.c|geo_update_animation_frame'
    'src/game/rendering_graph_node.c|geo_set_animation_globals'
    'src/game/spawn_sound.c|exec_anim_sound_state'
    'src/game/game_init.c|gGlobalTimer'
    'src/game/screen_transition.c|set_and_reset_transition_fade_timer'
    'src/game/area.c|gWarpTransDelay'
    'src/game/area.h|texTimer'
    'src/game/camera.c|gCutsceneTimer'
    'src/game/paintings.c|move_ddd_painting'
    'src/game/mario_actions_cutscene.c|handle_save_menu'
    'src/menu/file_select.c|save_file_erase'
    'src/menu/file_select.c|save_file_copy'
    'src/game/paintings.c|save_file_set_flags'
    'src/game/interaction.c|save_file_set_cap_pos'
    'src/game/hud.c|sPowerMeterVisibleTimer'
    'src/game/ingame_menu.c|gDialogBoxOpenTimer'
    'src/game/ingame_menu.c|gMenuHoldKeyTimer'
    'src/game/ingame_menu.c|gCutsceneMsgTimer'
    'src/game/ingame_menu.c|gDialogColorFadeTimer'
    'src/game/ingame_menu.c|gCourseDoneMenuTimer'
    'src/menu/file_select.c|sMainMenuTimer'
    'src/menu/file_select.c|sCursorClickingTimer'
    'src/menu/star_select.c|sActSelectorMenuTimer'
    'src/menu/star_select.c|oStarSelectorTimer'
    'src/menu/intro_geo.c|gTitleZoomCounter'
    'src/menu/intro_geo.c|gTitleFadeCounter'
    'src/menu/intro_geo.c|gGameOverFrameCounter'
    'src/game/mario_actions_cutscene.c|print_displaying_credits_entry'
    'src/game/mario_misc.c|geo_draw_mario_head_goddard'
    'src/game/game_init.c|record_demo'
    'src/game/game_init.c|run_demo_inputs'
    'src/game/game_init.c|read_controller_inputs'
    'src/game/thread6.c|thread6_rumble_loop'
    'src/pc/pc_main.c|create_next_audio_buffer'
    'src/pc/sm64_modern_gameplay_parity.c|sm64_modern_parity_begin_tick'
    'src/game/sound_init.c|audio_game_loop_tick'
    'src/pc/controller/controller_sm64_modern.c|sm64_modern_input_status'
    'src/pc/gfx/gfx_pc.c|gfx_start_frame'
    'src/pc/gfx/gfx_pc.c|gfx_end_frame'
    'src/game/game_init.c|display_and_vsync'
    'SM64Modern/EngineHost.swift|initializeCEngineOnEngineThread'
    'SM64Modern/EngineHost.swift|runFixedStepLoop'
  )
  for required_anchor in "${required_anchors[@]}"; do
    required_source="${required_anchor%%|*}"
    required_symbol="${required_anchor#*|}"
    if ! awk -F '\t' -v source="$required_source" -v symbol="$required_symbol" \
      'NR > 1 && $3 == source && $4 == symbol { found = 1 } END { exit !found }' \
      "$CADENCE_MANIFEST"; then
      echo "Cadence manifest is missing required anchor: $required_source:$required_symbol" >&2
      return 1
    fi
  done

  # Mixed seams must retain both ownership records. The M8b row records
  # elapsed-time progression; the M8d row records the active device/delivery
  # edge and its native cadence ownership.
  local required_scoped_anchor
  local required_scoped_category
  local required_scoped_scope
  local required_scoped_source
  local required_scoped_symbol
  local required_scoped_status
  local required_scoped_anchors=(
    $'transition\tM8b\tsrc/game/camera.c\tgCutsceneTimer\taudited'
    $'transition\tM8b\tsrc/game/camera.c\tplay_cutscene\taudited'
    $'transition\tM8b\tsrc/game/paintings.c\tmove_ddd_painting\taudited'
    $'save\tM8b\tsrc/game/mario_actions_cutscene.c\thandle_save_menu\taudited'
    $'save\tM8b\tsrc/menu/file_select.c\tsave_file_erase\taudited'
    $'save\tM8b\tsrc/menu/file_select.c\tsave_file_copy\taudited'
    $'save\tM8b\tsrc/game/paintings.c\tsave_file_set_flags\taudited'
    $'save\tM8c\tsrc/game/interaction.c\tsave_file_set_cap_pos\taudited'
    $'presentation\tM8c\tsrc/game/paintings.c\tpainting_update_floors\taudited'
    $'title_screen\tM8b\tsrc/game/mario_actions_cutscene.c\tprint_displaying_credits_entry\taudited'
    $'animation_event\tM8b\tsrc/game/mario_misc.c\tgeo_draw_mario_head_goddard\taudited'
    $'presentation\tM8d\tsrc/game/mario_misc.c\tgeo_draw_mario_head_goddard\tdeferred'
    $'demo\tM8b\tsrc/game/game_init.c\trun_demo_inputs\taudited'
    $'demo\tM8d\tsrc/game/game_init.c\trun_demo_inputs\tdeferred'
    $'input\tM8b\tsrc/game/game_init.c\tread_controller_inputs\taudited'
    $'input\tM8d\tsrc/game/game_init.c\tread_controller_inputs\taudited'
    $'rumble\tM8b\tsrc/game/thread6.c\tthread6_rumble_loop\taudited'
    $'rumble\tM8d\tsrc/game/thread6.c\tthread6_rumble_loop\taudited'
    $'global_timer\tM8b\tsrc/game/game_init.c\tdisplay_and_vsync\taudited'
    $'presentation\tM8d\tsrc/game/game_init.c\tdisplay_and_vsync\taudited'
    $'audio\tM8d\tsrc/pc/pc_main.c\tcreate_next_audio_buffer\taudited'
    $'presentation\tM8d\tsrc/pc/sm64_modern_gameplay_parity.c\tsm64_modern_parity_begin_tick\taudited'
    $'presentation\tM8d\tSM64Modern/EngineHost.swift\tinitializeCEngineOnEngineThread\taudited'
    $'presentation\tM8d\tSM64Modern/EngineHost.swift\trunFixedStepLoop\taudited'
  )
  for required_scoped_anchor in "${required_scoped_anchors[@]}"; do
    IFS=$'\t' read -r required_scoped_category required_scoped_scope \
      required_scoped_source required_scoped_symbol required_scoped_status \
      <<< "$required_scoped_anchor"
    if ! awk -F '\t' \
      -v category="$required_scoped_category" \
      -v scope="$required_scoped_scope" \
      -v source="$required_scoped_source" \
      -v symbol="$required_scoped_symbol" \
      -v status="$required_scoped_status" \
      'NR > 1 && $1 == category && $2 == scope && $3 == source && $4 == symbol && $7 == status { found = 1 } END { exit !found }' \
      "$CADENCE_MANIFEST"; then
      echo "Cadence manifest is missing required ownership row: $required_scoped_category/$required_scoped_scope $required_scoped_source:$required_scoped_symbol ($required_scoped_status)" >&2
      return 1
    fi
  done
}

validate_receipt_drift_contract() {
  local expected_header=$'category\tsource\tbaseline_matches\tcurrent_matches\tdelta\trequired_tokens\treceipt_commit\treceipt_subject'
  local header
  local line_number=1
  local category
  local source
  local baseline_matches
  local current_matches
  local delta
  local required_tokens
  local receipt_commit
  local receipt_subject
  local extra
  local pattern
  local actual_baseline
  local actual_current
  local commit_subject
  local token
  local token_list
  local rows=0
  local paths
  local category_name
  local fixture_files
  local fixture_matches
  local delta_sum
  local actual_files
  local actual_matches
  local expected_matches
  local callable_baseline
  local callable_current

  [[ -f "$RECEIPT_DRIFT_CONTRACT" ]] \
    || audit_fail "missing receipt-seam drift contract: $RECEIPT_DRIFT_CONTRACT"
  header="$(head -n 1 "$RECEIPT_DRIFT_CONTRACT")"
  [[ "$header" == "$expected_header" ]] \
    || audit_fail "receipt-seam drift contract schema mismatch"
  git cat-file -e "$RECEIPT_DRIFT_BASELINE_COMMIT^{commit}" 2>/dev/null \
    || audit_fail "receipt-seam drift baseline commit is unavailable: $RECEIPT_DRIFT_BASELINE_COMMIT"
  git merge-base --is-ancestor "$RECEIPT_DRIFT_BASELINE_COMMIT" HEAD \
    || audit_fail "receipt-seam drift baseline is not an ancestor of HEAD"

  RECEIPT_EXPECTED_DELTAS="$(mktemp "${TMPDIR:-/tmp}/sm64-modern-timebase-receipt-expected.XXXXXX")"
  RECEIPT_ACTUAL_DELTAS="$(mktemp "${TMPDIR:-/tmp}/sm64-modern-timebase-receipt-actual.XXXXXX")"

  while IFS=$'\t' read -r category source baseline_matches current_matches delta \
    required_tokens receipt_commit receipt_subject extra; do
    line_number=$((line_number + 1))
    [[ -n "$category$source$baseline_matches$current_matches$delta$required_tokens$receipt_commit$receipt_subject" ]] \
      || audit_fail "receipt-seam drift contract line $line_number is blank"
    [[ -z "$extra" ]] \
      || audit_fail "receipt-seam drift contract line $line_number has more than 8 columns"
    case "$category" in
      object_timer)
        pattern='\boTimer\b'
        ;;
      random_calls)
        pattern='\brandom_(u16|float|sign|fixed_seed)\b'
        ;;
      *)
        audit_fail "receipt-seam drift contract line $line_number has unsupported category: $category"
        ;;
    esac
    [[ "$source" == src/*.c && "$source" != */../* && "$source" != ../* ]] \
      || audit_fail "receipt-seam drift contract line $line_number has an unsafe source: $source"
    [[ -f "$PROJECT_ROOT/$source" ]] \
      || audit_fail "receipt-seam drift contract line $line_number references missing source: $source"
    git cat-file -e "$RECEIPT_DRIFT_BASELINE_COMMIT:$source" 2>/dev/null \
      || audit_fail "receipt-seam drift contract line $line_number source is absent at baseline: $source"
    awk -F '\t' -v category="$category" -v source="$source" \
      'NR > 1 && $1 == category && $2 == source { found = 1 } END { exit !found }' \
      "$RECEIPT_EXPECTED_DELTAS" \
      && audit_fail "receipt-seam drift contract duplicates $category/$source" || true

    [[ "$baseline_matches" =~ ^[0-9]+$ && "$current_matches" =~ ^[0-9]+$ \
       && "$delta" =~ ^-?[0-9]+$ ]] \
      || audit_fail "receipt-seam drift contract line $line_number has non-numeric counts"
    actual_baseline="$(count_baseline_file "$pattern" "$source")"
    actual_current="$(count_current_file "$pattern" "$source")"
    [[ "$actual_baseline" == "$baseline_matches" ]] \
      || audit_fail "receipt-seam drift baseline mismatch for $source: expected $baseline_matches, found $actual_baseline"
    [[ "$actual_current" == "$current_matches" ]] \
      || audit_fail "receipt-seam drift current mismatch for $source: expected $current_matches, found $actual_current"
    [[ "$delta" -eq $((current_matches - baseline_matches)) ]] \
      || audit_fail "receipt-seam drift delta mismatch for $source"

    git cat-file -e "$receipt_commit^{commit}" 2>/dev/null \
      || audit_fail "receipt-seam drift receipt commit is unavailable: $receipt_commit"
    git merge-base --is-ancestor "$receipt_commit" HEAD \
      || audit_fail "receipt-seam drift receipt commit is not an ancestor: $receipt_commit"
    commit_subject="$(git show -s --format=%s "$receipt_commit")"
    [[ "$commit_subject" == "$receipt_subject" ]] \
      || audit_fail "receipt-seam drift receipt subject mismatch for $source"
    if ! git diff-tree --no-commit-id --name-only -r "$receipt_commit" \
      | rg -Fxq -- "$source"; then
      audit_fail "receipt-seam drift receipt commit does not touch $source: $receipt_commit"
    fi
    IFS=';' read -r -a token_list <<< "$required_tokens"
    for token in "${token_list[@]}"; do
      [[ -n "$token" ]] || audit_fail "receipt-seam drift contract line $line_number has an empty required token"
      rg -Fq -- "$token" "$PROJECT_ROOT/$source" \
        || audit_fail "receipt-seam drift source token is missing for $source: $token"
    done
    printf '%s\t%s\t%s\t%s\t%s\n' \
      "$category" "$source" "$baseline_matches" "$current_matches" "$delta" \
      >> "$RECEIPT_EXPECTED_DELTAS"
    rows=$((rows + 1))
  done < <(tail -n +2 "$RECEIPT_DRIFT_CONTRACT")

  [[ "$rows" -eq 8 ]] \
    || audit_fail "receipt-seam drift contract must contain exactly 8 rows, found $rows"
  for category_name in object_timer random_calls; do
    awk -F '\t' -v category="$category_name" \
      'NR > 1 && $1 == category { found = 1 } END { exit !found }' \
      "$RECEIPT_DRIFT_CONTRACT" \
      || audit_fail "receipt-seam drift contract is missing category: $category_name"
  done

  paths="$(source_inventory_paths)"
  while IFS= read -r source; do
    [[ -n "$source" ]] || continue
    for category_name in object_timer random_calls; do
      if [[ "$category_name" == object_timer ]]; then
        pattern='\boTimer\b'
      else
        pattern='\brandom_(u16|float|sign|fixed_seed)\b'
      fi
      actual_baseline="$(count_baseline_file "$pattern" "$source")"
      actual_current=0
      if [[ -f "$PROJECT_ROOT/$source" ]]; then
        actual_current="$(count_current_file "$pattern" "$source")"
      fi
      if [[ "$actual_baseline" -ne "$actual_current" ]]; then
        printf '%s\t%s\t%s\t%s\t%s\n' \
          "$category_name" "$source" "$actual_baseline" "$actual_current" \
          "$((actual_current - actual_baseline))" >> "$RECEIPT_ACTUAL_DELTAS"
      fi
    done
  done <<< "$paths"
  if ! diff -u <(sort "$RECEIPT_EXPECTED_DELTAS") <(sort "$RECEIPT_ACTUAL_DELTAS"); then
    audit_fail "receipt-seam drift per-file attribution changed; refresh the contract only after review"
  fi

  for category_name in object_timer random_calls; do
    fixture_files="$(awk -F '\t' -v category="$category_name" \
      'NR > 1 && $1 == category { print $2 }' "$EXPECTED")"
    fixture_matches="$(awk -F '\t' -v category="$category_name" \
      'NR > 1 && $1 == category { print $3 }' "$EXPECTED")"
    delta_sum="$(awk -F '\t' -v category="$category_name" \
      '$1 == category { total += $5 } END { print total + 0 }' "$RECEIPT_EXPECTED_DELTAS")"
    actual_files="$(awk -F '\t' -v category="$category_name" \
      'NR > 1 && $1 == category { print $2 }' "$ACTUAL")"
    actual_matches="$(awk -F '\t' -v category="$category_name" \
      'NR > 1 && $1 == category { print $3 }' "$ACTUAL")"
    expected_matches=$((fixture_matches + delta_sum))
    [[ "$actual_files" == "$fixture_files" ]] \
      || audit_fail "receipt-seam drift changed file cardinality for $category_name: fixture $fixture_files, current $actual_files"
    [[ "$actual_matches" == "$expected_matches" ]] \
      || audit_fail "receipt-seam drift aggregate mismatch for $category_name: expected $expected_matches, found $actual_matches"
  done

  callable_baseline="$(count_tree_category "$CALLABLE_RANDOM_PATTERN" baseline)"
  callable_current="$(count_tree_category "$CALLABLE_RANDOM_PATTERN" current)"
  [[ "$callable_baseline" == $'79\t289' && "$callable_current" == $'79\t289' ]] \
    || audit_fail "receipt-seam drift callable RNG inventory changed: baseline=$callable_baseline current=$callable_current"

  printf 'timebase_receipt_drift_contract=pass rows=%s baseline=%s callable_rng=79/289\n' \
    "$rows" "$RECEIPT_DRIFT_BASELINE_COMMIT"
}

if rg -q 'Timer\(timeInterval:' "$PROJECT_ROOT/SM64Modern/EngineHost.swift"; then
  echo "EngineHost regressed to a coalescing Foundation Timer" >&2
  exit 1
fi
rg -q 'RationalFixedStepScheduler' "$PROJECT_ROOT/SM64Modern/EngineHost.swift"

case "$TIMEBASE_AUDIT_MODE" in
  strict)
    [[ -z "$RECEIPT_DRIFT_APPROVAL" ]] \
      || audit_fail "receipt-seam approval requires SM64_MODERN_TIMEBASE_AUDIT_MODE=receipt-seam-drift"
    if ! diff -u "$EXPECTED" "$ACTUAL"; then
      echo "Time-dependent gameplay inventory changed; classify the drift before updating the fixture." >&2
      exit 1
    fi
    ;;
  receipt-seam-drift)
    [[ "$RECEIPT_DRIFT_APPROVAL" == "$RECEIPT_DRIFT_APPROVAL_TOKEN" ]] \
      || audit_fail "receipt-seam mode requires SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED=$RECEIPT_DRIFT_APPROVAL_TOKEN"
    validate_receipt_drift_contract
    ;;
  *)
    audit_fail "unsupported SM64_MODERN_TIMEBASE_AUDIT_MODE: $TIMEBASE_AUDIT_MODE"
    ;;
esac
validate_cadence_manifest
if [[ "$TIMEBASE_AUDIT_MODE" == strict ]]; then
  echo "SM64 Modern timebase audit passed"
else
  echo "SM64 Modern timebase audit passed mode=$TIMEBASE_AUDIT_MODE"
fi
