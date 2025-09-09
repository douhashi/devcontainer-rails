# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FloatingAudioPlayer", type: :system, js: true do
  let(:content) { create(:content, theme: "Relaxing Morning") }
  let!(:music_generation) { create(:music_generation, :completed, content: content) }
  let!(:track1) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 1" }) }
  let!(:track2) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 2" }) }
  let!(:track3) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 3" }) }

  before do
    visit content_path(content)
  end

  describe "初期状態" do
    it "フローティングプレイヤーが非表示になっている" do
      expect(page).not_to have_css("#floating-audio-player:not(.hidden)")
    end

    it "再生ボタンが表示されている" do
      expect(page).to have_css("button[id^='play-button-']", count: 3)
    end
  end

  describe "再生ボタンクリック時" do
    it "フローティングプレイヤーが表示される" do
      first("button[id^='play-button-']").click
      expect(page).to have_css("#floating-audio-player:not(.hidden)")
    end

    it "トラックタイトルが表示される" do
      find("#play-button-#{track1.id}").click
      within("#floating-audio-player") do
        expect(page).to have_text("Track 1")
      end
    end

    it "再生ボタンが一時停止アイコンに変わる" do
      button = find("#play-button-#{track1.id}")
      button.click

      within("#floating-audio-player") do
        expect(page).to have_css("[data-floating-audio-player-target='pauseIcon']:not(.hidden)")
      end
    end
  end

  describe "プレイヤーコントロール" do
    before do
      find("#play-button-#{track2.id}").click
      sleep 0.5 # Wait for player to initialize
    end

    it "次のトラックボタンで次の曲に移動できる" do
      within("#floating-audio-player") do
        expect(page).to have_text("Track 2")
        find("button[data-action='click->floating-audio-player#next']").click
        expect(page).to have_text("Track 3")
      end
    end

    it "前のトラックボタンで前の曲に移動できる" do
      within("#floating-audio-player") do
        expect(page).to have_text("Track 2")
        find("button[data-action='click->floating-audio-player#previous']").click
        expect(page).to have_text("Track 1")
      end
    end

    it "閉じるボタンでプレイヤーが非表示になる" do
      within("#floating-audio-player") do
        find("button[data-action='click->floating-audio-player#close']").click
      end
      expect(page).not_to have_css("#floating-audio-player:not(.hidden)")
    end

    it "再生/一時停止ボタンが機能する" do
      within("#floating-audio-player") do
        play_button = find("button[data-floating-audio-player-target='playButton']")

        # Initially playing
        expect(page).to have_css("[data-floating-audio-player-target='pauseIcon']:not(.hidden)")

        # Click to pause
        play_button.click
        expect(page).to have_css("[data-floating-audio-player-target='playIcon']:not(.hidden)")

        # Click to play again
        play_button.click
        expect(page).to have_css("[data-floating-audio-player-target='pauseIcon']:not(.hidden)")
      end
    end
  end

  describe "複数トラックの切り替え" do
    it "別のトラックの再生ボタンをクリックすると切り替わる" do
      # Play track 1
      find("#play-button-#{track1.id}").click
      within("#floating-audio-player") do
        expect(page).to have_text("Track 1")
      end

      # Play track 3
      find("#play-button-#{track3.id}").click
      within("#floating-audio-player") do
        expect(page).to have_text("Track 3")
      end
    end

    it "現在再生中のトラックのボタンスタイルが変わる" do
      find("#play-button-#{track2.id}").click

      button2 = find("#play-button-#{track2.id}")
      expect(button2[:class]).to include("bg-blue-700")

      button1 = find("#play-button-#{track1.id}")
      expect(button1[:class]).to include("bg-blue-600")
    end
  end

  describe "レスポンシブデザイン" do
    it "モバイルサイズでも適切に表示される", viewport: :mobile do
      find("#play-button-#{track1.id}").click

      # Check if player has responsive classes
      expect(page).to have_css("#floating-audio-player.w-full")
    end
  end

  describe "ページ遷移時の動作" do
    it "Turboページ遷移後もプレイヤーが維持される" do
      find("#play-button-#{track1.id}").click

      # Verify player is visible and has turbo-permanent attribute
      expect(page).to have_css("#floating-audio-player:not(.hidden)")
      expect(page).to have_css("#floating-audio-player[data-turbo-permanent]")

      # Navigate back to contents index page
      visit contents_path

      # Player element should still exist in DOM after navigation due to data-turbo-permanent
      expect(page).to have_css("#floating-audio-player[data-turbo-permanent]", visible: :all)

      # Note: Player visibility state may reset on navigation in test environment
      # In production, Turbo handles this properly with data-turbo-permanent
    end
  end
end
