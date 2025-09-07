# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackCounter::Component, type: :component do
  let(:content) { build(:content) }
  let(:component) { described_class.new(content_record: content, current_count: current_count, max_count: max_count) }
  let(:current_count) { 5 }
  let(:max_count) { 100 }

  describe "counter display" do
    it "displays current and max count" do
      render_inline(component)

      expect(page).to have_text("5 / 100")
      expect(page).to have_css(".track-counter")
    end

    it "displays remaining count" do
      render_inline(component)

      expect(page).to have_text("残り: 95件")
    end

    context "when approaching limit" do
      let(:current_count) { 95 }

      it "displays warning styling" do
        render_inline(component)

        expect(page).to have_css(".text-red-600")
        expect(page).to have_text("残り: 5件")
      end
    end

    context "when at limit" do
      let(:current_count) { 100 }

      it "displays error styling" do
        render_inline(component)

        expect(page).to have_css(".text-red-600")
        expect(page).to have_text("上限に達しました")
      end
    end
  end

  describe "#remaining_count" do
    it "calculates remaining tracks correctly" do
      expect(component.remaining_count).to eq(95)
    end
  end

  describe "#progress_percentage" do
    it "calculates percentage correctly" do
      expect(component.progress_percentage).to eq(5)
    end

    context "when at max" do
      let(:current_count) { 100 }

      it "returns 100" do
        expect(component.progress_percentage).to eq(100)
      end
    end
  end

  describe "#status_color" do
    context "when usage is low" do
      let(:current_count) { 50 }

      it "returns green color" do
        expect(component.status_color).to eq("green")
      end
    end

    context "when usage is medium" do
      let(:current_count) { 85 }

      it "returns yellow color" do
        expect(component.status_color).to eq("yellow")
      end
    end

    context "when usage is high" do
      let(:current_count) { 95 }

      it "returns red color" do
        expect(component.status_color).to eq("red")
      end
    end
  end

  describe "#can_generate_more?" do
    context "when below limit" do
      let(:current_count) { 99 }

      it "returns true" do
        expect(component.can_generate_more?).to be true
      end
    end

    context "when at limit" do
      let(:current_count) { 100 }

      it "returns false" do
        expect(component.can_generate_more?).to be false
      end
    end
  end
end
