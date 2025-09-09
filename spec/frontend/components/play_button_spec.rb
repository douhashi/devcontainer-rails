# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlayButton::Component, type: :component do
  let(:track) { create(:track, :completed, :with_audio) }
  let(:content) { track.content }
  let(:component) { described_class.new(track: track) }

  describe "#render?" do
    context "when track is completed with audio" do
      it "returns true" do
        expect(component.render?).to be true
      end
    end

    context "when track is not completed" do
      let(:track) { create(:track, :processing) }

      it "returns false" do
        expect(component.render?).to be false
      end
    end

    context "when track has no audio" do
      let(:track) { create(:track, :completed) }

      it "returns false" do
        expect(component.render?).to be false
      end
    end
  end

  describe "rendered component" do
    subject(:rendered) { render_inline(component) }

    it "renders a play button" do
      expect(rendered).to have_css("button[onclick]")
    end

    it "includes track data attributes" do
      expect(rendered).to have_css("button[data-track-id='#{track.id}']")
      expect(rendered).to have_css("button[data-track-title='#{track.metadata_title}']")
      expect(rendered).to have_css("button[data-track-url='#{track.audio.url}']")
    end

    it "includes content data attributes" do
      expect(rendered).to have_css("button[data-content-id='#{content.id}']")
      expect(rendered).to have_css("button[data-content-title='#{content.theme}']")
    end

    it "includes play icon" do
      expect(rendered).to have_css("button svg")
    end

    it "has proper styling" do
      expect(rendered).to have_css("button.bg-blue-600")
      expect(rendered).to have_css("button.hover\\:bg-blue-700")
      expect(rendered).to have_css("button.rounded-full")
    end

    context "when playing state is true" do
      let(:component) { described_class.new(track: track, playing: true) }

      it "shows pause icon instead" do
        expect(rendered).to have_css("button[data-playing='true']")
      end
    end
  end

  describe "data attributes structure" do
    let(:rendered) { render_inline(component) }
    let(:button) { rendered.css("button").first }

    it "generates correct track list data" do
      other_tracks = create_list(:track, 2, :completed, :with_audio, content: content)
      component = described_class.new(track: track)
      rendered = render_inline(component)
      button = rendered.css("button").first

      track_list = JSON.parse(button["data-track-list"])
      expect(track_list).to be_an(Array)
      expect(track_list.size).to eq(3)
      expect(track_list.map { |t| t["id"] }).to include(track.id, *other_tracks.map(&:id))
    end
  end
end
