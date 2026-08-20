#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$PROJECT_ROOT/src/game/ingame_menu.c"

extract_function() {
  local name="$1"
  sed -n "/^void ${name}(/,/^}/p" "$SOURCE"
}

for function in \
  create_dialog_box \
  create_dialog_box_with_var \
  create_dialog_inverted_box \
  create_dialog_box_with_response \
  set_menu_mode \
  reset_cutscene_msg_fade \
  set_cutscene_message; do
  body="$(extract_function "$function")"
  if [[ -z "$body" ]]; then
    echo "Could not locate $function in $SOURCE" >&2
    exit 1
  fi
  if printf '%s\n' "$body" | rg -q 'sm64_modern_timebase_should_advance_legacy_domain'; then
    echo "$function must not drop one-shot state admissions on a held native step" >&2
    exit 1
  fi
  case "$function" in
    create_dialog_box*)
      printf '%s\n' "$body" | rg -q 'gDialogID == -1' || {
        echo "$function lost its one-shot dialog admission guard" >&2
        exit 1
      }
      ;;
    set_menu_mode)
      printf '%s\n' "$body" | rg -q 'gMenuMode == -1' || {
        echo "$function lost its one-shot menu admission guard" >&2
        exit 1
      }
      ;;
    set_cutscene_message)
      printf '%s\n' "$body" | rg -q 'gCutsceneMsgIndex == -1' || {
        echo "$function lost its one-shot cutscene-message admission guard" >&2
        exit 1
      }
      ;;
  esac
done

printf '%s\n' 'SM64 Modern course-exit cadence one-shot admissions passed'
