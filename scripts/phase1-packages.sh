#!/bin/bash
set -e

# ベースディレクトリを取得
BASE_DIR="$(dirname "$0")/.."

# 関数を読み込む
source "${BASE_DIR}/functions/print_message.sh"
source "${BASE_DIR}/functions/install_apt.sh"
source "${BASE_DIR}/functions/install_npm.sh"

# フェーズ1: 開発環境パッケージのインストール
print_section "フェーズ 1: 開発環境パッケージのインストール"

# aptパッケージのインストール
print_subsection "システムパッケージのインストール"
install_apt_packages \
    "git-lfs:Git Large File Storage"

# npmグローバルパッケージのインストール
print_subsection "npmグローバルパッケージのインストール"

# 必要なnpmパッケージをインストール
install_npm_globals \
    "@anthropic-ai/claude-code:Claude Code" \
    "ccmanager:Claude Code Manager"

# osobaのインストール
print_subsection "osobaのインストール"
curl -L https://github.com/douhashi/osoba/releases/latest/download/osoba_$(uname -s | tr '[:upper:]' '[:lower:]')_$(uname -m | sed 's/x86_64/x86_64/; s/aarch64/arm64/').tar.gz | tar xz -C /tmp && sudo mv /tmp/osoba /usr/local/bin/

# 将来的に追加されるパッケージの例:
# install_npm_globals \
#     "typescript:TypeScript" \
#     "prettier:コードフォーマッタ" \
#     "@rails/webpacker:Webpack統合"

print_success "開発環境パッケージのインストールが完了しました"
