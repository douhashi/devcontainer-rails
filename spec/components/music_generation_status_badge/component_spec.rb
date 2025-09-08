# frozen_string_literal: true

require "rails_helper"

RSpec.describe MusicGenerationStatusBadge::Component, type: :component do
  let(:music_generation) { create(:music_generation, status: status) }
  let(:component) { described_class.new(music_generation: music_generation) }

  describe "#status_text" do
    context "when status is pending" do
      let(:status) { :pending }

      it "returns 待機中" do
        expect(component.status_text).to eq("待機中")
      end
    end

    context "when status is processing" do
      let(:status) { :processing }

      it "returns 処理中" do
        expect(component.status_text).to eq("処理中")
      end
    end

    context "when status is completed" do
      let(:status) { :completed }

      it "returns 完了" do
        expect(component.status_text).to eq("完了")
      end
    end

    context "when status is failed" do
      let(:status) { :failed }

      it "returns 失敗" do
        expect(component.status_text).to eq("失敗")
      end
    end
  end

  describe "#status_classes" do
    context "when status is pending" do
      let(:status) { :pending }

      it "returns gray style classes" do
        expect(component.status_classes).to include("bg-gray-600")
        expect(component.status_classes).to include("text-gray-200")
      end
    end

    context "when status is processing" do
      let(:status) { :processing }

      it "returns yellow style classes" do
        expect(component.status_classes).to include("bg-yellow-600")
        expect(component.status_classes).to include("text-yellow-200")
      end
    end

    context "when status is completed" do
      let(:status) { :completed }

      it "returns green style classes" do
        expect(component.status_classes).to include("bg-green-600")
        expect(component.status_classes).to include("text-green-200")
      end
    end

    context "when status is failed" do
      let(:status) { :failed }

      it "returns red style classes" do
        expect(component.status_classes).to include("bg-red-600")
        expect(component.status_classes).to include("text-red-200")
      end
    end

    context "for all statuses" do
      let(:status) { :pending }

      it "includes base classes" do
        expect(component.status_classes).to include("px-2")
        expect(component.status_classes).to include("inline-flex")
        expect(component.status_classes).to include("text-xs")
        expect(component.status_classes).to include("leading-5")
        expect(component.status_classes).to include("font-semibold")
        expect(component.status_classes).to include("rounded-full")
      end
    end
  end

  describe "#show_progress_indicator?" do
    context "when status is processing" do
      let(:status) { :processing }

      it "returns true" do
        expect(component.show_progress_indicator?).to be true
      end
    end

    context "when status is not processing" do
      let(:status) { :pending }

      it "returns false" do
        expect(component.show_progress_indicator?).to be false
      end
    end
  end

  describe "#aria_label" do
    let(:status) { :completed }

    it "returns accessible label" do
      expect(component.aria_label).to eq("音楽生成#{music_generation.id}のステータス: 完了")
    end
  end

  describe "rendering" do
    context "when status is processing" do
      let(:status) { :processing }

      it "renders with progress indicator" do
        render_inline(component)

        expect(page).to have_css(".animate-pulse")
        expect(page).to have_text("処理中")
      end
    end

    context "when status is completed" do
      let(:status) { :completed }

      it "renders without progress indicator" do
        render_inline(component)

        expect(page).not_to have_css(".animate-pulse")
        expect(page).to have_text("完了")
      end
    end
  end
end
