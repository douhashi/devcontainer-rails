# frozen_string_literal: true

require "rails_helper"

RSpec.describe AudioPlayButton::Component, type: :component do
  let(:content) { create(:content) }
  let(:audio) { create(:audio, :completed, content: content) }
  let(:options) { { content_record: content } }
  let(:component) { AudioPlayButton::Component.new(**options) }

  describe "when audio is present and completed" do
    before do
      allow(audio).to receive_message_chain(:audio, :url).and_return('/test/audio.mp3')
      allow(audio).to receive_message_chain(:audio, :present?).and_return(true)
      content.audio = audio
    end

    it "renders a button using ButtonComponent" do
      result = render_inline(component)

      expect(result.css("button")).to be_present
      expect(result.css("button").first.attributes["class"].value).to include("rounded-full")
      expect(result.css("button").first.attributes["class"].value).to include("bg-blue-600")
    end

    it "includes play icon using IconComponent" do
      result = render_inline(component)

      expect(result.css("svg")).to be_present
      expect(result.css("svg path")).to be_present
    end

    it "has audio-play-button controller data attributes" do
      result = render_inline(component)
      button = result.css("button").first

      expect(button.attributes["data-controller"].value).to include("audio-play-button")
      expect(button.attributes["data-audio-play-button-content-id-value"].value).to eq(content.id.to_s)
      expect(button.attributes["data-audio-play-button-audio-url-value"].value).to eq("/test/audio.mp3")
    end

    context "with different sizes" do
      it "renders small size" do
        component = AudioPlayButton::Component.new(content_record: content, size: :small)
        result = render_inline(component)

        expect(result.css("button")).to be_present
        expect(result.css("button").first.attributes["class"].value).to include("w-8 h-8")
      end

      it "renders large size" do
        component = AudioPlayButton::Component.new(content_record: content, size: :large)
        result = render_inline(component)

        expect(result.css("button")).to be_present
        expect(result.css("button").first.attributes["class"].value).to include("w-12 h-12")
      end
    end
  end

  describe "when audio is not available" do
    before do
      content.audio = nil
    end

    it "does not render" do
      expect(component.render?).to be false
    end
  end
end
