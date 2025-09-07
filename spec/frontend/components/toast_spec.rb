# frozen_string_literal: true

require "rails_helper"

RSpec.describe Toast::Component, type: :component do
  let(:component) { described_class.new(message: message, type: type) }
  let(:message) { "Test message" }
  let(:type) { :success }

  describe "toast display" do
    context "when type is success" do
      let(:type) { :success }

      it "displays success toast with correct styling" do
        render_inline(component)

        expect(page).to have_css(".toast.toast--success")
        expect(page).to have_text("Test message")
        expect(page).to have_css(".bg-green-50")
        expect(page).to have_css(".text-green-800")
      end
    end

    context "when type is error" do
      let(:type) { :error }

      it "displays error toast with correct styling" do
        render_inline(component)

        expect(page).to have_css(".toast.toast--error")
        expect(page).to have_text("Test message")
        expect(page).to have_css(".bg-red-50")
        expect(page).to have_css(".text-red-800")
      end
    end

    context "when type is info" do
      let(:type) { :info }

      it "displays info toast with correct styling" do
        render_inline(component)

        expect(page).to have_css(".toast.toast--info")
        expect(page).to have_text("Test message")
        expect(page).to have_css(".bg-blue-50")
        expect(page).to have_css(".text-blue-800")
      end
    end

    context "when type is warning" do
      let(:type) { :warning }

      it "displays warning toast with correct styling" do
        render_inline(component)

        expect(page).to have_css(".toast.toast--warning")
        expect(page).to have_text("Test message")
        expect(page).to have_css(".bg-yellow-50")
        expect(page).to have_css(".text-yellow-800")
      end
    end
  end

  describe "stimulus controller" do
    it "includes toast controller data attributes" do
      render_inline(component)

      expect(page).to have_css('[data-controller="toast"]')
      expect(page).to have_css('[data-toast-duration-value="5000"]')
    end

    it "includes close button with action" do
      render_inline(component)

      expect(page).to have_css('[data-action="click->toast#close"]')
    end
  end

  describe "#toast_classes" do
    it "returns appropriate CSS classes for each type" do
      expect(described_class.new(message: "test", type: :success).toast_classes).to include("bg-green-50", "text-green-800")
      expect(described_class.new(message: "test", type: :error).toast_classes).to include("bg-red-50", "text-red-800")
      expect(described_class.new(message: "test", type: :info).toast_classes).to include("bg-blue-50", "text-blue-800")
      expect(described_class.new(message: "test", type: :warning).toast_classes).to include("bg-yellow-50", "text-yellow-800")
    end
  end

  describe "#icon_for_type" do
    it "returns appropriate icon for each type" do
      expect(described_class.new(message: "test", type: :success).icon_for_type).to include("✓")
      expect(described_class.new(message: "test", type: :error).icon_for_type).to include("✕")
      expect(described_class.new(message: "test", type: :info).icon_for_type).to include("ℹ")
      expect(described_class.new(message: "test", type: :warning).icon_for_type).to include("⚠")
    end
  end
end
