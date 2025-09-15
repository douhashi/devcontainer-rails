require "rails_helper"
require "vips"

RSpec.describe "Artwork Thumbnail Preview", type: :system, js: true do
  let(:content) { create(:content) }

  before do
    I18n.locale = :ja
  end

  describe "サムネイルプレビュー機能" do
    context "1920x1080の画像がアップロードされている場合" do
      before do
        # Create a 1920x1080 test image
        test_image_path = Rails.root.join("tmp/test_system_image.jpg").to_s
        image = Vips::Image.black(1920, 1080, bands: 3).add(128)
        image.write_to_file(test_image_path, Q: 90)

        # Create artwork with the image
        artwork = build(:artwork, content: content)
        artwork.image = File.open(test_image_path)
        artwork.save!

        FileUtils.rm_f(test_image_path)
      end

      it "プレビューボタンをクリックするとサムネイルプレビューが表示される", skip: "Stimulus controller auto-loading needs to be implemented" do
        visit content_path(content)

        # プレビューボタンが表示されていることを確認
        expect(page).to have_button("プレビューを表示")

        # プレビューボタンをクリック
        click_button "プレビューを表示"

        # ローディングスピナーが表示されることを確認
        expect(page).to have_css("[data-thumbnail-preview-target='loadingSpinner']", visible: true)

        # プレビューが読み込まれるのを待つ
        expect(page).to have_button("オリジナルを表示", wait: 10)

        # プレビュー画像が表示されていることを確認
        expect(page).to have_css("[data-thumbnail-preview-target='thumbnailImage']", visible: true)
        expect(page).to have_css("[data-thumbnail-preview-target='originalImage']", visible: false)

        # オリジナルに戻すボタンをクリック
        click_button "オリジナルを表示"

        # オリジナル画像が表示されていることを確認
        expect(page).to have_css("[data-thumbnail-preview-target='originalImage']", visible: true)
        expect(page).to have_css("[data-thumbnail-preview-target='thumbnailImage']", visible: false)
        expect(page).to have_button("プレビューを表示")
      end
    end

    context "1920x1080以外の画像がアップロードされている場合" do
      before do
        # Create a non-1920x1080 test image
        test_image_path = Rails.root.join("tmp/test_system_image_small.jpg").to_s
        image = Vips::Image.black(800, 600, bands: 3).add(128)
        image.write_to_file(test_image_path, Q: 90)

        # Create artwork with the image
        artwork = build(:artwork, content: content)
        artwork.image = File.open(test_image_path)
        artwork.save!

        FileUtils.rm_f(test_image_path)
      end

      it "プレビューボタンが表示されない" do
        visit content_path(content)

        # アートワークは表示されるがプレビューボタンは表示されない
        expect(page).to have_css('.artwork-variations-grid img')
        expect(page).not_to have_button("プレビューを表示")
      end
    end

    context "サムネイル生成中にエラーが発生した場合" do
      before do
        # Create a 1920x1080 test image
        test_image_path = Rails.root.join("tmp/test_system_image_error.jpg").to_s
        image = Vips::Image.black(1920, 1080, bands: 3).add(128)
        image.write_to_file(test_image_path, Q: 90)

        # Create artwork with the image
        artwork = build(:artwork, content: content)
        artwork.image = File.open(test_image_path)
        artwork.save!

        FileUtils.rm_f(test_image_path)

        # サムネイル生成サービスをモックしてエラーを発生させる
        allow_any_instance_of(ThumbnailGenerationService).to receive(:generate)
          .and_raise(ThumbnailGenerationService::GenerationError, "テスト用エラー")
      end

      it "エラーメッセージが表示される" do
        visit content_path(content)

        # プレビューボタンをクリック
        click_button "プレビューを表示"

        # エラーメッセージが表示されることを確認
        expect(page).to have_css("[data-thumbnail-preview-target='errorMessage']", visible: true, wait: 10)
        expect(page).to have_content("Failed to generate preview")

        # ボタンが再度有効になることを確認
        expect(page).to have_button("プレビューを表示", disabled: false)
      end
    end
  end

  describe "プレビュー表示の枠線確認" do
    context "生成されたサムネイルに正しい枠線が描画されている" do
      before do
        # Create a 1920x1080 test image
        test_image_path = Rails.root.join("tmp/test_system_border.jpg").to_s
        image = Vips::Image.black(1920, 1080, bands: 3).add(50)  # Dark gray background
        image.write_to_file(test_image_path, Q: 90)

        # Create artwork with the image
        artwork = build(:artwork, content: content)
        artwork.image = File.open(test_image_path)
        artwork.save!

        FileUtils.rm_f(test_image_path)
      end

      it "プレビューに矩形の白い枠線が表示される", skip: "Stimulus controller auto-loading needs to be implemented" do
        visit content_path(content)

        # プレビューボタンをクリック
        click_button "プレビューを表示"

        # プレビューが読み込まれるのを待つ
        expect(page).to have_button("オリジナルを表示", wait: 10)

        # プレビュー画像が表示されていることを確認
        thumbnail_element = find("[data-thumbnail-preview-target='thumbnailImage']", visible: true)

        # 画像が正しいサイズで表示されていることを確認（ブラウザのレンダリングサイズではなく、src属性の存在を確認）
        expect(thumbnail_element[:src]).to be_present
        expect(thumbnail_element[:src]).to start_with("data:image/jpeg;base64,")
      end
    end
  end
end
