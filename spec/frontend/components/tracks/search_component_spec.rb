require "rails_helper"

RSpec.describe Tracks::Search::Component, type: :component do
  let(:query_object) { Track.ransack }

  describe "initialization" do
    it "accepts a ransack query object" do
      component = described_class.new(q: query_object)
      expect(component.instance_variable_get(:@q)).to eq(query_object)
    end
  end

  describe "rendering" do
    before do
      render_inline(described_class.new(q: query_object))
    end

    it "renders the search form" do
      expect(page).to have_css("form[data-controller='track-search']")
    end

    it "renders content theme search field" do
      expect(page).to have_field("q[content_theme_cont]")
    end

    it "renders music title search field" do
      expect(page).to have_field("q[music_title_cont]")
    end

    it "renders status filter dropdown" do
      expect(page).to have_select("q[status_eq]")
    end

    it "renders created_at date range fields" do
      expect(page).to have_field("q[created_at_gteq]")
      expect(page).to have_field("q[created_at_lteq]")
    end

    it "renders search button" do
      expect(page).to have_button("検索")
    end

    it "renders reset button" do
      expect(page).to have_link("リセット")
    end
  end

  describe "with search parameters" do
    let(:query_object) { Track.ransack(content_theme_cont: "Relax", status_eq: "completed") }

    before do
      render_inline(described_class.new(q: query_object))
    end

    it "preserves search values in form fields" do
      expect(page).to have_select("q[status_eq]", selected: "完了")
    end
  end
end
