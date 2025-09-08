require 'rails_helper'

RSpec.describe "Tracks", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:content1) { create(:content, theme: "レコード、古いスピーカー") }
  let!(:content2) { create(:content, :cafe_theme) }

  describe "Track listing navigation" do
    let!(:track1) { create(:track, :completed, content: content1) }
    let!(:track2) { create(:track, :processing, content: content2) }

    it "can access tracks listing from direct URL" do
      visit tracks_path

      expect(page).to have_text("Track一覧")
      expect(page).to have_current_path(tracks_path)
    end

    it "displays track information with content links" do
      visit tracks_path

      expect(page).to have_text("Track一覧")
      expect(page).to have_text(content1.theme)
      expect(page).to have_text(content2.theme)

      # ContentへのリンクがあることをChク
      expect(page).to have_link(content1.theme.truncate(40), href: content_path(content1))
      expect(page).to have_link(content2.theme.truncate(40), href: content_path(content2))
    end

    it "shows appropriate track status indicators" do
      visit tracks_path

      expect(page).to have_text("完了")
      expect(page).to have_text("生成中")  # TrackStatus::Componentでは"生成中"と表示される
    end

    it "allows navigation to content detail from track listing" do
      visit tracks_path

      # Trackの行からContentリンクをクリック
      click_link content1.theme.truncate(40)

      expect(page).to have_current_path(content_path(content1))
      expect(page).to have_text(content1.theme)
    end
  end

  describe "Empty state handling" do
    it "displays appropriate message when no tracks exist" do
      visit tracks_path

      expect(page).to have_text("Trackがまだありません")
      expect(page).to have_text("まずはContentを作成してTrackを生成してください")
      expect(page).to have_link("コンテンツ一覧へ", href: contents_path)
    end

    it "allows navigation to contents from empty state" do
      visit tracks_path

      click_link "コンテンツ一覧へ"

      expect(page).to have_current_path(contents_path)
    end
  end

  describe "Pagination functionality", js: true do
    let!(:pagination_content) { create(:content, theme: "Pagination Test Content") }

    before do
      # 31個のtrackを作成してページネーションをテスト
      31.times do |i|
        create(:track, content: pagination_content, created_at: i.minutes.ago)
      end
    end

    it "displays pagination controls for large datasets" do
      visit tracks_path

      # 30個のTrackが表示されることを確認
      expect(page.all('[id^="track_"]').count).to eq(30)

      # ページネーションコントロールがあることを確認
      expect(page).to have_css('nav[role="navigation"]')
      expect(page).to have_link("Next")
    end

    it "allows navigation to next page" do
      visit tracks_path

      # 2ページ目に移動
      click_link "Next"

      expect(page).to have_current_path(tracks_path(page: 2))
      # 2ページ目には残りの1個のTrackが表示される
      expect(page.all('[id^="track_"]').count).to eq(1)
    end
  end

  describe "Responsive design", js: true do
    let!(:track) { create(:track, :completed, content: content1) }

    it "adapts layout for mobile devices" do
      visit tracks_path

      # デスクトップサイズ
      page.driver.browser.manage.window.resize_to(1200, 800)
      expect(page).to have_text("Track一覧")

      # モバイルサイズ
      page.driver.browser.manage.window.resize_to(375, 667)
      expect(page).to have_text("Track一覧")
      expect(page).to have_text(content1.theme.truncate(40))
    end
  end
end
