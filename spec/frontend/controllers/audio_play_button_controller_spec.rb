# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AudioPlayButtonController', type: :component do
  describe 'JavaScript functionality' do
    context 'when testing the unified controller logic' do
      it 'has the correct controller structure for unified audio play functionality' do
        # Simple test to verify the controller file exists and can be read
        expect(File.exist?(Rails.root.join('app/frontend/controllers/audio_play_button_controller.js'))).to be_truthy

        controller_content = File.read(Rails.root.join('app/frontend/controllers/audio_play_button_controller.js'))

        # Verify unified controller structure
        expect(controller_content).to include('play(event)')
        expect(controller_content).to include('audio:play')
        expect(controller_content).to include('static values')
        expect(controller_content).to include('id: Number')
        expect(controller_content).to include('title: String')
        expect(controller_content).to include('audioUrl: String')
        expect(controller_content).to include('type: String')
      end
    end
  end

  describe 'Content Integration' do
    let(:content) { create(:content, theme: 'Test Content Theme') }
    let!(:audio) do
      audio = create(:audio, :completed, content: content)
      # Create a temporary audio file for testing
      tempfile = Tempfile.new([ 'test_audio', '.mp3' ])
      tempfile.write("dummy audio content")
      tempfile.rewind

      audio.audio = tempfile
      audio.save!
      tempfile.close
      tempfile.unlink
      audio
    end

    it 'component renders with correct unified data attributes for content' do
      component = AudioPlayButton::Component.new(content_record: content)

      expect(component.render?).to be_truthy

      rendered_html = render_inline(component)

      expect(rendered_html).to have_selector(
        'button[data-controller="audio-play-button"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-action="click->audio-play-button#play"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-id-value="' + content.id.to_s + '"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-title-value="' + content.theme + '"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-type-value="content"]'
      )
    end
  end

  describe 'Track Integration' do
    let(:content) { create(:content, theme: 'Parent Content') }
    let(:track) do
      track = create(:track, :completed, content: content)
      track.update(metadata: { music_title: 'Test Track Title' })
      track
    end

    before do
      # Create a temporary audio file for testing
      tempfile = Tempfile.new([ 'test_audio', '.mp3' ])
      tempfile.write("dummy audio content")
      tempfile.rewind

      track.audio = tempfile
      track.save!
      tempfile.close
      tempfile.unlink
    end

    it 'component renders with correct unified data attributes for track' do
      component = AudioPlayButton::Component.new(track: track)

      expect(component.render?).to be_truthy

      rendered_html = render_inline(component)

      expect(rendered_html).to have_selector(
        'button[data-controller="audio-play-button"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-action="click->audio-play-button#play"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-id-value="' + track.id.to_s + '"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-title-value="' + track.metadata_title + '"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-type-value="track"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-content-id-value="' + content.id.to_s + '"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-content-title-value="' + content.theme + '"]'
      )
    end
  end
end
