# frozen_string_literal: true

require "rails_helper"

RSpec.describe "音楽生成リクエストセクション", type: :system do
  let(:content) { create(:content, duration_min: 30) }

  before do
    # ステータスごとの音楽生成リクエストを作成
    create_list(:music_generation, 2, content: content, status: :pending)
    create_list(:music_generation, 1, content: content, status: :processing)
    create_list(:music_generation, 3, content: content, status: :completed)
    create(:music_generation, content: content, status: :failed)
  end

  describe "ボタン配置の確認" do
    before do
      visit content_path(content)
    end

    it "音楽生成リクエストセクションが表示されること" do
      expect(page).to have_css(".music-generations-section")
      expect(page).to have_text("音楽生成リクエスト")
    end

    it "生成ボタンが右側に配置されていること" do
      within ".music-generations-section" do
        expect(page).to have_css(".generation-controls.flex.justify-end")
        expect(page).to have_button("1件生成")
        expect(page).to have_button("一括生成")
      end
    end

    it "ステータスサマリーが左側、ボタンが右側に配置されていること" do
      within ".music-generations-section" do
        section = find(".content-section-body div.flex.justify-between")
        expect(section).to have_css(".music-generation-status-summary")
        expect(section).to have_css(".generation-controls")
      end
    end

    context "レスポンシブデザイン" do
      it "デスクトップサイズで横並びになること" do
        within ".music-generations-section" do
          expect(page).to have_css(".content-section-body div.flex.sm\\:flex-row")
        end
      end
    end
  end

  describe "ダークモード対応の色確認" do
    before do
      visit content_path(content)
    end

    it "待機中ステータスがダークモード用の色になっていること" do
      within ".music-generation-status-summary" do
        expect(page).to have_css(".text-gray-300.bg-gray-700", text: /待機中/)
      end
    end

    it "処理中ステータスがダークモード用の色になっていること" do
      within ".music-generation-status-summary" do
        expect(page).to have_css(".text-yellow-300.bg-yellow-900", text: /処理中/)
      end
    end

    it "完了ステータスがダークモード用の色になっていること" do
      within ".music-generation-status-summary" do
        expect(page).to have_css(".text-green-300.bg-green-900", text: /完了/)
      end
    end

    it "失敗ステータスがダークモード用の色になっていること" do
      within ".music-generation-status-summary" do
        expect(page).to have_css(".text-red-300.bg-red-900", text: /失敗/)
      end
    end
  end

  describe "他セクションとの統一性確認" do
    before do
      visit content_path(content)
    end

    it "作品概要セクションと同様の右側配置になっていること" do
      # 作品概要セクションのボタン配置確認
      within first(".bg-gray-800") do
        expect(page).to have_css("div.flex.justify-end.gap-4")
      end

      # 音楽生成リクエストセクションのボタン配置確認
      within ".music-generations-section" do
        expect(page).to have_css(".generation-controls.flex.justify-end")
      end
    end
  end
end
