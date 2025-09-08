# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackStatusBadge::Component, type: :component do
  let(:track) { build(:track, status: status) }
  let(:component) { described_class.new(track: track) }

  describe "status display" do
    context "when status is pending" do
      let(:status) { :pending }

      it "displays pending status with correct styling" do
        render_inline(component)

        expect(page).to have_text("待機中")
        expect(page).to have_css("span.bg-gray-600.text-gray-200")
      end

      it "includes accessibility attributes" do
        render_inline(component)

        expect(page).to have_css('span[role="status"]')
        expect(page).to have_css('span[aria-label*="ステータス: 待機中"]')
      end
    end

    context "when status is processing" do
      let(:status) { :processing }

      it "displays processing status with progress indicator" do
        render_inline(component)

        expect(page).to have_text("処理中")
        expect(page).to have_css("span.bg-yellow-600.text-yellow-200")
        expect(page).to have_css("svg.animate-spin")
      end

      it "includes accessibility attributes" do
        render_inline(component)

        expect(page).to have_css('span[role="status"]')
        expect(page).to have_css('span[aria-label*="ステータス: 処理中"]')
        expect(page).to have_css('svg[aria-hidden="true"]')
      end
    end

    context "when status is completed" do
      let(:status) { :completed }

      it "displays completed status with success styling" do
        render_inline(component)

        expect(page).to have_text("完了")
        expect(page).to have_css("span.bg-green-600.text-green-200")
        expect(page).not_to have_css("svg.animate-spin")
      end

      it "includes accessibility attributes" do
        render_inline(component)

        expect(page).to have_css('span[role="status"]')
        expect(page).to have_css('span[aria-label*="ステータス: 完了"]')
      end
    end

    context "when status is failed" do
      let(:status) { :failed }

      it "displays failed status with error styling" do
        render_inline(component)

        expect(page).to have_text("失敗")
        expect(page).to have_css("span.bg-red-600.text-red-200")
        expect(page).not_to have_css("svg.animate-spin")
      end

      it "includes accessibility attributes" do
        render_inline(component)

        expect(page).to have_css('span[role="status"]')
        expect(page).to have_css('span[aria-label*="ステータス: 失敗"]')
      end
    end
  end

  describe "#status_text" do
    it "returns correct Japanese text for each status" do
      expect(described_class.new(track: build(:track, status: :pending)).status_text).to eq("待機中")
      expect(described_class.new(track: build(:track, status: :processing)).status_text).to eq("処理中")
      expect(described_class.new(track: build(:track, status: :completed)).status_text).to eq("完了")
      expect(described_class.new(track: build(:track, status: :failed)).status_text).to eq("失敗")
    end

    it "returns the raw status for unknown statuses" do
      track = build(:track)
      # Manually set an unknown status (bypassing enum validation in tests)
      allow(track).to receive(:status).and_return("unknown")
      component = described_class.new(track: track)

      expect(component.status_text).to eq("unknown")
    end
  end

  describe "#status_classes" do
    it "returns appropriate CSS classes for each status" do
      expect(described_class.new(track: build(:track, status: :pending)).status_classes).to include("bg-gray-600", "text-gray-200")
      expect(described_class.new(track: build(:track, status: :processing)).status_classes).to include("bg-yellow-600", "text-yellow-200")
      expect(described_class.new(track: build(:track, status: :completed)).status_classes).to include("bg-green-600", "text-green-200")
      expect(described_class.new(track: build(:track, status: :failed)).status_classes).to include("bg-red-600", "text-red-200")
    end

    it "always includes base classes" do
      %i[pending processing completed failed].each do |status|
        classes = described_class.new(track: build(:track, status: status)).status_classes
        expect(classes).to include("px-2", "inline-flex", "text-xs", "leading-5", "font-semibold", "rounded-full")
      end
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

  describe "#aria_label" do
    it "returns appropriate aria-label for each status" do
      track = build(:track, id: 123, status: :pending)
      component = described_class.new(track: track)
      expect(component.aria_label).to eq("トラック123のステータス: 待機中")
    end

    it "works with different track IDs and statuses" do
      track = build(:track, id: 456, status: :processing)
      component = described_class.new(track: track)
      expect(component.aria_label).to eq("トラック456のステータス: 処理中")
    end
  end
end
