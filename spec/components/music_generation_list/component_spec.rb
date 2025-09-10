# frozen_string_literal: true

require "rails_helper"

RSpec.describe MusicGenerationList::Component, type: :component do
  let(:content) { create(:content) }
  let(:tracks) { [] }
  let(:component) { described_class.new(tracks: tracks) }

  describe "#has_tracks?" do
    context "when tracks exist" do
      let(:tracks) { create_list(:track, 2, content: content) }

      it "returns true" do
        expect(component.has_tracks?).to be true
      end
    end

    context "when no tracks exist" do
      it "returns false" do
        expect(component.has_tracks?).to be false
      end
    end
  end

  describe "#empty_message" do
    it "returns appropriate message" do
      expect(component.empty_message).to eq("音楽生成リクエストがありません")
    end
  end

  describe "rendering" do
    context "when tracks exist" do
      let!(:track1) { create(:track, content: content, metadata: { "music_title" => "Track 1" }) }
      let!(:track2) { create(:track, content: content, metadata: { "music_title" => "Track 2" }) }
      let(:tracks) { [ track1, track2 ] }

      it "renders music generation request table" do
        render_inline(component)

        expect(page).to have_css("table.min-w-full")
        expect(page).to have_css("td", text: "#1")
        expect(page).to have_css("td", text: "#2")
      end

      it "renders table headers for track-based display" do
        render_inline(component)

        expect(page).to have_css("th", text: "Track No.")
        expect(page).to have_css("th", text: "ステータス")
        expect(page).to have_css("th", text: "タイトル")
        expect(page).to have_css("th", text: "曲の長さ")
        expect(page).to have_css("th", text: "プレイヤー")
        expect(page).to have_css("th", text: "作成日時")
      end

      it "displays track titles" do
        render_inline(component)

        expect(page).to have_content("Track 1")
        expect(page).to have_content("Track 2")
      end
    end

    context "when no tracks exist" do
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
      let(:tracks) { create_list(:track, 3, content: content) }

      it "includes scrollable table container" do
        render_inline(component)

        expect(page).to have_css(".overflow-y-auto")
        expect(page).to have_css(".max-h-96")
      end
    end
  end
end
