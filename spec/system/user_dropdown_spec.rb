# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Dropdown", type: :system, js: true do
  include_context "ログイン済み"

  describe "ドロップダウンメニューの基本動作" do
    it "ユーザー情報クリックでメニューが開閉する" do
      # 初期状態でメニューが非表示
      expect(page).to have_css("[data-user-dropdown-target='menu']", visible: false)

      # ユーザー情報をクリック
      find("[data-action='click->user-dropdown#toggle']").click

      # メニューが表示される
      expect(page).to have_css("[data-user-dropdown-target='menu']", visible: true)

      # フルメールアドレスとログアウトボタンが表示される
      within("[data-user-dropdown-target='menu']") do
        expect(page).to have_text(user.email)
        expect(page).to have_link("ログアウト")
      end
    end

    it "ユーザー情報をもう一度クリックするとメニューが閉じる" do
      # メニューを開く
      find("[data-action='click->user-dropdown#toggle']").click
      expect(page).to have_css("[data-user-dropdown-target='menu']", visible: true)

      # 再度クリックして閉じる
      find("[data-action='click->user-dropdown#toggle']").click
      expect(page).to have_css("[data-user-dropdown-target='menu']", visible: false)
    end
  end

  describe "外部クリックでの自動閉じ" do
    it "メニュー外をクリックするとメニューが閉じる" do
      # メニューを開く
      find("[data-action='click->user-dropdown#toggle']").click
      expect(page).to have_css("[data-user-dropdown-target='menu']", visible: true)

      # ページの他の部分をクリック（最初のh1要素を選択）
      page.all("h1").first.click

      # メニューが閉じる
      expect(page).to have_css("[data-user-dropdown-target='menu']", visible: false)
    end
  end

  describe "ESCキーでの閉じ操作" do
    it "ESCキーでメニューが閉じる" do
      # メニューを開く
      find("[data-action='click->user-dropdown#toggle']").click
      expect(page).to have_css("[data-user-dropdown-target='menu']", visible: true)

      # ESCキーを押す
      page.driver.browser.action.send_keys(:escape).perform

      # メニューが閉じる
      expect(page).to have_css("[data-user-dropdown-target='menu']", visible: false)
    end
  end

  describe "ログアウト機能" do
    it "ログアウトボタンをクリックするとログアウトできる" do
      # メニューを開く
      find("[data-action='click->user-dropdown#toggle']").click

      # ログアウトボタンをクリック
      within("[data-user-dropdown-target='menu']") do
        click_link("ログアウト")
      end

      # ログイン画面にリダイレクトされる
      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_text("ログイン")
    end
  end

  describe "ユーザー表示情報" do
    it "ヘッダーにユーザーメールアドレスが表示される" do
      expect(page).to have_css("[data-testid='user-email-display']")
      expect(page).to have_text(user.email)
    end

    it "アバターアイコンに正しい頭文字が表示される" do
      within("[data-testid='user-dropdown']") do
        initial = user.email[0].upcase
        expect(page).to have_text(initial)
      end
    end
  end


  describe "アクセシビリティ属性" do
    it "適切なARIA属性が設定されている" do
      dropdown_button = find("[data-action='click->user-dropdown#toggle']")

      # 初期状態の属性確認
      expect(dropdown_button["aria-haspopup"]).to eq("true")
      expect(dropdown_button["aria-expanded"]).to eq("false")
      expect(dropdown_button["role"]).to eq("button")

      # メニューの属性確認
      menu = find("[data-user-dropdown-target='menu']", visible: false)
      expect(menu["role"]).to eq("menu")
    end
  end

  describe "レスポンシブ表示" do
    it "モバイルサイズでも適切に表示される" do
      # ビューポートをモバイルサイズに変更
      page.driver.browser.manage.window.resize_to(375, 667)

      # ドロップダウンが表示される
      expect(page).to have_css("[data-testid='user-dropdown']")

      # メニューを開いて動作確認
      find("[data-action='click->user-dropdown#toggle']").click
      expect(page).to have_css("[data-user-dropdown-target='menu']", visible: true)
    end
  end
end
