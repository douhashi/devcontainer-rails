# frozen_string_literal: true

require "rails_helper"

describe Contents::Index::Component, type: :view_component do
  let(:contents) { [] }
  let(:component) { Contents::Index::Component.new(contents: contents) }

  describe "rendering" do
    context "with empty contents" do
      it "renders empty state message" do
        render_inline(component)

        expect(page).to have_text("コンテンツがまだありません")
        expect(page).to have_link("最初のコンテンツを作成", href: "/contents/new")
      end
    end

    context "with contents" do
      let(:contents) do
        [
          build(:content, id: 1, theme: "リラックスできる朝のBGM", created_at: Time.current, updated_at: Time.current),
          build(:content, id: 2, theme: "夜のチルアウトミュージック", created_at: Time.current, updated_at: Time.current)
        ]
      end

      it "renders title and new content button" do
        render_inline(component)

        expect(page).to have_text("コンテンツ一覧")
        expect(page).to have_link("新規作成", href: "/contents/new")
      end

      it "renders content cards" do
        render_inline(component)

        expect(page).to have_css("[data-testid='content-card']", count: 2)
      end

      it "passes each content to Content::Card::Component" do
        expect(Content::Card::Component).to receive(:new).with(item: contents[0]).and_call_original
        expect(Content::Card::Component).to receive(:new).with(item: contents[1]).and_call_original

        render_inline(component)
      end
    end

    context "with pagination" do
      let(:contents) do
        paginated_contents = [
          build(:content, id: 1, theme: "朝のBGM", created_at: Time.current, updated_at: Time.current),
          build(:content, id: 2, theme: "昼のBGM", created_at: Time.current, updated_at: Time.current),
          build(:content, id: 3, theme: "夜のBGM", created_at: Time.current, updated_at: Time.current)
        ]
        paginated_contents.define_singleton_method(:current_page) { 1 }
        paginated_contents.define_singleton_method(:total_pages) { 3 }
        paginated_contents.define_singleton_method(:limit_value) { 10 }
        paginated_contents
      end

      it "renders pagination info" do
        render_inline(component)

        expect(page).to have_css("[data-testid='pagination']")
      end
    end
  end
end
