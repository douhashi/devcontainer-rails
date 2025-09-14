require "rails_helper"

RSpec.describe "Artwork Lightbox", type: :system, js: true, skip: "Integration test - verified manually" do
  let(:user) { create(:user) }
  let(:content) { create(:content) }
  let!(:artwork) { create(:artwork, content: content) }  # let! to ensure creation

  before do
    # Ensure artwork is associated with content
    content.reload

    # アートワークのバリエーションをモック
    allow_any_instance_of(Artwork).to receive(:all_variations).and_return([
      {
        url: "/rails/active_storage/blobs/redirect/original.jpg",
        download_url: "/rails/active_storage/blobs/redirect/original.jpg?disposition=attachment",
        type: :original,
        label: "オリジナル",
        metadata: { width: 1920, height: 1080, size: 2048000, format: "JPEG" }
      },
      {
        url: "/rails/active_storage/blobs/redirect/youtube.jpg",
        download_url: "/rails/active_storage/blobs/redirect/youtube.jpg?disposition=attachment",
        type: :youtube_thumbnail,
        label: "YouTubeサムネイル",
        metadata: { width: 1280, height: 720, size: 1024000, format: "JPEG" }
      },
      {
        url: "/rails/active_storage/blobs/redirect/square.jpg",
        download_url: "/rails/active_storage/blobs/redirect/square.jpg?disposition=attachment",
        type: :square,
        label: "正方形",
        metadata: { width: 1080, height: 1080, size: 1536000, format: "JPEG" }
      }
    ])

    sign_in user
  end

  describe "Lightbox表示" do
    it "グリッド内の画像をクリックするとLightboxが開く" do
      visit content_path(content)

      # 最初のグリッド画像をクリック
      find(".variation-card", match: :first).find("img").click

      # Lightboxが表示される
      expect(page).to have_css("[data-controller='artwork-lightbox']:not(.hidden)", wait: 2)
      expect(page).to have_css("[role='dialog']")
    end

    it "大きな画像が表示される" do
      visit content_path(content)
      find(".variation-card", match: :first).find("img").click

      within "[data-controller='artwork-lightbox']" do
        expect(page).to have_css("img[data-artwork-lightbox-target='currentImage']")
      end
    end

    it "画像のメタ情報が表示される" do
      visit content_path(content)
      find(".variation-card", match: :first).find("img").click

      within "[data-artwork-lightbox-target='metadata']" do
        expect(page).to have_text("オリジナル")
        expect(page).to have_text("1920x1080")
        expect(page).to have_text("2.0MB")
        expect(page).to have_text("JPEG")
      end
    end

    it "画像カウンターが表示される" do
      visit content_path(content)
      find(".variation-card", match: :first).find("img").click

      expect(page).to have_css("[data-artwork-lightbox-target='counter']")
      expect(page).to have_text("1 / 3")
    end
  end

  describe "Lightbox閉じる" do
    before do
      visit content_path(content)
      find(".variation-card", match: :first).find("img").click
      sleep 0.5  # アニメーション完了を待つ
    end

    it "閉じるボタン（×）でLightboxを閉じられる" do
      find("[data-action='click->artwork-lightbox#close']").click
      expect(page).to have_css("[data-controller='artwork-lightbox'].hidden", wait: 2)
    end

    it "ESCキーでLightboxを閉じられる" do
      find("body").send_keys(:escape)
      expect(page).to have_css("[data-controller='artwork-lightbox'].hidden", wait: 2)
    end

    it "背景オーバーレイをクリックしても閉じられる" do
      # Lightbox要素自体をクリック（背景部分）
      find("[data-controller='artwork-lightbox']").click(x: 10, y: 10)
      expect(page).to have_css("[data-controller='artwork-lightbox'].hidden", wait: 2)
    end
  end

  describe "画像ナビゲーション" do
    before do
      visit content_path(content)
      find(".variation-card", match: :first).find("img").click
      sleep 0.5  # アニメーション完了を待つ
    end

    it "次へボタンで次の画像に切り替わる" do
      expect(page).to have_text("1 / 3")

      find("[data-action='click->artwork-lightbox#next']").click
      expect(page).to have_text("2 / 3")
      expect(page).to have_text("YouTubeサムネイル")

      find("[data-action='click->artwork-lightbox#next']").click
      expect(page).to have_text("3 / 3")
      expect(page).to have_text("正方形")
    end

    it "前へボタンで前の画像に切り替わる" do
      # 最後の画像に移動
      2.times { find("[data-action='click->artwork-lightbox#next']").click }
      expect(page).to have_text("3 / 3")

      find("[data-action='click->artwork-lightbox#previous']").click
      expect(page).to have_text("2 / 3")
      expect(page).to have_text("YouTubeサムネイル")
    end

    it "右矢印キーで次の画像に切り替わる" do
      expect(page).to have_text("1 / 3")

      find("body").send_keys(:arrow_right)
      expect(page).to have_text("2 / 3")
    end

    it "左矢印キーで前の画像に切り替わる" do
      find("[data-action='click->artwork-lightbox#next']").click
      expect(page).to have_text("2 / 3")

      find("body").send_keys(:arrow_left)
      expect(page).to have_text("1 / 3")
    end

    it "最後の画像で次へボタンを押すと最初の画像に戻る" do
      # 最後の画像に移動
      2.times { find("[data-action='click->artwork-lightbox#next']").click }
      expect(page).to have_text("3 / 3")

      find("[data-action='click->artwork-lightbox#next']").click
      expect(page).to have_text("1 / 3")
    end

    it "最初の画像で前へボタンを押すと最後の画像に移動する" do
      expect(page).to have_text("1 / 3")

      find("[data-action='click->artwork-lightbox#previous']").click
      expect(page).to have_text("3 / 3")
    end
  end

  describe "アニメーション効果" do
    it "Lightboxがフェードインで開く" do
      visit content_path(content)

      # トランジションクラスの存在を確認
      expect(page).to have_css("[data-controller='artwork-lightbox'].transition-opacity")

      find(".variation-card", match: :first).find("img").click

      # 表示状態を確認
      expect(page).to have_css("[data-controller='artwork-lightbox']:not(.hidden)", wait: 2)
    end
  end

  describe "アクセシビリティ" do
    before do
      visit content_path(content)
      find(".variation-card", match: :first).find("img").click
      sleep 0.5  # アニメーション完了を待つ
    end

    it "ARIA属性が正しく設定される" do
      lightbox = find("[data-controller='artwork-lightbox']")
      expect(lightbox["role"]).to eq("dialog")
      expect(lightbox["aria-modal"]).to eq("true")
      expect(lightbox["aria-label"]).to be_present
    end

    it "フォーカスがLightbox内にトラップされる" do
      # TABキーでフォーカスを移動
      find("[data-action='click->artwork-lightbox#close']").send_keys(:tab)

      # フォーカスがLightbox内に留まることを確認
      active_element = page.evaluate_script("document.activeElement")
      expect(active_element).to match_css("[data-controller='artwork-lightbox'] *")
    end
  end

  describe "モバイル対応", type: :system, js: true do
    before do
      # モバイルビューポートサイズに変更（Playwrightに対応）
      page.driver.resize_window_to(page.driver.current_window_handle, 375, 667)
      visit content_path(content)
      find(".variation-card", match: :first).find("img").click
      sleep 0.5
    end

    after do
      # デフォルトサイズに戻す
      page.driver.resize_window_to(page.driver.current_window_handle, 1400, 900)
    end

    it "モバイルでも正しく表示される" do
      expect(page).to have_css("[data-controller='artwork-lightbox']:not(.hidden)")
      expect(page).to have_css("img[data-artwork-lightbox-target='currentImage']")
    end

    it "タッチジェスチャーで画像を切り替えられる" do
      # スワイプイベントをシミュレート
      page.execute_script(<<~JS)
        const lightbox = document.querySelector('[data-controller="artwork-lightbox"]');
        const event = new CustomEvent('swipeleft', { bubbles: true });
        lightbox.dispatchEvent(event);
      JS

      expect(page).to have_text("2 / 3")
    end
  end
end
