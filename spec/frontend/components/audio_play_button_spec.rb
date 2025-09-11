# frozen_string_literal: true

require "rails_helper"

RSpec.describe AudioPlayButton::Component, type: :component do
  describe "with Content record" do
    let(:content) { create(:content) }
    let(:audio) { create(:audio, :completed, content: content) }
    let(:options) { { content_record: content } }
    let(:component) { AudioPlayButton::Component.new(**options) }

    describe "when audio is present and completed" do
      before do
        audio_attachment = double('audio_attachment', url: '/test/audio.mp3', present?: true)
        allow(audio).to receive(:audio).and_return(audio_attachment)
        content.audio = audio
      end

      it "renders a button using ButtonComponent" do
        result = render_inline(component)

        expect(result.css("button")).to be_present
        expect(result.css("button").first.attributes["class"].value).to include("rounded-full")
        expect(result.css("button").first.attributes["class"].value).to include("hover:bg-blue-500/20")
      end

      it "includes play icon using IconComponent" do
        result = render_inline(component)

        expect(result.css("svg")).to be_present
        # playアイコンは1つのpath要素を持つ（三角形の再生ボタン）
        expect(result.css("svg path").length).to eq(1)
      end

      it "applies blue color styling to the icon" do
        result = render_inline(component)
        svg = result.css("svg").first

        expect(svg.attributes["class"].value).to include("text-blue-400")
      end

      it "has unified audio-play-button controller data attributes" do
        result = render_inline(component)
        button = result.css("button").first

        expect(button.attributes["data-controller"].value).to include("audio-play-button")
        expect(button.attributes["data-audio-play-button-id-value"].value).to eq(content.id.to_s)
        expect(button.attributes["data-audio-play-button-title-value"].value).to eq(content.theme)
        expect(button.attributes["data-audio-play-button-audio-url-value"].value).to eq("/test/audio.mp3")
        expect(button.attributes["data-audio-play-button-type-value"].value).to eq("content")
      end

      context "with different sizes" do
        it "renders small size" do
          component = AudioPlayButton::Component.new(content_record: content, size: :small)
          result = render_inline(component)

          expect(result.css("button")).to be_present
          expect(result.css("button").first.attributes["class"].value).to include("w-6 h-6")
        end

        it "renders large size" do
          component = AudioPlayButton::Component.new(content_record: content, size: :large)
          result = render_inline(component)

          expect(result.css("button")).to be_present
          expect(result.css("button").first.attributes["class"].value).to include("w-10 h-10")
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

  describe "with Track record" do
    let(:content) { create(:content) }
    let(:track) { create(:track, :completed, content: content) }
    let(:options) { { track: track } }
    let(:component) { AudioPlayButton::Component.new(**options) }

    describe "when audio is present and completed" do
      before do
        allow(track).to receive_message_chain(:audio, :url).and_return('/test/track_audio.mp3')
        allow(track).to receive_message_chain(:audio, :present?).and_return(true)
      end

      it "renders a button using ButtonComponent" do
        result = render_inline(component)

        expect(result.css("button")).to be_present
        expect(result.css("button").first.attributes["class"].value).to include("rounded-full")
        expect(result.css("button").first.attributes["class"].value).to include("hover:bg-blue-500/20")
      end

      it "includes play icon using IconComponent" do
        result = render_inline(component)

        expect(result.css("svg")).to be_present
        # playアイコンは1つのpath要素を持つ（三角形の再生ボタン）
        expect(result.css("svg path").length).to eq(1)
      end

      it "applies blue color styling to the icon" do
        result = render_inline(component)
        svg = result.css("svg").first

        expect(svg.attributes["class"].value).to include("text-blue-400")
      end

      it "has unified audio-play-button controller data attributes for track" do
        result = render_inline(component)
        button = result.css("button").first

        expect(button.attributes["data-controller"].value).to include("audio-play-button")
        expect(button.attributes["data-audio-play-button-id-value"].value).to eq(track.id.to_s)
        expect(button.attributes["data-audio-play-button-title-value"].value).to eq(track.metadata_title || "Untitled")
        expect(button.attributes["data-audio-play-button-audio-url-value"].value).to eq("/test/track_audio.mp3")
        expect(button.attributes["data-audio-play-button-type-value"].value).to eq("track")
        expect(button.attributes["data-audio-play-button-content-id-value"].value).to eq(content.id.to_s)
        expect(button.attributes["data-audio-play-button-content-title-value"].value).to eq(content.theme)
      end
    end

    describe "when track is not completed" do
      let(:track) { create(:track, content: content) }

      it "does not render" do
        expect(component.render?).to be false
      end
    end

    describe "when track has no audio" do
      before do
        track.audio = nil
      end

      it "does not render" do
        expect(component.render?).to be false
      end
    end
  end

  describe "with invalid arguments" do
    it "raises error when both track and content are provided" do
      track = create(:track)
      content = create(:content)

      expect {
        AudioPlayButton::Component.new(track: track, content_record: content)
      }.to raise_error(ArgumentError, "Provide either track or content_record, not both")
    end

    it "raises error when neither track nor content are provided" do
      expect {
        AudioPlayButton::Component.new(size: :medium)
      }.to raise_error(ArgumentError, "Either track or content_record must be provided")
    end
  end
end
