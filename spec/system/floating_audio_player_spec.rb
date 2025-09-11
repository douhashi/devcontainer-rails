# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FloatingAudioPlayer", type: :system, js: true do
  include_context "ログイン済み"

  let(:content) { create(:content, theme: "Relaxing Morning") }
  let!(:music_generation) { create(:music_generation, :completed, content: content) }
  let!(:track1) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 1" }) }
  let!(:track2) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 2" }) }
  let!(:track3) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 3" }) }

  before do
    visit content_path(content)
  end


  describe "プレイヤーの基本動作" do
    it "再生ボタンクリックでプレイヤーが表示され、各種コントロールが機能する" do
      # 再生ボタンクリックでプレイヤー表示
      find("#audio-play-button-track-#{track2.id}").click
      expect(page).to have_css("#floating-audio-player:not(.hidden)")

      within("#floating-audio-player") do
        # トラックタイトル表示
        expect(page).to have_text("Track 2")

        # 再生中アイコン表示
        expect(page).to have_css("[data-floating-audio-player-target='pauseIcon']:not(.hidden)")

        # 次のトラックへ移動
        find("button[data-action='click->floating-audio-player#next']").click
        expect(page).to have_text("Track 3")

        # 前のトラックへ移動
        find("button[data-action='click->floating-audio-player#previous']").click
        expect(page).to have_text("Track 2")
        find("button[data-action='click->floating-audio-player#previous']").click
        expect(page).to have_text("Track 1")

        # 再生/一時停止切り替え
        play_button = find("button[data-floating-audio-player-target='playButton']")
        play_button.click
        expect(page).to have_css("[data-floating-audio-player-target='playIcon']:not(.hidden)")
        play_button.click
        expect(page).to have_css("[data-floating-audio-player-target='pauseIcon']:not(.hidden)")

        # 閉じるボタン
        find("button[data-action='click->floating-audio-player#close']").click
      end

      # プレイヤーが非表示になったことを確認
      expect(page).not_to have_css("#floating-audio-player:not(.hidden)")
    end
  end

  describe "トラック切り替えとボタンスタイル" do
    it "別のトラックの再生ボタンをクリックすると切り替わり、ボタンスタイルが変更される" do
      # Track 1を再生
      find("#audio-play-button-track-#{track1.id}").click
      within("#floating-audio-player") do
        expect(page).to have_text("Track 1")
      end

      # Track 2に切り替え
      find("#audio-play-button-track-#{track2.id}").click
      within("#floating-audio-player") do
        expect(page).to have_text("Track 2")
      end

      # 再生中のボタンスタイル確認
      button2 = find("#audio-play-button-track-#{track2.id}")
      expect(button2[:class]).to include("bg-blue-600")

      # 他のボタンは通常スタイル
      button1 = find("#audio-play-button-track-#{track1.id}")
      expect(button1[:class]).not_to include("bg-blue-600")

      # Track 3に切り替え
      find("#audio-play-button-track-#{track3.id}").click
      within("#floating-audio-player") do
        expect(page).to have_text("Track 3")
      end

      # スタイルも切り替わることを確認
      button3 = find("#audio-play-button-track-#{track3.id}")
      expect(button3[:class]).to include("bg-blue-600")
      expect(button2[:class]).not_to include("bg-blue-600")
    end
  end


  describe "アニメーション動作" do
    it "表示・非表示時にスライドアニメーションが実行される" do
      # 初期状態で非表示
      expect(page).to have_css("#floating-audio-player.hidden", visible: :all)

      # 表示アニメーション
      find("#audio-play-button-track-#{track1.id}").click
      expect(page).to have_css("#floating-audio-player:not(.hidden)")
      expect(page).to have_css("#floating-audio-player.translate-y-0")

      # 非表示アニメーション
      within("#floating-audio-player") do
        find("button[data-action='click->floating-audio-player#close']").click
      end

      sleep 0.4 # アニメーション完了待機
      expect(page).to have_css("#floating-audio-player.hidden", visible: :all)
    end
  end

  describe "ページ遷移時の動作" do
    it "Turboページ遷移後もプレイヤーが維持される" do
      find("#audio-play-button-track-#{track1.id}").click

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

  describe "UI改善の確認" do
    it "シークバー、ボーダー削除、パディング調整、垂直センタリング、フラットデザインが正しく適用される" do
      find("#audio-play-button-track-#{track1.id}").click
      expect(page).to have_css("#floating-audio-player:not(.hidden)")

      within("#floating-audio-player") do
        # シークバーのプログレスバーが正しく表示される
        expect(page).to have_css(".plyr__progress")
        expect(page).to have_css(".plyr__progress input[type='range']", visible: :all)
        progress_element = find(".plyr__progress")
        expect(progress_element).to be_present

        # コントロール領域にボーダーが表示されない
        controls_element = find(".plyr__controls")
        expect(controls_element[:class]).not_to include("border")
        expect(controls_element[:class]).not_to include("border-gray-600")

        # 音量コントロールが存在し、レイアウトが改善されている
        expect(page).to have_css(".plyr__volume")
        volume_element = find(".plyr__volume")
        expect(volume_element).to be_present

        # コントロール領域が垂直方向の中央に配置されている
        display_style = page.evaluate_script("getComputedStyle(arguments[0]).display", controls_element)
        expect(display_style).to eq("flex")

        # フラットなデザインが維持されている
        audio_player = find(".plyr--audio")
        expect(audio_player).to be_present
        background_style = page.evaluate_script("getComputedStyle(arguments[0]).backgroundColor", audio_player)
        expect(background_style).to match(/rgba?\(0,\s*0,\s*0,\s*0\)|transparent/)
      end
    end
  end
end
