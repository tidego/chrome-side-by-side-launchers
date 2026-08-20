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
PROFILE_1="${PROFILE_1:-$HOME/Chrome_Profiles/Profile_1_Beta}"
PROFILE_2="${PROFILE_2:-$HOME/Chrome_Profiles/Profile_2_Canary}"
PROXY_1="${PROXY_1:-}"
PROXY_2="${PROXY_2:-}"
LANG_1="${LANG_1:-}"
LANG_2="${LANG_2:-}"
EXTRA_ARGS_1_FILE="${EXTRA_ARGS_1_FILE:-}"
EXTRA_ARGS_2_FILE="${EXTRA_ARGS_2_FILE:-}"
BEFORE_LAUNCH_1="${BEFORE_LAUNCH_1:-}"
BEFORE_LAUNCH_2="${BEFORE_LAUNCH_2:-}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

shell_quote() {
  printf '%q' "$1"
}

official_executable() {
  local app_path="$1"
  local expected_id="$2"
  local app_id
  local executable

  [[ -d "$app_path" ]] || die "application not found: $app_path"
  app_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist")
  [[ "$app_id" == "$expected_id" ]] || die "$app_path has Bundle ID $app_id; expected $expected_id"
  codesign --verify --deep --strict "$app_path" >/dev/null || die "code-signature verification failed: $app_path"
  executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app_path/Contents/Info.plist")
  [[ -x "$app_path/Contents/MacOS/$executable" ]] || die "executable not found: $app_path/Contents/MacOS/$executable"
  printf '%s\n' "$app_path/Contents/MacOS/$executable"
}

write_launcher() {
  local app_name="$1"
  local bundle_id="$2"
  local executable_name="$3"
  local chrome_bin="$4"
  local profile_dir="$5"
  local profile_env="$6"
  local proxy="$7"
  local language="$8"
  local extra_args_file="$9"
  local before_launch="${10}"
  local output_app="$OUTPUT_DIR/$app_name.app"
  local contents_dir="$output_app/Contents"
  local macos_dir="$contents_dir/MacOS"
  local resources_dir="$contents_dir/Resources"
  local icon_source="$(dirname "$chrome_bin")/../Resources/app.icns"
  local chrome_bin_q profile_dir_q proxy_q language_q extra_args_q before_launch_q

  if [[ -e "$output_app" ]]; then
    [[ "${FORCE:-0}" == "1" ]] || die "$output_app already exists; set FORCE=1 after confirming the path"
    mv "$output_app" "$output_app.backup-$(date +%Y%m%d-%H%M%S)"
  fi

  mkdir -p "$macos_dir" "$resources_dir"
  chrome_bin_q=$(shell_quote "$chrome_bin")
  profile_dir_q=$(shell_quote "$profile_dir")
  proxy_q=$(shell_quote "$proxy")
  language_q=$(shell_quote "$language")
  extra_args_q=$(shell_quote "$extra_args_file")
  before_launch_q=$(shell_quote "$before_launch")

  cat > "$contents_dir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$app_name</string>
  <key>CFBundleExecutable</key>
  <string>$executable_name</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
  <key>CFBundleIdentifier</key>
  <string>$bundle_id</string>
  <key>CFBundleName</key>
  <string>$app_name</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
</dict>
</plist>
PLIST

  cat > "$macos_dir/$executable_name" <<LAUNCHER
#!/bin/zsh
set -e

chrome_bin=$chrome_bin_q
default_profile=$profile_dir_q
profile_dir="\${$profile_env:-\$default_profile}"
proxy=$proxy_q
language=$language_q
extra_args_file=$extra_args_q
before_launch=$before_launch_q

[[ -x "\$chrome_bin" ]] || { print -u2 "Chrome executable not found: \$chrome_bin"; exit 1; }
mkdir -p "\$profile_dir"
if [[ -n "\$before_launch" ]]; then
  [[ -x "\$before_launch" ]] || { print -u2 "Launch hook is not executable: \$before_launch"; exit 1; }
  "\$before_launch" "\$profile_dir" "\$chrome_bin"
fi
args=("--user-data-dir=\$profile_dir" "--no-first-run" "--no-default-browser-check")
[[ -n "\$proxy" ]] && args+=("--proxy-server=\$proxy")
[[ -n "\$language" ]] && args+=("--lang=\$language")
if [[ -n "\$extra_args_file" ]]; then
  [[ -f "\$extra_args_file" ]] || { print -u2 "Extra-args file not found: \$extra_args_file"; exit 1; }
  while IFS= read -r extra_arg || [[ -n "\$extra_arg" ]]; do
    [[ -z "\$extra_arg" || "\$extra_arg" == \#* ]] && continue
    args+=("\$extra_arg")
  done < "\$extra_args_file"
fi
exec "\$chrome_bin" "\${args[@]}"
LAUNCHER
  chmod 755 "$macos_dir/$executable_name"

  if [[ -f "$icon_source" ]]; then
    cp "$icon_source" "$resources_dir/AppIcon.icns"
  fi

  plutil -lint "$contents_dir/Info.plist" >/dev/null
  printf 'created %s\n' "$output_app"
}

beta_bin=$(official_executable "$BETA_APP" com.google.Chrome.beta)
canary_bin=$(official_executable "$CANARY_APP" com.google.Chrome.canary)
mkdir -p "$OUTPUT_DIR"

write_launcher "Google Chrome1" com.mycompany.Chrome1 Chrome1 "$beta_bin" "$PROFILE_1" CHROME1_USER_DATA_DIR "$PROXY_1" "$LANG_1" "$EXTRA_ARGS_1_FILE" "$BEFORE_LAUNCH_1"
write_launcher "Google Chrome2" com.mycompany.Chrome2 Chrome2 "$canary_bin" "$PROFILE_2" CHROME2_USER_DATA_DIR "$PROXY_2" "$LANG_2" "$EXTRA_ARGS_2_FILE" "$BEFORE_LAUNCH_2"

lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$lsregister" ]]; then
  "$lsregister" -f "$OUTPUT_DIR/Google Chrome1.app" "$OUTPUT_DIR/Google Chrome2.app"
fi
