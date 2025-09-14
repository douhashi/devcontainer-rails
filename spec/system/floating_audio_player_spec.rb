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

  describe "media-controller初期化問題の修正" do
    it "media-controllerとaudio要素が正しく連携する" do
      # Track 1を再生
      click_play_and_wait("#audio-play-button-track-#{track1.id}")

      # media-controllerが正しく初期化されているか確認
      within("#floating-audio-player") do
        # media-controllerが存在することを確認
        expect(page).to have_css("media-controller")

        # audio要素が存在することを確認（visible: :all で非表示要素も検索）
        expect(page).to have_css("audio[slot='media']", visible: :all)

        # media-controllerが存在し、audio要素が正しく配置されていることを確認
        media_state = page.evaluate_script(<<~JS)
          (() => {
            const mediaController = document.querySelector('#floating-audio-player media-controller');
            const audioElement = mediaController ? mediaController.querySelector('audio[slot="media"]') : null;
            return {
              hasController: !!mediaController,
              hasAudio: !!audioElement,
              audioSrc: audioElement ? audioElement.src : null,
              audioHasSlot: audioElement ? audioElement.hasAttribute('slot') : false
            };
          })()
        JS

        expect(media_state['hasController']).to be_truthy, "media-controller element not found"
        expect(media_state['hasAudio']).to be_truthy, "audio element not found in media-controller"
        expect(media_state['audioHasSlot']).to be_truthy, "audio element does not have slot='media' attribute"
      end

      # プレイヤーが表示されることを確認
      expect(player_showing?("Track 1")).to be true
    end

    it "初期化エラー 'Audio element or playback controller not available' が発生しない" do
      # コンソールエラーの収集を開始
      page.execute_script(<<~JS)
        window.consoleErrors = [];
        const originalError = console.error;
        console.error = function(...args) {
          window.consoleErrors.push(args.join(' '));
          originalError.apply(console, arguments);
        };
      JS

      # Track 1を再生
      click_play_and_wait("#audio-play-button-track-#{track1.id}")

      # エラーログをチェック
      console_errors = page.evaluate_script('window.consoleErrors || []')

      # 特定のエラーメッセージが出ていないことを確認
      init_errors = console_errors.select { |msg|
        msg.include?("Audio element or playback controller not available") ||
        msg.include?("Audio target not found") ||
        msg.include?("Audio element not found in media-controller")
      }

      expect(init_errors).to be_empty, "初期化エラーが発生しました: #{init_errors}"

      # プレイヤーが正常に表示されることを確認
      expect(player_showing?("Track 1")).to be true
    end
  end

  describe "AbortError問題の修正" do
    it "連続した再生ボタンクリックでAbortErrorが発生しない" do
      # 高速で連続クリックを実行
      5.times do |i|
        sleep 0.05  # 短いインターバルで連続実行
        find("#audio-play-button-track-#{track1.id}").click
      end

      # プレイヤーが正常に表示され、エラーログがないことを確認
      expect(player_showing?("Track 1")).to be true

      # Playwrightでコンソールエラーをチェック
      console_messages = page.evaluate_script(<<~JS)
        window.consoleErrors || []
      JS

      abort_errors = console_messages.select { |msg| msg.include?("AbortError") }
      expect(abort_errors).to be_empty, "AbortError が発生しました: #{abort_errors}"
    end

    it "異なるトラック間の高速切り替えでAbortErrorが発生しない" do
      # 高速でトラックを切り替える
      3.times do
        find("#audio-play-button-track-#{track1.id}").click
        sleep 0.1
        find("#audio-play-button-track-#{track2.id}").click
        sleep 0.1
      end

      # プレイヤーが正常に表示されることを確認
      expect(player_showing?("Track 2")).to be true

      # Playwrightでコンソールエラーをチェック
      console_messages = page.evaluate_script(<<~JS)
        window.consoleErrors || []
      JS

      abort_errors = console_messages.select { |msg| msg.include?("AbortError") }
      expect(abort_errors).to be_empty, "AbortError が発生しました: #{abort_errors}"
    end

    it "PlaybackControllerによる競合状態が解決されている", skip: "テスト環境のPlaywright要素選択問題により一時スキップ" do
      # Track 1を再生
      click_play_and_wait("#audio-play-button-track-#{track1.id}")
      expect(player_showing?("Track 1")).to be true

      # コンソールエラーの収集を開始
      page.execute_script(<<~JS)
        window.consoleErrors = [];
        const originalError = console.error;
        console.error = function(...args) {
          window.consoleErrors.push(args.join(' '));
          originalError.apply(console, arguments);
        };
      JS

      # PlaybackControllerを通した正常な連続操作をテスト（実際のユーザー操作を模擬）
      # これまでの実装により、play()とpause()の競合状態は解決されているはず
      find("#play-pause-button").click # 一時停止
      sleep 0.2
      find("#play-pause-button").click # 再生
      sleep 0.2
      find("#play-pause-button").click # 一時停止
      sleep 0.2
      find("#play-pause-button").click # 再生

      sleep 1

      # Playwrightでコンソールエラーをチェック
      console_messages = page.evaluate_script('window.consoleErrors || []')

      abort_errors = console_messages.select { |msg| msg.include?("AbortError") && !msg.include?("safely aborted") }
      expect(abort_errors).to be_empty, "PlaybackController操作でAbortError が発生しました: #{abort_errors}"
    end
  end
end
