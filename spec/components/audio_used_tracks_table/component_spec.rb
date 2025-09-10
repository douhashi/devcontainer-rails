# frozen_string_literal: true

require "rails_helper"

RSpec.describe AudioUsedTracksTable::Component, type: :component do
  let(:content) { create(:content) }
  let(:audio) { create(:audio, content: content, status: :completed) }
  let(:tracks) { create_list(:track, 3, content: content, status: :completed, duration_sec: 180) }

  describe "#initialize" do
    context "with valid audio" do
      it "initializes with audio object" do
        component = described_class.new(audio: audio)
        expect(component.audio).to eq(audio)
      end
    end

    context "with nil audio" do
      it "initializes with nil audio" do
        component = described_class.new(audio: nil)
        expect(component.audio).to be_nil
      end
    end
  end

  describe "#selected_tracks" do
    context "when audio has selected_track_ids in metadata" do
      before do
        audio.metadata = { "selected_track_ids" => tracks.map(&:id) }
        audio.save!
      end

      it "returns tracks in the order specified by selected_track_ids" do
        component = described_class.new(audio: audio)
        expect(component.selected_tracks.map(&:id)).to eq(tracks.map(&:id))
      end

      it "preserves the order of track IDs" do
        # Reverse the order in metadata
        audio.metadata = { "selected_track_ids" => tracks.map(&:id).reverse }
        audio.save!

        component = described_class.new(audio: audio)
        expect(component.selected_tracks.map(&:id)).to eq(tracks.map(&:id).reverse)
      end

      it "filters out non-existent track IDs" do
        audio.metadata = { "selected_track_ids" => tracks.map(&:id) + [ 999999 ] }
        audio.save!

        component = described_class.new(audio: audio)
        expect(component.selected_tracks.map(&:id)).to eq(tracks.map(&:id))
      end
    end

    context "when audio has no selected_track_ids" do
      it "returns empty array when metadata is nil" do
        audio.metadata = nil
        audio.save!

        component = described_class.new(audio: audio)
        expect(component.selected_tracks).to eq([])
      end

      it "returns empty array when metadata is empty hash" do
        audio.metadata = {}
        audio.save!

        component = described_class.new(audio: audio)
        expect(component.selected_tracks).to eq([])
      end

      it "returns empty array when selected_track_ids is nil" do
        audio.metadata = { "selected_track_ids" => nil }
        audio.save!

        component = described_class.new(audio: audio)
        expect(component.selected_tracks).to eq([])
      end

      it "returns empty array when selected_track_ids is empty array" do
        audio.metadata = { "selected_track_ids" => [] }
        audio.save!

        component = described_class.new(audio: audio)
        expect(component.selected_tracks).to eq([])
      end
    end

    context "when audio is nil" do
      it "returns empty array" do
        component = described_class.new(audio: nil)
        expect(component.selected_tracks).to eq([])
      end
    end
  end

  describe "#has_tracks?" do
    context "when tracks exist" do
      before do
        audio.metadata = { "selected_track_ids" => tracks.map(&:id) }
        audio.save!
      end

      it "returns true" do
        component = described_class.new(audio: audio)
        expect(component.has_tracks?).to be true
      end
    end

    context "when no tracks exist" do
      before do
        audio.metadata = { "selected_track_ids" => [] }
        audio.save!
      end

      it "returns false" do
        component = described_class.new(audio: audio)
        expect(component.has_tracks?).to be false
      end
    end

    context "when audio is nil" do
      it "returns false" do
        component = described_class.new(audio: nil)
        expect(component.has_tracks?).to be false
      end
    end
  end

  describe "#should_display?" do
    context "when audio is completed and has tracks" do
      before do
        audio.status = :completed
        audio.metadata = { "selected_track_ids" => tracks.map(&:id) }
        audio.save!
      end

      it "returns true" do
        component = described_class.new(audio: audio)
        expect(component.should_display?).to be true
      end
    end

    context "when audio is completed but has no tracks" do
      before do
        audio.status = :completed
        audio.metadata = { "selected_track_ids" => [] }
        audio.save!
      end

      it "returns false" do
        component = described_class.new(audio: audio)
        expect(component.should_display?).to be false
      end
    end

    context "when audio is not completed" do
      [ :pending, :processing, :failed ].each do |status|
        context "when status is #{status}" do
          before do
            audio.status = status
            audio.metadata = { "selected_track_ids" => tracks.map(&:id) }
            audio.save!
          end

          it "returns false" do
            component = described_class.new(audio: audio)
            expect(component.should_display?).to be false
          end
        end
      end
    end

    context "when audio is nil" do
      it "returns false" do
        component = described_class.new(audio: nil)
        expect(component.should_display?).to be false
      end
    end
  end

  describe "#empty_message" do
    it "returns appropriate message" do
      component = described_class.new(audio: audio)
      expect(component.empty_message).to eq("使用Track情報なし")
    end
  end

  describe "#track_row_data" do
    before do
      audio.metadata = { "selected_track_ids" => tracks.map(&:id) }
      audio.save!
    end

    it "returns track data with correct numbering" do
      component = described_class.new(audio: audio)
      row_data = component.track_row_data

      expect(row_data.size).to eq(3)
      expect(row_data[0][:track_number]).to eq(1)
      expect(row_data[1][:track_number]).to eq(2)
      expect(row_data[2][:track_number]).to eq(3)
    end

    it "includes track object in each row" do
      component = described_class.new(audio: audio)
      row_data = component.track_row_data

      expect(row_data[0][:track]).to eq(tracks[0])
      expect(row_data[1][:track]).to eq(tracks[1])
      expect(row_data[2][:track]).to eq(tracks[2])
    end
  end
end
