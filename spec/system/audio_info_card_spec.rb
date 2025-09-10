require 'rails_helper'

RSpec.describe 'AudioInfoCard', type: :system do
  let(:user) { create(:user) }
  let(:content) { create(:content) }

  before do
    # System specではブラウザ経由でログイン
    visit new_user_session_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password'
    click_button 'ログイン'
  end

  describe 'Audio info display' do
    context 'with completed audio', js: true do
      let!(:audio) do
        create(:audio,
               content: content,
               status: 'completed',
               metadata: {
                 'duration' => 180,
                 'file_url' => 'https://example.com/audio.mp3'
               })
      end

      before do
        audio.update!(created_at: 2.minutes.ago, updated_at: Time.current)
        # Shrine uploaderのモック設定
        allow_any_instance_of(Audio).to receive(:audio_url).and_return('https://example.com/audio.mp3')
      end

      it 'displays audio info in horizontal layout' do
        visit content_path(content)

        within '.audio-info-card' do
          # 音源情報が横並びで表示されることを確認
          info_section = find('.flex.flex-col.sm\\:flex-row')
          expect(info_section).to be_present

          # 長さと作成時間が同じ行に表示される
          expect(page).to have_content('長さ:')
          expect(page).to have_content('3:00')
          expect(page).to have_content('作成時間:')
          expect(page).to have_content('2分0秒')

          # 再生ボタンが存在する
          expect(page).to have_css('button[aria-label*="Play"]', visible: :all)

          # 削除アイコンが存在する
          expect(page).to have_css('.text-red-500')
        end
      end

      it 'shows delete confirmation when delete icon is clicked' do
        visit content_path(content)

        within '.audio-info-card' do
          # 削除アイコンをクリック
          accept_confirm('この音源を削除してもよろしいですか？') do
            find('.text-red-500').click
          end
        end

        # 削除後のリダイレクトを確認
        expect(page).to have_current_path(content_path(content))
      end

      it 'is responsive on mobile view' do
        # モバイルビューポートに変更
        page.driver.browser.manage.window.resize_to(375, 667)

        visit content_path(content)

        within '.audio-info-card' do
          # モバイルでは縦並びになることを確認
          info_section = find('.flex.flex-col.sm\\:flex-row')
          expect(info_section[:class]).to include('flex-col')
        end
      end
    end

    context 'with processing audio' do
      let!(:audio) do
        create(:audio,
               content: content,
               status: 'processing',
               metadata: {})
      end

      it 'does not display delete icon or play button' do
        visit content_path(content)

        within '.audio-info-card' do
          # 削除アイコンが表示されない
          expect(page).not_to have_css('.text-red-500')

          # 再生ボタンが表示されない
          expect(page).not_to have_css('button[aria-label*="Play"]')
        end
      end
    end

    context 'with failed audio' do
      let!(:audio) do
        create(:audio,
               content: content,
               status: 'failed',
               metadata: {})
      end

      it 'displays delete icon but not play button' do
        visit content_path(content)

        within '.audio-info-card' do
          # 削除アイコンが表示される
          expect(page).to have_css('.text-red-500')

          # 再生ボタンが表示されない
          expect(page).not_to have_css('button[aria-label*="Play"]')
        end
      end
    end

    context 'without audio' do
      it 'displays empty state message' do
        visit content_path(content)

        within '.audio-info-card' do
          expect(page).to have_content('音源未生成')
          expect(page).to have_content('音源を生成するには「音源生成」ボタンをクリックしてください')
        end
      end
    end
  end

  describe 'Wrapper removal from AudioGenerationButton' do
    it 'does not have audio-generation-section wrapper' do
      visit content_path(content)

      # audio-generation-sectionクラスが存在しないことを確認
      expect(page).not_to have_css('.audio-generation-section')
    end
  end
end
