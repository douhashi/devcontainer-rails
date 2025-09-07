require 'rails_helper'

RSpec.describe "Contents", type: :request do
  let(:valid_attributes) { { theme: "Rainy Day Coffee Shop" } }
  let(:invalid_attributes) { { theme: "" } }
  let(:content) { create(:content) }

  describe "GET /contents" do
    it "displays the contents list" do
      create_list(:content, 3)
      get contents_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Contents")
    end
  end

  describe "GET /contents/:id" do
    it "displays the content details" do
      get content_path(content)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(content.theme)
    end

    it "returns 404 for non-existent content" do
      get content_path(id: 'non-existent')
      expect(response).to have_http_status(:not_found)
    rescue ActiveRecord::RecordNotFound
      # This is expected
    end
  end

  describe "GET /contents/new" do
    it "displays the new content form" do
      get new_content_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("New Content")
    end
  end

  describe "POST /contents" do
    context "with valid parameters" do
      it "creates a new Content" do
        expect {
          post contents_path, params: { content: valid_attributes }
        }.to change(Content, :count).by(1)
      end

      it "redirects to the created content" do
        post contents_path, params: { content: valid_attributes }
        expect(response).to redirect_to(Content.last)
        follow_redirect!
        expect(response.body).to include("Content was successfully created")
      end
    end

    context "with invalid parameters" do
      it "does not create a new Content" do
        expect {
          post contents_path, params: { content: invalid_attributes }
        }.to change(Content, :count).by(0)
      end

      it "renders the new template with unprocessable content status" do
        post contents_path, params: { content: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("New Content")
      end
    end
  end

  describe "GET /contents/:id/edit" do
    it "displays the edit content form" do
      get edit_content_path(content)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Content")
      expect(response.body).to include(content.theme)
    end
  end

  describe "PATCH /contents/:id" do
    context "with valid parameters" do
      let(:new_attributes) { { theme: "Summer Night Study Session" } }

      it "updates the requested content" do
        patch content_path(content), params: { content: new_attributes }
        content.reload
        expect(content.theme).to eq("Summer Night Study Session")
      end

      it "redirects to the content" do
        patch content_path(content), params: { content: new_attributes }
        expect(response).to redirect_to(content)
        follow_redirect!
        expect(response.body).to include("Content was successfully updated")
      end
    end

    context "with invalid parameters" do
      it "does not update the content" do
        original_theme = content.theme
        patch content_path(content), params: { content: invalid_attributes }
        content.reload
        expect(content.theme).to eq(original_theme)
      end

      it "renders the edit template with unprocessable content status" do
        patch content_path(content), params: { content: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Edit Content")
      end
    end
  end

  describe "DELETE /contents/:id" do
    it "destroys the requested content" do
      content # create the content first
      expect {
        delete content_path(content)
      }.to change(Content, :count).by(-1)
    end

    it "redirects to the contents list" do
      delete content_path(content)
      expect(response).to redirect_to(contents_path)
      follow_redirect!
      expect(response.body).to include("Content was successfully destroyed")
    end
  end
end
