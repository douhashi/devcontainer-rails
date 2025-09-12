# frozen_string_literal: true

require "rails_helper"

RSpec.describe FloatingAudioPlayer::Component, type: :component do
  let(:component) { described_class.new }

  describe "rendered component" do
    subject(:rendered) { render_inline(component) }

    it "renders the floating player container" do
      expect(rendered).to have_css("div#floating-audio-player")
    end

    it "has bottom bar positioning classes" do
      expect(rendered).to have_css("div.fixed.bottom-0.left-0.right-0")
    end

    it "includes Stimulus controller" do
      expect(rendered).to have_css("div[data-controller='floating-audio-player']")
    end

    it "starts hidden" do
      expect(rendered).to have_css("div.hidden")
    end

    it "has proper z-index for floating" do
      expect(rendered).to have_css("div.z-50")
    end

    it "includes media-controller element" do
      expect(rendered).to have_css("media-controller#floating-audio")
    end

    it "includes track title display" do
      expect(rendered).to have_css("[data-floating-audio-player-target='trackTitle']")
    end

    it "includes previous button" do
      expect(rendered).to have_css("button[data-action='click->floating-audio-player#previous']")
    end

    it "includes play/pause button" do
      expect(rendered).to have_css("button[data-floating-audio-player-target='playButton']")
    end

    it "includes next button" do
      expect(rendered).to have_css("button[data-action='click->floating-audio-player#next']")
    end

    it "includes close button" do
      expect(rendered).to have_css("button[data-action='click->floating-audio-player#close']")
    end

    it "has dark theme styling with improved visual separation" do
      expect(rendered).to have_css("div.bg-gray-800")
    end

    it "has border for visual separation" do
      expect(rendered).to have_css("div.border-t.border-gray-700")
    end

    it "has adjusted shadow styling" do
      expect(rendered).to have_css("div.shadow-lg")
    end

    it "has full width bottom bar layout" do
      expect(rendered).to have_css("div.w-full")
    end

    it "has compact height for bottom bar" do
      expect(rendered).to have_css("div.h-16")
    end

    it "has responsive padding" do
      expect(rendered).to have_css("div.px-4")
    end

    it "has slide animation classes" do
      expect(rendered).to have_css("div.transform.translate-y-0")
    end
  end

  describe "horizontal layout" do
    subject(:rendered) { render_inline(component) }

    it "uses flex layout for horizontal arrangement" do
      expect(rendered).to have_css("div.flex.items-center")
    end

    it "includes left section for track info" do
      expect(rendered).to have_css("div.flex-shrink-0")
    end

    it "includes center section for controls" do
      expect(rendered).to have_css("div.flex-1")
    end

    it "includes right section for close button" do
      expect(rendered).to have_css("div.flex-shrink-0")
    end
  end

  describe "media-chrome integration" do
    subject(:rendered) { render_inline(component) }

    it "includes media-controller element" do
      expect(rendered).to have_css("media-controller#floating-audio")
    end

    it "includes media-chrome controls" do
      expect(rendered).to have_css("media-control-bar")
      expect(rendered).to have_css("media-time-range")
      expect(rendered).to have_css("media-time-display")
      expect(rendered).to have_css("media-volume-range")
    end
  end

  describe "volume control" do
    subject(:rendered) { render_inline(component) }

    it "includes volume control in media-chrome" do
      expect(rendered).to have_css("media-volume-range")
    end
  end

  describe "button hover states" do
    subject(:rendered) { render_inline(component) }

    it "control buttons have updated hover state for new background" do
      expect(rendered).to have_css("button.hover\\:bg-gray-700")
    end

    it "close button has updated hover state for new background" do
      close_button = rendered.css("button[data-action='click->floating-audio-player#close']").first
      expect(close_button["class"]).to include("hover:bg-gray-700")
    end
  end
end
