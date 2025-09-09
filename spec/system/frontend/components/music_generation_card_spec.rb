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
      expect(page).to have_css("#music_generation_#{music_generation.id}")
      expect(page).to have_button("削除")
    end

    it "削除ボタンをクリックすると確認ダイアログが表示される" do
      within("#music_generation_#{music_generation.id}") do
        delete_button = find("button[data-turbo-confirm]", text: "削除")

        # ダイアログをキャンセルする場合
        page.dismiss_confirm do
          delete_button.click
        end
      end

      # カードはまだ表示されている
      expect(page).to have_css("#music_generation_#{music_generation.id}")
      expect(MusicGeneration.exists?(music_generation.id)).to be true
    end

    it "確認ダイアログで削除を選択するとMusicGenerationが削除される" do
      within("#music_generation_#{music_generation.id}") do
        delete_button = find("button[data-turbo-confirm]", text: "削除")

        # ダイアログを受諾する場合（削除後はページがリダイレクトされる）
        page.accept_confirm do
          delete_button.click
        end
      end

      # 削除後、content詳細ページにリダイレクトされることを確認
      expect(page).to have_current_path(content_path(content))
      # 削除されたカードがページに表示されていないことを確認（これは確実な確認方法）
      expect(page).not_to have_css("#music_generation_#{music_generation.id}")
      # データベースからの確認も行うが、System Specでは表示確認の方が確実
      expect { MusicGeneration.find(music_generation.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { Track.find(track.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "異なるステータスのMusicGeneration" do
      %w[pending processing failed].each do |status|
        it "#{status}ステータスでも削除ボタンが表示される" do
          music_generation.update!(status: status)
          visit content_path(content)

          expect(page).to have_css("#music_generation_#{music_generation.id}")
          expect(page).to have_button("削除")
        end
      end
    end

    context "MusicGenerationに複数のTrackがある場合" do
      let!(:additional_track) { create(:track, content: content, music_generation: music_generation) }

      it "すべてのTrackが削除される" do
        expect(music_generation.tracks.count).to eq(2)

        within("#music_generation_#{music_generation.id}") do
          delete_button = find("button[data-turbo-confirm]", text: "削除")

          page.accept_confirm do
            delete_button.click
          end
        end

        # 削除後、content詳細ページにリダイレクトされることを確認
        expect(page).to have_current_path(content_path(content))
        # 削除されたカードがページに表示されていないことを確認（これは確実な確認方法）
        expect(page).not_to have_css("#music_generation_#{music_generation.id}")
        # データベースからの確認も行うが、System Specでは表示確認の方が確実
        expect { MusicGeneration.find(music_generation.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(Track.where(music_generation_id: music_generation.id).count).to eq(0)
      end
    end
  end
end
