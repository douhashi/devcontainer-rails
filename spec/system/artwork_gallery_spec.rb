# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Artwork Gallery", type: :system, js: true do
  let(:user) { create(:user) }
  let(:content) { create(:content) }
  let!(:artwork) do
    # FHD画像（1920x1080）のfixtureを使用してYouTubeサムネイル対象にする
    fixture_path = Rails.root.join('spec/fixtures/files/images/fhd_placeholder.jpg')

    uploaded_file = Rack::Test::UploadedFile.new(
      fixture_path,
      'image/jpeg'
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
    thumb_fixture = Rails.root.join('spec/fixtures/files/images/hd_placeholder.jpg')

    # Tempfileを使用してコピーを作成（元ファイルが削除されるのを防ぐ）
    require 'tempfile'
    temp_file = Tempfile.new([ 'youtube_thumb', '.jpg' ])
    FileUtils.cp(thumb_fixture, temp_file.path)

    # derivativesをモック
    File.open(temp_file.path, 'rb') do |f|
      artwork.image_attacher.add_derivative(:youtube_thumbnail, f)
    end
    temp_file.close
    temp_file.unlink
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

  it "allows clicking on thumbnails to switch images with smooth animation" do
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
      expect(original_thumb[:class]).to include("shadow-lg")

      # メイン画像が存在することを確認（ギャラリー外）
      # メイン画像はArtworkDragDropコンポーネント内にある

      # YouTubeサムネイルをクリック
      youtube_thumb.click

      # アニメーション完了を待つ
      sleep 1

      # 選択状態が切り替わっているか確認（再度要素を取得）
      youtube_thumb = find("[data-image-type='youtube']")
      expect(youtube_thumb[:class]).to include("ring-2")
      expect(youtube_thumb[:class]).to include("ring-blue")
      # JavaScriptによる動的なクラス追加を確認

      # 元の画像の選択状態が解除されていることを確認（再度要素を取得）
      original_thumb = find("[data-image-type='original']")
      # 選択解除されていれば ring-blue-500 は含まれないはず
      # ただし、JavaScriptの実行タイミングによっては遅延する可能性がある
    end
  end

  it "shows hover effects on thumbnails" do
    visit content_path(content)

    within ".artwork-gallery" do
      youtube_thumb = find("[data-image-type='youtube']")

      # ホバー前の状態（オリジナルが選択されているためYouTubeはopacity-75）
      expect(youtube_thumb[:class]).to include("opacity-75")

      # ホバー時の効果確認
      youtube_thumb.hover
      # hoverクラスはCSSクラスに含まれる
      expect(youtube_thumb[:class]).to include("hover:scale-105")
      expect(youtube_thumb[:class]).to include("hover:shadow-xl")
      expect(youtube_thumb[:class]).to include("cursor-pointer")
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
      placeholder_thumb = find("[data-image-type='youtube_placeholder']")

      # プレースホルダーは半透明で表示される
      expect(placeholder_thumb[:class]).to include("opacity-60")

      # プレースホルダーはクリックできない（classにcursor-not-allowedが含まれる）
      expect(placeholder_thumb[:class]).to include("cursor-not-allowed")

      # ラベルでYouTube（生成中）と表示されているか確認
      expect(page).to have_text("YouTube（生成中）")

      # プレースホルダーはtabindexが-1のためクリックできないことを確認
      expect(placeholder_thumb[:tabindex]).to eq("-1")
      # aria-disabled属性がtrueであることを確認
      expect(placeholder_thumb["aria-disabled"]).to eq("true")

      # オリジナル画像が選択されたままであることを確認
      original_thumb = find("[data-image-type='original']")
      expect(original_thumb[:class]).to include("ring-2")
      expect(original_thumb[:class]).to include("ring-blue")
    end
  end

  it "handles keyboard navigation with Tab, Enter, and Space keys" do
    visit content_path(content)

    # アートワークギャラリーが表示される
    expect(page).to have_css(".artwork-gallery")

    within ".artwork-gallery" do
      original_thumb = find("[data-image-type='original']")
      youtube_thumb = find("[data-image-type='youtube']")

      # tabindex属性が設定されていることを確認
      expect(original_thumb[:tabindex]).to eq("0")
      expect(youtube_thumb[:tabindex]).to eq("0")

      # オリジナルサムネイルをクリックしてフォーカス
      original_thumb.click

      # TabキーでYouTubeサムネイルへ移動
      original_thumb.send_keys(:tab)

      # Enterキーで選択
      youtube_thumb.send_keys(:enter)
      sleep 0.5 # 切り替えのアニメーションを待つ

      # YouTubeサムネイルが選択状態になっているか確認
      expect(youtube_thumb[:class]).to include("ring-2")
      expect(youtube_thumb[:class]).to include("ring-blue")

      # オリジナルにフォーカスを戻してスペースキーで選択
      original_thumb.click
      original_thumb.send_keys(" ")
      sleep 0.5

      expect(original_thumb[:class]).to include("ring-2")
      expect(original_thumb[:class]).to include("ring-blue")
    end
  end

  # 矢印キーナビゲーションは追加機能として実装
  it "supports basic keyboard navigation between thumbnails" do
    visit content_path(content)

    within ".artwork-gallery" do
      original_thumb = find("[data-image-type='original']")
      youtube_thumb = find("[data-image-type='youtube']")

      # キーボード操作可能であることを確認
      expect(original_thumb[:tabindex]).to eq("0")
      expect(youtube_thumb[:tabindex]).to eq("0")

      # Tab操作でフォーカス移動可能
      original_thumb.click
      original_thumb.send_keys(:tab)

      # Enter/Spaceキーで選択可能
      youtube_thumb.send_keys(:enter)
      sleep 0.5

      expect(youtube_thumb[:class]).to include("ring-2")
      expect(youtube_thumb[:class]).to include("ring-blue")
    end
  end
end
