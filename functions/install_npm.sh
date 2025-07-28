#!/bin/bash

# メッセージ出力関数を読み込む
# このスクリプトの実際のパスを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/print_message.sh"

# npmグローバルパッケージをインストールする関数
# 使用例: install_npm_global "ccmanager" "Claude Code Manager"
install_npm_global() {
    local package_name="$1"
    local description="$2"
    
    if [[ -z "$package_name" ]]; then
        print_error "パッケージ名が指定されていません"
        return 1
    fi
    
    # デフォルトの説明を設定
    if [[ -z "$description" ]]; then
        description="$package_name"
    fi
    
    print_processing "${description}をインストール中..."
    
    # パッケージが既にインストールされているかチェック
    if npm list -g "$package_name" > /dev/null 2>&1; then
        print_success "${description}は既にインストールされています"
        return 0
    fi
    
    # パッケージをインストール
    if npm install -g "$package_name" > /dev/null 2>&1; then
        print_success "${description}のインストールが完了しました"
        return 0
    else
        print_error "${description}のインストールに失敗しました"
        return 1
    fi
}

# 複数のnpmグローバルパッケージを一括インストールする関数
# 使用例: install_npm_globals ("ccmanager:Claude Code Manager" "typescript:TypeScript")
install_npm_globals() {
    local packages=("$@")
    local failed_packages=()
    
    # 各パッケージをインストール
    for package_info in "${packages[@]}"; do
        # パッケージ名と説明を分離
        local package_name="${package_info%%:*}"
        local description="${package_info#*:}"
        
        # 説明が指定されていない場合はパッケージ名を使用
        if [[ "$package_name" == "$description" ]]; then
            description="$package_name"
        fi
        
        if ! install_npm_global "$package_name" "$description"; then
            failed_packages+=("$package_name")
        fi
    done
    
    # 結果を報告
    if [[ ${#failed_packages[@]} -eq 0 ]]; then
        return 0
    else
        print_error "以下のパッケージのインストールに失敗しました: ${failed_packages[*]}"
        return 1
    fi
}