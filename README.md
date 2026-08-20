# Chrome Side-by-Side Launchers

[English](README.md) · [中文](README.zh-CN.md)

> **Two browsers. Two identities. One Mac.**
>
> Turn official Chrome Beta and Chrome Canary into two clear, independent
> launchers: `Google Chrome1` and `Google Chrome2`.

## Why this project?

Do you need to keep work and personal sessions apart? Test an extension without
touching your daily browser? Use a proxy in one browser while keeping the other
direct? Or simply run two genuinely separate Chromes instead of two profiles in
the same app?

This project creates two independent launchers from the official side-by-side
Chrome Beta and Chrome Canary builds.

| Launcher | Official build | Separate data |
| --- | --- | --- |
| Google Chrome1 | Chrome Beta | Logins, cookies, history, extensions, and proxy settings |
| Google Chrome2 | Chrome Canary | Logins, cookies, history, extensions, and network settings |

Each launcher uses its own official Bundle ID and its own user-data directory.
Both can run alongside Stable Chrome without modifying the official app bundle,
its code signature, or the Stable installation.

## What you get

- **Two real app identities** — official side-by-side Bundle IDs
- **Clean separation** — independent cookies, history, extensions, and sessions
- **Per-launcher networking** — assign a proxy to Google Chrome1 only, if needed
- **Safe updates** — official Beta/Canary bundles remain unmodified
- **Simple output** — generate `Google Chrome1.app` and `Google Chrome2.app` on the Desktop

## Customization interface

The launcher is a stable base for experiments. Customize each browser without
editing the generator or touching the official Chrome bundle:

- `EXTRA_ARGS_1_FILE` / `EXTRA_ARGS_2_FILE`: one Chrome argument per line
- `BEFORE_LAUNCH_1` / `BEFORE_LAUNCH_2`: an executable hook run before Chrome
- `PROFILE_1` / `PROFILE_2`: separate data roots for different experiments
- `PROXY_1` / `PROXY_2`: per-browser proxy configuration

An args file can look like this:

```text
# One complete argument per line
--enable-features=SomeFeature
--load-extension=/path/to/local/extension
```

A launch hook receives the profile directory as `$1` and the Chrome executable
path as `$2`. Put personal args and hooks under `local/`; that directory is
ignored by Git so local experiments stay local.

## Quick start

### Requirements

- macOS on a supported architecture
- Official Google Chrome Beta and Canary installed
- `zsh`, `PlistBuddy`, `codesign`, and `plutil`

Copy the example configuration and edit the app paths if needed:

```sh
cp config.example.env .env
${EDITOR:-vi} .env
```

Create the launchers:

```sh
./scripts/create-launchers.sh
```

Validate the official builds and generated launchers:

```sh
./scripts/validate-install.sh
```

Existing launcher apps are never overwritten automatically. Set `FORCE=1` only
after confirming the destination paths.

## How it works

The generator checks the official Bundle ID and code signature, then creates a
small local `.app` wrapper. The wrapper calls the executable inside the official
Beta or Canary bundle with a dedicated `--user-data-dir` and optional proxy.

The official Chrome bundles are never committed to this repository. Neither are
profiles, cookies, screenshots, DMGs, logs, or keychain data.

## Keychain behavior

Chrome may ask for access to macOS Keychain the first time a signed app uses its
Safe Storage item. Confirm the app identity before choosing an access option.
Do not grant the item to every application.

## License

MIT. See [LICENSE](LICENSE).
