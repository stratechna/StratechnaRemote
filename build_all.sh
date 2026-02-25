#!/bin/bash
set -euo pipefail

APP_NAME="StratechnaRemote"
DIST="/opt/stratechna-build/dist"
DOWNLOADS="/srv/rustdesk-pro/downloads"

mkdir -p "$DIST/linux" "$DIST/windows"

echo "[1/6] Clean"
cargo clean

echo "[2/6] Build Linux x64"
cargo build --release
cp target/release/rustdesk "$DIST/linux/$APP_NAME"

echo "[3/6] Build Windows x64"
export CC_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc
export CXX_x86_64_pc_windows_gnu=x86_64-w64-mingw32-g++
cargo build --release --target x86_64-pc-windows-gnu
cp target/x86_64-pc-windows-gnu/release/rustdesk.exe "$DIST/windows/$APP_NAME.exe"

echo "[4/6] Package Linux"
cd "$DIST/linux"
tar -czf ${APP_NAME}-Linux-x64.tar.gz $APP_NAME

echo "[5/6] Package Windows"
cd "$DIST/windows"
zip ${APP_NAME}-Windows-x64.zip ${APP_NAME}.exe

echo "[6/6] Checksums"
cd "$DIST"
sha256sum linux/*.tar.gz windows/*.zip > SHA256SUMS.txt

echo
echo "=== COPYING TO DOWNLOADS ==="
cp -f linux/*.tar.gz "$DOWNLOADS/"
cp -f windows/*.zip "$DOWNLOADS/"
cp -f SHA256SUMS.txt "$DOWNLOADS/"

echo "[OK] Done."
