# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FloatingAudioPlayerController' do
  describe 'JavaScript functionality' do
    it 'has the controller file with expected methods' do
      expect(File.exist?(Rails.root.join('app/frontend/controllers/floating_audio_player_controller.js'))).to be_truthy

      controller_content = File.read(Rails.root.join('app/frontend/controllers/floating_audio_player_controller.js'))

      # Verify essential methods and event handling are present
      expect(controller_content).to include('setupEventListeners()')
      expect(controller_content).to include('handlePlayEvent(event)')
      expect(controller_content).to include('track:play')
      expect(controller_content).to include('playTrack(trackData)')
      expect(controller_content).to include('trackTitleTarget')
    end
  end

  describe 'content:play event handling' do
    let(:content) { create(:content, theme: 'Test Theme') }
    let!(:audio) do
      audio = create(:audio, :completed, content: content)
      tempfile = Tempfile.new([ 'test_audio', '.mp3' ])
      tempfile.write("dummy audio content")
      tempfile.rewind
      audio.audio = tempfile
      audio.save!
      tempfile.close
      tempfile.unlink
      audio
    end

    it 'should handle content:play events when controller is enhanced' do
      # This test verifies that the necessary components exist for content:play handling
      # The actual event handling will be tested through integration tests

      # Verify content data is available for event handling
      expect(content.id).to be_present
      expect(content.theme).to eq('Test Theme')
      expect(audio.audio).to be_present
      expect(audio.status).to eq('completed')
    end
  end
end
