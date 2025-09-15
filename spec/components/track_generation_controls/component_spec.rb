# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackGenerationControls::Component, type: :component do
  let(:content_record) { create(:content) }
  let(:component) { described_class.new(content_record: content_record) }

  describe "レンダリング" do
    subject { render_inline(component) }

    it "ボタンコンテナが右側配置のフレックスレイアウトを持つこと" do
      subject
      expect(page).to have_css("div.generation-controls.flex.justify-end")
    end

    it "1件生成ボタンが表示されること" do
      subject
      expect(page).to have_button("1件生成")
    end

    it "一括生成ボタンが表示されること" do
      subject
      expect(page).to have_button("一括生成")
    end

    context "レスポンシブデザイン" do
      it "モバイルで縦並び、デスクトップで横並びのクラスを持つこと" do
        subject
        expect(page).to have_css("div.flex.flex-col.sm\\:flex-row")
      end
    end
  end

  describe "#single_button_classes" do
    it "青色のボタンスタイルクラスを返すこと" do
      expect(component.single_button_classes).to include("bg-blue-600")
      expect(component.single_button_classes).to include("hover:bg-blue-700")
    end
  end

  describe "#bulk_button_classes" do
    it "緑色のボタンスタイルクラスを返すこと" do
      expect(component.bulk_button_classes).to include("bg-green-600")
      expect(component.bulk_button_classes).to include("hover:bg-green-700")
    end
  end

  describe "#required_music_generation_count" do
    before do
      allow(MusicGenerationQueueingService).to receive(:calculate_music_generation_count)
        .with(content_record.duration_min)
        .and_return(5)
    end

    it "必要な音楽生成数を返すこと" do
      expect(component.required_music_generation_count).to eq(5)
    end
  end
end
