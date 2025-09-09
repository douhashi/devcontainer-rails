require 'rails_helper'

RSpec.describe "Track Audio Player", type: :system, js: true, skip: "AudioPlayer component has been replaced with PlayButton and FloatingAudioPlayer" do
  let(:content) { create(:content) }

  context "with completed tracks having audio" do
    let!(:track_with_audio) { create(:track, :completed, content: content) }
    let!(:track_without_audio) { create(:track, :completed, content: content) }

    before do
      # Mock audio for all Track instances - this way we don't need to mock the complex query chain
      allow_any_instance_of(Track).to receive(:audio) do |track|
        if track.id == track_with_audio.id
          double(present?: true, url: "https://example.com/test1.mp3")
        else
          double(present?: false)
        end
      end
    end

    it "displays audio player for tracks with audio" do
      visit tracks_path

      # Wait for page to load
      expect(page).to have_content("Track一覧")

      # Should have audio player for track with audio
      within("#track_#{track_with_audio.id}") do
        expect(page).to have_css('[data-controller="audio-player"]', visible: false)
        expect(page).to have_css('audio[data-audio-player-target="player"]', visible: false)
      end

      # Should not have audio player for track without audio
      within("#track_#{track_without_audio.id}") do
        expect(page).to have_content("音声なし")
        expect(page).not_to have_css('[data-controller="audio-player"]')
      end
    end

    it "initializes Plyr player on track with audio" do
      visit tracks_path

      # Wait for page to load and Stimulus controllers to connect
      expect(page).to have_content("Track一覧")
      sleep 1

      within("#track_#{track_with_audio.id}") do
        # Plyr should initialize and show controls
        expect(page).to have_css('.plyr', visible: true, wait: 5)
        expect(page).to have_css('.plyr__controls', visible: true)
        expect(page).to have_css('[data-plyr="play"]', visible: true)
      end
    end

    it "shows appropriate status messages for different track states" do
      processing_track = create(:track, :processing, content: content)
      pending_track = create(:track, :pending, content: content)
      failed_track = create(:track, :failed, content: content)

      visit tracks_path

      within("#track_#{processing_track.id}") do
        expect(page).to have_content("処理中...")
      end

      within("#track_#{pending_track.id}") do
        expect(page).to have_content("-")
      end

      within("#track_#{failed_track.id}") do
        expect(page).to have_content("-")
      end
    end
  end

  context "with multiple tracks having audio" do
    let!(:track1) { create(:track, :completed, content: content) }
    let!(:track2) { create(:track, :completed, content: content) }

    before do
      # Mock audio for all Track instances
      allow_any_instance_of(Track).to receive(:audio) do |track|
        if track.id == track1.id
          double(present?: true, url: "https://example.com/test1.mp3")
        elsif track.id == track2.id
          double(present?: true, url: "https://example.com/test2.mp3")
        else
          double(present?: false)
        end
      end
    end

    it "displays multiple audio players" do
      visit tracks_path

      expect(page).to have_content("Track一覧")

      # Both tracks should have audio players
      within("#track_#{track1.id}") do
        expect(page).to have_css('[data-controller="audio-player"]', visible: false)
      end

      within("#track_#{track2.id}") do
        expect(page).to have_css('[data-controller="audio-player"]', visible: false)
      end
    end

    it "initializes separate Plyr instances for each player" do
      visit tracks_path

      expect(page).to have_content("Track一覧")
      sleep 1

      # Each track should have its own Plyr instance
      within("#track_#{track1.id}") do
        expect(page).to have_css('.plyr', visible: true, wait: 5)
      end

      within("#track_#{track2.id}") do
        expect(page).to have_css('.plyr', visible: true, wait: 5)
      end
    end

    it "plays audio with a single click on play button" do
      visit tracks_path

      expect(page).to have_content("Track一覧")
      sleep 1

      within("#track_#{track1.id}") do
        # Find the play button
        play_button = find('[data-plyr="play"]', visible: true)

        # Store initial state
        initial_classes = play_button[:class]

        # Click once should start playback
        play_button.click

        # Wait a moment for the click to register
        sleep 0.5

        # Verify that the button was clicked and player initialized without errors
        # Since we can't verify actual playback without real audio, we check that:
        # 1. The button is still present (no JS errors)
        # 2. The player UI has been initialized properly
        expect(page).to have_css('[data-plyr="play"]', visible: true)
        expect(page).to have_css('.plyr__controls', visible: true)
      end
    end

    it "stops other players when starting a new one" do
      visit tracks_path

      expect(page).to have_content("Track一覧")
      sleep 1

      # Start playing track1
      track1_play_button = nil
      within("#track_#{track1.id}") do
        track1_play_button = find('[data-plyr="play"]', visible: true)
        track1_play_button.click
        sleep 0.5
      end

      # Start playing track2 - track1 should stop
      track2_play_button = nil
      within("#track_#{track2.id}") do
        track2_play_button = find('[data-plyr="play"]', visible: true)
        track2_play_button.click
        sleep 0.5
      end

      # Verify both players are still functional (no JS errors)
      within("#track_#{track1.id}") do
        expect(page).to have_css('[data-plyr="play"]', visible: true)
      end

      within("#track_#{track2.id}") do
        expect(page).to have_css('[data-plyr="play"]', visible: true)
      end
    end
  end

  context "responsive design" do
    let!(:track) { create(:track, :completed, content: content) }

    before do
      allow_any_instance_of(Track).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))
    end

    it "displays properly on mobile screens" do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone SE size
      visit tracks_path

      expect(page).to have_content("Track一覧")

      within("#track_#{track.id}") do
        # Should still display audio player
        expect(page).to have_css('[data-controller="audio-player"]', visible: false)
      end
    end
  end

  context "error handling" do
    let!(:track) { create(:track, :completed, content: content) }

    it "handles missing audio URL gracefully" do
      allow_any_instance_of(Track).to receive(:audio).and_return(double(present?: true, url: nil))

      visit tracks_path

      expect(page).to have_content("Track一覧")
      # Should not crash the page
      expect(page).to have_current_path(tracks_path)
    end
  end
end
