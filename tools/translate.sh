#!/bin/bash
# translate.sh - 编译翻译文件

set -e

PLUGIN_DIR="plugins/developer-tools"
TRANSLATIONS_DIR="$PLUGIN_DIR/translations"

echo "Compiling translations..."

# 检查lrelease命令
if ! command -v lrelease &> /dev/null; then
    echo "Error: lrelease command not found. Install Qt Linguist tools."
    exit 1
fi

# 编译所有.ts文件
for ts_file in "$TRANSLATIONS_DIR"/*.ts; do
    if [ -f "$ts_file" ]; then
        qm_file="${ts_file%.ts}.qm"
        echo "Compiling $(basename "$ts_file")..."
        lrelease "$ts_file" -qm "$qm_file"

        if [ $? -eq 0 ]; then
            echo "  -> $(basename "$qm_file")"
        else
            echo "  Error compiling $(basename "$ts_file")"
            exit 1
        fi
    fi
done

echo "Translation compilation complete."