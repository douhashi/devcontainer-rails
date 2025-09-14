# frozen_string_literal: true

require "rails_helper"

RSpec.describe InlineAudioPlayer::Component, type: :component do
  let(:track) { create(:track, :completed, :with_audio) }
  let(:content) { create(:content) }

  describe "#initialize" do
    context "with track" do
      subject { described_class.new(track: track) }

      it "sets record to track" do
        expect(subject.record).to eq(track)
      end

      it "sets record_type to :track" do
        expect(subject.record_type).to eq(:track)
      end

      it "sets default size to :medium" do
        expect(subject.size).to eq(:medium)
      end
    end

    context "with content_record" do
      subject { described_class.new(content_record: content) }

      it "sets record to content" do
        expect(subject.record).to eq(content)
      end

      it "sets record_type to :content" do
        expect(subject.record_type).to eq(:content)
      end
    end

    context "with custom size" do
      subject { described_class.new(track: track, size: :small) }

      it "sets the specified size" do
        expect(subject.size).to eq(:small)
      end
    end

    context "with both track and content_record" do
      it "raises ArgumentError" do
        expect {
          described_class.new(track: track, content_record: content)
        }.to raise_error(ArgumentError, "Provide either track or content_record, not both")
      end
    end

    context "without track or content_record" do
      it "raises ArgumentError" do
        expect {
          described_class.new
        }.to raise_error(ArgumentError, "Either track or content_record must be provided")
      end
    end
  end

  describe "#render?" do
    context "with track" do
      context "when track is completed with audio" do
        let(:track) { create(:track, :completed, :with_audio) }
        subject { described_class.new(track: track) }

        it "returns true" do
          expect(subject.render?).to be true
        end
      end

      context "when track is processing" do
        let(:track) { create(:track, :processing) }
        subject { described_class.new(track: track) }

        it "returns false" do
          expect(subject.render?).to be false
        end
      end

      context "when track is completed without audio" do
        let(:track) { create(:track, :completed) }
        subject { described_class.new(track: track) }

        it "returns false" do
          expect(subject.render?).to be false
        end
      end
    end

    context "with content_record" do
      context "when content has completed audio" do
        let(:audio) { create(:audio, :completed, :with_audio, content: content) }
        let(:content) { create(:content) }
        subject { described_class.new(content_record: content) }

        before do
          content.update(audio: audio)
        end

        it "returns true" do
          expect(subject.render?).to be true
        end
      end

      context "when content has no audio" do
        let(:content) { create(:content) }
        subject { described_class.new(content_record: content) }

        it "returns false" do
          expect(subject.render?).to be false
        end
      end

      context "when content has processing audio" do
        let(:content) { create(:content) }
        let(:audio) { create(:audio, :processing, content: content) }
        subject { described_class.new(content_record: content) }

        before do
          content.update(audio: audio)
        end

        it "returns false" do
          expect(subject.render?).to be false
        end
      end
    end
  end

  describe "#audio_url" do
    context "with track" do
      let(:track) { create(:track, :completed, :with_audio) }
      subject { described_class.new(track: track) }

      it "returns the track audio URL" do
        expect(subject.send(:audio_url)).to eq(track.audio.url)
      end
    end

    context "with content_record" do
      let(:audio) { create(:audio, :completed, :with_audio, content: content) }
      let(:content) { create(:content) }
      subject { described_class.new(content_record: content) }

      before do
        content.update(audio: audio)
      end

      it "returns the content audio URL" do
        expect(subject.send(:audio_url)).to eq(content.audio.audio.url)
      end
    end
  end

  describe "#audio_title" do
    context "with track" do
      let(:track) { create(:track, :completed, :with_audio) }
      subject { described_class.new(track: track) }

      before do
        track.metadata["music_title"] = "Test Track"
        track.save
      end

      it "returns the track metadata title" do
        expect(subject.send(:audio_title)).to eq("Test Track")
      end

      context "without metadata_title" do
        before do
          track.metadata.delete("music_title")
          track.save
        end

        it "returns 'Untitled'" do
          expect(subject.send(:audio_title)).to eq("Untitled")
        end
      end
    end

    context "with content_record" do
      let(:content) { create(:content, theme: "Test Theme") }
      subject { described_class.new(content_record: content) }

      it "returns the content theme" do
        expect(subject.send(:audio_title)).to eq("Test Theme")
      end
    end
  end

  describe "rendering" do
    context "when render? is true" do
      let(:track) { create(:track, :completed, :with_audio) }

      it "renders the component" do
        rendered = render_inline(described_class.new(track: track))

        expect(rendered.css("media-controller").count).to eq(1)
      end

      describe "UI design consistency" do
        it "does not have dark background on time range slider" do
          rendered = render_inline(described_class.new(track: track))
          time_range = rendered.css("media-time-range").first

          expect(time_range["class"]).not_to include("bg-gray-700")
        end

        it "does not have dark background on volume range slider" do
          rendered = render_inline(described_class.new(track: track))
          volume_range = rendered.css("media-volume-range").first

          expect(volume_range["class"]).not_to include("bg-gray-700")
        end

        it "has consistent play button styling with other controls" do
          rendered = render_inline(described_class.new(track: track))
          play_button = rendered.css("media-play-button").first

          # Should not have blue background
          expect(play_button["class"]).not_to include("bg-blue-500")
          expect(play_button["class"]).not_to include("bg-blue-600")

          # Should have gray text color like other controls
          expect(play_button["class"]).to include("text-gray-400")
          expect(play_button["class"]).to include("hover:text-white")
        end

        it "has responsive layout classes for preventing wrapping" do
          rendered = render_inline(described_class.new(track: track))
          container = rendered.css("div").first

          # Should have flex-nowrap to prevent wrapping
          expect(container["class"]).to include("flex-nowrap")
          # Should have min-w-0 for proper flex shrinking
          expect(container["class"]).to include("min-w-0")
        end
      end
    end

    context "when render? is false" do
      let(:track) { create(:track, :processing) }

      it "does not render the component" do
        rendered = render_inline(described_class.new(track: track))

        expect(rendered.css("media-controller").count).to eq(0)
      end
    end
  end
end
