require 'rails_helper'

RSpec.describe "Artwork Image Switcher", type: :request do
  include_context "Request Spec用認証"

  let(:content) { create(:content) }
  let(:artwork) { create(:artwork, content: content) }

  describe "GET /contents/:id" do
    context "アートワークがある場合" do
      before do
        content.update!(artwork: artwork)
      end

      it "ギャラリーが表示される" do
        get content_path(content)

        expect(response).to have_http_status(:success)

        # Turbo Frameが正しく設定されていることを確認
        expect(response.body).to include("turbo-frame")
        expect(response.body).to include("id=\"artwork_#{content.id}\"")

        # 画像が表示されることを確認
        expect(response.body).to include('alt="アートワーク"')

        # Stimulus コントローラーが設定されていることを確認
        expect(response.body).to include('data-controller')
        expect(response.body).to include('artwork-switcher')
      end

      it "オリジナル画像のサムネイルが表示される" do
        get content_path(content)

        expect(response).to have_http_status(:success)

        # ギャラリーが表示されることを確認
        expect(response.body).to include('artwork-gallery')
        expect(response.body).to include('data-image-type="original"')
        expect(response.body).to include('オリジナル')
      end

      it "サムネイルがクリック可能な構造を持っている" do
        get content_path(content)

        expect(response).to have_http_status(:success)

        # サムネイルの属性を確認
        expect(response.body).to include('role="button"')
        expect(response.body).to include('tabindex="0"')
        expect(response.body).to include('data-action')
        expect(response.body).to include('click->artwork-switcher#switchImage')
      end

      it "適切なARIA属性が設定されている" do
        get content_path(content)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('aria-label')
        expect(response.body).to include('オリジナル画像に切り替え')
      end
    end

    context "アートワーク未設定時" do
      it "ギャラリーが表示されない" do
        get content_path(content)

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('artwork-gallery')
        expect(response.body).to include("画像をドラッグ&ドロップ")
      end
    end
  end
end
