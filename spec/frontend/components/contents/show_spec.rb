# frozen_string_literal: true

require "rails_helper"

describe Contents::Show::Component, type: :view_component do
  let(:content) { build(:content, id: 1, theme: "リラックスできる朝のBGM", created_at: 1.day.ago, updated_at: 1.hour.ago) }
  let(:component) { Contents::Show::Component.new(item: content) }

  describe "rendering" do
    it "renders content theme" do
      render_inline(component)

      expect(page).to have_text("リラックスできる朝のBGM")
    end

    it "renders content metadata" do
      render_inline(component)

      expect(page).to have_text("作成日時")
      expect(page).to have_text("更新日時")
    end

    it "renders action buttons" do
      render_inline(component)

      expect(page).to have_link("編集", href: "/contents/1/edit")
      expect(page).to have_link("削除")
      expect(page).to have_link("一覧に戻る", href: "/contents")
    end

    it "includes delete confirmation data attributes" do
      render_inline(component)

      delete_link = page.find_link("削除")
      expect(delete_link[:"data-turbo-method"]).to eq("delete")
      expect(delete_link[:"data-controller"]).to include("delete-confirmation")
    end
  end
end
