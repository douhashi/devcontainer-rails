# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackRequestRow::Component, type: :component do
  let(:track) { create(:track, metadata: { "music_title" => "Test Track" }) }
  let(:track_number) { 1 }
  let(:component) { described_class.new(track: track, track_number: track_number) }

  describe "rendering basic information" do
    before { render_inline(component) }

    it "renders a table row" do
      expect(page).to have_css("tr")
    end

    it "displays the track number" do
      expect(page).to have_content("#1")
    end

    it "displays the track title" do
      expect(page).to have_content("Test Track")
    end

    it "displays creation date" do
      expect(page).to have_content(I18n.l(track.created_at, format: :short))
    end

    it "displays status badge" do
      expect(page).to have_css("span[role='status']")
    end

    it "does not show delete button" do
      expect(page).not_to have_css("button[data-turbo-method='delete']")
      expect(page).not_to have_content("削除")
    end
  end

  describe "track with audio and completed status" do
    let(:track) do
      create(:track,
        status: :completed,
        audio: fixture_file_upload("sample.mp3", "audio/mp3"),
        metadata: { "music_title" => "Completed Track" }
      )
    end

    before { render_inline(component) }

    it "shows audio play button" do
      expect(page).to have_css("[data-controller='audio-play-button']")
    end

    it "displays formatted duration" do
      expect(page).to have_content(track.formatted_duration)
    end
  end

  describe "track with processing status" do
    let(:track) { create(:track, status: :processing, metadata: { "music_title" => "Processing Track" }) }

    before { render_inline(component) }

    it "shows processing message instead of play button" do
      expect(page).to have_content("処理中...")
      expect(page).not_to have_css("[data-controller='audio-play-button']")
    end
  end

  describe "track with failed status" do
    let(:track) { create(:track, status: :failed, metadata: { "music_title" => "Failed Track" }) }

    before { render_inline(component) }

    it "shows unavailable message" do
      expect(page).to have_content("利用不可")
      expect(page).not_to have_css("[data-controller='audio-play-button']")
    end
  end

  describe "track without title metadata" do
    let(:track) { create(:track, metadata: {}) }

    before { render_inline(component) }

    it "shows fallback for empty title" do
      expect(page).to have_content("-") # or whatever fallback is used
    end
  end

  describe "track with different numbers" do
    let(:track_number) { 5 }

    before { render_inline(component) }

    it "displays correct track number" do
      expect(page).to have_content("#5")
    end
  end
end
