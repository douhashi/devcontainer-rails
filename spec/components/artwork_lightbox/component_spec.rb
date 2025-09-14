require "rails_helper"

RSpec.describe ArtworkLightbox::Component, type: :component do
  let(:artwork) { create(:artwork) }
  let(:variations) do
    [
      {
        url: "https://example.com/image1.jpg",
        download_url: "https://example.com/download/image1.jpg",
        type: :original,
        label: "オリジナル",
        metadata: {
          width: 1920,
          height: 1080,
          size: 2048000,
          format: "JPEG"
        }
      },
      {
        url: "https://example.com/image2.jpg",
        download_url: "https://example.com/download/image2.jpg",
        type: :youtube_thumbnail,
        label: "YouTubeサムネイル",
        metadata: {
          width: 1280,
          height: 720,
          size: 1024000,
          format: "JPEG"
        }
      }
    ]
  end
  let(:component) { described_class.new(variations: variations, initial_index: 0) }

  describe "#initialization" do
    it "初期化時にバリエーションとインデックスを設定する" do
      expect(component.variations).to eq(variations)
      expect(component.initial_index).to eq(0)
    end

    it "初期インデックスのデフォルト値は0" do
      component = described_class.new(variations: variations)
      expect(component.initial_index).to eq(0)
    end

    it "空のバリエーションを受け入れる" do
      component = described_class.new(variations: [])
      expect(component.variations).to eq([])
    end
  end

  describe "#render?" do
    it "バリエーションが存在する場合はtrueを返す" do
      expect(component.render?).to be true
    end

    it "バリエーションが空の場合はfalseを返す" do
      component = described_class.new(variations: [])
      expect(component.render?).to be false
    end
  end

  describe "#total_images" do
    it "バリエーションの総数を返す" do
      expect(component.total_images).to eq(2)
    end
  end

  describe "#format_file_size" do
    it "バイト単位を人間が読める形式に変換する" do
      expect(component.send(:format_file_size, 1024)).to eq("1.0KB")
      expect(component.send(:format_file_size, 1048576)).to eq("1.0MB")
      expect(component.send(:format_file_size, 512)).to eq("512B")
    end

    it "nilの場合はN/Aを返す" do
      expect(component.send(:format_file_size, nil)).to eq("N/A")
    end
  end

  describe "HTMLレンダリング" do
    subject { render_inline(component) }

    it "Lightboxコンテナをレンダリングする" do
      subject
      expect(page).to have_css("[controller='artwork-lightbox']")
    end

    it "必要なARIA属性を含む" do
      subject
      expect(page).to have_css("[role='dialog']")
      expect(page).to have_css("[aria-modal='true']")
    end

    it "画像表示エリアを含む" do
      subject
      expect(page).to have_css("[data-artwork-lightbox-target='imageContainer']")
    end

    it "ナビゲーションボタンを含む" do
      subject
      expect(page).to have_css("[data-action='click->artwork-lightbox#previous']")
      expect(page).to have_css("[data-action='click->artwork-lightbox#next']")
    end

    it "閉じるボタンを含む" do
      subject
      expect(page).to have_css("[data-action='click->artwork-lightbox#close']")
    end

    it "メタデータ表示エリアを含む" do
      subject
      expect(page).to have_css("[data-artwork-lightbox-target='metadata']")
    end

    it "画像カウンターを表示する" do
      subject
      expect(page).to have_css("[data-artwork-lightbox-target='counter']")
      expect(page).to have_text("1 / 2")
    end

    it "初期状態でhiddenクラスを持つ" do
      subject
      expect(page).to have_css(".hidden[controller='artwork-lightbox']")
    end
  end

  describe "データ属性" do
    subject { render_inline(component) }

    it "必要なdata-valuesを含む" do
      subject
      element = page.find("[controller='artwork-lightbox']")
      expect(element["artwork-lightbox-images-value"]).to be_present
      expect(element["artwork-lightbox-current-index-value"]).to eq("0")
    end
  end
end
