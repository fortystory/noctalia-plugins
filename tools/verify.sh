#!/bin/bash
# verify.sh - 验证插件完整性

set -e

PLUGIN_DIR="plugins/developer-tools"

echo "Verifying Developer Tools plugin..."

# 检查目录结构
echo "1. Checking directory structure..."
REQUIRED_DIRS=(
    "$PLUGIN_DIR"
    "$PLUGIN_DIR/qml"
    "$PLUGIN_DIR/qml/tools"
    "$PLUGIN_DIR/qml/components"
    "$PLUGIN_DIR/translations"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "  ✗ Missing directory: $dir"
        exit 1
    else
        echo "  ✓ Found: $dir"
    fi
done

# 检查必需文件
echo "2. Checking required files..."
REQUIRED_FILES=(
    "$PLUGIN_DIR/manifest.json"
    "$PLUGIN_DIR/icon.svg"
    "$PLUGIN_DIR/qml/main.qml"
    "$PLUGIN_DIR/qml/ToolButton.qml"
    "$PLUGIN_DIR/qml/components/Theme.qml"
    "$PLUGIN_DIR/qml/components/Sidebar.qml"
    "$PLUGIN_DIR/qml/components/TextEditor.qml"
    "$PLUGIN_DIR/qml/tools/ToolBase.qml"
    "$PLUGIN_DIR/qml/tools/TimestampTool.qml"
    "$PLUGIN_DIR/qml/tools/JsonFormatter.qml"
    "$PLUGIN_DIR/translations/en_US.ts"
    "$PLUGIN_DIR/translations/zh_CN.ts"
)

missing_files=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "  ✗ Missing file: $file"
        missing_files=$((missing_files + 1))
    else
        echo "  ✓ Found: $(basename "$file")"
    fi
done

if [ $missing_files -gt 0 ]; then
    echo "  ⚠  Missing $missing_files required file(s)"
fi

# 检查manifest.json语法
echo "3. Checking manifest.json..."
if python3 -m json.tool "$PLUGIN_DIR/manifest.json" > /dev/null 2>&1; then
    echo "  ✓ manifest.json syntax is valid"
else
    echo "  ✗ manifest.json has syntax errors"
    exit 1
fi

# 检查文件大小（粗略验证）
echo "4. Checking file sizes..."
MIN_SIZE=10  # 最小文件大小（字节）

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        if [ $size -lt $MIN_SIZE ]; then
            echo "  ⚠  File is very small: $file ($size bytes)"
        fi
    fi
done

echo ""
echo "Verification complete."
if [ $missing_files -eq 0 ]; then
    echo "✅ Plugin structure looks good!"
else
    echo "⚠️  Plugin has $missing_files missing file(s)"
fi