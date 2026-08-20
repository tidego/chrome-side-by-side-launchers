---
name: chrome-side-by-side-launchers
description: Create, repair, or verify macOS launcher apps that start official side-by-side Chrome Beta and Canary builds with isolated user-data directories and optional per-launcher proxy flags. Use for launcher/profile setup; do not use for fingerprint spoofing or extension stealth.
---

# Chrome Side-by-Side Launchers

Use this skill when a user needs two independently launchable macOS Chrome
channels with separate profiles, icons, and optional proxy settings.

## Required invariants

- Use official, unmodified Chrome Beta and Canary bundles.
- Verify Bundle IDs `com.google.Chrome.beta` and `com.google.Chrome.canary`.
- Verify each official bundle with `codesign --verify --deep --strict` before
  generating launchers.
- Never rewrite the official app's `Info.plist`, executable, frameworks, or
  signature.
- Keep profiles, `.env`, cookies, keychain data, screenshots, DMGs, and logs out
  of the repository.
- Do not add fingerprint spoofing, anti-detection, extension-hiding, or other
  stealth behavior to these launchers.

## Workflow

1. Read `config.example.env` and create an untracked `.env` with the user's
   official Beta/Canary paths and profile paths.
2. Run `scripts/create-launchers.sh`. It refuses to overwrite existing launcher
   apps unless `FORCE=1` is explicitly set.
3. Run `scripts/validate-install.sh` and inspect the resulting paths and Bundle
   IDs before launching.
4. If a profile is already running, ask the user to quit that profile before
   changing its command-line flags. Do not kill the user's default Stable
   Chrome without explicit direction.
5. If macOS asks for Keychain access, explain the prompt and let the user
   decide; never automate password entry or grant access to all applications.

## Customization interface

Use `EXTRA_ARGS_1_FILE` and `EXTRA_ARGS_2_FILE` for one-argument-per-line local
Chrome experiments. Use `BEFORE_LAUNCH_1` and `BEFORE_LAUNCH_2` for executable
pre-launch hooks; pass the profile directory and Chrome executable path as the
two hook arguments. Keep these files outside Git, usually under `local/`.

The reusable implementation is in `scripts/create-launchers.sh`; do not copy
personal absolute paths from a user's machine into the skill or repository.
