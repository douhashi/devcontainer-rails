# frozen_string_literal: true

require "rails_helper"

RSpec.describe "TrackRow with InlineAudioPlayer", type: :component do
  describe "TrackRow::Component" do
    let(:content) { create(:content, theme: "Test Content") }
    let(:track) { create(:track, :completed, :with_audio, content: content) }

    describe "#play_button_component" do
      subject { TrackRow::Component.new(track: track) }

      context "when track has audio" do
        it "returns InlineAudioPlayer component" do
          player = subject.send(:play_button_component)
          expect(player).to be_a(InlineAudioPlayer::Component)
          expect(player.track).to eq(track)
        end
      end

      context "when track is processing" do
        let(:track) { create(:track, :processing, content: content) }

        it "returns nil" do
          expect(subject.send(:play_button_component)).to be_nil
        end
      end

      context "when track has no audio" do
        let(:track) { create(:track, :completed, content: content) }

        before do
          track.audio.purge if track.audio&.attached?
        end

        it "returns nil" do
          expect(subject.send(:play_button_component)).to be_nil
        end
      end
    end

    describe "rendering" do
      it "renders InlineAudioPlayer instead of AudioPlayButton" do
        rendered = render_inline(TrackRow::Component.new(track: track))

        # Should render InlineAudioPlayer's media-controller
        expect(rendered.css("media-controller").count).to eq(1)

        # Should not render old AudioPlayButton
        expect(rendered.css("[data-controller='audio-play-button']").count).to eq(0)
      end
    end
  end

  describe "ExtendedTrackRow::Component" do
    let(:content) { create(:content, theme: "Test Content") }
    let(:track) { create(:track, :completed, :with_audio, content: content) }
    let(:music_generation) { create(:music_generation) }

    describe "#play_button_component" do
      subject { ExtendedTrackRow::Component.new(track: track, music_generation: music_generation) }

      context "when track has audio" do
        it "returns InlineAudioPlayer component" do
          player = subject.send(:play_button_component)
          expect(player).to be_a(InlineAudioPlayer::Component)
          expect(player.track).to eq(track)
        end
      end
    end

    describe "rendering" do
      it "renders InlineAudioPlayer" do
        rendered = render_inline(ExtendedTrackRow::Component.new(track: track, music_generation: music_generation))

        # Should render InlineAudioPlayer's media-controller
        expect(rendered.css("media-controller").count).to eq(1)
      end
    end
  end

  describe "AudioUsedTracksTable::Component" do
    let(:track1) { create(:track, :completed, :with_audio) }
    let(:track2) { create(:track, :completed, :with_audio) }
    let(:track3) { create(:track, :completed, :with_audio) }
    let(:audio) { create(:audio, :completed, metadata: { "selected_track_ids" => [ track1.id, track2.id, track3.id ] }) }

    describe "rendering" do
      it "renders InlineAudioPlayer for each content with audio" do
        rendered = render_inline(AudioUsedTracksTable::Component.new(audio: audio))

        # Should render InlineAudioPlayer for each track
        expect(rendered.css("media-controller").count).to eq(3)
      end
    end
  end
end
