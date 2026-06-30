#!/usr/bin/env bash
# Removes a per-user install of omarchy-about (mirror of install.sh).
set -euo pipefail
PREFIX="${PREFIX:-$HOME/.local}"

rm -f "$PREFIX/bin/omarchy-about"
rm -rf "$PREFIX/share/omarchy-about"
rm -f "$PREFIX/share/icons/hicolor/scalable/apps/omarchy-about.svg"
rm -f "$PREFIX/share/applications/omarchy-about.desktop"

update-desktop-database "$PREFIX/share/applications" >/dev/null 2>&1 || true
echo "✓ Removed omarchy-about from $PREFIX"
