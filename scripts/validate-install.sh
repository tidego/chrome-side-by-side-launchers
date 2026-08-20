#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$repo_dir/.env" ]]; then
  # shellcheck disable=SC1091
  source "$repo_dir/.env"
fi

BETA_APP="${BETA_APP:-/Applications/Google Chrome Beta.app}"
CANARY_APP="${CANARY_APP:-/Applications/Google Chrome Canary.app}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Desktop}"

check_app() {
  local app_path="$1"
  local expected_id="$2"
  local label="$3"
  local actual_id
  local executable

  [[ -d "$app_path" ]] || { printf 'missing %s: %s\n' "$label" "$app_path" >&2; return 1; }
  actual_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist")
  [[ "$actual_id" == "$expected_id" ]] || { printf 'bad %s Bundle ID: %s\n' "$actual_id" "$app_path" >&2; return 1; }
  codesign --verify --deep --strict "$app_path" >/dev/null
  executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app_path/Contents/Info.plist")
  [[ -x "$app_path/Contents/MacOS/$executable" ]] || return 1
  printf 'ok %s: %s (%s)\n' "$label" "$actual_id" "$app_path"
}

check_app "$BETA_APP" com.google.Chrome.beta "Chrome Beta"
check_app "$CANARY_APP" com.google.Chrome.canary "Chrome Canary"

for launcher in "$OUTPUT_DIR/Google Chrome1.app" "$OUTPUT_DIR/Google Chrome2.app"; do
  launcher_executable="$(basename "$launcher" .app | sed 's/^Google //' | tr -d ' ')"
  [[ -x "$launcher/Contents/MacOS/$launcher_executable" ]] || {
    printf 'missing launcher executable: %s\n' "$launcher"
    exit 1
  }
done

printf 'ok launchers: %s and %s\n' "$OUTPUT_DIR/Google Chrome1.app" "$OUTPUT_DIR/Google Chrome2.app"
