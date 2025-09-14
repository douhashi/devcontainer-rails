require 'rails_helper'

RSpec.describe "artworks/_artwork.html.erb", type: :view do
  let(:content_record) { create(:content) }
  let(:artwork) { create(:artwork, content: content_record) }

  before do
    # Stub the ArtworkDragDrop::Component
    stub_const('ArtworkDragDrop::Component', Class.new(ApplicationViewComponent) do
      def initialize(content_record:)
        @content_record = content_record
      end

      def call
        '<div class="artwork-drag-drop">Artwork Drag Drop</div>'.html_safe
      end
    end)
  end

  describe "with persisted artwork" do
    it "does not render anything when artwork exists" do
      render partial: "artworks/artwork", locals: { artwork: artwork, content: content_record }

      # 新しい実装では、アートワークが存在する場合は空のturbo-frameのみを表示
      expect(rendered).to have_css("turbo-frame#artwork_#{content_record.id}")
      expect(rendered).not_to have_css("img")
      expect(rendered).not_to have_css("button")
    end
  end

  describe "without artwork" do
    let(:artwork) { build(:artwork, content: content_record) }

    it "renders ArtworkDragDrop component" do
      render partial: "artworks/artwork", locals: { artwork: artwork, content: content_record }
      expect(rendered).to have_css(".artwork-drag-drop")
      expect(rendered).to have_content("Artwork Drag Drop")
    end
  end
end
