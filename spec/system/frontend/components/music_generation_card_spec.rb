require 'rails_helper'

RSpec.describe "MusicGenerationCard", type: :system, js: true do
  let(:content) { create(:content) }
  let!(:music_generation) { create(:music_generation, content: content, status: :completed) }
  let!(:track) { create(:track, content: content, music_generation: music_generation) }

  before do
    visit content_path(content)
  end

  describe "削除機能" do
    it "削除ボタンが表示される" do
      # Track単位表示なので、data-generation-id属性で要素を探す
      expect(page).to have_css("tr[data-generation-id='#{music_generation.id}']")
      # 削除ボタンはTrack行に表示される
      within("tr[data-track-id='#{track.id}']") do
        expect(page).to have_button("削除")
      end
    end

    it "削除ボタンをクリックすると確認ダイアログが表示される" do
      within("tr[data-track-id='#{track.id}']") do
        # button_toヘルパーは実際にはformとbuttonを生成する
        delete_button = find("button", text: "削除")

        # ダイアログをキャンセルする場合
        page.dismiss_confirm do
          delete_button.click
        end
      end

      # Trackはまだ表示されている
      expect(page).to have_css("tr[data-track-id='#{track.id}']")
      expect(Track.exists?(track.id)).to be true
    end

    it "確認ダイアログで削除を選択するとTrackが削除される", js: true do
      within("tr[data-track-id='#{track.id}']") do
        # button_toヘルパーは実際にはformとbuttonを生成する
        delete_button = find("button", text: "削除")

        # ダイアログを受諾する場合
        page.accept_confirm do
          delete_button.click
        end
      end

      # Turboによる非同期処理を待つ
      expect(page).not_to have_css("tr[data-track-id='#{track.id}']", wait: 5)

      # データベースからの確認も行う（リロードして最新状態を取得）
      track.reload rescue ActiveRecord::RecordNotFound
      expect { Track.find(track.id) }.to raise_error(ActiveRecord::RecordNotFound)
      # MusicGenerationは削除されない（Trackのみ削除）
      expect(MusicGeneration.exists?(music_generation.id)).to be true
    end

    context "異なるステータスのMusicGeneration" do
      %w[pending processing failed].each do |status|
        it "#{status}ステータスでも削除ボタンが表示される" do
          music_generation.update!(status: status)
          visit content_path(content)

          expect(page).to have_css("tr[data-generation-id='#{music_generation.id}']")
          within("tr[data-track-id='#{track.id}']") do
            expect(page).to have_button("削除")
          end
        end
      end
    end

    context "MusicGenerationに複数のTrackがある場合" do
      let!(:additional_track) { create(:track, content: content, music_generation: music_generation) }

      it "各Trackに削除ボタンが表示される", js: true do
        # ページをリロードして最新の状態を取得
        visit content_path(content)

        expect(music_generation.tracks.count).to eq(2)

        # デバッグ用：ページの内容を確認
        expect(page).to have_css("tr[data-generation-id='#{music_generation.id}']", count: 2)

        # 各Trackに削除ボタンがあることを確認
        within("tr[data-track-id='#{track.id}']") do
          expect(page).to have_button("削除")
        end

        within("tr[data-track-id='#{additional_track.id}']") do
          expect(page).to have_button("削除")
        end

        # 一つのTrackを削除
        within("tr[data-track-id='#{track.id}']") do
          delete_button = find("button", text: "削除")
          page.accept_confirm do
            delete_button.click
          end
        end

        # Turboによる非同期処理を待つ
        expect(page).not_to have_css("tr[data-track-id='#{track.id}']", wait: 5)

        # もう一つのTrackはまだ表示されている
        expect(page).to have_css("tr[data-track-id='#{additional_track.id}']")

        # データベースから確認（リロードして最新状態を取得）
        track.reload rescue ActiveRecord::RecordNotFound
        expect { Track.find(track.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(Track.exists?(additional_track.id)).to be true
        expect(MusicGeneration.exists?(music_generation.id)).to be true
      end
    end
  end
end
