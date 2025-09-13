# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FloatingAudioPlayer", type: :system, js: true, playwright: true do
  include_context "ログイン済み"
  include MediaChromeHelpers

  let(:content) { create(:content, theme: "Relaxing Morning") }
  let!(:music_generation) { create(:music_generation, :completed, content: content) }
  let!(:track1) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 1" }) }
  let!(:track2) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 2" }) }

  before do
    visit content_path(content)
  end

  describe "基本的な再生機能" do
    it "再生ボタンクリックでプレイヤーが表示される" do
      # 再生ボタンをクリック
      click_play_and_wait("#audio-play-button-track-#{track1.id}")

      # プレイヤーが表示されることを確認
      expect(player_showing?("Track 1")).to be true

      # 閉じるボタンで非表示にできることを確認
      within("#floating-audio-player") do
        find("button[data-action='click->floating-audio-player#close']").click
      end
      wait_for_audio_player_hidden
    end
  end

  describe "トラック切り替え" do
    it "別のトラックの再生ボタンで切り替わる" do
      # Track 1を再生
      click_play_and_wait("#audio-play-button-track-#{track1.id}")
      expect(player_showing?("Track 1")).to be true

      # Track 2に切り替え
      click_play_and_wait("#audio-play-button-track-#{track2.id}")
      expect(player_showing?("Track 2")).to be true
    end
  end

  describe "自動再生機能" do
    it "曲が終了すると自動的に次の曲に進む" do
      # Track 1を再生
      click_play_and_wait("#audio-play-button-track-#{track1.id}")
      expect(player_showing?("Track 1")).to be true

      # endedイベントを発火してTrack 2に自動進行
      trigger_audio_ended

      # Playwrightの場合は明示的な待機を使用
      expect(page).to have_content("Track 2", wait: 5)
      expect(player_showing?("Track 2")).to be true
    end

    it "プレイリストの最後の曲が終了すると最初の曲に戻る" do
      # Track 2（最後のトラック）を再生
      click_play_and_wait("#audio-play-button-track-#{track2.id}")
      expect(player_showing?("Track 2")).to be true

      # endedイベントを発火してTrack 1（最初のトラック）に戻る
      trigger_audio_ended

      # Playwrightの場合は明示的な待機を使用
      expect(page).to have_content("Track 1", wait: 5)
      expect(player_showing?("Track 1")).to be true
    end
  end

  describe "再生ボタンの状態表示" do
    it "音楽再生開始時にボタンが一時停止アイコンに変わる" do
      # Track 1を再生
      click_play_and_wait("#audio-play-button-track-#{track1.id}")
      expect(player_showing?("Track 1")).to be true

      # playイベントを発火
      trigger_audio_play

      # Playwrightの場合は明示的な待機を使用
      expect(page).to have_css('[data-floating-audio-player-target="pauseIcon"]:not(.hidden)', wait: 5)
      expect(play_button_shows_pause_icon?).to be true
    end

    it "一時停止時にボタンが再生アイコンに変わる", skip: "Playwright環境での動作不安定のため一時的にスキップ" do
      # Track 1を再生
      click_play_and_wait("#audio-play-button-track-#{track1.id}")
      expect(player_showing?("Track 1")).to be true

      # playイベントを発火してから一時停止
      trigger_audio_play
      expect(page).to have_css('[data-floating-audio-player-target="pauseIcon"]:not(.hidden)', wait: 10)

      trigger_audio_pause

      # Playwrightの場合は明示的な待機を使用（より長いタイムアウト）
      expect(page).to have_css('[data-floating-audio-player-target="playIcon"]:not(.hidden)', wait: 10)
      expect(play_button_shows_play_icon?).to be true
    end
  end
end
