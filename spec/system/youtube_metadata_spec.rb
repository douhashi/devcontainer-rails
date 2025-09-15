require 'rails_helper'

RSpec.describe "YouTube Metadata Management", type: :system, js: true do
  let!(:content) { create(:content, theme: "Peaceful Morning") }

  describe "新規作成" do
    before do
      visit content_path(content)
    end

    it "「YouTube メタデータを作成」ボタンをクリックするとモーダルが表示される" do
      # YouTube メタデータセクションを確認
      within(".youtube-metadata-section") do
        expect(page).to have_content("YouTube メタデータが設定されていません")
        expect(page).to have_button("YouTube メタデータを作成")

        # ボタンをクリック
        click_button "YouTube メタデータを作成"
      end

      # モーダルが表示されることを確認
      modal = find("#youtube-metadata-new-modal", visible: true)
      within(modal) do
        expect(page).to have_content("新しい YouTube メタデータを作成")
        # ラベルの確認（name属性で直接指定）
        expect(page).to have_field("youtube_metadata[title]")
        expect(page).to have_field("youtube_metadata[description_en]")
        expect(page).to have_field("youtube_metadata[description_ja]")
        expect(page).to have_field("youtube_metadata[hashtags]")
        expect(page).to have_field("youtube_metadata[status]")
        expect(page).to have_button("作成")
        expect(page).to have_button("キャンセル")
      end
    end

    it "モーダルからYouTube メタデータを作成できる" do
      # ボタンをクリックしてモーダルを表示
      within(".youtube-metadata-section") do
        click_button "YouTube メタデータを作成"
      end

      # モーダル内でフォームを入力
      within("#youtube-metadata-new-modal") do
        fill_in "youtube_metadata[title]", with: "Peaceful Morning - Lofi BGM"
        fill_in "youtube_metadata[description_en]", with: "A peaceful morning lofi track"
        fill_in "youtube_metadata[description_ja]", with: "穏やかな朝のLofi BGM"
        fill_in "youtube_metadata[hashtags]", with: "#lofi #bgm #peaceful"
        select "Draft", from: "youtube_metadata[status]"

        click_button "作成"
      end

      # 作成成功後の表示を確認
      within(".youtube-metadata-section") do
        expect(page).to have_content("Peaceful Morning - Lofi BGM")
        expect(page).to have_content("A peaceful morning lofi track")
        expect(page).to have_content("穏やかな朝のLofi BGM")
        expect(page).to have_content("#lofi #bgm #peaceful")
        # ステータスは英語・日本語どちらか
        expect(page.text).to match(/Draft|下書き/)
      end

      # モーダルが閉じていることを確認
      expect(page).not_to have_selector("#youtube-metadata-new-modal", visible: true)
    end

    it "キャンセルボタンでモーダルを閉じることができる" do
      # ボタンをクリックしてモーダルを表示
      within(".youtube-metadata-section") do
        click_button "YouTube メタデータを作成"
      end

      # キャンセルボタンをクリック
      within("#youtube-metadata-new-modal") do
        click_button "キャンセル"
      end

      # モーダルが閉じていることを確認
      expect(page).not_to have_selector("#youtube-metadata-new-modal", visible: true)
    end
  end

  describe "編集" do
    let!(:youtube_metadata) do
      create(:youtube_metadata,
        content: content,
        title: "Original Title",
        description_en: "Original English description",
        description_ja: "元の日本語説明",
        hashtags: "#original #tags",
        status: "draft"
      )
    end

    before do
      visit content_path(content)
    end

    it "編集ボタンをクリックすると編集モーダルが表示される" do
      within(".youtube-metadata-section") do
        # 編集ボタンをクリック
        find('[aria-label="YouTube メタデータを編集"]').click
      end

      # 編集モーダルが表示されることを確認
      modal = find("#youtube-metadata-edit-modal-#{youtube_metadata.id}", visible: true)
      within(modal) do
        expect(page).to have_content("YouTube メタデータを編集")
        expect(page).to have_field("youtube_metadata[title]", with: "Original Title")
        expect(page).to have_field("youtube_metadata[description_en]", with: "Original English description")
        expect(page).to have_field("youtube_metadata[description_ja]", with: "元の日本語説明")
        expect(page).to have_field("youtube_metadata[hashtags]", with: "#original #tags")
      end
    end

    it "YouTube メタデータを更新できる" do
      within(".youtube-metadata-section") do
        find('[aria-label="YouTube メタデータを編集"]').click
      end

      # 編集モーダル内でフォームを更新
      within("#youtube-metadata-edit-modal-#{youtube_metadata.id}") do
        fill_in "youtube_metadata[title]", with: "Updated Title"
        fill_in "youtube_metadata[description_en]", with: "Updated English description"
        fill_in "youtube_metadata[description_ja]", with: "更新された日本語説明"
        fill_in "youtube_metadata[hashtags]", with: "#updated #new #tags"

        click_button "更新"
      end

      # 更新後の表示を確認
      within(".youtube-metadata-section") do
        expect(page).to have_content("Updated Title")
        expect(page).to have_content("Updated English description")
        expect(page).to have_content("更新された日本語説明")
        expect(page).to have_content("#updated #new #tags")
      end

      # モーダルが閉じていることを確認
      expect(page).not_to have_selector("#youtube-metadata-edit-modal-#{youtube_metadata.id}", visible: true)
    end
  end

  describe "削除" do
    let!(:youtube_metadata) do
      create(:youtube_metadata,
        content: content,
        title: "To be deleted",
        status: "draft"
      )
    end

    before do
      visit content_path(content)
    end

    it "YouTube メタデータを削除できる" do
      within(".youtube-metadata-section") do
        expect(page).to have_content("To be deleted")

        # 削除ボタンをクリック
        accept_confirm "YouTube メタデータを削除しますか？" do
          find('[aria-label="YouTube メタデータを削除"]').click
        end
      end

      # 削除後の表示を確認
      within(".youtube-metadata-section") do
        expect(page).to have_content("YouTube メタデータが設定されていません")
        expect(page).to have_button("YouTube メタデータを作成")
        expect(page).not_to have_content("To be deleted")
      end
    end
  end

  describe "ステータス変更" do
    let!(:youtube_metadata) do
      create(:youtube_metadata,
        content: content,
        title: "Status Test",
        status: "draft"
      )
    end

    before do
      visit content_path(content)
    end

    it "ステータスを変更できる" do
      within(".youtube-metadata-section") do
        # ステータスを確認（英語・日本語どちらか）
        expect(page.text).to match(/Draft|下書き/)

        # ステータス変更ボタンをクリック（ボタンのテキストを直接指定）
        # ボタンのテキストを確認してからクリック
        button = find('button', text: /Ready|準備完了/, match: :first)
        button.click
      end

      # ステータスが変更されたことを確認
      within(".youtube-metadata-section") do
        # ステータスが変更されたことを確認
        expect(page.text).to match(/Ready|準備完了/)
        # Draftステータスが表示されないことを確認
        within(".youtube-metadata-management-container") do
          expect(page).not_to have_css('[class*="bg-gray"]', text: /Draft|下書き/)
        end
      end
    end
  end
end
