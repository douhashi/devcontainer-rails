# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackStatus::Component, type: :component do
  let(:track) { build(:track, status: status) }
  let(:component) { described_class.new(track: track) }

  describe "status display" do
    context "when status is pending" do
      let(:status) { :pending }

      it "displays pending status with correct styling" do
        render_inline(component)

        expect(page).to have_css(".track-status.track-status--pending")
        expect(page).to have_text("待機中")
        expect(page).to have_css(".bg-gray-100")
      end
    end

    context "when status is processing" do
      let(:status) { :processing }

      it "displays processing status with progress indicator" do
        render_inline(component)

        expect(page).to have_css(".track-status.track-status--processing")
        expect(page).to have_text("生成中")
        expect(page).to have_css(".bg-blue-100")
        expect(page).to have_css(".animate-pulse")
      end
    end

    context "when status is completed" do
      let(:status) { :completed }

      it "displays completed status with success styling" do
        render_inline(component)

        expect(page).to have_css(".track-status.track-status--completed")
        expect(page).to have_text("完了")
        expect(page).to have_css(".bg-green-100")
      end
    end

    context "when status is failed" do
      let(:status) { :failed }

      it "displays failed status with error styling" do
        render_inline(component)

        expect(page).to have_css(".track-status.track-status--failed")
        expect(page).to have_text("失敗")
        expect(page).to have_css(".bg-red-100")
      end
    end
  end

  describe "#status_text" do
    it "returns correct Japanese text for each status" do
      expect(described_class.new(track: build(:track, status: :pending)).status_text).to eq("待機中")
      expect(described_class.new(track: build(:track, status: :processing)).status_text).to eq("生成中")
      expect(described_class.new(track: build(:track, status: :completed)).status_text).to eq("完了")
      expect(described_class.new(track: build(:track, status: :failed)).status_text).to eq("失敗")
    end
  end

  describe "#status_classes" do
    it "returns appropriate CSS classes for each status" do
      expect(described_class.new(track: build(:track, status: :pending)).status_classes).to include("bg-gray-100", "text-gray-700")
      expect(described_class.new(track: build(:track, status: :processing)).status_classes).to include("bg-blue-100", "text-blue-700", "animate-pulse")
      expect(described_class.new(track: build(:track, status: :completed)).status_classes).to include("bg-green-100", "text-green-700")
      expect(described_class.new(track: build(:track, status: :failed)).status_classes).to include("bg-red-100", "text-red-700")
    end
  end

  describe "#show_progress_indicator?" do
    it "returns true only for processing status" do
      expect(described_class.new(track: build(:track, status: :pending)).show_progress_indicator?).to be false
      expect(described_class.new(track: build(:track, status: :processing)).show_progress_indicator?).to be true
      expect(described_class.new(track: build(:track, status: :completed)).show_progress_indicator?).to be false
      expect(described_class.new(track: build(:track, status: :failed)).show_progress_indicator?).to be false
    end
  end
end
