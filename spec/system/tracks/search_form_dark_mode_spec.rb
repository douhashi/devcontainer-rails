require 'rails_helper'

RSpec.describe "Track検索フォームのダークモード対応", type: :system, playwright: true do
  let(:user) { create(:user) }

  before do
    # ユーザーログイン（Systemテスト用）
    login_as user, scope: :user
    # テスト用のTrackデータを作成
    content1 = create(:content, theme: "LoFi BGM 1")
    content2 = create(:content, theme: "LoFi BGM 2")
    content3 = create(:content, theme: "LoFi BGM 3")
    content4 = create(:content, theme: "LoFi BGM 4")

    create(:track, content: content1, status: "pending", metadata: { "music_title" => "Chill Vibes" })
    create(:track, content: content2, status: "processing", metadata: { "music_title" => "Study Music" })
    create(:track, content: content3, status: "completed", metadata: { "music_title" => "Relax Mix" })
    create(:track, content: content4, status: "failed", metadata: { "music_title" => "Night Jazz" })
  end

  describe "検索フォームのダークモードUI" do
    before do
      visit tracks_path
    end

    it "検索フォームコンテナがダークモード対応の背景色になっている" do
      form_container = find("div.bg-gray-800.rounded-lg.p-6.mb-6")
      expect(form_container).to be_present
    end

    it "入力フィールドがダークモード対応のスタイルになっている" do
      # Content名の入力フィールド
      content_field = find("#q_content_theme_cont")
      expect(content_field[:class]).to include("bg-gray-800")
      expect(content_field[:class]).to include("border-gray-700")
      expect(content_field[:class]).to include("text-gray-100")
      expect(content_field[:class]).to include("placeholder-gray-500")
      expect(content_field[:class]).to include("px-4")
      expect(content_field[:class]).to include("py-2")

      # 楽曲タイトルの入力フィールド
      title_field = find("#q_music_title_cont")
      expect(title_field[:class]).to include("bg-gray-800")
      expect(title_field[:class]).to include("border-gray-700")
      expect(title_field[:class]).to include("text-gray-100")
      expect(title_field[:class]).to include("px-4")
      expect(title_field[:class]).to include("py-2")
    end

    it "ラベルがダークモード対応のテキストカラーになっている" do
      labels = all("label.text-gray-300")
      expect(labels).not_to be_empty

      # フィールドラベルの確認
      expect(page).to have_css("label.text-gray-300", text: "Content名")
      expect(page).to have_css("label.text-gray-300", text: "楽曲タイトル")
      expect(page).to have_css("label.text-gray-300", text: "作成日時（開始）")
      expect(page).to have_css("label.text-gray-300", text: "作成日時（終了）")

      # ステータスフィールドのlegend
      expect(page).to have_css("legend.text-gray-300", text: "ステータス")
    end

    it "チェックボックスがダークモード対応のスタイルになっている" do
      checkboxes = all("input[type='checkbox']")
      checkboxes.each do |checkbox|
        expect(checkbox[:class]).to include("border-gray-600")
        expect(checkbox[:class]).to include("text-blue-500")
        expect(checkbox[:class]).to include("focus:border-blue-500")
        expect(checkbox[:class]).to include("focus:ring-blue-500")
      end

      # チェックボックスのラベル
      checkbox_labels = all("label.inline-flex span.text-gray-300")
      expect(checkbox_labels).not_to be_empty
    end

    it "フォーカス時のリングカラーが統一されている" do
      # テキストフィールドのフォーカス
      content_field = find("#q_content_theme_cont")
      expect(content_field[:class]).to include("focus:ring-blue-500")

      # 日付フィールドのフォーカス
      date_field = find("#q_created_at_gteq")
      expect(date_field[:class]).to include("focus:ring-blue-500")
    end

    it "検索ボタンがButton::Componentを使用している" do
      # 検索ボタンの確認
      search_button = find("button[type='submit']", text: "検索")
      expect(search_button[:class]).to include("bg-blue-600")
      expect(search_button[:class]).to include("hover:bg-blue-700")
      expect(search_button[:class]).to include("text-white")
      expect(search_button[:class]).to include("px-4")
      expect(search_button[:class]).to include("py-2")
    end

    it "クリアボタンがButton::Componentを使用している" do
      # クリアボタンの確認
      clear_link = find("a", text: "クリア")
      # Button::Componentの基本クラスが適用されているかチェック
      expect(clear_link[:class]).to include("inline-flex")
      expect(clear_link[:class]).to include("items-center")
      expect(clear_link[:class]).to include("justify-center")
      expect(clear_link[:class]).to include("font-medium")
      expect(clear_link[:class]).to include("rounded-lg")
      expect(clear_link[:class]).to include("px-4")
      expect(clear_link[:class]).to include("py-2")
    end

    context "検索を実行した場合" do
      before do
        fill_in "q_content_theme_cont", with: "LoFi"
        click_button "検索"
      end

      it "検索結果表示部分がダークモード対応になっている" do
        result_display = find("div.bg-blue-900\\/20")
        expect(result_display).to be_present
        expect(result_display[:class]).to include("border-blue-500")

        result_text = find("p.text-blue-300")
        expect(result_text).to have_text(/検索結果:/)
      end
    end
  end

  describe "検索機能の動作確認" do
    before do
      visit tracks_path
    end

    it "Content名で検索できる" do
      fill_in "q_content_theme_cont", with: "LoFi BGM 1"
      click_button "検索"

      expect(page).to have_content("LoFi BGM 1")
      expect(page).not_to have_content("LoFi BGM 2")
    end

    it "楽曲タイトルで検索できる" do
      fill_in "q_music_title_cont", with: "Chill"
      click_button "検索"

      expect(page).to have_content("Chill Vibes")
      expect(page).not_to have_content("Study Music")
    end

    it "ステータスでフィルタリングできる" do
      check "q_status_in_pending"
      check "q_status_in_completed"
      click_button "検索"

      expect(page).to have_content("LoFi BGM 1") # pending
      expect(page).to have_content("LoFi BGM 3") # completed
      expect(page).not_to have_content("LoFi BGM 2") # processing
    end

    it "クリアボタンで検索条件をリセットできる" do
      fill_in "q_content_theme_cont", with: "Test"
      check "q_status_in_pending"
      click_button "検索"

      # ページ読み込み完了を待つ
      expect(page).to have_content("検索結果")

      click_link "クリア"

      # ページリダイレクト後の確認、少し待機
      expect(page).to have_current_path(tracks_path)
      sleep 0.5  # フォーム初期化の待機

      expect(find("#q_content_theme_cont").value).to eq("")
      expect(find("#q_status_in_pending")).not_to be_checked
    end
  end

  describe "レスポンシブデザイン", js: true, playwright: true do
    it "モバイル表示で正しくレイアウトされる" do
      visit tracks_path
      page.current_window.resize_to(375, 667)

      form_container = find("div.grid")
      expect(form_container[:class]).to include("grid-cols-1")
    end

    it "タブレット表示で正しくレイアウトされる" do
      visit tracks_path
      page.current_window.resize_to(768, 1024)

      form_container = find("div.grid")
      expect(form_container[:class]).to include("md:grid-cols-2")
    end

    it "デスクトップ表示で正しくレイアウトされる" do
      visit tracks_path
      page.current_window.resize_to(1920, 1080)

      form_container = find("div.grid")
      expect(form_container[:class]).to include("lg:grid-cols-3")
    end
  end
end
