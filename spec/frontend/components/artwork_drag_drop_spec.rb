# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArtworkDragDrop::Component, type: :component do
  let(:content) { create(:content) }
  let(:artwork) { create(:artwork, content: content) }

  describe "レンダリング" do
    context "アートワークが存在しない場合" do
      let(:component) { described_class.new(content_record: content) }

      it "ドラッグ&ドロップエリアが表示される" do
        render_inline(component)

        expect(page).to have_selector('[data-controller="artwork-drag-drop"]')
        expect(page).to have_text("画像をドラッグ&ドロップ")
        expect(page).to have_text("またはクリックしてファイルを選択")
        expect(page).to have_selector('input[type="file"]', visible: :all)
      end

      it "16:9のアスペクト比が適用される" do
        render_inline(component)

        expect(page).to have_css('.aspect-\\[16\\/9\\]')
      end

      it "ファイルアップロード用のフォームが含まれる" do
        render_inline(component)

        expect(page).to have_selector("form[action='#{component.form_url}']")
        expect(page).to have_selector('input[type="file"][accept="image/*"]', visible: :all)
      end
    end

    context "アートワークが存在する場合" do
      let(:content_with_artwork) { content }
      let(:component) { described_class.new(content_record: content_with_artwork) }

      before do
        content_with_artwork.artwork = artwork
      end

      it "アートワーク画像が表示される" do
        render_inline(component)

        expect(page).to have_selector("img[src*='#{artwork.image.url}']")
        expect(page).not_to have_text("画像をドラッグ&ドロップ")
      end

      it "削除ボタンが表示される" do
        render_inline(component)

        expect(page).to have_button("削除")
        expect(page).to have_selector("form[action='#{component.form_url}']")
      end

      it "16:9のアスペクト比で画像が表示される" do
        render_inline(component)

        expect(page).to have_css('.aspect-\\[16\\/9\\]')
        expect(page).to have_css('img.object-cover')
      end
    end
  end

  describe "初期化" do
    context "contentレコードが渡された場合" do
      let(:component) { described_class.new(content_record: content) }

      it "contentが設定される" do
        expect(component.content).to eq(content)
      end

      it "artworkが初期化される" do
        expect(component.artwork).to be_a(Artwork)
        expect(component.artwork).to be_new_record
      end
    end

    context "artworkを持つcontentが渡された場合" do
      let(:content_with_artwork) { content }
      let(:component) { described_class.new(content_record: content_with_artwork) }

      before do
        content_with_artwork.artwork = artwork
      end

      it "既存のartworkが使用される" do
        expect(component.artwork).to eq(artwork)
      end
    end
  end

  describe "ヘルパーメソッド" do
    let(:component) { described_class.new(content_record: content) }

    describe "#has_artwork?" do
      context "アートワークが存在しない場合" do
        it "falseを返す" do
          expect(component.has_artwork?).to be false
        end
      end

      context "アートワークが存在する場合" do
        before do
          content.artwork = artwork
        end

        it "trueを返す" do
          expect(component.has_artwork?).to be true
        end
      end
    end

    describe "#form_url" do
      context "新規アートワークの場合" do
        it "createアクション用のURLを返す" do
          expect(component.form_url).to include("/contents/#{content.id}/artworks")
        end
      end

      context "既存アートワークの場合" do
        before do
          content.artwork = artwork
        end

        it "updateアクション用のURLを返す" do
          expect(component.form_url).to include("/contents/#{content.id}/artworks/#{artwork.id}")
        end
      end
    end

    describe "#form_method" do
      context "新規アートワークの場合" do
        it "postを返す" do
          expect(component.form_method).to eq(:post)
        end
      end

      context "既存アートワークの場合" do
        before do
          content.artwork = artwork
        end

        it "patchを返す" do
          expect(component.form_method).to eq(:patch)
        end
      end
    end

    describe "#artwork_url" do
      context "アートワークが存在しない場合" do
        it "nilを返す" do
          expect(component.artwork_url).to be_nil
        end
      end

      context "アートワークが存在する場合" do
        before do
          content.artwork = artwork
        end

        it "画像URLを返す" do
          expect(component.artwork_url).to eq(artwork.image.url)
        end
      end
    end
  end
end
