# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AudioPlayButtonController', type: :component do
  describe 'JavaScript functionality' do
    let(:content) { create(:content, theme: 'Test Content Theme') }

    context 'when testing the controller logic' do
      it 'has the correct controller name and action mapping' do
        # Simple test to verify the controller file exists and can be read
        expect(File.exist?(Rails.root.join('app/frontend/controllers/audio_play_button_controller.js'))).to be_truthy

        controller_content = File.read(Rails.root.join('app/frontend/controllers/audio_play_button_controller.js'))

        # Verify essential parts of the controller are present
        expect(controller_content).to include('playContent(event)')
        expect(controller_content).to include('content:play')
        expect(controller_content).to include('static values')
        expect(controller_content).to include('contentId: Number')
        expect(controller_content).to include('theme: String')
        expect(controller_content).to include('audioUrl: String')
      end
    end
  end

  describe 'Component Integration' do
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

    it 'component renders with correct data attributes' do
      component = AudioPlayButton::Component.new(content_record: content)

      expect(component.render?).to be_truthy

      rendered_html = render_inline(component)

      expect(rendered_html).to have_selector(
        'button[data-controller="audio-play-button"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-action="click->audio-play-button#playContent"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-content-id-value="' + content.id.to_s + '"]'
      )
      expect(rendered_html).to have_selector(
        'button[data-audio-play-button-theme-value="' + content.theme + '"]'
      )
    end
  end
end
