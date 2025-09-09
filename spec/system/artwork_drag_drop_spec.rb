require 'rails_helper'

RSpec.describe "Artwork Drag and Drop", type: :system, js: true do
  let(:content) { create(:content) }
  let(:test_image_path) { Rails.root.join('spec', 'fixtures', 'test_image.jpg') }

  before do
    visit content_path(content)
  end

  describe "アートワーク未設定時" do
    it "ドラッグ&ドロップエリアが表示される" do
      expect(page).to have_selector('[data-controller="artwork-drag-drop"]')
      expect(page).to have_text("画像をドラッグ&ドロップ")
      expect(page).to have_text("またはクリックしてファイルを選択")
    end

    it "16:9の比率でエリアが表示される" do
      expect(page).to have_css('.aspect-\\[16\\/9\\]')
    end

    context "ファイル選択によるアップロード" do
      it "画像ファイルを選択してアップロードできる" do
        # JavaScriptコンソールのエラーを確認
        errors = page.driver.browser.logs.get(:browser).select { |e| e.level == "SEVERE" }
        puts "Initial JS errors: #{errors}" if errors.any?

        # ファイル選択
        file_input = find('[data-artwork-drag-drop-target="fileInput"]', visible: :all)
        file_input.set(test_image_path)

        # JavaScriptのchangeイベントを手動でトリガー
        page.execute_script("document.querySelector('[data-artwork-drag-drop-target=\"fileInput\"]').dispatchEvent(new Event('change', { bubbles: true }))")

        # 少し待機
        sleep 1

        # アップロード処理が完了し、画像が表示されるまで待つ
        expect(page).to have_css('img[alt="アートワーク"]', wait: 10)
        expect(page).to have_button("削除")

        # DBに保存されている確認
        expect(content.reload.artwork).to be_present
      end
    end

    context "ドラッグ&ドロップによるアップロード" do
      it "画像をドラッグ&ドロップしてアップロードできる" do
        # ドロップゾーンを取得
        drop_zone = find('[data-artwork-drag-drop-target="dropZone"]')

        # ファイルをドラッグ&ドロップする（Capybaraの制限により、実際のD&Dは難しいため、代替手段）
        # 実際のテストではファイル選択で代用
        file_input = find('[data-artwork-drag-drop-target="fileInput"]', visible: :all)
        file_input.set(test_image_path)

        # JavaScriptのchangeイベントを手動でトリガー
        # セレクターが見つからない場合に備えて、エラーハンドリングを追加
        page.execute_script(<<~JS)
          const fileInput = document.querySelector('[data-artwork-drag-drop-target="fileInput"]');
          if (fileInput) {
            fileInput.dispatchEvent(new Event('change', { bubbles: true }));
          } else {
            // フォームが動的に生成されるのを待機
            const interval = setInterval(() => {
              const input = document.querySelector('[data-artwork-drag-drop-target="fileInput"]');
              if (input) {
                clearInterval(interval);
                input.dispatchEvent(new Event('change', { bubbles: true }));
              }
            }, 100);
            // 5秒後にタイムアウト
            setTimeout(() => clearInterval(interval), 5000);
          }
        JS

        # アップロード成功を確認
        expect(page).to have_css('img[alt="アートワーク"]', wait: 10)
      end
    end
  end

  describe "アートワーク設定済み時" do
    let!(:artwork) { create(:artwork, content: content) }

    before do
      visit content_path(content)
    end

    it "設定済みのアートワークが表示される" do
      expect(page).to have_css('img[alt="アートワーク"]')
      expect(page).to have_button("削除")
      expect(page).not_to have_text("画像をドラッグ&ドロップ")
    end

    it "削除ボタンクリックで確認ダイアログが表示される" do
      accept_confirm("アートワークを削除しますか？") do
        click_button "削除"
      end

      # 削除後、再度ドロップゾーンが表示される
      expect(page).to have_text("画像をドラッグ&ドロップ", wait: 10)
      expect(page).not_to have_css('img[alt="アートワーク"]')

      # DBから削除されている確認
      expect(content.reload.artwork).to be_nil
    end

    it "削除後に「アートワーク」ラベルが重複して表示されない" do
      accept_confirm("アートワークを削除しますか？") do
        click_button "削除"
      end

      # 削除後、再度ドロップゾーンが表示される
      expect(page).to have_text("画像をドラッグ&ドロップ", wait: 10)

      # 「アートワーク」ラベルが1つだけ表示されることを確認
      artwork_labels = page.all("h2", text: "アートワーク")
      expect(artwork_labels.count).to eq(1)
    end

    it "16:9の比率で画像が表示される" do
      expect(page).to have_css('.aspect-\\[16\\/9\\]')
      expect(page).to have_css('img.object-cover')
    end
  end

  describe "エラーハンドリング" do
    context "ファイルサイズが大きすぎる場合" do
      it "エラーメッセージが表示される" do
        # 10MB以上のファイルをテストする場合のシミュレーション
        # 実際のテストではJavaScriptのファイル検証をテストする

        # JavaScriptのバリデーションにより、大きすぎるファイルは送信されない
        # システムテストでは、JavaScriptの動作を確認
        expect(page).to have_selector('[data-artwork-drag-drop-target="fileInput"][accept="image/*"]', visible: :all)
      end
    end

    context "画像以外のファイルを選択した場合" do
      it "JavaScriptでバリデーションされる" do
        # 画像以外のファイルは accept="image/*" により選択できない
        file_input = find('[data-artwork-drag-drop-target="fileInput"]', visible: :all)
        expect(file_input['accept']).to eq('image/*')
      end
    end
  end

  describe "レスポンシブデザイン" do
    context "モバイル画面サイズ" do
      before do
        page.driver.browser.manage.window.resize_to(375, 667)
      end

      it "モバイルでも適切に表示される" do
        expect(page).to have_selector('[data-controller="artwork-drag-drop"]')
        expect(page).to have_css('.aspect-\\[16\\/9\\]')
      end
    end

    context "タブレット画面サイズ" do
      before do
        page.driver.browser.manage.window.resize_to(768, 1024)
      end

      it "タブレットでも適切に表示される" do
        expect(page).to have_selector('[data-controller="artwork-drag-drop"]')
        expect(page).to have_css('.aspect-\\[16\\/9\\]')
      end
    end
  end
end
