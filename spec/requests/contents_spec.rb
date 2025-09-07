require 'rails_helper'

RSpec.describe "Contents", type: :request do
  describe "GET /contents" do
    it "displays contents list" do
      create(:content, theme: "朝のリラックスBGM")
      create(:content, theme: "夜のチルアウト")

      get contents_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("コンテンツ一覧")
      expect(response.body).to include("朝のリラックスBGM")
      expect(response.body).to include("夜のチルアウト")
    end

    it "displays empty state when no contents" do
      get contents_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("コンテンツがまだありません")
    end
  end

  describe "GET /contents/:id" do
    let(:content) { create(:content, theme: "テストテーマ") }

    it "displays content details" do
      get content_path(content)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("テストテーマ")
      expect(response.body).to include("作成日時")
      expect(response.body).to include("更新日時")
    end
  end

  describe "GET /contents/new" do
    it "displays new content form" do
      get new_content_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("form")
    end
  end

  describe "POST /contents" do
    context "with valid params" do
      it "creates a new content" do
        expect {
          post contents_path, params: { content: { theme: "新しいテーマ" } }
        }.to change(Content, :count).by(1)

        expect(response).to redirect_to(Content.last)
        follow_redirect!
        expect(response.body).to include("Content was successfully created")
      end
    end

    context "with invalid params" do
      it "renders new template with errors" do
        post contents_path, params: { content: { theme: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("form")
      end
    end
  end

  describe "GET /contents/:id/edit" do
    let(:content) { create(:content) }

    it "displays edit form" do
      get edit_content_path(content)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("form")
      expect(response.body).to include(content.theme)
    end
  end

  describe "PATCH /contents/:id" do
    let(:content) { create(:content, theme: "古いテーマ") }

    context "with valid params" do
      it "updates the content" do
        patch content_path(content), params: { content: { theme: "更新されたテーマ" } }

        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("Content was successfully updated")
        expect(response.body).to include("更新されたテーマ")
      end
    end

    context "with invalid params" do
      it "renders edit template with errors" do
        patch content_path(content), params: { content: { theme: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("form")
      end
    end
  end

  describe "DELETE /contents/:id" do
    let!(:content) { create(:content) }

    it "destroys the content" do
      expect {
        delete content_path(content)
      }.to change(Content, :count).by(-1)

      expect(response).to redirect_to(contents_path)
      follow_redirect!
      expect(response.body).to include("Content was successfully destroyed")
    end
  end
end
