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

# Build the tiny native launcher that gives the window a stable Wayland app_id
# (com.omarchy.about). Optional: if a C++ compiler or the Qt6 build files are
# missing we skip it, and bin/omarchy-about falls back to the qml6 runtime
# (the card is identical; only the window class differs).
if command -v g++ >/dev/null 2>&1 && command -v pkg-config >/dev/null 2>&1 \
   && pkg-config --exists Qt6Gui Qt6Qml 2>/dev/null; then
  echo "• Building native launcher (com.omarchy.about)…"
  install -d "$PREFIX/lib/omarchy-about"
  if g++ -std=c++17 -fPIC native/main.cpp -o "$PREFIX/lib/omarchy-about/omarchy-about-bin" \
       $(pkg-config --cflags --libs Qt6Gui Qt6Qml); then
    chmod 755 "$PREFIX/lib/omarchy-about/omarchy-about-bin"
    echo "  ✓ native launcher installed"
  else
    rm -f "$PREFIX/lib/omarchy-about/omarchy-about-bin"
    echo "  ! native build failed — using the qml6 fallback (generic app_id)"
  fi
else
  echo "• Skipping native launcher (need g++, pkg-config, Qt6 dev) — using qml6 fallback"
fi

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
