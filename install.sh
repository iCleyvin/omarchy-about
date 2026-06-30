#!/usr/bin/env bash
#
# Per-user installer for omarchy-about (no root needed).
# Installs into ~/.local by default; set PREFIX to change.
#
#   ./install.sh                 # -> ~/.local
#   PREFIX=/usr/local sudo ./install.sh
#
set -euo pipefail
cd "$(dirname "$0")"

PREFIX="${PREFIX:-$HOME/.local}"

install -Dm755 bin/omarchy-about               "$PREFIX/bin/omarchy-about"
install -Dm644 share/omarchy-about/main.qml    "$PREFIX/share/omarchy-about/main.qml"
install -Dm644 share/omarchy-about/SpecRow.qml "$PREFIX/share/omarchy-about/SpecRow.qml"
install -Dm644 share/icons/omarchy-about.svg   "$PREFIX/share/icons/hicolor/scalable/apps/omarchy-about.svg"
install -Dm644 omarchy-about.desktop           "$PREFIX/share/applications/omarchy-about.desktop"

update-desktop-database "$PREFIX/share/applications" >/dev/null 2>&1 || true
gtk-update-icon-cache -q "$PREFIX/share/icons/hicolor" >/dev/null 2>&1 || true

echo "✓ Installed omarchy-about to $PREFIX"
case ":$PATH:" in
  *":$PREFIX/bin:"*) : ;;
  *) echo "  Note: add $PREFIX/bin to your PATH to run 'omarchy-about' directly." ;;
esac
echo "  Launch it from your app launcher (search \"About This PC\") or run: omarchy-about"
