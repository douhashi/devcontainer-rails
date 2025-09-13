# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unified Audio Play Integration", type: :system, js: true do
  include_context "ログイン済み"

  describe "基本的な再生機能" do
    let(:content) { create(:content, theme: "Test Content Theme") }
    let!(:music_generation) { create(:music_generation, :completed, content: content) }
    let!(:track) { create(:track, :completed, :with_audio, content: content, music_generation: music_generation, metadata: { music_title: 'Test Track Title' }) }

    before do
      visit content_path(content)
    end

    it "トラックオーディオを再生できる" do
      # AudioPlayButtonコンポーネントが存在することを確認
      expect(page).to have_css('button[data-audio-play-button-type-value="track"]')

      # 再生ボタンをクリック
      click_play_and_wait('button[data-audio-play-button-type-value="track"]')

      # プレイヤーに正しいタイトルが表示されることを確認
      expect(player_showing?('Test Track Title')).to be true
    end
  end
end
