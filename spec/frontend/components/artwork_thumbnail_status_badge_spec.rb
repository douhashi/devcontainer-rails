# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArtworkThumbnailStatusBadge::Component, type: :component do
  let(:content) { create(:content) }

  describe "rendering" do
    context "when status is pending" do
      let(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :pending) }

      it "displays pending status" do
        render_inline(described_class.new(artwork: artwork))

        expect(page).to have_content("未生成")
        expect(page).to have_css(".bg-gray-600.text-gray-200")
        expect(page).not_to have_css("svg.animate-spin")
      end
    end

    context "when status is processing" do
      let(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :processing) }

      it "displays processing status with spinner" do
        render_inline(described_class.new(artwork: artwork))

        expect(page).to have_content("生成中")
        expect(page).to have_css(".bg-yellow-600.text-yellow-200")
        expect(page).to have_css("svg.animate-spin")
      end
    end

    context "when status is completed" do
      let(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :completed) }

      it "displays completed status" do
        render_inline(described_class.new(artwork: artwork))

        expect(page).to have_content("生成済み")
        expect(page).to have_css(".bg-green-600.text-green-200")
        expect(page).not_to have_css("svg.animate-spin")
      end
    end

    context "when status is failed" do
      let(:artwork) { create(:artwork, content: content, thumbnail_generation_status: :failed, thumbnail_generation_error: "Generation error") }

      it "displays failed status" do
        render_inline(described_class.new(artwork: artwork))

        expect(page).to have_content("失敗")
        expect(page).to have_css(".bg-red-600.text-red-200")
        expect(page).not_to have_css("svg.animate-spin")
      end
    end
  end

  describe "#status_text" do
    it "returns Japanese text for each status" do
      component = described_class.new(artwork: double(thumbnail_generation_status: "pending"))
      expect(component.status_text).to eq("未生成")

      component = described_class.new(artwork: double(thumbnail_generation_status: "processing"))
      expect(component.status_text).to eq("生成中")

      component = described_class.new(artwork: double(thumbnail_generation_status: "completed"))
      expect(component.status_text).to eq("生成済み")

      component = described_class.new(artwork: double(thumbnail_generation_status: "failed"))
      expect(component.status_text).to eq("失敗")
    end
  end

  describe "#show_progress_indicator?" do
    it "returns true only for processing status" do
      artwork = double(thumbnail_generation_status: "processing")
      component = described_class.new(artwork: artwork)
      expect(component.show_progress_indicator?).to be true

      artwork = double(thumbnail_generation_status: "completed")
      component = described_class.new(artwork: artwork)
      expect(component.show_progress_indicator?).to be false
    end
  end
end
