#!/bin/bash
# deploy.sh - 部署插件到Noctalia

set -e

PLUGIN_DIR="plugins/developer-tools"
NOCTALIA_PLUGINS="$HOME/.local/share/noctalia/plugins"

echo "Deploying Developer Tools plugin..."

# 验证必需文件
echo "Verifying required files..."
REQUIRED_FILES=(
    "$PLUGIN_DIR/manifest.json"
    "$PLUGIN_DIR/qml/main.qml"
    "$PLUGIN_DIR/qml/ToolButton.qml"
    "$PLUGIN_DIR/qml/components/Sidebar.qml"
    "$PLUGIN_DIR/qml/tools/TimestampTool.qml"
    "$PLUGIN_DIR/qml/tools/JsonFormatter.qml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: Missing required file: $file"
        exit 1
    fi
done

echo "All required files present."

# 检查目标目录
if [ ! -d "$NOCTALIA_PLUGINS" ]; then
    echo "Creating Noctalia plugins directory..."
    mkdir -p "$NOCTALIA_PLUGINS"
fi

# 部署插件
cp -r "$PLUGIN_DIR" "$NOCTALIA_PLUGINS/"

echo "Deployment complete. Restart Noctalia to load the plugin."
echo "Plugin installed at: $NOCTALIA_PLUGINS/developer-tools"