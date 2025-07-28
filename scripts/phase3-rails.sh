#!/bin/bash
set -e

# ベースディレクトリを取得
BASE_DIR="$(dirname "$0")/.."

# 関数を読み込む
source "${BASE_DIR}/functions/print_message.sh"

# フェーズ3: Railsアプリケーションのセットアップ
print_section "フェーズ 3: Railsアプリケーションのセットアップ"

# ワークスペースのルートディレクトリに移動
# BASE_DIR は .devcontainer なので、1つ上がプロジェクトルート
PROJECT_ROOT="$(cd "${BASE_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"
print_processing "作業ディレクトリ: ${PROJECT_ROOT}"

# if .envrc exists, source it
if [[ -f ".envrc" ]]; then
    print_processing "環境変数を読み込み中..."
    source .envrc
fi

# Railsの初期設定を実行
print_subsection "Railsの初期設定を実行中..."


if [[ -f "bin/setup" ]]; then
    # bin/setupが存在する場合は実行
    if bin/setup --skip-server; then
        print_success "Railsのセットアップが完了しました"
    else
        print_error "Railsのセットアップでエラーが発生しました"
        exit 1
    fi
else
    print_warning "bin/setupが見つかりません"
    
    # 代替のセットアップ手順
    print_subsection "代替セットアップを実行中..."
    
    # bundleのインストール
    if [[ -f "Gemfile" ]]; then
        print_processing "Gemのインストール中..."
        bundle install
    fi
    
    # データベースのセットアップ
    if [[ -f "config/database.yml" ]]; then
        print_processing "データベースのセットアップ中..."
        bin/rails db:create
        bin/rails db:migrate
    fi
    
    print_success "代替セットアップが完了しました"
fi

print_success "Railsアプリケーションのセットアップが完了しました"
