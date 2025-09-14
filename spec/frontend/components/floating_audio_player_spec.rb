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

  describe "media-chrome style adjustments" do
    subject(:rendered) { render_inline(component) }

    it "media-control-bar does not have bg-gray-700 class" do
      expect(rendered).not_to have_css("media-control-bar.bg-gray-700")
    end

    it "media-controller has proper styling classes" do
      expect(rendered).to have_css("media-controller.bg-gray-700")
    end

    it "media-control-bar has text color but no background color" do
      media_bar = rendered.css("media-control-bar").first
      expect(media_bar["class"]).to include("text-gray-300")
      expect(media_bar["class"]).not_to include("bg-gray-700")
    end
  end

  describe "layout restructuring" do
    subject(:rendered) { render_inline(component) }

    it "elements appear in correct order: track info, controls, close button" do
      container = rendered.css("#floating-audio-player").first
      sections = container.css("> div")

      expect(sections[0]["class"]).to include("flex-shrink-0")
      expect(sections[0].css("[data-floating-audio-player-target='trackTitle']")).not_to be_empty

      expect(sections[1]["class"]).to include("flex-1")
      expect(sections[1].css("media-controller")).not_to be_empty

      expect(sections[2]["class"]).to include("flex-shrink-0")
      expect(sections[2].css("[data-action='click->floating-audio-player#close']")).not_to be_empty
    end

    it "control buttons are centered in controls section" do
      expect(rendered).to have_css("div.flex-1 div.justify-center")
    end

    it "container has proper max-width constraint" do
      container = rendered.css("#floating-audio-player").first
      expect(container["class"]).to include("max-w-4xl")
    end

    it "container is centered horizontally" do
      container = rendered.css("#floating-audio-player").first
      expect(container["class"]).to include("mx-auto")
    end
  end

  describe "vertical centering of media-controller" do
    subject(:rendered) { render_inline(component) }

    it "controls section has vertical centering classes" do
      controls_section = rendered.css("div.flex-1.flex.items-center").first
      expect(controls_section).not_to be_nil
      expect(controls_section["class"]).to include("items-center")
    end

    it "media-controller has self-center alignment" do
      media_controller = rendered.css("media-controller").first
      expect(media_controller["class"]).to include("self-center")
    end

    it "media-control-bar maintains vertical alignment" do
      media_bar = rendered.css("media-control-bar").first
      expect(media_bar["class"]).to include("items-center")
    end
  end
end
