# frozen_string_literal: true

require "rails_helper"

RSpec.describe FloatingAudioPlayer::Component, type: :component do
  let(:component) { described_class.new }

  describe "rendered component" do
    subject(:rendered) { render_inline(component) }

    it "renders the floating player container" do
      expect(rendered).to have_css("div#floating-audio-player")
    end

    it "has fixed positioning classes" do
      expect(rendered).to have_css("div.fixed.bottom-4.right-4")
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

    it "includes audio element" do
      expect(rendered).to have_css("audio#floating-audio")
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

    it "has dark theme styling" do
      expect(rendered).to have_css("div.bg-gray-900")
    end

    it "has rounded corners and shadow" do
      expect(rendered).to have_css("div.rounded-lg.shadow-2xl")
    end

    it "is responsive for mobile" do
      expect(rendered).to have_css("div.w-full.sm\\:w-96")
    end
  end

  describe "Plyr integration" do
    subject(:rendered) { render_inline(component) }

    it "includes data attributes for Plyr configuration" do
      expect(rendered).to have_css("audio[data-plyr-config]")
    end

    it "configures compact controls" do
      rendered_html = rendered.to_html
      expect(rendered_html).to include("controls")
      expect(rendered_html).to include("play")
      expect(rendered_html).to include("progress")
      expect(rendered_html).to include("current-time")
    end
  end
end
