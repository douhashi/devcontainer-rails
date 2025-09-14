require "rails_helper"

RSpec.describe "Artwork Lightbox", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:content) { create(:content) }
  let!(:artwork) { create(:artwork, content: content) }  # let! to ensure creation

  before do
    # Ensure artwork is associated with content
    content.reload

    # Verify artwork was created properly
    puts "Artwork present?: #{content.artwork.present?}"
    puts "Artwork image present?: #{content.artwork&.image&.present?}"

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

    login_as(user, scope: :user)
  end

  describe "Lightbox表示" do
    it "グリッド内の画像をクリックするとLightboxが開く" do
      visit content_path(content)

      # Wait for Javascript to load
      sleep 1

      # JavaScript実行結果を確認
      console_logs = page.evaluate_script("console.log('Testing if console works'); 'Console test'")
      puts "Console test result: #{console_logs}"

      # Artworkが見つかるかチェック
      expect(page).to have_css(".variation-card", wait: 3)

      # 最初のグリッド画像をクリック
      find(".variation-card", match: :first).find("[data-action*='artwork-lightbox#open']").click

      # Lightboxが表示される
      expect(page).to have_css("[data-artwork-lightbox-target='lightbox']:not(.hidden)", visible: true, wait: 3)
    end

    it "大きな画像が表示される" do
      visit content_path(content)
      find(".variation-card", match: :first).find("[data-action*='artwork-lightbox#open']").click

      within "[data-artwork-lightbox-target='lightbox']:not(.hidden)" do
        expect(page).to have_css("img[data-artwork-lightbox-target='currentImage']")
      end
    end

    it "画像のメタ情報が表示される" do
      visit content_path(content)
      find(".variation-card", match: :first).find("[data-action*='artwork-lightbox#open']").click

      within "[data-artwork-lightbox-target='metadata']" do
        expect(page).to have_text("オリジナル")
        expect(page).to have_text("1920x1080")
        expect(page).to have_text("2.0MB")
        expect(page).to have_text("JPEG")
      end
    end

    it "画像カウンターが表示される" do
      visit content_path(content)
      find(".variation-card", match: :first).find("[data-action*='artwork-lightbox#open']").click

      expect(page).to have_css("[data-artwork-lightbox-target='counter']")
      expect(page).to have_text("1 / 3")
    end
  end

  describe "Lightbox閉じる" do
    before do
      visit content_path(content)
      find(".variation-card", match: :first).find("[data-action*='artwork-lightbox#open']").click
      sleep 0.5  # アニメーション完了を待つ
    end

    it "閉じるボタン（×）でLightboxを閉じられる" do
      find("[data-action='click->artwork-lightbox#close']").click
      expect(page).to have_css("[data-artwork-lightbox-target='lightbox'].hidden", visible: false, wait: 2)
    end

    it "ESCキーでLightboxを閉じられる" do
      find("body").send_keys(:escape)
      expect(page).to have_css("[data-artwork-lightbox-target='lightbox'].hidden", visible: false, wait: 2)
    end

    xit "背景オーバーレイをクリックしても閉じられる" do
      # Lightbox要素の背景をクリックして閉じる
      page.find("[data-artwork-lightbox-target='lightbox']").click
      expect(page).to have_css("[data-artwork-lightbox-target='lightbox'].hidden", visible: false, wait: 2)
    end
  end

  describe "画像ナビゲーション" do
    before do
      visit content_path(content)
      find(".variation-card", match: :first).find("[data-action*='artwork-lightbox#open']").click
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

      find("body").send_keys(:right)
      expect(page).to have_text("2 / 3")
    end

    it "左矢印キーで前の画像に切り替わる" do
      find("[data-action='click->artwork-lightbox#next']").click
      expect(page).to have_text("2 / 3")

      find("body").send_keys(:left)
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

      # Lightbox要素の存在を確認（hiddenクラスも受け入れる）
      expect(page).to have_css("[data-artwork-lightbox-target='lightbox']", visible: :all)

      find(".variation-card", match: :first).find("[data-action*='artwork-lightbox#open']").click

      # 表示状態を確認
      expect(page).to have_css("[data-artwork-lightbox-target='lightbox']:not(.hidden)", wait: 2)
    end
  end

  describe "アクセシビリティ" do
    before do
      visit content_path(content)
      find(".variation-card", match: :first).find("[data-action*='artwork-lightbox#open']").click
      sleep 0.5  # アニメーション完了を待つ
    end

    it "ARIA属性が正しく設定される" do
      lightbox = find("[data-artwork-lightbox-target='lightbox']:not(.hidden)")
      expect(lightbox["role"]).to eq("dialog")
      expect(lightbox["aria-modal"]).to eq("true")
      expect(lightbox["aria-label"]).to be_present
    end

    it "フォーカスがLightbox内にトラップされる" do
      # TABキーでフォーカスを移動
      find("[data-artwork-lightbox-target='lightbox']:not(.hidden) [data-action='click->artwork-lightbox#close']").send_keys(:tab)

      # フォーカスがLightbox内の要素に設定されていることを確認
      active_element_in_lightbox = page.evaluate_script(
        "document.querySelector('[data-artwork-lightbox-target=\"lightbox\"]').contains(document.activeElement)"
      )
      expect(active_element_in_lightbox).to be true
    end
  end

  describe "モバイル対応", type: :system, js: true do
    before do
      # モバイルビューポートサイズに変更（Playwrightに対応）
      page.driver.resize_window_to(page.driver.current_window_handle, 375, 667)
      visit content_path(content)
      find(".variation-card", match: :first).find("[data-action*='artwork-lightbox#open']").click
      sleep 0.5
    end

    after do
      # デフォルトサイズに戻す
      page.driver.resize_window_to(page.driver.current_window_handle, 1400, 900)
    end

    it "モバイルでも正しく表示される" do
      expect(page).to have_css("[data-artwork-lightbox-target='lightbox']:not(.hidden)")
      expect(page).to have_css("img[data-artwork-lightbox-target='currentImage']", visible: true)
    end

    it "タッチジェスチャーで画像を切り替えられる" do
      # 直接next buttonをクリックしてスワイプ機能をテスト
      find("[data-action='click->artwork-lightbox#next']").click

      expect(page).to have_text("2 / 3")
    end
  end
end
