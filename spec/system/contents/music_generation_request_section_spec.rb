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

    it "生成ボタンがactionsエリアに配置されていること" do
      within ".music-generations-section" do
        expect(page).to have_css(".content-section-actions")
        within ".content-section-actions" do
          expect(page).to have_button("1件生成")
          expect(page).to have_button("一括生成")
        end
      end
    end

    it "待機中・処理中の情報がヘッダーバッジエリアに表示されること" do
      within ".music-generations-section" do
        within ".content-section-header" do
          expect(page).to have_text("待機中: 2件")
          expect(page).to have_text("処理中: 1件")
        end
      end
    end

    context "DOM構造の統一性" do
      it "ContentSectionコンポーネントの標準構造に従っていること" do
        within ".music-generations-section" do
          expect(page).to have_css(".content-section-header")
          expect(page).to have_css(".content-section-body")
          expect(page).to have_css(".content-section-actions")
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

    it "作品概要セクションと同様のDOM構造になっていること" do
      # 作品概要セクションのボタン配置確認
      within first(".bg-gray-800") do
        expect(page).to have_css(".content-section-actions.flex.justify-end.gap-4")
      end

      # 音楽生成リクエストセクションのボタン配置確認
      within ".music-generations-section" do
        expect(page).to have_css(".content-section-actions")
      end
    end
  end
end
