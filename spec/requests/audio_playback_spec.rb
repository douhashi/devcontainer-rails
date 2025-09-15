# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Audio Playback', type: :request do
  describe 'GET /contents/:id with audio play button' do
    let(:content) { create(:content, theme: 'Test Content') }
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

    it 'renders content page with InlineAudioPlayer' do
      get content_path(content)

      expect(response).to have_http_status(:success)

      # Check for InlineAudioPlayer data attributes
      expect(response.body).to include('data-controller="inline-audio-player"')
      expect(response.body).to include('data-inline-audio-player-type-value="content"')
      expect(response.body).to include("data-inline-audio-player-id-value=\"#{content.id}\"")
      expect(response.body).to include("data-inline-audio-player-title-value=\"#{content.theme}\"")
      # Audio URL should be present
      expect(response.body).to include('data-inline-audio-player-url-value=')
    end
  end

  describe 'Track with audio play button' do
    let(:content) { create(:content, theme: 'Parent Content') }
    let(:track) do
      track = create(:track, :completed, content: content)
      track.update(metadata: { music_title: 'Test Track' })
      # Create a temporary audio file for testing
      tempfile = Tempfile.new([ 'test_audio', '.mp3' ])
      tempfile.write("dummy audio content")
      tempfile.rewind
      track.audio = tempfile
      track.save!
      tempfile.close
      tempfile.unlink
      track
    end

    before do
      # Create the audio for content as well to display tracks
      audio = create(:audio, :completed, content: content)
      tempfile = Tempfile.new([ 'test_audio', '.mp3' ])
      tempfile.write("dummy audio content")
      tempfile.rewind
      audio.audio = tempfile
      # Add track ID to metadata
      audio.metadata = { selected_track_ids: [ track.id ] }
      audio.save!
      tempfile.close
      tempfile.unlink
    end

    it 'renders track with InlineAudioPlayer' do
      get content_path(content)

      expect(response).to have_http_status(:success)

      # Check for track InlineAudioPlayer data attributes
      expect(response.body).to include('data-controller="inline-audio-player"')
      expect(response.body).to include('data-inline-audio-player-type-value="track"')
      expect(response.body).to include("data-inline-audio-player-id-value=\"#{track.id}\"")
      # Audio URL should be present
      expect(response.body).to include('data-inline-audio-player-url-value=')
    end
  end
end
