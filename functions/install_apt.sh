#!/bin/bash

# メッセージ出力関数を読み込む
# このスクリプトの実際のパスを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/print_message.sh"

# aptパッケージをインストールする関数
# 使用例: install_apt_package "jq" "JSONプロセッサ"
install_apt_package() {
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
    if dpkg -l | grep -q "^ii  $package_name "; then
        print_success "${description}は既にインストールされています"
        return 0
    fi
    
    # パッケージをインストール
    if sudo apt-get install -y "$package_name" > /dev/null 2>&1; then
        print_success "${description}のインストールが完了しました"
        return 0
    else
        print_error "${description}のインストールに失敗しました"
        return 1
    fi
}

# 複数のaptパッケージを一括インストールする関数
# 使用例: install_apt_packages ("jq:JSONプロセッサ" "curl:HTTPクライアント")
install_apt_packages() {
    local packages=("$@")
    local failed_packages=()
    
    # apt updateを実行
    print_processing "パッケージリストを更新中..."
    if ! sudo apt-get update > /dev/null 2>&1; then
        print_warning "パッケージリストの更新に失敗しました"
    fi
    
    # 各パッケージをインストール
    for package_info in "${packages[@]}"; do
        # パッケージ名と説明を分離
        local package_name="${package_info%%:*}"
        local description="${package_info#*:}"
        
        # 説明が指定されていない場合はパッケージ名を使用
        if [[ "$package_name" == "$description" ]]; then
            description="$package_name"
        fi
        
        if ! install_apt_package "$package_name" "$description"; then
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