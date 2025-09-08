# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AudioPlayer::Component, type: :component do
  let(:content) { create(:content) }

  describe "with completed track and audio present" do
    let(:track) { create(:track, :completed, content: content) }

    before do
      # Shrineでaudio添付をモック
      allow(track).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))
    end

    it "renders audio player" do
      render_inline described_class.new(track: track)

      expect(page).to have_css("audio[data-audio-player-target='player']")
      expect(page).to have_css("audio[preload='none']")
      expect(page).to have_css("audio[data-audio-url='https://example.com/test.mp3']")
    end

    it "includes Plyr initialization data" do
      render_inline described_class.new(track: track)

      expect(page).to have_css("div[data-controller='audio-player']")
    end
  end

  describe "with completed track but no audio" do
    let(:track) { create(:track, :completed, content: content) }

    before do
      allow(track).to receive(:audio).and_return(double(present?: false))
    end

    it "does not render audio player" do
      render_inline described_class.new(track: track)

      expect(page).not_to have_css("audio")
    end
  end

  describe "with failed track" do
    let(:track) { create(:track, :failed, content: content) }

    it "does not render audio player" do
      render_inline described_class.new(track: track)

      expect(page).not_to have_css("audio")
    end
  end

  describe "with pending track" do
    let(:track) { create(:track, :pending, content: content) }

    it "does not render audio player" do
      render_inline described_class.new(track: track)

      expect(page).not_to have_css("audio")
    end
  end

  describe "with processing track" do
    let(:track) { create(:track, :processing, content: content) }

    it "does not render audio player" do
      render_inline described_class.new(track: track)

      expect(page).not_to have_css("audio")
    end
  end

  describe "with autoplay option" do
    let(:track) { create(:track, :completed, content: content) }

    before do
      allow(track).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))
    end

    it "sets autoplay data attribute when autoplay is true" do
      render_inline described_class.new(track: track, autoplay: true)

      expect(page).to have_css("div[data-audio-player-autoplay-value='true']")
    end

    it "defaults to false when autoplay is not specified" do
      render_inline described_class.new(track: track)

      expect(page).to have_css("div[data-audio-player-autoplay-value='false']")
    end
  end
end
