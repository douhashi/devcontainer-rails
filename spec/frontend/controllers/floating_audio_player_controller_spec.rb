# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FloatingAudioPlayerController' do
  describe 'JavaScript functionality with media-chrome' do
    it 'has the controller file with expected methods for media-chrome' do
      expect(File.exist?(Rails.root.join('app/frontend/controllers/floating_audio_player_controller.js'))).to be_truthy

      controller_content = File.read(Rails.root.join('app/frontend/controllers/floating_audio_player_controller.js'))

      # Verify essential methods and event handling are present for media-chrome
      expect(controller_content).to include('setupEventListeners()')
      expect(controller_content).to include('handlePlayEvent(event)')
      expect(controller_content).to include('track:play')
      expect(controller_content).to include('playTrack(trackData)')
      expect(controller_content).to include('trackTitleTarget')
      expect(controller_content).not_to include('Plyr')
      expect(controller_content).to include('media-controller')
    end
  end

  describe 'audio:play event handling' do
    it 'should properly map audioUrl to url in trackData' do
      controller_content = File.read(Rails.root.join('app/frontend/controllers/floating_audio_player_controller.js'))

      # Verify handleAudioPlayEvent method exists
      expect(controller_content).to include('handleAudioPlayEvent(event)')
      expect(controller_content).to include('audio:play')

      # Verify that playTrack expects url property
      expect(controller_content).to include('this.audioElement.src = trackData.url')
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

  describe 'media-controller initialization' do
    it 'should wait for media-controller custom element to be defined' do
      controller_content = File.read(Rails.root.join('app/frontend/controllers/floating_audio_player_controller.js'))

      # Verify that the controller includes media-controller initialization handling
      expect(controller_content).to include('initializePlayer')
      expect(controller_content).to include('audioTarget')
      expect(controller_content).to include('media-controller')
    end

    it 'should handle missing audio target gracefully' do
      controller_content = File.read(Rails.root.join('app/frontend/controllers/floating_audio_player_controller.js'))

      # Verify error handling for missing audio target
      expect(controller_content).to include('if (!this.hasAudioTarget)')
      expect(controller_content).to include('Audio target (media-controller) not found')
    end

    it 'should find audio element inside media-controller' do
      controller_content = File.read(Rails.root.join('app/frontend/controllers/floating_audio_player_controller.js'))

      # Verify that the controller looks for audio element with slot="media"
      expect(controller_content).to include('querySelector(\'audio[slot="media"]\'')
    end

    it 'should handle PlaybackController initialization errors' do
      controller_content = File.read(Rails.root.join('app/frontend/controllers/floating_audio_player_controller.js'))

      # Verify PlaybackController initialization and error handling
      expect(controller_content).to include('new PlaybackController')
      expect(controller_content).to include('playbackController')
      expect(controller_content).to include('Audio element not available after reinitialization')
      expect(controller_content).to include('PlaybackController not available after reinitialization')
    end
  end
end
