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
    it "renders delete button as icon button" do
      render partial: "artworks/artwork", locals: { artwork: artwork, content: content_record }

      # Check for icon button structure
      expect(rendered).to have_css("button[type='submit'] i.fa-trash")

      # Check for aria-label
      expect(rendered).to have_css("button[aria-label='削除']")

      # Check for danger variant styling
      expect(rendered).to have_css("button.bg-red-600")
      expect(rendered).to have_css("button.hover\\:bg-red-700")

      # Check for turbo confirm
      expect(rendered).to have_css("button[data-turbo-confirm='アートワークを削除しますか？']")
    end

    it "maintains proper button sizing" do
      render partial: "artworks/artwork", locals: { artwork: artwork, content: content_record }

      # Check for icon button class
      expect(rendered).to have_css("button.px-4.py-2")
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
