require "rails_helper"

RSpec.describe Track, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:content) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "enumerize" do
    it "has status values" do
      expect(Track.status.values).to eq(%w[pending processing completed failed])
    end

    it "sets default status to pending" do
      track = Track.new
      expect(track.status).to eq("pending")
    end

    describe "status predicates" do
      let(:content) { create(:content) }

      it "responds to status predicates" do
        track = Track.new(content: content, status: :pending)
        expect(track.pending?).to be true
        expect(track.processing?).to be false
      end
    end
  end

  describe "scopes" do
    let!(:content) { create(:content) }
    let!(:old_track) { create(:track, content: content, created_at: 2.days.ago) }
    let!(:new_track) { create(:track, content: content, created_at: 1.day.ago) }
    let!(:pending_track) { create(:track, :pending, content: content) }
    let!(:completed_track) { create(:track, :completed, content: content) }

    describe ".recent" do
      it "orders by created_at desc" do
        expect(Track.recent.to_a).to eq([ completed_track, pending_track, new_track, old_track ])
      end
    end

    describe ".by_status" do
      it "filters by status" do
        expect(Track.by_status(:pending)).to include(pending_track)
        expect(Track.by_status(:pending)).not_to include(completed_track)
      end
    end
  end

  describe "metadata" do
    let(:content) { create(:content) }

    it "has default empty JSON object" do
      track = Track.create!(content: content, status: :pending)
      expect(track.metadata).to eq({})
    end

    it "can store JSON data" do
      metadata = { "kie_response" => { "url" => "http://example.com/track.mp3" } }
      track = Track.create!(content: content, status: :completed, metadata: metadata)
      expect(track.metadata).to eq(metadata)
    end
  end
end
