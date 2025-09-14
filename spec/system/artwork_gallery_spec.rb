# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Artwork Gallery", type: :system, js: true do
  let(:user) { create(:user) }
  let(:content) { create(:content) }
  let!(:artwork) do
    # FHD画像（1920x1080）を設定してYouTubeサムネイル対象にする
    tempfile = Tempfile.new([ 'test', '.jpg' ])
    create_test_fhd_image(tempfile.path)

    uploaded_file = Rack::Test::UploadedFile.new(
      tempfile,
      'image/jpeg',
      original_filename: 'fhd_image.jpg'
    )

    create(:artwork, content: content, image: uploaded_file)
  end

  before do
    # UIでログイン
    visit new_user_session_path
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: user.password
    click_button 'ログイン'

    # YouTubeサムネイルのderivativeを追加
    thumb_tempfile = Tempfile.new([ 'youtube_thumb', '.jpg' ])
    create_test_hd_image(thumb_tempfile.path)

    # derivativesをモック
    artwork.image_attacher.add_derivative(:youtube_thumbnail, thumb_tempfile)
    artwork.image_attacher.write
    artwork.update!(
      thumbnail_generation_status: :completed,
      thumbnail_generated_at: Time.current
    )
  end

  it "displays artwork gallery with grid layout" do
    visit content_path(content)

    expect(page).to have_css(".artwork-gallery")
    expect(page).to have_css(".grid.grid-cols-2")

    # 2つのサムネイルが表示されている
    within ".artwork-gallery" do
      expect(page).to have_css("[data-image-type]", count: 2)
      expect(page).to have_css("[data-image-type='original']")
      expect(page).to have_css("[data-image-type='youtube']")
    end
  end

  it "allows clicking on thumbnails to switch images" do
    visit content_path(content)

    # アートワークギャラリーが表示される
    expect(page).to have_css(".artwork-gallery")

    within ".artwork-gallery" do
      # 初期状態：オリジナル画像が選択されている
      original_thumb = find("[data-image-type='original']")
      youtube_thumb = find("[data-image-type='youtube']")

      # オリジナルが選択状態になっていることを確認
      expect(original_thumb[:class]).to include("ring-2")
      expect(original_thumb[:class]).to include("ring-blue")

      # YouTubeサムネイルをクリック
      youtube_thumb.click
      sleep 0.5 # 切り替えのアニメーションを待つ

      # 選択状態が切り替わっているか確認
      expect(youtube_thumb[:class]).to include("ring-2")
      expect(youtube_thumb[:class]).to include("ring-blue")
    end
  end

  it "shows placeholder for YouTube thumbnail when generating" do
    # YouTubeサムネイル生成中の状態をシミュレート
    # derivativesを削除して生成中状態にする
    artwork.image_attacher.remove_derivative(:youtube_thumbnail)
    artwork.image_attacher.write
    artwork.update!(
      thumbnail_generation_status: "processing"
    )

    visit content_path(content)

    # アートワークギャラリーが表示される
    expect(page).to have_css(".artwork-gallery")

    within ".artwork-gallery" do
      # オリジナルとYouTubeの2つが表示される
      expect(page).to have_css("[data-image-type]", count: 2)
      expect(page).to have_css("[data-image-type='original']")

      # YouTubeサムネイルの項目があるかを確認
      # プレースホルダーでもimage_typeは'youtube_placeholder'ではなく'youtube'になる
      thumbnails = all("[data-image-type]")
      expect(thumbnails.size).to eq(2)

      # ラベルでYouTube（生成中）と表示されているか確認
      expect(page).to have_text("YouTube（生成中）")
    end
  end

  it "handles keyboard navigation" do
    visit content_path(content)

    # アートワークギャラリーが表示される
    expect(page).to have_css(".artwork-gallery")

    within ".artwork-gallery" do
      original_thumb = find("[data-image-type='original']")
      youtube_thumb = find("[data-image-type='youtube']")

      # オリジナルサムネイルにフォーカス
      original_thumb.click

      # TabキーでYouTubeサムネイルへ移動
      page.send_keys(:tab)
      sleep 0.1 # フォーカス移動を待つ

      # Enterキーで選択
      page.send_keys(:enter)
      sleep 0.5 # 切り替えのアニメーションを待つ

      # YouTubeサムネイルが選択状態になっているか確認
      expect(youtube_thumb[:class]).to include("ring-2")
      expect(youtube_thumb[:class]).to include("ring-blue")
    end
  end
end
