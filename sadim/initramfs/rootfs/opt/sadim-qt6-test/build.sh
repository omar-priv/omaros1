#!/bin/sh
# Sadim OS — بناء وتشغيل تطبيق Qt6 التجريبي (على الهدف)
# يتطلب: qt6base مع development headers (مُضمن في Buildroot عند تفعيل الحزم)

set -e

SRC_DIR="/opt/sadim-qt6-test"
BUILD_DIR="/tmp/qt6-test-build"
BIN="/tmp/sadim-qt6-test"

echo "[qt6-test] Building Qt6 test application…"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# qmake project file
cat > sadim-qt6-test.pro <<'EOF'
TEMPLATE = app
TARGET = sadim-qt6-test
QT += core gui widgets
CONFIG += c++17
SOURCES += /opt/sadim-qt6-test/main.cpp
EOF

# بناء
qmake sadim-qt6-test.pro
make -j$(nproc)

if [ -f "$BIN" ]; then
    echo "[qt6-test] Build successful: $BIN"
    echo "[qt6-test] Run with: QT_QPA_PLATFORM=linuxfb $BIN"
else
    echo "[qt6-test] FAIL: binary not found"
    exit 1
fi