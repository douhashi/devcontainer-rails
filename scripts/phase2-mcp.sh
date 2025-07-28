#!/bin/bash
set -e

# ベースディレクトリを取得
BASE_DIR="$(dirname "$0")/.."

# 関数を読み込む
source "${BASE_DIR}/functions/print_message.sh"

# フェーズ2: MCPサーバのセットアップ
print_section "フェーズ 2: MCPサーバのセットアップ"

# MCPディレクトリのパス
MCPS_DIR="${BASE_DIR}/mcps"

# MCPサーバのインストール
print_subsection "MCPサーバをインストール中..."

failed_scripts=()

for mcp_script in "$MCPS_DIR"/*.sh; do
    if [[ -f "$mcp_script" ]]; then
        print_processing "$(basename "$mcp_script")を処理中..."
        
        # スクリプトを実行可能にする
        chmod +x "$mcp_script"
        
        # スクリプトを実行してMCPをインストール
        if "$mcp_script" >&2; then
            echo -e "${GREEN}    ✓ 完了${NC}"
        else
            print_warning "$(basename "$mcp_script")の実行に失敗しました"
            failed_scripts+=("$(basename "$mcp_script")")
        fi
    fi
done

# 失敗したスクリプトがある場合は警告を表示（エラーで停止せず、後続処理を継続）
if [[ ${#failed_scripts[@]} -gt 0 ]]; then
    print_warning "以下のMCPサーバのインストールに失敗しました: ${failed_scripts[*]}"
    print_warning "MCPサーバは利用できない可能性がありますが、セットアップを続行します"
fi

print_success "MCPサーバのインストールが完了しました"

# .mcp.jsonファイルを生成
print_subsection ".mcp.jsonファイルを生成中..."
GENERATE_SCRIPT="${BASE_DIR}/scripts/generate-mcp-json.sh"
if [[ -f "$GENERATE_SCRIPT" ]]; then
    chmod +x "$GENERATE_SCRIPT"
    if "$GENERATE_SCRIPT" >&2; then
        print_success ".mcp.jsonファイルの生成が完了しました"
    else
        print_warning ".mcp.jsonファイルの生成に失敗しました"
    fi
else
    print_warning "generate-mcp-json.shスクリプトが見つかりません"
fi
