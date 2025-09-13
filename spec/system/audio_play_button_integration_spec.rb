# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AudioPlayButton and FloatingAudioPlayer integration', type: :system, js: true do
  let(:user) { create(:user) }
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
    login_as(user, scope: :user)
  end

  describe 'Audio playback functionality' do
    context 'when playing content audio' do
      before do
        visit content_path(content)
      end

      it 'plays audio when AudioPlayButton is clicked' do
        # Find and click the audio play button
        play_button = find('button[data-controller="audio-play-button"][data-audio-play-button-type-value="content"]')
        play_button.click

        # Wait for floating player to appear
        expect(page).to have_selector('#floating-audio-player', visible: true)

        # Check that the floating player shows the correct title
        within('#floating-audio-player') do
          expect(page).to have_content(content.theme)
        end

        # Verify that audio element has src set
        audio_element = find('audio[slot="media"]', visible: :all)
        expect(audio_element['src']).not_to be_empty
      end
    end

    context 'when playing track audio' do
      before do
        track # Create the track
        visit content_path(content)
      end

      it 'plays audio when track AudioPlayButton is clicked' do
        # Find and click the track play button
        play_button = find("button[data-controller='audio-play-button'][data-audio-play-button-type-value='track'][data-audio-play-button-id-value='#{track.id}']")
        play_button.click

        # Wait for floating player to appear
        expect(page).to have_selector('#floating-audio-player', visible: true)

        # Check that the floating player shows the correct title
        within('#floating-audio-player') do
          expect(page).to have_content(track.metadata_title)
        end

        # Verify that audio element has src set
        audio_element = find('audio[slot="media"]', visible: :all)
        expect(audio_element['src']).not_to be_empty
      end
    end

    context 'error handling' do
      it 'handles invalid audio URL gracefully' do
        # Create content without audio file
        content_without_audio = create(:content, theme: 'No Audio Content')
        audio_without_file = create(:audio, :completed, content: content_without_audio)

        visit content_path(content_without_audio)

        # Should not show play button when audio file is missing
        expect(page).not_to have_selector('button[data-controller="audio-play-button"]')
      end
    end
  end
end
