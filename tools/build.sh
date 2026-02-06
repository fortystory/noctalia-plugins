#!/bin/bash
# build.sh - 构建开发者工具插件

set -e

PLUGIN_DIR="plugins/developer-tools"
BUILD_DIR="build"

echo "Building Developer Tools plugin..."

# 清理旧构建
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 复制文件
cp -r "$PLUGIN_DIR" "$BUILD_DIR/"

# 检查必需文件
if [ ! -f "$PLUGIN_DIR/manifest.json" ]; then
    echo "Error: manifest.json not found"
    exit 1
fi

if [ ! -f "$PLUGIN_DIR/qml/main.qml" ]; then
    echo "Warning: main.qml not found yet (first build)"
fi

echo "Build complete. Plugin in: $BUILD_DIR/developer-tools"

# 编译翻译文件
if [ -f "tools/translate.sh" ]; then
    echo "Compiling translations..."
    ./tools/translate.sh || echo "Warning: Translation compilation failed"
fi

echo "Build complete. Plugin in: $BUILD_DIR/developer-tools"