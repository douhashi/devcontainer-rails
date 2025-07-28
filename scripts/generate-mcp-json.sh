#!/bin/bash
set -e

# ベースディレクトリを取得
BASE_DIR="$(dirname "$0")/.."

# MCP設定を読み込む
source "${BASE_DIR}/functions/mcp_config.sh"

# .mcp.jsonファイルのパス
MCP_JSON_PATH="/workspaces/tone/.mcp.json"

# .mcp.jsonファイルを生成
cat > "${MCP_JSON_PATH}" <<EOF
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@upstash/context7-mcp"
      ],
      "env": {}
    },
    "markdownify-mcp": {
      "command": "node",
      "args": [
        "${MARKDOWNIFY_MCP_EXEC}"
      ],
      "disabled": false,
      "autoApprove": [
        "webpage-to-markdown",
        "pdf-to-markdown"
      ],
      "env": {
        "UV_PATH": "${UV_PATH}"
      }
    }
  }
}
EOF

echo ".mcp.json file generated at ${MCP_JSON_PATH}"