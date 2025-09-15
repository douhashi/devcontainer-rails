# frozen_string_literal: true

require "rails_helper"

RSpec.describe MusicGenerationRequestTable::Component, type: :component do
  let(:content) { create(:content) }
  let(:component) { described_class.new(tracks: tracks) }

  describe "with tracks" do
    let!(:track1) { create(:track, content: content, metadata: { "music_title" => "Test Track 1" }) }
    let!(:track2) { create(:track, content: content, metadata: { "music_title" => "Test Track 2" }) }
    let(:tracks) { [ track1, track2 ] }

    before { render_inline(component) }

    it "renders the table with tracks" do
      expect(page).to have_css("table")
      expect(page).to have_css("tbody tr", count: 2)
    end

    it "displays track numbers sequentially" do
      expect(page).to have_content("#1")
      expect(page).to have_content("#2")
    end

    it "displays track titles" do
      expect(page).to have_content("Test Track 1")
      expect(page).to have_content("Test Track 2")
    end

    # Status badges removed as per Issue #243

    it "shows table headers" do
      expect(page).to have_content("Track No.")
      expect(page).to have_content("タイトル")
      expect(page).to have_content("曲の長さ")
      expect(page).to have_content("プレイヤー")
      # Creation date column removed as per Issue #348
      # expect(page).to have_content("作成日時")
    end

    it "does not show delete actions" do
      expect(page).not_to have_css("button[data-turbo-method='delete']")
      expect(page).not_to have_content("削除")
    end
  end

  describe "with empty tracks" do
    let(:tracks) { [] }

    before { render_inline(component) }

    it "shows empty state message" do
      expect(page).to have_content("音楽生成リクエストがありません")
      expect(page).not_to have_css("table")
    end
  end

  describe "pagination behavior" do
    it "shows pagination wrapper when show_pagination is true and tracks respond to current_page" do
      tracks_with_pagination = double("tracks", any?: true)
      allow(tracks_with_pagination).to receive(:respond_to?).with(:current_page).and_return(true)
      allow(tracks_with_pagination).to receive(:each_with_index).and_return([])

      component = described_class.new(tracks: tracks_with_pagination, show_pagination: true)
      expect(component.send(:show_pagination_area?)).to be true
    end

    it "does not show pagination when show_pagination is false" do
      tracks_without_pagination = [ create(:track) ]
      component = described_class.new(tracks: tracks_without_pagination, show_pagination: false)
      expect(component.send(:show_pagination_area?)).to be false
    end
  end
end
