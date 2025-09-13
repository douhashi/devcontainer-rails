# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FloatingAudioPlayer", type: :system, js: true do
  include_context "ログイン済み"

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
end
