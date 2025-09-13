# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unified Audio Play Integration", type: :system, js: true do
  include_context "ログイン済み"

  describe "基本的な再生機能" do
    let(:content) { create(:content, theme: "Test Content Theme") }
    let!(:music_generation) { create(:music_generation, :completed, content: content) }
    let!(:track) do
      create(:track, :completed, :with_audio, content: content, music_generation: music_generation,
             metadata: {
               "music_title" => 'Test Track Title',
               "music_tags" => "lofi, chill",
               "model_name" => "test-model",
               "generated_prompt" => "A chill lofi track",
               "audio_id" => "test-audio-123",
               "kie_response" => {
                 "url" => "https://example.com/track.mp3",
                 "duration" => 180,
                 "format" => "mp3"
               }
             })
    end

    before do
      visit content_path(content)
    end

    it "トラックオーディオを再生できる" do
      # AudioPlayButtonコンポーネントが存在することを確認
      expect(page).to have_css('button[data-audio-play-button-type-value="track"]', wait: 10)

      # 再生ボタンをクリック
      click_play_and_wait('button[data-audio-play-button-type-value="track"]')

      # プレイヤーが表示されることを確認
      expect(page).to have_css('#floating-audio-player:not(.hidden)', wait: 15)

      # プレイヤーに正しいタイトルが表示されることを確認
      within('#floating-audio-player') do
        expect(page).to have_content('Test Track Title', wait: 10)
      end
    end
  end
end
