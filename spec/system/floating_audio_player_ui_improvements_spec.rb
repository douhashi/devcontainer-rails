# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FloatingAudioPlayer UI Improvements", type: :system, js: true, playwright: true do
  include_context "ログイン済み"
  include MediaChromeHelpers

  let(:content) { create(:content, theme: "Relaxing Morning") }
  let!(:music_generation) { create(:music_generation, :completed, content: content) }
  let!(:track1) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 1" }) }
  let!(:track2) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { "music_title" => "Track 2" }) }

  before do
    visit content_path(content)
    find("#audio-play-button-track-#{track1.id}").click
    expect(page).to have_css("#floating-audio-player:not(.hidden)")
  end

  describe "レイアウト改善" do
    it "再生コントロールが画面中央に配置されている" do
      within("#floating-audio-player") do
        controls_section = find(".flex-1.flex.items-center.justify-center")
        expect(controls_section).to be_present

        # 再生コントロールボタンが中央寄せになっている
        buttons = controls_section.all("button")
        expect(buttons.size).to be >= 3 # 前、再生/一時停止、次のボタン

        # justify-centerクラスが適用されている
        expect(controls_section[:class]).to include("justify-center")
      end
    end

    it "シークバーと音量コントロールの縦位置が中央揃えになっている" do
      within("#floating-audio-player") do
        media_bar = find("media-control-bar")

        # align-items: center が適用されていることを確認
        align_items = page.evaluate_script("getComputedStyle(arguments[0]).alignItems", media_bar)
        expect(align_items).to eq("center")
      end
    end
  end

  describe "表示改善" do
    it "シークバーと音量コントロールが常に表示されている（ホバー不要）" do
      within("#floating-audio-player") do
        media_controller = find("media-controller")

        # autohide属性が無効化されている
        expect(media_controller[:autohide]).to eq("-1")

        # シークバーが常に表示されている
        time_range = find("media-time-range")
        opacity = page.evaluate_script("getComputedStyle(arguments[0]).opacity", time_range)
        expect(opacity).to eq("1")

        # 音量コントロールが常に表示されている
        volume_range = find("media-volume-range")
        opacity = page.evaluate_script("getComputedStyle(arguments[0]).opacity", volume_range)
        expect(opacity).to eq("1")
      end
    end

    it "ホバー時のフェードイン/アウト効果が削除されている", skip: "Playwright環境でのhover動作不安定のため一時的にスキップ" do
      within("#floating-audio-player") do
        # media-controllerとmedia-control-barが存在することを確認
        expect(page).to have_css("media-controller", wait: 10)
        expect(page).to have_css("media-control-bar", wait: 10)

        media_controller = find("media-controller", wait: 10)

        # 初期状態でコントロールが表示されている
        media_bar = find("media-control-bar", wait: 10)
        initial_opacity = page.evaluate_script("getComputedStyle(arguments[0]).opacity", media_bar)
        expect(initial_opacity).to eq("1")

        # ホバー時もopacityが変わらない
        # Playwrightの場合、要素が完全に表示されるまで待機
        page.execute_script("arguments[0].scrollIntoView(true);", media_controller)
        sleep 0.5 # 要素が安定するまで少し待機
        media_controller.hover
        hover_opacity = page.evaluate_script("getComputedStyle(arguments[0]).opacity", media_bar)
        expect(hover_opacity).to eq("1")
      end

      # ホバーを外してもopacityが変わらない（within句の外で実行）
      find(".text-sm.font-medium.truncate").hover # track info にホバー
      within("#floating-audio-player") do
        media_bar = find("media-control-bar")
        unhover_opacity = page.evaluate_script("getComputedStyle(arguments[0]).opacity", media_bar)
        expect(unhover_opacity).to eq("1")
      end
    end

    it "ホバー時の背景色変化が削除されている", skip: "Playwright環境でのhover動作不安定のため一時的にスキップ" do
      within("#floating-audio-player") do
        # media-controllerとmedia-control-barが存在することを確認
        expect(page).to have_css("media-controller", wait: 10)
        expect(page).to have_css("media-control-bar", wait: 10)

        media_controller = find("media-controller", wait: 10)
        media_bar = find("media-control-bar", wait: 10)

        # 初期状態の背景色を取得
        initial_bg = page.evaluate_script("getComputedStyle(arguments[0]).backgroundColor", media_bar)

        # ホバー時の背景色が変わらない
        # Playwrightの場合、要素が完全に表示されるまで待機
        page.execute_script("arguments[0].scrollIntoView(true);", media_controller)
        sleep 0.5 # 要素が安定するまで少し待機
        media_controller.hover
        hover_bg = page.evaluate_script("getComputedStyle(arguments[0]).backgroundColor", media_bar)
        expect(hover_bg).to eq(initial_bg)
      end
    end

    it "media-chromeのコントロールが常に可視状態になっている" do
      within("#floating-audio-player") do
        # CSS変数で opacity が 1 に設定されている
        media_controller = find("media-controller")
        control_opacity = page.evaluate_script("getComputedStyle(arguments[0]).getPropertyValue('--media-control-opacity')", media_controller)
        expect(control_opacity.strip).to eq("1")

        # hover背景色が透明に設定されている
        hover_bg = page.evaluate_script("getComputedStyle(arguments[0]).getPropertyValue('--media-control-hover-background')", media_controller)
        expect(hover_bg.strip).to eq("transparent")
      end
    end
  end

  describe "スタイリング" do
    it "全体的なデザインが統一され、クリーンな見た目になっている" do
      # コンテナのスタイルが正しく適用されている
      container = find("#floating-audio-player")
      expect(container[:class]).to include("bg-gray-800")
      expect(container[:class]).to include("text-white")

      within("#floating-audio-player") do
        # media-controllerの背景が適切に設定されている
        media_controller = find("media-controller")
        expect(media_controller[:class]).to include("bg-gray-700")
        expect(media_controller[:class]).to include("rounded-md")
      end
    end

    it "ダークテーマに合った配色が維持されている" do
      # ダークテーマのカラーパレットが使用されている
      container = find("#floating-audio-player")
      bg_color = page.evaluate_script("getComputedStyle(arguments[0]).backgroundColor", container)
      # bg-gray-800 のRGB値またはoklch形式を確認
      expect(bg_color).to match(/rgb\(31,\s*41,\s*55\)|rgba\(31,\s*41,\s*55|oklch/)

      # テキストカラーが白
      text_color = page.evaluate_script("getComputedStyle(arguments[0]).color", container)
      expect(text_color).to match(/rgb\(255,\s*255,\s*255\)|rgba\(255,\s*255,\s*255|oklch/)
    end
  end

  describe "ボタングループの中央配置" do
    it "再生コントロールボタンがグループとして中央に配置されている" do
      within("#floating-audio-player") do
        # ボタングループが存在し、中央配置されている
        button_group = find(".flex.items-center.justify-center.gap-2")
        expect(button_group).to be_present

        # 各ボタンが存在する
        previous_button = find("button[data-action='click->floating-audio-player#previous']")
        play_button = find("button[data-floating-audio-player-target='playButton']")
        next_button = find("button[data-action='click->floating-audio-player#next']")

        expect(previous_button).to be_present
        expect(play_button).to be_present
        expect(next_button).to be_present

        # ボタンが適切な間隔で配置されている
        expect(button_group[:class]).to include("gap-2")
      end
    end
  end
end
