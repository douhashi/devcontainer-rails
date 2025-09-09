# frozen_string_literal: true

require "rails_helper"

RSpec.describe MusicGenerationList::Component, type: :component do
  let(:content) { create(:content) }
  let(:music_generations) { [] }
  let(:component) { described_class.new(music_generations: music_generations) }

  describe "#has_generations?" do
    context "when music generations exist" do
      let(:music_generations) { create_list(:music_generation, 2, content: content) }

      it "returns true" do
        expect(component.has_generations?).to be true
      end
    end

    context "when no music generations exist" do
      it "returns false" do
        expect(component.has_generations?).to be false
      end
    end
  end

  describe "#empty_message" do
    it "returns appropriate message" do
      expect(component.empty_message).to eq("音楽生成リクエストがありません")
    end
  end

  describe "rendering" do
    context "when music generations exist" do
      let!(:generation1) { create(:music_generation, content: content, status: :completed) }
      let!(:generation2) { create(:music_generation, content: content, status: :processing) }
      let!(:generation3) { create(:music_generation, content: content, status: :pending) }
      let(:music_generations) { [ generation1, generation2, generation3 ] }

      before do
        create_list(:track, 2, music_generation: generation1)
      end

      it "renders all music generation cards" do
        render_inline(component)

        expect(page).to have_text("生成リクエスト ##{generation1.id}")
        expect(page).to have_text("生成リクエスト ##{generation2.id}")
        expect(page).to have_text("生成リクエスト ##{generation3.id}")

        expect(page).to have_text("完了")
        expect(page).to have_text("処理中")
        expect(page).to have_text("待機中")
      end

      it "has responsive grid layout" do
        render_inline(component)

        expect(page).to have_css(".grid")
        expect(page).to have_css(".gap-4")
      end
    end

    context "when no music generations exist" do
      it "renders empty message" do
        render_inline(component)

        expect(page).to have_text("音楽生成リクエストがありません")
        expect(page).to have_css(".text-center")
        expect(page).to have_css(".text-gray-400")
      end

      it "has appropriate dark mode classes for empty state" do
        render_inline(component)

        expect(page).to have_css(".text-gray-400")
        expect(page).to have_css(".text-gray-500")
      end
    end

    context "responsive design" do
      let(:music_generations) { create_list(:music_generation, 3, content: content) }

      it "applies responsive grid classes" do
        render_inline(component)

        expect(page).to have_css(".grid")
        expect(page).to have_css(".grid-cols-1")
        expect(page).to have_css(".lg\\:grid-cols-1", visible: false)
      end
    end
  end
end
