# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

`omarchy-about` is a Windows-style "About This PC" panel for [Omarchy](https://omarchy.org): a Qt6/QML card that paints itself with the user's active Omarchy theme and shows CPU/GPU/RAM/disk/display/model/kernel/uptime. No daemon, no config files.

## Architecture — the three pieces and the contract between them

Data flows in one direction through three components. Understanding the **JSON contract** is the key to the whole app:

1. **`bin/omarchy-about`** (bash launcher) — the only place that touches the system. It collects hardware (`lscpu`/`/proc/cpuinfo`, `lspci` + `nvidia-smi`, `df`, `/proc/meminfo`, DMI under `/sys/.../dmi/id`, `hyprctl monitors`) **plus** the active theme's colours from `~/.config/omarchy/current/theme/colors.toml` (falls back to `alacritty.toml`, then hard-coded tokyo-night). It writes everything to a temp JSON file (`mktemp`, removed by an EXIT trap) and launches the QML card, passing the JSON path as the last argument.

2. **`share/omarchy-about/main.qml`** (+ `SpecRow.qml`) — all presentation. The root `Window` reads the JSON via an `XMLHttpRequest` to `file://`, then renders. **It does no system calls** — if you need a new data point, add it in the launcher's JSON and read `d.<field>` here. UI strings and i18n live in the `dict` object near the top; language is chosen from the JSON `lang` field.

3. **`native/main.cpp`** (tiny C++ launcher) — exists **only** to give the window a stable Wayland `app_id` (`com.omarchy.about`) via `QGuiApplication::setDesktopFileName()`, then loads the same `main.qml`. The generic `qml6` runtime reports `org.qt-project.qml`, which every QML app shares, so it can't be focused reliably or targeted by Hyprland rules. The bash launcher **prefers this compiled binary and falls back to `qml6`** when it isn't built — the card is identical either way, only the window class differs.

The JSON is the contract: bash produces it, QML consumes it. They never call each other directly.

## Commands

```bash
# Build only the native launcher (REQUIRES -fPIC; Qt6 fails to link without it)
g++ -std=c++17 -fPIC native/main.cpp -o build/omarchy-about-bin \
    $(pkg-config --cflags --libs Qt6Gui Qt6Qml)

# Per-user install to ~/.local (compiles the native launcher if a toolchain is
# present, else skips it and relies on the qml6 fallback)
./install.sh

# Build/install the Arch package (validates the whole packaging path)
makepkg -si                 # or: makepkg -f   (build to .pkg.tar.zst, no install)

# Run from the working tree
./bin/omarchy-about

# Render the card to a PNG headless (used for README screenshots / verification)
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software ./bin/omarchy-about --shot=out.png
```

There is no test suite — verification is running the app (or the `--shot` headless render, which also confirms the QML parses).

## Critical gotchas (most are non-obvious and were hard-won)

- **Native build needs `-fPIC`.** Without it, linking against Qt6 fails with "copy relocation against non-copyable protected symbol".
- **A QML app's Wayland `app_id` cannot be set via CLI flags or from pure QML** — not by `-name`, `--desktop-file-name`, nor anything in the `.qml`. Verified empirically. The C++ wrapper (`setDesktopFileName`) is the only way; that's the entire reason `native/main.cpp` exists.
- **Local-file XHR in QML requires `QML_XHR_ALLOW_FILE_READ=1`** — the launcher sets it. Without it the card renders blank.
- **Argument passing differs by launcher:** with the native binary the QML path goes via `$OMARCHY_ABOUT_QML` and the data/`--shot` args are passed directly; with `qml6` they must come **after `--`** (`qml6 main.qml -- args`) or the runtime treats them as extra QML files. The QML arg parser is defensive: it picks the arg ending in `.json` and the one starting with `--shot=`, ignoring anything else.
- **QML layout traps already solved in `main.qml`:** `font.pixelSize` is an int; inside Layouts use `implicitWidth`/`implicitHeight` (not `width`/`height`); the window height is driven by the intermediate `winHeight` property to avoid a `minimumHeight↔height` binding loop. The card is intentionally **resizable + wrapped in a `Flickable`** so it tiles cleanly under Hyprland (small slots scroll instead of clipping); `width`/`height` are just the preferred/floating size.
- **The launcher forces `LC_ALL=C` for parsing** (so `lscpu`/`df`/`uptime` labels stay English) but detects the UI locale *before* that, so the interface still follows the user's language.

## Conventions & layout

- **C++ source lives in `native/`, not `src/`** — `src/`, `pkg/`, and `build/` are gitignored because `makepkg` uses `src`/`pkg` as its build dirs; a tracked `src/` would collide.
- **Installed layout:** launcher → `$PREFIX/bin/omarchy-about`, native binary → `$PREFIX/lib/omarchy-about/omarchy-about-bin`, QML → `$PREFIX/share/omarchy-about/`. The launcher locates both relative to itself (following symlinks) and falls back to `/usr`, `/usr/local`, `~/.local`.
- **`PKGBUILD` is `arch=('x86_64')`** (not `any`) because it now compiles a native binary; `build()` compiles it, `makedepends` are `gcc`/`pkgconf`.
- Code, comments, and UI strings are in **English**; the UI is bilingual (en/es) only through the `dict` in `main.qml`. Adding a language = a new block in `dict` + a case in the launcher's locale detection.
- Commit messages end with a `Co-Authored-By:` trailer (see git log).
- `NOTES.local.md` is a gitignored personal handoff file (`*.local.md` is ignored) — never published, don't rely on it being present.

## Distribution status

Published at `github.com/iCleyvin/omarchy-about`, tag/release `v1.0.0`. The `PKGBUILD` pulls the `v1.0.0` tarball and is validated with `makepkg`. AUR publishing is still pending (needs an AUR account).
