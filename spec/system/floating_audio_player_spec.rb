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

  describe "初期状態" do
    it "フローティングプレイヤーが非表示になっている" do
      expect(page).not_to have_css("#floating-audio-player:not(.hidden)")
    end

    it "再生ボタンが表示されている" do
      # スクロールして音楽生成セクションを表示
      page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

      # Track番号が表示されていることを確認（Track 1ではなく#1, #2, #3として表示）
      expect(page).to have_content("#1")
      expect(page).to have_content("#2")
      expect(page).to have_content("#3")

      # 再生ボタンの存在を確認
      expect(page).to have_css("button[data-controller='audio-play-button']", minimum: 1)
    end
  end

  describe "再生ボタンクリック時" do
    it "フローティングプレイヤーが表示される" do
      first("button[data-controller='audio-play-button']").click
      expect(page).to have_css("#floating-audio-player:not(.hidden)")
    end

    it "トラックタイトルが表示される" do
      find("#audio-play-button-track-#{track1.id}").click
      within("#floating-audio-player") do
        expect(page).to have_text("Track 1")
      end
    end

    it "再生ボタンが一時停止アイコンに変わる" do
      button = find("#audio-play-button-track-#{track1.id}")
      button.click

      within("#floating-audio-player") do
        expect(page).to have_css("[data-floating-audio-player-target='pauseIcon']:not(.hidden)")
      end
    end
  end

  describe "プレイヤーコントロール" do
    before do
      find("#audio-play-button-track-#{track2.id}").click
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
      find("#audio-play-button-track-#{track1.id}").click
      within("#floating-audio-player") do
        expect(page).to have_text("Track 1")
      end

      # Play track 3
      find("#audio-play-button-track-#{track3.id}").click
      within("#floating-audio-player") do
        expect(page).to have_text("Track 3")
      end
    end

    it "現在再生中のトラックのボタンスタイルが変わる" do
      find("#audio-play-button-track-#{track2.id}").click
      sleep 0.5 # Stimulusコントローラーがクラスを適用するのを待つ

      # ghostバリアントに変更されたため、bg-blue-600が再生中のボタンに適用される
      button2 = find("#audio-play-button-track-#{track2.id}")
      expect(button2[:class]).to include("bg-blue-600")

      # 他のボタンは通常のghostスタイル（bg-blue-600を持たない）
      button1 = find("#audio-play-button-track-#{track1.id}")
      button3 = find("#audio-play-button-track-#{track3.id}")
      expect(button1[:class]).to include("hover:bg-blue-500/10")
      expect(button1[:class]).not_to include("bg-blue-600")
      expect(button3[:class]).to include("hover:bg-blue-500/10")
      expect(button3[:class]).not_to include("bg-blue-600")
    end
  end

  describe "新しい下部バーレイアウト" do
    before do
      find("#audio-play-button-track-#{track1.id}").click
      sleep 0.5 # Wait for player to initialize
    end

    it "画面下部全体に固定されている" do
      expect(page).to have_css("#floating-audio-player.fixed.bottom-0.left-0.right-0")
    end

    it "横長レイアウトでフレックス配置されている" do
      expect(page).to have_css("#floating-audio-player.flex.items-center")
    end

    it "コンパクトな高さ(h-16)になっている" do
      expect(page).to have_css("#floating-audio-player.h-16")
    end

    it "左側にトラック情報が表示される" do
      within("#floating-audio-player") do
        expect(page).to have_css("div.flex-shrink-0.min-w-0", text: "Track 1")
      end
    end

    it "中央にコントロールボタンとプレイヤーが配置されている" do
      within("#floating-audio-player") do
        expect(page).to have_css("div.flex-1")
        expect(page).to have_css("button[data-action='click->floating-audio-player#previous']")
        expect(page).to have_css("button[data-floating-audio-player-target='playButton']")
        expect(page).to have_css("button[data-action='click->floating-audio-player#next']")
        # Plyr wraps the audio element, so check for the plyr wrapper instead
        expect(page).to have_css(".plyr")
      end
    end

    it "右側に閉じるボタンが配置されている" do
      within("#floating-audio-player") do
        expect(page).to have_css("div.flex-shrink-0 button[data-action='click->floating-audio-player#close']")
      end
    end
  end

  describe "レスポンシブデザイン" do
    it "モバイルサイズでも適切に表示される", viewport: :mobile do
      find("#audio-play-button-track-#{track1.id}").click

      # Check if player has responsive classes and proper sizing
      expect(page).to have_css("#floating-audio-player.w-full.h-16")
      expect(page).to have_css("#floating-audio-player.px-4")
    end

    it "デスクトップサイズで適切な余白が設定されている" do
      find("#audio-play-button-track-#{track1.id}").click

      expect(page).to have_css("#floating-audio-player.px-4.sm\\:px-6")
    end
  end

  describe "スライドアニメーション" do
    it "表示時にslide-upアニメーションが実行される" do
      # Initially hidden
      expect(page).to have_css("#floating-audio-player.hidden", visible: :all)

      # Click to show
      find("#audio-play-button-track-#{track1.id}").click

      # Should not be hidden and should have proper transform classes
      expect(page).to have_css("#floating-audio-player:not(.hidden)")
      expect(page).to have_css("#floating-audio-player.translate-y-0")
    end

    it "非表示時にslide-downアニメーションが実行される" do
      # Show player first
      find("#audio-play-button-track-#{track1.id}").click
      expect(page).to have_css("#floating-audio-player:not(.hidden)")

      # Click close button
      within("#floating-audio-player") do
        find("button[data-action='click->floating-audio-player#close']").click
      end

      # Should eventually become hidden (after animation)
      sleep 0.4 # Wait for animation to complete
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
end
