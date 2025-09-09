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
        create_list(:track, 2, music_generation: generation1, duration_sec: 120)
      end

      it "renders music generation table" do
        render_inline(component)

        expect(page).to have_css("table.min-w-full")
        # Track単位表示なので、MusicGeneration IDはセルに表示される
        expect(page).to have_css("td", text: generation1.id.to_s)
        expect(page).to have_css("td", text: generation2.id.to_s)
        expect(page).to have_css("td", text: generation3.id.to_s)
      end

      it "renders table headers for track-based display" do
        render_inline(component)

        # Track単位表示用のヘッダー
        expect(page).to have_css("th", text: "生成リクエストID")
        expect(page).to have_css("th", text: "Track ID")
        expect(page).to have_css("th", text: "曲の長さ")
        expect(page).to have_css("th", text: "プレイヤー")
        expect(page).to have_css("th", text: "アクション")
      end

      it "renders track rows grouped by music generation" do
        render_inline(component)

        # generation1は2つのTrack、generation2とgeneration3はTrackなし
        # Track単位表示なので、Trackがある行 + Trackがない行が表示される
        expect(page).to have_css("tbody tr[data-generation-id='#{generation1.id}']", minimum: 2)
        expect(page).to have_css("tbody tr[data-generation-id='#{generation2.id}']", minimum: 1)
        expect(page).to have_css("tbody tr[data-generation-id='#{generation3.id}']", minimum: 1)
      end
    end

    context "when no music generations exist" do
      it "renders empty message" do
        render_inline(component)

        expect(page).to have_text("音楽生成リクエストがありません")
        expect(page).to have_css(".empty-state")
        expect(page).to have_css(".text-gray-400")
      end

      it "does not render table when empty" do
        render_inline(component)

        expect(page).not_to have_css("table")
      end
    end

    context "responsive design" do
      let(:music_generations) { create_list(:music_generation, 3, content: content) }

      it "includes responsive table container" do
        render_inline(component)

        expect(page).to have_css(".overflow-x-auto")
      end
    end
  end
end
