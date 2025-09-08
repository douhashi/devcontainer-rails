require "rails_helper"

RSpec.describe Track, type: :model do
  describe "ransackable attributes" do
    it "defines searchable attributes" do
      expect(Track.ransackable_attributes).to include(
        "status",
        "created_at"
      )
    end

    it "defines searchable associations" do
      expect(Track.ransackable_associations).to include("content")
    end
  end

  describe "custom ransackers" do
    let!(:content1) { create(:content, theme: "Relaxing BGM") }
    let!(:content2) { create(:content, theme: "Focus Music") }
    let!(:track1) do
      create(:track, content: content1, metadata: { music_title: "Morning Coffee" })
    end
    let!(:track2) do
      create(:track, content: content2, metadata: { music_title: "Deep Work" })
    end

    describe "content_theme_cont ransacker" do
      it "searches by content theme" do
        result = Track.joins(:content).ransack(content_theme_cont: "Relax").result
        expect(result).to include(track1)
        expect(result).not_to include(track2)
      end
    end

    describe "music_title_cont ransacker" do
      it "searches by music title in metadata" do
        result = Track.ransack(music_title_cont: "Coffee").result
        expect(result).to include(track1)
        expect(result).not_to include(track2)
      end
    end
  end

  describe "search integration" do
    let!(:content) { create(:content, theme: "Test Content") }
    let!(:pending_track) do
      create(:track, content: content, status: "pending", metadata: { music_title: "Song A" })
    end
    let!(:completed_track) do
      create(:track, content: content, status: "completed", metadata: { music_title: "Song B" })
    end
    let!(:old_track) do
      create(:track, content: content, status: "completed", created_at: 1.month.ago)
    end

    it "filters by status" do
      result = Track.ransack(status_eq: "pending").result
      expect(result).to include(pending_track)
      expect(result).not_to include(completed_track)
    end

    it "filters by created_at range" do
      result = Track.ransack(created_at_gteq: 1.week.ago).result
      expect(result).to include(pending_track, completed_track)
      expect(result).not_to include(old_track)
    end

    it "combines multiple search criteria" do
      result = Track.ransack(
        status_eq: "completed",
        created_at_gteq: 1.week.ago
      ).result
      expect(result).to include(completed_track)
      expect(result).not_to include(pending_track, old_track)
    end
  end
end
