# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExtendedTrackRow::Component, type: :component do
  let(:content) { create(:content) }
  let(:music_generation) { create(:music_generation, content: content) }
  let(:track) { create(:track, music_generation: music_generation, content: content, duration_sec: 180, status: :completed) }
  let(:is_group_start) { false }
  let(:group_size) { 1 }
  let(:track_number) { 1 }
  let(:component) { described_class.new(track: track, music_generation: music_generation, is_group_start: is_group_start, group_size: group_size, track_number: track_number) }
  let(:rendered) { render_inline(component) }

  before do
    # audio添付ファイルをモック
    audio_double = double("audio")
    allow(audio_double).to receive(:present?).and_return(true)
    allow(audio_double).to receive(:url).and_return("/test/audio.mp3")
    allow(track).to receive(:audio).and_return(audio_double)
  end

  describe "初期化" do
    it "必須パラメータを受け取る" do
      expect(component.track).to eq track
      expect(component.music_generation).to eq music_generation
      expect(component.is_group_start).to eq false
      expect(component.group_size).to eq 1
    end
  end

  describe "レンダリング" do
    context "グループの最初のTrackの場合" do
      let(:is_group_start) { true }
      let(:group_size) { 3 }

      it "グループ開始用のCSSクラスが適用される" do
        expect(rendered).to have_css("tr.border-t-2.border-gray-600")
      end
    end

    context "グループの中間または最後のTrackの場合" do
      let(:is_group_start) { false }
      let(:group_size) { 1 }

      it "グループ開始用のCSSクラスが適用されない" do
        expect(rendered).not_to have_css("tr.border-t-2.border-gray-600")
      end
    end

    it "Track番号が表示される" do
      expect(rendered).to have_css("td", text: "##{track_number}")
    end

    context "Track番号が異なる場合" do
      let(:track_number) { 5 }

      it "正しいTrack番号が表示される" do
        expect(rendered).to have_css("td", text: "#5")
      end
    end

    it "曲の長さが表示される" do
      expect(rendered).to have_content("3:00")
    end

    it "プレイヤーコンポーネントが表示される" do
      # InlineAudioPlayer::Componentがレンダリングされることを確認
      expect(rendered).to have_css("[data-controller='inline-audio-player']")
    end

    it "削除アクションが表示される" do
      expect(rendered).to have_css("[data-turbo-method='delete']")
    end

    it "data-generation-id属性が設定される" do
      expect(rendered).to have_css("tr[data-generation-id='#{music_generation.id}']")
    end

    it "data-track-id属性が設定される" do
      expect(rendered).to have_css("tr[data-track-id='#{track.id}']")
    end
  end

  describe "削除機能" do
    it "削除ボタンがTurboメソッドで設定される" do
      expect(rendered).to have_css("form[data-turbo-method='delete']")
    end

    it "削除確認ダイアログが設定される" do
      expect(rendered).to have_css("form[data-turbo-confirm]")
    end
  end

  describe "グループ化表示" do
    context "同一MusicGenerationの複数Track" do
      let(:track2) { create(:track, music_generation: music_generation, content: content) }

      context "最初のTrack" do
        let(:is_group_start) { true }
        let(:group_size) { 2 }

        it "背景色がグループ用に設定される" do
          expect(rendered).to have_css("tr.bg-gray-800\\/50")
        end
      end

      context "2番目のTrack" do
        let(:component) { described_class.new(track: track2, music_generation: music_generation, is_group_start: false, group_size: 0, track_number: 2) }

        it "同じ背景色が設定される" do
          expect(rendered).to have_css("tr.bg-gray-800\\/50")
        end
      end
    end
  end
end
