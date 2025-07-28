#!/bin/bash
set -e

# ベースディレクトリを取得
BASE_DIR="$(dirname "$0")"

# メッセージ出力関数を読み込む
source "${BASE_DIR}/functions/print_message.sh"

# ログファイルの設定
LOG_DIR="/tmp/devcontainer-setup"
LOG_FILE="${LOG_DIR}/setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "${LOG_DIR}"

# ログ出力を設定（標準出力と標準エラー出力をログファイルにも記録）
exec > >(tee -a "${LOG_FILE}")
exec 2>&1

print_section "Devcontainerセットアップ開始"
print_subsection "ログファイル: ${LOG_FILE}"

# 各フェーズのスクリプトを実行
SCRIPTS_DIR="${BASE_DIR}/scripts"

# フェーズ1: パッケージのインストール
if [[ -f "${SCRIPTS_DIR}/phase1-packages.sh" ]]; then
    chmod +x "${SCRIPTS_DIR}/phase1-packages.sh"
    "${SCRIPTS_DIR}/phase1-packages.sh"
else
    print_error "フェーズ1のスクリプトが見つかりません: ${SCRIPTS_DIR}/phase1-packages.sh"
    exit 1
fi

# フェーズ2: MCPサーバのセットアップ
if [[ -f "${SCRIPTS_DIR}/phase2-mcp.sh" ]]; then
    chmod +x "${SCRIPTS_DIR}/phase2-mcp.sh"
    "${SCRIPTS_DIR}/phase2-mcp.sh"
else
    print_error "フェーズ2のスクリプトが見つかりません: ${SCRIPTS_DIR}/phase2-mcp.sh"
    exit 1
fi

# フェーズ3: Railsアプリケーションのセットアップ
if [[ -f "${SCRIPTS_DIR}/phase3-rails.sh" ]]; then
    chmod +x "${SCRIPTS_DIR}/phase3-rails.sh"
    "${SCRIPTS_DIR}/phase3-rails.sh"
else
    print_error "フェーズ3のスクリプトが見つかりません: ${SCRIPTS_DIR}/phase3-rails.sh"
    exit 1
fi

# 完了メッセージ
print_completion "すべてのセットアップが正常に完了しました！"
print_subsection "ログファイルは以下の場所に保存されました: ${LOG_FILE}"

# ログの最後に概要を追加
echo "" >> "${LOG_FILE}"
echo "=== セットアップ概要 ===" >> "${LOG_FILE}"
echo "開始時刻: $(date -r "${LOG_FILE}" +"%Y-%m-%d %H:%M:%S")" >> "${LOG_FILE}"
echo "終了時刻: $(date +"%Y-%m-%d %H:%M:%S")" >> "${LOG_FILE}"
echo "ログファイル: ${LOG_FILE}" >> "${LOG_FILE}"
