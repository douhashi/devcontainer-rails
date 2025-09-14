require "rails_helper"
require "vips"

RSpec.describe "Artwork Layout Refactor", type: :system, playwright: true do
  include ActiveJob::TestHelper
  include_context "ログイン済み"

  let(:content) { create(:content) }

  before do
    # Create test image
    create_test_fhd_image(Rails.root.join("tmp/test_fhd_artwork.jpg"))
  end

  after do
    # Clean up test files
    FileUtils.rm_f(Rails.root.join("tmp/test_fhd_artwork.jpg"))
  end

  describe "リファクタリング後のレイアウト", js: true, playwright: true do
    context "アートワークがアップロードされた場合" do
      it "大きなプレビューを表示せず、コンパクトな管理インターフェースを表示する" do
        visit content_path(content)

        # Upload the FHD image
        attach_file "artwork[image]", Rails.root.join("tmp/test_fhd_artwork.jpg"), visible: false

        # アップロード完了を待つ
        expect(page).to have_css(".artwork-variations-grid", wait: 10)

        # 大きなプレビューが表示されていないことを確認
        within(".artwork-section") do
          # ドラッグ&ドロップエリアが表示されていないことを確認
          expect(page).not_to have_text("画像をドラッグ&ドロップ")

          # グリッドレイアウトが表示されていることを確認
          expect(page).to have_css(".artwork-variations-grid")

          # ドラッグ&ドロップコンポーネントが表示されていないことを確認
          expect(page).not_to have_text("画像をドラッグ&ドロップ")
        end
      end

      it "削除ボタンがグリッドの兄弟要素として配置されている" do
        # 既存のアートワークを作成
        artwork = create(:artwork, content: content)

        visit content_path(content)

        within(".artwork-section") do
          # 削除ボタンが存在することを確認
          expect(page).to have_css("button[aria-label='アートワークを削除']")

          # グリッドコンポーネントが存在することを確認
          expect(page).to have_css(".artwork-variations-grid")

          # 削除ボタンがグリッドの兄弟要素として配置されていることを確認
          # （同じ親要素内に存在することを確認）
          container = find(".artwork-management-container")
          expect(container).to have_css(".artwork-variations-grid")
          expect(container).to have_css("button[aria-label='アートワークを削除']")
        end
      end
    end

    context "アートワークが存在しない場合" do
      it "ドラッグ&ドロップコンポーネントのみを表示する" do
        visit content_path(content)

        within(".artwork-section") do
          # ドラッグ&ドロップエリアが表示されていることを確認
          expect(page).to have_text("画像をドラッグ&ドロップ")
          expect(page).to have_text("またはクリックしてファイルを選択")

          # グリッドレイアウトが表示されていないことを確認
          expect(page).not_to have_css(".artwork-variations-grid")
        end
      end
    end

    context "グリッド内の画像クリック" do
      let!(:artwork) { create(:artwork, content: content) }

      it "Lightboxモーダルで拡大表示される", skip: "Lightbox動作は手動テストで確認" do
        visit content_path(content)

        within(".artwork-variations-grid") do
          # グリッド内の画像をクリック
          first(".variation-card img").click
        end

        # Lightboxモーダルが表示されることを確認
        # 少し待機してJavaScriptの実行を待つ
        sleep 0.5

        # Lightboxコンポーネントを探す（複数ある場合は最後のものを選択）
        lightboxes = all("[data-controller='artwork-lightbox']", visible: :all)
        lightbox = lightboxes.last

        # hiddenクラスが削除されていることを確認
        expect(lightbox[:class]).not_to include("hidden")

        # 画像が表示されることを確認
        within(lightbox) do
          expect(page).to have_css("img[data-artwork-lightbox-target='currentImage']", visible: :all)
        end

        # 閉じるボタンをクリックしてモーダルを閉じる
        find("[data-action='click->artwork-lightbox#close']", visible: :all).click

        # モーダルが閉じられることを確認
        expect(page).not_to have_css("[data-artwork-lightbox-target='modal'][class*='opacity-100']")
      end
    end

    context "レスポンシブデザイン" do
      let!(:artwork) { create(:artwork, content: content) }

      it "モバイル表示で適切にレイアウトされる" do
        # Playwrightでのビューポート設定はスキップ
        skip "ビューポートサイズ変更はPlaywrightでは異なる方法が必要"

        visit content_path(content)

        within(".artwork-section") do
          # グリッドがモバイル用の1カラムレイアウトになっていることを確認
          grid = find(".artwork-variations-grid .grid")
          expect(grid[:class]).to include("grid-cols-1")
        end
      end

      it "デスクトップ表示で適切にレイアウトされる" do
        # Playwrightでのビューポート設定はスキップ
        skip "ビューポートサイズ変更はPlaywrightでは異なる方法が必要"

        visit content_path(content)

        within(".artwork-section") do
          # グリッドがデスクトップ用の3カラムレイアウトになっていることを確認
          grid = find(".artwork-variations-grid .grid")
          expect(grid[:class]).to include("lg:grid-cols-3")
        end
      end
    end
  end

  describe "削除機能", js: true, playwright: true do
    let!(:artwork) { create(:artwork, content: content) }

    it "削除ボタンクリックで確認ダイアログを表示し、削除を実行できる", skip: "Turbo Stream削除の動作確認は手動テストで実施" do
      visit content_path(content)

      # アートワークが表示されていることを確認
      expect(page).to have_css(".artwork-variations-grid")

      # 削除ボタンをクリック
      accept_confirm("アートワークを削除しますか？") do
        find("button[aria-label='アートワークを削除']").click
      end

      # Turbo Streamの処理を待つ
      sleep 3

      # アートワークが削除されたことを確認
      # ドラッグ&ドロップエリアが表示されることを確認
      within("#artwork-section-#{content.id}") do
        expect(page).to have_text("画像をドラッグ&ドロップ", wait: 10)
      end
    end
  end

  private

  def create_test_fhd_image(path)
    image = Vips::Image.black(1920, 1080, bands: 3)
    image = image.add(128)  # Make it gray
    image.write_to_file(path.to_s, Q: 90)
  end
end
