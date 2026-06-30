# Maintainer: iCleyvin <50295633+iCleyvin@users.noreply.github.com>
pkgname=omarchy-about
pkgver=1.0.0
pkgrel=1
pkgdesc="A Windows-style 'About this PC' panel for Omarchy that auto-themes to the active theme"
arch=('x86_64')
url="https://github.com/iCleyvin/omarchy-about"
license=('MIT')
depends=('qt6-declarative' 'bash' 'pciutils')
makedepends=('gcc' 'pkgconf')
optdepends=('nvidia-utils: discrete GPU name and VRAM via nvidia-smi'
            'hyprland: live display resolution'
            'dmidecode: richer machine model info')
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
  cd "$srcdir/$pkgname-$pkgver"
  # Native launcher: sets the stable Wayland app_id (com.omarchy.about).
  g++ -std=c++17 -fPIC native/main.cpp -o omarchy-about-bin \
    $(pkg-config --cflags --libs Qt6Gui Qt6Qml)
}

package() {
  cd "$srcdir/$pkgname-$pkgver"
  install -Dm755 bin/omarchy-about                "$pkgdir/usr/bin/omarchy-about"
  install -Dm755 omarchy-about-bin                "$pkgdir/usr/lib/omarchy-about/omarchy-about-bin"
  install -Dm644 share/omarchy-about/main.qml     "$pkgdir/usr/share/omarchy-about/main.qml"
  install -Dm644 share/omarchy-about/SpecRow.qml  "$pkgdir/usr/share/omarchy-about/SpecRow.qml"
  install -Dm644 omarchy-about.desktop            "$pkgdir/usr/share/applications/omarchy-about.desktop"
  install -Dm644 share/icons/omarchy-about.svg    "$pkgdir/usr/share/icons/hicolor/scalable/apps/omarchy-about.svg"
  install -Dm644 LICENSE                          "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
