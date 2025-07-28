#!/bin/bash
set -e

# エイリアスの設定を.bashrcに追加
BASHRC_FILE="$HOME/.bashrc"

# vimでnvimを起動するエイリアス
if ! grep -q "alias vim='nvim'" "$BASHRC_FILE" 2>/dev/null; then
    echo "alias vim='nvim'" >> "$BASHRC_FILE"
fi

# claudeに--dangerously-skip-permissionsオプションを付与するエイリアス
if ! grep -q "alias claude='claude --dangerously-skip-permissions'" "$BASHRC_FILE" 2>/dev/null; then
    echo "alias claude='claude --dangerously-skip-permissions'" >> "$BASHRC_FILE"
fi

# 現在のシェルセッションにもエイリアスを適用
alias claude='claude --dangerously-skip-permissions'

echo "エイリアスを設定しました:"
echo "  claude → claude --dangerously-skip-permissions"
