# frozen_string_literal: true

require "rails_helper"

RSpec.describe AudioUsedTracksTable::Component, type: :component do
  let(:audio) { create(:audio, status: :completed, metadata: metadata) }
  let(:metadata) { { "selected_track_ids" => track_ids } }
  let(:track_ids) { [] }
  let(:component) { described_class.new(audio: audio) }

  describe "#play_button_component" do
    context "when track has completed status and audio" do
      let(:track) { create(:track, status: :completed, audio: fixture_file_upload("audio/sample.mp3", "audio/mp3")) }

      it "returns AudioPlayButton component" do
        button = component.send(:play_button_component, track)
        expect(button).to be_a(AudioPlayButton::Component)
        expect(button.record).to eq(track)
      end
    end

    context "when track has pending status" do
      let(:track) { create(:track, status: :pending) }

      it "returns nil" do
        button = component.send(:play_button_component, track)
        expect(button).to be_nil
      end
    end

    context "when track has no audio" do
      let(:track) { create(:track, status: :completed, audio: nil) }

      it "returns nil" do
        button = component.send(:play_button_component, track)
        expect(button).to be_nil
      end
    end
  end

  describe "#track_row_data" do
    let(:track1) { create(:track, metadata: { "music_title" => "Track 1" }) }
    let(:track2) { create(:track, metadata: { "music_title" => "Track 2" }) }
    let(:track_ids) { [ track1.id, track2.id ] }

    it "includes track title in row data" do
      row_data = component.track_row_data

      expect(row_data.size).to eq(2)
      expect(row_data[0][:track]).to eq(track1)
      expect(row_data[0][:track_number]).to eq(1)
      expect(row_data[0][:track_title]).to eq("Track 1")
      expect(row_data[1][:track]).to eq(track2)
      expect(row_data[1][:track_number]).to eq(2)
      expect(row_data[1][:track_title]).to eq("Track 2")
    end

    context "when track has no title metadata" do
      let(:track1) { create(:track, metadata: {}) }

      it "uses nil as fallback" do
        row_data = component.track_row_data
        expect(row_data[0][:track_title]).to be_nil
      end
    end
  end

  describe "rendering" do
    before { render_inline(component) }

    context "with tracks having audio" do
      let(:track1) { create(:track, status: :completed, audio: fixture_file_upload("audio/sample.mp3", "audio/mp3"), metadata: { "music_title" => "Test Track" }) }
      let(:track2) { create(:track, status: :completed, audio: fixture_file_upload("audio/sample.mp3", "audio/mp3")) }
      let(:track_ids) { [ track1.id, track2.id ] }

      it "renders AudioPlayButton components" do
        expect(page).to have_css("[data-controller='audio-play-button']", count: 2)
      end

      it "displays track titles" do
        expect(page).to have_content("Test Track")
        expect(page).not_to have_content("Untitled")
      end

      it "displays track numbers" do
        expect(page).to have_content("#1")
        expect(page).to have_content("#2")
      end
    end

    context "with tracks without audio" do
      let(:track1) { create(:track, status: :pending) }
      let(:track_ids) { [ track1.id ] }

      it "shows dash for player column" do
        expect(page).to have_content("-")
        expect(page).not_to have_css("[data-controller='audio-play-button']")
      end
    end
  end
end
